//+------------------------------------------------------------------+
//|                                           fast-start-example.mq5 |
//|                        Copyright 2012, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2012, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
#include <Trade\Trade.mqh>                                         //include the library for execution of trades
#include <Trade\PositionInfo.mqh>                                  //include the library for obtaining information on positions

int               iMA_handle;                                      //variable for storing the indicator handle
double            iMA_buf[];                                       //dynamic array for storing indicator values
double            Close_buf[];                                     //dynamic array for storing the closing price of each bar

string            my_symbol;                                       //variable for storing the symbol
ENUM_TIMEFRAMES   my_timeframe;                                    //variable for storing the time frame

CTrade            m_Trade;                                         //structure for execution of trades
CPositionInfo     m_Position;                                      //structure for obtaining information of positions
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit()
  {
  
   my_symbol=Symbol();                                             //save the current chart symbol for further operation of the EA on this very symbol
   my_timeframe=PERIOD_CURRENT;                                    //save the current time frame of the chart for further operation of the EA on this very time frame
   iMA_handle=iMA(my_symbol,my_timeframe,20,0,MODE_SMA,PRICE_CLOSE);  //apply the indicator and get its handle
   if(iMA_handle==INVALID_HANDLE)                                  //check the availability of the indicator handle
   {
      Print("Failed to get the indicator handle");                 //if the handle is not obtained, print the relevant error message into the log file
      return(-1);                                                  //complete handling the error
   }
   ChartIndicatorAdd(ChartID(),0,iMA_handle);                      //add the indicator to the price chart
   ArraySetAsSeries(iMA_buf,true);                                 //set iMA_buf array indexing as time series
   ArraySetAsSeries(Close_buf,true);                               //set Close_buf array indexing as time series
   return(0);                                                      //return 0, initialization complete
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   IndicatorRelease(iMA_handle);                                   //deletes the indicator handle and deallocates the memory space it occupies
   ArrayFree(iMA_buf);                                             //free the dynamic array iMA_buf of data
   ArrayFree(Close_buf);                                           //free the dynamic array Close_buf of data
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
  
   int err1=0;                                                     //variable for storing the results of working with the indicator buffer
   int err2=0;                                                     //variable for storing the results of working with the price chart
   
   err1=CopyBuffer(iMA_handle,0,0,3,iMA_buf);                      //copy data from the indicator array into the dynamic array iMA_buf for further work with them
   err2=CopyClose(my_symbol,my_timeframe,0,3,Close_buf);           //copy the price chart data into the dynamic array Close_buf for further work with them
   if(err1<0 || err2<0)                                            //in case of errors
   {
      Print("Failed to copy data from the indicator buffer or price chart buffer");  //then print the relevant error message into the log file
      return;                                                                        //and exit the function
   }
   
   bool BuyPositionOpen  = PositionSelect(my_symbol) && (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY);
   bool SellPositionOpen = PositionSelect(my_symbol) && (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL);
  
   
   bool CrossUp   = Close_buf[1] > iMA_buf[1] && Close_buf[2] < iMA_buf[2];
   bool CrossDown = Close_buf[1] < iMA_buf[1] && Close_buf[2] > iMA_buf[2];

 
   if (CrossUp)
   {
      if (BuyPositionOpen) 
      {
         //m_Trade.PositionClose(my_symbol);
         //Comment("Buy Position Closed");
      }
      else if(SellPositionOpen)
      {
         m_Trade.PositionClose(my_symbol);
         Print("Sell Position Closed");
      }
      else
      {
         m_Trade.Buy(100, my_symbol);
         Print("Buy Order");
      }
   }
   else if (CrossDown)
   {
      if (SellPositionOpen) 
      {
         //m_Trade.PositionClose(my_symbol);
         //Comment("Sell Position Closed");
      }
      else if(BuyPositionOpen)
      {
         m_Trade.PositionClose(my_symbol);
         Print("Buy Position Closed");
      }
      else
      {
         m_Trade.Sell(100, my_symbol);
         Print("Sell Order");
      }
   }
  
  }
//+------------------------------------------------------------------+

