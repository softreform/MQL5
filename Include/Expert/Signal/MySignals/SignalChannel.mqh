//+------------------------------------------------------------------+
//|                                                SignalChannel.mqh |
//|                                  Copyright 2019, Marco Consiglio |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "@nick"
#property link      "https://www.mql5.com"
#property version   "1.00"
#include <Expert\ExpertSignal.mqh>
// wizard description start
//+------------------------------------------------------------------+
//| Description of the class                                         |
//| Title=Signals from Channel                                       |
//| Type=SignalAdvanced                                              |
//| Name=SignalChannel                                               |
//| Class=CSiChannel                                                 |
//| Page=                                                            |
//| Parameter=PeriodMA,int,12                                        |
//| Parameter=ShiftMA,int,0                                          |
//| Parameter=MethodMA,ENUM_MA_METHOD,MODE_EMA                       |
//| Parameter=AppliedMA,ENUM_APPLIED_PRICE,PRICE_CLOSE               |
//| Parameter=Limit,double,0.0                                       |
//| Parameter=StopLoss,double,50.0                                   |
//| Parameter=TakeProfit,double,50.0                                 |
//| Parameter=Expiration,int,10                                      |
//+------------------------------------------------------------------+
// wizard description end
//+------------------------------------------------------------------+
//| CSiChannel class.                                             |
//| Purpose: Class of trading signal generator when price            |
//|             crosses moving average,                              |
//|             entering on the subsequent back movement.            |
//|             It is derived from the CExpertSignal class.          |
//+------------------------------------------------------------------+
class CSiChannel : public CExpertSignal
{
protected:
   CiMA                 m_MA;
   CiOpen               m_open_ch;
   CiClose              m_close_ch;
   //--- Setup parameters
   int                  m_period_ma;      // averaging period of the MA
   int                  m_shift_ma;       // shift of the MA along the time axis       
   ENUM_MA_METHOD       m_method_ma;      // averaging method of the MA
   ENUM_APPLIED_PRICE   m_applied_ma;     // averaging object of the MA
   double               m_limit;          // level to place a pending order relative to the MA
   double               m_stop_loss;      // level to place a stop loss order relative to the open price
   double               m_take_profit;    // level to place a take profit order relative to the open price
   int                  m_expiration_ch;     // lifetime of a pending order in bars
   
public:
                        CSiChannel();
   //--- Methods to set the parameters
   void                 PeriodMA(int value)                 { m_period_ma=value;  }
   void                 ShiftMA(int value)                  { m_shift_ma=value;   }
   void                 MethodMA(ENUM_MA_METHOD value)      { m_method_ma=value;  }   
   void                 AppliedMA(ENUM_APPLIED_PRICE value) { m_applied_ma=value; }
   void                 Limit(double value)                 { m_limit=value;      }
   void                 StopLoss(double value)              { m_stop_loss=value;  }
   void                 TakeProfit(double value)            { m_take_profit=value;}
   void                 Expiration(int value)               { m_expiration_ch=value; }
   //--- Methods to validate the parameters
   virtual bool         ValidationSettings();
   //--- Method to validate the parameters
   virtual bool         InitIndicators(CIndicators *indicators);
   //--- Methods to generate signals to enter the market
   virtual bool      CheckOpenLong(double& price,double& sl,double& tp,datetime& expiration);
   virtual bool      CheckOpenShort(double& price,double& sl,double& tp,datetime& expiration);
   //--- Methods to generate signals of pending order modification
   virtual bool      CheckTrailingOrderLong(COrderInfo* order,double& price);
   virtual bool      CheckTrailingOrderShort(COrderInfo* order,double& price);
      
protected:
   //--- Object initialization method
   bool                 InitMA(CIndicators *indicators);
   bool                 InitOpen(CIndicators *indicators);
   bool                 InitClose(CIndicators *indicators);
   //--- Methods to access object data
   double               MA(int index)                       { return(m_MA.Main(index));      }
   double               Open(int index)                     { return(m_open_ch.GetData(index)); }
   double               Close(int index)                    { return(m_close_ch.GetData(index));}
};


void CSiChannel::CSiChannel()
  {
//--- Setting the default values
   m_period_ma  =12;
   m_shift_ma   =0;
   m_method_ma  =MODE_EMA;
   m_applied_ma =PRICE_CLOSE;
   m_limit      =0.0;
   m_stop_loss  =50.0;
   m_take_profit=50.0;
   m_expiration_ch =10;
  }
//+------------------------------------------------------------------+
//| Validation of the setup parameters.                              |
//| INPUT:  No.                                                      |
//| OUTPUT: true if the settings are correct, otherwise false.       |
//| REMARK: No.                                                      |
//+------------------------------------------------------------------+
bool CSiChannel::ValidationSettings(void)
{
   if(m_period_ma<=0)
     {
      printf(__FUNCTION__+": MA period must be greater than zero!");
      return(false);
     }
   return(true);  
}

//+------------------------------------------------------------------+
//| Initialization of indicators and timeseries.                     |
//| INPUT:  indicators - pointer to the object - collection of       |
//|                      indicators and timeseries.                  |
//| OUTPUT: true in case of success, otherwise false.                |
//| REMARK: No.                                                      |
//+------------------------------------------------------------------+
bool CSiChannel::InitIndicators(CIndicators *indicators)
{
   if(indicators==NULL)      return(false);
   
   if(!InitMA(indicators))   return(false);
   
   if(!InitOpen(indicators)) return(false);
   
   if(!InitClose(indicators))return(false);
   
   return(true);
}

//+------------------------------------------------------------------+
//| Initialization of the moving average                             |
//| INPUT:  indicators - pointer to the object - collection of       |
//|                      indicators and timeseries.                  |
//| OUTPUT: true in case of success, otherwise false.                |
//| REMARK: No.                                                      |
//+------------------------------------------------------------------+
bool CSiChannel::InitMA(CIndicators *indicators)
{
   if(!m_MA.Create(m_symbol.Name(),m_period,m_period_ma,m_shift_ma,m_method_ma,m_applied_ma))
     {
      printf(__FUNCTION__+": object initialization error");
      return(false);      
     }
   m_MA.BufferResize(3+m_shift_ma);
   
   if(!indicators.Add(GetPointer(m_MA)))
     {
      printf(__FUNCTION__+": object adding error");
      return(false);
     }
     
   return(true);
}

//+------------------------------------------------------------------+
//| Initialization of the timeseries of open prices.                 |
//| INPUT:  indicators - pointer to the object - collection of       |
//|                      indicators and timeseries.                  |
//| OUTPUT: true in case of success, otherwise false.                |
//| REMARK: No.                                                      |
//+------------------------------------------------------------------+
bool CSiChannel::InitOpen(CIndicators *indicators)
{

   if(!m_open_ch.Create(m_symbol.Name(),m_period))
     {
      printf(__FUNCTION__+": object initialization error");
      return(false);
     }
     
   if(!indicators.Add(GetPointer(m_open_ch)))
     {
      printf(__FUNCTION__+": object adding error");
      return(false);
     }
     
   return(true);
}

//+------------------------------------------------------------------+
//| Initialization of the timeseries of close prices.                |
//| INPUT:  indicators - pointer to the object - collection of       |
//|                      indicators and timeseries.                  |
//| OUTPUT: true in case of success, otherwise false.                |
//| REMARK: No.                                                      |
//+------------------------------------------------------------------+
bool CSiChannel::InitClose(CIndicators *indicators)
{

   if(!m_close_ch.Create(m_symbol.Name(),m_period))
     {
      printf(__FUNCTION__+": object initialization error");
      return(false);
     }
     
   if(!indicators.Add(GetPointer(m_close_ch)))
     {
      printf(__FUNCTION__+": object adding error");
      return(false);
     }
     
   return(true);
}

//+------------------------------------------------------------------+
//| Check whether a Buy condition is fulfilled                       |
//| INPUT:  price      - variable for open price                     |
//|         sl         - variable for stop loss price,               |
//|         tp         - variable for take profit price              |
//|         expiration - variable for expiration time.               |
//| OUTPUT: true if the condition is fulfilled, otherwise false.     |
//| REMARK: No.                                                      |
//+------------------------------------------------------------------+
bool CSiChannel::CheckOpenLong(double& price,double& sl,double& tp,datetime& expiration)
  {
//--- Preparing the data
   double spread=m_symbol.Ask()-m_symbol.Bid();
   double ma    =MA(1);
   double unit  =PriceLevelUnit();
//--- Checking the condition
   if(Open(1)<ma && Close(1)>ma && ma>MA(2))
     {
      price=m_symbol.NormalizePrice(ma-m_limit*unit+spread);
      sl   =m_symbol.NormalizePrice(price-m_stop_loss*unit);
      tp   =m_symbol.NormalizePrice(price+m_take_profit*unit);
      expiration+=m_expiration_ch*PeriodSeconds(m_period);
      //--- Condition is fulfilled
      return(true);
     }
//--- Condition is not fulfilled
   return(false);
  }
//+------------------------------------------------------------------+
//| Check whether a Sell condition is fulfilled.                     |
//| INPUT:  price      - variable for open price,                    |
//|         sl         - variable for stop loss,                     |
//|         tp         - variable for take profit                    |
//|         expiration - variable for expiration time.               |
//| OUTPUT: true if the condition is fulfilled, otherwise false.     |
//| REMARK: No.                                                      |
//+------------------------------------------------------------------+
bool CSiChannel::CheckOpenShort(double& price,double& sl,double& tp,datetime& expiration)
  {
//--- Preparing the data
   double ma  =MA(1);
   double unit=PriceLevelUnit();
//--- Checking the condition
   if(Open(1)>ma && Close(1)<ma && ma<MA(2))
     {
      price=m_symbol.NormalizePrice(ma+m_limit*unit);
      sl   =m_symbol.NormalizePrice(price+m_stop_loss*unit);
      tp   =m_symbol.NormalizePrice(price-m_take_profit*unit);
      expiration+=m_expiration_ch*PeriodSeconds(m_period);
      //--- Condition is fulfilled
      return(true);
     }
//--- Condition is not fulfilled
   return(false);
  }
//+------------------------------------------------------------------+
//| Check whether the condition of modification                      |
//|  of a Buy order is fulfilled.                                    |
//| INPUT:  order - pointer at the object-order,                     |
//|         price - a variable for the new open price.               |
//| OUTPUT: true if the condition is fulfilled, otherwise false.     |
//| REMARK: No.                                                      |
//+------------------------------------------------------------------+
bool CSiChannel::CheckTrailingOrderLong(COrderInfo* order,double& price)
  {
//--- Checking the pointer
   if(order==NULL) return(false);
//--- Preparing the data
   double spread   =m_symbol.Ask()-m_symbol.Bid();
   double ma       =MA(1);
   double unit     =PriceLevelUnit();
   double new_price=m_symbol.NormalizePrice(ma-m_limit*unit+spread);
//--- Checking the condition
   if(order.PriceOpen()==new_price) return(false);
   price=new_price;
//--- Condition is fulfilled
   return(true);
  }
//+------------------------------------------------------------------+
//| Check whether the condition of modification                      |
//| of a Sell order is fulfilled.                                    |
//| INPUT:  order - pointer at the object-order,                     |
//|         price - a variable for the new open price.               |
//| OUTPUT: true if the condition is fulfilled, otherwise false.     |
//| REMARK: No.                                                      |
//+------------------------------------------------------------------+
bool CSiChannel::CheckTrailingOrderShort(COrderInfo* order,double& price)
  {
//--- Checking the pointer
   if(order==NULL) return(false);
//--- Preparing the data
   double ma  =MA(1);
   double unit=PriceLevelUnit();
   double new_price=m_symbol.NormalizePrice(ma+m_limit*unit);
//--- Checking the condition
   if(order.PriceOpen()==new_price) return(false);
   price=new_price;
//--- Condition is fulfilled
   return(true);
  }
//+------------------------------------------------------------------+