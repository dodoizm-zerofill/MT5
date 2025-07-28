//+------------------------------------------------------------------+
//|                                                    antiBTCv5.mq5 |
//|                                  Copyright 2024, PT. SENIMAN CODING INDONESIA |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, PT. SENIMAN CODING INDONESIA"
#property link      "https://www.mql5.com"
#property version   "5.00"
#property description "Fully automated trading system for BTCUSD using EMA and RSI indicators"

//--- Input Parameters
input group "=== Technical Indicators ==="
input int                  FastEMA_Period = 9;           // Fast EMA Period
input int                  SlowEMA_Period = 21;          // Slow EMA Period
input int                  RSI_Period = 14;              // RSI Period
input double               RSI_Overbought = 70.0;        // RSI Overbought Level
input double               RSI_Oversold = 30.0;          // RSI Oversold Level

input group "=== Risk Management ==="
input double               InitialLotSize = 0.1;         // Initial Lot Size
input double               MaxLotSize = 1.0;             // Maximum Lot Size
input int                  TakeProfit = 20;              // Take Profit (pips)
input int                  StopLoss = 50;                // Stop Loss (pips)
input int                  MaxMartingaleSteps = 5;       // Maximum Martingale Steps
input int                  RecoveryHours = 24;           // Recovery Hours After Max Steps

input group "=== Market Conditions ==="
input double               ATR_Threshold = 1.0;          // ATR Threshold for High Volatility
input double               ATR_Multiplier = 1.5;         // ATR Multiplier for Noise Filter
input int                  ATR_Period = 14;              // ATR Period

input group "=== Trading Schedule ==="
input bool                 EnableTrading = true;         // Enable Trading
input string               TradingStartTime = "00:00";   // Trading Start Time
input string               TradingEndTime = "23:59";     // Trading End Time

//--- Global Variables
int                        FastEMA_Handle;
int                        SlowEMA_Handle;
int                        RSI_Handle;
int                        ATR_Handle;
double                     FastEMA_Buffer[];
double                     SlowEMA_Buffer[];
double                     RSI_Buffer[];
double                     ATR_Buffer[];

bool                       IsNewBar = false;
datetime                   LastBarTime = 0;
int                        ConsecutiveLosses = 0;
datetime                   LastRecoveryTime = 0;
double                     CurrentLotSize = InitialLotSize;
bool                       IsRecoveryMode = false;

//--- Trade Management
ulong                      LastTicket = 0;
bool                       IsPositionOpen = false;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   // Initialize indicator handles
   FastEMA_Handle = iMA(_Symbol, PERIOD_M15, FastEMA_Period, 0, MODE_EMA, PRICE_CLOSE);
   SlowEMA_Handle = iMA(_Symbol, PERIOD_M15, SlowEMA_Period, 0, MODE_EMA, PRICE_CLOSE);
   RSI_Handle = iRSI(_Symbol, PERIOD_M15, RSI_Period, PRICE_CLOSE);
   ATR_Handle = iATR(_Symbol, PERIOD_M15, ATR_Period);
   
   // Check if handles are valid
   if(FastEMA_Handle == INVALID_HANDLE || SlowEMA_Handle == INVALID_HANDLE || 
      RSI_Handle == INVALID_HANDLE || ATR_Handle == INVALID_HANDLE)
   {
      Print("Error: Failed to create indicator handles");
      return(INIT_FAILED);
   }
   
   // Initialize arrays
   ArraySetAsSeries(FastEMA_Buffer, true);
   ArraySetAsSeries(SlowEMA_Buffer, true);
   ArraySetAsSeries(RSI_Buffer, true);
   ArraySetAsSeries(ATR_Buffer, true);
   
   // Set initial lot size
   CurrentLotSize = InitialLotSize;
   
   // Display EA information on chart
   CreateInfoPanel();
   
   Print("antiBTCv5 EA initialized successfully");
   Print("Symbol: ", _Symbol);
   Print("Initial Lot Size: ", InitialLotSize);
   Print("Take Profit: ", TakeProfit, " pips");
   Print("Stop Loss: ", StopLoss, " pips");
   
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   // Release indicator handles
   if(FastEMA_Handle != INVALID_HANDLE) IndicatorRelease(FastEMA_Handle);
   if(SlowEMA_Handle != INVALID_HANDLE) IndicatorRelease(SlowEMA_Handle);
   if(RSI_Handle != INVALID_HANDLE) IndicatorRelease(RSI_Handle);
   if(ATR_Handle != INVALID_HANDLE) IndicatorRelease(ATR_Handle);
   
   // Remove chart objects
   ObjectDelete(0, "EA_Info_Panel");
   ObjectDelete(0, "EA_Status");
   ObjectDelete(0, "EA_Position");
   ObjectDelete(0, "EA_Profit");
   ObjectDelete(0, "EA_Losses");
   
   Print("antiBTCv5 EA deinitialized");
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   // Check if trading is enabled
   if(!EnableTrading) return;
   
   // Check recovery mode
   if(IsRecoveryMode)
   {
      if(TimeCurrent() - LastRecoveryTime >= RecoveryHours * 3600)
      {
         IsRecoveryMode = false;
         ConsecutiveLosses = 0;
         CurrentLotSize = InitialLotSize;
         Print("Recovery period ended. Resuming normal trading.");
      }
      else
      {
         return; // Skip trading during recovery
      }
   }
   
   // Check if it's a new bar
   if(!IsNewBar())
   {
      UpdateInfoPanel();
      return;
   }
   
   // Check trading hours
   if(!IsWithinTradingHours()) return;
   
   // Update indicator data
   if(!UpdateIndicators()) return;
   
   // Check for open positions
   CheckExistingPositions();
   
   // Check market conditions
   if(!CheckMarketConditions()) return;
   
   // Check trading signals
   CheckTradingSignals();
   
   // Update information panel
   UpdateInfoPanel();
}

//+------------------------------------------------------------------+
//| Check if it's a new bar                                          |
//+------------------------------------------------------------------+
bool IsNewBar()
{
   datetime currentBarTime = iTime(_Symbol, PERIOD_M15, 0);
   if(currentBarTime != LastBarTime)
   {
      LastBarTime = currentBarTime;
      return true;
   }
   return false;
}

//+------------------------------------------------------------------+
//| Update indicator data                                            |
//+------------------------------------------------------------------+
bool UpdateIndicators()
{
   // Copy indicator data
   if(CopyBuffer(FastEMA_Handle, 0, 0, 3, FastEMA_Buffer) < 3) return false;
   if(CopyBuffer(SlowEMA_Handle, 0, 0, 3, SlowEMA_Buffer) < 3) return false;
   if(CopyBuffer(RSI_Handle, 0, 0, 3, RSI_Buffer) < 3) return false;
   if(CopyBuffer(ATR_Handle, 0, 0, 3, ATR_Buffer) < 3) return false;
   
   return true;
}

//+------------------------------------------------------------------+
//| Check market conditions                                          |
//+------------------------------------------------------------------+
bool CheckMarketConditions()
{
   // Check ATR for volatility
   double currentATR = ATR_Buffer[0];
   if(currentATR < ATR_Threshold)
   {
      return false; // Low volatility, skip trading
   }
   
   // Check for excessive noise
   double priceChange = MathAbs(iClose(_Symbol, PERIOD_M15, 0) - iClose(_Symbol, PERIOD_M15, 1));
   if(priceChange > currentATR * ATR_Multiplier)
   {
      return false; // Excessive noise detected
   }
   
   return true;
}

//+------------------------------------------------------------------+
//| Check trading signals                                            |
//+------------------------------------------------------------------+
void CheckTradingSignals()
{
   // Don't open new positions if one is already open
   if(IsPositionOpen) return;
   
   double fastEMA_Current = FastEMA_Buffer[0];
   double fastEMA_Previous = FastEMA_Buffer[1];
   double slowEMA_Current = SlowEMA_Buffer[0];
   double slowEMA_Previous = SlowEMA_Buffer[1];
   double rsi_Current = RSI_Buffer[0];
   
   // Check for buy signal
   if(fastEMA_Current > slowEMA_Current && fastEMA_Previous <= slowEMA_Previous && rsi_Current < RSI_Overbought)
   {
      OpenBuyOrder();
   }
   
   // Check for sell signal
   if(fastEMA_Current < slowEMA_Current && fastEMA_Previous >= slowEMA_Previous && rsi_Current > RSI_Oversold)
   {
      OpenSellOrder();
   }
}

//+------------------------------------------------------------------+
//| Open buy order                                                   |
//+------------------------------------------------------------------+
void OpenBuyOrder()
{
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double sl = ask - StopLoss * _Point;
   double tp = ask + TakeProfit * _Point;
   
   MqlTradeRequest request = {};
   MqlTradeResult result = {};
   
   request.action = TRADE_ACTION_DEAL;
   request.symbol = _Symbol;
   request.volume = CurrentLotSize;
   request.type = ORDER_TYPE_BUY;
   request.price = ask;
   request.sl = sl;
   request.tp = tp;
   request.deviation = 10;
   request.magic = 123456;
   request.comment = "antiBTCv5 Buy";
   
   if(OrderSend(request, result))
   {
      if(result.retcode == TRADE_RETCODE_DONE)
      {
         LastTicket = result.order;
         IsPositionOpen = true;
         Print("Buy order opened successfully. Ticket: ", LastTicket, " Lot: ", CurrentLotSize);
         LogTrade("BUY", ask, sl, tp, CurrentLotSize);
      }
      else
      {
         Print("Error opening buy order: ", result.retcode);
      }
   }
}

//+------------------------------------------------------------------+
//| Open sell order                                                  |
//+------------------------------------------------------------------+
void OpenSellOrder()
{
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double sl = bid + StopLoss * _Point;
   double tp = bid - TakeProfit * _Point;
   
   MqlTradeRequest request = {};
   MqlTradeResult result = {};
   
   request.action = TRADE_ACTION_DEAL;
   request.symbol = _Symbol;
   request.volume = CurrentLotSize;
   request.type = ORDER_TYPE_SELL;
   request.price = bid;
   request.sl = sl;
   request.tp = tp;
   request.deviation = 10;
   request.magic = 123456;
   request.comment = "antiBTCv5 Sell";
   
   if(OrderSend(request, result))
   {
      if(result.retcode == TRADE_RETCODE_DONE)
      {
         LastTicket = result.order;
         IsPositionOpen = true;
         Print("Sell order opened successfully. Ticket: ", LastTicket, " Lot: ", CurrentLotSize);
         LogTrade("SELL", bid, sl, tp, CurrentLotSize);
      }
      else
      {
         Print("Error opening sell order: ", result.retcode);
      }
   }
}

//+------------------------------------------------------------------+
//| Check existing positions                                         |
//+------------------------------------------------------------------+
void CheckExistingPositions()
{
   bool hasPosition = false;
   
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(PositionSelectByTicket(PositionGetTicket(i)))
      {
         if(PositionGetString(POSITION_SYMBOL) == _Symbol && PositionGetInteger(POSITION_MAGIC) == 123456)
         {
            hasPosition = true;
            break;
         }
      }
   }
   
   IsPositionOpen = hasPosition;
   
   // Check for closed positions to update martingale
   if(!hasPosition && LastTicket != 0)
   {
      // Check if the last position was closed
      if(!PositionSelectByTicket(LastTicket))
      {
         // Position was closed, check if it was a loss
         CheckPositionResult();
         LastTicket = 0;
      }
   }
}

//+------------------------------------------------------------------+
//| Check position result and update martingale                      |
//+------------------------------------------------------------------+
void CheckPositionResult()
{
   // Get the last closed position
   HistorySelect(0, TimeCurrent());
   
   for(int i = HistoryDealsTotal() - 1; i >= 0; i--)
   {
      ulong dealTicket = HistoryDealGetTicket(i);
      if(HistoryDealGetInteger(dealTicket, DEAL_MAGIC) == 123456)
      {
         double profit = HistoryDealGetDouble(dealTicket, DEAL_PROFIT);
         
         if(profit < 0) // Loss
         {
            ConsecutiveLosses++;
            Print("Position closed with loss. Consecutive losses: ", ConsecutiveLosses);
            
            if(ConsecutiveLosses >= MaxMartingaleSteps)
            {
               // Enter recovery mode
               IsRecoveryMode = true;
               LastRecoveryTime = TimeCurrent();
               CurrentLotSize = InitialLotSize;
               Print("Maximum martingale steps reached. Entering recovery mode for ", RecoveryHours, " hours.");
            }
            else
            {
               // Double the lot size for next trade
               CurrentLotSize = MathMin(CurrentLotSize * 2, MaxLotSize);
               Print("Doubling lot size to: ", CurrentLotSize);
            }
         }
         else // Profit
         {
            ConsecutiveLosses = 0;
            CurrentLotSize = InitialLotSize;
            Print("Position closed with profit. Resetting to initial lot size: ", CurrentLotSize);
         }
         
         break;
      }
   }
}

//+------------------------------------------------------------------+
//| Check if current time is within trading hours                    |
//+------------------------------------------------------------------+
bool IsWithinTradingHours()
{
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);
   
   string currentTime = StringFormat("%02d:%02d", dt.hour, dt.min);
   
   return (currentTime >= TradingStartTime && currentTime <= TradingEndTime);
}

//+------------------------------------------------------------------+
//| Create information panel on chart                                |
//+------------------------------------------------------------------+
void CreateInfoPanel()
{
   // Create main panel
   ObjectCreate(0, "EA_Info_Panel", OBJ_RECTANGLE_LABEL, 0, 0, 0);
   ObjectSetInteger(0, "EA_Info_Panel", OBJPROP_XDISTANCE, 20);
   ObjectSetInteger(0, "EA_Info_Panel", OBJPROP_YDISTANCE, 20);
   ObjectSetInteger(0, "EA_Info_Panel", OBJPROP_XSIZE, 200);
   ObjectSetInteger(0, "EA_Info_Panel", OBJPROP_YSIZE, 120);
   ObjectSetInteger(0, "EA_Info_Panel", OBJPROP_BGCOLOR, clrDarkBlue);
   ObjectSetInteger(0, "EA_Info_Panel", OBJPROP_BORDER_TYPE, BORDER_FLAT);
   ObjectSetInteger(0, "EA_Info_Panel", OBJPROP_CORNER, CORNER_LEFT_UPPER);
   
   // Create status label
   ObjectCreate(0, "EA_Status", OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(0, "EA_Status", OBJPROP_XDISTANCE, 30);
   ObjectSetInteger(0, "EA_Status", OBJPROP_YDISTANCE, 35);
   ObjectSetString(0, "EA_Status", OBJPROP_TEXT, "Status: Active");
   ObjectSetInteger(0, "EA_Status", OBJPROP_COLOR, clrWhite);
   ObjectSetInteger(0, "EA_Status", OBJPROP_FONTSIZE, 9);
   
   // Create position label
   ObjectCreate(0, "EA_Position", OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(0, "EA_Position", OBJPROP_XDISTANCE, 30);
   ObjectSetInteger(0, "EA_Position", OBJPROP_YDISTANCE, 55);
   ObjectSetString(0, "EA_Position", OBJPROP_TEXT, "Position: None");
   ObjectSetInteger(0, "EA_Position", OBJPROP_COLOR, clrWhite);
   ObjectSetInteger(0, "EA_Position", OBJPROP_FONTSIZE, 9);
   
   // Create profit label
   ObjectCreate(0, "EA_Profit", OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(0, "EA_Profit", OBJPROP_XDISTANCE, 30);
   ObjectSetInteger(0, "EA_Profit", OBJPROP_YDISTANCE, 75);
   ObjectSetString(0, "EA_Profit", OBJPROP_TEXT, "Profit: $0.00");
   ObjectSetInteger(0, "EA_Profit", OBJPROP_COLOR, clrWhite);
   ObjectSetInteger(0, "EA_Profit", OBJPROP_FONTSIZE, 9);
   
   // Create losses label
   ObjectCreate(0, "EA_Losses", OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(0, "EA_Losses", OBJPROP_XDISTANCE, 30);
   ObjectSetInteger(0, "EA_Losses", OBJPROP_YDISTANCE, 95);
   ObjectSetString(0, "EA_Losses", OBJPROP_TEXT, "Losses: 0");
   ObjectSetInteger(0, "EA_Losses", OBJPROP_COLOR, clrWhite);
   ObjectSetInteger(0, "EA_Losses", OBJPROP_FONTSIZE, 9);
}

//+------------------------------------------------------------------+
//| Update information panel                                         |
//+------------------------------------------------------------------+
void UpdateInfoPanel()
{
   // Update status
   string status = EnableTrading ? "Active" : "Disabled";
   if(IsRecoveryMode) status = "Recovery Mode";
   ObjectSetString(0, "EA_Status", OBJPROP_TEXT, "Status: " + status);
   
   // Update position
   string position = IsPositionOpen ? "Open" : "None";
   ObjectSetString(0, "EA_Position", OBJPROP_TEXT, "Position: " + position);
   
   // Update profit
   double totalProfit = 0;
   for(int i = 0; i < PositionsTotal(); i++)
   {
      if(PositionSelectByTicket(PositionGetTicket(i)))
      {
         if(PositionGetString(POSITION_SYMBOL) == _Symbol && PositionGetInteger(POSITION_MAGIC) == 123456)
         {
            totalProfit += PositionGetDouble(POSITION_PROFIT);
         }
      }
   }
   ObjectSetString(0, "EA_Profit", OBJPROP_TEXT, "Profit: $" + DoubleToString(totalProfit, 2));
   
   // Update consecutive losses
   ObjectSetString(0, "EA_Losses", OBJPROP_TEXT, "Losses: " + IntegerToString(ConsecutiveLosses));
   
   // Update colors based on profit/loss
   if(totalProfit > 0)
      ObjectSetInteger(0, "EA_Profit", OBJPROP_COLOR, clrLime);
   else if(totalProfit < 0)
      ObjectSetInteger(0, "EA_Profit", OBJPROP_COLOR, clrRed);
   else
      ObjectSetInteger(0, "EA_Profit", OBJPROP_COLOR, clrWhite);
}

//+------------------------------------------------------------------+
//| Log trade information                                            |
//+------------------------------------------------------------------+
void LogTrade(string action, double price, double sl, double tp, double lot)
{
   string logMessage = StringFormat("[%s] %s Order - Price: %.2f, SL: %.2f, TP: %.2f, Lot: %.2f, ATR: %.2f, RSI: %.2f",
                                   TimeToString(TimeCurrent()), action, price, sl, tp, lot, ATR_Buffer[0], RSI_Buffer[0]);
   Print(logMessage);
}

//+------------------------------------------------------------------+
//| Custom function to optimize EMA and RSI parameters               |
//+------------------------------------------------------------------+
void OptimizeParameters()
{
   // This function can be called periodically to adjust parameters
   // based on market performance
   
   // Example: Adjust EMA periods based on volatility
   double currentATR = ATR_Buffer[0];
   double avgATR = 0;
   
   for(int i = 0; i < 10; i++)
   {
      avgATR += ATR_Buffer[i];
   }
   avgATR /= 10;
   
   // If volatility is high, use shorter EMA periods
   if(currentATR > avgATR * 1.5)
   {
      // Could dynamically adjust EMA periods here
      // This is a placeholder for optimization logic
   }
}