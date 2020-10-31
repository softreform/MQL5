/* 
    CExpertBase.mqh
    For framework version 1.0

    Copyright 2020, SoftReform

*/
#include "CommonBase.mqh"
#include "Signals/SignalBase.mqh"
#include "Trade/Trade.mqh"

class CExpertBase : public CCommonBase
{
private:
    /* data */
protected:  // Variables
    int             mMagicNumber;
    string          mTradeComment;
    double          mVolume;
    datetime        mLastBarTime;
    datetime        mBarTime;

    CSignalBase     *mEntrySignal;
    CSignalBase     *mExitSignal;

protected:  // Function
    virtual bool    LoopMain(bool newBar, bool firstTime);
    int             Init(int magicNumber, string tradeComment);
public:
    CExpertBase(/* args */)             :   CCommonBase()
                                        {   Init(0, "");    }
    CExpertBase(string symbol, int timeFrame, int magicNumber, string tradeComment)
                                        :   CCommonBase(symbol, timeFrame)
                                        {   Init(magicNumber, tradeComment);    }
    CExpertBase(string symbol, ENUM_TIMEFRAMES timeFrame, int magicNumber, string tradeComment)                                        
                                        :   CCommonBase(symbol, timeFrame)
                                        {   Init(magicNumber, tradeComment);    }
    CExpertBase(int magicNumber, string tradeComment)
                                        :   CCommonBase()
                                        {   Init(magicNumber, tradeComment);    }

    ~CExpertBase();

public: // Default properties

    // Assign the default values to the expert
    virtual void    SetVolume(double volume)        { mVolume       = volume;   }
    virtual void    SetTradeComment(string comment) { mTradeComment = comment;  }
    virtual void    SetMagic(int magicNumber)       { mMagicNumber  = magicNumber;  }

public: // Setup

    virtual void    AddEntrySignal(CSignalBase *signal) {   mEntrySignal = signal;  }
    virtual void    AddExitSignal(CSignalBase *signal)  {   mExitSignal  = signal;  }

public: // Event handlers

    virtual int     OnInit()        {   return(InitResult());  }
    virtual void    OnTick();
    virtual void    OnTimer()       {   return;     }
    virtual double  OnTester()      {   return(0.0);    }
    virtual void    OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam) {}

#ifdef __MQL5__
    virtual void    OnTrade()       {   return;     }    
    virtual void    OnTradeTransaction(const MqlTradeTransaction& trans,
                                        const MqlTradeRequest& request,
                                        const MqlTradeResult& result)
                                    {   return;     }
    virtual void    OnTesterInit()  {   return;     }                                        
    virtual void    OnTesterPass()  {   return;     }
    virtual void    OnTesterDeinit(){   return;     }
    virtual void    OnBookEvent(const string& symbol)   
                                    {   return;     }
#endif

};

CExpertBase::~CExpertBase()
{
}

int     CExpertBase::Init(int magicNumber, string tradeComment) {

    if (mInitResult!=INIT_SUCCEEDED) return(mInitResult);

    mMagicNumber        = magicNumber;
    mTradeComment       = tradeComment;
    mLastBarTime        = 0;

    return(INIT_SUCCEEDED);
    
}

void    CExpertBase::OnTick(void) {

    //if(!TradeAllowed()) return;

    mBarTime            =   iTime(mSymbol, mTimeFrame, 0);

    bool    firstTime   =   (mLastBarTime==0);
    bool    newBar      =   (mBarTime!=mLastBarTime);

    if (LoopMain(newBar, firstTime))
    {
        mLastBarTime    = mBarTime;
    }
    
    return;
            
}

bool    CExpertBase::LoopMain(bool newBar, bool firstTime) {

    if(!newBar)     return(true);
    if(firstTime)   return(true);

    // Update the signals
    if ( mEntrySignal!=NULL) mEntrySignal.UpdateSignal();
    if ( mEntrySignal!=mExitSignal) {
        if (mExitSignal!=NULL)  mExitSignal.UpdateSignal();
    }

    // Should any trades be closed
    if (mExitSignal!=NULL) {
        if ( mExitSignal.ExitSignal()==OFX_SIGNAL_BOTH) {
            // Close all
        } else
        if ( mExitSignal.ExitSignal()==OFX_SIGNAL_BUY ) {
            // Close buy trades
        } else
        if ( mExitSignal.ExitSignal()==OFX_SIGNAL_SELL) {
            // Close sell trades
        }    
    }

    // Should any trades be opened
    if (mEntrySignal!=NULL) {
        if ( mEntrySignal.EntrySignal()==OFX_SIGNAL_BOTH) {
            // Open both sides
        } else
        if ( mEntrySignal.EntrySignal()==OFX_SIGNAL_BUY ) {
            // Open buy trades
        } else
        if ( mEntrySignal.EntrySignal()==OFX_SIGNAL_SELL) {
            // Open sell trades
        }    
    }    

    return(true);
    
}
