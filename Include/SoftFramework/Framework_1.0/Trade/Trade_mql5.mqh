/* 
    Trade_mql5.mqh
    Copyright 2020, SoftReform
*/

#include <Trade/Trade.mqh>

class CTradeCustom : public CTrade {

protected: // membervariables

public: // constructors

public:

    bool    PositionCloseByType(const string symbol, ENUM_POSITION_TYPE positionType, const ulong deviation=ULONG_MAX);

};

bool CTradeCustom::PositionCloseByType(const string symbol, ENUM_POSITION_TYPE positionType, const ulong deviation=ULONG_MAX ) {

    bool result     = true;
    int  cnt        = PositionsTotal();
    for (int i = cnt-1; i>=0; i--) {
        ulong ticket = PositionGetTicket(i);
        if (PositionSelectByTicket(ticket)) {
            if (PositionGetString(POSITION_SYMBOL)==symbol && PositionGetInteger(POSITION_TYPE)==positionType && PositionGetInteger(POSITION_MAGIC)==m_magic) {
                result  &= PositionClose(ticket, deviation);
            }
        } else {
            m_result.retcode = TRADE_RETCODE_REJECT;
            result           = false;
        }
    }

    return(result);

}