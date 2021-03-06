//+------------------------------------------------------------------+
//|                                                    Buffering.mqh |
//|                                  Copyright 2018, Serhii Shevchuk |
//|                           https://www.mql5.com/en/users/decanium |
//+------------------------------------------------------------------+
#property copyright "Copyright 2018, Serhii Shevchuk"
#property link      "https://www.mql5.com/en/users/decanium"
#property version   "1.00"
//+------------------------------------------------------------------+
//| CBuffering                                                       |
//+------------------------------------------------------------------+
class CBuffering
  {
private:
   string            m_symbol;
   ENUM_TIMEFRAMES   m_period;
   int               m_maxbars;
   uint              m_memory_usage;   //amount of used memory
   bool              m_spread_ena;     //upload spread buffer
   datetime          m_from;
   datetime          m_to;
   uint              m_timeout;        //upload timeout in milliseconds
   ulong             m_ts_abort;       //time stamp in microseconds when the operation should be interrupted
   //--- forced upload
   bool              ForceUploading(datetime from,datetime to);
public:
                     CBuffering();
                    ~CBuffering();
   //--- amount of data in the buffers
   int               Depth;
   //--- buffers
   double            Open[];
   double            High[];
   double            Low[];
   double            Close[];
   double            Spread[];
   datetime          Time[];
   //--- get real time borders of uploaded data
   datetime          TimeFrom(void){return m_from;}
   datetime          TimeTo(void){return m_to;}
   //--- 
   int               Copy(string symbol,ENUM_TIMEFRAMES period,datetime from,datetime to,double point=0);
   uint              GetMemoryUsage(void){return m_memory_usage;}
   bool              SpreadBufEnable(void){return m_spread_ena;}
   void              SpreadBufEnable(bool ena){m_spread_ena=ena;}
   void              SetTimeout(uint timeout){m_timeout=timeout;}
  };
//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CBuffering::CBuffering() : m_memory_usage(0),
                           m_from(0),
                           m_to(0),
                           m_spread_ena(false),
                           m_timeout(5000),
                           m_ts_abort(0),
                           m_symbol(_Symbol),
                           m_period(_Period)
  {
  }
//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CBuffering::~CBuffering()
  {
   ArrayFree(Open);
   ArrayFree(High);
   ArrayFree(Low);
   ArrayFree(Close);
   ArrayFree(Spread);
   ArrayFree(Time);
  }
//+------------------------------------------------------------------+
//| Timeout handling macro                                           |
//+------------------------------------------------------------------+
#define IF_TIMED_OUT(err)  if(m_ts_abort) if(GetMicrosecondCount()>=m_ts_abort) return err  
//+------------------------------------------------------------------+
//| Copying timeseries                                               |
//+------------------------------------------------------------------+
int CBuffering::Copy(string symbol,ENUM_TIMEFRAMES period,datetime from,datetime to,double point=0)
  {
   if(!SymbolInfoInteger(symbol,SYMBOL_SELECT))
      return -1;
   m_symbol = symbol;
   m_period = period;
//--- time buffers for time and price
   datetime ttmp[];
   double   ptmp[];
//--- get the maximum number of bars on the chart
   m_maxbars=TerminalInfoInteger(TERMINAL_MAXBARS);
//--- set the time when execution should be interrupted
   if(m_timeout)
      m_ts_abort=GetMicrosecondCount()+ulong(m_timeout*1000);
//--- start copying data
   int depth_total=0;
//--- check the availability of bars having the time less or equal to the one set in "from"
   int depth=CopyTime(m_symbol,m_period,from,from-3*24*3600,ttmp);//
   if(depth<1)
     {
      //--- data unavailable, activate forced upload
      if(ForceUploading(from,to)==false)
         return -2;
     }
//--- get time less or equal to the one set in "to"
   depth=CopyTime(m_symbol,m_period,to,1,ttmp);
   if(depth<1)
      return -2;
   to=ttmp[0];
   uint seconds=PeriodSeconds(m_period);
   uint step = seconds*m_maxbars;
   datetime t=from;
//--- Data upload loop
   while(!IsStopped())
     {
      datetime t_end=t+step;
      if(t_end>to)
         t_end=to;
      //--- Time:         
      depth=CopyTime(m_symbol,m_period,t,t_end,ttmp);
      if(depth<1)
        {
         //--- data unavailable, activate forced upload
         if(ForceUploading(t,t_end)==false)
            return -2;
        }
      ArrayCopy(Time,ttmp,depth_total);
      //--- Open:     
      while(!IsStopped())
        {
         if(CopyOpen(m_symbol,m_period,t,t_end,ptmp)==depth)
            break;
         if(ForceUploading(t,t_end)==false)
            return -2;
         IF_TIMED_OUT(-2);
        }
      ArrayCopy(Open,ptmp,depth_total);
      //--- High:     
      while(!IsStopped())
        {
         if(CopyHigh(m_symbol,m_period,t,t_end,ptmp)==depth)
            break;
         if(ForceUploading(t,t_end)==false)
            return -2;
         IF_TIMED_OUT(-2);
        }
      ArrayCopy(High,ptmp,depth_total);
      //--- Low:
      while(!IsStopped())
        {
         if(CopyLow(m_symbol,m_period,t,t_end,ptmp)==depth)
            break;
         if(ForceUploading(t,t_end)==false)
            return -2;
         IF_TIMED_OUT(-2);
        }
      ArrayCopy(Low,ptmp,depth_total);
      //--- Close:     
      while(!IsStopped())
        {
         if(CopyClose(m_symbol,m_period,t,t_end,ptmp)==depth)
            break;
         if(ForceUploading(t,t_end)==false)
            return -2;
         IF_TIMED_OUT(-2);
        }
      ArrayCopy(Close,ptmp,depth_total);
      //--- Spread:
      if(m_spread_ena==true)
        {
         int spr[];
         while(!IsStopped())
           {
            if(CopySpread(m_symbol,m_period,t,t_end,spr)==depth)
               break;
            if(ForceUploading(t,t_end)==false)
               return -2;
            IF_TIMED_OUT(-2);
           }
         double spread[];
         if(ArrayResize(spread,depth)!=depth)
            return -2;
         for(int i=0;i<depth;i++)
            spread[i]=spr[i]*point;
         ArrayCopy(Spread,spread,depth_total);
        }
      //--- re-calculate the amount of data and the time stamp for the next upload
      depth_total+=depth;
      t=Time[depth_total-1];
      //--- exit if all data uploaded      
      if(t>=to)
         break;
      t+=seconds;
      //--- exit by timeout if set
      IF_TIMED_OUT(-2);
     }
//--- save data borders and size
   m_from=from;
   m_to=to;
   Depth=depth_total;
//--- calculate the amount of the occupied memory
   m_memory_usage = depth_total*4*sizeof(double);
   m_memory_usage+=depth_total*sizeof(datetime);
   if(m_spread_ena==true)
      m_memory_usage+=depth_total*sizeof(double);
   return 0;
  }
//+------------------------------------------------------------------+
//| Forced upload                                                    |
//+------------------------------------------------------------------+
bool CBuffering::ForceUploading(datetime from,datetime to)
  {
   uint step=(PeriodSeconds(m_period)*m_maxbars)/4;
   datetime t_end=to;
   datetime t_start=t_end-step;
   MqlRates r[];
   while(!IsStopped())
     {
      int depth=CopyRates(_Symbol,m_period,t_start,t_end,r);
      //   
      if(depth>0)
        {
         if(r[0].time<=from)
            break;
         t_end=r[0].time-1;
         t_start=t_end-step;
        }
      else
         Sleep(10);
      IF_TIMED_OUT(false);
     }
   return true;
  }
//+------------------------------------------------------------------+
