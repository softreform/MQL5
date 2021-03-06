//+------------------------------------------------------------------+
//|                                                 RevPatTrader.mq5 |
//|                                  Copyright 2018, Serhii Shevchuk |
//|                           https://www.mql5.com/en/users/decanium |
//+------------------------------------------------------------------+
#property copyright "Copyright 2018, Serhii Shevchuk"
#property link      "https://www.mql5.com/en/users/decanium"
#property version   "1.00"

#include <OCL_Patterns\RevPatterns.mqh>
#include <Trade\Trade.mqh>
#include <OCL_Patterns\Duration.mqh>
//--- input parameters
input int      inp_ref=50;
input int      inp_tp=500;
input int      inp_sl=500;
input int      inp_timeout=5;
input bool     inp_bullish_pin_bar = true;
input bool     inp_bearish_pin_bar = true;
input bool     inp_bullish_engulfing = true;
input bool     inp_bearish_engulfing = true;
input double   inp_lot_size=1;
//--- trading class
CTrade trade;
//--- class for working with the duration between reference points
CDuration time;
//--- pattern flags
uint p_flags;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   time.Start();
   p_flags=0;
   if(inp_bullish_pin_bar==true)
      p_flags|=PAT_PINBAR_BULLISH;
   if(inp_bearish_pin_bar==true)
      p_flags|=PAT_PINBAR_BEARISH;
   if(inp_bullish_engulfing==true)
      p_flags|=PAT_ENGULFING_BULLISH;
   if(inp_bearish_engulfing==true)
      p_flags|=PAT_ENGULFING_BEARISH;
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   time.Stop();
   Print("Test lasted "+time.ToStr());
  }
//+------------------------------------------------------------------+
//| Check for a new bar                                              |
//+------------------------------------------------------------------+
bool IsNewBar(void)
  {
   static datetime tprev=0;
   datetime tcur=iTime(_Symbol,_Period,0);
   if(tprev!=tcur)
     {
      tprev=tcur;
      return true;
     }
   else
      return false;
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//--- handle open positions
   int total= PositionsTotal();
   for(int i=0;i<total;i++)
     {
      PositionSelect(_Symbol);
      datetime t0=datetime(PositionGetInteger(POSITION_TIME));
      if(TimeCurrent()>=(t0+(inp_timeout*3600)))
        {
         trade.PositionClose(PositionGetInteger(POSITION_TICKET));
        }
      else
         break;
     }
   if(IsNewBar()==false)
      return;
//--- check if the pattern is present
   ENUM_PATTERN pat=IsPattern(p_flags,inp_ref);
   if(pat==PAT_NONE)
      return;
//--- open positions
   double ask=SymbolInfoDouble(_Symbol,SYMBOL_ASK);
   double bid=SymbolInfoDouble(_Symbol,SYMBOL_BID);
   if((pat&(PAT_ENGULFING_BULLISH|PAT_PINBAR_BULLISH))!=0)//buy     
      trade.Buy(inp_lot_size,_Symbol,ask,NormalizeDouble(ask-inp_sl*_Point,_Digits),NormalizeDouble(ask+inp_tp*_Point,_Digits),DoubleToString(ask,_Digits));
   else//sell
   trade.Sell(inp_lot_size,_Symbol,bid,NormalizeDouble(bid+inp_sl*_Point,_Digits),NormalizeDouble(bid-inp_tp*_Point,_Digits),DoubleToString(bid,_Digits));
  }
//+------------------------------------------------------------------+
