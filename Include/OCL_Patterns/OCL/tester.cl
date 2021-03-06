//+------------------------------------------------------------------+
//|                                                        tester.cl |
//|                                  Copyright 2018, Serhii Shevchuk |
//|                           https://www.mql5.com/en/users/decanium |
//+------------------------------------------------------------------+
#pragma OPENCL EXTENSION cl_khr_fp64 : enable
#pragma OPENCL EXTENSION cl_khr_global_int32_base_atomics : enable
#pragma OPENCL EXTENSION cl_khr_local_int32_base_atomics : enable
#pragma OPENCL EXTENSION cl_khr_global_int32_extended_atomics : enable
#pragma OPENCL EXTENSION cl_khr_local_int32_extended_atomics : enable
#pragma OPENCL EXTENSION cl_khr_int64_base_atomics : enable
#pragma OPENCL EXTENSION cl_khr_int64_base_atomics : enable
//--- number of bars in the pattern
#define  PBARS  3
//--- operations
#define  OP_NONE   0   
#define  OP_BUY    1
#define  OP_SELL   2
//--- patterns
#define  PAT_NONE                0
#define  PAT_PINBAR_BEARISH      (1<<0)
#define  PAT_PINBAR_BULLISH      (1<<1)
#define  PAT_ENGULFING_BEARISH   (1<<2)
#define  PAT_ENGULFING_BULLISH   (1<<3)
//--- prices
#define  O(i) Open[i]
#define  H(i) High[i]
#define  L(i) Low[i]
#define  C(i) Close[i]
//+------------------------------------------------------------------+
//| Check if the patterns are present                                |
//+------------------------------------------------------------------+
uint Check(__global double *Open,__global double *High,__global double *Low,__global double *Close,double ref,uint flags)
  {
//--- bearish pin bar  
   if((flags&PAT_PINBAR_BEARISH)!=0)
     {//
      double tail=H(1)-fmax(O(1),C(1));
      if(tail>=ref && C(0)>O(0) && O(2)>C(2) && H(1)>fmax(H(0),H(2)) && fabs(O(1)-C(1))<tail)
         return PAT_PINBAR_BEARISH;
     }
//--- bullish pin bar  
   if((flags&PAT_PINBAR_BULLISH)!=0)
     {//
      double tail=fmin(O(1),C(1))-L(1);
      if(tail>=ref && O(0)>C(0) && C(2)>O(2) && L(1)<fmin(L(0),L(2)) && fabs(O(1)-C(1))<tail)
         return PAT_PINBAR_BULLISH;
     }
//--- bearish engulfing
   if((flags&PAT_ENGULFING_BEARISH)!=0)
     {//
      if((C(1)-O(1))>=ref && H(0)<C(1) && O(2)>C(1) && C(2)<O(1))
         return PAT_ENGULFING_BEARISH;
     }
//--- bullish engulfing
   if((flags&PAT_ENGULFING_BULLISH)!=0)
     {//
      if((O(1)-C(1))>=ref && L(0)>C(1) && O(2)<C(1) && C(2)>O(1))
         return PAT_ENGULFING_BULLISH;
     }
//--- nothing found   
   return PAT_NONE;
  }
//+------------------------------------------------------------------+
//| Search for the patterns and set orders                           |
//+------------------------------------------------------------------+
__kernel void find_patterns(__global double *Open,__global double *High,__global double *Low,__global double *Close,
                            __global int *Order,       // order buffer
                            __global int *Count,       // number of orders in the buffer
                            const double ref,          // pattern parameter 
                            const uint flags)          // what patterns to search for
  {
//--- works in one dimension  
//--- bar index  
   size_t x=get_global_id(0);
//--- patterns search space size   
   size_t depth=get_global_size(0)-PBARS;
   if(x>=depth)
      return;
//--- check if the patterns are present
   uint res=Check(&Open[x],&High[x],&Low[x],&Close[x],ref,flags);
   if(res==PAT_NONE)
      return;
//--- set the orders
   if(res==PAT_PINBAR_BEARISH || res==PAT_ENGULFING_BEARISH)
     {//sell
      int i=atomic_inc(&Count[0]);
      Order[i*2]=x+PBARS;
      Order[(i*2)+1]=OP_SELL;
     }
   else if(res==PAT_PINBAR_BULLISH || res==PAT_ENGULFING_BULLISH)
     {//buy
      int i=atomic_inc(&Count[0]);
      Order[i*2]=x+PBARS;
      Order[(i*2)+1]=OP_BUY;
     }
  }
//+------------------------------------------------------------------+
//| Search for entry points on М1 period                             |
//+------------------------------------------------------------------+
__kernel void order_to_M1(__global ulong *Time,__global ulong *TimeM1,
                          __global int *Order,__global int *OrderM1,
                          __global int *Count,
                          const ulong shift) // time shift in seconds
  {
//--- works in two dimensions
   size_t x=get_global_id(0); //index of Time index in Order
   if(OrderM1[x*2]>=0)
      return;
   size_t y=get_global_id(1); //index in TimeM1
   if((Time[Order[x*2]]+shift)==TimeM1[y])
     {
      atomic_inc(&Count[1]);
      //--- set indices in the TimeM1 buffer by even indices
      OrderM1[x*2]=y;
      //--- set (OP_BUY/OP_SELL) operations by odd indices
      OrderM1[(x*2)+1]=Order[(x*2)+1];
     }
  }
//+------------------------------------------------------------------+
//| Track an open position in the single test mode                   |
//+------------------------------------------------------------------+
__kernel void tester_step(__global double *OpenM1,__global double *HighM1,__global double *LowM1,__global double *CloseM1,
                          __global double *SpreadM1,// in price difference, not in points
                          __global ulong *TimeM1,
                          __global int *OrderM1,     // order buffer where [0] is an index in OHLC(M1), while [1] is (Buy/Sell) operation
                          __global int *Tasks,       // task buffer (of open positions) stores indices for orders in the OrderM1 buffer
                          __global int *Left,        // number of remaining tasks, two elements: [0] - for bank0, [1] - for bank1
                          __global double *Res,      // result buffer 
                          const uint bank,           // current bank                           
                          const uint orders,         // number of orders in OrderM1
                          const uint start_bar,      // serial number of the handled bar (as a shift from the specified index in OrderM1)
                          const uint stop_bar,       // the last bar to be handled
                          const uint maxbar,         // maximum acceptable bar index (the last bar of the array)
                          const double tp_dP,        // TP in price difference
                          const double sl_dP,        // SL in price difference
                          const ulong timeout)       // when to forcibly close a trade (in seconds) 
  {
//--- works in one dimension    
//--- get the index of the task to work with  
   size_t id=get_global_id(0);
//--- index of the next tasks bank
   uint bank_next=(bank)?0:1;
//--- order index in the OrderM1 buffer (trade result index)   
   uint idx;
//--- at the first launch, the order index is equal to the task index   
//--- in these cases, the order index is taken from the list of tasks formed during the previous launch
   if(!start_bar)
      idx=id;
   else
      idx=Tasks[(orders*bank)+id];
//--- bar index in the M1 buffer where a position was opened
   uint iO=OrderM1[idx*2];
//--- (OP_BUY/OP_SELL) operation
   uint op=OrderM1[(idx*2)+1];
//--- forced close time
   ulong tclose=TimeM1[iO]+timeout;
//--- wait for a position to close within the range from (iO+start_bar) to (iO+stop_bar)
   if(op==OP_BUY)
     {
      //--- position open price
      double open=OpenM1[iO]+SpreadM1[iO];
      double tp = open+tp_dP;
      double sl = open-sl_dP;
      double p=0;
      for(uint j=iO+start_bar; j<=(iO+stop_bar); j++)
        {
         for(uint k=0;k<4;k++)
           {
            if(k==0)
              {
               p=OpenM1[j];
               if(j>=maxbar || TimeM1[j]>=tclose)
                 {
                  //--- forced close by time
                  Res[idx]=p-open;
                  return;
                 }
              }
            else if(k==1)
               p=HighM1[j];
            else if(k==2)
               p=LowM1[j];
            else
               p=CloseM1[j];
            //--- check if TP or SL is triggered
            if(p<=sl)
              {
               Res[idx]=sl-open;
               return;
              }
            else if(p>=tp)
              {
               Res[idx]=tp-open;
               return;
              }
           }
        }
     }
   else if(op==OP_SELL)
     {
      // position open price
      double open=OpenM1[iO];
      double tp = OpenM1[iO]-tp_dP;
      double sl = OpenM1[iO]+sl_dP;
      double p=0;
      for(uint j=iO+start_bar; j<=(iO+stop_bar); j++)
        {
         for(uint k=0;k<4;k++)
           {
            if(k==0)
              {
               p=OpenM1[j]+SpreadM1[j];
               //
               if(j>=maxbar || TimeM1[j]>=tclose)
                 {
                  //--- forced close by time
                  Res[idx]=open-p;
                  return;
                 }
              }
            else if(k==1)
               p=HighM1[j]+SpreadM1[j];
            else if(k==2)
               p=LowM1[j]+SpreadM1[j];
            else
               p=CloseM1[j]+SpreadM1[j];
            //--- check if TP or SL is triggered
            if(p>=sl)
              {
               Res[idx]=open-sl;
               return;
                 }else if(p<=tp){
               Res[idx]=open-tp;
               return;
              }
           }
        }
     }
//--- if you reached this place, the test is not over yet
//--- increase the number of tasks for the next launch and put the next task there
   uint i=atomic_inc(&Left[bank_next]);
   Tasks[(orders*bank_next)+i]=idx;
  }
//+------------------------------------------------------------------+
//| Fill the buffer with a specified value                           |
//+------------------------------------------------------------------+
__kernel void array_fill(__global int *Buf,const int value)
  {
//--- works in one dimension    
   size_t x=get_global_id(0);
   Buf[x]=value;
  }
//+------------------------------------------------------------------+
//| Placing orders for optimization                                  |
//+------------------------------------------------------------------+
__kernel void tester_opt_prepare(__global ulong *Time,__global ulong *TimeM1,
                                 __global int *OrderM1,// order buffer
                                 __global int *Count,
                                 const int   SL_count,      // number of SL values
                                 const ulong shift)         // time shift in seconds
  {
//--- works in two dimensions   
   size_t x=get_global_id(0); //index in Time
   if(OrderM1[x*SL_count*4]>=0)
      return;
   size_t y=get_global_id(1); //index in TimeM1
   if((Time[x]+shift)==TimeM1[y])
     {
      //--- find the maximum bar index for М1 period along the way
      atomic_max(&Count[1],y);
      uint offset=x*SL_count*4;
      for(int i=0;i<SL_count;i++)
        {
         uint idx=offset+i*4;
         //--- add two orders (buy and sell) for each bar
         OrderM1[idx++]=y;
         OrderM1[idx++]=OP_BUY |(i<<2);
         OrderM1[idx++]=y;
         OrderM1[idx]  =OP_SELL|(i<<2);
        }
      atomic_inc(&Count[0]);
     }
  }
//+------------------------------------------------------------------+
//| Track an open position in optimization mode                      |
//+------------------------------------------------------------------+
__kernel void tester_opt_step(__global double *OpenM1,__global double *HighM1,__global double *LowM1,__global double *CloseM1,
                              __global double *SpreadM1,// in price difference, not in points
                              __global ulong *TimeM1,
                              __global int *OrderM1,     // order buffer, where [0] is an index in OHLC(M1), [1] is a (Buy/Sell) operation
                              __global int *Tasks,       // buffer of tasks (open positions) storing indices for orders in the OrderM1 buffer
                              __global int *Left,        // number of remaining tasks, two elements: [0] - for bank0, [1] - for bank1
                              __global double *Res,      // buffer of results filled as soon as they are received, 
                              const uint bank,           // the current bank                           
                              const uint orders,         // number of orders in OrderM1
                              const uint start_bar,      // the serial number of a handled bar (as a shift from the specified index in OrderM1) - in fact, "i" from the loop launching the kernel
                              const uint stop_bar,       // the final bar to be handled - generally, equal to 'bar'
                              const uint maxbar,         // maximum acceptable bar index (last bar of the array)
                              const double tp_dP,        // TP in price difference
                              const uint sl_start,       // SL in points - initial value
                              const uint sl_step,        // SL in points - step
                              const ulong timeout,       // trade lifetime (in seconds), after which it is forcibly closed 
                              const double point)        // _Point
  {
//--- works in one dimension    
//--- get the index of the task to work with   
   size_t id=get_global_id(0);
//--- index of the next tasks bank
   uint bank_next=(bank)?0:1;
//--- order index in the OrderM1 buffer (trade result index)                                  
   uint idx;
//--- during the first launch, the order index is equal to the task one   
//--- during susequent launches, the order index is taken from the list of tasks formed during the previous launch   
   if(!start_bar)
      idx=id;
   else
      idx=Tasks[(orders*bank)+id];
//--- bar index in M1 buffer where a position was opened   
   uint iO=OrderM1[idx*2];
//--- operation (bits 1:0) and SL index (bits 9:2)
   uint opsl=OrderM1[(idx*2)+1];
//--- get SL index   
   uint sli=opsl>>2;
//--- forced close time
   ulong tclose=TimeM1[iO]+timeout;
//--- wait for closing a position in the range from (iO+start_bar) to (iO+stop_bar)
   if(opsl&OP_BUY)
     {
      //--- position open price
      double open=OpenM1[iO]+SpreadM1[iO];
      double tp= open+tp_dP;
      int slpp = sl_start+(sl_step*sli);
      double sl= open-slpp*point;
      double p = 0;
      for(uint j=iO+start_bar; j<=(iO+stop_bar); j++)
        {
         for(uint k=0;k<4;k++)
           {
            if(k==0)
              {
               p=OpenM1[j];
               //
               if(j>=maxbar || TimeM1[j]>=tclose)
                 {
                  //--- forced closing by time
                  Res[idx]=p-open;
                  return;
                 }
              }
            else if(k==1)
               p=HighM1[j];
            else if(k==2)
               p=LowM1[j];
            else
               p=CloseM1[j];
            //--- check if TP or SL is triggered
            if(p<=sl)
              {
               Res[idx]=sl-open;
               return;
              }
            else if(p>=tp)
              {
               Res[idx]=tp-open;
               return;
              }
           }
        }
     }
   else if(opsl&OP_SELL)
     {
      //--- position open price
      double open=OpenM1[iO];
      double tp= open-tp_dP;
      int slpp = sl_start+(sl_step*sli);
      double sl= open+slpp*point;
      double p = 0;
      for(uint j=iO+start_bar; j<=(iO+stop_bar); j++)
        {
         for(uint k=0;k<4;k++)
           {
            if(k==0)
              {
               p=OpenM1[j]+SpreadM1[j];
               //
               if(j>=maxbar || TimeM1[j]>=tclose)
                 {
                  //--- forced close by time
                  Res[idx]=open-p;
                  return;
                 }
              }
            else if(k==1)
               p=HighM1[j]+SpreadM1[j];
            else if(k==2)
               p=LowM1[j]+SpreadM1[j];
            else
               p=CloseM1[j]+SpreadM1[j];
            //--- check if TP or SL is triggered
            if(p>=sl)
              {
               Res[idx]=open-sl;
               return;
              }
            else if(p<=tp)
              {
               Res[idx]=open-tp;
               return;
              }
           }
        }
     }
//--- if you reached this point, the test is not over yet
//--- increase the number of tasks for the next launch and put the current task there
   uint i=atomic_inc(&Left[bank_next]);
   Tasks[(orders*bank_next)+i]=idx;
  }
//+--------------------------------------------------------------------------+
//| Search for the patterns and sum up the results in the optimization mode  |
//+--------------------------------------------------------------------------+
__kernel void find_patterns_opt(__global double *Open,__global double *High,__global double *Low,__global double *Close,
                                __global double *Test,     // test results buffer for each bar, size 2*x*z ([0]-buy, [1]-sell ... )
                                __global int *Results,     // result buffer, size 4*y*z 
                                const double ref_start,    // pattern parameter
                                const double ref_step,     // 
                                const uint flags,          // what patterns to look for
                                const double point)        // _Point/100
  {
//--- works in three dimensions
//--- bar index 
   size_t x=get_global_id(0);
//--- ref value index
   size_t y=get_global_id(1);
//--- SL value index
   size_t z=get_global_id(2);
//--- number of bars
   size_t x_sz=get_global_size(0);
//--- number of ref values
   size_t y_sz=get_global_size(1);
//--- number of sl values
   size_t z_sz=get_global_size(2);
//--- pattern search space size   
   size_t depth=x_sz-PBARS;
   if(x>=depth)//do not open near the buffer end
      return;
//
   uint res=Check(&Open[x],&High[x],&Low[x],&Close[x],ref_start+ref_step*y,flags);
   if(res==PAT_NONE)
      return;
//--- calculate the trade result index in the Test[] buffer
   int ri;
   if(res==PAT_PINBAR_BEARISH || res==PAT_ENGULFING_BEARISH) //sell
      ri = (x+PBARS)*z_sz*2+z*2+1;
   else                                                      //buy
      ri=(x+PBARS)*z_sz*2+z*2;
//--- get the result by the calculated index and convert into cents
   int r=Test[ri]/point;
//--- calculate the test result index in the Results[] buffer
   int idx=z*y_sz*4+y*4;
//--- add the current pattern's trade result
   if(r>=0)
     {//--- profit
      //--- sum up the total profit in cents
      atomic_add(&Results[idx],r);
      //--- increase the number of profitable trades
      atomic_inc(&Results[idx+2]);
     }
   else
     {//--- loss
      //--- sum up the total loss in cents
      atomic_add(&Results[idx+1],r);
      //--- increase the number of loss trades
      atomic_inc(&Results[idx+3]);
     }
  }
//+------------------------------------------------------------------+
