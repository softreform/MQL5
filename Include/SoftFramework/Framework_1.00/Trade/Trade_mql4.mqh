/* 
    Trade_mql4.mqh
    Copyright 2020, SoftReform
*/

#include "../CommonBase.mqh"

enum ENUM_POSITION_TYPE {
    POSITION_TYPE_BUY   = ORDER_TYPE_BUY,
    POSITION_TYPE_SELL  = ORDER_TYPE_SELL
};

class CTradeCustom : public CCommonBase {

private:

protected:

    int             mMagic;         // expert magic number

public: // constructors

    CTradeCustom();
    ~CTradeCustom();
    
}