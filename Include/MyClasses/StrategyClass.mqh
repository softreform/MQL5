//+------------------------------------------------------------------+
//|                                                  StrategyInd.mqh |
//|                                                            @nick |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "@nick"
#property link      "https://www.mql5.com"
#property version   "1.00"
class CStrategyInd
  {
private:

   string            mSymbol;
   ENUM_TIMEFRAMES   mTimeFrame;
   int               mBarCount;
   
   datetime          mFirstBarTime;
   
   double            mChannelHigh[];
   double            mChannelLow[];
   
   int               mPrevCalculated; 
   
   void              Update();
   
public:
   CStrategyInd();
   CStrategyInd(string symbol, ENUM_TIMEFRAMES timeframe, int barCount);
  ~CStrategyInd();
                  
   void Init(string symbol, ENUM_TIMEFRAMES timeframe, int barCount); 
   
   double            High(int index);
   double            Low( int index); 
                    
  };

CStrategyInd::CStrategyInd() {
   // default values
   // barCount 20
   Init(_Symbol, (ENUM_TIMEFRAMES)_Period, 20 ); 
   }
 
CStrategyInd::CStrategyInd(string symbol, ENUM_TIMEFRAMES timeframe, int barCount) {

   Init(symbol, timeframe, barCount ); 
   
   }

CStrategyInd::~CStrategyInd() {
   }

void CStrategyInd::Init(string symbol, ENUM_TIMEFRAMES timeframe, int barCount) {

   mSymbol                 = symbol;
   mTimeFrame              = timeframe;
   mBarCount               = barCount;
   
   mFirstBarTime           = 0; 
   mPrevCalculated         = 0;
   
   ArraySetAsSeries(mChannelHigh, true);
   ArraySetAsSeries(mChannelLow, true);
   
   Update();
   
   }
   
double CStrategyInd::High(int index) {

   Update();
   if (index >=ArraySize(mChannelHigh)) return(0);
   return(mChannelHigh[index] );

}  

double CStrategyInd::Low(int index) {

   Update();
   if (index >=ArraySize(mChannelLow)) return(0);
   return(mChannelLow[index] );

}
   
void CStrategyInd::Update(void) {
   int      bars           = iBars( mSymbol, mTimeFrame);      // How many bars are available to calculate
   datetime firstBarTime   = iTime(mSymbol, mTimeFrame, bars-1);
   
   // How many bars must be calculcated
   int      limit          = bars - mPrevCalculated;           // How many bars we NOT calculated
   if (mPrevCalculated>0) limit++;                             // This force calculation of the current bar (0)
   if (firstBarTime!=mFirstBarTime) {                          // First time change means recalculate everything
         limit             = bars;
         mFirstBarTime     = firstBarTime;                     // Just  reset
   }
   
   if (limit <= 0)  return;                                    // Should not happen but better to be safe
   
   if (bars!=ArraySize(mChannelHigh)) {                        // Make sure array size matches number of bars
      ArrayResize(mChannelHigh, bars);
      ArrayResize(mChannelLow,  bars);
   }
   
   int   lim = 0;
   for (int i = limit - 1; i>=0; i-- ) {
         lim         = (bars-i)>=mBarCount ? mBarCount : (bars - i); // To handle bars before the length of the channel
         mChannelHigh[i]= iHigh(mSymbol,mTimeFrame, iHighest(mSymbol, mTimeFrame, MODE_HIGH, lim, i));
         mChannelLow[i] = iLow(mSymbol,mTimeFrame, iLowest(mSymbol, mTimeFrame, MODE_LOW, lim, i));
   
   }
   
   mPrevCalculated   = bars;
   
   }