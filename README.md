# antiBTCv5 - MetaTrader 5 Expert Advisor

## Overview
antiBTCv5 is a fully automated trading system designed specifically for the BTCUSDm pair in MetaTrader 5. The EA utilizes Exponential Moving Average (EMA) and Relative Strength Index (RSI) indicators to identify optimal entry points while implementing advanced risk management and martingale recovery strategies.

## Features

### 🎯 **Trading Strategy**
- **EMA Crossover System**: Uses Fast EMA (9) and Slow EMA (21) for trend identification
- **RSI Filter**: RSI (14) with overbought (70) and oversold (30) levels for momentum confirmation
- **ATR Volatility Filter**: Only trades during high volatility periods (ATR > 1.0)
- **Market Noise Handling**: Filters out excessive price fluctuations

### 📊 **Technical Indicators**
- **Fast EMA**: Period 9, Close price
- **Slow EMA**: Period 21, Close price  
- **RSI**: Period 14, Overbought 70, Oversold 30
- **ATR**: Period 14 for volatility measurement

### 🛡️ **Risk Management**
- **Take Profit**: 20 pips
- **Stop Loss**: 50 pips
- **Initial Lot Size**: 0.1 lots
- **Maximum Lot Size**: 1.0 lots
- **Martingale Recovery**: Doubles lot size after each loss
- **Maximum Martingale Steps**: 5 consecutive losses
- **Recovery Mode**: 24-hour pause after max steps reached

### ⏰ **Trading Schedule**
- **Timeframe**: M15 (15-minute chart)
- **Trading Hours**: 24/7 (configurable)
- **New Bar Processing**: Only processes signals on new candle formation

## Installation

### Step 1: Copy Files
1. Copy `antiBTCv5.mq5` to your MetaTrader 5 `Experts` folder:
   ```
   C:\Users\[YourUsername]\AppData\Roaming\MetaQuotes\Terminal\[TerminalID]\MQL5\Experts\
   ```

### Step 2: Compile
1. Open MetaTrader 5
2. Press `Ctrl+N` to open Navigator
3. Right-click on `antiBTCv5` in the Expert Advisors section
4. Select "Modify" to open MetaEditor
5. Press `F7` to compile the EA

### Step 3: Attach to Chart
1. Open a BTCUSDm chart with M15 timeframe
2. Drag `antiBTCv5` from Navigator to the chart
3. Configure parameters in the popup window
4. Enable "Allow live trading" and "Allow DLL imports"
5. Click "OK"

## Configuration Parameters

### Technical Indicators
| Parameter | Default | Description |
|-----------|---------|-------------|
| `FastEMA_Period` | 9 | Fast EMA period |
| `SlowEMA_Period` | 21 | Slow EMA period |
| `RSI_Period` | 14 | RSI period |
| `RSI_Overbought` | 70.0 | RSI overbought level |
| `RSI_Oversold` | 30.0 | RSI oversold level |

### Risk Management
| Parameter | Default | Description |
|-----------|---------|-------------|
| `InitialLotSize` | 0.1 | Starting lot size |
| `MaxLotSize` | 1.0 | Maximum allowed lot size |
| `TakeProfit` | 20 | Take profit in pips |
| `StopLoss` | 50 | Stop loss in pips |
| `MaxMartingaleSteps` | 5 | Maximum consecutive losses before recovery |
| `RecoveryHours` | 24 | Hours to wait in recovery mode |

### Market Conditions
| Parameter | Default | Description |
|-----------|---------|-------------|
| `ATR_Threshold` | 1.0 | Minimum ATR for trading |
| `ATR_Multiplier` | 1.5 | ATR multiplier for noise filter |
| `ATR_Period` | 14 | ATR calculation period |

### Trading Schedule
| Parameter | Default | Description |
|-----------|---------|-------------|
| `EnableTrading` | true | Enable/disable trading |
| `TradingStartTime` | "00:00" | Trading start time (HH:MM) |
| `TradingEndTime` | "23:59" | Trading end time (HH:MM) |

## Trading Logic

### Buy Signal Conditions
1. Fast EMA (9) crosses above Slow EMA (21)
2. RSI (14) < 70 (not overbought)
3. ATR > 1.0 (sufficient volatility)
4. No excessive market noise
5. No existing position open

### Sell Signal Conditions
1. Fast EMA (9) crosses below Slow EMA (21)
2. RSI (14) > 30 (not oversold)
3. ATR > 1.0 (sufficient volatility)
4. No excessive market noise
5. No existing position open

### Martingale Recovery System
- After each loss, lot size is doubled
- Maximum 5 consecutive losses allowed
- After 5 losses, EA enters 24-hour recovery mode
- Recovery mode resets lot size to initial value
- After recovery period, normal trading resumes

## Visual Interface

The EA displays a real-time information panel on the chart showing:
- **Status**: Active/Disabled/Recovery Mode
- **Position**: Open/None
- **Profit**: Current profit/loss in USD
- **Losses**: Consecutive loss count

## Performance Monitoring

### Logging
- All trades are logged with timestamps
- Entry/exit prices, profit/loss amounts
- Market conditions (ATR, RSI values)
- Martingale progression

### Performance Targets
- **Win Rate**: Target > 60%
- **Maximum Drawdown**: Target < 15%
- **Risk/Reward Ratio**: 1:2.5 (50 pips SL, 20 pips TP)

## Safety Features

### Error Handling
- Robust error handling for all trading operations
- Indicator handle validation
- Memory management for indicator buffers
- Graceful handling of market data errors

### Market Protection
- ATR-based volatility filtering
- Market noise detection
- Trading hours restriction
- Position size limits

## Backtesting

The EA is fully compatible with MetaTrader 5's Strategy Tester:
1. Open Strategy Tester (Ctrl+R)
2. Select `antiBTCv5` as the Expert Advisor
3. Choose BTCUSDm symbol
4. Set timeframe to M15
5. Configure date range
6. Run optimization or single test

## Optimization Tips

### Parameter Optimization
- Use Strategy Tester's genetic algorithm
- Focus on EMA periods (7-15 for Fast, 18-25 for Slow)
- Test RSI levels (25-35 for oversold, 65-75 for overbought)
- Optimize ATR threshold based on market conditions

### Risk Management
- Start with small lot sizes in live trading
- Monitor martingale progression carefully
- Consider reducing max martingale steps for conservative approach
- Adjust recovery hours based on market volatility

## Troubleshooting

### Common Issues

**EA not opening trades:**
- Check if trading is enabled
- Verify market conditions (ATR, volatility)
- Ensure no existing positions
- Check trading hours settings

**Compilation errors:**
- Ensure MetaTrader 5 is updated to latest version
- Check for syntax errors in code
- Verify all required functions are available

**Performance issues:**
- Reduce indicator periods for faster processing
- Limit chart objects if using multiple EAs
- Monitor memory usage

## Support

For technical support and updates:
- **Website**: https://www.mql5.com
- **Author**: PT. SENIMAN CODING INDONESIA
- **Version**: 5.00

## Disclaimer

This Expert Advisor is for educational and informational purposes only. Past performance does not guarantee future results. Trading involves substantial risk of loss and is not suitable for all investors. Always test thoroughly in a demo account before using with real money.

## License

Copyright 2024, PT. SENIMAN CODING INDONESIA
All rights reserved.
