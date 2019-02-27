//+------------------------------------------------------------------+
//|                                                TrailingMinPrev.mqh |
//|                   Copyright 2009-2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#include <Expert\ExpertTrailing.mqh>
// wizard description start
//+------------------------------------------------------------------+
//| Description of the class                                         |
//| Title=Trailing Stop based on Min value of previos candle         |
//| Type=Trailing                                                    |
//| Name=DG                                                          |
//| Class=CTrailingMinPrev                                             |
//| Page=                                                            |
//+------------------------------------------------------------------+
// wizard description end
//+------------------------------------------------------------------+
//| Class CTrailingMinPrev.                                           |
//| Purpose: Class of trailing stops based on minimal value of candle.|
//|              Derives from class CExpertTrailing.                 |
//+------------------------------------------------------------------+
class CTrailingMinPrev : public CExpertTrailing
  {
protected:
   CiMA          m_fast_ma;        // The indicator as an object
   CiMA          m_mean_ma;        // The indicator as an object
   CiMA          m_slow_ma;        // Slow MA indicator as an object
   CiADXWilder   m_adx;			     // ADX indicator as an object
   
   //--- Configurable module parameters
   int               m_period_fast;    // Period of the fast MA
   int               m_period_mean;    // Period of the mean MA
   int               m_period_slow;    // Period of the slow MA
   ENUM_MA_METHOD    m_method_fast;    // Type of smoothing of the fast MA
   ENUM_MA_METHOD    m_method_mean;    // Type of smoothing of the fast MA
   ENUM_MA_METHOD    m_method_slow;    // Type of smoothing of the slow MA
   int               m_ma_shift;       // the "time shift" parameter of the MA indicators
   ENUM_APPLIED_PRICE m_ma_applied;    // the "object of averaging" parameter of the indicator   

   int               m_period_adx;     // Period of the ADX
   double            m_level_adx;      // Level of thee ADX
   
   double            m_dd_epsilon;     // Max distance between cross lines

public:
                     CTrailingMinPrev(void);
                    ~CTrailingMinPrev(void);
   //--- methods of initialization of protected data
   virtual bool      InitIndicators(CIndicators *indicators);
   virtual bool      ValidationSettings(void);
   
   //--- Methods for setting
   void              FastPeriod(int value)               { m_period_fast=value;        }
   void              FastMethod(ENUM_MA_METHOD value)    { m_method_fast=value;        }
   void              MeanPeriod(int value)               { m_period_mean=value;        }
   void              MeanMethod(ENUM_MA_METHOD value)    { m_method_mean=value;        }
   void              SlowPeriod(int value)               { m_period_slow=value;        }
   void              SlowMethod(ENUM_MA_METHOD value)    { m_method_slow=value;        }
   void              Shift(int value)                    { m_ma_shift=value;           }
   void              Applied(ENUM_APPLIED_PRICE value)   { m_ma_applied=value;         }
   
   void              ADXPeriod(int value)                { m_period_adx=value;         }
   void              ADXLevel(double value)              { m_level_adx=value;          }
   
   //--- Access to indicator data
   double            FastMA(const int index)             const { return(m_fast_ma.GetData(0,index)); }
   double            MeanMA(const int index)             const { return(m_mean_ma.GetData(0,index)); }
   double            SlowMA(const int index)             const { return(m_slow_ma.GetData(0,index)); }

   double            FastDD(const int index)             const { return(m_fast_ma.GetData(0,index) / m_mean_ma.GetData(0,index)); }
   double            MeanDD(const int index)             const { return(1.00); }
   double            SlowDD(const int index)             const { return(m_slow_ma.GetData(0,index) / m_mean_ma.GetData(0,index)); }
      
   double            ADXPlus(const int index)            const { return(m_adx.Plus(index)); }
   double            ADXMinus(const int index)           const { return(m_adx.Minus(index));}
   double            ADXMain(const int index)            const { return(m_adx.Main(index)); }
   
   double            EpsilonDD(const double value)       const { return m_dd_epsilon; }

   
   //---
   virtual bool      CheckTrailingStopLong(CPositionInfo *position,double &sl,double &tp);
   virtual bool      CheckTrailingStopShort(CPositionInfo *position,double &sl,double &tp);
   
   
protected:
   //--- Creating MA indicators
   bool              CreateFastMA(CIndicators *indicators);
   bool              CreateMeanMA(CIndicators *indicators);
   bool              CreateSlowMA(CIndicators *indicators);
   //--- Creating ADX indicators
   bool              CreateADX(CIndicators *indicators);
   
   
   
   
   bool CheckDDCrossFastMeanBuy(int idx) const
   {
      return AreGEquals(FastDD(idx), MeanDD(idx)) && AreLEquals(FastDD(idx), MeanDD(idx));
   }


   bool CheckDDCrossFastMeanSell(int idx) const
   {
      return AreLEquals(FastDD(idx), MeanDD(idx)) && AreGEquals(FastDD(idx), MeanDD(idx));
   }
   
   
   bool AreEquals(double a, double b) const 
   {
       return MathAbs(a - b) < m_dd_epsilon;
   }
   bool AreLEquals(double a, double b) const
   {
       return (a < b) && AreEquals(a, b);
   }
   bool AreGEquals(double a, double b) const
   {
       return (a > b) && AreEquals(a, b);
   }  
};


  
  
  
//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
void CTrailingMinPrev::CTrailingMinPrev(void) :
                             m_period_fast(3),           // Default period of the fast MA is 3
                             m_method_fast(MODE_SMA),    // Default smoothing method of the fast MA
                             m_period_mean(8),           // Default period of the mean MA is 8
                             m_method_mean(MODE_SMA),    // Default smoothing method of the mean MA
                             m_period_slow(20),          // Default period of the slow MA is 20
                             m_method_slow(MODE_SMA),    // Default smoothing method of the slow MA
                             m_period_adx(8),			   // Default period of the ADX is 8
                             m_level_adx(32.0)
  {
  }
//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
void CTrailingMinPrev::~CTrailingMinPrev(void)
  {
  }
//+------------------------------------------------------------------+
//| Validation settings protected data.                              |
//+------------------------------------------------------------------+
bool CTrailingMinPrev::ValidationSettings(void)
  {
   if(!CExpertTrailing::ValidationSettings())
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
//--- Check ADX period
   if(m_period_adx < 1)
     {
      PrintFormat("Incorrect value set for adx period! ADXPeriod=%d", m_period_adx);
      return false;
     }
//--- All checks are completed, everything is ok
   return true;
  }
//+------------------------------------------------------------------+
//| Checking for input parameters and setting protected data.        |
//+------------------------------------------------------------------+
bool CTrailingMinPrev::InitIndicators(CIndicators *indicators)
  {
//--- check
   if(indicators==NULL)
      return(false);
      
///--- Creating our MA indicators
   if(!CreateFastMA(indicators))                  return(false);
   if(!CreateMeanMA(indicators))                  return(false);
   if(!CreateSlowMA(indicators))                  return(false);
   if(!CreateADX(indicators))                  return(false);
//--- ok
   return(true);
  }
  

//+------------------------------------------------------------------+
//| Creates the "Fast MA" indicator                                  |
//+------------------------------------------------------------------+
bool CTrailingMinPrev::CreateFastMA(CIndicators *indicators)
{
//--- Checking the pointer
   if(indicators==NULL) return(false);
//--- Adding an object to the collection
   if(!indicators.Add(GetPointer(m_fast_ma)))
     {
      printf(__FUNCTION__+": Error adding an object of the fast MA");
      return(false);
     }
     
     if(!m_fast_ma.Create(m_symbol.Name(),m_period,m_period_fast,m_ma_shift,m_method_fast,m_ma_applied))
     {
      printf(__FUNCTION__+": error initializing fast_MA object");
      return(false);
     }
  
   return(true);
}



//+------------------------------------------------------------------+
//| Creates the "Mean MA" indicator                                  |
//+------------------------------------------------------------------+
bool CTrailingMinPrev::CreateMeanMA(CIndicators *indicators)
{
//--- Checking the pointer
   if(indicators==NULL) return(false);
//--- Adding an object to the collection
   if(!indicators.Add(GetPointer(m_mean_ma)))
     {
      printf(__FUNCTION__+": Error adding an object of the mean MA");
      return(false);
     }
     
     if(!m_mean_ma.Create(m_symbol.Name(),m_period,m_period_mean,m_ma_shift,m_method_mean,m_ma_applied))
     {
      printf(__FUNCTION__+": error initializing mean_MA object");
      return(false);
     }
//--- Reached this part, so the function was successful, return true
   return(true);
}


//+------------------------------------------------------------------+
//| Creates the "Slow MA" indicator                                  |
//+------------------------------------------------------------------+
bool CTrailingMinPrev::CreateSlowMA(CIndicators *indicators)
{
//--- Checking the pointer
   if(indicators==NULL) return(false);
//--- Adding an object to the collection
   if(!indicators.Add(GetPointer(m_slow_ma)))
     {
      printf(__FUNCTION__+": Error adding an object of the slow MA");
      return(false);
     }
     
   if(!m_slow_ma.Create(m_symbol.Name(),m_period,m_period_slow,m_ma_shift,m_method_slow,m_ma_applied))
     {
      printf(__FUNCTION__+": error initializing slow_MA object");
      return(false);
     }

//--- Reached this part, so the function was successful, return true
   return(true);
}


//+------------------------------------------------------------------+
//| Creates the ADX indicator                                  |
//+------------------------------------------------------------------+
bool CTrailingMinPrev::CreateADX(CIndicators *indicators)
{
//--- Checking the pointer
   if(indicators==NULL) return(false);
//--- Adding an object to the collection
   if(!indicators.Add(GetPointer(m_adx)))
     {
      printf(__FUNCTION__+": Error adding an object of the ADX");
      return(false);
     }
     
   if(!m_adx.Create(m_symbol.Name(),m_period,m_period_adx))
     {
      printf(__FUNCTION__+": error initializing ADX object");
      return(false);
     }

//--- Reached this part, so the function was successful, return true
   return(true);
}
  
//+------------------------------------------------------------------+
//| Checking trailing stop and/or profit for long position.          |
//+------------------------------------------------------------------+
bool CTrailingMinPrev::CheckTrailingStopLong(CPositionInfo *position,double &sl,double &tp)
{
   if(position==NULL)
      return(false);

   double price =m_symbol.Ask();

   sl = FastMA(2);

   tp=EMPTY_VALUE;
   
   return(sl!=EMPTY_VALUE);
   
}
//+------------------------------------------------------------------+
//| Checking trailing stop and/or profit for short position.         |
//+------------------------------------------------------------------+
bool CTrailingMinPrev::CheckTrailingStopShort(CPositionInfo *position,double &sl,double &tp)
{
   
   if(position==NULL)
      return(false);

   double price =m_symbol.Ask();

   sl = FastMA(2);

   tp=EMPTY_VALUE;
   
   
   return(sl!=EMPTY_VALUE);
}
//+------------------------------------------------------------------+


