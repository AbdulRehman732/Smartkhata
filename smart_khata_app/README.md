# Smart Khata Mobile App (Flutter)

Flutter Android-first mobile client for **Smart Khata**, an AI-powered shop management system for Pakistani Kiryana stores.

## Features
- **Dashboard**: Live metric cards (Revenue, Gross Profit, Cash Collected, Low Stock Alerts, Pending Khata, Employees Present)
- **Inventory Management**: Search in English & Urdu (e.g. "چاول"), category filtering, low-stock alerts, non-negative stock adjustments
- **Point of Sale (POS)**: Multi-item sales, discount input, payment options (`Cash`, `Credit`, `Partial`), stock availability badges
- **Customer Khata Ledger**: Customer list, balance due tracking, payment recording modal, interleaved transaction history
- **Employee Attendance Roster**: Daily attendance toggles (`Present`, `Absent`, `Half-Day`, `Leave`), date picker
- **Payroll HR**: Monthly payroll run breakdown, salaried vs daily rate proration, mark-as-paid action
- **Reports & Insights**: Date-range financial summary, Cashbook inflow/outflow ledger, scikit-learn restock demand forecast
- **AI Voice Command Assistant**: Prompt box with wave visualizer, multilingual Urdu/Punjabi/English intent response cards
- **Offline Sync & Caching**: SQLite local cache (`smart_khata_local.db`), pending write queues for offline sales & attendance, manual & background sync engine

## Setup & Running

1. **Get Dependencies**:
```bash
flutter pub get
```

2. **Run Application**:
```bash
flutter run
```

3. **Run Unit Tests**:
```bash
flutter test
```

## Tested vs Unverified
- **Verified**:
  - Flutter Dart models, SQLite Map conversion, and sync payload serialization (100% passing tests via `flutter test`)
  - Screen component structure and widget layout
- **Unverified (Environment Specific)**:
  - Physical Android device / emulator runtime execution (depends on live Flutter engine connection to localhost FastAPI server).
