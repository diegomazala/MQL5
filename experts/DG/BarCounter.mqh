//+------------------------------------------------------------------+
//|                                                   BarCounter.mqh |
//|                               Copyright 2020, DG Financial Corp. |
//|                                           https://www.google.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, DG Financial Corp."
#property link      "https://www.google.com"
#property version   "1.0"


class CBarCounter
{   
public:
   
   CBarCounter()
   {
      LastCandleTime = 0;
      Counter = 0;
      NewBar = false;
   }
   
   void OnTick()
   {
      NewBar = false;
      
      datetime currentCandleTime = SeriesInfoInteger(_Symbol, _Period, SERIES_LASTBAR_DATE);
      if (LastCandleTime != currentCandleTime)
      {
         LastCandleTime = currentCandleTime;
         Counter = Counter + 1;
         NewBar = true;
      }
   }
   
   ulong GetCounter() const 
   { 
      return Counter; 
   }
   
   bool IsNewBar() const
   {
      return NewBar;
   }
 
private:  
   datetime LastCandleTime;
   ulong Counter;
   bool NewBar;
   
};