// More information about this indicator can be found at:
//http://fxcodebase.com/code/viewtopic.php?f=38&t=70281

//+------------------------------------------------------------------+
//|                               Copyright © 2020, Gehtsoft USA LLC |
//|                                            http://fxcodebase.com |
//+------------------------------------------------------------------+
//|                                      Developed by : Mario Jemic  |
//|                                           mario.jemic@gmail.com  |
//|                          https://AppliedMachineLearning.systems  |
//+------------------------------------------------------------------+
//|                                 Support our efforts by donating  |
//|                                  Paypal : https://goo.gl/9Rj74e  |
//|                                 Patreon : https://goo.gl/GdXWeN  |
//+------------------------------------------------------------------+

#property copyright "Copyright © 2020, Gehtsoft USA LLC"
#property link      "http://fxcodebase.com"
#property version   "1.0"

#property strict

#define ACT_ON_SWITCH_CONDITION
#define TAKE_PROFIT_FEATURE

// Order side v1.0

#ifndef OrderSide_IMP
#define OrderSide_IMP

enum OrderSide
{
   BuySide,
   SellSide
};

#endif

#ifndef tradeManager_INSTANCE
#define tradeManager_INSTANCE
#include <Trade\Trade.mqh>
CTrade tradeManager;
#endif

enum TradingMode
{
   TradingModeOnBarClose, // Entry on candle close
   TradingModeLive // Entry on tick
};

enum TradingDirection
{
   LongSideOnly, // Long only
   ShortSideOnly, // Short only
   BothSides // Both
};

// Stop/limit type v1.0

#ifndef StopLimitType_IMP
#define StopLimitType_IMP

enum StopLimitType
{
   StopLimitDoNotUse, // Do not use
   StopLimitPercent, // Set in %
   StopLimitPips, // Set in Pips
   StopLimitDollar, // Set in $,
   StopLimitRiskReward, // Set in % of stop loss (take profit only)
   StopLimitAbsolute // Set in absolite value (rate)
};

#endif
// Position size type

#ifndef PositionSizeType_IMP
#define PositionSizeType_IMP

enum PositionSizeType
{
   PositionSizeAmount, // $
   PositionSizeContract, // In contracts
   PositionSizeEquity, // % of equity
   PositionSizeRisk, // Risk in % of equity
   PositionSizeMoneyPerPip, // $ per pip
   PositionSizeRiskCurrency // Risk in $
};

#endif
// Supported stop loss types v1.0

#ifndef StopLossType_IMP
#define StopLossType_IMP

enum StopLossType
{
   SLDoNotUse, // Do not use
   SLPercent, // Set in %
   SLPips, // Set in Pips
   SLDollar, // Set in $,
   SLAbsolute, // Set in absolite value (rate),
   SLAtr // Set in ATR(value) * mult
};

#endif
// Take profit type v1.0

#ifndef TakeProfitType_IMP
#define TakeProfitType_IMP

enum TakeProfitType
{
   TPDoNotUse, // Do not use
   TPPercent, // Set in %
   TPPips, // Set in Pips
   TPDollar, // Set in $,
   TPRiskReward, // Set in % of stop loss
   TPAbsolute, // Set in absolite value (rate),
   TPAtr // Set in ATR(value) * mult
};

#endif

enum PositionDirection
{
   DirectLogic, // Direct
   ReversalLogic // Reversal
};

enum TrailingType
{
   TrailingDontUse, // No trailing
   TrailingPips, // Use trailing in pips
   TrailingPercent // Use trailing in % of stop
};

input int MAIN_PERIOD = 10;
input int ADX_PERIOD = 7;
input string GeneralSection = ""; // == General ==
input string symbols = ""; // Symbols to trade. Separated by ","
input bool allow_trading = true; // Allow trading
input bool BTCAccount = false; // Is BTC Account?
input TradingMode entry_logic = TradingModeOnBarClose; // Entry type
input TradingDirection trading_side = BothSides; // What trades should be taken
input double lots_value            = 0.1; // Position size
input PositionSizeType lots_type = PositionSizeContract; // Position size type
input int slippage_points           = 3; // Slippage, in points
input bool close_on_opposite = true; // Close on opposite

input string SLSection            = ""; // == Stop loss/TakeProfit ==
input StopLossType stop_loss_type = SLPips; // Stop loss type
input double stop_loss_value            = 10; // Stop loss value
input TrailingType trailing_type = TrailingDontUse; // Use trailing
input double TrailingStep = 10; // Trailing step
input TakeProfitType take_profit_type = TPPips; // Take profit type
input double take_profit_value           = 10; // Take profit value
input double take_profit_atr_multiplicator = 1.0; // Take profit ATR Multiplicator
// input StopLimitType breakeven_type = StopLimitPips; // Trigger type for the breakeven
// input double breakeven_value = 10; // Trigger for the breakeven

input string PositionCapSection = ""; // == Position cap ==
input bool use_position_cap = true; // Use position cap?
input int max_positions = 2; // Max positions

enum DayOfWeek
{
   DayOfWeekSunday = 0, // Sunday
   DayOfWeekMonday = 1, // Monday
   DayOfWeekTuesday = 2, // Tuesday
   DayOfWeekWednesday = 3, // Wednesday
   DayOfWeekThursday = 4, // Thursday
   DayOfWeekFriday = 5, // Friday
   DayOfWeekSaturday = 6 // Saturday
};

input string OtherSection            = ""; // == Other ==
input int magic_number        = 42; // Magic number
input PositionDirection logic_direction = DirectLogic; // Logic type
input string StartTime = "000000"; // Start time in hhmmss format
input string EndTime = "235959"; // End time in hhmmss format
input bool LimitWeeklyTime = false; // Weekly time
input DayOfWeek WeekStartDay = DayOfWeekSunday; // Start day
input string WeekStartTime = "000000"; // Start time in hhmmss format
input DayOfWeek WeekStopDay = DayOfWeekSaturday; // Stop day
input string WeekStopTime = "235959"; // Stop time in hhmmss format
input bool MandatoryClosing = false; // Mandatory closing for non-trading time
input bool print_log = false; // Print decisions into the log
input string log_file = "log.csv"; // Log file name

//Signaler v 1.4
input string AlertsSection = ""; // == Alerts ==
input bool     Popup_Alert              = true; // Popup message
input bool     Notification_Alert       = false; // Push notification
input bool     Email_Alert              = false; // Email
input bool     Play_Sound               = false; // Play sound on alert
input string   Sound_File               = ""; // Sound file
#ifdef ADVANCED_ALERTS
input bool     Advanced_Alert           = false; // Advanced alert
input string   Advanced_Key             = ""; // Advanced alert key
input string   Comment2                 = "- You can get a key via @profit_robots_bot Telegram Bot. Visit ProfitRobots.com for discord/other platform keys -";
input string   Comment3                 = "- Allow use of dll in the indicator parameters window -";
input string   Comment4                 = "- Install AdvancedNotificationsLib using ProfitRobots installer -";

// AdvancedNotificationsLib.dll could be downloaded here: http://profitrobots.com/Home/TelegramNotificationsMT4
#import "AdvancedNotificationsLib.dll"
void AdvancedAlert(string key, string text, string instrument, string timeframe);
#import
#endif

// Trading time condition v1.0

// ICondition v3.0

#ifndef ICondition_IMP
#define ICondition_IMP
interface ICondition
{
public:
   virtual void AddRef() = 0;
   virtual void Release() = 0;
   virtual bool IsPass(const int period, const datetime date) = 0;
   virtual string GetLogMessage(const int period, const datetime date) = 0;
};
#endif

#ifndef TradingTimeCondition_IMP
#define TradingTimeCondition_IMP

class TradingTime
{
   int _startTime;
   int _endTime;
   bool _useWeekTime;
   int _weekStartTime;
   int _weekStartDay;
   int _weekStopTime;
   int _weekStopDay;
public:
   TradingTime()
   {
      _startTime = 0;
      _endTime = 0;
      _useWeekTime = false;
   }

   bool SetWeekTradingTime(const DayOfWeek startDay, const string startTime, const DayOfWeek stopDay, 
      const string stopTime, string &error)
   {
      _useWeekTime = true;
      _weekStartTime = ParseTime(startTime, error);
      if (_weekStartTime == -1)
         return false;
      _weekStopTime = ParseTime(stopTime, error);
      if (_weekStopTime == -1)
         return false;
      
      _weekStartDay = (int)startDay;
      _weekStopDay = (int)stopDay;
      return true;
   }

   bool Init(const string startTime, const string endTime, string &error)
   {
      _startTime = ParseTime(startTime, error);
      if (_startTime == -1)
         return false;
      _endTime = ParseTime(endTime, error);
      if (_endTime == -1)
         return false;

      return true;
   }

   bool IsTradingTime(datetime dt)
   {
      if (_startTime == _endTime && !_useWeekTime)
         return true;
      MqlDateTime current_time;
      if (!TimeToStruct(dt, current_time))
         return false;
      if (!IsIntradayTradingTime(current_time))
         return false;
      return IsWeeklyTradingTime(current_time);
   }
private:
   bool IsIntradayTradingTime(const MqlDateTime &current_time)
   {
      if (_startTime == _endTime)
         return true;
      int current_t = TimeToInt(current_time);
      if (_startTime > _endTime)
         return current_t >= _startTime || current_t <= _endTime;
      return current_t >= _startTime && current_t <= _endTime;
   }

   int TimeToInt(const MqlDateTime &current_time)
   {
      return (current_time.hour * 60 + current_time.min) * 60 + current_time.sec;
   }

   bool IsWeeklyTradingTime(const MqlDateTime &current_time)
   {
      if (!_useWeekTime)
         return true;
      if (current_time.day_of_week < _weekStartDay || current_time.day_of_week > _weekStopDay)
         return false;

      if (current_time.day_of_week == _weekStartDay)
      {
         int current_t = TimeToInt(current_time);
         return current_t >= _weekStartTime;
      }
      if (current_time.day_of_week == _weekStopDay)
      {
         int current_t = TimeToInt(current_time);
         return current_t < _weekStopTime;
      }

      return true;
   }

   int ParseTime(const string time, string &error)
   {
      int time_parsed = (int)StringToInteger(time);
      int seconds = time_parsed % 100;
      if (seconds > 59)
      {
         error = "Incorrect number of seconds in " + time;
         return -1;
      }
      time_parsed /= 100;
      int minutes = time_parsed % 100;
      if (minutes > 59)
      {
         error = "Incorrect number of minutes in " + time;
         return -1;
      }
      time_parsed /= 100;
      int hours = time_parsed % 100;
      if (hours > 24 || (hours == 24 && (minutes > 0 || seconds > 0)))
      {
         error = "Incorrect number of hours in " + time;
         return -1;
      }
      return (hours * 60 + minutes) * 60 + seconds;
   }
};

class TradingTimeCondition : public ICondition
{
   TradingTime *_tradingTime;
   ENUM_TIMEFRAMES _timeframe;
public:
   TradingTimeCondition(ENUM_TIMEFRAMES timeframe)
   {
      _timeframe = timeframe;
      _tradingTime = new TradingTime();
   }

   ~TradingTimeCondition()
   {
      delete _tradingTime;
   }

   bool Init(const string startTime, const string endTime, string &error)
   {
      return _tradingTime.Init(startTime, endTime, error);
   }

   virtual bool IsPass(const int period)
   {
      datetime time = iTime(_Symbol, _timeframe, period);
      return _tradingTime.IsTradingTime(time);
   }
};
#endif
// Disabled condition v1.0
// Condition base v2.0

#ifndef ACondition_IMP
#define ACondition_IMP


class AConditionBase : public ICondition
{
   int _references;
public:
   AConditionBase()
   {
      _references = 1;
   }
   
   virtual void AddRef()
   {
      ++_references;
   }

   virtual void Release()
   {
      --_references;
      if (_references == 0)
         delete &this;
   }
   
   virtual string GetLogMessage(const int period, const datetime date)
   {
      return "";
   }
};

#endif

#ifndef DisabledCondition_IMP
#define DisabledCondition_IMP
class DisabledCondition : public AConditionBase
{
public:
   virtual bool IsPass(const int period, const datetime date) { return false; }
};
#endif
// And condition v1.0



#ifndef AndCondition_IMP
#define AndCondition_IMP
class AndCondition : public AConditionBase
{
   ICondition *_conditions[];
public:
   ~AndCondition()
   {
      int size = ArraySize(_conditions);
      for (int i = 0; i < size; ++i)
      {
         _conditions[i].Release();
      }
   }

   void Add(ICondition *condition, bool addRef)
   {
      int size = ArraySize(_conditions);
      ArrayResize(_conditions, size + 1);
      _conditions[size] = condition;
      if (addRef)
      {
         condition.AddRef();
      }
   }

   virtual bool IsPass(const int period, const datetime date)
   {
      int size = ArraySize(_conditions);
      for (int i = 0; i < size; ++i)
      {
         if (!_conditions[i].IsPass(period, date))
            return false;
      }
      return true;
   }
};
#endif
// Base condition v1.0

#ifndef ABaseCondition_IMP
#define ABaseCondition_IMP


// Symbol info v.1.2

#ifndef InstrumentInfo_IMP
#define InstrumentInfo_IMP

class InstrumentInfo
{
   string _symbol;
   double _mult;
   double _point;
   double _pipSize;
   int _digit;
   double _ticksize;
public:
   InstrumentInfo(const string symbol)
   {
      _symbol = symbol;
      _point = SymbolInfoDouble(symbol, SYMBOL_POINT);
      _digit = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS); 
      _mult = _digit == 3 || _digit == 5 ? 10 : 1;
      _pipSize = _point * _mult;
      _ticksize = NormalizeDouble(SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_SIZE), _digit);
   }

   // Return < 0 when lot1 < lot2, > 0 when lot1 > lot2 and 0 owtherwise
   int CompareLots(double lot1, double lot2)
   {
      double lotStep = SymbolInfoDouble(_symbol, SYMBOL_VOLUME_STEP);
      if (lotStep == 0)
      {
         return lot1 < lot2 ? -1 : (lot1 > lot2 ? 1 : 0);
      }
      int lotSteps1 = (int)floor(lot1 / lotStep + 0.5);
      int lotSteps2 = (int)floor(lot2 / lotStep + 0.5);
      int res = lotSteps1 - lotSteps2;
      return res;
   }

   static double GetPipSize(const string symbol)
   {
      double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
      double digit = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS); 
      double mult = digit == 3 || digit == 5 ? 10 : 1;
      return point * mult;
   }
   double GetPointSize() { return _point; }
   double GetPipSize() { return _pipSize; }
   int GetDigits() { return _digit; }
   string GetSymbol() { return _symbol; }
   static double GetBid(const string symbol) { return SymbolInfoDouble(symbol, SYMBOL_BID); }
   static double GetAsk(const string symbol) { return SymbolInfoDouble(symbol, SYMBOL_ASK); }
   double GetBid() { return SymbolInfoDouble(_symbol, SYMBOL_BID); }
   double GetAsk() { return SymbolInfoDouble(_symbol, SYMBOL_ASK); }
   double GetMinVolume() { return SymbolInfoDouble(_symbol, SYMBOL_VOLUME_MIN); }

   double RoundRate(const double rate)
   {
      return NormalizeDouble(MathRound(rate / _ticksize) * _ticksize, _digit);
   }
};

#endif
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
// No condition v1.0



#ifndef NoCondition_IMP
#define NoCondition_IMP

class NoCondition : public AConditionBase
{
public:
   bool IsPass(const int period, const datetime date) { return true; }

   virtual string GetLogMessage(const int period, const datetime date)
   {
      return "No condition";
   }
};

#endif
#ifdef ACT_ON_SWITCH_CONDITION
// Act on switch condition v1.0



#ifndef ActOnSwitchCondition_IMP
#define ActOnSwitchCondition_IMP

class ActOnSwitchCondition : public ACondition
{
   ICondition* _condition;
   bool _current;
   datetime _currentDate;
   bool _last;
public:
   ActOnSwitchCondition(string symbol, ENUM_TIMEFRAMES timeframe, ICondition* condition)
      :ACondition(symbol, timeframe)
   {
      _last = false;
      _current = false;
      _currentDate = 0;
      _condition = condition;
      _condition.AddRef();
   }

   ~ActOnSwitchCondition()
   {
      _condition.Release();
   }

   virtual bool IsPass(const int period, const datetime date)
   {
      datetime time = iTime(_symbol, _timeframe, period);
      if (time != _currentDate)
      {
         _last = _current;
         _currentDate = time;
      }
      _current = _condition.IsPass(period, date);
      return _current && !_last;
   }
};
#endif
#endif
// IStream v.2.0
interface IStream
{
public:
   virtual void AddRef() = 0;
   virtual void Release() = 0;
   
   virtual bool GetValues(const int period, const int count, double &val[]) = 0;
   virtual bool GetSeriesValues(const int period, const int count, double &val[]) = 0;

   virtual int Size() = 0;
};
// Market entry strategy v1.0

// Entry strategy v1.0

// Money management strategy interface v1.0

#ifndef IMoneyManagementStrategy_IMP
#define IMoneyManagementStrategy_IMP
interface IMoneyManagementStrategy
{
public:
   virtual void Get(const int period, const double entryPrice, double &amount, double &stopLoss, double &takeProfit) = 0;
};
#endif

#ifndef IEntryStrategy_IMP
#define IEntryStrategy_IMP
interface IEntryStrategy
{
public:
   virtual ulong OpenPosition(const int period, OrderSide side, IMoneyManagementStrategy *moneyManagement, const string comment, bool ecnBroker) = 0;

   virtual int Exit(const OrderSide side) = 0;
};
#endif
// Action on condition logic v2.0

// Action on condition v3.0


// Action v2.0

#ifndef IAction_IMP

interface IAction
{
public:
   virtual void AddRef() = 0;
   virtual void Release() = 0;
   
   virtual bool DoAction(const int period, const datetime date) = 0;
};
#define IAction_IMP
#endif

#ifndef ActionOnConditionController_IMP
#define ActionOnConditionController_IMP

class ActionOnConditionController
{
   bool _finished;
   ICondition *_condition;
   IAction* _action;
public:
   ActionOnConditionController()
   {
      _action = NULL;
      _condition = NULL;
      _finished = true;
   }

   ~ActionOnConditionController()
   {
      if (_action != NULL)
         _action.Release();
      if (_condition != NULL)
         _condition.Release();
   }
   
   bool Set(IAction* action, ICondition *condition)
   {
      if (!_finished || action == NULL)
         return false;

      if (_action != NULL)
         _action.Release();
      _action = action;
      _action.AddRef();
      _finished = false;
      if (_condition != NULL)
         _condition.Release();
      _condition = condition;
      _condition.AddRef();
      return true;
   }

   void DoLogic(const int period, const datetime date)
   {
      if (_finished)
         return;

      if ( _condition.IsPass(period, date))
      {
         if (_action.DoAction(period, date))
            _finished = true;
      }
   }
};

#endif

#ifndef ActionOnConditionLogic_IMP
#define ActionOnConditionLogic_IMP

class ActionOnConditionLogic
{
   ActionOnConditionController* _controllers[];
public:
   ~ActionOnConditionLogic()
   {
      int count = ArraySize(_controllers);
      for (int i = 0; i < count; ++i)
      {
         delete _controllers[i];
      }
   }

   void DoLogic(const int period, const datetime date)
   {
      int count = ArraySize(_controllers);
      for (int i = 0; i < count; ++i)
      {
         _controllers[i].DoLogic(period, date);
      }
   }

   bool AddActionOnCondition(IAction* action, ICondition* condition)
   {
      int count = ArraySize(_controllers);
      for (int i = 0; i < count; ++i)
      {
         if (_controllers[i].Set(action, condition))
            return true;
      }

      ArrayResize(_controllers, count + 1);
      _controllers[count] = new ActionOnConditionController();
      return _controllers[count].Set(action, condition);
   }
};

#endif

#ifndef MarketEntryStrategy_IMP
#define MarketEntryStrategy_IMP

class MarketEntryStrategy : public IEntryStrategy
{
   string _symbol;
   int _magicNumber;
   int _slippagePoints;
   ActionOnConditionLogic* _actions;
public:
   MarketEntryStrategy(const string symbol, 
      const int magicMumber, 
      const int slippagePoints,
      ActionOnConditionLogic* actions)
   {
      _actions = actions;
      _magicNumber = magicMumber;
      _slippagePoints = slippagePoints;
      _symbol = symbol;
   }

   ulong OpenPosition(const int period, OrderSide side, IMoneyManagementStrategy *moneyManagement, const string comment, bool ecnBroker)
   {
      double entryPrice = side == BuySide ? InstrumentInfo::GetAsk(_symbol) : InstrumentInfo::GetBid(_symbol);
      double amount;
      double takeProfit;
      double stopLoss;
      moneyManagement.Get(period, entryPrice, amount, stopLoss, takeProfit);
      if (amount == 0.0)
         return -1;
      string error = "";
      MarketOrderBuilder *orderBuilder = new MarketOrderBuilder(_actions);
      ulong order = orderBuilder
         .SetSide(side)
         .SetECNBroker(ecnBroker)
         .SetInstrument(_symbol)
         .SetAmount(amount)
         .SetSlippage(_slippagePoints)
         .SetMagicNumber(_magicNumber)
         .SetStopLoss(stopLoss)
         .SetTakeProfit(takeProfit)
         .SetComment(comment)
         .Execute(error);
      delete orderBuilder;
      if (error != "")
      {
         Print("Failed to open position: " + error);
      }
      return order;
   }

   int Exit(const OrderSide side)
   {
      TradesIterator toClose();
      toClose.WhenSide(side);
      toClose.WhenMagicNumber(_magicNumber);
      return TradingCommands::CloseTrades(toClose);
   }
};

#endif

// Trades iterator v 1.2

// Compare type v1.0

#ifndef CompareType_IMP
#define CompareType_IMP

enum CompareType
{
   CompareLessThan
};

#endif

#ifndef TradesIterator_IMP

class TradesIterator
{
   bool _useMagicNumber;
   int _magicNumber;
   int _orderType;
   bool _useSide;
   bool _isBuySide;
   int _lastIndex;
   bool _useSymbol;
   string _symbol;
   bool _useProfit;
   double _profit;
   CompareType _profitCompare;
   string _comment;
public:
   TradesIterator()
   {
      _comment = NULL;
      _useMagicNumber = false;
      _useSide = false;
      _lastIndex = INT_MIN;
      _useSymbol = false;
      _useProfit = false;
   }

   TradesIterator* WhenComment(string comment)
   {
      _comment = comment;
      return &this;
   }

   void WhenSymbol(const string symbol)
   {
      _useSymbol = true;
      _symbol = symbol;
   }

   void WhenProfit(const double profit, const CompareType compare)
   {
      _useProfit = true;
      _profit = profit;
      _profitCompare = compare;
   }

   void WhenSide(const bool isBuy)
   {
      _useSide = true;
      _isBuySide = isBuy;
   }

   void WhenMagicNumber(const int magicNumber)
   {
      _useMagicNumber = true;
      _magicNumber = magicNumber;
   }
   
   ulong GetTicket() { return PositionGetTicket(_lastIndex); }
   double GetLots() { return PositionGetDouble(POSITION_VOLUME); }
   double GetOpenPrice() { return PositionGetDouble(POSITION_PRICE_OPEN); }
   double GetStopLoss() { return PositionGetDouble(POSITION_SL); }
   double GetTakeProfit() { return PositionGetDouble(POSITION_TP); }
   ENUM_POSITION_TYPE GetPositionType() { return (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE); }
   bool IsBuyOrder() { return GetPositionType() == POSITION_TYPE_BUY; }
   string GetSymbol() { return PositionGetSymbol(_lastIndex); }

   int Count()
   {
      int count = 0;
      for (int i = PositionsTotal() - 1; i >= 0; i--)
      {
         ulong ticket = PositionGetTicket(i);
         if (PositionSelectByTicket(ticket) && PassFilter(i))
         {
            count++;
         }
      }
      return count;
   }

   bool Next()
   {
      if (_lastIndex == INT_MIN)
      {
         _lastIndex = PositionsTotal() - 1;
      }
      else
         _lastIndex = _lastIndex - 1;
      while (_lastIndex >= 0)
      {
         ulong ticket = PositionGetTicket(_lastIndex);
         if (PositionSelectByTicket(ticket) && PassFilter(_lastIndex))
            return true;
         _lastIndex = _lastIndex - 1;
      }
      return false;
   }

   bool Any()
   {
      for (int i = PositionsTotal() - 1; i >= 0; i--)
      {
         ulong ticket = PositionGetTicket(i);
         if (PositionSelectByTicket(ticket) && PassFilter(i))
         {
            return true;
         }
      }
      return false;
   }

   ulong First()
   {
      for (int i = PositionsTotal() - 1; i >= 0; i--)
      {
         ulong ticket = PositionGetTicket(i);
         if (PositionSelectByTicket(ticket) && PassFilter(i))
         {
            return ticket;
         }
      }
      return 0;
   }

private:
   bool PassFilter(const int index)
   {
      if (_useMagicNumber && PositionGetInteger(POSITION_MAGIC) != _magicNumber)
         return false;
      if (_useSymbol && PositionGetSymbol(index) != _symbol)
         return false;
      if (_useProfit)
      {
         switch (_profitCompare)
         {
            case CompareLessThan:
               if (PositionGetDouble(POSITION_PROFIT) >= _profit)
                  return false;
               break;
         }
      }
      if (_useSide)
      {
         ENUM_POSITION_TYPE positionType = GetPositionType();
         if (_isBuySide && positionType != POSITION_TYPE_BUY)
            return false;
         if (!_isBuySide && positionType != POSITION_TYPE_SELL)
            return false;
      }
      if (_comment != NULL)
      {
         if (_comment != PositionGetString(POSITION_COMMENT))
            return false;
      }
      return true;
   }
};
#define TradesIterator_IMP
#endif
// Trading calculator v.1.3







#ifndef TradingCalculator_IMP
#define TradingCalculator_IMP

class TradingCalculator
{
   InstrumentInfo *_symbolInfo;
public:
   static TradingCalculator* Create(string symbol)
   {
      return new TradingCalculator(symbol);
   }

   TradingCalculator(const string symbol)
   {
      _symbolInfo = new InstrumentInfo(symbol);
   }

   ~TradingCalculator()
   {
      delete _symbolInfo;
   }

   InstrumentInfo *GetSymbolInfo()
   {
      return _symbolInfo;
   }

   double GetBreakevenPrice(const bool isBuy, const int magicNumber)
   {
      string symbol = _symbolInfo.GetSymbol();
      double lotStep = SymbolInfoDouble(symbol, SYMBOL_VOLUME_STEP);
      double price = isBuy ? _symbolInfo.GetBid() : _symbolInfo.GetAsk();
      double totalPL = 0;
      double totalAmount = 0;
      TradesIterator it1();
      it1.WhenMagicNumber(magicNumber);
      it1.WhenSymbol(symbol);
      it1.WhenSide(isBuy);
      while (it1.Next())
      {
         double orderLots = PositionGetDouble(POSITION_VOLUME);
         totalAmount += orderLots / lotStep;
         double openPrice = it1.GetOpenPrice();
         if (isBuy)
            totalPL += (price - openPrice) * (orderLots / lotStep);
         else
            totalPL += (openPrice - price) * (orderLots / lotStep);
      }
      if (totalAmount == 0.0)
         return 0.0;
      double shift = -(totalPL / totalAmount);
      return isBuy ? price + shift : price - shift;
   }
   
   double CalculateTakeProfit(const bool isBuy, const double takeProfit, const StopLimitType takeProfitType, const double amount, double basePrice)
   {
      int direction = isBuy ? 1 : -1;
      switch (takeProfitType)
      {
         case StopLimitPercent:
            return basePrice + basePrice * takeProfit / 100.0 * direction;
         case StopLimitPips:
            return basePrice + takeProfit * _symbolInfo.GetPipSize() * direction;
         case StopLimitDollar:
            return basePrice + CalculateSLShift(amount, takeProfit) * direction;
      }
      return 0.0;
   }
   
   double CalculateStopLoss(const bool isBuy, const double stopLoss, const StopLimitType stopLossType, const double amount, double basePrice)
   {
      int direction = isBuy ? 1 : -1;
      switch (stopLossType)
      {
         case StopLimitPercent:
            return basePrice - basePrice * stopLoss / 100.0 * direction;
         case StopLimitPips:
            return basePrice - stopLoss * _symbolInfo.GetPipSize() * direction;
         case StopLimitDollar:
            return basePrice - CalculateSLShift(amount, stopLoss) * direction;
      }
      return 0.0;
   }

   double GetLots(PositionSizeType lotsType, double lotsValue, const OrderSide orderSide, const double price, double stopDistance)
   {
      switch (lotsType)
      {
         case PositionSizeMoneyPerPip:
         {
            double unitCost = SymbolInfoDouble(_symbolInfo.GetSymbol(), SYMBOL_TRADE_TICK_VALUE);
            double mult = _symbolInfo.GetPipSize() / _symbolInfo.GetPointSize();
            double lots = RoundLots(lotsValue / (unitCost * mult));
            return LimitLots(lots);
         }
         case PositionSizeAmount:
            return GetLotsForMoney(orderSide, price, lotsValue);
         case PositionSizeContract:
            return LimitLots(RoundLots(lotsValue));
         case PositionSizeEquity:
            return GetLotsForMoney(orderSide, price, AccountInfoDouble(ACCOUNT_EQUITY) * lotsValue / 100.0);
         case PositionSizeRisk:
         {
            double affordableLoss = AccountInfoDouble(ACCOUNT_EQUITY) * lotsValue / 100.0;
            double unitCost = SymbolInfoDouble(_symbolInfo.GetSymbol(), SYMBOL_TRADE_TICK_VALUE);
            double tickSize = SymbolInfoDouble(_symbolInfo.GetSymbol(), SYMBOL_TRADE_TICK_SIZE);
            double possibleLoss = unitCost * stopDistance / tickSize;
            if (possibleLoss <= 0.01)
               return 0;
            return LimitLots(RoundLots(affordableLoss / possibleLoss));
         }
      }
      return lotsValue;
   }

   bool IsLotsValid(const double lots, PositionSizeType lotsType, string &error)
   {
      switch (lotsType)
      {
         case PositionSizeContract:
            return IsContractLotsValid(lots, error);
      }
      return true;
   }

   double NormilizeLots(double lots)
   {
      return LimitLots(RoundLots(lots));
   }

private:
   bool IsContractLotsValid(const double lots, string &error)
   {
      double minVolume = SymbolInfoDouble(_symbolInfo.GetSymbol(), SYMBOL_VOLUME_MIN);
      if (minVolume > lots)
      {
         error = "Min. allowed lot size is " + DoubleToString(minVolume);
         return false;
      }
      double maxVolume = SymbolInfoDouble(_symbolInfo.GetSymbol(), SYMBOL_VOLUME_MAX);
      if (maxVolume < lots)
      {
         error = "Max. allowed lot size is " + DoubleToString(maxVolume);
         return false;
      }
      return true;
   }

   double GetLotsForMoney(const OrderSide orderSide, const double price, const double money)
   {
      ENUM_ORDER_TYPE orderType = orderSide != BuySide ? ORDER_TYPE_BUY : ORDER_TYPE_SELL;
      string symbol = _symbolInfo.GetSymbol();
      double minVolume = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MIN);
      double marginRequired;
      if (!OrderCalcMargin(orderType, symbol, minVolume, price, marginRequired))
      {
         return 0.0;
      }
      if (marginRequired <= 0.0)
      {
         Print("Margin is 0. Server misconfiguration?");
         return 0.0;
      }
      double lots = RoundLots(money / marginRequired);
      return LimitLots(lots);
   }

   double RoundLots(const double lots)
   {
      double lotStep = SymbolInfoDouble(_symbolInfo.GetSymbol(), SYMBOL_VOLUME_STEP);
      if (lotStep == 0)
         return 0.0;
      return floor(lots / lotStep) * lotStep;
   }

   double LimitLots(const double lots)
   {
      double minVolume = SymbolInfoDouble(_symbolInfo.GetSymbol(), SYMBOL_VOLUME_MIN);
      if (minVolume > lots)
         return 0.0;
      double maxVolume = SymbolInfoDouble(_symbolInfo.GetSymbol(), SYMBOL_VOLUME_MAX);
      if (maxVolume < lots)
         return maxVolume;
      return lots;
   }

   double CalculateSLShift(const double amount, const double money)
   {
      double unitCost = SymbolInfoDouble(_symbolInfo.GetSymbol(), SYMBOL_TRADE_TICK_VALUE);
      double tickSize = SymbolInfoDouble(_symbolInfo.GetSymbol(), SYMBOL_TRADE_TICK_SIZE);
      return (money / (unitCost / tickSize)) / amount;
   }
};

#endif



// Orders iterator v1.9

#ifndef OrdersIterator_IMP
#define OrdersIterator_IMP

class OrdersIterator
{
   bool _useMagicNumber;
   int _magicNumber;
   bool _useOrderType;
   ENUM_ORDER_TYPE _orderType;
   bool _useSide;
   bool _isBuySide;
   int _lastIndex;
   bool _useSymbol;
   string _symbol;
   bool _usePendingOrder;
   bool _pendingOrder;
   bool _useComment;
   string _comment;
   CompareType _profitCompare;
public:
   OrdersIterator()
   {
      _useOrderType = false;
      _useMagicNumber = false;
      _usePendingOrder = false;
      _pendingOrder = false;
      _useSide = false;
      _lastIndex = INT_MIN;
      _useSymbol = false;
      _useComment = false;
   }

   OrdersIterator *WhenPendingOrder()
   {
      _usePendingOrder = true;
      _pendingOrder = true;
      return &this;
   }

   OrdersIterator *WhenSymbol(const string symbol)
   {
      _useSymbol = true;
      _symbol = symbol;
      return &this;
   }

   OrdersIterator *WhenSide(const OrderSide side)
   {
      _useSide = true;
      _isBuySide = side == BuySide;
      return &this;
   }

   OrdersIterator *WhenOrderType(const ENUM_ORDER_TYPE orderType)
   {
      _useOrderType = true;
      _orderType = orderType;
      return &this;
   }

   OrdersIterator *WhenMagicNumber(const int magicNumber)
   {
      _useMagicNumber = true;
      _magicNumber = magicNumber;
      return &this;
   }

   OrdersIterator *WhenComment(const string comment)
   {
      _useComment = true;
      _comment = comment;
      return &this;
   }

   long GetMagicNumger() { return OrderGetInteger(ORDER_MAGIC); }
   ENUM_ORDER_TYPE GetType() { return (ENUM_ORDER_TYPE)OrderGetInteger(ORDER_TYPE); }
   string GetSymbol() { return OrderGetString(ORDER_SYMBOL); }
   string GetComment() { return OrderGetString(ORDER_COMMENT); }
   ulong GetTicket() { return OrderGetTicket(_lastIndex); }
   double GetOpenPrice() { return OrderGetDouble(ORDER_PRICE_OPEN); }
   double GetStopLoss() { return OrderGetDouble(ORDER_SL); }
   double GetTakeProfit() { return OrderGetDouble(ORDER_TP); }

   int Count()
   {
      int count = 0;
      for (int i = OrdersTotal() - 1; i >= 0; i--)
      {
         ulong ticket = OrderGetTicket(i);
         if (OrderSelect(ticket) && PassFilter())
            count++;
      }
      return count;
   }

   bool Next()
   {
      if (_lastIndex == INT_MIN)
         _lastIndex = OrdersTotal() - 1;
      else
         _lastIndex = _lastIndex - 1;
      while (_lastIndex >= 0)
      {
         ulong ticket = OrderGetTicket(_lastIndex);
         if (OrderSelect(ticket) && PassFilter())
            return true;
         _lastIndex = _lastIndex - 1;
      }
      return false;
   }

   bool Any()
   {
      for (int i = OrdersTotal() - 1; i >= 0; i--)
      {
         ulong ticket = OrderGetTicket(i);
         if (OrderSelect(ticket) && PassFilter())
            return true;
      }
      return false;
   }

   ulong First()
   {
      for (int i = OrdersTotal() - 1; i >= 0; i--)
      {
         ulong ticket = OrderGetTicket(i);
         if (OrderSelect(ticket) && PassFilter())
            return ticket;
      }
      return -1;
   }

private:
   bool PassFilter()
   {
      if (_useMagicNumber && GetMagicNumger() != _magicNumber)
         return false;
      if (_useOrderType && GetType() != _orderType)
         return false;
      if (_useSymbol && OrderGetString(ORDER_SYMBOL) != _symbol)
         return false;
      if (_usePendingOrder && !IsPendingOrder())
         return false;
      if (_useComment && OrderGetString(ORDER_COMMENT) != _comment)
         return false;
      return true;
   }

   bool IsPendingOrder()
   {
      switch (GetType())
      {
         case ORDER_TYPE_BUY_LIMIT:
         case ORDER_TYPE_BUY_STOP:
         case ORDER_TYPE_BUY_STOP_LIMIT:
         case ORDER_TYPE_SELL_LIMIT:
         case ORDER_TYPE_SELL_STOP:
         case ORDER_TYPE_SELL_STOP_LIMIT:
            return true;
      }
      return false;
   }
};
#endif
// Trading commands v.2.0




#ifndef tradeManager_INSTANCE
#define tradeManager_INSTANCE
#include <Trade\Trade.mqh>
CTrade tradeManager;
#endif

#ifndef TradingCommands_IMP
#define TradingCommands_IMP

class TradingCommands
{
public:
   static bool MoveSLTP(const ulong ticket, const double stopLoss, double takeProfit, string &error)
   {
      if (!PositionSelectByTicket(ticket))
      {
         error = "Invalid ticket";
         return false;
      }
      return tradeManager.PositionModify(ticket, stopLoss, takeProfit);
   }

   static bool MoveSL(const ulong ticket, const double stopLoss, string &error)
   {
      if (!PositionSelectByTicket(ticket))
      {
         error = "Invalid ticket";
         return false;
      }
      return tradeManager.PositionModify(ticket, stopLoss, PositionGetDouble(POSITION_TP));
   }

   static bool MoveTP(const ulong ticket, const double takeProfit, string &error)
   {
      if (!PositionSelectByTicket(ticket))
      {
         error = "Invalid ticket";
         return false;
      }
      return tradeManager.PositionModify(ticket, PositionGetDouble(POSITION_SL), takeProfit);
   }

   static void DeleteOrders(const int magicNumber, const string symbol)
   {
      OrdersIterator it();
      it.WhenMagicNumber(magicNumber);
      it.WhenSymbol(symbol);
      while (it.Next())
      {
         tradeManager.OrderDelete(it.GetTicket());
      }
   }

   static bool CloseTrade(ulong ticket, string error)
   {
      if (!tradeManager.PositionClose(ticket)) 
      {
         error = IntegerToString(GetLastError());
         return false;
      }
      return true;
   }

   static int CloseTrades(TradesIterator &it)
   {
      int close = 0;
      while (it.Next())
      {
         string error;
         if (!CloseTrade(it.GetTicket(), error)) 
            Print("LastError = ", error);
         else
            ++close;
      }
      return close;
   }
};

#endif
// Trailing controller v.1.7
enum TrailingControllerType
{
   TrailingControllerTypeStandard,
   TrailingControllerTypeCustom
};

interface ITrailingController
{
public:
   virtual bool IsFinished() = 0;
   virtual void UpdateStop() = 0;
   virtual TrailingControllerType GetType() = 0;
};

//Signaler v 4.0

#ifdef ADVANCED_ALERTS
// AdvancedNotificationsLib.dll could be downloaded here: http://profitrobots.com/Home/TelegramNotificationsMT4
#import "AdvancedNotificationsLib.dll"
void AdvancedAlert(string key, string text, string instrument, string timeframe);
#import
#endif

class Signaler
{
   string _symbol;
   ENUM_TIMEFRAMES _timeframe;
   string _prefix;
   bool _popupAlert;
   bool _emailAlert;
   bool _playSound;
   string _soundFile;
   bool _notificationAlert;
   bool _advancedAlert;
   string _advancedKey;
public:
   Signaler(const string symbol, ENUM_TIMEFRAMES timeframe)
   {
      _symbol = symbol;
      _timeframe = timeframe;
      _popupAlert = false;
      _emailAlert = false;
      _playSound = false;
      _notificationAlert = false;
      _advancedAlert = false;
   }

   void SetPopupAlert(bool isEnabled) { _popupAlert = isEnabled; }
   void SetEmailAlert(bool isEnabled) { _emailAlert = isEnabled; }
   void SetPlaySound(bool isEnabled, string fileName) 
   { 
      _playSound = isEnabled;
      _soundFile = fileName;
   }
   void SetNotificationAlert(bool isEnabled) { _notificationAlert = isEnabled; }
   void SetAdvancedAlert(bool isEnabled, string key)
   {
      _advancedAlert = isEnabled;
      _advancedKey = key;
   }

   void SendNotifications(string message, string subject = NULL, string symbol = NULL, string timeframe = NULL)
   {
      if (subject == NULL)
         subject = message;

      if (_prefix != "" && _prefix != NULL)
         message = _prefix + message;
      if (symbol == NULL)
         symbol = _symbol;
      if (timeframe == NULL)
         timeframe = GetTimeframeStr();

      if (_popupAlert)
         Alert(message);
      if (_emailAlert)
         SendMail(subject, message);
      if (_playSound)
         PlaySound(_soundFile);
      if (_notificationAlert)
         SendNotification(message);
#ifdef ADVANCED_ALERTS
      if (_advancedAlert && _advancedKey != "")
         AdvancedAlert(_advancedKey, message, symbol, timeframe);
#endif
   }

   void SetMessagePrefix(string prefix)
   {
      _prefix = prefix;
   }

   string GetSymbol()
   {
      return _symbol;
   }

   ENUM_TIMEFRAMES GetTimeframe()
   {
      return _timeframe;
   }

   string GetTimeframeStr()
   {
      switch (_timeframe)
      {
         case PERIOD_M1: return "M1";
         case PERIOD_M2: return "M2";
         case PERIOD_M3: return "M3";
         case PERIOD_M4: return "M4";
         case PERIOD_M5: return "M5";
         case PERIOD_M6: return "M6";
         case PERIOD_M10: return "M10";
         case PERIOD_M12: return "M12";
         case PERIOD_M15: return "M15";
         case PERIOD_M20: return "M20";
         case PERIOD_M30: return "M30";
         case PERIOD_D1: return "D1";
         case PERIOD_H1: return "H1";
         case PERIOD_H2: return "H2";
         case PERIOD_H3: return "H3";
         case PERIOD_H4: return "H4";
         case PERIOD_H6: return "H6";
         case PERIOD_H8: return "H8";
         case PERIOD_H12: return "H12";
         case PERIOD_MN1: return "MN1";
         case PERIOD_W1: return "W1";
      }
      return "M1";
   }
};


class CustomLevelController : public ITrailingController
{
   Signaler *_signaler;
   ulong _order;
   bool _finished;
   double _stop;
   double _trigger;
   TradingCalculator *_tradeCalculator;
public:
   CustomLevelController(TradingCalculator *tradeCalculator, Signaler *signaler = NULL)
   {
      _tradeCalculator = tradeCalculator;
      _finished = true;
      _order = 0;
      _signaler = signaler;
      _trigger = 0;
      _stop = 0;
   }
   
   bool IsFinished()
   {
      return _finished;
   }

   bool SetOrder(const ulong order, const double stop, const double trigger)
   {
      if (!_finished)
      {
         return false;
      }
      if (!OrderSelect(order))
      {
         return false;
      }
      _trigger = trigger;
      _finished = false;
      _order = order;
      _stop = stop;
      
      return true;
   }

   void UpdateStop()
   {
      if (_finished)
         return;
      if (!PositionSelectByTicket(_order))
      {
         if (!OrderSelect(_order))
            _finished = true;
         return;
      }

      int type = (int)PositionGetInteger(POSITION_TYPE);
      double newStop = PositionGetDouble(POSITION_SL);
      if (type == POSITION_TYPE_BUY)
      {
         if (_trigger < _tradeCalculator.GetSymbolInfo().GetAsk()) 
         {
            if (_signaler != NULL)
            {
               string message = "Trailing stop loss for " + IntegerToString(_order) + " to " + DoubleToString(_stop);
               _signaler.SendNotifications(message);
            }
            string error;
            if (!TradingCommands::MoveSL(_order, _stop, error))
            {
               Print(error);
               return;
            }
            _finished = true;
         }
      }
      else if (type == POSITION_TYPE_SELL) 
      {
         if (_trigger > _tradeCalculator.GetSymbolInfo().GetBid()) 
         {
            if (_signaler != NULL)
            {
               string message = "Trailing stop loss for " + IntegerToString(_order) + " to " + DoubleToString(_stop);
               _signaler.SendNotifications(message);
            }
            string error;
            if (!TradingCommands::MoveSL(_order, _stop, error))
            {
               Print(error);
               return;
            }
            _finished = true;
         }
      }
   }

   TrailingControllerType GetType()
   {
      return TrailingControllerTypeCustom;
   }
};

class TrailingController : public ITrailingController
{
   Signaler *_signaler;
   ulong _order;
   bool _finished;
   double _stop;
   double _trailingStep;
   TradingCalculator *_tradeCalculator;
public:
   TrailingController(TradingCalculator *tradeCalculator, Signaler *signaler = NULL)
   {
      _tradeCalculator = tradeCalculator;
      _finished = true;
      _order = 0;
      _signaler = signaler;
   }
   
   bool IsFinished()
   {
      return _finished;
   }

   bool SetOrder(const ulong order, const double stop, const double trailingStep)
   {
      if (!_finished)
      {
         return false;
      }
      if (!OrderSelect(order))
      {
         return false;
      }
      _trailingStep = _tradeCalculator.GetSymbolInfo().RoundRate(trailingStep);
      if (_trailingStep == 0)
         return false;

      _finished = false;
      _order = order;
      _stop = stop;
      
      return true;
   }

   void UpdateStop()
   {
      if (_finished)
         return;
      if (!PositionSelectByTicket(_order))
      {
         if (!OrderSelect(_order))
            _finished = true;
         return;
      }

      int type = (int)PositionGetInteger(POSITION_TYPE);
      double originalStop = PositionGetDouble(POSITION_SL);
      double newStop = originalStop;
      if (type == POSITION_TYPE_BUY)
      {
         while (_tradeCalculator.GetSymbolInfo().RoundRate(newStop + _trailingStep) < _tradeCalculator.GetSymbolInfo().RoundRate(_tradeCalculator.GetSymbolInfo().GetAsk() - _stop))
         {
            newStop = _tradeCalculator.GetSymbolInfo().RoundRate(newStop + _trailingStep);
         }
         if (newStop != originalStop) 
         {
            if (_signaler != NULL)
            {
               string message = "Trailing stop loss for " + IntegerToString(_order) + " to " + DoubleToString(newStop, _tradeCalculator.GetSymbolInfo().GetDigits());
               _signaler.SendNotifications(message);
            }
            string error;
            if (!TradingCommands::MoveSL(_order, newStop, error))
            {
               Print(error);
               _finished = true;
               return;
            }
         }
      } 
      else if (type == POSITION_TYPE_SELL) 
      {
         while (_tradeCalculator.GetSymbolInfo().RoundRate(newStop - _trailingStep) > _tradeCalculator.GetSymbolInfo().RoundRate(_tradeCalculator.GetSymbolInfo().GetBid() + _stop))
         {
            newStop = _tradeCalculator.GetSymbolInfo().RoundRate(newStop - _trailingStep);
         }
         if (newStop != originalStop) 
         {
            if (_signaler != NULL)
            {
               string message = "Trailing stop loss for " + IntegerToString(_order) + " to " + DoubleToString(newStop, _tradeCalculator.GetSymbolInfo().GetDigits());
               _signaler.SendNotifications(message);
            }
            string error;
            if (!TradingCommands::MoveSL(_order, newStop, error))
            {
               Print(error);
               _finished = true;
               return;
            }
         }
      } 
   }

   TrailingControllerType GetType()
   {
      return TrailingControllerTypeStandard;
   }
};

class TrailingLogic
{
   ITrailingController *_trailing[];
   TradingCalculator *_calculator;
   TrailingType _trailingType;
   double _trailingStep;
   double _atrTrailingMultiplier;
   ENUM_TIMEFRAMES _timeframe;
public:
   TrailingLogic(TradingCalculator *calculator, TrailingType trailing, 
      double trailingStep, double atrTrailingMultiplier, ENUM_TIMEFRAMES timeframe)
   {
      _calculator = calculator;
      _trailingType = trailing;
      _trailingStep = trailingStep;
      _atrTrailingMultiplier = atrTrailingMultiplier;
      _timeframe = timeframe;
   }

   ~TrailingLogic()
   {
      int i_count = ArraySize(_trailing);
      for (int i = 0; i < i_count; ++i)
      {
         delete _trailing[i];
      }
   }

   void DoLogic()
   {
      int i_count = ArraySize(_trailing);
      for (int i = 0; i < i_count; ++i)
      {
         _trailing[i].UpdateStop();
      }
   }

   void CreateCustom(const ulong order, const double stop, const bool isBuy, const double triggerLevel)
   {
      if (!OrderSelect(order))
         return;

      string symbol = OrderGetString(ORDER_SYMBOL);
      if (symbol != _calculator.GetSymbolInfo().GetSymbol())
      {
         Print("Error in trailing usage");
         return;
      }

      int i_count = ArraySize(_trailing);
      for (int i = 0; i < i_count; ++i)
      {
         if (_trailing[i].GetType() != TrailingControllerTypeCustom)
            continue;
         CustomLevelController *trailingController = (CustomLevelController *)_trailing[i];
         if (trailingController.SetOrder(order, stop, triggerLevel))
         {
            return;
         }
      }

      CustomLevelController *trailingController = new CustomLevelController(_calculator);
      trailingController.SetOrder(order, stop, triggerLevel);
      
      ArrayResize(_trailing, i_count + 1);
      _trailing[i_count] = trailingController;
   }

   void Create(const ulong order, const double stop, const bool isBuy)
   {
      if (!OrderSelect(order))
         return;

      string symbol = OrderGetString(ORDER_SYMBOL);
      if (symbol != _calculator.GetSymbolInfo().GetSymbol())
      {
         Print("Error in trailing usage");
         return;
      }
      double stopDiff = isBuy ? _calculator.GetSymbolInfo().GetAsk() - stop : stop - _calculator.GetSymbolInfo().GetBid();
      switch (_trailingType)
      {
         case TrailingPips:
            CreateTrailing(order, stopDiff, _trailingStep * _calculator.GetSymbolInfo().GetPipSize());
            break;
         case TrailingPercent:
            CreateTrailing(order, stopDiff, stopDiff * _trailingStep / 100.0);
            break;
      }
   }
private:
   void CreateTrailing(const ulong order, const double stop, const double trailingStep)
   {
      int i_count = ArraySize(_trailing);
      for (int i = 0; i < i_count; ++i)
      {
         if (_trailing[i].GetType() != TrailingControllerTypeStandard)
            continue;
         TrailingController *trailingController = (TrailingController *)_trailing[i];
         if (trailingController.SetOrder(order, stop, trailingStep))
         {
            return;
         }
      }

      TrailingController *trailingController = new TrailingController(_calculator);
      trailingController.SetOrder(order, stop, trailingStep);
      
      ArrayResize(_trailing, i_count + 1);
      _trailing[i_count] = trailingController;
   }
};
// Net stop loss v 1.1
interface INetStopLossStrategy
{
public:
   virtual void DoLogic() = 0;
};

// Disabled net stop loss
class NoNetStopLossStrategy : public INetStopLossStrategy
{
public:
   void DoLogic()
   {
      // Do nothing
   }
};

class NetStopLossStrategy : public INetStopLossStrategy
{
   TradingCalculator *_calculator;
   int _magicNumber;
   double _stopLossPips;
   Signaler *_signaler;
public:
   NetStopLossStrategy(TradingCalculator *calculator, const double stopLossPips, Signaler *signaler, const int magicNumber)
   {
      _calculator = calculator;
      _stopLossPips = stopLossPips;
      _signaler = signaler;
      _magicNumber = magicNumber;
   }

   void DoLogic()
   {
      MoveStopLoss(true);
      MoveStopLoss(false);
   }
private:
   void MoveStopLoss(const bool isBuy)
   {
      TradesIterator it();
      it.WhenMagicNumber(_magicNumber);
      it.WhenSide(isBuy);
      if (it.Count() <= 1)
         return;
      double averagePrice = _calculator.GetBreakevenPrice(isBuy, _magicNumber);
      if (averagePrice == 0.0)
         return;
         
      double pipSize = _calculator.GetSymbolInfo().GetPipSize();
      double stopLoss = isBuy ? _calculator.GetSymbolInfo().RoundRate(averagePrice - _stopLossPips * pipSize)
         : _calculator.GetSymbolInfo().RoundRate(averagePrice + _stopLossPips * pipSize);
      if (isBuy)
      {
         if (stopLoss >= _calculator.GetSymbolInfo().GetBid())
            return;
      }
      else
      {
         if (stopLoss <= _calculator.GetSymbolInfo().GetAsk())
            return;
      }
      
      TradesIterator it1();
      it1.WhenMagicNumber(_magicNumber);
      it1.WhenSymbol(_calculator.GetSymbolInfo().GetSymbol());
      it1.WhenSide(isBuy);
      int count = 0;
      while (it1.Next())
      {
         if (it1.GetStopLoss() != stopLoss)
         {
            string error = "";
            if (!TradingCommands::MoveSL(it1.GetTicket(), stopLoss, error))
            {
               if (error != "")
                  Print(error);
            }
            else
               ++count;
         }
      }
      if (_signaler != NULL && count > 0)
         _signaler.SendNotifications("Moving net stop loss to " + DoubleToString(stopLoss, _calculator.GetSymbolInfo().GetDigits()));
   }
};
// Market order builder v1.4



#ifndef MarketOrderBuilder_IMP
#define MarketOrderBuilder_IMP
class MarketOrderBuilder
{
   OrderSide _orderSide;
   string _instrument;
   double _amount;
   double _rate;
   int _slippage;
   double _stop;
   double _limit;
   int _magicNumber;
   string _comment;
   bool _btcAccount;
   bool _ecnBroker;
   ActionOnConditionLogic* _actions;
public:
   MarketOrderBuilder(ActionOnConditionLogic* actions)
   {
      _ecnBroker = false;
      _actions = actions;
      _btcAccount = false;
      _amount = 0;
      _rate = 0;
      _slippage = 0;
      _stop = 0;
      _limit = 0;
      _magicNumber = 0;
   }

   // Sets ECN broker flag
   MarketOrderBuilder* SetECNBroker(bool isEcn) { _ecnBroker = isEcn; return &this; }
   MarketOrderBuilder* SetComment(const string comment) { _comment = comment; return &this; }
   MarketOrderBuilder* SetSide(const OrderSide orderSide) { _orderSide = orderSide; return &this; }
   MarketOrderBuilder* SetInstrument(const string instrument) { _instrument = instrument; return &this; }
   MarketOrderBuilder* SetAmount(const double amount) { _amount = amount; return &this; }
   MarketOrderBuilder* SetSlippage(const int slippage) { _slippage = slippage; return &this; }
   MarketOrderBuilder* SetStopLoss(const double stop) { _stop = stop; return &this; }
   MarketOrderBuilder* SetTakeProfit(const double limit) { _limit = limit; return &this; }
   MarketOrderBuilder* SetMagicNumber(const int magicNumber) { _magicNumber = magicNumber; return &this; }
   MarketOrderBuilder* SetBTCAccount(const bool isBtcAccount) { _btcAccount = isBtcAccount; return &this; }
   
   ulong Execute(string &error)
   {
      int tradeMode = (int)SymbolInfoInteger(_instrument, SYMBOL_TRADE_MODE);
      switch (tradeMode)
      {
         case SYMBOL_TRADE_MODE_DISABLED:
            error = "Trading is disbled";
            return 0;
         case SYMBOL_TRADE_MODE_CLOSEONLY:
            error = "Only close is allowed";
            return 0;
         case SYMBOL_TRADE_MODE_SHORTONLY:
            if (_orderSide == BuySide)
            {
               error = "Only short are allowed";
               return 0;
            }
            break;
         case SYMBOL_TRADE_MODE_LONGONLY:
            if (_orderSide == SellSide)
            {
               error = "Only long are allowed";
               return 0;
            }
            break;
      }
      ENUM_ORDER_TYPE orderType = _orderSide == BuySide ? ORDER_TYPE_BUY : ORDER_TYPE_SELL;
      int digits = (int)SymbolInfoInteger(_instrument, SYMBOL_DIGITS);
      double rate = _orderSide == BuySide ? SymbolInfoDouble(_instrument, SYMBOL_ASK) : SymbolInfoDouble(_instrument, SYMBOL_BID);
      double ticksize = SymbolInfoDouble(_instrument, SYMBOL_TRADE_TICK_SIZE);
      
      MqlTradeRequest request;
      ZeroMemory(request);
      request.action = TRADE_ACTION_DEAL;
      request.symbol = _instrument;
      request.type = orderType;
      request.volume = _amount;
      request.price = MathRound(rate / ticksize) * ticksize;
      request.deviation = _slippage;
      request.sl = MathRound(_stop / ticksize) * ticksize;
      request.tp = MathRound(_limit / ticksize) * ticksize;
      request.magic = _magicNumber;
      if (_comment != "")
         request.comment = _comment;
      if (_btcAccount)
         request.type_filling = SYMBOL_FILLING_FOK;
      MqlTradeResult result;
      ZeroMemory(result);
      bool res = OrderSend(request, result);
      switch (result.retcode)
      {
         case TRADE_RETCODE_INVALID_FILL:
            error = "Invalid order filling type";
            return 0;
         case TRADE_RETCODE_LONG_ONLY:
            error = "Only long trades are allowed for " + _instrument;
            return 0;
         case TRADE_RETCODE_INVALID_VOLUME:
            {
               double minVolume = SymbolInfoDouble(_instrument, SYMBOL_VOLUME_MIN);
               error = "Invalid volume in the request. Min volume is: " + DoubleToString(minVolume);
            }
            return 0;
         case TRADE_RETCODE_INVALID_PRICE:
            error = "Invalid price in the request";
            return 0;
         case TRADE_RETCODE_INVALID_STOPS:
            {
               int filling = (int)SymbolInfoInteger(_instrument, SYMBOL_ORDER_MODE); 
               if ((filling & SYMBOL_ORDER_SL) != SYMBOL_ORDER_SL)
               {
                  error = "Stop loss in now allowed for " + _instrument;
                  return 0;
               }

               int minStopDistancePoints = (int)SymbolInfoInteger(_instrument, SYMBOL_TRADE_STOPS_LEVEL);
               double point = SymbolInfoDouble(_instrument, SYMBOL_POINT);
               double price = request.stoplimit > 0.0 ? request.stoplimit : request.price;
               if (MathRound(MathAbs(price - request.sl) / point) < minStopDistancePoints)
               {
                  error = "Your stop level is too close. The minimal distance allowed is " + IntegerToString(minStopDistancePoints) + " points";
               }
               else
               {
                  error = "Invalid stops in the request";
               }
            }
            return 0;
         case TRADE_RETCODE_DONE:
            break;
         default:
            error = "Unknown error: " + IntegerToString(result.retcode);
            return 0;
      }
      return result.order;
   }
};
#endif
// Position cap v.1.1
interface IPositionCapStrategy
{
public:
   virtual bool IsLimitHit() = 0;
};

class PositionCapStrategy : public IPositionCapStrategy
{
   int _totalPositions;
   string _symbol;
   bool _useMagicNumber;
   int _magicNumber;
public:
   PositionCapStrategy(const int totalPositions)
   {
      _totalPositions = totalPositions;
      _symbol = "";
      _useMagicNumber = false;
   }

   PositionCapStrategy* WhenSymbol(string symbol)
   {
      _symbol = symbol;
      return &this;
   }

   PositionCapStrategy* WhenMagicNumber(int magicNumber)
   {
      _useMagicNumber = true;
      _magicNumber = magicNumber;
      return &this;
   }

   bool IsLimitHit()
   {
      TradesIterator it();
      if (_symbol != "")
         it.WhenSymbol(_symbol);
      if (_useMagicNumber)
         it.WhenMagicNumber(_magicNumber);
      int positions = it.Count();
      return positions >= _totalPositions;
   }
};

class NoPositionCapStrategy : public IPositionCapStrategy
{
public:
   bool IsLimitHit()
   {
      return false;
   }
};
// Trade controller v.2.0

#include <Trade\Trade.mqh>
// Breakeven controller v. 1.4
class BreakevenController
{
   ulong _order;
   bool _finished;
   double _trigger;
   double _target;
public:
   BreakevenController()
   {
      _finished = false;
   }
   
   bool SetOrder(const ulong order, const double trigger, const double target)
   {
      if (!_finished)
      {
         return false;
      }
      _finished = false;
      _trigger = trigger;
      _target = target;
      _order = order;
      return true;
   }

   void DoLogic()
   {
      if (_finished || !OrderSelect(_order))
      {
         _finished = true;
         return;
      }

      string symbol = OrderGetString(ORDER_SYMBOL);
      int type = (int)OrderGetInteger(ORDER_TYPE);
      if (type == ORDER_TYPE_BUY)
      {
         if (SymbolInfoDouble(symbol, SYMBOL_ASK) >= _trigger)
         {
            string error;
            bool res = TradingCommands::MoveSL(_order, _target, error);
            if (!res)
            {
               return;
            }
            _finished = true;
         }
      } 
      else if (type == ORDER_TYPE_SELL) 
      {
         if (SymbolInfoDouble(symbol, SYMBOL_BID) < _trigger) 
         {
            string error;
            bool res = TradingCommands::MoveSL(_order, _target, error);
            if (!res)
            {
               return;
            }
            _finished = true;
         }
      } 
   }
};

// Close on opposite strategy interface v1.0

#ifndef ICloseOnOppositeStrategy_IMP
#define ICloseOnOppositeStrategy_IMP

interface ICloseOnOppositeStrategy
{
public:
   virtual void DoClose(const OrderSide side) = 0;
};

#endif

// Order action (abstract) v1.0
// Used to execute action on orders

// AAction v1.0



#ifndef AAction_IMP

class AAction : public IAction
{
protected:
   int _references;
   AAction()
   {
      _references = 1;
   }
public:
   void AddRef()
   {
      ++_references;
   }

   void Release()
   {
      --_references;
      if (_references == 0)
         delete &this;
   }
};

#define AAction_IMP

#endif
#ifndef AOrderAction_IMP
#define AOrderAction_IMP
class AOrderAction : public AAction
{
protected:
   ulong _currentTicket;
public:
   virtual bool DoAction(ulong ticket)
   {
      _currentTicket = ticket;
      return DoAction(0, 0);
   }
};

#endif

class TradingController
{
   ENUM_TIMEFRAMES _entryTimeframe;
   ENUM_TIMEFRAMES _exitTimeframe;
   datetime _lastActionTime;
   double _lastLot;
   ActionOnConditionLogic* actions;
   Signaler *_signaler;
   datetime _lastLimitPositionMessage;
   datetime _lastEntryTime;
   datetime _lastExitTime;
   TradingCalculator *_calculator;
   ICondition* _longCondition;
   ICondition* _shortCondition;
   ICondition* _longFilterCondition;
   ICondition* _shortFilterCondition;
   ICondition* _exitLongCondition;
   ICondition* _exitShortCondition;
   #ifdef MARTINGALE_FEATURE
   IMartingaleStrategy *_shortMartingale;
   IMartingaleStrategy *_longMartingale;
   #endif
   IMoneyManagementStrategy *_longMoneyManagement[];
   IMoneyManagementStrategy *_shortMoneyManagement[];
   ICloseOnOppositeStrategy *_closeOnOpposite;
   #ifdef POSITION_CAP_FEATURE
   IPositionCapStrategy *_longPositionCap;
   IPositionCapStrategy *_shortPositionCap;
   #endif
   IEntryStrategy *_entryStrategy;
   string _algorithmId;
   ActionOnConditionLogic* _actions;
   AOrderAction* _orderHandlers[];
   TradingMode _entryLogic;
   TradingMode _exitLogic;
   bool _ecnBroker;
   int _logFile;
public:
   TradingController(TradingCalculator *calculator, 
                     ENUM_TIMEFRAMES entryTimeframe, 
                     ENUM_TIMEFRAMES exitTimeframe, 
                     Signaler *signaler, 
                     const string algorithmId = "")
   {
      _lastLimitPositionMessage = 0;
      _ecnBroker = false;
      _entryLogic = TradingModeOnBarClose;
      _exitLogic = TradingModeLive;
      _actions = NULL;
      _algorithmId = algorithmId;
      #ifdef POSITION_CAP_FEATURE
      _longPositionCap = NULL;
      _shortPositionCap = NULL;
      #endif
      _closeOnOpposite = NULL;
      #ifdef MARTINGALE_FEATURE
      _shortMartingale = NULL;
      _longMartingale = NULL;
      #endif
      _longCondition = NULL;
      _shortCondition = NULL;
      _longFilterCondition = NULL;
      _shortFilterCondition = NULL;
      _calculator = calculator;
      _signaler = signaler;
      _entryTimeframe = entryTimeframe;
      _exitTimeframe = exitTimeframe;
      _lastLot = lots_value;
      _exitLongCondition = NULL;
      _exitShortCondition = NULL;
      _logFile = -1;
   }

   ~TradingController()
   {
      if (_logFile != -1)
      {
         FileClose(_logFile);
      }
      for (int i = 0; i < ArraySize(_orderHandlers); ++i)
      {
         delete _orderHandlers[i];
      }
      delete _actions;
      delete _entryStrategy;
      #ifdef POSITION_CAP_FEATURE
      delete _longPositionCap;
      delete _shortPositionCap;
      #endif
      delete _closeOnOpposite;
      for (int i = 0; i < ArraySize(_longMoneyManagement); ++i)
      {
         delete _longMoneyManagement[i];
      }
      for (int i = 0; i < ArraySize(_shortMoneyManagement); ++i)
      {
         delete _shortMoneyManagement[i];
      }
      #ifdef MARTINGALE_FEATURE
      delete _shortMartingale;
      delete _longMartingale;
      #endif
      if (_exitLongCondition != NULL)
         _exitLongCondition.Release();
      if (_exitShortCondition != NULL)
         _exitShortCondition.Release();
      delete _calculator;
      delete _signaler;
      if (_longCondition != NULL)
         _longCondition.Release();
      if (_shortCondition != NULL)
         _shortCondition.Release();
      if (_longFilterCondition != NULL)
         _longFilterCondition.Release();
      if (_shortFilterCondition != NULL)
         _shortFilterCondition.Release();
   }

   void AddOrderAction(AOrderAction* orderAction)
   {
      int count = ArraySize(_orderHandlers);
      ArrayResize(_orderHandlers, count + 1);
      _orderHandlers[count] = orderAction;
      orderAction.AddRef();
   }
   void SetECNBroker(bool ecn) { _ecnBroker = ecn; }
   void SetPrintLog(string logFile)
   {
      _logFile = FileOpen(logFile, FILE_WRITE | FILE_CSV, ",");
   }
   void SetEntryLogic(TradingMode logicType) { _entryLogic = logicType; }
   void SetExitLogic(TradingMode logicType) { _exitLogic = logicType; }
   void SetActions(ActionOnConditionLogic* __actions) { _actions = __actions; }
   void SetLongCondition(ICondition *condition) { _longCondition = condition; }
   void SetShortCondition(ICondition *condition) { _shortCondition = condition; }
   void SetLongFilterCondition(ICondition *condition) { _longFilterCondition = condition; }
   void SetShortFilterCondition(ICondition *condition) { _shortFilterCondition = condition; }
   void SetExitLongCondition(ICondition *condition) { _exitLongCondition = condition; }
   void SetExitShortCondition(ICondition *condition) { _exitShortCondition = condition; }
   #ifdef MARTINGALE_FEATURE
   void SetShortMartingaleStrategy(IMartingaleStrategy *martingale) { _shortMartingale = martingale; }
   void SetLongMartingaleStrategy(IMartingaleStrategy *martingale) { _longMartingale = martingale; }
   #endif
   void AddLongMoneyManagement(IMoneyManagementStrategy *moneyManagement)
   {
      int count = ArraySize(_longMoneyManagement);
      ArrayResize(_longMoneyManagement, count + 1);
      _longMoneyManagement[count] = moneyManagement;
   }
   void AddShortMoneyManagement(IMoneyManagementStrategy *moneyManagement)
   {
      int count = ArraySize(_shortMoneyManagement);
      ArrayResize(_shortMoneyManagement, count + 1);
      _shortMoneyManagement[count] = moneyManagement;
   }
   void SetCloseOnOpposite(ICloseOnOppositeStrategy *closeOnOpposite) { _closeOnOpposite = closeOnOpposite; }
   #ifdef POSITION_CAP_FEATURE
      void SetLongPositionCap(IPositionCapStrategy *positionCap) { _longPositionCap = positionCap; }
      void SetShortPositionCap(IPositionCapStrategy *positionCap) { _shortPositionCap = positionCap; }
   #endif
   void SetEntryStrategy(IEntryStrategy *entryStrategy) { _entryStrategy = entryStrategy; }

   void DoTrading()
   {
      int entryTradePeriod = _entryLogic == TradingModeLive ? 0 : 1;
      datetime entryTime = iTime(_calculator.GetSymbolInfo().GetSymbol(), _entryTimeframe, entryTradePeriod);
      _actions.DoLogic(entryTradePeriod, entryTime);
      #ifdef MARTINGALE_FEATURE
         DoMartingale(_shortMartingale);
         DoMartingale(_longMartingale);
      #endif
      string entryLongLog = "";
      string entryShortLog = "";
      string exitLongLog = "";
      string exitShortLog = "";
      if (EntryAllowed(entryTime))
      {
         if (DoEntryLogic(entryTradePeriod, entryTime, entryLongLog, entryShortLog))
         {
            _lastActionTime = entryTime;
         }
         _lastEntryTime = entryTime;
      }

      int exitTradePeriod = _exitLogic == TradingModeLive ? 0 : 1;
      datetime exitTime = iTime(_calculator.GetSymbolInfo().GetSymbol(), _exitTimeframe, exitTradePeriod);
      if (ExitAllowed(exitTime))
      {
         DoExitLogic(exitTradePeriod, exitTime, exitLongLog, exitShortLog);
         _lastExitTime = exitTime;
      }
      if (_logFile != -1 && (entryLongLog != "" || entryShortLog != "" || exitLongLog != "" || exitShortLog != ""))
      {
         FileWrite(_logFile, TimeToString(TimeCurrent()), 
            "Entry long: " + entryLongLog, 
            "Entry short: " + entryShortLog, 
            "Exit long: " + exitLongLog, 
            "Exit short: " + exitShortLog);
      }
   }
private:
   bool ExitAllowed(datetime exitTime)
   {
      return _exitLogic != TradingModeOnBarClose || _lastExitTime != exitTime;
   }

   void DoExitLogic(int exitTradePeriod, datetime date, string& longLog, string& shortLog)
   {
      if (_logFile != -1)
      {
         longLog = _exitLongCondition.GetLogMessage(exitTradePeriod, date);
         shortLog = _exitShortCondition.GetLogMessage(exitTradePeriod, date);
      }
      if (_exitLongCondition.IsPass(exitTradePeriod, date))
      {
         if (_entryStrategy.Exit(BuySide) > 0)
            _signaler.SendNotifications("Exit Buy");
      }
      if (_exitShortCondition.IsPass(exitTradePeriod, date))
      {
         if (_entryStrategy.Exit(SellSide) > 0)
            _signaler.SendNotifications("Exit Sell");
      }
   }

   bool EntryAllowed(datetime entryTime)
   {
      if (_entryLogic == TradingModeOnBarClose)
         return _lastEntryTime != entryTime;
      return _lastActionTime != entryTime;
   }

   bool DoEntryLongLogic(int period, datetime date, string& logMessage)
   {
      if (_logFile != -1)
      {
         logMessage = _longCondition.GetLogMessage(period, date);
      }
      if (!_longCondition.IsPass(period, date))
      {
         return false;
      }
      if (_longFilterCondition != NULL && !_longFilterCondition.IsPass(period, date))
      {
         return false;
      }
      _closeOnOpposite.DoClose(SellSide);
      #ifdef POSITION_CAP_FEATURE
         if (_longPositionCap.IsLimitHit())
         {
            if (_lastLimitPositionMessage != date)
            {
               _signaler.SendNotifications("Positions limit has been reached");
            }
            _lastLimitPositionMessage = date;
            return false;
         }
      #endif
      for (int i = 0; i < ArraySize(_longMoneyManagement); ++i)
      {
         ulong order = _entryStrategy.OpenPosition(period, BuySide, _longMoneyManagement[i], _algorithmId, _ecnBroker);
         if (order >= 0)
         {
            for (int orderHandlerIndex = 0; orderHandlerIndex < ArraySize(_orderHandlers); ++orderHandlerIndex)
            {
               _orderHandlers[orderHandlerIndex].DoAction(order);
            }
            #ifdef MARTINGALE_FEATURE
               _longMartingale.OnOrder(order);
            #endif
         }
      }
      _signaler.SendNotifications("Buy");
      return true;
   }

   bool DoEntryShortLogic(int period, datetime date, string& logMessage)
   {
      if (_logFile)
      {
         logMessage = _shortCondition.GetLogMessage(period, date);
      }
      if (!_shortCondition.IsPass(period, date))
      {
         return false;
      }
      if (_shortFilterCondition != NULL && !_shortFilterCondition.IsPass(period, date))
      {
         return false;
      }
      _closeOnOpposite.DoClose(BuySide);
      #ifdef POSITION_CAP_FEATURE
         if (_shortPositionCap.IsLimitHit())
         {
            if (_lastLimitPositionMessage != date)
            {
               _signaler.SendNotifications("Positions limit has been reached");
            }
            _lastLimitPositionMessage = date;
            return false;
         }
      #endif
      for (int i = 0; i < ArraySize(_shortMoneyManagement); ++i)
      {
         ulong order = _entryStrategy.OpenPosition(period, SellSide, _shortMoneyManagement[i], _algorithmId, _ecnBroker);
         if (order >= 0)
         {
            for (int orderHandlerIndex = 0; orderHandlerIndex < ArraySize(_orderHandlers); ++orderHandlerIndex)
            {
               _orderHandlers[orderHandlerIndex].DoAction(order);
            }
            #ifdef MARTINGALE_FEATURE
               _shortMartingale.OnOrder(order);
            #endif
         }
      }
      _signaler.SendNotifications("Sell");
      return true;
   }

   bool DoEntryLogic(int entryTradePeriod, datetime date, string& longLog, string& shortLog)
   {
      bool longOpened = DoEntryLongLogic(entryTradePeriod, date, longLog);
      bool shortOpened = DoEntryShortLogic(entryTradePeriod, date, shortLog);
      return longOpened || shortOpened;
   }

   #ifdef MARTINGALE_FEATURE
   void DoMartingale(IMartingaleStrategy *martingale)
   {
      OrderSide anotherSide;
      if (martingale.NeedAnotherPosition(anotherSide))
      {
         double initialLots = OrderLots();
         IMoneyManagementStrategy* moneyManagement = martingale.GetMoneyManagement();
         ulong order = _entryStrategy.OpenPosition(0, anotherSide, moneyManagement, "Martingale position", _ecnBroker);
         if (order >= 0)
         {
            // if (_printLog)
            // {
            //    double newLots = 0;
            //    if (OrderSelect(order, SELECT_BY_TICKET, MODE_TRADES))
            //    {
            //       newLots = OrderLots();
            //    }
            //    Print("Opening martingale position. Initial lots: " + DoubleToString(initialLots) 
            //       + ". New martingale lots: " + DoubleToString(newLots));
            // }
            martingale.OnOrder(order);
         }
         if (anotherSide == BuySide)
            _signaler.SendNotifications("Opening martingale long position");
         else
            _signaler.SendNotifications("Opening martingale short position");
      }
   }
   #endif
};
// Close on opposite strategy v1.0



#ifndef DoCloseOnOppositeStrategy_IMP
#define DoCloseOnOppositeStrategy_IMP

class DoCloseOnOppositeStrategy : public ICloseOnOppositeStrategy
{
   int _magicNumber;
public:
   DoCloseOnOppositeStrategy(const int magicNumber)
   {
      _magicNumber = magicNumber;
   }

   void DoClose(const OrderSide side)
   {
      TradesIterator toClose();
      toClose.WhenSide(side);
      toClose.WhenMagicNumber(_magicNumber);
      TradingCommands::CloseTrades(toClose);
   }
};
#endif
// Don't close on opposite strategy v1.0



#ifndef DontCloseOnOppositeStrategy_IMP
#define DontCloseOnOppositeStrategy_IMP
class DontCloseOnOppositeStrategy : public ICloseOnOppositeStrategy
{
public:
   void DoClose(const OrderSide side)
   {
      // do nothing
   }
};

#endif
// Money management strategy v1.0


// Stop Loss and amount strategy interface v1.0

#ifndef IStopLossAndAmountStrategy_IMP
#define IStopLossAndAmountStrategy_IMP

class IStopLossAndAmountStrategy
{
public:
   virtual void GetStopLossAndAmount(const int period, const double entryPrice, double &amount, double &stopLoss) = 0;
};

#endif
// Take profit strategy interface v1.0

#ifndef ITakeProfitStrategy_IMP
#define ITakeProfitStrategy_IMP

class ITakeProfitStrategy
{
public:
   virtual void GetTakeProfit(const int period, const double entryPrice, double stopLoss, double amount, double& takeProfit) = 0;
};

#endif

#ifndef MoneyManagementStrategy_IMP
#define MoneyManagementStrategy_IMP

class MoneyManagementStrategy : public IMoneyManagementStrategy
{
public:
   IStopLossAndAmountStrategy* _stopLossAndAmount;
   ITakeProfitStrategy* _takeProfit;

   MoneyManagementStrategy(IStopLossAndAmountStrategy* stopLossAndAmount, ITakeProfitStrategy* takeProfit)
   {
      _stopLossAndAmount = stopLossAndAmount;
      _takeProfit = takeProfit;
   }

   ~MoneyManagementStrategy()
   {
      delete _stopLossAndAmount;
      delete _takeProfit;
   }

   void Get(const int period, const double entryPrice, double &amount, double &stopLoss, double &takeProfit)
   {
      _stopLossAndAmount.GetStopLossAndAmount(period, entryPrice, amount, stopLoss);
      _takeProfit.GetTakeProfit(period, entryPrice, stopLoss, amount, takeProfit);
   }
};

#endif
// Default lots provider v1.0

// Lots provider interface v1.0

#ifndef ILotsProvider_IMP
#define ILotsProvider_IMP
class ILotsProvider
{
public:
   virtual double GetLots(double stopLoss) = 0;
};
#endif



#ifndef DefaultLotsProvider_IMP
#define DefaultLotsProvider_IMP
class DefaultLotsProvider : public ILotsProvider
{
   PositionSizeType _lotsType;
   double _lots;
   TradingCalculator *_calculator;
public:
   DefaultLotsProvider(TradingCalculator *calculator, PositionSizeType lotsType, double lots)
   {
      _calculator = calculator;
      _lotsType = lotsType;
      _lots = lots;
   }

   virtual double GetLots(double stopLoss)
   {
      return _calculator.GetLots(_lotsType, _lots, BuySide, 0, 0);
   }
};
#endif
// Stop loss and amount strategy for position size risk v1.1




#ifndef PositionSizeRiskStopLossAndAmountStrategy_IMP
#define PositionSizeRiskStopLossAndAmountStrategy_IMP

class PositionSizeRiskStopLossAndAmountStrategy : public IStopLossAndAmountStrategy
{
   double _lots;
   TradingCalculator *_calculator;
   StopLimitType _stopLossType;
   double _stopLoss;
   bool _isBuy;
public:
   PositionSizeRiskStopLossAndAmountStrategy(TradingCalculator *calculator, double lots,
      StopLimitType stopLossType, double stopLoss, bool isBuy)
   {
      _calculator = calculator;
      _lots = lots;
      _stopLossType = stopLossType;
      _stopLoss = stopLoss;
      _isBuy = isBuy;
   }
   
   void GetStopLossAndAmount(const int period, const double entryPrice, double &amount, double &stopLoss)
   {
      stopLoss = _calculator.CalculateStopLoss(_isBuy, _stopLoss, _stopLossType, 0.0, entryPrice);
      amount = _calculator.GetLots(PositionSizeRisk, _lots, _isBuy ? BuySide : SellSide, entryPrice, _isBuy ? (entryPrice - stopLoss) : (stopLoss - entryPrice));
   }
};

#endif
// Default stop loss and amount strategy v1.0




#ifndef DefaultStopLossAndAmountStrategy_IMP
#define DefaultStopLossAndAmountStrategy_IMP

class DefaultStopLossAndAmountStrategy : public IStopLossAndAmountStrategy
{
   TradingCalculator *_calculator;
   StopLimitType _stopLossType;
   double _stopLoss;
   bool _isBuy;
   ILotsProvider* _lotsProvider;
public:
   DefaultStopLossAndAmountStrategy(TradingCalculator *calculator, ILotsProvider* lotsProvider,
      StopLimitType stopLossType, double stopLoss, bool isBuy)
   {
      _lotsProvider = lotsProvider;
      _isBuy = isBuy;
      _calculator = calculator;
      _stopLossType = stopLossType;
      _stopLoss = stopLoss;
   }

   ~DefaultStopLossAndAmountStrategy()
   {
      delete _lotsProvider;
   }
   
   void GetStopLossAndAmount(const int period, const double entryPrice, double &amount, double &stopLoss)
   {
      amount = _lotsProvider.GetLots(0.0);
      stopLoss = _calculator.CalculateStopLoss(_isBuy, _stopLoss, _stopLossType, amount, entryPrice);
   }
};

#endif
// Default take profit strategy v1.1




#ifndef DefaultTakeProfitStrategy_IMP
#define DefaultTakeProfitStrategy_IMP

class DefaultTakeProfitStrategy : public ITakeProfitStrategy
{
   StopLimitType _takeProfitType;
   TradingCalculator *_calculator;
   double _takeProfit;
   bool _isBuy;
public:
   DefaultTakeProfitStrategy(TradingCalculator *calculator, StopLimitType takeProfitType, double takeProfit, bool isBuy)
   {
      _calculator = calculator;
      _takeProfitType = takeProfitType;
      _takeProfit = takeProfit;
      _isBuy = isBuy;
   }

   virtual void GetTakeProfit(const int period, const double entryPrice, double stopLoss, double amount, double& takeProfit)
   {
      takeProfit = _calculator.CalculateTakeProfit(_isBuy, _takeProfit, _takeProfitType, amount, entryPrice);
   }
};

#endif
// Risk to reward take profit strategy v1.1



#ifndef RiskToRewardTakeProfitStrategy_IMP
#define RiskToRewardTakeProfitStrategy_IMP

class RiskToRewardTakeProfitStrategy : public ITakeProfitStrategy
{
   double _takeProfit;
   bool _isBuy;
public:
   RiskToRewardTakeProfitStrategy(double takeProfit, bool isBuy)
   {
      _isBuy = isBuy;
      _takeProfit = takeProfit;
   }

   virtual void GetTakeProfit(const int period, const double entryPrice, double stopLoss, double amount, double& takeProfit)
   {
      if (_isBuy)
         takeProfit = entryPrice + MathAbs(entryPrice - stopLoss) * _takeProfit / 100;
      else
         takeProfit = entryPrice - MathAbs(entryPrice - stopLoss) * _takeProfit / 100;
   }
};
#endif
// ATR take profit strategy v1.0



#ifndef ATRTakeProfitStrategy_IMP
#define ATRTakeProfitStrategy_IMP

class ATRTakeProfitStrategy : public ITakeProfitStrategy
{
   int _period;
   double _multiplicator;
   bool _isBuy;
   string _symbol;
   ENUM_TIMEFRAMES _timeframe;
   int _atr;
public:
   ATRTakeProfitStrategy(string symbol, ENUM_TIMEFRAMES timeframe, int period, double multiplicator, bool isBuy)
   {
      _symbol = symbol;
      _timeframe = timeframe;
      _period = period;
      _multiplicator = multiplicator;
      _isBuy = true;
      _atr = iATR(_symbol, _timeframe, _period);
   }
   ~ATRTakeProfitStrategy()
   {
      IndicatorRelease(_atr);
   }

   virtual void GetTakeProfit(const int period, const double entryPrice, double stopLoss, double amount, double& takeProfit)
   {
      double buffer[1];
      if (CopyBuffer(_atr, 0, period, 1, buffer) != 1)
      {
         return;
      }
      takeProfit = _isBuy ? (entryPrice + buffer[0]) : (entryPrice - buffer[0]);
   }
};
#endif




#ifndef MoneyManagementFunctions_IMP
#define MoneyManagementFunctions_IMP

MoneyManagementStrategy* CreateMoneyManagementStrategy(TradingCalculator* tradingCalculator, string symbol
   , ENUM_TIMEFRAMES timeframe, bool isBuy, PositionSizeType lotsType, double lotsValue
   , StopLossType stopLossType, double stopLossValue, TakeProfitType takeProfitType, double takeProfitValue, double takeProfitATRMult)
{
   ILotsProvider* lots = NULL;
   switch (lotsType)
   {
      case PositionSizeRisk:
      case PositionSizeRiskCurrency:
         break;
      default:
         lots = new DefaultLotsProvider(tradingCalculator, lotsType, lotsValue);
         break;
   }
   IStopLossAndAmountStrategy* sl = NULL;
   switch (stopLossType)
   {
      case SLDoNotUse:
         {
            if (lotsType == PositionSizeRisk)
               sl = new PositionSizeRiskStopLossAndAmountStrategy(tradingCalculator, lotsValue, StopLimitDoNotUse, stopLossValue, isBuy);
            else
               sl = new DefaultStopLossAndAmountStrategy(tradingCalculator, lots, StopLimitDoNotUse, stopLossValue, isBuy);
         }
         break;
      case SLPercent:
         {
            if (lotsType == PositionSizeRisk)
               sl = new PositionSizeRiskStopLossAndAmountStrategy(tradingCalculator, lotsValue, StopLimitPercent, stopLossValue, isBuy);
            else
               sl = new DefaultStopLossAndAmountStrategy(tradingCalculator, lots, StopLimitPercent, stopLossValue, isBuy);
         }
         break;
      case SLPips:
         {
            if (lotsType == PositionSizeRisk)
               sl = new PositionSizeRiskStopLossAndAmountStrategy(tradingCalculator, lotsValue, StopLimitPips, stopLossValue, isBuy);
            else
               sl = new DefaultStopLossAndAmountStrategy(tradingCalculator, lots, StopLimitPips, stopLossValue, isBuy);
         }
         break;
      case SLDollar:
         {
            if (lotsType == PositionSizeRisk)
               sl = new PositionSizeRiskStopLossAndAmountStrategy(tradingCalculator, lotsValue, StopLimitDollar, stopLossValue, isBuy);
            else
               sl = new DefaultStopLossAndAmountStrategy(tradingCalculator, lots, StopLimitDollar, stopLossValue, isBuy);
         }
         break;
      case SLAbsolute:
         {
            if (lotsType == PositionSizeRisk)
               sl = new PositionSizeRiskStopLossAndAmountStrategy(tradingCalculator, lotsValue, StopLimitAbsolute, stopLossValue, isBuy);
            else
               sl = new DefaultStopLossAndAmountStrategy(tradingCalculator, lots, StopLimitAbsolute, stopLossValue, isBuy);
         }
         break;
   }
   ITakeProfitStrategy* tp = NULL;
   switch (takeProfitType)
   {
      case TPDoNotUse:
         tp = new DefaultTakeProfitStrategy(tradingCalculator, StopLimitDoNotUse, takeProfitValue, isBuy);
         break;
      #ifdef TAKE_PROFIT_FEATURE
         case TPPercent:
            tp = new DefaultTakeProfitStrategy(tradingCalculator, StopLimitPercent, takeProfitValue, isBuy);
            break;
         case TPPips:
            tp = new DefaultTakeProfitStrategy(tradingCalculator, StopLimitPips, takeProfitValue, isBuy);
            break;
         case TPDollar:
            tp = new DefaultTakeProfitStrategy(tradingCalculator, StopLimitDollar, takeProfitValue, isBuy);
            break;
         case TPRiskReward:
            tp = new RiskToRewardTakeProfitStrategy(takeProfitValue, isBuy);
            break;
         case TPAbsolute:
            tp = new DefaultTakeProfitStrategy(tradingCalculator, StopLimitAbsolute, takeProfitValue, isBuy);
            break;
         case TPAtr:
            tp = new ATRTakeProfitStrategy(symbol, timeframe, (int)takeProfitValue, takeProfitATRMult, isBuy);
            break;
      #endif
   }
   
   return new MoneyManagementStrategy(sl, tp);
}
#endif

class EntryLongCondition : public ACondition
{
   int _indi;
public:
   EntryLongCondition(string symbol, ENUM_TIMEFRAMES timeframe)
      :ACondition(symbol, timeframe)
   {
      _indi = iCustom(_symbol, _timeframe, "HOLYGRAIL", MAIN_PERIOD, ADX_PERIOD);
   }

   ~EntryLongCondition()
   {
      IndicatorRelease(_indi);
   }

   virtual bool IsPass(const int period, const datetime date)
   {
      double buyValue[100];
      if (CopyBuffer(_indi, 0, period, 100, buyValue) != 100)
      {
         return false;
      }
      double sellValue[100];
      if (CopyBuffer(_indi, 1, period, 100, sellValue) != 100)
      {
         return false;
      }
      for (int i = 0; i < 100; ++i)
      {
         if (sellValue[i] != EMPTY_VALUE)
         {
            return false;
         }
         if (buyValue[i] != EMPTY_VALUE)
         {
            return true;
         }
      }
      return false;
   }
};

class EntryShortCondition : public ACondition
{
   int _indi;
public:
   EntryShortCondition(string symbol, ENUM_TIMEFRAMES timeframe)
      :ACondition(symbol, timeframe)
   {
      _indi = iCustom(_symbol, _timeframe, "HOLYGRAIL", MAIN_PERIOD, ADX_PERIOD);
   }

   ~EntryShortCondition()
   {
      IndicatorRelease(_indi);
   }

   virtual bool IsPass(const int period, const datetime date)
   {
      double buyValue[100];
      if (CopyBuffer(_indi, 0, period, 100, buyValue) != 100)
      {
         return false;
      }
      double sellValue[100];
      if (CopyBuffer(_indi, 1, period, 100, sellValue) != 100)
      {
         return false;
      }
      for (int i = 0; i < 100; ++i)
      {
         if (buyValue[i] != EMPTY_VALUE)
         {
            return false;
         }
         if (sellValue[i] != EMPTY_VALUE)
         {
            return true;
         }
      }
      return false;
   }
};

ICondition* CreateLongCondition(string symbol, ENUM_TIMEFRAMES timeframe)
{
   if (trading_side == ShortSideOnly)
   {
      return (ICondition *)new DisabledCondition();
   }

   AndCondition* condition = new AndCondition();
   condition.Add(new EntryLongCondition(symbol, timeframe), false);
   #ifdef ACT_ON_SWITCH_CONDITION
      ActOnSwitchCondition* switchCondition = new ActOnSwitchCondition(symbol, timeframe, (ICondition*) condition);
      condition.Release();
      return switchCondition;
   #else 
      return (ICondition*) condition;
   #endif
}

ICondition* CreateLongFilterCondition(string symbol, ENUM_TIMEFRAMES timeframe)
{
   if (trading_side == ShortSideOnly)
   {
      return (ICondition *)new DisabledCondition();
   }
   AndCondition* condition = new AndCondition();
   condition.Add(new NoCondition(), false);
   return condition;
}

ICondition* CreateShortCondition(string symbol, ENUM_TIMEFRAMES timeframe)
{
   if (trading_side == LongSideOnly)
   {
      return (ICondition *)new DisabledCondition();
   }

   AndCondition* condition = new AndCondition();
   condition.Add(new EntryShortCondition(symbol, timeframe), false);
   #ifdef ACT_ON_SWITCH_CONDITION
      ActOnSwitchCondition* switchCondition = new ActOnSwitchCondition(symbol, timeframe, (ICondition*) condition);
      condition.Release();
      return switchCondition;
   #else 
      return (ICondition*) condition;
   #endif
}

ICondition* CreateShortFilterCondition(string symbol, ENUM_TIMEFRAMES timeframe)
{
   if (trading_side == LongSideOnly)
   {
      return (ICondition *)new DisabledCondition();
   }
   AndCondition* condition = new AndCondition();
   condition.Add(new NoCondition(), false);
   return condition;
}

ICondition* CreateExitLongCondition(string symbol, ENUM_TIMEFRAMES timeframe)
{
   AndCondition* condition = new AndCondition();
   condition.Add(new DisabledCondition(), false);
   #ifdef ACT_ON_SWITCH_CONDITION
      ActOnSwitchCondition* switchCondition = new ActOnSwitchCondition(symbol, timeframe, (ICondition*) condition);
      condition.Release();
      return switchCondition;
   #else
      return (ICondition *)condition;
   #endif
}

ICondition* CreateExitShortCondition(string symbol, ENUM_TIMEFRAMES timeframe)
{
   AndCondition* condition = new AndCondition();
   condition.Add(new DisabledCondition(), false);
   #ifdef ACT_ON_SWITCH_CONDITION
      ActOnSwitchCondition* switchCondition = new ActOnSwitchCondition(symbol, timeframe, (ICondition*) condition);
      condition.Release();
      return switchCondition;
   #else
      return (ICondition *)condition;
   #endif
}

TradingController* controllers[];

TradingController* CreateController(const string symbol, ENUM_TIMEFRAMES timeframe, string &error)
{
   #ifdef TRADING_TIME_FEATURE
      ICondition* tradingTimeCondition = CreateTradingTimeCondition(start_time, stop_time, use_weekly_timing,
         week_start_day, week_start_time, week_stop_day, 
         week_stop_time, error);
      if (tradingTimeCondition == NULL)
         return NULL;
   #endif

   TradingCalculator* tradingCalculator = TradingCalculator::Create(symbol);
   if (!tradingCalculator.IsLotsValid(lots_value, lots_type, error))
   {
      #ifdef TRADING_TIME_FEATURE
      tradingTimeCondition.Release();
      #endif
      delete tradingCalculator;
      return NULL;
   }

   Signaler* signaler = new Signaler(symbol, timeframe);
   signaler.SetPopupAlert(Popup_Alert);
   signaler.SetEmailAlert(Email_Alert);
   signaler.SetPlaySound(Play_Sound, Sound_File);
   signaler.SetNotificationAlert(Notification_Alert);
   #ifdef ADVANCED_ALERTS
   signaler.SetAdvancedAlert(Advanced_Alert, Advanced_Key);
   #endif
   signaler.SetMessagePrefix(symbol + "/" + signaler.GetTimeframeStr() + ": ");
   
   TradingController* controller = new TradingController(tradingCalculator, timeframe, timeframe, signaler);
   
   ActionOnConditionLogic* actions = new ActionOnConditionLogic();
   controller.SetActions(actions);
   //controller.SetECNBroker(ecn_broker);
   
   //if (breakeven_type != StopLimitDoNotUse)
   {
      #ifndef USE_NET_BREAKEVEN
         // MoveStopLossOnProfitOrderAction* orderAction = new MoveStopLossOnProfitOrderAction(breakeven_type, breakeven_value, breakeven_level, signaler, actions);
         // controller.AddOrderAction(orderAction);
         // orderAction.Release();
      #endif
   }

   #ifdef STOP_LOSS_FEATURE
      switch (trailing_type)
      {
         case TrailingDontUse:
            break;
      #ifdef INDICATOR_BASED_TRAILING
         case TrailingIndicator:
            break;
      #endif
         case TrailingPips:
            {
               CreateTrailingAction* trailingAction = new CreateTrailingAction(trailing_start, trailing_step, actions);
               controller.AddOrderAction(trailingAction);
               trailingAction.Release();
            }
            break;
      }
   #endif

   #ifdef MARTINGALE_FEATURE
      switch (martingale_type)
      {
         case MartingaleDoNotUse:
            controller.SetShortMartingaleStrategy(new NoMartingaleStrategy());
            controller.SetLongMartingaleStrategy(new NoMartingaleStrategy());
            break;
         case MartingaleOnLoss:
            {
               PriceMovedFromTradeOpenCondition* condition = new PriceMovedFromTradeOpenCondition(symbol, timeframe, martingale_step_type, martingale_step);
               controller.SetShortMartingaleStrategy(new ActiveMartingaleStrategy(tradingCalculator, martingale_lot_sizing_type, martingale_lot_value, condition));
               controller.SetLongMartingaleStrategy(new ActiveMartingaleStrategy(tradingCalculator, martingale_lot_sizing_type, martingale_lot_value, condition));
               condition.Release();
            }
            break;
      }
   #endif

   AndCondition* longCondition = new AndCondition();
   longCondition.Add(CreateLongCondition(symbol, timeframe), false);
   AndCondition* shortCondition = new AndCondition();
   shortCondition.Add(CreateShortCondition(symbol, timeframe), false);
   #ifdef TRADING_TIME_FEATURE
      longCondition.Add(tradingTimeCondition, true);
      shortCondition.Add(tradingTimeCondition, true);
      tradingTimeCondition.Release();
   #endif

   ICondition* longFilterCondition = CreateLongFilterCondition(symbol, timeframe);
   ICondition* shortFilterCondition = CreateShortFilterCondition(symbol, timeframe);

   #ifdef WITH_EXIT_LOGIC
      controller.SetExitLogic(exit_logic);
      ICondition* exitLongCondition = CreateExitLongCondition(symbol, timeframe);
      ICondition* exitShortCondition = CreateExitShortCondition(symbol, timeframe);
   #else
      ICondition* exitLongCondition = new DisabledCondition();
      ICondition* exitShortCondition = new DisabledCondition();
   #endif

   switch (logic_direction)
   {
      case DirectLogic:
         controller.SetLongCondition(longCondition);
         controller.SetLongFilterCondition(longFilterCondition);
         controller.SetShortCondition(shortCondition);
         controller.SetShortFilterCondition(shortFilterCondition);
         controller.SetExitLongCondition(exitLongCondition);
         controller.SetExitShortCondition(exitShortCondition);
         break;
      case ReversalLogic:
         controller.SetLongCondition(shortCondition);
         controller.SetLongFilterCondition(shortFilterCondition);
         controller.SetShortCondition(longCondition);
         controller.SetShortFilterCondition(longFilterCondition);
         controller.SetExitLongCondition(exitShortCondition);
         controller.SetExitShortCondition(exitLongCondition);
         break;
   }
   #ifdef TRADING_TIME_FEATURE
      if (mandatory_closing)
      {
         NotCondition* condition = new NotCondition(tradingTimeCondition);
         IAction* action = new CloseAllAction(magic_number, slippage_points);
         actions.AddActionOnCondition(action, condition);
         action.Release();
         condition.Release();
      }
   #endif
   
   IMoneyManagementStrategy* longMoneyManagement = CreateMoneyManagementStrategy(tradingCalculator, symbol, timeframe, true
      , lots_type, lots_value, stop_loss_type, stop_loss_value, take_profit_type, take_profit_value, take_profit_atr_multiplicator);
   IMoneyManagementStrategy* shortMoneyManagement = CreateMoneyManagementStrategy(tradingCalculator, symbol, timeframe, false
      , lots_type, lots_value, stop_loss_type, stop_loss_value, take_profit_type, take_profit_value, take_profit_atr_multiplicator);
   controller.AddLongMoneyManagement(longMoneyManagement);
   controller.AddShortMoneyManagement(shortMoneyManagement);

   #ifdef NET_STOP_LOSS_FEATURE
      if (net_stop_loss_type != StopLimitDoNotUse)
      {
         MoveNetStopLossAction* action = new MoveNetStopLossAction(tradingCalculator, net_stop_loss_type, net_stop_loss_value, signaler, magic_number);
         #ifdef USE_NET_BREAKEVEN
            if (breakeven_type != StopLimitDoNotUse)
            {
               //TODO: use breakeven_type as well
               action.SetBreakeven(breakeven_value, breakeven_level);
            }
         #endif

         NoCondition* condition = new NoCondition();
         actions.AddActionOnCondition(action, condition);
         action.Release();
      }
   #endif
   #ifdef NET_TAKE_PROFIT_FEATURE
      if (net_take_profit_type != StopLimitDoNotUse)
      {
         IAction* action = new MoveNetTakeProfitAction(tradingCalculator, net_take_profit_type, net_take_profit_value, signaler, magic_number);
         NoCondition* condition = new NoCondition();
         actions.AddActionOnCondition(action, condition);
         action.Release();
      }
   #endif

   if (close_on_opposite)
      controller.SetCloseOnOpposite(new DoCloseOnOppositeStrategy(magic_number));
   else
      controller.SetCloseOnOpposite(new DontCloseOnOppositeStrategy());

   #ifdef POSITION_CAP_FEATURE
      if (position_cap)
      {
         controller.SetLongPositionCap(new PositionCapStrategy(BuySide, magic_number, no_of_buy_position, no_of_positions, symbol));
         controller.SetShortPositionCap(new PositionCapStrategy(SellSide, magic_number, no_of_sell_position, no_of_positions, symbol));
      }
      else
      {
         controller.SetLongPositionCap(new NoPositionCapStrategy());
         controller.SetShortPositionCap(new NoPositionCapStrategy());
      }
   #endif

   controller.SetEntryLogic(entry_logic);
//   #ifdef USE_MARKET_ORDERS
      controller.SetEntryStrategy(new MarketEntryStrategy(symbol, magic_number, slippage_points, actions));
   // #else
   //    IStream *longPrice = new LongEntryStream(symbol, timeframe);
   //    IStream *shortPrice = new ShortEntryStream(symbol, timeframe);
   //    controller.SetEntryStrategy(new PendingEntryStrategy(symbol, magic_number, slippage_points, longPrice, shortPrice, actions));
   // #endif
   if (print_log)
   {
      controller.SetPrintLog(log_file);
   }

   return controller;
}

int OnInit()
{
   string error;
   string sym_arr[];
   if (symbols != "")
   {
      StringSplit(symbols, ',', sym_arr);
   }
   else
   {
      ArrayResize(sym_arr, 1);
      sym_arr[0] = _Symbol;
   }
   int sym_count = ArraySize(sym_arr);
   for (int i = 0; i < sym_count; i++)
   {
      string symbol = sym_arr[i];
      TradingController* controller = CreateController(symbol, (ENUM_TIMEFRAMES)_Period, error);
      if (controller == NULL)
      {
         Print(error);
         return INIT_FAILED;
      }
      int controllersCount = ArraySize(controllers);
      ArrayResize(controllers, controllersCount + 1);
      controllers[controllersCount] = controller;
   }
   
   return INIT_SUCCEEDED;
}

void OnDeinit(const int reason)
{
   for (int i = 0; i < ArraySize(controllers); ++i)
   {
      delete controllers[i];
   }
}

void OnTick()
{
   for (int i = 0; i < ArraySize(controllers); ++i)
   {
      controllers[i].DoTrading();
   }
}