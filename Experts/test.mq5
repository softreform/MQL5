//+------------------------------------------------------------------+
//|                                                   expChannel.mq5 |
//|                                                            @nick |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "@nick"
#property link      "https://www.mql5.com"
#property version   "1.00"
//+------------------------------------------------------------------+
//| Include                                                          |
//+------------------------------------------------------------------+
#include <Expert\Expert.mqh>
//--- available signals
#include <Expert\Signal\MySignals\SignalChannel.mqh>
//--- available trailing
#include <Expert\Trailing\TrailingNone.mqh>
//--- available money management
#include <Expert\Money\MoneyFixedLot.mqh>
//+------------------------------------------------------------------+
//| Inputs                                                           |
//+------------------------------------------------------------------+
//--- inputs for expert
input string             Expert_Title         ="expChannel"; // Document name
ulong                    Expert_MagicNumber   =16084;        //
bool                     Expert_EveryTick     =false;        //
//--- inputs for main signal
input int                Signal_ThresholdOpen =10;           // Signal threshold value to open [0...100]
input int                Signal_ThresholdClose=10;           // Signal threshold value to close [0...100]
input double             Signal_PriceLevel    =0.0;          // Price level to execute a deal
input double             Signal_StopLevel     =50.0;         // Stop Loss level (in points)
input double             Signal_TakeLevel     =50.0;         // Take Profit level (in points)
input int                Signal_Expiration    =4;            // Expiration of pending orders (in bars)
input int                Signal__PeriodMA     =12;           // SignalChannel(12,0,MODE_EMA,...)
input int                Signal__ShiftMA      =0;            // SignalChannel(12,0,MODE_EMA,...)
input ENUM_MA_METHOD     Signal__MethodMA     =MODE_EMA;     // SignalChannel(12,0,MODE_EMA,...)
input ENUM_APPLIED_PRICE Signal__AppliedMA    =PRICE_CLOSE;  // SignalChannel(12,0,MODE_EMA,...)
input double             Signal__Limit        =0.0;          // SignalChannel(12,0,MODE_EMA,...)
input double             Signal__StopLoss     =50.0;         // SignalChannel(12,0,MODE_EMA,...)
input double             Signal__TakeProfit   =50.0;         // SignalChannel(12,0,MODE_EMA,...)
input int                Signal__Expiration   =10;           // SignalChannel(12,0,MODE_EMA,...)
input double             Signal__Weight       =1.0;          // SignalChannel(12,0,MODE_EMA,...) Weight [0...1.0]
//--- inputs for money
input double             Money_FixLot_Percent =100.0;        // Percent
input double             Money_FixLot_Lots    =0.1;          // Fixed volume
//+------------------------------------------------------------------+
//| Global expert object                                             |
//+------------------------------------------------------------------+
CExpert ExtExpert;
//+------------------------------------------------------------------+
//| Initialization function of the expert                            |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- Initializing expert
   if(!ExtExpert.Init(Symbol(),Period(),Expert_EveryTick,Expert_MagicNumber))
     {
      //--- failed
      printf(__FUNCTION__+": error initializing expert");
      ExtExpert.Deinit();
      return(INIT_FAILED);
     }
//--- Creating signal
   CExpertSignal *signal=new CExpertSignal;
   if(signal==NULL)
     {
      //--- failed
      printf(__FUNCTION__+": error creating signal");
      ExtExpert.Deinit();
      return(INIT_FAILED);
     }
//---
   ExtExpert.InitSignal(signal);
   signal.ThresholdOpen(Signal_ThresholdOpen);
   signal.ThresholdClose(Signal_ThresholdClose);
   signal.PriceLevel(Signal_PriceLevel);
   signal.StopLevel(Signal_StopLevel);
   signal.TakeLevel(Signal_TakeLevel);
   signal.Expiration(Signal_Expiration);
//--- Creating filter CSiChannel
   CSiChannel *filter0=new CSiChannel;
   if(filter0==NULL)
     {
      //--- failed
      printf(__FUNCTION__+": error creating filter0");
      ExtExpert.Deinit();
      return(INIT_FAILED);
     }
   signal.AddFilter(filter0);
//--- Set filter parameters
   filter0.PeriodMA(Signal__PeriodMA);
   filter0.ShiftMA(Signal__ShiftMA);
   filter0.MethodMA(Signal__MethodMA);
   filter0.AppliedMA(Signal__AppliedMA);
   filter0.Limit(Signal__Limit);
   filter0.StopLoss(Signal__StopLoss);
   filter0.TakeProfit(Signal__TakeProfit);
   filter0.Expiration(Signal__Expiration);
   filter0.Weight(Signal__Weight);
//--- Creation of trailing object
   CTrailingNone *trailing=new CTrailingNone;
   if(trailing==NULL)
     {
      //--- failed
      printf(__FUNCTION__+": error creating trailing");
      ExtExpert.Deinit();
      return(INIT_FAILED);
     }
//--- Add trailing to expert (will be deleted automatically))
   if(!ExtExpert.InitTrailing(trailing))
     {
      //--- failed
      printf(__FUNCTION__+": error initializing trailing");
      ExtExpert.Deinit();
      return(INIT_FAILED);
     }
//--- Set trailing parameters
//--- Creation of money object
   CMoneyFixedLot *money=new CMoneyFixedLot;
   if(money==NULL)
     {
      //--- failed
      printf(__FUNCTION__+": error creating money");
      ExtExpert.Deinit();
      return(INIT_FAILED);
     }
//--- Add money to expert (will be deleted automatically))
   if(!ExtExpert.InitMoney(money))
     {
      //--- failed
      printf(__FUNCTION__+": error initializing money");
      ExtExpert.Deinit();
      return(INIT_FAILED);
     }
//--- Set money parameters
   money.Percent(Money_FixLot_Percent);
   money.Lots(Money_FixLot_Lots);
//--- Check all trading objects parameters
   if(!ExtExpert.ValidationSettings())
     {
      //--- failed
      ExtExpert.Deinit();
      return(INIT_FAILED);
     }
//--- Tuning of all necessary indicators
   if(!ExtExpert.InitIndicators())
     {
      //--- failed
      printf(__FUNCTION__+": error initializing indicators");
      ExtExpert.Deinit();
      return(INIT_FAILED);
     }
//--- ok
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Deinitialization function of the expert                          |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   ExtExpert.Deinit();
  }
//+------------------------------------------------------------------+
//| "Tick" event handler function                                    |
//+------------------------------------------------------------------+
void OnTick()
  {
   ExtExpert.OnTick();
  }
//+------------------------------------------------------------------+
//| "Trade" event handler function                                   |
//+------------------------------------------------------------------+
void OnTrade()
  {
   ExtExpert.OnTrade();
  }
//+------------------------------------------------------------------+
//| "Timer" event handler function                                   |
//+------------------------------------------------------------------+
void OnTimer()
  {
   ExtExpert.OnTimer();
  }
//+------------------------------------------------------------------+
