//+------------------------------------------------------------------+
//|                                                DG_DaveLandry.mq5 |
//|                               Copyright 2020, DG Financial Corp. |
//|                                           https://www.google.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, DG Financial Corp."
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

input ulong                MagicNumber = 12345;
input ENUM_ORDER_ALLOWED   OrderAllowed = BUY_AND_SELL;
input ENUM_TIMEFRAMES      TimeFrame = PERIOD_CURRENT;
input int                  PreviousCandlesCount = 1;
input bool                 UseCurrentCandleForLowHigh = false;             
input int                  TakeProfitPercentOfCandle = 100;
input double               Volume = 100;

input int                  PreviousCandlesTraillingStop = 0; 

ENUM_ORDER_TYPE_FILLING    OrderTypeFilling = ORDER_FILLING_RETURN;
ulong                      OrderDeviationInPoints = 50;

input ENUM_ORDER_TYPE_TIME OrderLifeTime = ORDER_TIME_GTC;

int                        iMA_Handle;                                      // variable for storing the indicator handle
double                     iMA_Data[];                                      // dynamic array for storing indicator values
input int                  MA_Period = 20;  
input ENUM_MA_METHOD       MA_Method = MODE_SMA;   
input ENUM_APPLIED_PRICE   MA_AppliedPrice = PRICE_CLOSE;                          

input int                  HourToOpenOrder = 10;             
input int                  MinuteToOpenOrder = 00; 

MqlRates          Candles[];

MqlDateTime       CurrentTime;   

CTrade            m_Trade;                                         // structure for execution of trades
CPositionInfo     m_Position;                                      // structure for obtaining information of positions

CBarCounter                BarCounter;

int LastCandleTransaction = -1;
int BufferSize = 4; //PreviousCandlesCount + 1;

int OnInit()
{
   iMA_Handle=iMA(_Symbol, TimeFrame, MA_Period, 0, MA_Method, MA_AppliedPrice);  // apply the indicator and get its handle
   if(iMA_Handle == INVALID_HANDLE)                                 // check the availability of the indicator handle
   {
      Print("Failed to get the indicator handle");                  // if the handle is not obtained, print the relevant error message into the log file
      return(INIT_FAILED);                                                   // complete handling the error
   }
  
   ArraySetAsSeries(iMA_Data,true);                                 // set iMA_Data array indexing as time series
   
   ArraySetAsSeries(Candles, true);

   m_Trade.SetDeviationInPoints(OrderDeviationInPoints);
   m_Trade.SetTypeFilling(OrderTypeFilling);
   m_Trade.SetExpertMagicNumber(MagicNumber);

   return(INIT_SUCCEEDED);
}



void OnDeinit(const int reason)
{
   IndicatorRelease(iMA_Handle);                                   // deletes the indicator handle and deallocates the memory space it occupies
   ArrayFree(iMA_Data);                                            // free the dynamic array iMA_Data of data
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
   
   
   ////////////////////////////////////////////////////
   // Check if this is a new candle
   // If it is not a new candle and we don't use the current candle, abort
   //
   BarCounter.OnTick();
   if (!UseCurrentCandleForLowHigh && !BarCounter.IsNewBar())
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
      if (PreviousCandlesTraillingStop > 0)
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
   // Copy MM data
   //
   if(CopyBuffer(iMA_Handle, 0, 0, BufferSize, iMA_Data) < 0)               
   {
      Print("Failed to copy data from the indicator buffer or price chart buffer");  
      return; 
   }
   //
   ////////////////////////////////////////////////////

   MqlTick Tick;
   if(!SymbolInfoTick(_Symbol, Tick))
   {
      Print("Failed to copy tick info");
      return;
   }
   
   bool PriceAboveMA     = Tick.last > iMA_Data[0];
   bool PriceBelowMA     = Tick.last < iMA_Data[0];
   bool CandlesMinLower  = true;
   bool CandlesMaxHigher = true;
   int  BeginCandle = UseCurrentCandleForLowHigh ? 0 : 1;
   for (int i = BeginCandle; i < PreviousCandlesCount + BeginCandle; ++i)
   {
      CandlesMinLower = CandlesMinLower && Candles[i].low < Candles[i+1].low && Candles[i].high > iMA_Data[0];
      CandlesMaxHigher= CandlesMaxHigher && Candles[i].high > Candles[i+1].high && Candles[i].low < iMA_Data[0];;
   }
 
    
   if (PriceAboveMA && CandlesMinLower && OrderAllowed != SELL_ONLY)
   {   
      if (OrdersTotal() > 0)
      {
         ModifyBuyOrder();
      }
      else
      {
         if (LastCandleTransaction + 1 < BarCounter.GetCounter())
            BuyStop();  
      }
   }
   else if (PriceBelowMA && CandlesMaxHigher && OrderAllowed != BUY_ONLY)
   {
      if (OrdersTotal() > 0)
      {
         ModifySellOrder();
      }
      else
      {
         if (LastCandleTransaction + 1 < BarCounter.GetCounter())
            SellStop();
      }
   }
   
        
   //double Bid = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_BID), _Digits);
   //double Ask = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_ASK), _Digits);
   //double Balance = AccountInfoDouble(ACCOUNT_BALANCE);
   //double Equity  = AccountInfoDouble(ACCOUNT_EQUITY);
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
                  case DEAL_TYPE_BUY : ModifyBuyStopLoss(trans.order, trans.price_tp); break;
                  case DEAL_TYPE_SELL : ModifySellStopLoss(trans.order, trans.price_tp); break;
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
                                 
   if(!m_Trade.BuyStop(Volume, Price, _Symbol, StopLoss, TakeProfit, OrderLifeTime, Expiration, InfoComment))
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

void ModifyBuyStopLoss(ulong Ticket, double TakeProfit)
{
   Print("------------------------------------------------ Modify Buy Stop Loss ", BarCounter.GetCounter());
   double StopLoss = MathMin(Candles[1].low, Candles[0].low) - _Point * 1;
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
                                 
   if(!m_Trade.SellStop(Volume, Price, _Symbol, StopLoss, TakeProfit, OrderLifeTime, Expiration, InfoComment))
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



void ModifySellStopLoss(ulong Ticket, double TakeProfit)
{
   Print("------------------------------------------------ Modify Sell Stop Loss ", BarCounter.GetCounter());
   double StopLoss = MathMax(Candles[1].high, Candles[0].high) + _Point * 1; 
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


