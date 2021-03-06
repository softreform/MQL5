//+------------------------------------------------------------------+
//|                                                     Duration.mqh |
//|                                  Copyright 2018, Serhii Shevchuk |
//|                           https://www.mql5.com/en/users/decanium |
//+------------------------------------------------------------------+
#property copyright "Copyright 2018, Serhii Shevchuk"
#property link      "https://www.mql5.com/en/users/decanium"
#property version   "1.00"
//+------------------------------------------------------------------+
//| Measure duration between the program reference points            |
//+------------------------------------------------------------------+
class CDuration
  {
private:
   ulong             m_t_start;  // start counting
   ulong             m_t_end;    // stop counting
public:
                     CDuration();
                    ~CDuration();
   void              Reset(void){m_t_start=m_t_end=0;}
   void              Start(void){m_t_start=GetMicrosecondCount();}
   void              Stop(void){m_t_end=GetMicrosecondCount();}
   ulong             Value(void);
   string            ToStr(void);

  };
//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CDuration::CDuration() : m_t_start(0),
                         m_t_end(0)
  {
  }
//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CDuration::~CDuration()
  {
  }
//+------------------------------------------------------------------+
//| Get the value in microseconds                                    |
//+------------------------------------------------------------------+
ulong CDuration::Value(void)
  {
   if(m_t_end>m_t_start)
      return(m_t_end-m_t_start);
   else
      return(0);
  }
//+------------------------------------------------------------------+
//| Display value as a line                                          |
//+------------------------------------------------------------------+
string CDuration::ToStr(void)
  {
   ulong d=Value();
   if(!d)
      return "0s";
   else if(d<1000)
      return IntegerToString(d)+"us";
   else if(d<1000000)
      return DoubleToString(double(d)/1000,1)+"ms";
   else
     {
      ulong mm=d/60000000;
      if(mm)
         return IntegerToString(mm)+"m "+IntegerToString((d%60000000)/1000000)+"s";
      else
         return DoubleToString(double(d)/1000000,1)+"s";
     }
  }
//+------------------------------------------------------------------+
