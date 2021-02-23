//+------------------------------------------------------------------+
//|                                                     DG_Timer.mqh |
//|                                         Copyright 2009-2021, DG. |
//|                               http://github.com/diegomazala/MQL5 |
//+------------------------------------------------------------------+
#include "DG_Trade.mqh"
//+------------------------------------------------------------------+
//| Class DG_Timer.                                                  |
//+------------------------------------------------------------------+
class DG_Timer
{
public:
	DG_Timer(void);
   ~DG_Timer(void);

    void SetTimeToOpenPositions(int min_hour, int min_minutes, int max_hour, int max_minutes);
    void SetTimeToClosePositions(int hour, int minutes);

    bool IsItTimeToOpenPositions() const;
    bool IsItTimeToClosePositions() const;

    void OnTick(DG_Trade& trade) const;

protected:

    int MinHourToOpenPositions;
    int MinMinuteToOpenPositions;
    int MaxHourToOpenPositions;
    int MaxMinuteToOpenPositions;
    int HourToClosePositions;
    int MinuteToClosePositions;
};



DG_Timer::DG_Timer(void):
    MinHourToOpenPositions(9),             
    MinMinuteToOpenPositions(15),
    MaxHourToOpenPositions(17),             
    MaxMinuteToOpenPositions(00), 
    HourToClosePositions(17),
    MinuteToClosePositions(30)
{
}

DG_Timer::~DG_Timer(void)
{
}


void DG_Timer::SetTimeToOpenPositions(int min_hour, int min_minutes, int max_hour, int max_minutes)
{
    MinHourToOpenPositions = min_hour;
    MinMinuteToOpenPositions = min_minutes;
    MaxHourToOpenPositions = max_hour;
    MaxMinuteToOpenPositions = max_minutes;
}

void DG_Timer::SetTimeToClosePositions(int hour, int minutes)
{
    HourToClosePositions = hour;
    MinuteToClosePositions = minutes;
}

//
// Return true if time it is time range
//
bool DG_Timer::IsItTimeToOpenPositions() const
{
    MqlDateTime currentTime;   
    TimeToStruct(TimeCurrent(), currentTime);
    // let's convert everything to minutes
    ulong now = currentTime.hour * 60 + currentTime.min;
    ulong minTime = MinHourToOpenPositions * 60 + MinMinuteToOpenPositions;
    ulong maxTime = MaxHourToOpenPositions * 60 + MaxMinuteToOpenPositions;
    return (now > minTime) && (now < maxTime);
}


//
// Return true if time is over
//
bool DG_Timer::IsItTimeToClosePositions() const
{
    MqlDateTime currentTime;   
    TimeToStruct(TimeCurrent(), currentTime);
    ulong now = currentTime.hour * 60 + currentTime.min;
    ulong timeToClose = HourToClosePositions * 60 + MinuteToClosePositions;
    return (now >= timeToClose);
}


void DG_Timer::OnTick(DG_Trade& trade) const
{
    if (IsItTimeToClosePositions())
    {
        if (PositionsTotal() > 0)
        {
            trade.CloseAllPositions();
        }
    }

    if (!IsItTimeToOpenPositions() && PositionsTotal() < 1) // nothing to do
    {
        return;
    }
}