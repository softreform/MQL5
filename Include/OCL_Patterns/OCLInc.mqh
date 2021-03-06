//+------------------------------------------------------------------+
//|                                                       OCLInc.mqh |
//|                                  Copyright 2018, Serhii Shevchuk |
//|                           https://www.mql5.com/en/users/decanium |
//+------------------------------------------------------------------+
#property copyright "Copyright 2018, Serhii Shevchuk"
#property link      "https://www.mql5.com/en/users/decanium"

//--- kernels' source codes
#resource "OCL/tester.cl" as string cl_tester
//--- kernels' IDs
enum ENUM_KERNELS
  {
   k_FIND_PATTERNS=0,
   k_ORDER_TO_M1,
   k_ARRAY_FILL,
   k_TESTER_STEP,
   k_TESTER_OPT_STEP,
   k_TESTER_OPT_PREPARE,
   k_FIND_PATTERNS_OPT,
   //
   OCL_KERNELS_COUNT
  };
//--- buffers' IDs
enum ENUM_BUFFERS
  {
   buf_OPEN=0,
   buf_HIGH,
   buf_LOW,
   buf_CLOSE,
   buf_TIME,
   buf_ORDER,
   buf_OPEN_M1,
   buf_HIGH_M1,
   buf_LOW_M1,
   buf_CLOSE_M1,
   buf_SPREAD_M1,
   buf_TIME_M1,
   buf_ORDER_M1,
   buf_COUNT,
   buf_TASKS,
   buf_LEFT,
   buf_RESULT,
   buf_OPT_RESULTS,
   //
   OCL_BUFFERS_COUNT
  };
//+------------------------------------------------------------------+
