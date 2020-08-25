#property copyright "@nick"
#property link      "https://www.mql5.com"
#property version   "1.00"

#include "CChannelBase.mqh";
#include <mq5-templates/snippets/Conditions/ACondition.mq5>

class CChannel : public CChannelBase {

private:

   int               mChannelPeriod;
   
protected:

   virtual void      UpdateValues(int bars, int limit);

public:
                     CChannel();
                     CChannel(string symbol, ENUM_TIMEFRAMES timeframe, int channelPeriods);
                    ~CChannel();
                    
   void              Init(int channlePeriods);
    
  };
  
class UpArrowCondition : public ACondition
{
public:
   UpArrowCondition(const string symbol, ENUM_TIMEFRAMES timeframe)
      :ACondition(symbol, timeframe)
   {

   }

   bool IsPass(const int period, const datetime date);
};

bool UpArrowCondition::IsPass(const int period,const datetime date)
{
   return false;
}

class DownArrowCondition : public ACondition
{
public:
   DownArrowCondition(const string symbol, ENUM_TIMEFRAMES timeframe)
      :ACondition(symbol, timeframe)
   {

   }

   bool IsPass(const int period, const datetime date);
};

bool DownArrowCondition::IsPass(const int period,const datetime date)
{
   return false;
}

CChannel::CChannel()
  {
// Default values
// barCount = 20

   Init(20);
   
  }
 
CChannel::CChannel(string symbol, ENUM_TIMEFRAMES timeframe, int channelPeriods)
   : CChannelBase(symbol, timeframe) {

   Init(channelPeriods);
   
  }  

CChannel::~CChannel()
  {
  }

void CChannel::Init(int channelPeriods) {
  
   mChannelPeriod                   = channelPeriods;
   
}

void CChannel::UpdateValues(int bars,int limit) {

     int    lim   = 0;
     for(int i=limit-1;i>=0;i--)
       {
            lim                         = (bars-i)>=mChannelPeriod ? mChannelPeriod : (bars-i);
            mCChannelBaseHi[i]          = iHigh(mSymbol, mTimeFrame, iHighest(mSymbol, mTimeFrame, MODE_HIGH, lim, i));
            mCChannelBaseLo[i]          = iLow(mSymbol, mTimeFrame, iLowest(mSymbol, mTimeFrame, MODE_LOW, lim, i));
            mCChannelBaseMi[i]          = (mCChannelBaseHi[i]+mCChannelBaseLo[i])/2;

            //if (UpArrowCondition.IsPass(mTimeFrame, iTime(mSymbol, mTimeFrame, MODE_HIGH, lim, i))) {
            //mCChannelBaseBuy[i]         =  mCChannelBaseHi[i] ;
            //}    

            //if (DownArrowCondition.IsPass(mTimeFrame, iTime(mSymbol, mTimeFrame, MODE_HIGH, lim, i))) {
            //mCChannelBaseSell[i]         =  mCChannelBaseLo[i] ;
            //}                   
       }
       
     mPrevCalculated                = bars;

}