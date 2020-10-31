/*
 	IndicatorBase.mqh
 	
   Copyright 2020, Soft Reform
   https://www.mql5.com
 
*/
 
#include	"../CommonBase.mqh"

class CIndicatorBase : public CCommonBase {

private:

protected:	// member variables

	// Only used for MT5
	int							mIndicatorHandle;

public:	// constructors

	CIndicatorBase()			:	CCommonBase()
									{	Init();	}
	CIndicatorBase(string symbol, ENUM_TIMEFRAMES timeframe)
									:	CCommonBase(symbol, timeframe)
									{	Init();	}
	~CIndicatorBase();
	
	int			Init();

public:

   virtual double    GetData(const int index) 							{ return(GetData(0,index)); }
   virtual double    GetData(const int bufferNum, const int index){ return (0); }

};

CIndicatorBase::~CIndicatorBase() {

#ifdef __MQL5__
	if (mIndicatorHandle!=INVALID_HANDLE) IndicatorRelease(mIndicatorHandle);
#endif
}

int		CIndicatorBase::Init() {

	if (InitResult()!=INIT_SUCCEEDED)	return(InitResult());
	
	mIndicatorHandle	= INVALID_HANDLE;
	
	return(INIT_SUCCEEDED);
	
}



