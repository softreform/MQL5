#property copyright "@nick"
#property link      "https://www.mql5.com"
#property version   "1.00"

class CChannelBase
  {
private:

protected:

   string            mSymbol;
   ENUM_TIMEFRAMES   mTimeFrame;
   
   double            mCChannelBaseHi[];
   double            mCChannelBaseMi[];
   double            mCChannelBaseLo[];
   double            mCChannelBaseBuy[];
   double            mCChannelBaseSell[];   
   
   int               mPrevCalculated;
   datetime          mFirstBarTime;
   
   virtual void      Update();
   virtual void      UpdateValues(int bars, int limit);

public:
                     CChannelBase();
                     CChannelBase(string symbol, ENUM_TIMEFRAMES timeframe);
                    ~CChannelBase();
                    
   void Init(string symbol, ENUM_TIMEFRAMES timeframe);
   
   double            High(int index);
   double            Mid( int index);
   double            Low( int index);
   double            Buy( int index);
   double            Sell( int index);   
    
  };

CChannelBase::CChannelBase()
  {
// Default values
// barCount = 20

   Init( _Symbol,( ENUM_TIMEFRAMES)_Period);
   
  }
  
CChannelBase::CChannelBase(string symbol, ENUM_TIMEFRAMES timeframe)
  {

   Init( symbol,timeframe);
   
  }

CChannelBase::~CChannelBase()
  {
  }

void CChannelBase::Init(string symbol, ENUM_TIMEFRAMES timeframe) {
  
   mSymbol                          = symbol;
   mTimeFrame                       = timeframe;
   
   mFirstBarTime                    = 0;
   mPrevCalculated                  = 0;
   
   
   ArraySetAsSeries(mCChannelBaseHi, true);
   ArraySetAsSeries(mCChannelBaseMi, true);
   ArraySetAsSeries(mCChannelBaseLo, true);
   ArraySetAsSeries(mCChannelBaseBuy, true);
   ArraySetAsSeries(mCChannelBaseSell, true);   
   
}

void  CChannelBase::Update() {

   //Some basic information required
   int      bars                    = iBars(mSymbol, mTimeFrame);           // How many bars are available to calculate
   datetime firstBarTime            = iTime(mSymbol, mTimeFrame, bars-1);   // Find the time of the first available bar
   
   // How many bars must be calculated
   int      limit                   = bars-mPrevCalculated;                 // How many bars have we NOT calculated
   //if(mPrevCalculated>0)            limit++;                                // This force recalculation of the current bar (0)
                                                                 
   if(firstBarTime!=mFirstBarTime)
     {
            limit                   = bars;
            mFirstBarTime           = firstBarTime; 
     }
   if(limit<=0)            return;                                          // Should not happen but better to be safe
   
   if(bars!=ArraySize(mCChannelBaseHi))                                          // Make sure array size matches number of bars
     {
            ArrayResize(mCChannelBaseHi, bars);
            ArrayResize(mCChannelBaseMi, bars);
            ArrayResize(mCChannelBaseLo, bars); 
            ArrayResize(mCChannelBaseBuy, bars);
            ArrayResize(mCChannelBaseSell, bars);             
     }
   
   UpdateValues(bars, limit); 
}

void CChannelBase::UpdateValues(int bars, int limit) {
  
   mPrevCalculated                  = bars;
   return;
   
}

double   CChannelBase::High(int index) {

      Update();
      
      if(index>=ArraySize(mCChannelBaseHi)) return(0);
      return(mCChannelBaseHi[index]);

}

double   CChannelBase::Mid(int index) {

      Update();
      
      if(index>=ArraySize(mCChannelBaseMi)) return(0);
      return(mCChannelBaseMi[index]);

}

double   CChannelBase::Low(int index) {

      Update();
      
      if(index>=ArraySize(mCChannelBaseLo)) return(0);
      return(mCChannelBaseLo[index]);

}

double   CChannelBase::Buy(int index) {

      Update();
      
      if(index>=ArraySize(mCChannelBaseBuy)) return(0);
      return(mCChannelBaseBuy[index]);

}

double   CChannelBase::Sell(int index) {

      Update();
      
      if(index>=ArraySize(mCChannelBaseSell)) return(0);
      return(mCChannelBaseSell[index]);

}