//+------------------------------------------------------------------+
//|                                                 MA_Crossover.mqh |
//|                                                      @softreform |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "@softreform"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

#include <SoftFramework/Framework.mqh>

//Input Section
input double                  InpVolume              = 0.1;        // Default order size
input string                  InpComment             = __FILE__;   //Default trade comment
input int                     InpMagicNumber         = 20201018;   // Magic Number
// Fast moving average
input int                     InpFastPeriods         = 10;         // Fast period
input ENUM_MA_METHOD          InpFastMethod          = MODE_SMA;   // Fast method
input ENUM_APPLIED_PRICE      InpFastAppliedPrice    = PRICE_CLOSE;// Fast price

// Slow moving average
input int                     InpSlowPeriods         = 20;         // Slow period
input ENUM_MA_METHOD          InpSlowMethod          = MODE_SMA;   // Slow method
input ENUM_APPLIED_PRICE      InpSlowAppliedPrice    = PRICE_CLOSE;// Slow price

#define         CExpert   CExpertBase
CExpert         *Expert;

// Signals, use the child class name if applicable
CSignalBase     *EntrySignal;
CSignalBase     *ExitSignal;

// Indicators
CIndicatorMA    *FastIndicator;
CIndicatorMA    *SlowIndicator;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit() {
  //--- create timer
  //EventSetTimer(60);

  Expert     = new CExpert;


  Expert.SetVolume(InpVolume);
  Expert.SetTradeComment(InpComment);
  Expert.SetMagic(InpMagicNumber);

  // Set up the indicators
  FastIndicator = new CIndicatorMA(InpFastPeriods, 0, InpFastMethod, InpFastAppliedPrice);
  SlowIndicator = new CIndicatorMA(InpSlowPeriods, 0, InpSlowMethod, InpSlowAppliedPrice);

  // Set up the signals
  EntrySignal   = new CSignalCrossover();
  EntrySignal.AddIndicator(FastIndicator, 0);
  EntrySignal.AddIndicator(SlowIndicator, 0);

  // ExitSignal    = new CSignalCrossover();
  // ExitSignal.AddIndicator(FastIndicator, 0);
  // ExitSignal.AddIndicator(SlowIndicator, 0);

  // Add the signals to the exper
  Expert.AddEntrySignal(EntrySignal);
  Expert.AddExitSignal(EntrySignal);  // Same signal

  int  result  = Expert.OnInit();
  //---
  return(result);

}
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//--- destroy timer
   EventKillTimer();
   
   delete   Expert;
   //delete   ExitSignal;
   delete   EntrySignal;
   delete   FastIndicator;
   delete   SlowIndicator;

   return;
   
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
    Expert.OnTick();
    return;
  }
//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer()
  {
//---
    Expert.OnTimer();
    return;
  }
//+------------------------------------------------------------------+
//| Trade function                                                   |
//+------------------------------------------------------------------+
void OnTrade()
  {
//---
    Expert.OnTrade();
    return;
  }
//+------------------------------------------------------------------+
//| TradeTransaction function                                        |
//+------------------------------------------------------------------+
void OnTradeTransaction(const MqlTradeTransaction& trans,
                        const MqlTradeRequest& request,
                        const MqlTradeResult& result)
  {
//---
    Expert.OnTradeTransaction(trans, request, result); 
    return;
  }
//+------------------------------------------------------------------+
//| Tester function                                                  |
//+------------------------------------------------------------------+
double OnTester()
  {
//---
   double ret=0.0;

   return(Expert.OnTester());
  }
//+------------------------------------------------------------------+
//| TesterInit function                                              |
//+------------------------------------------------------------------+
void OnTesterInit()
  {
    Expert.OnTesterInit();
    return;
  }
//+------------------------------------------------------------------+
//| TesterPass function                                              |
//+------------------------------------------------------------------+
void OnTesterPass()
  {
//---
    Expert.OnTesterPass(); 
    return; 
  }
//+------------------------------------------------------------------+
//| TesterDeinit function                                            |
//+------------------------------------------------------------------+
void OnTesterDeinit()
  {
//---
    Expert.OnTesterDeinit();   
    return;
  }
//+------------------------------------------------------------------+
//| ChartEvent function                                              |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,
                  const long& lparam,
                  const double& dparam,
                  const string& sparam)
  {
//---
    Expert.OnChartEvent(id, lparam, dparam, sparam); 
    return;  
  }
//+------------------------------------------------------------------+
//| BookEvent function                                               |
//+------------------------------------------------------------------+
void OnBookEvent(const string& symbol)
  {
//---
    Expert.OnBookEvent(); 
    return;
  }
//+------------------------------------------------------------------+