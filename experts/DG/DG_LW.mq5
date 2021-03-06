//+------------------------------------------------------------------+
//|                                                        DG_LW.mq5 |
//|                               Copyright 2020, DG Financial Corp. |
//|                                           https://www.google.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, DG Financial Corp."
#property link      "https://www.google.com"
#property version   "1.00"

#include "BarCounter.mqh"
#include <Trade\Trade.mqh>                                         // include the library for execution of trades
#include <Trade\PositionInfo.mqh>                                  // include the library for obtaining information on positions

enum ENUM_ORDER_ALLOWED
{
   BUY_ONLY, 
   SELL_ONLY,
   BUY_AND_SELL              
};

input ulong                ExpertMagicNumber = 22345;

input ENUM_ORDER_ALLOWED   OrderAllowed = BUY_AND_SELL;

input ENUM_TIMEFRAMES      TimeFrame = PERIOD_CURRENT;

input double               Volume = 100;

input int                  HourToOpenOrder = 10;             
input int                  MinuteToOpenOrder = 00; 

input ENUM_MA_METHOD       MA_Method = MODE_SMA;
input ENUM_APPLIED_PRICE   MA_AppliedPrice = PRICE_CLOSE; 
input int                  iMA_High_Period = 3;  
input int                  iMA_Low_Period = 3;
input int                  iMA_Trend_Period = 21;
int                        iMA_High_Handle;                                 
double                     iMA_High[]; 
int                        iMA_Low_Handle;                                 
double                     iMA_Low[];
int                        iMA_Trend_Handle;                                 
double                     iMA_Trend[];


MqlRates                   Candles[];

ENUM_ORDER_TYPE_FILLING    OrderTypeFilling = ORDER_FILLING_RETURN;
ulong                      OrderDeviationInPoints = 50;

MqlDateTime                CurrentTime;   

CTrade                     m_Trade;                                         // structure for execution of trades
CPositionInfo              m_Position;                                      // structure for obtaining information of positions

CBarCounter                BarCounter;

int BufferSize = 4; //PreviousCandlesCount + 1;

int OnInit()
{
   iMA_High_Handle = iMA(_Symbol, TimeFrame, iMA_High_Period, 0, MODE_SMA, PRICE_HIGH);  
   if(iMA_High_Handle == INVALID_HANDLE)                                 
   {
      Print("Failed to get the indicator handle");                  
      return(-1);                                                   
   }

   iMA_Low_Handle = iMA(_Symbol, TimeFrame, iMA_Low_Period, 0, MODE_SMA, PRICE_LOW);  
   if(iMA_Low_Handle == INVALID_HANDLE)                                 
   {
      Print("Failed to get the indicator handle");                  
      return(-1);                                                   
   }

   iMA_Trend_Handle = iMA(_Symbol, TimeFrame, iMA_Trend_Period, 0, MODE_SMA, PRICE_CLOSE);  
   if(iMA_Trend_Handle == INVALID_HANDLE)                                 
   {
      Print("Failed to get the indicator handle");                  
      return(-1);                                                   
   }
   
   ArraySetAsSeries(iMA_High, true);
   ArraySetAsSeries(iMA_Low, true);
   ArraySetAsSeries(iMA_Trend, true);
 
    
   m_Trade.SetDeviationInPoints(OrderDeviationInPoints);
   m_Trade.SetTypeFilling(OrderTypeFilling);
   m_Trade.SetExpertMagicNumber(ExpertMagicNumber);                               

   return(INIT_SUCCEEDED);
}



void OnDeinit(const int reason)
{
   IndicatorRelease(iMA_High_Handle); 
   IndicatorRelease(iMA_Low_Handle);
   IndicatorRelease(iMA_Trend_Handle);                                  
   ArrayFree(iMA_High);                                            
   ArrayFree(iMA_Low);
   ArrayFree(iMA_Trend);       
   ArrayFree(Candles);                                
}



void OnTick()
{
   Comment(PositionsTotal(), "  ", OrdersTotal());
   ////////////////////////////////////////////////////
   // Copy price information
   //
   if( CopyRates(_Symbol, TimeFrame, 0, BufferSize, Candles) < 0)
   {
      Print("Failed to copy rates");  
      return;
   }  

   ////////////////////////////////////////////////////
   // If it is not a new candle, abort
   //
   BarCounter.OnTick();
   if (!BarCounter.IsNewBar())
      return;
      
      

   ////////////////////////////////////////////////////
   // Check if there is any open position
   //
   if (PositionsTotal() > 0)
   {
      ////////////////////////////////////////////////////
      // Update trailing stop 
      //
      TraillingStop();
      return;
   }


   ////////////////////////////////////////////////////
   // Check time allowed to open position
   //
   TimeToStruct(TimeCurrent(), CurrentTime);
   if (CurrentTime.hour <= HourToOpenOrder && CurrentTime.min < MinuteToOpenOrder)
   {
      return;  // current time is not allowed to open order
   }


   ////////////////////////////////////////////////////
   // Copy MM data
   //
   int err1 = CopyBuffer(iMA_High_Handle, 0, 0, 3, iMA_High); 
   int err2 = CopyBuffer(iMA_Low_Handle, 0, 0, 3, iMA_Low);
   int err3 = CopyBuffer(iMA_Trend_Handle, 0, 0, 3, iMA_Trend);                
   if(err1 < 0 || err2 < 0 || err3 < 0)                
   {
      Print("Failed to copy data from the indicator buffer or price chart buffer");  // then print the relevant error message into the log file
      return;                                                                        // and exit the function
   }
   
   MqlTick Tick;
   if(!SymbolInfoTick(_Symbol, Tick))
   {
      Print("Failed to copy tick info");
      return;
   }

   bool LastPriceAboveMA     = Candles[1].close > iMA_Trend[1];
   bool LastPriceBelowMA     = Candles[1].close < iMA_Trend[1];

   bool PriceAboveMA     = Tick.last > iMA_Trend[0];
   bool PriceBelowMA     = Tick.last < iMA_Trend[0];
 
   if (LastPriceAboveMA != PriceAboveMA || LastPriceBelowMA != PriceBelowMA)
   {
      DeletePendingOrders();
   }
   else if (PriceAboveMA && OrderAllowed != SELL_ONLY)
   {
      if (OrdersTotal() > 0)
         ModifyBuyOrder();
      else
         BuyLimit();  
   }
   else if (PriceBelowMA && OrderAllowed != BUY_ONLY)
   {
      if (OrdersTotal() > 0)
         ModifySellOrder();
      else
         SellLimit();
   }

}



void OnTradeTransaction(const MqlTradeTransaction& trans,
                        const MqlTradeRequest& request,
                        const MqlTradeResult& result)
{
     
     if(trans.symbol == _Symbol)
     {
          ENUM_DEAL_ENTRY deal_entry=(ENUM_DEAL_ENTRY) HistoryDealGetInteger(trans.deal,DEAL_ENTRY);
          ENUM_DEAL_REASON deal_reason=(ENUM_DEAL_REASON) HistoryDealGetInteger(trans.deal,DEAL_REASON);
          //PrintFormat("------- deal entry type=%s trans type=%s trans deal type=%s order-ticket=%d deal-ticket=%d deal-reason=%s",EnumToString(deal_entry),EnumToString(trans.type),EnumToString(trans.deal_type),trans.order,trans.deal,EnumToString(deal_reason));               
           
          if (trans.type == TRADE_TRANSACTION_DEAL_ADD)
          {
             Print("-- ", EnumToString(deal_entry), " ", EnumToString(trans.type), " ", 
             EnumToString(trans.deal_type), " ", trans.order, " ", trans.deal, " ", EnumToString(deal_reason), 
             "  ", DoubleToString(result.price, _Digits),
             "  ", DoubleToString(result.ask, _Digits),
             "  ", DoubleToString(result.bid, _Digits),
             "  ", DoubleToString(request.price, _Digits),
             "  ", DoubleToString(request.sl, _Digits),
             "  ", DoubleToString(request.tp, _Digits),
             "  ", DoubleToString(request.stoplimit, _Digits),
             "  ", DoubleToString(trans.price, _Digits),
             "  ", DoubleToString(trans.price_sl, _Digits),
             "  ", DoubleToString(trans.price_tp, _Digits),
             "  ", DoubleToString(trans.price_trigger, _Digits)); 
             
             if (trans.deal_type == DEAL_TYPE_BUY)
             {
                m_Trade.PositionModify(trans.order, trans.price - MathAbs(iMA_High[0] - iMA_Low[0]), iMA_High[0]);
             }
             else if (trans.deal_type == DEAL_TYPE_SELL)
             {
                m_Trade.PositionModify(trans.order, trans.price + MathAbs(iMA_High[0] - iMA_Low[0]), iMA_Low[0]);
             }
          }
     }       
}




void BuyLimit()
{  
   double Price        = iMA_Low[1];  
   double StopLoss     = iMA_Low[1] - MathAbs(iMA_High[1] - iMA_Low[1]);   
   double TakeProfit   = iMA_High[1];  
   datetime Expiration = TimeTradeServer() + PeriodSeconds(PERIOD_D1);   
   string InfoComment  = StringFormat("Buy Stop %s %G lots at %s, SL=%s TP=%s",
                               _Symbol, 
                               Volume,
                               DoubleToString(Price, _Digits),
                               DoubleToString(StopLoss, _Digits),
                               DoubleToString(TakeProfit, _Digits));                          
                                 
   if(!m_Trade.BuyLimit(Volume, Price, _Symbol, StopLoss, TakeProfit, ORDER_TIME_DAY, Expiration, InfoComment))
   {
      Print("-- Fail    BuyLimit: [", m_Trade.ResultRetcode(), "] ", m_Trade.ResultRetcodeDescription());
   }
   else
   {
      Print("-- Success BuyLimit: [", m_Trade.ResultRetcode(), "] ", m_Trade.ResultRetcodeDescription());
   }
}



void ModifyBuyOrder()
{
   double Price        = iMA_Low[1];  
   double StopLoss     = iMA_Low[1] - MathAbs(iMA_High[1] - iMA_Low[1]);   
   double TakeProfit   = iMA_High[1]; 
   datetime Expiration = TimeTradeServer() + PeriodSeconds(PERIOD_D1);   
  
   if (OrdersTotal() == 1)
   {
      ulong Ticket = OrderGetTicket(0);
      if(OrderSelect(Ticket) && OrderGetString(ORDER_SYMBOL) == Symbol())
      {     
         if(!m_Trade.OrderModify(Ticket, Price, StopLoss, TakeProfit, ORDER_TIME_DAY, Expiration))
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




void SellLimit()
{  
   double Price        = iMA_High[1];  
   double StopLoss     = iMA_High[1] + MathAbs(iMA_High[1] - iMA_Low[1]);   
   double TakeProfit   = iMA_Low[1];  
   datetime Expiration = TimeTradeServer() + PeriodSeconds(PERIOD_D1);   
   string InfoComment  = StringFormat("Buy Stop %s %G lots at %s, SL=%s TP=%s",
                               _Symbol, 
                               Volume,
                               DoubleToString(Price, _Digits),
                               DoubleToString(StopLoss, _Digits),
                               DoubleToString(TakeProfit, _Digits));                          
                                 
   if(!m_Trade.SellLimit(Volume, Price, _Symbol, StopLoss, TakeProfit, ORDER_TIME_DAY, Expiration, InfoComment))
   {
      Print("-- Fail    SellLimit: [", m_Trade.ResultRetcode(), "] ", m_Trade.ResultRetcodeDescription());
   }
   else
   {
      Print("-- Success SellLimit: [", m_Trade.ResultRetcode(), "] ", m_Trade.ResultRetcodeDescription());
   }
}



void ModifySellOrder()
{
   double Price        = iMA_High[1];  
   double StopLoss     = iMA_High[1] + MathAbs(iMA_High[1] - iMA_Low[1]);   
   double TakeProfit   = iMA_Low[1]; 
   datetime Expiration = TimeTradeServer() + PeriodSeconds(PERIOD_D1);   
  
   if (OrdersTotal() == 1)
   {
      ulong Ticket = OrderGetTicket(0);
      if(OrderSelect(Ticket) && OrderGetString(ORDER_SYMBOL) == Symbol())
      {     
         if(!m_Trade.OrderModify(Ticket, Price, StopLoss, TakeProfit, ORDER_TIME_DAY, Expiration))
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
            m_Trade.PositionModify(Ticket, iMA_Low[0], TakeProfit);
         }
         else if (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL)
         {
            m_Trade.PositionModify(Ticket, iMA_High[0], TakeProfit);
         }
      } 
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