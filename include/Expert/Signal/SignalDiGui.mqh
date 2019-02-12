//+------------------------------------------------------------------+
//|                                                  SignalDiGui.mqh |
//|                   Copyright 2009-2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#include <Expert\ExpertSignal.mqh>
#property tester_indicator "Examples\\Custom Moving Average.ex5"
// wizard description start
//+------------------------------------------------------------------+
//| Description of the class                                         |
//| Title=Signals of indicator 'DiGui'                               |
//| Type=SignalAdvanced                                              |
//| Name=DiGui                                                       |
//| ShortName=DG                                                     |
//| Class=CSignalDiGui                                               |
//| Page=Not needed                                                  |
//| Parameter=FastPeriod,int,3,Period of fast MA                     |
//| Parameter=FastMethod,ENUM_MA_METHOD,MODE_SMA,Method of fast MA   |
//| Parameter=MeanPeriod,int,8,Period of mean MA                     |
//| Parameter=MeanMethod,ENUM_MA_METHOD,MODE_SMA,Method of mean MA   |
//| Parameter=SlowPeriod,int,20,Period of slow MA                    |
//| Parameter=SlowMethod,ENUM_MA_METHOD,MODE_SMA,Method of slow MA   |
//+------------------------------------------------------------------+
// wizard description end
//+------------------------------------------------------------------+
//| Class CSignalDiGui.                                              |
//| Purpose: Class of generator of trade signals based on            |
//|          the 'Moving Average' indicator.                         |
//| Is derived from the CExpertSignal class.                         |
//+------------------------------------------------------------------+
class CSignalDiGui : public CExpertSignal
  {
protected:
   CiCustom          m_fast_ma;        // The indicator as an object
   CiCustom          m_mean_ma;        // The indicator as an object
   CiCustom          m_slow_ma;        // The indicator as an object
   
   //--- Configurable module parameters
   int               m_period_fast;    // Period of the fast MA
   int               m_period_mean;    // Period of the mean MA
   int               m_period_slow;    // Period of the slow MA
   ENUM_MA_METHOD    m_method_fast;    // Type of smoothing of the fast MA
   ENUM_MA_METHOD    m_method_mean;    // Type of smoothing of the fast MA
   ENUM_MA_METHOD    m_method_slow;    // Type of smoothing of the slow MA

public:
                     CSignalDiGui(void);
                    ~CSignalDiGui(void);

   //--- method of verification of settings
   virtual bool      ValidationSettings(void);
   //--- method of creating the indicator and timeseries
   virtual bool      InitIndicators(CIndicators *indicators);
   //--- methods of checking if the market models are formed
   virtual int       LongCondition(void);
   virtual int       ShortCondition(void);

   
   //--- Methods for setting
   void              FastPeriod(int value)               { m_period_fast=value;        }
   void              FastMethod(ENUM_MA_METHOD value)    { m_method_fast=value;        }
   void              MeanPeriod(int value)               { m_period_mean=value;        }
   void              MeanMethod(ENUM_MA_METHOD value)    { m_method_mean=value;        }
   void              SlowPeriod(int value)               { m_period_slow=value;        }
   void              SlowMethod(ENUM_MA_METHOD value)    { m_method_slow=value;        }

   //--- Access to indicator data
   double            FastMA(const int index)             const { return(m_fast_ma.GetData(0,index)); }
   double            MeanMA(const int index)             const { return(m_mean_ma.GetData(0,index)); }
   double            SlowMA(const int index)             const { return(m_slow_ma.GetData(0,index)); }

protected:
   //--- Creating MA indicators
   bool              CreateFastMA(CIndicators *indicators);
   bool              CreateMeanMA(CIndicators *indicators);
   bool              CreateSlowMA(CIndicators *indicators);
  };
//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CSignalDiGui::CSignalDiGui(void) : 
                             m_period_fast(3),           // Default period of the fast MA is 3
                             m_method_fast(MODE_SMA),    // Default smoothing method of the fast MA
                             m_period_mean(8),           // Default period of the mean MA is 8
                             m_method_mean(MODE_SMA),    // Default smoothing method of the mean MA
                             m_period_slow(20),          // Default period of the slow MA is 20
                             m_method_slow(MODE_SMA)     // Default smoothing method of the slow MA
  {
//--- initialization of protected data
   m_used_series=USE_SERIES_OPEN+USE_SERIES_HIGH+USE_SERIES_LOW+USE_SERIES_CLOSE;
  }
//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CSignalDiGui::~CSignalDiGui(void)
  {
  }
//+------------------------------------------------------------------+
//| Validation settings protected data.                              |
//+------------------------------------------------------------------+
bool CSignalDiGui::ValidationSettings(void)
  {
//--- validation settings of additional filters
   if(!CExpertSignal::ValidationSettings())
      return(false);
//--- Check periods, number of bars for the calculation of the MA >=1
   if(m_period_fast<1 || m_period_mean<1 || m_period_slow<1)
     {
      PrintFormat("Incorrect value set for one of the periods! FastPeriod=%d, MeanPeriod=%d, SlowPeriod=%d",
                  m_period_fast,m_period_mean,m_period_slow);
      return false;
     }
//--- Slow MA period must be greater that the fast MA period
   if(m_period_fast>m_period_mean || m_period_mean>m_period_slow)
     {
      PrintFormat("SlowPeriod=%d must be greater than MeanPeriod=%d and MeanPeriod=%d must be greater than FastPeriod%d!",
                  m_period_slow,m_period_mean,m_period_fast);
      return false;
     }
//--- Fast MA smoothing type must be one of the four values of the enumeration
   if(m_method_fast!=MODE_SMA && m_method_fast!=MODE_EMA && m_method_fast!=MODE_SMMA && m_method_fast!=MODE_LWMA)
     {
      PrintFormat("Invalid type of smoothing of the fast MA!");
      return false;
     }
//--- Mean MA smoothing type must be one of the four values of the enumeration
   if(m_method_mean!=MODE_SMA && m_method_mean!=MODE_EMA && m_method_mean!=MODE_SMMA && m_method_mean!=MODE_LWMA)
     {
      PrintFormat("Invalid type of smoothing of the fast MA!");
      return false;
     }
//--- Show MA smoothing type must be one of the four values of the enumeration
   if(m_method_slow!=MODE_SMA && m_method_slow!=MODE_EMA && m_method_slow!=MODE_SMMA && m_method_slow!=MODE_LWMA)
     {
      PrintFormat("Invalid type of smoothing of the slow MA!");
      return false;
     }
//--- All checks are completed, everything is ok
   return true;
  }


//+------------------------------------------------------------------+
//| Create indicators.                                               |
//+------------------------------------------------------------------+
bool CSignalDiGui::InitIndicators(CIndicators *indicators)
  {
//--- check pointer
   if(indicators==NULL)
      return(false);
//--- Initializing indicators and timeseries in additional filters
   if(!CExpertSignal::InitIndicators(indicators)) return(false);
//--- Creating our MA indicators
   if(!CreateFastMA(indicators))                  return(false);
   if(!CreateMeanMA(indicators))                  return(false);
   if(!CreateSlowMA(indicators))                  return(false);
//--- Reached this part, so the function was successful, return true
   return(true);
  }




//+------------------------------------------------------------------+
//| Creates the "Fast MA" indicator                                  |
//+------------------------------------------------------------------+
bool CSignalDiGui::CreateFastMA(CIndicators *indicators)
  {
//--- Checking the pointer
   if(indicators==NULL) return(false);
//--- Adding an object to the collection
   if(!indicators.Add(GetPointer(m_fast_ma)))
     {
      printf(__FUNCTION__+": Error adding an object of the fast MA");
      return(false);
     }
//--- Setting parameters of the fast MA
   MqlParam parameters[4];
//---
   parameters[0].type=TYPE_STRING;
   parameters[0].string_value="Examples\\Custom Moving Average.ex5";
   parameters[1].type=TYPE_INT;
   parameters[1].integer_value=m_period_fast;      // Period
   parameters[2].type=TYPE_INT;
   parameters[2].integer_value=0;                  // Shift
   parameters[3].type=TYPE_INT;
   parameters[3].integer_value=m_method_fast;      // Method of averaging
//--- Object initialization
   if(!m_fast_ma.Create(m_symbol.Name(),m_period,IND_CUSTOM,4,parameters))
     {
      printf(__FUNCTION__+": Error initializing the object of the fast MA");
      return(false);
     }
//--- Number of buffers
   if(!m_fast_ma.NumBuffers(1)) return(false);
//--- Reached this part, so the function was successful, return true
   return(true);
  }



//+------------------------------------------------------------------+
//| Creates the "Mean MA" indicator                                  |
//+------------------------------------------------------------------+
bool CSignalDiGui::CreateMeanMA(CIndicators *indicators)
  {
//--- Checking the pointer
   if(indicators==NULL) return(false);
//--- Adding an object to the collection
   if(!indicators.Add(GetPointer(m_mean_ma)))
     {
      printf(__FUNCTION__+": Error adding an object of the mean MA");
      return(false);
     }
//--- Setting parameters of the mean MA
   MqlParam parameters[4];
//---
   parameters[0].type=TYPE_STRING;
   parameters[0].string_value="Examples\\Custom Moving Average.ex5";
   parameters[1].type=TYPE_INT;
   parameters[1].integer_value=m_period_slow;      // Period
   parameters[2].type=TYPE_INT;
   parameters[2].integer_value=0;                  // Shift
   parameters[3].type=TYPE_INT;
   parameters[3].integer_value=m_method_slow;      // Method of averaging
//--- Object initialization  
   if(!m_mean_ma.Create(m_symbol.Name(),m_period,IND_CUSTOM,4,parameters))
     {
      printf(__FUNCTION__+": Error initializing the object of the mean MA");
      return(false);
     }
//--- Number of buffers
   if(!m_mean_ma.NumBuffers(1)) return(false);
//--- Reached this part, so the function was successful, return true
   return(true);
  }


//+------------------------------------------------------------------+
//| Creates the "Slow MA" indicator                                  |
//+------------------------------------------------------------------+
bool CSignalDiGui::CreateSlowMA(CIndicators *indicators)
  {
//--- Checking the pointer
   if(indicators==NULL) return(false);
//--- Adding an object to the collection
   if(!indicators.Add(GetPointer(m_slow_ma)))
     {
      printf(__FUNCTION__+": Error adding an object of the slow MA");
      return(false);
     }
//--- Setting parameters of the slow MA
   MqlParam parameters[4];
//---
   parameters[0].type=TYPE_STRING;
   parameters[0].string_value="Examples\\Custom Moving Average.ex5";
   parameters[1].type=TYPE_INT;
   parameters[1].integer_value=m_period_slow;      // Period
   parameters[2].type=TYPE_INT;
   parameters[2].integer_value=0;                  // Shift
   parameters[3].type=TYPE_INT;
   parameters[3].integer_value=m_method_slow;      // Method of averaging
//--- Object initialization  
   if(!m_slow_ma.Create(m_symbol.Name(),m_period,IND_CUSTOM,4,parameters))
     {
      printf(__FUNCTION__+": Error initializing the object of the slow MA");
      return(false);
     }
//--- Number of buffers
   if(!m_slow_ma.NumBuffers(1)) return(false);
//--- Reached this part, so the function was successful, return true
   return(true);
  }


//+------------------------------------------------------------------+
//| "Voting" that price will grow.                                   |
//+------------------------------------------------------------------+
int CSignalDiGui::LongCondition(void)
  {
    int signal=0;
//--- For operation with ticks idx=0, for operation with formed bars idx=1
   int idx=StartIndex();
//--- Values of MAs at the last formed bar
   double last_fast_value=FastMA(idx);
   double last_mean_value=MeanMA(idx);
   double last_slow_value=SlowMA(idx);
//--- Values of MAs at the last but one formed bar
   double prev_fast_value=FastMA(idx+1);
   double prev_mean_value=MeanMA(idx+1);
   double prev_slow_value=SlowMA(idx+1);
//--- If the fast MA crossed the slow MA from bottom upwards on the last two closed bars
   if((last_fast_value>last_mean_value) && (prev_fast_value<prev_mean_value))
     {
      signal=100; // There is a signal to buy
     }
//--- Return the signal value
   return(signal);
  }


//+------------------------------------------------------------------+
//| "Voting" that price will fall.                                   |
//+------------------------------------------------------------------+
int CSignalDiGui::ShortCondition(void)
  {
   int signal=0;
//--- For operation with ticks idx=0, for operation with formed bars idx=1
   int idx=StartIndex();
//--- Values of MAs at the last formed bar
   double last_fast_value=FastMA(idx);
   double last_mean_value=SlowMA(idx);
   double last_slow_value=SlowMA(idx);
//--- Values of MAs at the last but one formed bar
   double prev_fast_value=FastMA(idx+1);
   double prev_mean_value=FastMA(idx+1);
   double prev_slow_value=SlowMA(idx+1);
//--- If the fast MA crossed the slow MA from up downwards on the last two closed bars
   if((last_fast_value<last_mean_value) && (prev_fast_value>prev_mean_value))
     {
      signal=100; // There is a signal to sell
     }
//--- Return the signal value
   return(signal);
  }
//+------------------------------------------------------------------+