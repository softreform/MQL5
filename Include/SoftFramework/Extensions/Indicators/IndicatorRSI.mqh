/*
 	IndicatorRSI.mqh
 	For framework version 1.0
 	
   Copyright 2020, Soft Reform
   https://www.mql5.com
 
*/
 
#include	"../../Framework.mqh"

class CIndicatorRSI : public CIndicatorBase {

private:

protected:	// member variables

	int						mPeriods;
	ENUM_APPLIED_PRICE		mAppliedPrice;

	//	Only used for MQL5
	int						mHandle;

public:	// constructors

	CIndicatorRSI(int periods, ENUM_APPLIED_PRICE appliedPrice)
								:	CIndicatorBase()
								{	Init(periods, appliedPrice);	}
	CIndicatorRSI(string symbol, ENUM_TIMEFRAMES timeframe,
						int periods, ENUM_APPLIED_PRICE appliedPrice)
								:	CIndicatorBase(symbol, timeframe)
								{	Init(periods, appliedPrice);	}
	~CIndicatorRSI();
	
	virtual int			Init(int periods, ENUM_APPLIED_PRICE appliedPrice);

public:

   virtual double GetData(const int buffer_num,const int index);

};

CIndicatorRSI::~CIndicatorRSI() {

#ifdef __MQL5__

	if (mHandle!=INVALID_HANDLE) IndicatorRelease(mHandle);
	
#endif

}

int		CIndicatorRSI::Init(int periods, ENUM_APPLIED_PRICE appliedPrice) {

	if (InitResult()!=INIT_SUCCEEDED)	return(InitResult());
	
	mPeriods			=	periods;
	mAppliedPrice	=	appliedPrice;

#ifdef __MQL5__
	mHandle			=	iRSI(mSymbol, mTimeframe, mPeriods, mAppliedPrice);
	if (mHandle==INVALID_HANDLE)	return(InitError("Failed to create indicator handle", INIT_FAILED));
#endif

	return(INIT_SUCCEEDED);
	
}

double	CIndicatorRSI::GetData(const int buffer_num,const int index) {

	double	value	=	0;
#ifdef __MQL4__
	value	=	iRSI(mSymbol, mTimeframe, mPeriods, mAppliedPrice, index);
#endif

#ifdef __MQL5__
	double	bufferData[];
	ArraySetAsSeries(bufferData, true);
	int cnt	=	CopyBuffer(mHandle, buffer_num, index, 1, bufferData);
	if (cnt>0) value	=	bufferData[0];
#endif

	return(value);
	
}


