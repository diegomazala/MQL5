
namespace DG
{

    double NormalizePrice(double price, double shift = 0)
    {
        double tick_size = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
        return (NormalizeDouble(MathRound(price / tick_size) * tick_size, _Digits) + shift);
    }
};
