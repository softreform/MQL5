//+------------------------------------------------------------------+
//|                                              EA_Template_1.0.mqh |
//|                                                      @softreform |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "@softreform"
#property link      "https://www.mql5.com"
#property version   "1.00"

#include <SoftFramework/Framework_1.0.mqh>

//Input Sevtion
input double    InpVolume         = 0.1;        // Default order size
input string    InpComment        = __FILE__;   //Default trade comment
input int       InpMagicNumber    = 20201003;   // Magic Number

#define         CExpert   CExpertBase
CExpert         *Expert;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- create timer
   EventSetTimer(60);

   Expert     = new CExpert;


   Expert.SetVolume(InpVolume);
   Expert.SetTradeComment(InpComment);
   Expert.SetMagic(InpMagicNumber);

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
    Expert.OnBookEvent(symbol); 
    return;
  }
//+------------------------------------------------------------------+