//+------------------------------------------------------------------+
//|                                              TestPatternsOCL.mqh |
//|                                  Copyright 2018, Serhii Shevchuk |
//|                           https://www.mql5.com/en/users/decanium |
//+------------------------------------------------------------------+
#property copyright "Copyright 2018, Serhii Shevchuk"
#property link      "https://www.mql5.com/en/users/decanium"
#property version   "1.00"

//--- COpenCLx class
#include "OpenCLx.mqh"
//--- Data upload class
#include "Buffering.mqh"
//--- User errors  
#define UERR_DATA_LOADING     1
#define UERR_DATA_ACCESS      2
#define UERR_ORDERS_PREPARE   3
#define UERR_OPT_PARS         4
//--- single pass test result
struct STR_TEST_RESULT
  {
   int               trades_total;
   int               profit_trades;
   int               loss_trades;
   double            gross_profit;
   double            gross_loss;
   double            net_profit;
  };
//--- inputs for a single test
struct STR_TEST_PARS
  {
   uint              ref;        // reference value
   uint              tp;         // Take profit
   uint              sl;         // Stop loss
   uint              timeout;    // amount of SECONDS, after which a trade is forcibly closed
   uint              flags;      // patterns to be tested
  };
//--- optimized parameter structure
struct STR_OPT_PAR
  {
   int               start;
   int               step;
   int               stop;
   //--- optimization result:
   int               value;
  };
//--- inputs for optimization
struct STR_OPT_PARS
  {
   STR_OPT_PAR       ref;     // reference value
   uint              tp;      // Take profit
   STR_OPT_PAR       sl;      // Stop loss
   uint              timeout; // amount of SECONDS, after which a trade is forcibly closed
   uint              flags;   // patterns to be tested
  };
//+------------------------------------------------------------------+
//| CTestPatterns                                                    |
//+------------------------------------------------------------------+
class CTestPatterns : private COpenCLx
  {
private:
   CBuffering       *m_sbuf;  //Scan buf
   CBuffering       *m_tbuf;  //Test buf
   int               m_prepare_passes;
   uint              m_tester_passes;
   bool              LoadTimeseries(datetime from,datetime to);
   bool              LoadTimeseriesOCL(void);
   bool              test(STR_TEST_RESULT &result,datetime from,datetime to,STR_TEST_PARS &par);
   bool              optimize(STR_TEST_RESULT &result,datetime from,datetime to,STR_OPT_PARS &par);
   void              buffers_free(void);
public:
                     CTestPatterns();
                    ~CTestPatterns();
   //--- launch a single test                    
   bool              Test(STR_TEST_RESULT &result,datetime from,datetime to,STR_TEST_PARS &par);
   //--- launch optimization   
   bool              Optimize(STR_TEST_RESULT &result,datetime from,datetime to,STR_OPT_PARS &par);
   //--- get a pointer to the program execution statistics   
   COCLStat         *GetStat(void){return &m_stat;}
   //--- get the last error code   
   int               GetLastError(void){return m_last_error.code;}
   //--- get the last error structure
   STR_ERROR         GetLastErrorExt(void){return m_last_error;}
   //--- reset the last error  
   void              ResetLastError(void);
   //--- amount of passes the test kernel is divided into
   void              SetTesterPasses(uint tp){m_tester_passes=tp;}
   //--- amount of passes the launch of the order preparation kernel is divided into
   void              SetPrepPasses(int p){m_prepare_passes=p;}
  };
//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CTestPatterns::CTestPatterns() : m_sbuf(NULL),
                                 m_tbuf(NULL),
                                 m_tester_passes(8),
                                 m_prepare_passes(64)
  {

  }
//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CTestPatterns::~CTestPatterns()
  {
   Deinit();
   buffers_free();
  }
//+------------------------------------------------------------------+
//| Remove timeseries buffers                                        |
//+------------------------------------------------------------------+
void CTestPatterns::buffers_free(void)
  {
   if(m_sbuf!=NULL)
     {
      delete m_sbuf;
      m_sbuf=NULL;
     }
   if(m_tbuf!=NULL)
     {
      delete m_tbuf;
      m_tbuf=NULL;
     }
  }
//+------------------------------------------------------------------+
//| Reset the last error                                             |
//+------------------------------------------------------------------+
void CTestPatterns::ResetLastError(void)
  {
   m_last_error.code=0;
   m_last_error.comment="No errors";
   m_last_error.function="";
   m_last_error.line=0;
  }
//+------------------------------------------------------------------+
//| Upload timeseries                                                |
//+------------------------------------------------------------------+
bool CTestPatterns::LoadTimeseries(datetime from,datetime to)
  {
//--- excluding "to" time
   to-=PeriodSeconds(_Period);
//--- pattern search buffer (current chart period)
   if(m_sbuf==NULL)
      m_sbuf= new CBuffering;
//--- upload data
   int res=m_sbuf.Copy(_Symbol,_Period,from,to);
   if(res<0)
     {
      if(res==-1)
         SET_UERRt(UERR_DATA_ACCESS,"Failed to access the current period data");
      else if(res==-2)
         SET_UERRt(UERR_DATA_LOADING,"Failed to upload the current period data");
      return false;
     }
//--- test buffer (M1 period)
   if(m_tbuf==NULL)
      m_tbuf= new CBuffering;
   m_tbuf.SpreadBufEnable(true);
//--- upload data
   res=m_tbuf.Copy(_Symbol,PERIOD_M1,from,to,_Point);
   if(res<0)
     {
      if(res==-1)
         SET_UERRt(UERR_DATA_ACCESS,"Failed to access M1 period data");
      else if(res==-2)
         SET_UERRt(UERR_DATA_LOADING,"Failed to load M1 period data");
      return false;
     }
//--- 
   return true;
  }
//+------------------------------------------------------------------+
//| Public method for launching a single test                        |
//+------------------------------------------------------------------+
bool CTestPatterns::Test(STR_TEST_RESULT &result,datetime from,datetime to,STR_TEST_PARS &par)
  {
   ResetLastError();
   m_stat.Reset();   
   m_stat.time_total.Start();
//--- upload timeseries data   
   m_stat.time_buffering.Start();
   if(LoadTimeseries(from,to)==false)
      return false;
   m_stat.time_buffering.Stop();  
//--- initialize OpenCL
   m_stat.time_ocl_init.Start();
   if(Init(i_MODE_TESTER)==false)
      return false;
   m_stat.time_ocl_init.Stop();
//--- launch the test
   bool res=test(result,from,to,par);
   Deinit();
   buffers_free();
   m_stat.time_total.Stop();
   return res;
  }
//+------------------------------------------------------------------+
//| Single test                                                      |
//+------------------------------------------------------------------+
bool CTestPatterns::test(STR_TEST_RESULT &result,datetime from,datetime to,STR_TEST_PARS &par)
  {
   m_stat.time_ocl_buf.Start();
//--- upload the timeseries to GPU memory
   if(LoadTimeseriesOCL()==false)
      return false;
   m_stat.time_ocl_buf.Stop();
   m_stat.time_ocl_exec.Start();
//--- Step one: find the patterns -------------------------------------------------------------
//--- create the Order buffer: 
   _BufferCreate(buf_ORDER,m_sbuf.Depth*2*sizeof(int),CL_MEM_READ_WRITE);
//--- create the buf_COUNT buffer from the Count buffer
//--- it is intended for intermediate results
   int  count[2]={0,0};
   _BufferFromArray(buf_COUNT,count,0,2,CL_MEM_READ_WRITE);
//--- set the arguments for the k_FIND_PATTERNS kernel
   _SetArgumentBuffer(k_FIND_PATTERNS,0,buf_OPEN);
   _SetArgumentBuffer(k_FIND_PATTERNS,1,buf_HIGH);
   _SetArgumentBuffer(k_FIND_PATTERNS,2,buf_LOW);
   _SetArgumentBuffer(k_FIND_PATTERNS,3,buf_CLOSE);
   _SetArgumentBuffer(k_FIND_PATTERNS,4,buf_ORDER);
   _SetArgumentBuffer(k_FIND_PATTERNS,5,buf_COUNT);
   _SetArgument(k_FIND_PATTERNS,6,double(par.ref)*_Point);
   _SetArgument(k_FIND_PATTERNS,7,par.flags);
//--- k_FIND_PATTERNS kernel task space is one-dimensional
   uint global_size[1];
//--- number of tasks in the first dimension is equal to the number of bars on the current chart
   global_size[0]=m_sbuf.Depth;
//--- initial offset in the tasks space is equal to zero   
   uint work_offset[1]={0};
//--- launch the patterns search kernel execution
   _Execute(k_FIND_PATTERNS,1,work_offset,global_size);
//--- read the number of orders
   _BufferRead(buf_COUNT,count,0,0,2);
//--- Step two: move entry points to M1 chart -------------------------------------------
   m_stat.time_ocl_orders.Start();
//--- create the OrderM1 buffer:
   int len=count[0]*2;
   _BufferCreate(buf_ORDER_M1,len*sizeof(int),CL_MEM_READ_WRITE);
//--- the buf_ORDER_M1 buffer should be filled with "-1" value, use the k_ARRAY_FILL kernel for that
//--- prepare to execute k_ARRAY_FILL, set the arguments:   
   _SetArgumentBuffer(k_ARRAY_FILL,0,buf_ORDER_M1);
   _SetArgument(k_ARRAY_FILL,1,int(-1));
//--- k_ARRAY_FILL kernel task space is one-dimensional
   uint opt_init_work_size[1];
//--- number of tasks in the first dimension is equal to the buffer size   
   opt_init_work_size[0]=len;
//--- initial offset in the tasks space is equal to zero   
   uint opt_init_work_offset[1]={0};
//--- execute the buffer filling kernel
   _Execute(k_ARRAY_FILL,1,opt_init_work_offset,opt_init_work_size);
//--- the k_ORDER_TO_M1 kernel is used to move orders from the current timeframe to M1 one
//--- set the arguments
   _SetArgumentBuffer(k_ORDER_TO_M1,0,buf_TIME);
   _SetArgumentBuffer(k_ORDER_TO_M1,1,buf_TIME_M1);
   _SetArgumentBuffer(k_ORDER_TO_M1,2,buf_ORDER);
   _SetArgumentBuffer(k_ORDER_TO_M1,3,buf_ORDER_M1);
   _SetArgumentBuffer(k_ORDER_TO_M1,4,buf_COUNT);
//--- task space for the k_ORDER_TO_M1 kernel is two-dimensional
   uint global_work_size[2];
//--- the first dimension are orders left by the k_FIND_PATTERNS kernel
   global_work_size[0]=count[0];
//--- the second dimension is comprised of all M1 chart bars
   global_work_size[1]=m_tbuf.Depth;
//--- initial offset in the tasks space for both dimensions is equal to zero
   uint global_work_offset[2]={0,0};
//--- launch the k_ORDER_TO_M1 kernel execution
//--- calculate the maximum offset for М1 bar inside the current period's bar   
   int maxshift=PeriodSeconds()/PeriodSeconds(PERIOD_M1);
   for(int s=0;s<maxshift;s++)
     {
      //--- set the offset for the current pass
      _SetArgument(k_ORDER_TO_M1,5,ulong(s*60));
      //--- execute the kernel
      _Execute(k_ORDER_TO_M1,2,global_work_offset,global_work_size);
      //--- read the results
      _BufferRead(buf_COUNT,count,0,0,2);
      //--- index 0 contains the number of orders on the current chart
      //--- index 1 contains the number of detected appropriate bars on M1 chart
      //--- both values match, exit the loop
      if(count[0]==count[1])
         break;
      //--- otherwise, start the next iteration and launch the kernel with another offset
     }
//--- check if the number of orders is valid once again just in case we have exited the loop not by 'break'
   if(count[0]!=count[1])
     {
      SET_UERRt(UERR_ORDERS_PREPARE,"M1 orders preparation error");
      return false;
     }
   m_stat.time_ocl_orders.Stop();
//--- Step three: launch the test of detected entry points ---------------------------------
//--- create the Tasks buffer where the number of tasks for the next pass is formed
   _BufferCreate(buf_TASKS,m_sbuf.Depth*2*sizeof(int),CL_MEM_READ_WRITE);
//--- create the Result buffer where trade results are stored
   _BufferCreate(buf_RESULT,m_sbuf.Depth*sizeof(double),CL_MEM_READ_WRITE);
//--- set the arguments for the single test kernel   
   _SetArgumentBuffer(k_TESTER_STEP,0,buf_OPEN_M1);
   _SetArgumentBuffer(k_TESTER_STEP,1,buf_HIGH_M1);
   _SetArgumentBuffer(k_TESTER_STEP,2,buf_LOW_M1);
   _SetArgumentBuffer(k_TESTER_STEP,3,buf_CLOSE_M1);
   _SetArgumentBuffer(k_TESTER_STEP,4,buf_SPREAD_M1);
   _SetArgumentBuffer(k_TESTER_STEP,5,buf_TIME_M1);
   _SetArgumentBuffer(k_TESTER_STEP,6,buf_ORDER_M1);
   _SetArgumentBuffer(k_TESTER_STEP,7,buf_TASKS);
   _SetArgumentBuffer(k_TESTER_STEP,8,buf_COUNT);
   _SetArgumentBuffer(k_TESTER_STEP,9,buf_RESULT);
   uint orders_count=count[0];
   _SetArgument(k_TESTER_STEP,11,uint(orders_count));
   _SetArgument(k_TESTER_STEP,14,uint(m_tbuf.Depth-1));
   _SetArgument(k_TESTER_STEP,15, double(par.tp)*_Point);
   _SetArgument(k_TESTER_STEP,16, double(par.sl)*_Point);
   _SetArgument(k_TESTER_STEP,17,ulong(par.timeout));
//--- calculate the maximum M1 period test duration in bars                                                          
   uint maxdepth=(par.timeout/PeriodSeconds(PERIOD_M1))+1;
//--- check the validity of the specified number of test passes   
   if(m_tester_passes<1)
      m_tester_passes=1;
   if(m_tester_passes>maxdepth)
      m_tester_passes=maxdepth;
   uint step_size=maxdepth/m_tester_passes;
//--- k_TESTER_STEP kernel task space is one-dimensional
//--- number of tasks in the first dimension is equal to the number of orders
   global_size[0]=orders_count;
   m_stat.time_ocl_test.Start();
   for(uint i=0;i<m_tester_passes;i++)
     {
      //--- set the current bank index
      _SetArgument(k_TESTER_STEP,10,uint(i&0x01));
      uint start_bar=i*step_size;
      //--- set the index of the bar the test in the current pass starts from
      _SetArgument(k_TESTER_STEP,12,start_bar);
      //--- set the index of the last bar the test is performed at during the current pass
      uint stop_bar=(i==(m_tester_passes-1))?(m_tbuf.Depth-1):(start_bar+step_size-1);
      _SetArgument(k_TESTER_STEP,13,stop_bar);
      //--- reset the number of tasks in the next bank 
      //--- it is to store the number of orders remaining for the next pass
      count[(~i)&0x01]=0;
      _BufferWrite(buf_COUNT,count,0,0,2);
      //--- launch the test kernel
      _Execute(k_TESTER_STEP,1,work_offset,global_size);
      //--- read the number of orders remaining for the next pass
      _BufferRead(buf_COUNT,count,0,0,2);
      //--- set the new number of tasks equal to the number of orders
      global_size[0]=count[(~i)&0x01];
      //--- if no tasks remain, exit the loop
      if(!global_size[0])
         break;
     }
   m_stat.time_ocl_test.Stop();
//--- create the buffer of trade results   
   double Result[];
   ArrayResize(Result,orders_count);
   _BufferRead(buf_RESULT,Result,0,0,orders_count);
   m_stat.time_ocl_exec.Stop();
//--- Step four: calculate the test result -------------------------------------------   
   m_stat.time_proc.Start();
//--- to do this, we should sum up the trade results
   result.trades_total=0;
   result.gross_loss=0;
   result.gross_profit=0;
   result.net_profit=0;
   result.loss_trades=0;
   result.profit_trades=0;
   for(uint i=0;i<orders_count;i++)
     {
      double r=Result[i]/_Point;
      if(r>=0)
        {
         result.gross_profit+=r;
         result.profit_trades++;
           }else{
         result.gross_loss+=r;
         result.loss_trades++;
        }
     }
   result.trades_total=result.loss_trades+result.profit_trades;
   result.net_profit=result.gross_profit+result.gross_loss;
   m_stat.time_proc.Stop();
//---
   return true;
  }
//+------------------------------------------------------------------+
//| Public method for launching optimization                         |
//+------------------------------------------------------------------+
bool CTestPatterns::Optimize(STR_TEST_RESULT &result,datetime from,datetime to,STR_OPT_PARS &par)
  {
   ResetLastError();
   if(par.sl.step<=0 || par.sl.stop<par.sl.start || 
      par.ref.step<=0 || par.ref.stop<par.ref.start)
     {
      SET_UERR(UERR_OPT_PARS,"Optimization parameters are incorrect");
      return false;
     }
   m_stat.Reset();
   m_stat.time_total.Start();
//--- upload timeseries data   
   m_stat.time_buffering.Start();
   if(LoadTimeseries(from,to)==false)
      return false;
   m_stat.time_buffering.Stop();
//--- initialize OpenCL
   m_stat.time_ocl_init.Start();
   if(Init(i_MODE_OPTIMIZER)==false)
      return false;
   m_stat.time_ocl_init.Stop();
//--- launch optimization
   bool res=optimize(result,from,to,par);
   Deinit();
   buffers_free();
   m_stat.time_total.Stop();
   return res;
  }
//+------------------------------------------------------------------+
//| Optimization                                                     |
//+------------------------------------------------------------------+
bool CTestPatterns::optimize(STR_TEST_RESULT &result,datetime from,datetime to,STR_OPT_PARS &par)
  {
   m_stat.time_ocl_buf.Start();
//--- upload the timeseries to GPU memory
   if(LoadTimeseriesOCL()==false)
      return(false);
   m_stat.time_ocl_buf.Stop();
   m_stat.time_ocl_exec.Start();      
//--- Step one: fill in the order array -----------------------------------------------------   
//--- calculate the number of Stop Loss values     
   uint slc=((par.sl.stop-par.sl.start)/par.sl.step)+1;
//--- create the OrderM1 buffer:
   int len=m_sbuf.Depth*4*int(slc);
   _BufferCreate(buf_ORDER_M1,len*sizeof(int),CL_MEM_READ_WRITE);
//--- the buf_ORDER_M1 buffer should be filled with "-1" value, use the k_ARRAY_FILL kernel for that
//--- prepare to execute k_ARRAY_FILL, set the arguments:      
   _SetArgumentBuffer(k_ARRAY_FILL,0,buf_ORDER_M1);
   _SetArgument(k_ARRAY_FILL,1,int(-1));
//--- k_ARRAY_FILL kernel task space is one-dimensional   
   uint opt_init_work_size[1];
//--- number of tasks in the first dimension is equal to the buffer size      
   opt_init_work_size[0]=len;
//--- initial offset in the tasks space is equal to zero    
   uint opt_init_work_offset[1]={0};
//--- execute the buffer filling kernel   
   _Execute(k_ARRAY_FILL,1,opt_init_work_offset,opt_init_work_size);
//--- fill the buffer with orders, two orders (buy and sell) per each bar
//--- this task is assigned to the k_TESTER_OPT_PREPARE kernel
//--- create the Count buffer:
   int count[2]={0,0};
   _BufferFromArray(buf_COUNT,count,0,2,CL_MEM_READ_WRITE);
//--- set the arguments
   _SetArgumentBuffer(k_TESTER_OPT_PREPARE,0,buf_TIME);
   _SetArgumentBuffer(k_TESTER_OPT_PREPARE,1,buf_TIME_M1);
   _SetArgumentBuffer(k_TESTER_OPT_PREPARE,2,buf_ORDER_M1);
   _SetArgumentBuffer(k_TESTER_OPT_PREPARE,3,buf_COUNT);
   _SetArgument(k_TESTER_OPT_PREPARE,4,int(slc)); // number of Stop Loss values
//--- the k_TESTER_OPT_PREPARE kernel will have the two-dimensional task space
   uint global_work_size[2];
//--- 0 dimension - current period orders 
   global_work_size[0]=m_sbuf.Depth;
//--- 1 st dimension - all М1 bars   
   global_work_size[1]=m_tbuf.Depth;
//--- for the first launch, set the offset in the task space to be equal to zero for both dimensions   
   uint global_work_offset[2]={0,0};
   m_stat.time_ocl_orders.Start();
//--- in the process of work, move the offset in the task space for the 1 st dimension
//--- we will get it from the maximum value of the handled index of the minute bar
//--- read in the 1 st count[] array element
   count[1]=0;
   int maxshift=PeriodSeconds()/PeriodSeconds(PERIOD_M1);
   int prep_step=m_sbuf.Depth/m_prepare_passes;
   for(int p=0;p<m_prepare_passes;p++)
     {
      //offset for the current period task space
      global_work_offset[0]=p*prep_step;
      //offset for the M1 period task space
      global_work_offset[1]=count[1];
      //task dimension for the current period
      global_work_size[0]=(p<(m_prepare_passes-1))?prep_step:(m_sbuf.Depth-global_work_offset[0]);
      //task dimension for M1 period
      uint sz=maxshift*global_work_size[0];//there may be LESS (but not more) M1 bars than the calculated value
      //Therefore, it is possible to use the calculated value obtained based on the number of the current bars 
      //multiplied by the ratio of its period to M1 bars   
      uint sz_max=m_tbuf.Depth-global_work_offset[1];
      //make sure not to exceed the buffer size
      global_work_size[1]=(sz>sz_max)?sz_max:sz;
      //
      count[0]=0;
      _BufferWrite(buf_COUNT,count,0,0,2);
      for(int s=0;s<maxshift;s++)
        {
         _SetArgument(k_TESTER_OPT_PREPARE,5,ulong(s*60)); // time shift
         //--- launch the kernel execution
         _Execute(k_TESTER_OPT_PREPARE,2,global_work_offset,global_work_size);
         //--- read the result (number should coincide with global_work_size[0])
         _BufferRead(buf_COUNT,count,0,0,2);
         if(count[0]==global_work_size[0])
            break;
        }
      count[1]++;
     }
   m_stat.time_ocl_orders.Stop();
   if(count[0]!=global_work_size[0])
     {
      SET_UERRt(UERR_ORDERS_PREPARE,"M1 orders preparation error");
      return false;
     }
//--- Step two: launch calculation of trade results by orders -------------------------------
//--- Tasks buffer:
   len=m_sbuf.Depth*4*int(slc)*sizeof(int);
   _BufferCreate(buf_TASKS,len,CL_MEM_READ_WRITE);
//--- Result buffer:
   _BufferCreate(buf_RESULT,m_sbuf.Depth*2*slc*sizeof(double),CL_MEM_READ_WRITE);
//--- set the buffers as arguments   
   _SetArgumentBuffer(k_TESTER_OPT_STEP,0,buf_OPEN_M1);
   _SetArgumentBuffer(k_TESTER_OPT_STEP,1,buf_HIGH_M1);
   _SetArgumentBuffer(k_TESTER_OPT_STEP,2,buf_LOW_M1);
   _SetArgumentBuffer(k_TESTER_OPT_STEP,3,buf_CLOSE_M1);
   _SetArgumentBuffer(k_TESTER_OPT_STEP,4,buf_SPREAD_M1);
   _SetArgumentBuffer(k_TESTER_OPT_STEP,5,buf_TIME_M1);
   _SetArgumentBuffer(k_TESTER_OPT_STEP,6,buf_ORDER_M1);
   _SetArgumentBuffer(k_TESTER_OPT_STEP,7,buf_TASKS);
   _SetArgumentBuffer(k_TESTER_OPT_STEP,8,buf_COUNT);
   _SetArgumentBuffer(k_TESTER_OPT_STEP,9,buf_RESULT);
//--- number of generated orders
   uint orders_count=m_sbuf.Depth*2*slc;//each bar has two orders (buy and sell) for each SL value
//--- set the arguments   
   _SetArgument(k_TESTER_OPT_STEP,11, uint(orders_count));
   _SetArgument(k_TESTER_OPT_STEP,14, uint(m_tbuf.Depth-1));                                                            
   _SetArgument(k_TESTER_OPT_STEP,15, double(par.tp)*_Point);
   _SetArgument(k_TESTER_OPT_STEP,16, par.sl.start);
   _SetArgument(k_TESTER_OPT_STEP,17, par.sl.step);
   _SetArgument(k_TESTER_OPT_STEP,18, ulong(par.timeout));
   _SetArgument(k_TESTER_OPT_STEP,19, _Point);
//--- get the number of bars corresponding to the maximum holding time of an open position                                                            
   uint maxdepth=(par.timeout/PeriodSeconds(PERIOD_M1))+1;
   m_stat.time_ocl_test.Start();
   if(m_tester_passes<1)
      m_tester_passes=1;
   if(m_tester_passes>maxdepth)
      m_tester_passes=maxdepth;
   uint step_size=maxdepth/m_tester_passes;
   uint work_offset[1]={0};
   uint global_size[1];
   global_size[0]=orders_count;
   for(uint i=0;i<m_tester_passes;i++)
     {
      _SetArgument(k_TESTER_OPT_STEP,10,uint(i&0x01));// bank index
      uint start_bar=i*step_size;
      _SetArgument(k_TESTER_OPT_STEP,12,start_bar); 
      uint stop_bar=(i==(m_tester_passes-1))?(m_tbuf.Depth-1):(start_bar+step_size-1);
      _SetArgument(k_TESTER_OPT_STEP,13,stop_bar);
      //--- reset the next bank where the number of tasks for the next time is formed
      count[(~i)&0x01]=0;
      _BufferWrite(buf_COUNT,count,0,0,2);
      //--- launch the kernel execution
      _Execute(k_TESTER_OPT_STEP,1,work_offset,global_size);
      _BufferRead(buf_COUNT,count,0,0,2);
      global_size[0]=count[(~i)&0x01];
      if(!global_size[0])
         break;
     }
   m_stat.time_ocl_test.Stop();
//--- Step three: look for patterns and read optimization results -------------------------------
//--- calculate the number of reference values     
   uint refc=((par.ref.stop-par.ref.start)/par.ref.step)+1;
//--- OptResults buffer:
   int OptResults[];
   len=int(slc*refc*4);  // 4 values per each ref and sl combination
   if(ArrayResize(OptResults,len)<len)
      return(false);
   ArrayFill(OptResults,0,len,0);
   _BufferFromArray(buf_OPT_RESULTS,OptResults,0,len,CL_MEM_READ_WRITE);
//--- set the buffers as arguments
   _SetArgumentBuffer(k_FIND_PATTERNS_OPT,0,buf_OPEN);
   _SetArgumentBuffer(k_FIND_PATTERNS_OPT,1,buf_HIGH);
   _SetArgumentBuffer(k_FIND_PATTERNS_OPT,2,buf_LOW);
   _SetArgumentBuffer(k_FIND_PATTERNS_OPT,3,buf_CLOSE);
   _SetArgumentBuffer(k_FIND_PATTERNS_OPT,4,buf_RESULT);
   _SetArgumentBuffer(k_FIND_PATTERNS_OPT,5,buf_OPT_RESULTS);
//--- set the arguments
   double ref_start=double(par.ref.start)*_Point;
   _SetArgument(k_FIND_PATTERNS_OPT,6,ref_start);
   double ref_step=double(par.ref.step)*_Point;
   _SetArgument(k_FIND_PATTERNS_OPT,7, ref_step);
   _SetArgument(k_FIND_PATTERNS_OPT,8, par.flags);
   double pc=_Point/100;
   _SetArgument(k_FIND_PATTERNS_OPT,9,pc);
//--- the find_patterns_opt() kernel works in a three-dimensional task space
   uint global_work_size3[3];
//--- 0 dimension - current period bars
   global_work_size3[0]=m_sbuf.Depth;
//--- 1 st dimension - reference values
   global_work_size3[1]=refc;
//--- 2 nd dimension - Stop Loss values   
   global_work_size3[2]=slc;
//--- offset in the tasks space is equal to zero for all dimensions   
   uint global_work_offset3[3]={0,0,0};
//--- launch the kernel execution
   _Execute(k_FIND_PATTERNS_OPT,3,global_work_offset3,global_work_size3);
   _BufferRead(buf_OPT_RESULTS,OptResults,0,0,len);
//--- test results for each ref and SL combinations are stored in the OptResult buffer
   m_stat.time_ocl_exec.Stop();
//--- Step four: look for the maximum net profit -----------------------------
   m_stat.time_proc.Start();   
   int max_profit=-2147483648;
   uint idx_ref_best= 0;
   uint idx_sl_best = 0;
   for(uint i=0;i<refc;i++)
      for(uint j=0;j<slc;j++)
        {
         uint idx=j*refc*4+i*4;
         int profit=OptResults[idx]+OptResults[idx+1];
         if(max_profit<profit)
           {
            max_profit=profit;
            idx_ref_best= i;
            idx_sl_best = j;
           }
        }
//--- set the values to the test results structure        
   uint idx=idx_sl_best*refc*4+idx_ref_best*4;
   result.gross_profit=double(OptResults[idx])/100;
   result.gross_loss=double(OptResults[idx+1])/100;
   result.profit_trades=OptResults[idx+2];
   result.loss_trades=OptResults[idx+3];
   result.trades_total=result.loss_trades+result.profit_trades;
   result.net_profit=result.gross_profit+result.gross_loss;
//--- set the desired values of the optimized parameters
   par.ref.value= int(par.ref.start+idx_ref_best*par.ref.step);
   par.sl.value = int(par.sl.start+idx_sl_best*par.sl.step);
   m_stat.time_proc.Stop();
   return true;
  }
//+------------------------------------------------------------------+
//| Upload the timeseries buffers to the OpenCL buffers              |
//+------------------------------------------------------------------+
bool CTestPatterns::LoadTimeseriesOCL()
  {
//--- Open buffer:
   _BufferFromArray(buf_OPEN,m_sbuf.Open,0,m_sbuf.Depth,CL_MEM_READ_ONLY);
//--- High buffer:
   _BufferFromArray(buf_HIGH,m_sbuf.High,0,m_sbuf.Depth,CL_MEM_READ_ONLY);
//--- Low buffer:
   _BufferFromArray(buf_LOW,m_sbuf.Low,0,m_sbuf.Depth,CL_MEM_READ_ONLY);
//--- Close buffer:
   _BufferFromArray(buf_CLOSE,m_sbuf.Close,0,m_sbuf.Depth,CL_MEM_READ_ONLY);
//--- Time buffer:
   _BufferFromArray(buf_TIME,m_sbuf.Time,0,m_sbuf.Depth,CL_MEM_READ_ONLY);
//--- Open (M1) buffer:
   _BufferFromArray(buf_OPEN_M1,m_tbuf.Open,0,m_tbuf.Depth,CL_MEM_READ_ONLY);
//--- High (M1) buffer:
   _BufferFromArray(buf_HIGH_M1,m_tbuf.High,0,m_tbuf.Depth,CL_MEM_READ_ONLY);
//--- Low (M1) buffer:
   _BufferFromArray(buf_LOW_M1,m_tbuf.Low,0,m_tbuf.Depth,CL_MEM_READ_ONLY);
//--- Close (M1) buffer:
   _BufferFromArray(buf_CLOSE_M1,m_tbuf.Close,0,m_tbuf.Depth,CL_MEM_READ_ONLY);
//--- Spread (M1) buffer:
   _BufferFromArray(buf_SPREAD_M1,m_tbuf.Spread,0,m_tbuf.Depth,CL_MEM_READ_ONLY);
//--- Time (M1) buffer:
   _BufferFromArray(buf_TIME_M1,m_tbuf.Time,0,m_tbuf.Depth,CL_MEM_READ_ONLY);
//--- copying successful
   return true;
  }
//+------------------------------------------------------------------+
