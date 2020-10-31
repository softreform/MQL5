/*
    DtoCHannel.mqh
 	
    Copyright 2020, Soft Reform
    https://www.mql5.com
 
*/

class CDtoChannel {

public: // dto variables

	int					   mDigits;
    string				   mSymbol;
    ENUM_TIMEFRAMES	   mTimeframe;

    double              channelHigh[];
    double              channelMid[];
    double              channelLow[];
    double              channelBuy[];
    double              channelSell[];

};