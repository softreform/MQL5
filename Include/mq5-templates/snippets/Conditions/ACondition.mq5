// Base condition v1.0

#ifndef ABaseCondition_IMP
#define ABaseCondition_IMP

#include "AConditionBase.mq5"
#include "../InstrumentInfo.mq5"
class ACondition : public AConditionBase
{
protected:
   ENUM_TIMEFRAMES _timeframe;
   InstrumentInfo* _instrument;
   string _symbol;
public:
   ACondition(const string symbol, ENUM_TIMEFRAMES timeframe)
   {
      _instrument = new InstrumentInfo(symbol);
      _timeframe = timeframe;
      _symbol = symbol;
   }
   ~ACondition()
   {
      delete _instrument;
   }
};


#endif