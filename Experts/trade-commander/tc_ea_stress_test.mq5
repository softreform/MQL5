//+------------------------------------------------------------------+
//|                                            tc_ea_stress_test.mq5 |
//|                              Copyright 2016, trade-commander.com |
//|                                   http://www.trade-commander.com |
//+------------------------------------------------------------------+


#property copyright "Copyright 2016, trade-commander.com"
#property link      "http://www.trade-commander.com"
#property version   "1.00"
#property strict

//#include <stdlib.mqh> 
#include <trade-commander/errordescription.mqh>
#include <Trade\SymbolInfo.mqh>
#include <trade-commander/tc_bridge_utils.mqh>
#include <trade-commander/gui_objects.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\Trade.mqh>


//+------------------------------------------------------------------+
//| Expert inputs                                   |
//+------------------------------------------------------------------+

input double           i_lots                					=0.5;          // order size
input int              i_millseconds_placement                	=300;          // placement timer in milliseconds. default: each tick
input int				i_runs									=50;							// number of runs
input color			i_clr_counter							=clrWhite;		// color of counter
input int				i_size_counter							=60;			// fontsize counter

//+------------------------------------------------------------------+
//| Expert globals                                   |
//+------------------------------------------------------------------+

int ticketopen=0;
bool buy=false;
double lots=1.0;
int runs=0;
string	lbl_counter="lbl_counter"; // name of counter label
CSymbolInfo si;
CPositionInfo pi;
tc_label*	_label=NULL;

void update_label(void)
{
	string xtext=StringFormat("%d",runs);
	_label.text(xtext,true);
}



void  print_error(string file,string function,string comment="",int error=0)
{
   if(error==0)
      error=GetLastError();
	string serror=ErrorDescription(error);
	if(serror=="Unknown error")
		serror=TradeServerReturnCodeDescription(error);
    PrintFormat("ERROR %s:%s %s desc=%s code=%d",file,function,comment,serror,error); 	
}
#define PRINT_ERROR(comment,error)  print_error(__FILE__,__FUNCTION__,comment,error)


bool	order_place(bool xbuy)
{
	MqlTradeRequest  trq;      // query structure 
	MqlTradeResult   trs;        // structure of the answer 

	ZeroMemory(trq);
	ZeroMemory(trs);

	trq.symbol=Symbol();	
	trq.action=TRADE_ACTION_DEAL;
	trq.volume=lots;
	trq.deviation=20;
	trq.type_filling=ORDER_FILLING_FOK;

	if(xbuy == true)
	{
		trq.price=si.Ask();
		trq.type=ORDER_TYPE_BUY;

	}
	else
	{
		trq.price=si.Bid();
		trq.type=ORDER_TYPE_SELL;

	}
	if(OrderSend( trq,trs) == false)
	{
	   PRINT_ERROR("",trs.retcode);
	   return false;
	}
	
	return true;	
}
bool order_open(void)
{
	bool bres=false;
	buy=!buy;
	
	//order_place(buy);
	CTrade trx;
	ResetLastError();
	if(buy == true)
		bres=trx.Buy( i_lots,Symbol(),0.0,0.0,0.0,"");
	else
		bres=trx.Sell( i_lots,Symbol(),0.0,0.0,0.0,"");
	if(bres == false)
	{
		PrintFormat("#error::%s code=%d",__FUNCTION__,GetLastError());
	}
	return bres;
}
bool order_close(void)
{
	bool bres=true;
	
	if(pi.Select( Symbol()) == true)
	{
		CTrade trx;
		bres=trx.PositionClose( Symbol(),ULONG_MAX);
   
		if(bres == true)
			runs -= 1;
	}
	return bres;
}

bool auto_place(void)
{
	if(pi.Select( Symbol()) == false)
		order_open();
	else
	{	
		order_close();
		update_label();
		if(runs == 0)
		{
			int y=1;
			int x=1/(y-1);
		}
		
	}
	return true;
}
int OnInit()
  {
		lots=MathAbs(i_lots);
		runs=i_runs;
		si.Name(Symbol());
		si.Select();


		_label=new tc_label(lbl_counter,10,40,i_clr_counter,"Verdana",20);

		update_label();
		if(i_millseconds_placement > 0)
		{
			bool  bres=EventSetMillisecondTimer( 700);
		}
		return(INIT_SUCCEEDED);
   
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
	// we should be flat again
	order_close();
	TC_DEL(_label);
 
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
	if(i_millseconds_placement <= 0)
		auto_place();
   
  }
//+------------------------------------------------------------------+
void OnTimer()
{
	auto_place();
}