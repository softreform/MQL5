//+------------------------------------------------------------------+
//|                                                      OCLStat.mqh |
//|                                  Copyright 2018, Serhii Shevchuk |
//|                           https://www.mql5.com/en/users/decanium |
//+------------------------------------------------------------------+
#property copyright "Copyright 2018, Serhii Shevchuk"
#property link      "https://www.mql5.com/en/users/decanium"
#property version   "1.00"

#include "Duration.mqh"
#include "Memsize.mqh"

//+------------------------------------------------------------------+
//| Execution statistics - time and memory volume                    |
//+------------------------------------------------------------------+
class COCLStat
  {
public:
                     COCLStat();
                    ~COCLStat();
   CMemsize          gpu_mem_size;     // available GPU memory
   CMemsize          gpu_mem_usage;    // used GPU memory
   CDuration         time_buffering;   // timeseries data upload duration
   CDuration         time_ocl_init;    // OpenCL initialization duration
   CDuration         time_ocl_buf;     // duration of OpenCL buffers preparation
   CDuration         time_ocl_orders;  // duration of orders preparation
   CDuration         time_ocl_exec;    // duration of kernels preparation
   CDuration         time_ocl_test;    // duration of testing kernel execution   
   CDuration         time_proc;        // results handling duration
   CDuration         time_total;       // total time spent        
   void              Reset(void);            
  };
//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
COCLStat::COCLStat()
  {
  }
//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
COCLStat::~COCLStat()
  {
  }

void COCLStat::Reset(void)  
{
   gpu_mem_size = 0;
   gpu_mem_usage = 0;
   time_buffering.Reset();
   time_ocl_init.Reset();
   time_ocl_buf.Reset();
   time_ocl_orders.Reset();
   time_ocl_exec.Reset();
   time_ocl_test.Reset();
   time_proc.Reset();
   time_total.Reset();
}
//+------------------------------------------------------------------+
