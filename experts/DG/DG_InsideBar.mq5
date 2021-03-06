//+------------------------------------------------------------------+
//|                                                 DG_InsideBar.mq5 |
//|                               Copyright 2021, DG Financial Corp. |
//|                                           https://www.google.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, DG Financial Corp."
#property link      "https://www.dgfinancial.com"
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

input ulong                MagicNumber = 10003;
input ENUM_ORDER_ALLOWED   OrderAllowed = BUY_AND_SELL;
input ENUM_TIMEFRAMES      TimeFrame = PERIOD_CURRENT;
input int                  TakeProfitPercentOfCandle = 100;
input double               Volume = 100;

input int                  TraillingStopPreviousCandles = 0; 

input ENUM_ORDER_TYPE_TIME OrderLifeTime = ORDER_TIME_DAY;//ORDER_TIME_GTC;

ENUM_ORDER_TYPE_FILLING    OrderTypeFilling = ORDER_FILLING_RETURN;
ulong                      OrderDeviationInPoints = 50;


input int                  HourToOpenOrder = 9;             
input int                  MinuteToOpenOrder = 00; 

MqlRates          Candles[];

MqlDateTime       CurrentTime;   

CTrade            m_Trade;                                         // structure for execution of trades
CPositionInfo     m_Position;                                      // structure for obtaining information of positions

CBarCounter                BarCounter;

int LastCandleTransaction = -1;
int BufferSize = 4; //PreviousCandlesCount + 1;

double Low = 0;
double High = 0;

int OnInit()
{
   ArraySetAsSeries(Candles, true);

   m_Trade.SetDeviationInPoints(OrderDeviationInPoints);
   m_Trade.SetTypeFilling(OrderTypeFilling);
   m_Trade.SetExpertMagicNumber(MagicNumber);

   return(INIT_SUCCEEDED);
}



void OnDeinit(const int reason)
{
   ArrayFree(Candles);
}



void OnTick()
{
   
   ////////////////////////////////////////////////////
   // Copy price information
   //
   if( CopyRates(_Symbol, TimeFrame, 0, BufferSize, Candles) < 0)
   {
      Print("Failed to copy rates");  
      return;
   }  
   
   
   TimeToStruct(TimeCurrent(), CurrentTime);
   if (CurrentTime.hour > 17 && CurrentTime.min > 25)
   {
      CloseAllPositions();
      return;  // current time is not allowed to open order
   }
   
   
   ////////////////////////////////////////////////////
   // Check if this is a new candle
   // If it is not a new candle and we don't use the current candle, abort
   //
   BarCounter.OnTick();
   if (!BarCounter.IsNewBar())
      return;
   //
   ////////////////////////////////////////////////////


   ////////////////////////////////////////////////////
   // Check if there is any open position
   //
   if (PositionsTotal() > 0)
   {
      ////////////////////////////////////////////////////
      // Check if trailing stop is activated
      //
      if (TraillingStopPreviousCandles > 0)
      {
         TraillingStop();
      }
      return;
   }
   //
   ////////////////////////////////////////////////////
   
   
   ////////////////////////////////////////////////////
   // Check time allowed to open position
   //
   TimeToStruct(TimeCurrent(), CurrentTime);
   if (CurrentTime.hour <= HourToOpenOrder && CurrentTime.min < MinuteToOpenOrder)
   {
      return;  // current time is not allowed to open order
   }
   //
   ////////////////////////////////////////////////////
   

   ////////////////////////////////////////////////////
   // Get last tick info
   //
   MqlTick Tick;
   if(!SymbolInfoTick(_Symbol, Tick))
   {
      Print("Failed to copy tick info");
      return;
   }
   //
   ////////////////////////////////////////////////////
   
   
   
   if (IsInsideBar(
               Candles[1].low, 
               Candles[1].high, 
               Candles[2].low, 
               Candles[2].high)
               ) 
   {
      if (OrdersTotal() > 0)
      {
         DeletePendingOrders();
      }
      //else
      {
         
         ////////////////////////////////////////////////////
         // Open order only if none was open in the last candle
         if (LastCandleTransaction + 1 < BarCounter.GetCounter())
         {
            Low = Candles[1].low;
            High = Candles[1].high;
            BuyStop();  
            SellStop();
         }
      }
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
              DeletePendingOrders();
          }
     }       
}



void BuyStop()
{  
   Print("------------------------------------------------ Buy Stop ", BarCounter.GetCounter());
   double ProfitScale  = TakeProfitPercentOfCandle / 100.0;  
   double Price        = MathMax(High, SymbolInfoDouble(_Symbol, SYMBOL_ASK)); 
   double StopLoss     = Low;
   double TakeProfit   = NormalizeDouble((High - Low) * ProfitScale + High, _Digits);  
   datetime Expiration = TimeTradeServer() + PeriodSeconds(PERIOD_D1);   
   string InfoComment  = StringFormat("Buy Stop %s %G lots at %s, SL=%s TP=%s",
                               _Symbol, 
                               Volume,
                               DoubleToString(Price, _Digits),
                               DoubleToString(StopLoss, _Digits),
                               DoubleToString(TakeProfit, _Digits));                          
                                 
   if(!m_Trade.BuyStop(Volume, Price, _Symbol, StopLoss, TakeProfit, OrderLifeTime, Expiration, InfoComment))
   {
      Print("-- Fail    BuyStop: [", m_Trade.ResultRetcode(), "] ", m_Trade.ResultRetcodeDescription());
   }
   else
   {
      Print("-- Success BuyStop: [", m_Trade.ResultRetcode(), "] ", m_Trade.ResultRetcodeDescription());
   }
}



void SellStop()
{  
   Print("------------------------------------------------ Sell Stop ", BarCounter.GetCounter());
   double ProfitScale  = TakeProfitPercentOfCandle / 100.0;  
   double CandleRange  = High - Low;
   double Price        = MathMin(Low, SymbolInfoDouble(_Symbol, SYMBOL_BID)); 
   double StopLoss     = NormalizeDouble(High, _Digits);   
   double TakeProfit   = NormalizeDouble(Low - CandleRange * ProfitScale, _Digits);  
   datetime Expiration = TimeTradeServer() + PeriodSeconds(PERIOD_D1);   
   string InfoComment  = StringFormat("Buy Stop %s %G lots at %s, SL=%s TP=%s",
                               _Symbol, 
                               Volume,
                               DoubleToString(Price, _Digits),
                               DoubleToString(StopLoss, _Digits),
                               DoubleToString(TakeProfit, _Digits));                          
                                 
   if(!m_Trade.SellStop(Volume, Price, _Symbol, StopLoss, TakeProfit, OrderLifeTime, Expiration, InfoComment))
   {
      Print("-- Fail    SellStop: [", m_Trade.ResultRetcode(), "] ", m_Trade.ResultRetcodeDescription());
   }
   else
   {
      Print("-- Success SellStop: [", m_Trade.ResultRetcode(), "] ", m_Trade.ResultRetcodeDescription());
   }
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
            m_Trade.PositionModify(Ticket, Candles[TraillingStopPreviousCandles].low, TakeProfit);
         }
         else if (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL)
         {
            m_Trade.PositionModify(Ticket, Candles[TraillingStopPreviousCandles].high, TakeProfit);
         }
      } 
   }
}



bool IsInsideBar(double low_1, double high_1, double low_2, double high_2)
{
   return (low_1 > low_2) && (high_1 < high_2);
}



void CloseAllPositions()
{
   for (int i=PositionsTotal()-1;i>=0; i--) 
   { 
      if(!m_Trade.PositionClose(PositionGetSymbol(i))) 
      {
         //--- failure message
         //Print(PositionGetSymbol(i), "PositionClose() method failed. Return code=",trade.ResultRetcode(), ". Code description: ",trade.ResultRetcodeDescription());
      }
      else
      {
         //Print(PositionGetSymbol(i), "PositionClose() method executed successfully. Return code=",trade.ResultRetcode(), " (",trade.ResultRetcodeDescription(),")");
      }
   }
} 