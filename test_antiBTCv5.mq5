//+------------------------------------------------------------------+
//|                                              test_antiBTCv5.mq5 |
//|                                  Copyright 2024, PT. SENIMAN CODING INDONESIA |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, PT. SENIMAN CODING INDONESIA"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property description "Test script for antiBTCv5 EA validation"

//--- Test Parameters
input int                  TestBars = 100;               // Number of bars to test
input bool                 ShowSignals = true;           // Show signal details

//--- Indicator handles (same as main EA)
int                        FastEMA_Handle;
int                        SlowEMA_Handle;
int                        RSI_Handle;
int                        ATR_Handle;

//--- Buffers
double                     FastEMA_Buffer[];
double                     SlowEMA_Buffer[];
double                     RSI_Buffer[];
double                     ATR_Buffer[];

//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart()
{
   Print("=== antiBTCv5 EA Test Script ===");
   Print("Symbol: ", _Symbol);
   Print("Timeframe: ", EnumToString(Period()));
   Print("Testing ", TestBars, " bars...");
   
   // Initialize indicators
   if(!InitializeIndicators())
   {
      Print("Failed to initialize indicators");
      return;
   }
   
   // Test indicator calculations
   TestIndicatorCalculations();
   
   // Test trading signals
   TestTradingSignals();
   
   // Test market conditions
   TestMarketConditions();
   
   Print("=== Test completed ===");
}

//+------------------------------------------------------------------+
//| Initialize indicators                                            |
//+------------------------------------------------------------------+
bool InitializeIndicators()
{
   // Create indicator handles
   FastEMA_Handle = iMA(_Symbol, PERIOD_M15, 9, 0, MODE_EMA, PRICE_CLOSE);
   SlowEMA_Handle = iMA(_Symbol, PERIOD_M15, 21, 0, MODE_EMA, PRICE_CLOSE);
   RSI_Handle = iRSI(_Symbol, PERIOD_M15, 14, PRICE_CLOSE);
   ATR_Handle = iATR(_Symbol, PERIOD_M15, 14);
   
   // Check handles
   if(FastEMA_Handle == INVALID_HANDLE || SlowEMA_Handle == INVALID_HANDLE || 
      RSI_Handle == INVALID_HANDLE || ATR_Handle == INVALID_HANDLE)
   {
      Print("Error: Invalid indicator handles");
      return false;
   }
   
   // Initialize arrays
   ArraySetAsSeries(FastEMA_Buffer, true);
   ArraySetAsSeries(SlowEMA_Buffer, true);
   ArraySetAsSeries(RSI_Buffer, true);
   ArraySetAsSeries(ATR_Buffer, true);
   
   Print("Indicators initialized successfully");
   return true;
}

//+------------------------------------------------------------------+
//| Test indicator calculations                                      |
//+------------------------------------------------------------------+
void TestIndicatorCalculations()
{
   Print("--- Testing Indicator Calculations ---");
   
   // Copy recent data
   if(CopyBuffer(FastEMA_Handle, 0, 0, 10, FastEMA_Buffer) < 10) return;
   if(CopyBuffer(SlowEMA_Handle, 0, 0, 10, SlowEMA_Buffer) < 10) return;
   if(CopyBuffer(RSI_Handle, 0, 0, 10, RSI_Buffer) < 10) return;
   if(CopyBuffer(ATR_Handle, 0, 0, 10, ATR_Buffer) < 10) return;
   
   // Display current values
   Print("Current Fast EMA (9): ", DoubleToString(FastEMA_Buffer[0], 5));
   Print("Current Slow EMA (21): ", DoubleToString(SlowEMA_Buffer[0], 5));
   Print("Current RSI (14): ", DoubleToString(RSI_Buffer[0], 2));
   Print("Current ATR (14): ", DoubleToString(ATR_Buffer[0], 5));
   
   // Check for valid values
   if(FastEMA_Buffer[0] <= 0 || SlowEMA_Buffer[0] <= 0 || 
      RSI_Buffer[0] < 0 || RSI_Buffer[0] > 100 || ATR_Buffer[0] <= 0)
   {
      Print("Warning: Invalid indicator values detected");
   }
   else
   {
      Print("All indicator values are valid");
   }
}

//+------------------------------------------------------------------+
//| Test trading signals                                             |
//+------------------------------------------------------------------+
void TestTradingSignals()
{
   Print("--- Testing Trading Signals ---");
   
   int buySignals = 0;
   int sellSignals = 0;
   
   for(int i = 1; i < TestBars && i < 1000; i++)
   {
      // Copy data for this bar
      if(CopyBuffer(FastEMA_Handle, 0, i, 2, FastEMA_Buffer) < 2) continue;
      if(CopyBuffer(SlowEMA_Handle, 0, i, 2, SlowEMA_Buffer) < 2) continue;
      if(CopyBuffer(RSI_Handle, 0, i, 1, RSI_Buffer) < 1) continue;
      if(CopyBuffer(ATR_Handle, 0, i, 1, ATR_Buffer) < 1) continue;
      
      double fastEMA_Current = FastEMA_Buffer[0];
      double fastEMA_Previous = FastEMA_Buffer[1];
      double slowEMA_Current = SlowEMA_Buffer[0];
      double slowEMA_Previous = SlowEMA_Buffer[1];
      double rsi_Current = RSI_Buffer[0];
      double atr_Current = ATR_Buffer[0];
      
      // Check buy signal conditions
      bool buySignal = (fastEMA_Current > slowEMA_Current && 
                       fastEMA_Previous <= slowEMA_Previous && 
                       rsi_Current < 70.0 && 
                       atr_Current > 1.0);
      
      // Check sell signal conditions
      bool sellSignal = (fastEMA_Current < slowEMA_Current && 
                        fastEMA_Previous >= slowEMA_Previous && 
                        rsi_Current > 30.0 && 
                        atr_Current > 1.0);
      
      if(buySignal)
      {
         buySignals++;
         if(ShowSignals)
         {
            datetime barTime = iTime(_Symbol, PERIOD_M15, i);
            Print("BUY Signal at ", TimeToString(barTime), 
                  " - Fast EMA: ", DoubleToString(fastEMA_Current, 5),
                  " Slow EMA: ", DoubleToString(slowEMA_Current, 5),
                  " RSI: ", DoubleToString(rsi_Current, 2),
                  " ATR: ", DoubleToString(atr_Current, 5));
         }
      }
      
      if(sellSignal)
      {
         sellSignals++;
         if(ShowSignals)
         {
            datetime barTime = iTime(_Symbol, PERIOD_M15, i);
            Print("SELL Signal at ", TimeToString(barTime), 
                  " - Fast EMA: ", DoubleToString(fastEMA_Current, 5),
                  " Slow EMA: ", DoubleToString(slowEMA_Current, 5),
                  " RSI: ", DoubleToString(rsi_Current, 2),
                  " ATR: ", DoubleToString(atr_Current, 5));
         }
      }
   }
   
   Print("Signal Summary:");
   Print("Buy Signals: ", buySignals);
   Print("Sell Signals: ", sellSignals);
   Print("Total Signals: ", buySignals + sellSignals);
   
   if(TestBars > 0)
   {
      double signalFrequency = (double)(buySignals + sellSignals) / TestBars * 100;
      Print("Signal Frequency: ", DoubleToString(signalFrequency, 2), "%");
   }
}

//+------------------------------------------------------------------+
//| Test market conditions                                           |
//+------------------------------------------------------------------+
void TestMarketConditions()
{
   Print("--- Testing Market Conditions ---");
   
   int highVolatilityBars = 0;
   int lowVolatilityBars = 0;
   int noiseFilteredBars = 0;
   
   for(int i = 0; i < TestBars && i < 1000; i++)
   {
      if(CopyBuffer(ATR_Handle, 0, i, 2, ATR_Buffer) < 2) continue;
      
      double currentATR = ATR_Buffer[0];
      double previousATR = ATR_Buffer[1];
      
      // Check volatility
      if(currentATR > 1.0)
         highVolatilityBars++;
      else
         lowVolatilityBars++;
      
      // Check for excessive noise
      double priceChange = MathAbs(iClose(_Symbol, PERIOD_M15, i) - iClose(_Symbol, PERIOD_M15, i+1));
      if(priceChange > currentATR * 1.5)
         noiseFilteredBars++;
   }
   
   Print("Market Conditions Summary:");
   Print("High Volatility Bars (ATR > 1.0): ", highVolatilityBars);
   Print("Low Volatility Bars (ATR <= 1.0): ", lowVolatilityBars);
   Print("Noise Filtered Bars: ", noiseFilteredBars);
   
   if(TestBars > 0)
   {
      double highVolatilityPercent = (double)highVolatilityBars / TestBars * 100;
      double noiseFilteredPercent = (double)noiseFilteredBars / TestBars * 100;
      
      Print("High Volatility Percentage: ", DoubleToString(highVolatilityPercent, 2), "%");
      Print("Noise Filtered Percentage: ", DoubleToString(noiseFilteredPercent, 2), "%");
   }
}

//+------------------------------------------------------------------+
//| Cleanup function                                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   // Release indicator handles
   if(FastEMA_Handle != INVALID_HANDLE) IndicatorRelease(FastEMA_Handle);
   if(SlowEMA_Handle != INVALID_HANDLE) IndicatorRelease(SlowEMA_Handle);
   if(RSI_Handle != INVALID_HANDLE) IndicatorRelease(RSI_Handle);
   if(ATR_Handle != INVALID_HANDLE) IndicatorRelease(ATR_Handle);
   
   Print("Test script cleanup completed");
}