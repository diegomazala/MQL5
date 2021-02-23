//+------------------------------------------------------------------+
//|                                                   BarCounter.mqh |
//|                               Copyright 2020, DG Financial Corp. |
//|                                           https://www.google.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, DG Financial Corp."
#property link      "https://www.google.com"
#property version   "1.0"

namespace DG
{
    class CandleInfo
    {   
        public:
        
        CandleInfo()
        {
            LastCandleTime = 0;
            Counter = 0;
            NewBar = false;
            ResetCounterPerDay = false;
        }
        
        void OnTick()
        {
            NewBar = false;
            
            datetime currentCandleTime = (datetime)SeriesInfoInteger(_Symbol, _Period, SERIES_LASTBAR_DATE);
            if (LastCandleTime != currentCandleTime)
            {
                LastCandleTime = currentCandleTime;
                Counter = Counter + 1;
                NewBar = true;
            }

            datetime today = (datetime)SeriesInfoInteger(_Symbol, PERIOD_D1, SERIES_LASTBAR_DATE);
            if (LastDay != today)
            {
                Counter = 1;
                LastDay = today;
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

        void ResetPerDay(bool reset)
        {
            ResetCounterPerDay = reset;
        }

        bool ResetPerDay()
        {
            return ResetCounterPerDay;
        }


        static bool IsStrongBar(double o, double h, double l, double c, int closePercentage)
        {
            int percentage = 0;
            if (c > o) // bull bar
                percentage = (int)((c - l) / (h - l)) * 100;
            else // bear bar
                percentage = 100 - (int)((c - l) / (h - l)) * 100;
            return percentage >= closePercentage;
        }
        


        static bool IsDoji(double o, double l, double h, double c, int bodyPercentage)
        {
            double body = MathAbs(c - o);
            double range = MathAbs(h - l);
            int percentage = (int)((body / range) * 100);
            return (percentage <= bodyPercentage);
        }


        private:  
            datetime LastCandleTime;
            ulong Counter;
            bool NewBar;
            bool ResetCounterPerDay;

            datetime LastDay;
    };
}