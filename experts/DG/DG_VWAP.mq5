//+------------------------------------------------------------------+
//|                                                  DG_VWAPTest.mq5 |
//|                               Copyright 2020, DG Financial Corp. |
//|                                           https://www.google.com |
//+------------------------------------------------------------------+

// Test cases = G x L
// 14/01/2021 = Avaliar dia atípico
// 22/01/2021 = Semelhanças com o dia 14/01/2021
// 26/01/2021 = 1 x 0
// 27/01/2021 = 1 x 0
// 29/01/2021 = Semelhanças com o dia 14/01/2021
// 01/02/2021 = 0 x 1
// 02/02/2021 = 1 x 1
// 03/02/2021 = 1 x 1
// 04/02/2021 = 2 x 2 

#property copyright "Copyright 2021, DG Financial Corp."
#property link      "https://www.google.com"
#property version   "1.0"

#include "BarCounter.mqh"
#include "TransactionInfo.mqh"
#include <Trade\Trade.mqh>                                         // include the library for execution of trades
#include <Trade\PositionInfo.mqh>                                  // include the library for obtaining information on positions

enum ENUM_ORDER_ALLOWED
{
   BUY_ONLY, 
   SELL_ONLY,
   BUY_AND_SELL              
};


enum PRICE_TYPE 
  {
   OPEN,
   CLOSE,
   HIGH,
   LOW,
   OPEN_CLOSE,
   HIGH_LOW,
   CLOSE_HIGH_LOW,
   OPEN_CLOSE_HIGH_LOW
  };

input ulong                MagicNumber = 20007;
input double               Volume = 100;

input group                "Buy/Sell Filter #1"
input ENUM_ORDER_ALLOWED   OrderAllowed = BUY_AND_SELL;
input ENUM_TIMEFRAMES      TimeFrame = PERIOD_CURRENT;
input int                  TakeProfitPercentOfCandle = 100;
//input int                  PreviousCandlesLowHighCount = 2;
input int                  PreviousCandlesTraillingStop = 0; 
//input int                  WaitCandlesAfterStopLoss = 0;

int                        DojiBodyPercentage = 10;

// input group                "Mean Average #2"
// input bool                 MAFilter = false;
// int                        iMAFastHandle; 
// double                     iMAFast[];                                      
// input int                  MAFastPeriod = 8;  
// int                        iMASlowHandle;                                      
// double                     iMASlow[];                                      
// input int                  MASlowPeriod = 20;  
// input ENUM_MA_METHOD       MA_Method = MODE_SMA;   
// input ENUM_APPLIED_PRICE   MA_AppliedPrice = PRICE_CLOSE;                          


input group                "Time #3"
input int                  MinHourToOpenOrder = 9;             
input int                  MinMinuteToOpenOrder = 15; 

input int                  MaxHourToOpenOrder = 12;             
input int                  MaxMinuteToOpenOrder = 30; 

input group                "Order Settings #4"
ulong                      OrderDeviationInPoints = 50;
input ENUM_ORDER_TYPE_TIME OrderLifeTime = ORDER_TIME_DAY;
ENUM_ORDER_TYPE_FILLING    OrderTypeFilling = ORDER_FILLING_RETURN;

int                        VwapHandle;
double                     VwapData[];

MqlRates                   Candles[];

MqlDateTime                CurrentTime;   

CTrade                     m_Trade;                    // structure for execution of trades
CPositionInfo              m_Position;                 // structure for obtaining information of positions

CBarCounter                BarCounter;

ulong                      LastCandleTransaction = 0;

int                        LastCandleAboveVwap = 0;
int                        LastCandleBelowVwap = 0;



double Normalize(double value)
{
   return NormalizeDouble(value, _Digits);
}

int OnInit()
{
   ////////////////////////////////////////////////////
   // VWAP
   //
   VwapHandle = iCustom(_Symbol, PERIOD_CURRENT, "Dev\\vwap.ex5", "VWAP", CLOSE_HIGH_LOW, false);
   if(VwapHandle == INVALID_HANDLE)
   {
      Print("Failed to get the VWAP indicator handle");                  
      return(INIT_FAILED);                                          
   }
   ArraySetAsSeries(VwapData, true); 
   //
   //////////////////////////////////////////////////

   // ////////////////////////////////////////////////////
   // // Fast MA
   // //
   // iMAFastHandle = iMA(_Symbol, TimeFrame, MAFastPeriod, 0, MA_Method, MA_AppliedPrice);  
   // if(iMAFastHandle == INVALID_HANDLE)                                 
   // {
   //    Print("Failed to get the indicator handle");                  
   //    return(INIT_FAILED);                                          
   // }
   // ArraySetAsSeries(iMAFast,true);        
   // //
   // ////////////////////////////////////////////////////

   // ////////////////////////////////////////////////////
   // // Slow MA
   // //
   // iMASlowHandle = iMA(_Symbol, TimeFrame, MASlowPeriod, 0, MA_Method, MA_AppliedPrice);  
   // if(iMASlowHandle == INVALID_HANDLE)                                 
   // {
   //    Print("Failed to get the indicator handle");                  
   //    return(INIT_FAILED);                                          
   // }
   // ArraySetAsSeries(iMASlow,true);        
   // //
   // ////////////////////////////////////////////////////

   ArraySetAsSeries(Candles, true);

   m_Trade.SetDeviationInPoints(OrderDeviationInPoints);
   m_Trade.SetTypeFilling(OrderTypeFilling);
   m_Trade.SetExpertMagicNumber(MagicNumber);
   
   BarCounter.ResetPerDay(true);

   LastCandleAboveVwap = 0;
   LastCandleBelowVwap = 0;

   return(INIT_SUCCEEDED);
}



void OnDeinit(const int reason)
{
   IndicatorRelease(VwapHandle);
   ArrayFree(VwapData);

   // IndicatorRelease(iMAFastHandle);
   // IndicatorRelease(iMASlowHandle);
   // ArrayFree(iMAFast);
   // ArrayFree(iMASlow);
   ArrayFree(Candles);
}



void OnTick()
{
   int BufferSize = (int)BarCounter.GetCounter() + 10;

   ////////////////////////////////////////////////////
   // Copy price information
   //
   if( CopyRates(_Symbol, TimeFrame, 0, 100, Candles) < 0)
   {
      Print("Failed to copy rates");  
      return;
   }  
   
  
   ////////////////////////////////////////////////////
   // Check if this is a new candle
   // If it is not a new candle and we don't use the current candle, abort
   //
   BarCounter.OnTick();
   if (!BarCounter.IsNewBar() || BarCounter.GetCounter() < 2)
      return;
   
   ////////////////////////////////////////////////////



   ////////////////////////////////////////////////////
   // Check if there is any open position
   //
   if (PositionsTotal() > 0)
   {
      ////////////////////////////////////////////////////
      // Check if trailing stop is activated
      //
      if (PreviousCandlesTraillingStop > 0)
      {
         TraillingStop();
      }
      return;
   }
   //
   ////////////////////////////////////////////////////
   
   ////////////////////////////////////////////////////
   //Copy VWAP data
   //
   if(CopyBuffer(VwapHandle, 0, 0, BufferSize, VwapData) < 0)               
   {
      Print("Failed to copy data from the VWAP indicator buffer or price chart buffer");  
      return; 
   }
   double vwap = Normalize(VwapData[1]);
   //
   //////////////////////////////////////////////////

   // ////////////////////////////////////////////////////
   // // Copy Fast MA data
   // //
   // if(CopyBuffer(iMAFastHandle, 0, 0, BufferSize, iMAFast) < 0)               
   // {
   //    Print("Failed to copy data from the indicator buffer or price chart buffer");  
   //    return; 
   // }
   // //
   // ////////////////////////////////////////////////////

   // ////////////////////////////////////////////////////
   // // Copy Slow MA data
   // //
   // if(CopyBuffer(iMASlowHandle, 0, 0, BufferSize, iMASlow) < 0)               
   // {
   //    Print("Failed to copy data from the indicator buffer or price chart buffer");  
   //    return; 
   // }
   // //
   // ////////////////////////////////////////////////////

   
   ////////////////////////////////////////////////////
   // Check time allowed to open position
   //
   TimeToStruct(TimeCurrent(), CurrentTime);
   bool TimeAllowedToOpenOrder = (CurrentTime.hour >= MinHourToOpenOrder && CurrentTime.min >= MinMinuteToOpenOrder) 
                                 && ((CurrentTime.hour < MaxHourToOpenOrder) || (CurrentTime.hour == MaxHourToOpenOrder && CurrentTime.min <= MaxMinuteToOpenOrder));
   //
   ////////////////////////////////////////////////////


   



   bool Crossing = (Normalize(Candles[1].high) >= vwap) && (Normalize(Candles[1].low) <= vwap);
   if (!Crossing)
   {
      if (Normalize(Candles[1].high) > vwap && Normalize(Candles[1].low) > vwap)
      {
         LastCandleAboveVwap = (int)BarCounter.GetCounter();
      }
      else if (Normalize(Candles[1].high) < vwap && Normalize(Candles[1].low) < vwap)
      {
         LastCandleBelowVwap = (int)BarCounter.GetCounter();
      }
   }
   

   // bool Below           = (Normalize(Candles[2].high) < vwap);
   // bool Above           = (Normalize(Candles[2].low) > vwap);

   // bool CloseAbovePrev  = Normalize(Candles[1].close) > Normalize(Candles[2].close);
   // bool CloseBelowPrev  = Normalize(Candles[1].close) < Normalize(Candles[2].close);

   // bool PrevAbove       = Normalize(Candles[2].close) >= vwap;
   // bool PrevBelow       = Normalize(Candles[2].close) <= vwap;

   // bool HigherThenPrev  = Normalize(Candles[1].high) >= Normalize(Candles[2].high);
   // bool LowerThenPrev   = Normalize(Candles[1].low)  <= Normalize(Candles[2].low);
  
   // bool AboveMASlow     = Normalize(Candles[1].close) > Normalize(iMASlow[1]);
   // bool BelowMASlow     = Normalize(Candles[1].close) < Normalize(iMASlow[1]);

   // bool AboveMAFast     = Normalize(Candles[1].close) > Normalize(iMAFast[1]);
   // bool BelowMAFast     = Normalize(Candles[1].close) < Normalize(iMAFast[1]);

   //bool PrevIsDoji      = IsDoji(Candles[2].open, Candles[2].low, Candles[2].high, Candles[2].close, DojiBodyPercentage);

   bool HighLowerThenPrev  = Normalize(Candles[1].high) <= Normalize(Candles[2].high);
   bool LowHigherThenPrev  = Normalize(Candles[1].low) >= Normalize(Candles[2].low);

   // //////////////////////////////////////////////////////
   // // Check if MA allows operation
   // //
   // bool MASellAllowed = true;
   // bool MABuyAllowed = true;
   // if (MAFilter)
   // {
   //    MASellAllowed = BelowMAFast && BelowMASlow;
   //    MABuyAllowed = AboveMAFast && AboveMASlow;
   // }
   // //
   // //////////////////////////////////////////////////////

   // bool CandlesMinLower  = true;
   // bool CandlesMaxHigher = true;
   // int  BeginCandle = 1; //UseCurrentCandleForLowHigh ? 0 : 1;
   // for (int i = BeginCandle; i < PreviousCandlesLowHighCount + BeginCandle; ++i)
   // {
   //    CandlesMinLower = CandlesMinLower && Candles[i].low <= Candles[i+1].low;
   //    CandlesMaxHigher= CandlesMaxHigher && Candles[i].high >= Candles[i+1].high;
   // }

   Print("----------------------- " , BarCounter.GetCounter(), " Crossing ", Crossing, 
   " vwap ", vwap, " high ", Candles[1].high, " low ", Candles[1].low, 
   " highlower ", HighLowerThenPrev, "  lowhigher ", LowHigherThenPrev,
   " buy: ", (LastCandleAboveVwap > LastCandleBelowVwap),
   " sell: ", (LastCandleBelowVwap > LastCandleAboveVwap));

   if (Crossing && HighLowerThenPrev && (LastCandleAboveVwap > LastCandleBelowVwap)) 
   {
      if (OrdersTotal() > 0)
      {
         ModifyBuyOrder();
      }
      else
      {
         if (TimeAllowedToOpenOrder)
            BuyStop();  
      }

   }
   else if (Crossing && LowHigherThenPrev && (LastCandleBelowVwap > LastCandleAboveVwap))
   {
      if (OrdersTotal() > 0)
      {
         ModifySellOrder();
      }
      else
      {
         if (TimeAllowedToOpenOrder)
            SellStop();
      }
   }
   else
   {
      DeletePendingOrders();
   }

}



void OnTradeTransaction(const MqlTradeTransaction& trans,
                        const MqlTradeRequest& request,
                        const MqlTradeResult& result)
{
      

//     Print("################################################### INFO < ", BarCounter.GetCounter());
//     PrintTransactionInfo(trans, request, result);
//     Print("################################################### INFO >");
      
     if(trans.symbol == _Symbol)
     {
          if (trans.type == TRADE_TRANSACTION_DEAL_ADD) 
          {
              LastCandleTransaction = BarCounter.GetCounter();
              
              switch(trans.deal_type)
              {
                  case DEAL_TYPE_BUY : ModifyBuyStop(trans.order); break;
                  case DEAL_TYPE_SELL : ModifySellStop(trans.order); break;
                  default: break;
              }
          }
     }       
}



void BuyStop()
{  
   Print("------------------------------------------------ Buy Stop ", BarCounter.GetCounter());
   double ProfitScale  = TakeProfitPercentOfCandle / 100.0;  
   double Price        = MathMax(Candles[1].high, SymbolInfoDouble(_Symbol, SYMBOL_ASK)); 
   double StopLoss     = NormalizeDouble(Candles[1].low, _Digits) - _Point * 2;   
   double TakeProfit   = NormalizeDouble(MathAbs(Candles[1].high - Candles[1].low) * ProfitScale + Candles[1].high, _Digits);  
   datetime Expiration = TimeTradeServer() + PeriodSeconds(PERIOD_D1);   
   string InfoComment  = StringFormat("Buy Stop %s %G lots at %s, SL=%s TP=%s",
                               _Symbol, 
                               Volume,
                               DoubleToString(Price, _Digits),
                               DoubleToString(StopLoss, _Digits),
                               DoubleToString(TakeProfit, _Digits));                          
                                 
   //if(!m_Trade.BuyStop(Volume, Price, _Symbol, StopLoss, TakeProfit, OrderLifeTime, Expiration, InfoComment))
   if(!m_Trade.BuyStop(Volume, Price, _Symbol, 0, 0, OrderLifeTime, Expiration, InfoComment))
   {
      Print("-- Fail    BuyStop: [", m_Trade.ResultRetcode(), "] ", m_Trade.ResultRetcodeDescription());
   }
   else
   {
      Print("-- Success BuyStop: [", m_Trade.ResultRetcode(), "] ", m_Trade.ResultRetcodeDescription());
   }
}

void ModifyBuyOrder()
{
   Print("------------------------------------------------ Modify Buy Order ", BarCounter.GetCounter());
   double ProfitScale  = TakeProfitPercentOfCandle / 100.0;  
   double Price        = MathMax(Candles[1].high, SymbolInfoDouble(_Symbol, SYMBOL_ASK)); 
   double StopLoss     = NormalizeDouble(Candles[1].low, _Digits) - _Point * 3;   
   double TakeProfit   = NormalizeDouble(MathAbs(Candles[1].high - Candles[1].low) * ProfitScale + Candles[1].high, _Digits);  
   datetime Expiration = TimeTradeServer() + PeriodSeconds(PERIOD_D1);   
  
   if (OrdersTotal() == 1)
   {
      ulong Ticket = OrderGetTicket(0);
      if(OrderSelect(Ticket) && OrderGetString(ORDER_SYMBOL)==Symbol())
      {     
         if(!m_Trade.OrderModify(Ticket, Price, StopLoss, TakeProfit, OrderLifeTime, Expiration))
         {
            Print("-- Fail    BuyOrderModify: [", m_Trade.ResultRetcode(), "] ", m_Trade.ResultRetcodeDescription());
         }
         else
         {
            Print("-- Success BuyOrderModify: [", m_Trade.ResultRetcode(), "] ", m_Trade.ResultRetcodeDescription());
         }
      }
   }
   else
   {
      Print("******* Nao deveria ter mais de uma ordem pendente: ", OrdersTotal());
   }
}

void ModifyBuyStop(ulong Ticket)
{
   Print("------------------------------------------------ Modify Buy Stop Loss ", BarCounter.GetCounter());
   double ProfitScale  = TakeProfitPercentOfCandle / 100.0;  
   double StopLoss = MathMin(Candles[1].low, Candles[0].low) - _Point * 1;
   double TakeProfit   = NormalizeDouble(MathAbs(Candles[1].high - Candles[1].low) * ProfitScale + Candles[1].high, _Digits);  
   m_Trade.PositionModify(Ticket, StopLoss, TakeProfit);
}



void SellStop()
{  
   Print("------------------------------------------------ Sell Stop ", BarCounter.GetCounter());
   double ProfitScale  = TakeProfitPercentOfCandle / 100.0;  
   double CandleRange  = Candles[1].high - Candles[1].low;
   double Price        = MathMin(Candles[1].low, SymbolInfoDouble(_Symbol, SYMBOL_BID)); 
   double StopLoss     = NormalizeDouble(Candles[1].high, _Digits) + _Point * 1;  
   double TakeProfit   = NormalizeDouble(Candles[1].low - CandleRange * ProfitScale, _Digits);  
   datetime Expiration = TimeTradeServer() + PeriodSeconds(PERIOD_D1);   
   string InfoComment  = StringFormat("Buy Stop %s %G lots at %s, SL=%s TP=%s",
                               _Symbol, 
                               Volume,
                               DoubleToString(Price, _Digits),
                               DoubleToString(StopLoss, _Digits),
                               DoubleToString(TakeProfit, _Digits));                          
                                 
   //if(!m_Trade.SellStop(Volume, Price, _Symbol, StopLoss, TakeProfit, OrderLifeTime, Expiration, InfoComment))
   if(!m_Trade.SellStop(Volume, Price, _Symbol, 0, 0, OrderLifeTime, Expiration, InfoComment))
   {
      Print("-- Fail    SellStop: [", m_Trade.ResultRetcode(), "] ", m_Trade.ResultRetcodeDescription());
   }
   else
   {
      Print("-- Success SellStop: [", m_Trade.ResultRetcode(), "] ", m_Trade.ResultRetcodeDescription());
   }
}



void ModifySellOrder()
{
   Print("------------------------------------------------ Modify Sell Order ", BarCounter.GetCounter());
   double ProfitScale  = TakeProfitPercentOfCandle / 100.0;  
   double CandleRange  = Candles[1].high - Candles[1].low;
   double Price        = MathMin(Candles[1].low, SymbolInfoDouble(_Symbol, SYMBOL_BID)); 
   double StopLoss     = NormalizeDouble(Candles[1].high, _Digits) + _Point * 3;    
   double TakeProfit   = NormalizeDouble(Candles[1].low - CandleRange * ProfitScale, _Digits);  
   datetime Expiration = TimeTradeServer() + PeriodSeconds(PERIOD_D1);   
  
   if (OrdersTotal() == 1)
   {
      ulong Ticket = OrderGetTicket(0);
      if(OrderSelect(Ticket) && OrderGetString(ORDER_SYMBOL)==Symbol())
      {     
         if(!m_Trade.OrderModify(Ticket, Price, StopLoss, TakeProfit, OrderLifeTime, Expiration))
         {
            Print("-- Fail    SellOrderModify: [", m_Trade.ResultRetcode(), "] ", m_Trade.ResultRetcodeDescription());
         }
         else
         {
            Print("-- Success SellOrderModify: [", m_Trade.ResultRetcode(), "] ", m_Trade.ResultRetcodeDescription());
         }
      }
   }
   else
   {
      Print("******* Nao deveria ter mais de uma ordem pendente: ", OrdersTotal());
   }
}



void ModifySellStop(ulong Ticket)
{
   Print("------------------------------------------------ Modify Sell Stop Loss ", BarCounter.GetCounter());
   double ProfitScale  = TakeProfitPercentOfCandle / 100.0;  
   double CandleRange  = Candles[1].high - Candles[1].low;
   double StopLoss = MathMax(Candles[1].high, Candles[0].high) + _Point * 1; 
   double TakeProfit   = NormalizeDouble(Candles[1].low - CandleRange * ProfitScale, _Digits);  
   m_Trade.PositionModify(Ticket, StopLoss, TakeProfit);
}




void DeletePendingOrders()
{
   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
      ulong ticket = OrderGetTicket(i);
      if(OrderSelect(ticket) && OrderGetString(ORDER_SYMBOL) == Symbol())
      {
         m_Trade.OrderDelete(ticket);
      }
   }
}


void TraillingStop()
{
   for (int i = 0; i < PositionsTotal(); i++)
   {
      if (PositionGetSymbol(i) == _Symbol) // && PositionGetInteger(POSITION_MAGIC)
      {
         ulong Ticket = PositionGetInteger(POSITION_TICKET);
         double StopLoss = PositionGetDouble(POSITION_SL);
         double TakeProfit = PositionGetDouble(POSITION_TP);
         
         if (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY)
         {
            m_Trade.PositionModify(Ticket, Candles[PreviousCandlesTraillingStop].low, TakeProfit);
         }
         else if (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL)
         {
            m_Trade.PositionModify(Ticket, Candles[PreviousCandlesTraillingStop].high, TakeProfit);
         }
      } 
   }
}

bool IsStrongBar(double o, double h, double l, double c, int closePercentage)
{
   int percentage = 0;
   if (c > o)  // bull bar
      percentage = (int)((c - l) / (h - l)) * 100;
   else        // bear bar
      percentage = 100 - (int)((c - l) / (h - l)) * 100;
   return percentage >= closePercentage;
}

bool IsDoji(double o, double l, double h, double c, int bodyPercentage)
{
   double body = MathAbs(c - o);
   double range = MathAbs(h - l);
   int percentage = (int)((body / range) * 100);
   return (percentage <= bodyPercentage);
}
