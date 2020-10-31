/*
 	TPSLBase.mqh
 	
   Copyright 2020, Soft Reform
   https://www.mql5.com
 
*/
 
#include	"../Signals/SignalBase.mqh"


class CTPSLBase : public CSignalBase {

private:

protected:	// member variables

	
public:	// constructors

	CTPSLBase()															:	CSignalBase()
																			{	Init();	}
	CTPSLBase(string symbol, ENUM_TIMEFRAMES timeframe)					:	CSignalBase(symbol, timeframe)
																			{	Init();	}
	~CTPSLBase()															{	}
	
	int			Init();

public:

	virtual double				GetTakeProfit()		{ return(0.0);	}
	virtual double				GetStopLoss()		{ return(0.0);	}

};

int		CTPSLBase::Init() {

	if (InitResult()!=INIT_SUCCEEDED)	return(InitResult());

	return(INIT_SUCCEEDED);
	
}




