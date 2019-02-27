//+------------------------------------------------------------------+
//|                                                  SignalDiGui.mqh |
//|                                      Copyright 2009-2019, DiGUI. |
//|                               http://github.com/diegomazala/MQL5 |
//+------------------------------------------------------------------+
#include <Expert\ExpertSignal.mqh>
// wizard description start
//+------------------------------------------------------------------+
//| Description of the class                                         |
//| Title=Signals of indicator 'DiGui' (wip)                         |
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
//| Parameter=Shift,int,0,Time shift                                 |
//| Parameter=Applied,ENUM_APPLIED_PRICE,PRICE_CLOSE,Prices series   |
//| Parameter=ADXPeriod,int,8,Period of ADX                          |
//| Parameter=ADXLevel,double,32,Level of ADX                        |
//| Parameter=EpsilonDD,double,0.001,Max distance between cross lines     |
//| Parameter=OffsetDD,double,0.01,Max distance of cross lines from MeanDD |
//| Parameter=TimeStart,datetime,0,Max distance of cross lines from MeanDD |
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
   double            m_dd_offset;      // Max distance of cross lines from MeanDD
   

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
   
   double            EpsilonDD(const double value)       const { return m_dd_epsilon; }
   double            OffsetDD(const double value)        const { return m_dd_offset; }
   
   double            ADXPlus(const int index)            const { return(m_adx.Plus(index)); }
   double            ADXMinus(const int index)           const { return(m_adx.Minus(index));}
   double            ADXMain(const int index)            const { return(m_adx.Main(index)); }

   bool              HasPositionBuy();
   bool              HasPositionSell();
   
   

protected:
   //--- Creating MA indicators
   bool              CreateFastMA(CIndicators *indicators);
   bool              CreateMeanMA(CIndicators *indicators);
   bool              CreateSlowMA(CIndicators *indicators);
   //--- Creating ADX indicators
   bool              CreateADX(CIndicators *indicators);
   
   int               CheckAgulhadaBuy(int idx) const;
   int               CheckAgulhadaSell(int idx) const;
   
   bool              CanBuy(int idx) const;
   bool              CanSell(int idx) const;
   
   bool              IsInTimeRangeAllowed() const;
      
   
   bool CheckDDCrossFastMeanBuy(int idx) const
   {
      return AreGEquals(FastDD(idx), MeanDD(idx)) && AreLEquals(FastDD(idx), MeanDD(idx));
   }
   
   
   bool CheckDDCrossFastMeanSell(int idx) const
   {
      return AreLEquals(FastDD(idx), MeanDD(idx)) && AreGEquals(FastDD(idx), MeanDD(idx));
   }
   
   
   bool CheckDDCrossFastSlowBuy(int idx) const
   {
      return AreGEquals(FastDD(idx), SlowDD(idx)) && AreLEquals(FastDD(idx), SlowDD(idx));
   }
   
   
   bool CheckDDCrossFastSlowSell(int idx) const
   {
      return AreLEquals(FastDD(idx), SlowDD(idx)) && AreGEquals(FastDD(idx), SlowDD(idx));
   }
   
   bool CheckMACrossFastMeanBuy(int idx) const
   {
      return AreGEquals(FastMA(idx), MeanMA(idx)) && AreLEquals(FastMA(idx), MeanMA(idx));
   }
   
   
   bool CheckMACrossFastMeanSell(int idx) const
   {
      return AreLEquals(FastMA(idx), MeanMA(idx)) && AreGEquals(FastMA(idx), MeanMA(idx));
   }
   
   
   bool CheckMACrossFastSlowBuy(int idx) const
   {
      return AreGEquals(FastMA(idx), SlowMA(idx)) && AreLEquals(FastMA(idx), SlowMA(idx));
   }
   
   
   bool CheckMACrossFastSlowSell(int idx) const
   {
      return AreLEquals(FastMA(idx), SlowMA(idx)) && AreGEquals(FastMA(idx), SlowMA(idx));
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
CSignalDiGui::CSignalDiGui(void) : 
                             m_period_fast(3),           // Default period of the fast MA is 3
                             m_method_fast(MODE_SMA),    // Default smoothing method of the fast MA
                             m_period_mean(8),           // Default period of the mean MA is 8
                             m_method_mean(MODE_SMA),    // Default smoothing method of the mean MA
                             m_period_slow(20),          // Default period of the slow MA is 20
                             m_method_slow(MODE_SMA),    // Default smoothing method of the slow MA
                             m_period_adx(8),			   // Default period of the ADX is 8
                             m_level_adx(32.0)
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
   if(!CreateADX(indicators))                  return(false);
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
bool CSignalDiGui::CreateADX(CIndicators *indicators)
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


void GetPositionProperties()
{
//--- variables for returning values from position properties

   double   open_price;
   double   initial_volume;
   long     positionID;
   double   position_profit;

   ENUM_POSITION_TYPE      type;

//--- number of current positions

   uint     total=PositionsTotal();
//--- go through orders in a loop
   for(uint i=0;i<total;i++)
   {
      //--- return order ticket by its position in the list
          {
         //--- return order properties
         open_price    =PositionGetDouble(POSITION_PRICE_OPEN);
         positionID    =PositionGetInteger(POSITION_IDENTIFIER);
         initial_volume=PositionGetDouble(POSITION_VOLUME);
         position_profit=PositionGetDouble(POSITION_PROFIT);
         
         type          =(ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
         Alert(EnumToString(type));  
        }
   }
}


//+------------------------------------------------------------------+
//| Verifica se há COMPRA aberta                                     |
//+------------------------------------------------------------------+

bool CSignalDiGui::HasPositionBuy() 
{
   for (int i = 0; i < PositionsTotal(); ++i)
   {
      if(PositionSelect(m_symbol.Name()) == true &&
         PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY)
            return true;        
   }
   return false;
}


//+------------------------------------------------------------------+
//| Verifica se há VENDA aberta                                      |
//+------------------------------------------------------------------+
bool CSignalDiGui::HasPositionSell() 
{
   for (int i = 0; i < PositionsTotal(); ++i)
   {
      if(PositionSelect(m_symbol.Name()) == true &&
         PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL)
            return true;        
   }
   return false;
}



//+------------------------------------------------------------------+
//| Calculando se há sinal de COMPRA                                 |
//+------------------------------------------------------------------+
int CSignalDiGui::LongCondition(void)
{
   ////////////////////// NÃO COMPRA /////////////////////////////////
   //
   // Se existe posição comprada, NÂO COMPRA MAIS NADA
   // 
   if (HasPositionBuy())
      return 0;
   //
   ///////////////////////////////////////////////////////////////////


   ///////////////////////////////////////////////////////////////////
   //
   // Verifica o horário permitido de operação
   // 
   if (!IsInTimeRangeAllowed())
      return 0;
   // 
   ///////////////////////////////////////////////////////////////////

   
   //--- For operation with ticks idx=0, for operation with formed bars idx=1
   int idx=StartIndex();
   int signal=0;


   ///////////////////////////////////////////////////////////////////
   //
   // Verifica se os indicadores não permitem venda
   // 
   //if(!CanBuy(idx))
   //   return 0;
   // 
   ///////////////////////////////////////////////////////////////////
   
   
   
   ///////////////////////////////////////////////////////////////////
   // Existe AGULHADA?
   // 
   signal += CheckAgulhadaBuy(idx);
   //
   ///////////////////////////////////////////////////////////////////


/*
   ///////////////////////////////////////////////////////////////////
   // Tratando Média Móvel Rápida
   // 
   // FastDidi cruzou Mean pra baixo, +10
   signal += CheckDDCrossFastMeanBuy(idx) ? 10 : 0;
   signal += CheckDDCrossFastMeanBuy(idx + 1) ? 10 : 0;
   // 
   // FastDidi cruzou pra Slow baixo, +10
   signal += CheckDDCrossFastSlowBuy(idx) ? 10 : 0;
   signal += CheckDDCrossFastSlowBuy(idx + 1) ? 10 : 0;
   //
   // FastDidi acima da MeanDidi e apotando pra cima
   signal += (FastDD(idx) > MeanDD(idx) && FastDD(idx) > FastDD(idx + 1)) ? 10 : 0;
   ///////////////////////////////////////////////////////////////////      
    

   ///////////////////////////////////////////////////////////////////
   // Tratando o ADX
   // 
   // ADX apontando pra cima, +10
   signal += (ADXMain(idx) > ADXMain(idx + 1)) ? 10 : 0;
   //
   // ADX acima do nível, +10
   signal += (ADXMain(idx) > m_level_adx) ? 10 : 0;
   //
   // Se DI+ está acima do DI-, adiciona 10
   signal += (ADXPlus(idx) > ADXMinus(idx)) ? 20 : 0;
   ///////////////////////////////////////////////////////////////////
*/
   //     
   // Retorna a força do sinal entre 0 e 100 
   return MathMax(0, MathMin(100, signal));
}


//+------------------------------------------------------------------+
//| Calculando se há sinal de VENDA                                  |
//+------------------------------------------------------------------+
int CSignalDiGui::ShortCondition(void)
{
   ///////////////////////////////////////////////////////////////////
   //
   // Se existe posição vendida, NÂO VENDE MAIS NADA
   // 
   if (HasPositionSell())
      return 0;
   // 
   ///////////////////////////////////////////////////////////////////



   ///////////////////////////////////////////////////////////////////
   //
   // Verifica o horário permitido de operação
   // 
   if (!IsInTimeRangeAllowed())
      return 0;
   // 
   ///////////////////////////////////////////////////////////////////
   
  
   //--- For operation with ticks idx=0, for operation with formed bars idx=1
   int idx=StartIndex();
   int signal=0;


   ///////////////////////////////////////////////////////////////////
   //
   // Verifica se os indicadores não permitem venda
   // 
   //if(!CanSell(idx))
   //   return 0;
   // 
   ///////////////////////////////////////////////////////////////////

   ///////////////////////////////////////////////////////////////////
   // Existe AGULHADA?
   // 
   signal += CheckAgulhadaSell(idx);
   //
   ///////////////////////////////////////////////////////////////////


/*
   ///////////////////////////////////////////////////////////////////
   // Tratando Média Móvel Rápida
   // 
   // FastDidi cruzou Mean pra baixo, +10
   signal += CheckDDCrossFastMeanSell(idx) ? 10 : 0;
   signal += CheckDDCrossFastMeanSell(idx + 1) ? 10 : 0;
   // 
   // FastDidi cruzou pra Slow baixo, +10
   signal += CheckDDCrossFastSlowSell(idx) ? 10 : 0;
   signal += CheckDDCrossFastSlowSell(idx + 1) ? 10 : 0;
   //
   // FastDidi abaixo da MeanDidi e apotando pra baixo
   signal += (FastDD(idx) < MeanDD(idx) && FastDD(idx) < FastDD(idx + 1)) ? 10 : 0;
   ///////////////////////////////////////////////////////////////////      
    
    
    
   ///////////////////////////////////////////////////////////////////
   // Tratando o ADX
   // 
   // ADX apontando pra cima, +10
   signal += (ADXMain(idx) > ADXMain(idx + 1)) ? 10 : 0;
   //
   // ADX acima do nível, +10
   signal += (ADXMain(idx) > m_level_adx) ? 20 : 0;
   //
   // Se DI- está acima do DI+, adiciona 10
   signal += (ADXMinus(idx) > ADXPlus(idx)) ? 20 : 0;
   ///////////////////////////////////////////////////////////////////
*/
   //     
   // Retorna a força do sinal entre 0 e 100 
   return MathMax(0, MathMin(100, signal));

}

bool CSignalDiGui::CanBuy(int idx) const
{
   // TODO: Verificar horário de operação

   return ADXPlus(idx) > ADXMinus(idx)
      && ADXMain(idx) > m_level_adx
      //&& AreGEquals(ADXMain(idx), ADXMain(idx + 1))
      && AreGEquals(FastDD(idx), MeanDD(idx))
      && MathAbs(FastDD(idx) - MeanDD(idx)) < m_dd_offset;
}

bool CSignalDiGui::CanSell(int idx) const
{
   return ADXMinus(idx) > ADXPlus(idx)
      && ADXMain(idx) > m_level_adx
      //&& AreGEquals(ADXMain(idx), ADXMain(idx + 1))
      && AreLEquals(FastDD(idx), MeanDD(idx))
      && MathAbs(FastDD(idx) - MeanDD(idx)) < m_dd_offset;
}



int CSignalDiGui::CheckAgulhadaBuy(int idx) const
{
   
   if ( 
      FastDD(idx) > MeanDD(idx) && FastDD(idx) > SlowDD(idx) 
      &&
      FastDD(idx + 1) < MeanDD(idx + 1) && FastDD(idx + 1) < SlowDD(idx + 1)
      &&
      SlowDD(idx) < SlowDD(idx + 1)
      )
   {
      return 50;
   }
   
   if ( 
      FastDD(idx) > MeanDD(idx) && FastDD(idx) > SlowDD(idx) 
      &&
      FastDD(idx + 2) < MeanDD(idx + 2) && FastDD(idx + 2) < SlowDD(idx + 2)
      &&
      SlowDD(idx) < SlowDD(idx + 1)
      )
   {
      return 30;
   }
   
   return 0;
}


int CSignalDiGui::CheckAgulhadaSell(int idx) const
{
  
   if ( 
      FastDD(idx) < MeanDD(idx) && FastDD(idx) < SlowDD(idx) 
      &&
      FastDD(idx + 1) > MeanDD(idx + 1) && FastDD(idx + 1) > SlowDD(idx + 1)
      &&
      SlowDD(idx) > SlowDD(idx + 1)
      )
   {
      return 50;
   }
   
   if ( 
      FastDD(idx) < MeanDD(idx) && FastDD(idx) < SlowDD(idx) 
      &&
      FastDD(idx + 2) > MeanDD(idx + 2) && FastDD(idx + 2) > SlowDD(idx + 2)
      &&
      SlowDD(idx) > SlowDD(idx + 1)
      )
   {
      return 30;
   }
   
   return 0;
}


bool CSignalDiGui::IsInTimeRangeAllowed() const
{
   MqlDateTime dt;
   datetime dtSer=TimeCurrent(dt);
   return (dt.hour > 9 && dt.hour < 18);
}
