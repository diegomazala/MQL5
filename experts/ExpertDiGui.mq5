//+------------------------------------------------------------------+
//|                                                  ExpertDiGui.mq5 |
//|                        Copyright 2019, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2019, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
//+------------------------------------------------------------------+
//| Include                                                          |
//+------------------------------------------------------------------+
#include <Expert\Expert.mqh>
#include <Expert\Signal\SignalDiGui.mqh>
#include <Expert\Trailing\TrailingNone.mqh>
#include <Expert\Money\MoneyFixedLot.mqh>
//+------------------------------------------------------------------+
//| Inputs                                                           |
//+------------------------------------------------------------------+
//--- inputs for expert
input string         Expert_Title         ="DiGui";  // Document name
ulong                Expert_MagicNumber   =12693;    // 
bool                 Expert_EveryTick     =false;    // 
//--- inputs for main signal
input int            Signal_ThresholdOpen =10;       // Signal threshold value to open [0...100]
input int            Signal_ThresholdClose=10;       // Signal threshold value to close [0...100]
input double         Signal_PriceLevel    =0.0;      // Price level to execute a deal
input double         Signal_StopLevel     =50.0;     // Stop Loss level (in points)
input double         Signal_TakeLevel     =50.0;     // Take Profit level (in points)
input int            Signal_Expiration    =4;        // Expiration of pending orders (in bars)
input int            Signal_DG_FastPeriod =3;        // DiGui(3,MODE_SMA,8,MODE_SMA,...) Period of fast MA
input ENUM_MA_METHOD Signal_DG_FastMethod =MODE_SMA; // DiGui(3,MODE_SMA,8,MODE_SMA,...) Method of fast MA
input int            Signal_DG_MeanPeriod =8;        // DiGui(3,MODE_SMA,8,MODE_SMA,...) Period of mean MA
input ENUM_MA_METHOD Signal_DG_MeanMethod =MODE_SMA; // DiGui(3,MODE_SMA,8,MODE_SMA,...) Method of mean MA
input int            Signal_DG_SlowPeriod =20;       // DiGui(3,MODE_SMA,8,MODE_SMA,...) Period of slow MA
input ENUM_MA_METHOD Signal_DG_SlowMethod =MODE_SMA; // DiGui(3,MODE_SMA,8,MODE_SMA,...) Method of slow MA
input int            Signal_DG_Shift      =0;        // 
input ENUM_APPLIED_PRICE Signal_DG_Applied=PRICE_CLOSE;// 
input int            Signal_DG_ADXPeriod  =8;        // DiGui(8) Period of ADX
//--- inputs for money
input double         Money_FixLot_Percent =100;     // Percent
input double         Money_FixLot_Lots    =100;     // Fixed volume
//+------------------------------------------------------------------+
//| Global expert object                                             |
//+------------------------------------------------------------------+
CExpert ExtExpert;
//+------------------------------------------------------------------+
//| Initialization function of the expert                            |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- Initializing expert
   if(!ExtExpert.Init(Symbol(),Period(),Expert_EveryTick,Expert_MagicNumber))
     {
      //--- failed
      printf(__FUNCTION__+": error initializing expert");
      ExtExpert.Deinit();
      return(INIT_FAILED);
     }
//--- Creating signal
   CExpertSignal *signal=new CExpertSignal;
   if(signal==NULL)
     {
      //--- failed
      printf(__FUNCTION__+": error creating signal");
      ExtExpert.Deinit();
      return(INIT_FAILED);
     }
//---
   ExtExpert.InitSignal(signal);
   signal.ThresholdOpen(Signal_ThresholdOpen);
   signal.ThresholdClose(Signal_ThresholdClose);
   signal.PriceLevel(Signal_PriceLevel);
   signal.StopLevel(Signal_StopLevel);
   signal.TakeLevel(Signal_TakeLevel);
   signal.Expiration(Signal_Expiration);
//--- Creating filter CSignalDiGui
   CSignalDiGui *filter0=new CSignalDiGui;
   if(filter0==NULL)
     {
      //--- failed
      printf(__FUNCTION__+": error creating filter0");
      ExtExpert.Deinit();
      return(INIT_FAILED);
     }
   signal.AddFilter(filter0);
//--- Set filter parameters
   filter0.FastPeriod(Signal_DG_FastPeriod);
   filter0.FastMethod(Signal_DG_FastMethod);
   filter0.MeanPeriod(Signal_DG_MeanPeriod);
   filter0.MeanMethod(Signal_DG_MeanMethod);
   filter0.SlowPeriod(Signal_DG_SlowPeriod);
   filter0.SlowMethod(Signal_DG_SlowMethod);
   filter0.ADXPeriod(Signal_DG_ADXPeriod);
//--- Creation of trailing object
   CTrailingNone *trailing=new CTrailingNone;
   if(trailing==NULL)
     {
      //--- failed
      printf(__FUNCTION__+": error creating trailing");
      ExtExpert.Deinit();
      return(INIT_FAILED);
     }
//--- Add trailing to expert (will be deleted automatically))
   if(!ExtExpert.InitTrailing(trailing))
     {
      //--- failed
      printf(__FUNCTION__+": error initializing trailing");
      ExtExpert.Deinit();
      return(INIT_FAILED);
     }
//--- Set trailing parameters
//--- Creation of money object
   CMoneyFixedLot *money=new CMoneyFixedLot;
   if(money==NULL)
     {
      //--- failed
      printf(__FUNCTION__+": error creating money");
      ExtExpert.Deinit();
      return(INIT_FAILED);
     }
//--- Add money to expert (will be deleted automatically))
   if(!ExtExpert.InitMoney(money))
     {
      //--- failed
      printf(__FUNCTION__+": error initializing money");
      ExtExpert.Deinit();
      return(INIT_FAILED);
     }
     
//--- Set money parameters
   money.Percent(Money_FixLot_Percent);
   money.Lots(Money_FixLot_Lots);
//--- Check all trading objects parameters
   if(!ExtExpert.ValidationSettings())
     {
      //--- failed
      ExtExpert.Deinit();
      return(INIT_FAILED);
     }
//--- Tuning of all necessary indicators
   if(!ExtExpert.InitIndicators())
     {
      //--- failed
      printf(__FUNCTION__+": error initializing indicators");
      ExtExpert.Deinit();
      return(INIT_FAILED);
     }
//--- ok
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Deinitialization function of the expert                          |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   ExtExpert.Deinit();
  }
//+------------------------------------------------------------------+
//| "Tick" event handler function                                    |
//+------------------------------------------------------------------+
void OnTick()
  {
   ExtExpert.OnTick();
  }
//+------------------------------------------------------------------+
//| "Trade" event handler function                                   |
//+------------------------------------------------------------------+
void OnTrade()
  {
   ExtExpert.OnTrade();
  }
//+------------------------------------------------------------------+
//| "Timer" event handler function                                   |
//+------------------------------------------------------------------+
void OnTimer()
  {
   ExtExpert.OnTimer();
  }
//+------------------------------------------------------------------+
