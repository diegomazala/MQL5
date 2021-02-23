//+------------------------------------------------------------------+
//|                                                     DG_Trade.mqh |
//|                                         Copyright 2009-2021, DG. |
//|                               http://github.com/diegomazala/MQL5 |
//+------------------------------------------------------------------+
#include <Trade\Trade.mqh>        // include the library for execution of trades
#include <Trade\PositionInfo.mqh> // include the library for obtaining information on positions
#include "DG_Price.mqh"
// wizard description start
//+------------------------------------------------------------------+
//| Class DG_Trade.                                                  |
//| Purpose: Class of wrap trade operations                          |
//| Is derived from the CTrade class.                                |
//+------------------------------------------------------------------+
class DG_Trade : public CTrade
{
public:
    DG_Trade(void);
    ~DG_Trade(void);

    void SetDeafaultParameters(double volume, int takeProfitPercentOfCandle, ENUM_ORDER_TYPE_TIME orderLifeTime = ORDER_TIME_DAY);
    bool DeletePendingOrders();
    bool CloseAllPositions();
    bool BuyStop(const MqlRates &lastCandle);
    bool BuyOrderModify(const MqlRates &lastCandle);
    bool SellStop(const MqlRates &lastCandle);
    bool SellOrderModify(const MqlRates &lastCandle);
    void TraillingStop(const MqlRates &previousCandle);

protected:    
    double               Volume;
    double               TakeProfitPercentOfCandle;
    ENUM_ORDER_TYPE_TIME OrderLifeTime;
};

DG_Trade::DG_Trade(void)
{
}

DG_Trade::~DG_Trade(void)
{
}

void DG_Trade::SetDeafaultParameters(double volume, int takeProfitPercentOfCandle, ENUM_ORDER_TYPE_TIME orderLifeTime)
{
    Volume                    = volume;
    TakeProfitPercentOfCandle = takeProfitPercentOfCandle;
    OrderLifeTime             = orderLifeTime;
}


//
// Return true if any order was deleted, false otherwise
//
bool DG_Trade::DeletePendingOrders()
{
    bool deleted = false;
    for (int i = OrdersTotal() - 1; i >= 0; i--)
    {
        ulong ticket = OrderGetTicket(i);
        if (OrderSelect(ticket) && OrderGetString(ORDER_SYMBOL) == Symbol())
        {
            OrderDelete(ticket);
            deleted = true;
        }
    }
    return deleted;
}


//
// Return true if any position was closed, false otherwise
//
bool DG_Trade::CloseAllPositions()
{
    bool positionClosed = false;
    for (int i = PositionsTotal() - 1; i >= 0; i--)
    {
        PositionClose(PositionGetTicket(i));
        positionClosed = true;
    }
    return positionClosed;
}

bool DG_Trade::BuyStop(const MqlRates &lastCandle)
{
    double ProfitScale = TakeProfitPercentOfCandle / 100.0;
    double Price = MathMax(lastCandle.high, SymbolInfoDouble(_Symbol, SYMBOL_ASK));
    double StopLoss = DG::NormalizePrice(lastCandle.low, -0.5);
    double TakeProfit = (TakeProfitPercentOfCandle == 0) ? 0 : DG::NormalizePrice(MathAbs(lastCandle.high - lastCandle.low) * ProfitScale + lastCandle.high);
    datetime Expiration = TimeTradeServer() + PeriodSeconds(PERIOD_D1);
    string InfoComment = StringFormat("Buy Stop %s %G lots at %s, SL=%s TP=%s",
                                      _Symbol,
                                      Volume,
                                      DoubleToString(Price, _Digits),
                                      DoubleToString(StopLoss, _Digits),
                                      DoubleToString(TakeProfit, _Digits));

    return CTrade::BuyStop(Volume, Price, _Symbol, StopLoss, TakeProfit, OrderLifeTime, Expiration, InfoComment);
}


bool DG_Trade::BuyOrderModify(const MqlRates &lastCandle)
{
    double ProfitScale = TakeProfitPercentOfCandle / 100.0;
    double Price = MathMax(lastCandle.high, SymbolInfoDouble(_Symbol, SYMBOL_ASK));
    double StopLoss = DG::NormalizePrice(lastCandle.low, -0.5);
    double TakeProfit = (TakeProfitPercentOfCandle == 0) ? 0 : DG::NormalizePrice(MathAbs(lastCandle.high - lastCandle.low) * ProfitScale + lastCandle.high);
    datetime Expiration = TimeTradeServer() + PeriodSeconds(PERIOD_D1);

    if (OrdersTotal() == 1)
    {
        ulong Ticket = OrderGetTicket(0);
        if (OrderSelect(Ticket) && OrderGetString(ORDER_SYMBOL) == Symbol())
        {
            return CTrade::OrderModify(Ticket, Price, StopLoss, TakeProfit, OrderLifeTime, Expiration);
        }
    }
    return false;
}


bool DG_Trade::SellStop(const MqlRates &lastCandle)
{
    double ProfitScale = TakeProfitPercentOfCandle / 100.0;
    double CandleRange = lastCandle.high - lastCandle.low;
    double Price = MathMin(lastCandle.low, SymbolInfoDouble(_Symbol, SYMBOL_BID));
    double StopLoss = DG::NormalizePrice(lastCandle.high, 0.5);
    double TakeProfit = (TakeProfitPercentOfCandle == 0) ? 0 : DG::NormalizePrice(lastCandle.low - CandleRange * ProfitScale);
    datetime Expiration = TimeTradeServer() + PeriodSeconds(PERIOD_D1);
    string InfoComment = StringFormat("Sell Stop %s %G lots at %s, SL=%s TP=%s",
                                      _Symbol,
                                      Volume,
                                      DoubleToString(Price, _Digits),
                                      DoubleToString(StopLoss, _Digits),
                                      DoubleToString(TakeProfit, _Digits));

    return CTrade::SellStop(Volume, Price, _Symbol, StopLoss, TakeProfit, OrderLifeTime, Expiration, InfoComment);
}


bool DG_Trade::SellOrderModify(const MqlRates &lastCandle)
{
    double ProfitScale = TakeProfitPercentOfCandle / 100.0;
    double CandleRange = lastCandle.high - lastCandle.low;
    double Price = MathMin(lastCandle.low, SymbolInfoDouble(_Symbol, SYMBOL_BID));
    double StopLoss = DG::NormalizePrice(lastCandle.high, 0.5);
    double TakeProfit = (TakeProfitPercentOfCandle == 0) ? 0 : DG::NormalizePrice(lastCandle.low - CandleRange * ProfitScale);
    datetime Expiration = TimeTradeServer() + PeriodSeconds(PERIOD_D1);

    if (OrdersTotal() == 1)
    {
        ulong Ticket = OrderGetTicket(0);
        if (OrderSelect(Ticket) && OrderGetString(ORDER_SYMBOL) == Symbol())
        {
            return Trade.OrderModify(Ticket, Price, StopLoss, TakeProfit, OrderLifeTime, Expiration);
        }
    }
    return false;
}




void DG_Trade::TraillingStop(const MqlRates &previousCandle)
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
                PositionModify(Ticket, DG::NormalizePrice(previousCandle.low, -0.5), TakeProfit);
            }
            else if (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL)
            {
                PositionModify(Ticket, DG::NormalizePrice(previousCandle.high, 0.5), TakeProfit);
            }
        }
    }
}