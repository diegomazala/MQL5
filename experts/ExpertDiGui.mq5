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
//--- available signals
#include <Expert\Signal\SignalDiGui.mqh>
//--- available trailing
#include <Expert\Trailing\TrailingMA.mqh>
//--- available money management
#include <Expert\Money\MoneyFixedLot.mqh>
//+------------------------------------------------------------------+
//| Inputs                                                           |
//+------------------------------------------------------------------+
//--- inputs for expert
input string             Expert_Title         ="ExpertDiGui";// Document name
ulong                    Expert_MagicNumber   =23757;       // 
bool                     Expert_EveryTick     =false;       // 
//--- inputs for main signal
input int                Signal_ThresholdOpen =10;          // Signal threshold value to open [0...100]
input int                Signal_ThresholdClose=10;          // Signal threshold value to close [0...100]
input double             Signal_PriceLevel    =0.0;         // Price level to execute a deal
input double             Signal_StopLevel     =50.0;        // Stop Loss level (in points)
input double             Signal_TakeLevel     =50.0;        // Take Profit level (in points)
input int                Signal_Expiration    =4;           // Expiration of pending orders (in bars)
input int                Signal_DG_FastPeriod =3;           // DiGui(3,MODE_SMA,8,MODE_SMA,...) Period of fast MA
input ENUM_MA_METHOD     Signal_DG_FastMethod =MODE_SMA;    // DiGui(3,MODE_SMA,8,MODE_SMA,...) Method of fast MA
input int                Signal_DG_MeanPeriod =8;           // DiGui(3,MODE_SMA,8,MODE_SMA,...) Period of mean MA
input ENUM_MA_METHOD     Signal_DG_MeanMethod =MODE_SMA;    // DiGui(3,MODE_SMA,8,MODE_SMA,...) Method of mean MA
input int                Signal_DG_SlowPeriod =20;          // DiGui(3,MODE_SMA,8,MODE_SMA,...) Period of slow MA
input ENUM_MA_METHOD     Signal_DG_SlowMethod =MODE_SMA;    // DiGui(3,MODE_SMA,8,MODE_SMA,...) Method of slow MA
input int                Signal_DG_Shift      =0;           // DiGui(3,MODE_SMA,8,MODE_SMA,...) Time shift
input ENUM_APPLIED_PRICE Signal_DG_Applied    =PRICE_CLOSE; // DiGui(3,MODE_SMA,8,MODE_SMA,...) Prices series
input int                Signal_DG_ADXPeriod  =8;           // DiGui(3,MODE_SMA,8,MODE_SMA,...) Period of ADX
input double             Signal_DG_ADXLevel   =32;          // DiGui(3,MODE_SMA,8,MODE_SMA,...) Level of ADX
input double             Signal_DG_Weight     =1.0;         // DiGui(3,MODE_SMA,8,MODE_SMA,...) Weight [0...1.0]
//--- inputs for trailing
input int                Trailing_MA_Period   =8;           // Period of MA
input int                Trailing_MA_Shift    =0;           // Shift of MA
input ENUM_MA_METHOD     Trailing_MA_Method   =MODE_SMA;    // Method of averaging
input ENUM_APPLIED_PRICE Trailing_MA_Applied  =PRICE_CLOSE; // Prices series
//--- inputs for money
input double             Money_FixLot_Percent =100.0;       // Percent
input double             Money_FixLot_Lots    =100.0;       // Fixed volume
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
   filter0.Shift(Signal_DG_Shift);
   filter0.Applied(Signal_DG_Applied);
   filter0.ADXPeriod(Signal_DG_ADXPeriod);
   filter0.ADXLevel(Signal_DG_ADXLevel);
   filter0.Weight(Signal_DG_Weight);
//--- Creation of trailing object
   CTrailingMA *trailing=new CTrailingMA;
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
   trailing.Period(Trailing_MA_Period);
   trailing.Shift(Trailing_MA_Shift);
   trailing.Method(Trailing_MA_Method);
   trailing.Applied(Trailing_MA_Applied);
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