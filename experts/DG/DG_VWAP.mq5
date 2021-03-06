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
#property link "https://www.google.com"
#property version "1.0"

#include "DG_CandleInfo.mqh"
#include "DG_Price.mqh"
#include "DG_TransactionInfo.mqh"
#include "DG_Timer.mqh"
#include "DG_Trade.mqh"
#include <Trade\PositionInfo.mqh> // include the library for obtaining information on positions

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

input ulong MagicNumber = 20007;
input double Volume = 100;

input                           group                           "Buy/Sell Filter #1" 
input ENUM_ORDER_ALLOWED        OrderAllowed                    = BUY_AND_SELL;
input ENUM_TIMEFRAMES           TimeFrame                       = PERIOD_CURRENT;
input int                       TakeProfitPercentOfCandle       = 150;
input int                       PreviousCandlesTraillingStop    = 0;
//input int                     WaitCandlesAfterStopLoss        = 0;

int DojiBodyPercentage = 10;

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

input                           group                           "Time #3" 
input int                       MinHourToOpenPositions          = 9;
input int                       MinMinuteToOpenPositions        = 15;
input int                       MaxHourToOpenPositions          = 17;
input int                       MaxMinuteToOpenPositions        = 00;
input int                       HourToClosePositions            = 17;
input int                       MinuteToClosePositions          = 30;

input                           group                           "Order Settings #4" 
input ENUM_ORDER_TYPE_TIME      OrderLifeTime                   = ORDER_TIME_DAY;
ulong                           OrderDeviationInPoints          = 50;
ENUM_ORDER_TYPE_FILLING         OrderTypeFilling                = ORDER_FILLING_RETURN;

int VwapHandle;
double VwapData[];

MqlRates Candles[];

DG_Timer                Timer;
DG_Trade                Trade;
//DG_TradeTransaction     Transaction;
DG::CandleInfo          CandleInfo;

ulong LastCandleTransaction = 0;

int LastCandleAboveVwap = 0;
int LastCandleBelowVwap = 0;

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
    if (VwapHandle == INVALID_HANDLE)
    {
        Print("Failed to get the VWAP indicator handle");
        return (INIT_FAILED);
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

    Timer.SetTimeToOpenPositions(MinHourToOpenPositions, MinMinuteToOpenPositions, MaxHourToOpenPositions, MaxMinuteToOpenPositions);
    Timer.SetTimeToClosePositions(HourToClosePositions, MinuteToClosePositions);

    Trade.SetDeviationInPoints(OrderDeviationInPoints);
    Trade.SetTypeFilling(OrderTypeFilling);
    Trade.SetExpertMagicNumber(MagicNumber);
    Trade.SetDeafaultParameters(Volume, TakeProfitPercentOfCandle, OrderLifeTime);

    CandleInfo.ResetPerDay(true);

    LastCandleAboveVwap = 0;
    LastCandleBelowVwap = 0;

    return (INIT_SUCCEEDED);
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

    ////////////////////////////////////////////////////
    // Check time allowed to open/close positions
    Timer.OnTick(Trade);
    //
    ////////////////////////////////////////////////////




    int BufferSize = (int)CandleInfo.GetCounter() + 10;

    ////////////////////////////////////////////////////
    // Copy price information
    //
    if (CopyRates(_Symbol, TimeFrame, 0, 100, Candles) < 0)
    {
        Print("Failed to copy rates");
        return;
    }

    ////////////////////////////////////////////////////
    // Check if this is a new candle
    // If it is not a new candle and we don't use the current candle, abort
    //
    CandleInfo.OnTick();
    if (!CandleInfo.IsNewBar())
        return;
    if (CandleInfo.GetCounter() < 2)
    {

        LastCandleAboveVwap = 0;
        LastCandleBelowVwap = 0;
        return;
    }

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
            Trade.TraillingStop(Candles[PreviousCandlesTraillingStop]);
        }
        return;
    }
    //
    ////////////////////////////////////////////////////

    ////////////////////////////////////////////////////
    //Copy VWAP data
    //
    if (CopyBuffer(VwapHandle, 0, 0, BufferSize, VwapData) < 0)
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

    bool Crossing = (Normalize(Candles[1].high) >= vwap) && (Normalize(Candles[1].low) <= vwap);
    if (!Crossing)
    {
        if (Normalize(Candles[1].high) > vwap && Normalize(Candles[1].low) > vwap)
        {
            LastCandleAboveVwap = (int)CandleInfo.GetCounter();
        }
        else if (Normalize(Candles[1].high) < vwap && Normalize(Candles[1].low) < vwap)
        {
            LastCandleBelowVwap = (int)CandleInfo.GetCounter();
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

    bool HighLowerThenPrev = Normalize(Candles[1].high) <= Normalize(Candles[2].high);
    bool LowHigherThenPrev = Normalize(Candles[1].low) >= Normalize(Candles[2].low);

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

    Print("----------------------- ", CandleInfo.GetCounter(), " Crossing ", Crossing,
          " vwap ", vwap, " high ", Candles[1].high, " low ", Candles[1].low,
          " highlower ", HighLowerThenPrev, "  lowhigher ", LowHigherThenPrev,
          " buy: ", (LastCandleAboveVwap > LastCandleBelowVwap),
          " sell: ", (LastCandleBelowVwap > LastCandleAboveVwap),
          " ordersTotal: ", OrdersTotal());

    if (Crossing && HighLowerThenPrev && (LastCandleAboveVwap > LastCandleBelowVwap))
    {
        Print("============ BUY POSSIBILITY ============");
        if (OrdersTotal() > 0)
        {
            Print("============ ModifyBuyOrder ============");
            //ModifyBuyOrder();
        }
        else
        {
            BuyStop();
        }
    }
    else if (Crossing && LowHigherThenPrev && (LastCandleBelowVwap > LastCandleAboveVwap))
    {
        Print("============ SELL POSSIBILITY ===========");
        if (OrdersTotal() > 0)
        {
            //ModifySellOrder();
        }
        else
        {
            SellStop();
        }
    }
    else
    {
        Print("------------------------------------------------ ", OrdersTotal(), " Pending Orders Canceled at ", CandleInfo.GetCounter());
        Trade.DeletePendingOrders();
    }
}


void OnTradeTransaction(const MqlTradeTransaction &trans,
                        const MqlTradeRequest &request,
                        const MqlTradeResult &result)
{

    //     Print("################################################### INFO < ", CandleInfo.GetCounter());
    //     DG_TransactionInfo::PrintInfo(trans, request, result);
    //     Print("################################################### INFO >");

    if (trans.symbol == _Symbol)
    {
        if (trans.type == TRADE_TRANSACTION_DEAL_ADD)
        {
            LastCandleTransaction = CandleInfo.GetCounter();

            switch (trans.deal_type)
            {
            //case DEAL_TYPE_BUY : ModifyBuyStop(trans.order); break;
            //case DEAL_TYPE_SELL : ModifySellStop(trans.order); break;
            default:
                break;
            }
        }
    }
}

void BuyStop()
{
    Print("------------------------------------------------ Buy Stop ", CandleInfo.GetCounter());
    if (!Trade.BuyStop(Candles[1]))
    {
        Print("-- Fail    BuyStop: [", Trade.ResultRetcode(), "] ", Trade.ResultRetcodeDescription());
    }
    else
    {
        Print("-- Success BuyStop: [", Trade.ResultRetcode(), "] ", Trade.ResultRetcodeDescription());
    }
}

void ModifyBuyOrder()
{
    Print("------------------------------------------------ Modify Buy Order ", CandleInfo.GetCounter());
    if (!Trade.BuyOrderModify(Candles[1]))
    {
        Print("-- Fail    BuyOrderModify: [", Trade.ResultRetcode(), "] ", Trade.ResultRetcodeDescription());
    }
    else
    {
        Print("-- Success BuyOrderModify: [", Trade.ResultRetcode(), "] ", Trade.ResultRetcodeDescription());
    }
}


// void ModifyBuyStop(ulong Ticket)
// {
//     Print("------------------------------------------------ Modify Buy Stop ", CandleInfo.GetCounter());
//     double ProfitScale = TakeProfitPercentOfCandle / 100.0;
//     double StopLoss = DG::NormalizePrice(MathMin(Candles[1].low, Candles[0].low), -0.5);
//     double TakeProfit = (TakeProfitPercentOfCandle == 0) ? 0 : DG::NormalizePrice(MathAbs(Candles[1].high - Candles[1].low) * ProfitScale + Candles[1].high);
//     Trade.PositionModify(Ticket, StopLoss, TakeProfit);
// }

void SellStop()
{
    Print("------------------------------------------------ Sell Stop ", CandleInfo.GetCounter());
    if (!Trade.SellStop(Candles[1]))
    {
        Print("-- Fail    SellStop: [", Trade.ResultRetcode(), "] ", Trade.ResultRetcodeDescription());
    }
    else
    {
        Print("-- Success SellStop: [", Trade.ResultRetcode(), "] ", Trade.ResultRetcodeDescription());
    }
}

void ModifySellOrder()
{
    Print("------------------------------------------------ Modify Sell Order ", CandleInfo.GetCounter());
    if (!Trade.SellOrderModify(Candles[1]))
    {
        Print("-- Fail    SellOrderModify: [", Trade.ResultRetcode(), "] ", Trade.ResultRetcodeDescription());
    }
    else
    {
        Print("-- Success SellOrderModify: [", Trade.ResultRetcode(), "] ", Trade.ResultRetcodeDescription());
    }   
}

// void ModifySellStop(ulong Ticket)
// {
//     Print("------------------------------------------------ Modify Sell Stop  ", CandleInfo.GetCounter());
//     double ProfitScale = TakeProfitPercentOfCandle / 100.0;
//     double CandleRange = Candles[1].high - Candles[1].low;
//     double StopLoss = DG::NormalizePrice(MathMax(Candles[1].high, Candles[0].high), 0.5);
//     double TakeProfit = (TakeProfitPercentOfCandle == 0) ? 0 : DG::NormalizePrice(Candles[1].low - CandleRange * ProfitScale);
//     Trade.PositionModify(Ticket, StopLoss, TakeProfit);
// }


