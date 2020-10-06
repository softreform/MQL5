//+------------------------------------------------------------------+
//|                                                   CommonBase.mqh |
//|                                                      @softreform |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "@softreform"
#property link      "https://www.mql5.com"
//+------------------------------------------------------------------+
//| defines                                                          |
//+------------------------------------------------------------------+

class CCommonBase {

private:
protected:  // Members

    int                     mDigits;
    string                  mSymbol;
    ENUM_TIMEFRAMES         mTimeFrame;

    string                  mInitMessage;
    int                     mInitResult;

protected:          // Constructor

    CCommonBase()                                           {   Init(_Symbol, (ENUM_TIMEFRAMES)_Period);    }
    CCommonBase(string symbol)                              {   Init( symbol, (ENUM_TIMEFRAMES)_Period);    }
    CCommonBase(int timeFrame)                              {   Init(_Symbol, (ENUM_TIMEFRAMES)timeFrame);  }
    CCommonBase(ENUM_TIMEFRAMES timeFrame)                  {   Init(_Symbol, timeFrame);                   }
    CCommonBase(string symbol, int timeFrame)               {   Init( symbol, (ENUM_TIMEFRAMES)timeFrame);  }
    CCommonBase(string symbol, ENUM_TIMEFRAMES timeFrame)   {   Init( symbol, timeFrame);                   }

    // Destructor
    ~CCommonBase() {};
    
    int                 Init(string symbol, ENUM_TIMEFRAMES timeFrame);

protected:  // Functions

    int                 InitError(string initMessage, int initResult ) 
                                                            {   mInitMessage    = initMessage;
                                                                mInitResult     = initResult;
                                                                return(initResult);     }
public:     // Properties

    int                 InitResult()                        {   return(mInitResult);                        }
    string              InitMessage()                       {   return(mInitMessage);                       }

public:     // Functions
    bool                TradeAllowed()                      {   return(SymbolInfoInteger(mSymbol, SYMBOL_TRADE_MODE)!=SYMBOL_TRADE_MODE_DISABLED);   }

};

int     CCommonBase::Init(string symbol, ENUM_TIMEFRAMES timeFrame) {

    InitError("", INIT_SUCCEEDED);

    mSymbol             =   symbol;
    mTimeFrame          =   timeFrame;
    mDigits             =   (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);

    return(INIT_SUCCEEDED);
};