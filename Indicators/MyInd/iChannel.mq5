//+------------------------------------------------------------------+
//|                                                      Channel.mq5 |
//|                                                            @nick |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "@TorMT5"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property indicator_chart_window
#property indicator_buffers 5
#property indicator_plots   5
//--- plot indHi
#property indicator_label1  "indHi"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrBlue
#property indicator_style1  STYLE_SOLID
#property indicator_width1  2
//--- plot indMi
#property indicator_label2  "indMi"
#property indicator_type2   DRAW_LINE
#property indicator_color2  clrGreen
#property indicator_style2  STYLE_SOLID
#property indicator_width2  2
//--- plot indLo
#property indicator_label3  "indLo"
#property indicator_type3   DRAW_LINE
#property indicator_color3  clrRed
#property indicator_style3  STYLE_SOLID
#property indicator_width3  2
//--- plot indBuy
#property indicator_label4  "indBuy"
#property indicator_type4   DRAW_ARROW
#property indicator_color4  clrBlueViolet
#property indicator_style4  STYLE_SOLID
#property indicator_width4  2
//--- plot indSell
#property indicator_label5  "indSell"
#property indicator_type5   DRAW_ARROW
#property indicator_color5  clrRed
#property indicator_style5  STYLE_SOLID
#property indicator_width5  2

#include <MyClasses\CChannel.mqh>
#include <MyClasses\CAtrChannel.mqh>

enum ENUM_CHANNEL_TYPE
  {
      CHANNEL_TYPE_HL,                 // High-Low Price Channel
      CHANNEL_TYPE_ATR                 // ATR Channel
  };
//--- input parameters
input int      InpPeriods=25;
input bool     AsSeries=true;
input          ENUM_CHANNEL_TYPE InpChannelType = CHANNEL_TYPE_ATR;  //Channel Type by Default
//--- indicator buffers
double         indHiBuffer[];
double         indMiBuffer[];
double         indLoBuffer[];
double         indBuyBuffer[];
double         indSellBuffer[];

#define        indHi        0
#define        indMi        1
#define        indLo        2
#define        indBuy       3
#define        indSell      4

CChannelBase   *oChannel;

//int      mMAHandle;
//int      mATRHandle;

int OnInit()
  {
  
   if(AsSeries) ArraySetAsSeries(indHiBuffer,true);
   if(AsSeries) ArraySetAsSeries(indMiBuffer,true);
   if(AsSeries) ArraySetAsSeries(indLoBuffer,true);
   if(AsSeries) ArraySetAsSeries(indBuyBuffer,true);
   if(AsSeries) ArraySetAsSeries(indSellBuffer,true);   
  
   SetIndexBuffer(indHi,indHiBuffer,INDICATOR_DATA);
   SetIndexBuffer(indMi,indMiBuffer,INDICATOR_DATA);
   SetIndexBuffer(indLo,indLoBuffer,INDICATOR_DATA);
   SetIndexBuffer(indBuy,indBuyBuffer,INDICATOR_DATA);
   SetIndexBuffer(indSell,indSellBuffer,INDICATOR_DATA);   
   
   PlotIndexSetInteger(3,PLOT_ARROW,221);
   PlotIndexSetInteger(4,PLOT_ARROW,222);
   
   //oChannel                = new CChannel(_Symbol, (ENUM_TIMEFRAMES)_Period, InpPeriods);
   switch(InpChannelType)
     {
      case CHANNEL_TYPE_HL:
        oChannel    = new CChannel(_Symbol, (ENUM_TIMEFRAMES)_Period, InpPeriods );
        break;
      case CHANNEL_TYPE_ATR:
        //mMAHandle = iMA( _Symbol, (ENUM_TIMEFRAMES)_Period,  InpPeriods,  0 ,  MODE_EMA,  MODE_CLOSE);
        //mATRHandle= iATR( _Symbol,(ENUM_TIMEFRAMES)_Period,  InpPeriods);
        //oChannel    = new CATRChannel(_Symbol, (ENUM_TIMEFRAMES)_Period, InpPeriods, mMAHandle, mATRHandle);
        oChannel    = new CATRChannel(_Symbol, (ENUM_TIMEFRAMES)_Period, InpPeriods);
        break; 
      default:
        return(INIT_PARAMETERS_INCORRECT);
        break;
     }
   
   return(INIT_SUCCEEDED);
  }

int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {

   int limit=rates_total-prev_calculated;
   //if(prev_calculated>0) limit++;

   for (int i=limit-1; i>=0; i--)
   {
      indHiBuffer[i]          = oChannel.High(i);
      indLoBuffer[i]          = oChannel.Low(i);
      indMiBuffer[i]          = oChannel.Mid(i);
      indBuyBuffer[i]         = oChannel.Buy(i);
      indSellBuffer[i]        = oChannel.Sell(i);      
      
   }   
   return(rates_total);
  }
  
void OnDeinit(const int reason)
   {
      delete      oChannel;
   }