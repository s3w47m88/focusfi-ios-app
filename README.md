# FocusFi iOS App

A personal finance tracking application for iOS built with SwiftUI and SwiftData.

## Features

### Current Features
- **Income & Expense Tracking**: Add, view, and manage financial transactions
- **Progress Visualization**: Real-time progress bars showing income and expenses against forecasts
- **Date Range Filtering**: View transactions by custom date ranges or quick filters (This Month, Last Month, This Year)
- **Bank Account Management**: Track multiple bank accounts grouped by institution
- **Transaction Organization**: Collapsible income/expense sections with sorting options (by date or amount)
- **Glass Morphism UI**: Modern, polished interface with glass effect design

### Data Models
- **Transaction**: Title, details, amount, date, and type (income/expense)
- **BankAccount**: Bank name, account name, and balance
- **SwiftData Persistence**: Local data storage using Apple's SwiftData framework

## Architecture

- **SwiftUI**: Declarative UI framework
- **SwiftData**: Local persistence layer
- **MVVM Pattern**: Model-View architecture with @Query property wrappers

## Project Structure

```
FocusFi/
├── FocusFiApp.swift           # App entry point and SwiftData configuration
├── Models.swift               # Data models (Transaction, BankAccount)
├── ContentView.swift          # Main dashboard view
├── ProgressView.swift         # Progress bar component
├── TransactionListView.swift  # Transaction list with sorting and deletion
├── AddTransactionView.swift   # Transaction entry form
├── CurrentFundsView.swift     # Bank account summary display
└── DateRangePickerView.swift  # Date range selector
```

## Requirements

- iOS 17.0+
- Xcode 15.0+
- Swift 5.9+

## Installation

1. Clone the repository:
```bash
git clone git@github.com:s3w47m88/focusfi-ios-app.git
cd focusfi-ios-app
```

2. Open the project in Xcode:
```bash
open FocusFi.xcodeproj
```

3. Build and run the project (⌘+R)

## Usage

### Adding Transactions
1. Tap the "+" button in the navigation bar
2. Select "Add Transaction"
3. Fill in the transaction details (type, title, description, amount, date)
4. Tap "Save"

### Viewing Transactions
- Tap on "Income" or "Expenses" sections to expand/collapse
- Use the sort button to toggle between sorting by date or amount
- Swipe left on a transaction to delete it

### Filtering by Date
1. Tap the calendar icon in the top-left
2. Select a custom date range or use quick filters
3. Transactions will update to show only those within the selected range

### Managing Data
- Use the "+" menu to access "Clear All Data" for resetting the app

## Version

Current Version: 1.0.0

## License

Proprietary
