

void OnTick()
{
   // Get the first visible candle on the chart
   int CandlesOnChart = ChartGetInteger(0, CHART_FIRST_VISIBLE_BAR, 0);
   
   // Create a variable for the lowest candle
   int LowestCandle;
   
   // Create an array for the lowest candle prices
   double Low[];
    
   // Create a variable for the highest candle
   int HighestCandle;
   
   // Create an array for the highest candle prices
   double High[];

   // Sort the array for the lowest candle prices
   ArraySetAsSeries(Low, true);
   
   // Sort the array for the highest candle prices
   ArraySetAsSeries(High, true);
   
   // Fill the array with data for the candles on the chart
   CopyLow(_Symbol, _Period, 0, CandlesOnChart, Low);

   // Fill the array with data for the candles on the chart
   CopyHigh(_Symbol, _Period, 0, CandlesOnChart, High);

   // Calculate the lowest candle
   LowestCandle = ArrayMinimum(Low, 0, CandlesOnChart);
   
   // Calculate the highest candle
   HighestCandle = ArrayMaximum(High, 0, CandlesOnChart);
   
   // Create an array for price data
   MqlRates PriceInformation[];
   
   // Sort the array from the current candle downwards
   ArraySetAsSeries(PriceInformation, true);
   
   // Fill the array with data for the candles on the chart
   int Data = CopyRates(_Symbol, _Period, 0, CandlesOnChart, PriceInformation);

   // Delete the old object
   ObjectDelete(_Symbol, "ChannelObject");
   
   // Create a channel object
   ObjectCreate(
                _Symbol,                              // for the current currency
                "ChannelObject",                      // object name
                OBJ_CHANNEL,                          // object type
                0,                                    // candle chart
                PriceInformation[LowestCandle].time,  // from the lowest candle
                PriceInformation[LowestCandle].low,   // from the lowest candle
                PriceInformation[0].time,             // from the lowest candle
                PriceInformation[LowestCandle].low,   // from the lowest candle
                PriceInformation[HighestCandle].time, // from the lowest candle
                PriceInformation[HighestCandle].high  // from the lowest candle
               );
        
   // Set the object color
   ObjectSetInteger(0, "ChannelObject", OBJPROP_COLOR, Yellow);

   // Set the object style
   ObjectSetInteger(0, "ChannelObject", OBJPROP_STYLE, STYLE_SOLID);
   

   // Set the object width
   ObjectSetInteger(0, "ChannelObject", OBJPROP_WIDTH, 1);   

   // Set the object preview
   ObjectSetInteger(0, "ChannelObject", OBJPROP_RAY_RIGHT, true);

}



