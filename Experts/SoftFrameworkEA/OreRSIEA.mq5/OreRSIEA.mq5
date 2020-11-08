//+------------------------------------------------------------------+
//|                                                   Ore RSI EA.mqh |
//|                                                      @softreform |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "@softreform"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

#include <SoftFramework/Framework.mqh>

//Input Section
input int                 InpPeriods             = 14;           // RSI periods 
input ENUM_APPLIED_PRICE  InpAppliedPrice        = PRICE_CLOSE; // Applied price
input double              InpSellLevel           = 90.0;         // Sell at RSI Level
input double              InpBuyLevel            = 10.0;         // Buy at  RSI Level
// For simple point based TPSL
input int                 InpTPPoints            = 100;          // Take profit points
input int                 InpSLPoints            = 100;          // Stop loss point
// Some standard inputs, 
// remember to change the default magic for each EA
input double              InpVolume              = 0.1;          // Default order size
input string              InpComment             = __FILE__;     //Default trade comment
input int                 InpMagicNumber         = 20201024;     // Magic Number

#define         CExpert   CExpertBase
CExpert         *Expert;

// Signals, use the child class name if applicable
OreCSignalRSI*      EntrySignal;

// TPSL - use child class name
// CTPSLSimple     *TPSL;

// Indicators
OreCIndicatorRSI*   RSIIndicator;

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
  RSIIndicator = new OreCIndicatorRSI(InpPeriods, InpAppliedPrice);

  // Set up the signals
  EntrySignal   = new OreCSignalRSI(InpBuyLevel, InpSellLevel);
  EntrySignal.AddIndicator(RSIIndicator, 0);


  // ExitSignal    = new CSignalRSI();
  // ExitSignal.AddIndicator(FastIndicator, 0);
  // ExitSignal.AddIndicator(SlowIndicator, 0);

  // Add the signals to the exper
  Expert.AddEntrySignal(EntrySignal);

  // Set the tp and sl
  Expert.SetTakeProfitValue(InpTPPoints);
  Expert.SetStopLossValue(InpSLPoints);

  int  result  = Expert.OnInit();
  //---
  return(INIT_SUCCEEDED);

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
   
   delete   RSIIndicator;

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
//void OnTesterInit()
//  {
//    Expert.OnTesterInit();
//    return;
//  }
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