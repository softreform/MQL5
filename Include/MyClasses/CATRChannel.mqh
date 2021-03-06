#property copyright "@nick"
#property link      "https://www.mql5.com"
#property version   "1.00"

#include "CChannelBase.mqh";
#include <mq5-templates/snippets/Conditions/ACondition.mq5>
#include <mq5-templates/snippets/Conditions/AndCondition.mq5>

enum TwoStreamsConditionType
{
   FirstAboveSecond,
   FirstBelowSecond,
   FirstCrossOverSecond,
   FirstCrossUnderSecond
};

enum TradingMode
{
   TradingModeOnBarClose, // Entry on candle close
   TradingModeLive // Entry on tick
};

enum TradingDirection
{
   LongSideOnly, // Long only
   ShortSideOnly, // Short only
   BothSides // Both
};


class CATRChannel : public CChannelBase {

private:

   int                  mATRChannelPeriod;
   double               mAtrMultiplier;
   int                  mMAPeriod;
   ENUM_MA_METHOD       mMAMethod;
   ENUM_APPLIED_PRICE   mMAAppliedPrice;
   
   int                  mMAHandle;
   int                  mATRHandle;

   AndCondition*        mlongCondition;
   AndCondition*        mshortCondition;
   
protected:

   virtual void         UpdateValues(int bars, int limit);  
   ICondition*          CreateLongCondition(string symbol, ENUM_TIMEFRAMES timeframe, CChannelBase* cind)
                        {
                           AndCondition* condition = new AndCondition();
                           condition.Add(new EntryLongCondition(symbol, timeframe, FirstCrossOverSecond, cind), false);
                           return (ICondition*) condition;
                        }   
   ICondition*          CreateShortCondition(string symbol, ENUM_TIMEFRAMES timeframe, CChannelBase* cind)
                        {
                           AndCondition* condition = new AndCondition();
                           condition.Add(new EntryShortCondition(symbol, timeframe, FirstCrossUnderSecond, cind), false);
                           return (ICondition*) condition;
                        }      

public:
                        CATRChannel();
                        CATRChannel(string symbol, ENUM_TIMEFRAMES timeframe, int atrPeriods);
                        ~CATRChannel();
                    
   void                 Init(int atrPeriods);
    
  };
  
class EntryLongCondition : public ACondition
{
TwoStreamsConditionType _condition;
CChannelBase*           _cind;
public:
   EntryLongCondition(string symbol, ENUM_TIMEFRAMES timeframe, TwoStreamsConditionType condition, CChannelBase* cind)
      :ACondition(symbol, timeframe)
   {
      _condition = condition;
      _cind = cind;
   }

   virtual bool IsPass(const int period, const datetime date);
};

class EntryShortCondition : public ACondition
{
TwoStreamsConditionType _condition;
CChannelBase*           _cind;
public:
   EntryShortCondition(string symbol, ENUM_TIMEFRAMES timeframe, TwoStreamsConditionType condition, CChannelBase* cind)
      :ACondition(symbol, timeframe)
   {
      _condition = condition;
      _cind = cind;
   }

   virtual bool IsPass(const int period, const datetime date);

};    

bool EntryLongCondition::IsPass(const int period,const datetime date)
{
      double price0     = iClose(_symbol,_timeframe,period+1);
      double price1     = iOpen(_symbol,_timeframe,period+1);
      double priceInd   = _cind.High(period+1);

      switch (_condition)
      {
         case FirstAboveSecond:
            return price0 > priceInd;
         case FirstBelowSecond:
            return price0 < priceInd;
         case FirstCrossOverSecond:
            return price0 >= priceInd && price1 < priceInd;
         case FirstCrossUnderSecond:
            return price0 <= priceInd && price1 > priceInd;
      }
      return false;
}

bool EntryShortCondition::IsPass(const int period,const datetime date)
{
      double price0      = iClose(_symbol,_timeframe,period+1);
      double price1      = iOpen(_symbol,_timeframe,period+1);
      double priceInd    = _cind.Low(period+1);

      switch (_condition)
      {
         case FirstAboveSecond:
            return price0 > priceInd;
         case FirstBelowSecond:
            return price0 < priceInd;
         case FirstCrossOverSecond:
            return price0 >= priceInd && price1 < priceInd;
         case FirstCrossUnderSecond:
            return price0 <= priceInd && price1 > priceInd;
      }
      return false;
}

CATRChannel::CATRChannel()
  {
// Default values
// barCount = 14

   Init(14);
   
  }
 
CATRChannel::CATRChannel(string symbol, ENUM_TIMEFRAMES timeframe, int atrPeriods)
   : CChannelBase(symbol, timeframe) {

   Init(atrPeriods);
   
  }  

CATRChannel::~CATRChannel()
  {
  }

void CATRChannel::Init(int atrPeriods) {
  
   mATRChannelPeriod                   = atrPeriods;
   
   mAtrMultiplier                      = 1.0;
   mMAPeriod                           = atrPeriods;
   mMAMethod                           = MODE_EMA;
   mMAAppliedPrice                     = PRICE_CLOSE;
   
   // This line should be in OnInit() and maHandle declared as global
   mMAHandle = iMA( mSymbol, mTimeFrame,  mMAPeriod,  0 ,  mMAMethod,  mMAAppliedPrice);
   mATRHandle= iATR( mSymbol, mTimeFrame,  mMAPeriod);  

   //Strategy Conditions
   mlongCondition = new AndCondition();
   CChannelBase* longcind = this;
   mlongCondition.Add(CreateLongCondition(mSymbol, mTimeFrame, longcind), false);
   mshortCondition = new AndCondition();
   CChannelBase* shortcind = this;
   mshortCondition.Add(CreateShortCondition(mSymbol, mTimeFrame, shortcind), false);   
      
   Update();
   
}

void CATRChannel::UpdateValues(int bars,int limit) {
     double mas[1];
     
     if(BarsCalculated(mMAHandle)<bars) return;
     if(BarsCalculated(mATRHandle)<bars) return;      
     
     int    lim   = 0;
     for(int i=limit-1;i>=0;i--)
       {
            lim                        = (bars-i)>=mATRChannelPeriod ? mATRChannelPeriod : (bars-i);

            int copied                 = CopyBuffer(mMAHandle,0,i,1,mas);
            if(copied>0) {
            mCChannelBaseMi[i]         = mas[0];
            }
            copied                     = CopyBuffer(mATRHandle,0,i,1,mas);
            if ( copied >0) {
            mCChannelBaseHi[i]         = mCChannelBaseMi[i]+(mas[0]*mAtrMultiplier);
            mCChannelBaseLo[i]         = mCChannelBaseMi[i]-(mas[0]*mAtrMultiplier);        
            }
            
            if(mlongCondition.IsPass(i,iTime(mSymbol,mTimeFrame,i))) {
            mCChannelBaseBuy[i]        = iClose(mSymbol,mTimeFrame,i+1);
            }
            if(mshortCondition.IsPass(i,iTime(mSymbol,mTimeFrame,i))){
            mCChannelBaseSell[i]       = iClose(mSymbol,mTimeFrame,i+1); 
            }
       }
       
     mPrevCalculated                = bars;

}