//+------------------------------------------------------------------+
//|                                                  example_opt.mq5 |
//|                                  Copyright 2018, Serhii Shevchuk |
//|                           https://www.mql5.com/en/users/decanium |
//+------------------------------------------------------------------+
#property copyright "Copyright 2018, Serhii Shevchuk"
#property link      "https://www.mql5.com/en/users/decanium"
#property version   "1.00"

#include <OCL_Patterns\TestPatternsOCL.mqh>

CTestPatterns tpat;
//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart()
  {
   datetime from=D'2018.01.01 00:00';
   datetime to=D'2018.10.01 00:00';
//--- set optimization parameters
   STR_OPT_PARS optpar;
   optpar.ref.start = 15;
   optpar.ref.step  = 5;
   optpar.ref.stop  = 510;
   optpar.sl.start = 15;
   optpar.sl.step  = 5;
   optpar.sl.stop  = 510;
   optpar.flags=15;
   optpar.tp=50;
   optpar.timeout=12*3600;
//--- results structure
   STR_TEST_RESULT res;
//--- launch optimization
   tpat.Optimize(res,from,to,optpar);
   STR_ERROR oclerr=tpat.GetLastErrorExt();
   if(oclerr.code)
     {
      Print(oclerr.comment);
      Print("code = ",oclerr.code,", function = ",oclerr.function,", line = ",oclerr.line);
      return;
     }
//--- values of the optimized parameters
   Print("Ref: ",optpar.ref.value,", SL: ",optpar.sl.value);
//--- test results  
   Print("Net Profit: ",   res.net_profit);
   Print("Gross Profit: ", res.gross_profit);
   Print("Gross Loss: ",   res.gross_loss);
   Print("Trades Total: ", res.trades_total);
   Print("Profit Trades: ",res.profit_trades);
   Print("Loss Trades: ",  res.loss_trades);
//--- execution statistics
   COCLStat ocl_stat=tpat.GetStat();
   Print("GPU memory size: ",       ocl_stat.gpu_mem_size.ToStr());
   Print("GPU memory usage: ",      ocl_stat.gpu_mem_usage.ToStr());
   Print("Buffering: ",             ocl_stat.time_buffering.ToStr());
   Print("OpenCL init: ",           ocl_stat.time_ocl_init.ToStr());
   Print("OpenCL buffering: ",      ocl_stat.time_ocl_buf.ToStr());
   Print("OpenCL prepare orders: ", ocl_stat.time_ocl_orders.ToStr());
   Print("OpenCL test: ",           ocl_stat.time_ocl_test.ToStr());
   Print("OpenCL total execution: ",ocl_stat.time_ocl_exec.ToStr());
   Print("Post-processing: ",       ocl_stat.time_proc.ToStr());
   Print("Total: ",                 ocl_stat.time_total.ToStr());
  }
//+------------------------------------------------------------------+
