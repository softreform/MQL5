//+------------------------------------------------------------------+
//|                                                      Memsize.mqh |
//|                                  Copyright 2018, Serhii Shevchuk |
//|                           https://www.mql5.com/en/users/decanium |
//+------------------------------------------------------------------+
#property copyright "Copyright 2018, Serhii Shevchuk"
#property link      "https://www.mql5.com/en/users/decanium"
#property version   "1.00"
//+------------------------------------------------------------------+
//| Consider amount of memory                                        |
//+------------------------------------------------------------------+
class CMemsize
  {
private:
   long              m_size;
   long              m_max_size;
public:
                     CMemsize();
                    ~CMemsize();
   void              Set(long sz){m_size=sz;}
   void              operator=(long sz){m_size=sz;}
   bool              operator+=(long sz);
   long              Max(void){return m_max_size;}
   void              Max(long m){if(m>0) m_max_size=m;}
   long              Value(void){return m_size;}
   long              Comp(long sz){return(m_max_size-(m_size+sz));}
   string            ToStr(void);
  };
//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CMemsize::CMemsize() : m_size(0),
                       m_max_size(0)
  {
  }
//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CMemsize::~CMemsize()
  {
  }
//+------------------------------------------------------------------+
//| Add memory volume                                                |
//+------------------------------------------------------------------+
bool CMemsize::operator+=(long sz)
  {
   if(m_max_size>0 && (m_size+sz)>m_max_size)
      return false;
   m_size+=sz;
   return true;
  }
//+------------------------------------------------------------------+
//| Display the value as a line                                      |
//+------------------------------------------------------------------+
string CMemsize::ToStr(void)
  {
   if(m_size<1024)
      return IntegerToString(m_size)+" byte";
   else if(m_size<1048576)
      return DoubleToString(double(m_size)/1024,1)+" Kbyte";
   else if(m_size<1073741824)
      return DoubleToString(double(m_size)/1048576,1)+" Mbyte";
   else
      return DoubleToString(double(m_size)/1073741824,1)+" Gbyte";
  }
//+------------------------------------------------------------------+
