//+------------------------------------------------------------------+
//|                                                CandleCounter.mq5 |
//|                        Copyright 2020, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"

MqlRates Candles[];

int      CandleCounter = 0;
datetime TimeStampLastCheck;

int OnInit()
{
   ArraySetAsSeries(Candles, true);
   return(INIT_SUCCEEDED);
}


void OnDeinit(const int reason)
{
   ArrayFree(Candles);
}


void OnTick()
{
   CopyRates(_Symbol, _Period, 0, 3, Candles);
   
   datetime TimeStampCurrentCandle = Candles[0].time;
   
   if (TimeStampCurrentCandle != TimeStampLastCheck)
   {
      TimeStampLastCheck = TimeStampCurrentCandle;
      CandleCounter = CandleCounter + 1;
   }
   
   Comment("Candle Counter : ", CandleCounter);
}
