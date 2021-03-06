//+------------------------------------------------------------------+
//|                                                     ExpertDG.mq5 |
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
#include <..\experts\DG\SignalDG.mqh>
#include <..\experts\DG\TrailingDG.mqh>
#include <Expert\Money\MoneyFixedLot.mqh>
//+------------------------------------------------------------------+
//| Inputs                                                           |
//+------------------------------------------------------------------+
//--- inputs for expert
input string             Expert_Title         ="ExpertDG";  // Document name
ulong                    Expert_MagicNumber   =23757;       // 
bool                     Expert_EveryTick     =false;       // 
//--- inputs for main signal
input int                Signal_ThresholdOpen =10;          // Signal threshold value to open [0...100]
input int                Signal_ThresholdClose=10;          // Signal threshold value to close [0...100]
input double             Signal_PriceLevel    =0.0;         // Price level to execute a deal
input double             Signal_StopLevel     =1000.0;      // Stop Loss level (in points)
input double             Signal_TakeLevel     =1000.0;      // Take Profit level (in points)
input int                Signal_Expiration    =1;           // Expiration of pending orders (in bars)
input int                Signal_DG_FastPeriod =3;           // MA Fast Period
input ENUM_MA_METHOD     Signal_DG_FastMethod =MODE_SMA;    // MA Fast Method
input int                Signal_DG_MeanPeriod =8;           // MA Mean Period
input ENUM_MA_METHOD     Signal_DG_MeanMethod =MODE_SMA;    // MA Mean Method
input int                Signal_DG_SlowPeriod =20;          // MA Slow Period
input ENUM_MA_METHOD     Signal_DG_SlowMethod =MODE_SMA;    // MA Slow Method
input int                Signal_DG_Shift      =0;           // Time shift
input ENUM_APPLIED_PRICE Signal_DG_Applied    =PRICE_CLOSE; // Prices series
input bool               Signal_DG_ADXEnabled =false;       // ADX Enable/Disable
input int                Signal_DG_ADXPeriod  =8;           // ADX Period
input double             Signal_DG_ADXLevel   =32;          // ADX Level
input double             Signal_DG_EpsisilonDD=0.001;       // DD Epsilon
input double             Signal_DG_OffsetDD   =0.01;        // DD Offset
input double             Signal_DG_Weight     =1.0;         // Weight [0...1.0]
//--- inputs for money
input double             Money_FixLot_Percent =100.0;       // Percent
input double             Money_FixLot_Lots    =100.0;       // Fixed volume

input int                Signal_DG_HourStart  =10;          // Hour Start
input int                Signal_DG_HourEnd    =17;          // Hour End

//+------------------------------------------------------------------+
//| Global expert object                                             |
//+------------------------------------------------------------------+
CExpert ExtExpert;
CSignalDG* ExpertFilter;
CTrailingDG* ExpertTrailing;
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
//--- Creating filter CSignalDG
   ExpertFilter=new CSignalDG;
   if(ExpertFilter==NULL)
     {
      //--- failed
      printf(__FUNCTION__+": error creating ExpertFilter");
      ExtExpert.Deinit();
      return(INIT_FAILED);
     }
   signal.AddFilter(ExpertFilter);
//--- Set filter parameters
   ExpertFilter.FastPeriod(Signal_DG_FastPeriod);
   ExpertFilter.FastMethod(Signal_DG_FastMethod);
   ExpertFilter.MeanPeriod(Signal_DG_MeanPeriod);
   ExpertFilter.MeanMethod(Signal_DG_MeanMethod);
   ExpertFilter.SlowPeriod(Signal_DG_SlowPeriod);
   ExpertFilter.SlowMethod(Signal_DG_SlowMethod);
   ExpertFilter.Shift(Signal_DG_Shift);
   ExpertFilter.Applied(Signal_DG_Applied);
   ExpertFilter.ADXEnable(Signal_DG_ADXEnabled);
   ExpertFilter.ADXPeriod(Signal_DG_ADXPeriod);
   ExpertFilter.ADXLevel(Signal_DG_ADXLevel);
   ExpertFilter.EpsilonDD(Signal_DG_EpsisilonDD);
   ExpertFilter.OffsetDD(Signal_DG_OffsetDD);
   ExpertFilter.Weight(Signal_DG_Weight);
   ExpertFilter.HourStart(Signal_DG_HourStart);
   ExpertFilter.HourStart(Signal_DG_HourEnd);
//--- Creation of trailing object
   

   ExpertTrailing = new  CTrailingDG();
   if(ExpertTrailing==NULL)
   {
      //--- failed
      printf(__FUNCTION__+": error creating trailing");
      ExtExpert.Deinit();
      return(INIT_FAILED);
   }
//--- Add trailing to expert (will be deleted automatically))
   if(!ExtExpert.InitTrailing(ExpertTrailing))
   {
      //--- failed
      printf(__FUNCTION__+": error initializing trailing");
      ExtExpert.Deinit();
      return(INIT_FAILED);
   }
   ExpertTrailing.FastPeriod(Signal_DG_FastPeriod);
   ExpertTrailing.FastMethod(Signal_DG_FastMethod);
   ExpertTrailing.MeanPeriod(Signal_DG_MeanPeriod);
   ExpertTrailing.MeanMethod(Signal_DG_MeanMethod);
   ExpertTrailing.SlowPeriod(Signal_DG_SlowPeriod);
   ExpertTrailing.SlowMethod(Signal_DG_SlowMethod);
   ExpertTrailing.Shift(Signal_DG_Shift);
   ExpertTrailing.Applied(Signal_DG_Applied);
   ExpertTrailing.ADXPeriod(Signal_DG_ADXPeriod);
   ExpertTrailing.ADXLevel(Signal_DG_ADXLevel);
 
   
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
   
   MqlDateTime dt;
   datetime dtSer=TimeCurrent(dt);
   Comment(PositionsTotal(), " - ", dt.hour, ":", dt.min, ":", dt.sec);
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

/*
void TrailingStop(double preco)
   {
      for(int i = PositionsTotal()-1; i>=0; i--)
         {
            string symbol = PositionGetSymbol(i);
            ulong magic = PositionGetInteger(POSITION_MAGIC);
            if(symbol == _Symbol && magic==magicNum)
               {
                  ulong PositionTicket = PositionGetInteger(POSITION_TICKET);
                  double StopLossCorrente = PositionGetDouble(POSITION_SL);
                  double TakeProfitCorrente = PositionGetDouble(POSITION_TP);
                  if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY)
                     {
                        if(preco >= (StopLossCorrente + gatilhoTS) )
                           {
                              double novoSL = NormalizeDouble(StopLossCorrente + stepTS, _Digits);
                              if(trade.PositionModify(PositionTicket, novoSL, TakeProfitCorrente))
                                 {
                                    Print("TrailingStop - sem falha. ResultRetcode: ", trade.ResultRetcode(), ", RetcodeDescription: ", trade.ResultRetcodeDescription());
                                 }
                              else
                                 {
                                    Print("TrailingStop - com falha. ResultRetcode: ", trade.ResultRetcode(), ", RetcodeDescription: ", trade.ResultRetcodeDescription());
                                 }
                           }
                     }
                  else if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL)
                     {
                        if(preco <= (StopLossCorrente - gatilhoTS) )
                           {
                              double novoSL = NormalizeDouble(StopLossCorrente - stepTS, _Digits);
                              if(trade.PositionModify(PositionTicket, novoSL, TakeProfitCorrente))
                                 {
                                    Print("TrailingStop - sem falha. ResultRetcode: ", trade.ResultRetcode(), ", RetcodeDescription: ", trade.ResultRetcodeDescription());
                                 }
                              else
                                 {
                                    Print("TrailingStop - com falha. ResultRetcode: ", trade.ResultRetcode(), ", RetcodeDescription: ", trade.ResultRetcodeDescription());
                                 }
                           }
                     }
               }
         }
   }
   */
   /*
void BreakEven(double preco)
   {

   // GLOBAL VARIABLES
   ulong                   magicNum = 123456;//Magic Number
   double                  lote = 5.0;//Volume
   double                  stopLoss = 5;//Stop Loss
   double                  takeProfit = 5;//Take Profit
   double                  gatilhoBE = 2;//Gatilho BreakEven
   bool                          posAberta;
   bool                          ordPendente;
   bool                          beAtivo;
   
   
      for(int i = PositionsTotal()-1; i>=0; i--)
         {
            string symbol = PositionGetSymbol(i);
            ulong magic = PositionGetInteger(POSITION_MAGIC);
            if(symbol == _Symbol && magic == magicNum)
               {
                  ulong PositionTicket = PositionGetInteger(POSITION_TICKET);
                  double PrecoEntrada = PositionGetDouble(POSITION_PRICE_OPEN);
                  double TakeProfitCorrente = PositionGetDouble(POSITION_TP);
                  if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY)
                     {
                        if( preco >= (PrecoEntrada + gatilhoBE) )
                           {
                              if(trade.PositionModify(PositionTicket, PrecoEntrada, TakeProfitCorrente))
                                 {
                                    Print("BreakEven - sem falha. ResultRetcode: ", trade.ResultRetcode(), ", RetcodeDescription: ", trade.ResultRetcodeDescription());
                                    beAtivo = true;
                                 }
                              else
                                 {
                                    Print("BreakEven - com falha. ResultRetcode: ", trade.ResultRetcode(), ", RetcodeDescription: ", trade.ResultRetcodeDescription());
                                 }
                           }                           
                     }
                  else if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL)
                     {
                        if( preco <= (PrecoEntrada - gatilhoBE) )
                           {
                              if(trade.PositionModify(PositionTicket, PrecoEntrada, TakeProfitCorrente))
                                 {
                                    Print("BreakEven - sem falha. ResultRetcode: ", trade.ResultRetcode(), ", RetcodeDescription: ", trade.ResultRetcodeDescription());
                                    beAtivo = true;
                                 }
                              else
                                 {
                                    Print("BreakEven - com falha. ResultRetcode: ", trade.ResultRetcode(), ", RetcodeDescription: ", trade.ResultRetcodeDescription());
                                 }
                           }
                     }
               }
         }
    
   }
        */