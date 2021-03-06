//+------------------------------------------------------------------+
//|                                                  RevPatterns.mqh |
//|                                  Copyright 2018, Serhii Shevchuk |
//|                           https://www.mql5.com/en/users/decanium |
//+------------------------------------------------------------------+
#property copyright "Copyright 2018, Serhii Shevchuk"
#property link      "https://www.mql5.com/en/users/decanium"
//+------------------------------------------------------------------+
//| defines                                                          |
//+------------------------------------------------------------------+
#define PBARS  3//number of bars in the pattern
#define O(i) (r[i].open)
#define H(i) (r[i].high)
#define L(i) (r[i].low)
#define C(i) (r[i].close)
//+------------------------------------------------------------------+
//| Pattern flags                                                    |
//+------------------------------------------------------------------+
enum ENUM_PATTERN
  {
   PAT_NONE=0,
   PAT_PINBAR_BEARISH = (1<<0),
   PAT_PINBAR_BULLISH = (1<<1),
   PAT_ENGULFING_BEARISH = (1<<2),
   PAT_ENGULFING_BULLISH = (1<<3)
  };
//+------------------------------------------------------------------+
//| Upload data and check if the patterns are present                |
//+------------------------------------------------------------------+
ENUM_PATTERN IsPattern(uint flags,uint ref)
  {
   MqlRates r[];
   if(CopyRates(_Symbol,_Period,1,PBARS,r)<PBARS)
      return 0;
   ArraySetAsSeries(r,false);
   return Check(r,flags,double(ref)*_Point);
  }
//+------------------------------------------------------------------+
//| Check if the patterns are present                                |
//+------------------------------------------------------------------+
ENUM_PATTERN Check(MqlRates &r[],uint flags,double ref)
  {
//--- bearish pin bar  
   if((flags&PAT_PINBAR_BEARISH)!=0)
     {//
      double tail=H(1)-MathMax(O(1),C(1));
      if(tail>=ref && C(0)>O(0) && O(2)>C(2) && H(1)>MathMax(H(0),H(2)) && MathAbs(O(1)-C(1))<tail)
         return PAT_PINBAR_BEARISH;
     }
//--- bullish pin bar
   if((flags&PAT_PINBAR_BULLISH)!=0)
     {//
      double tail=MathMin(O(1),C(1))-L(1);
      if(tail>=ref && O(0)>C(0) && C(2)>O(2) && L(1)<MathMin(L(0),L(2)) && MathAbs(O(1)-C(1))<tail)
         return PAT_PINBAR_BULLISH;
     }
//--- bearish engulfing
   if((flags&PAT_ENGULFING_BEARISH)!=0)
     {//
      if((C(1)-O(1))>=ref && H(0)<C(1) && O(2)>C(1) && C(2)<O(1))
         return PAT_ENGULFING_BEARISH;
     }
//--- bullish engulfing
   if((flags&PAT_ENGULFING_BULLISH)!=0)
     {//
      if((O(1)-C(1))>=ref && L(0)>C(1) && O(2)<C(1) && C(2)>O(1))
         return PAT_ENGULFING_BULLISH;
     }
//--- nothing found   
   return PAT_NONE;
  }
//+------------------------------------------------------------------+
