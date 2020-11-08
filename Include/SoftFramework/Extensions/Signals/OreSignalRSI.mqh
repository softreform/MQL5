/*
 	OreSignalRSI.mqh
 	For framework version 1.0
 	
   Copyright 2020, Soft Reform
   https://www.mql5.com
 
*/
 
#include	"../../Framework.mqh"

class OreCSignalRSI : public CSignalBase {

private:

protected:	// member variables

	double				mBuyLevel;
	double				mSellLevel;
	
public:	// constructors

	OreCSignalRSI(string symbol, ENUM_TIMEFRAMES timeframe,
								double buyLevel, double sellLevel)
								:	CSignalBase(symbol, timeframe)
								{	Init(buyLevel, sellLevel);	}
	OreCSignalRSI(double buyLevel, double sellLevel)
								:	CSignalBase()
								{	Init(buyLevel, sellLevel);	}
	~OreCSignalRSI()	{	}
	
	int			Init(double buyLevel, double sellLevel);

public:

	virtual void								UpdateSignal();

};

int		OreCSignalRSI::Init(double buyLevel, double sellLevel) {

	if (InitResult()!=INIT_SUCCEEDED)	return(InitResult());

	mBuyLevel			=	buyLevel;
	mSellLevel			=	sellLevel;
			
	return(INIT_SUCCEEDED);
	
}

void		OreCSignalRSI::UpdateSignal() {

	double	level1	=	GetIndicatorData(0, 1);
	double	level2	=	GetIndicatorData(0, 2);

	//	Just set the buy or sell signals now
	if ( (level1<=mSellLevel) && !(level2<=mSellLevel) ) {	//	Crossed up
		mEntrySignal	=	OFX_SIGNAL_BUY;
	} else
	if ( (level1>=mBuyLevel) && !(level2>=mBuyLevel) ) {	//	Crossed down
		mEntrySignal	=	OFX_SIGNAL_SELL;
	} else {
		mEntrySignal	=	OFX_SIGNAL_NONE;
	}

	return;
	
}

	
