/*
 	ContractChannel.mqh
 	For framework version 1.0
 	
   Copyright 2020, Soft Reform
   https://www.mql5.com
 
*/

#include "../../Framework.mqh"
#include "../Enum/enum.mqh"
#include "dto/dtoChannel.mqh"
#include <mq5-templates/snippets/Conditions/ACondition.mq5>
#include <mq5-templates/snippets/Conditions/AndCondition.mq5>

class CContractChannel : public CIndicatorBase {

private:

protected:	// member variables

   int	           mPeriods;
   
   int                 mATRPeriod;
   double              mAtrMultiplier;
   int                 mMAPeriod;
   ENUM_MA_METHOD      mMAMethod;
   ENUM_APPLIED_PRICE  mMAAppliedPrice;
   
   int                 mMAHandle;
   int                 mATRHandle;
   int                 mRSIHandle;
   
   AndCondition*       mlongCondition;
   AndCondition*       mshortCondition;    
   CDtoChannel*        mDto;
   
   double              mChannelHi[];
   double              mChannelMi[];
   double              mChannelLo[];
   double              mChannelBuy[];
   double              mChannelSell[];   
   
   int                 mPrevCalculated;
   datetime            mFirstBarTime;
   
   virtual void        Update();
   virtual void        UpdateValues(int bars, int limit);    

   ICondition*          CreateLongCondition(string symbol, ENUM_TIMEFRAMES timeframe, CDtoChannel* dto)
                        {
                           AndCondition* condition = new AndCondition();
                           condition.Add(new EntryLongCondition(symbol, timeframe, FirstCrossOverSecond, mDto), false);
                           return (ICondition*) condition;
                        }   
   ICondition*          CreateShortCondition(string symbol, ENUM_TIMEFRAMES timeframe, CDtoChannel* dto)
                        {
                           AndCondition* condition = new AndCondition();
                           condition.Add(new EntryShortCondition(symbol, timeframe, FirstCrossUnderSecond, mDto), false);
                           return (ICondition*) condition;
                        }      

public:	// constructors

   CContractChannel()  :	CIndicatorBase()
                        {  Init(14);}

	CContractChannel(int periods)
								:	CIndicatorBase()
								{	Init(periods);	}
	CContractChannel(string symbol, ENUM_TIMEFRAMES timeframe,
						int periods)
								:	CIndicatorBase(symbol, timeframe)
								{	Init(periods);	}
	~CContractChannel();
	
	virtual int		   Init(int periods);

   double            High(int index);
   double            Mid( int index);
   double            Low( int index);
   double            Buy( int index);
   double            Sell(int index);   

public:

    virtual double GetData(const int buffer_num,const int index);

};

CContractChannel::~CContractChannel() {

}

int CContractChannel::Init(int atrPeriods) {

   mDto                               = new CDtoChannel();
   mDto.mDigits                       = mDigits;
   mDto.mSymbol                       = mSymbol;
   mDto.mTimeframe                    = mTimeframe;

  
   mATRPeriod                          = atrPeriods;
   
   mAtrMultiplier                      = 1.0;
   mMAPeriod                           = atrPeriods;
   mMAMethod                           = MODE_EMA;
   mMAAppliedPrice                     = PRICE_CLOSE;
   
   // This line should be in OnInit() and maHandle declared as global
   mMAHandle = iMA(  mSymbol, mTimeframe,  mMAPeriod,  0 ,  mMAMethod,  mMAAppliedPrice);
   mATRHandle= iATR( mSymbol, mTimeframe,  mMAPeriod);  

   //Strategy Conditions
   mlongCondition = new AndCondition();
   mlongCondition.Add(CreateLongCondition(mSymbol, mTimeframe, mDto), false);
   mshortCondition = new AndCondition();
   mshortCondition.Add(CreateShortCondition(mSymbol, mTimeframe, mDto), false);         

   Update();   
   
   return(INIT_SUCCEEDED);
   
}

void  CContractChannel::Update() {

   //Some basic information required
   int      bars                    = iBars(mSymbol, mTimeframe);           // How many bars are available to calculate
   datetime firstBarTime            = iTime(mSymbol, mTimeframe, bars-1);   // Find the time of the first available bar
   
   // How many bars must be calculated
   int      limit                   = bars-mPrevCalculated;                 // How many bars have we NOT calculated
   if(mPrevCalculated>0)            limit++;                                // This force recalculation of the current bar (0)
                                                                 
   if(firstBarTime!=mFirstBarTime)
     {
            limit                   = bars;
            mFirstBarTime           = firstBarTime; 
     }
   if(limit<=0)            return;                                          // Should not happen but better to be safe
   
   
   if(bars!=ArraySize(mDto.channelHigh))                                     // Make sure array size matches number of bars
     {
            ArrayResize(mDto.channelHigh,  bars);
            ArrayResize(mDto.channelMid,  bars);
            ArrayResize(mDto.channelLow,  bars); 
            ArrayResize(mDto.channelBuy, bars);
            ArrayResize(mDto.channelSell,bars);             
     }
     
   int arsize  = ArraySize(mDto.channelSell);   
   
   UpdateValues(bars, limit); 
}

void CContractChannel::UpdateValues(int bars,int limit) {
     double mas[1];
     
     if(BarsCalculated(mMAHandle)<bars)  return;
     if(BarsCalculated(mATRHandle)<bars) return;      
     
     int    lim   = 0;
     for(int i=limit-1;i>=0;i--)
       {
            lim                        = (bars-i)>=mATRPeriod ? mATRPeriod : (bars-i);
            if (i == 20 ) {
               mDto.channelMid[i] = 0;
            }
            int copied                 = CopyBuffer(mMAHandle,0,i,1,mas);
            if(copied>0) {
            mDto.channelMid[i]         = mas[0];
            }
            copied                     = CopyBuffer(mATRHandle,0,i,1,mas);
            if ( copied >0) {
            mDto.channelHigh[i]        = mDto.channelMid[i]+(mas[0]*mAtrMultiplier);
            mDto.channelLow[i]         = mDto.channelMid[i]-(mas[0]*mAtrMultiplier);        
            }
            
            if(mlongCondition.IsPass(i,iTime(mSymbol,mTimeframe,i))) {
            mDto.channelBuy[i]        = iClose(mSymbol,mTimeframe,i+1);
            }
            if(mshortCondition.IsPass(i,iTime(mSymbol,mTimeframe,i))){
            mDto.channelSell[i]       = iClose(mSymbol,mTimeframe,i+1); 
            }
       }
       
     mPrevCalculated              = bars;
}

double   CContractChannel::High(int index) {

      Update();
      
      if(index>=ArraySize(mDto.channelHigh)) return(0);
      return(mDto.channelHigh[index]);

}

double   CContractChannel::Mid(int index) {

      Update();
      
      if(index>=ArraySize(mDto.channelMid)) return(0);
      return(mDto.channelMid[index]);

}

double   CContractChannel::Low(int index) {

      Update();
      
      if(index>=ArraySize(mDto.channelLow)) return(0);
      return(mDto.channelLow[index]);

}

double   CContractChannel::Buy(int index) {

      Update();
      
      if(index>=ArraySize(mDto.channelBuy)) return(0);
      return(mDto.channelBuy[index]);

}

double   CContractChannel::Sell(int index) {

      Update();
      
      if(index>=ArraySize(mDto.channelSell)) return(0);
      return(mDto.channelSell[index]);

}

class EntryLongCondition : public ACondition
{
TwoStreamsConditionType _condition;
CDtoChannel*           _dto;
public:
   EntryLongCondition(string symbol, ENUM_TIMEFRAMES timeframe, TwoStreamsConditionType condition, CDtoChannel* dto)
      :ACondition(symbol, timeframe)
   {
      _condition = condition;
      _dto = dto;
   }

   virtual bool IsPass(const int period, const datetime date);
};

class EntryShortCondition : public ACondition
{
TwoStreamsConditionType _condition;
CDtoChannel*           _dto;
public:
   EntryShortCondition(string symbol, ENUM_TIMEFRAMES timeframe, TwoStreamsConditionType condition, CDtoChannel* dto)
      :ACondition(symbol, timeframe)
   {
      _condition = condition;
      _dto = dto;
   }

   virtual bool IsPass(const int period, const datetime date);

};    

bool EntryLongCondition::IsPass(const int period,const datetime date)
{
      double price0     = iClose(_symbol,_timeframe,period);
      double price1     = iOpen(_symbol,_timeframe,period);
      int arsize = ArraySize(_dto.channelHigh);
      double priceInd   = _dto.channelHigh[period];

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
      double price0      = iClose(_symbol,_timeframe,period);
      double price1      = iOpen(_symbol,_timeframe,period);
      double priceInd    = _dto.channelLow[period];

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

double	CContractChannel::GetData(const int buffer_num,const int index) {

	double	value	=	0;
#ifdef __MQL4__
	value	=	iRSI(mSymbol, mTimeframe, mPeriods, mAppliedPrice, index);
#endif

#ifdef __MQL5__
	double	bufferData[];
	ArraySetAsSeries(bufferData, true);
	int cnt	=	CopyBuffer(mRSIHandle, buffer_num, index, 1, bufferData);
	if (cnt>0) value	=	bufferData[0];
#endif

	return(value);
	
}