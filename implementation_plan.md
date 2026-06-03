# Implementation Plan - MypersonalTracker (Local-First Glassmorphic Expense & Portfolio Tracker)

We are building a private, local-first personal finance and investment advisor app named **MypersonalTracker** using **Flutter**. It will support **Android** (targeting the Samsung S24 Ultra) and **Windows Desktop** (for laptop use), with automated encrypted sync between the devices via Google Drive or WebDAV.

## User Review Required

> [!WARNING]
> **SMS Parsing is Android-Only**: Due to security sandboxes, SMS parsing is supported on Android (Samsung S24 Ultra) automatically after permission is granted. On non-Android desktop environments, we will rely on manual transaction inputs and clipboard/file parses.

> [!IMPORTANT]
> **Ollama on Laptop**: To run the local LLM on your laptop, you will need Ollama installed and running (`ollama run gemma2:2b` or similar). The app will connect to it locally on `http://localhost:11434`. On your phone, we will set up the Google AI Edge SDK to load a downloaded `.bin` model file, or you can supply an API key (Gemini/OpenAI) for cloud processing.

---

## Proposed Changes

We will initialize the Flutter project in `e:/Projects/Money_Tracker`.

### 1. Project Initialization & Dependencies
Initialize a multi-platform Flutter app and add key packages to `pubspec.yaml`:
*   **Database**: `isar` & `isar_generator` & `path_provider` (very fast, supports encryption, cross-platform)
*   **Secure Storage**: `flutter_secure_storage` (for API keys and IMAP credentials)
*   **State Management**: `flutter_riverpod` & `riverpod_annotation`
*   **SMS Reading (Android)**: `telephony` or `flutter_sms_inbox`
*   **Email (IMAP)**: `enough_mail` (pure Dart IMAP client for direct mail sync)
*   **PDF/Excel Parsing**: `syncfusion_flutter_pdf` (for card statement parser) and `excel` (for Zerodha Console holdings imports)
*   **Charts**: `fl_chart` (for premium expense and allocation visualizations)
*   **Network (Prices)**: `http` (fetching from Yahoo Finance / AMFI APIs)
*   **Local AI (Android)**: `google_mlkit_commons` or Google AI Edge/MediaPipe LLM Inference library
*   **Biometrics**: `local_auth` (local lock screen)

---

### 2. Core Architecture & Folder Structure
We will adopt a Clean Architecture folder structure:
*   `lib/core/`: Security, theme (Glassmorphic Midnight), database configurations, encrypted sync service.
*   `lib/features/expenses/`: Manual logging, category management, budget planning.
*   `lib/features/cards_loans/`: Credit card manager, statement parser, EMI tracker, borrowing/lending ledger.
*   `lib/features/investments/`: Zerodha/Coin file parses, portfolio dashboard, public price fetchers.
*   `lib/features/parser/`: SMS background listeners and IMAP client scheduler.
*   `lib/features/advisor/`: Quantitative calculation engine and Local LLM / API Chat interface.

---

### 3. Database Schema (Isar)
We will design a relational database schema:
*   `Transaction`: 
    *   ID, amount (total/original), description, timestamp
    *   transactionType (enum: Income, Expense, Transfer)
    *   category (e.g., Food, Shopping, Rent, Travel, Utilities, Investment)
    *   source (Manual, SMS, IMAP)
    *   accountName / cardId (nullable, links to cash or a specific credit card)
    *   isSplit (boolean), splitDetails (embedded list of child transactions showing sub-category splits or shared amounts with friends, referencing contacts/loans)
*   `CreditCard`: ID, cardName, last4, creditLimit, statementDay, dueDay, balance, statementEMIs (embedded list).
*   `Loan`: ID, contactName, isLent (true if lent, false if borrowed), amount, interestRate, compoundInterval, startDate, emiAmount, remainingBalance, linkedTransactionId (nullable).
*   `Holding`: ID, symbol, token, quantity, buyAvgPrice, currentPrice, assetType (Stock, MutualFund), broker (Zerodha, Coin).
*   `SyncMetadata`: ID, lastSyncTime, syncProvider.

### 4. Standard Core Features Checklist
To match and exceed the functionality of commercial trackers, the app will include these built-in standard features:
*   **Net Worth & Account Balances**: A dashboard card summing up Cash + Card Balances + Stock/Mutual Fund values - Active Debts.
*   **Recurring Transactions / Subscriptions**: Automatic scheduling of repeating transactions (e.g., Netflix, rent, monthly electricity) which feeds into future cash flow forecasts.
*   **Category Budgets & Alerts**: Define monthly spend caps per category (e.g., ₹5,000 for Dining Out) with interactive progress bars that change color as you approach the limits.
*   **Data Export (CSV/Excel)**: Export transactions list and investment portfolio to open CSV or Excel formats for personal tax filing or sheets backup.
*   **Global Search & Filters**: Fast local search bar to filter transactions by keyword, tag (e.g., `#trip2026`), category, or date range.
*   **Biometric Security**: Direct local lock screen using Fingerprint/FaceID (`local_auth`) to protect sensitive financial records when opening the app.
*   **Multi-Currency Support**: Ability to toggle or convert transactions that occur in other currencies (USD/EUR) into INR.

---

### 5. Implementation Steps

#### Phase 1: Foundation & Theme (Aesthetics)
*   Setup a design system in `lib/core/theme.dart`.
*   Implement custom Flutter components mimicking **Glassmorphism**:
    *   Containers with `BackdropFilter` for blur effect.
    *   Subtle thin white borders (`Colors.white.withOpacity(0.1)`).
    *   Vibrant background gradients blending midnight blue (`#0B0F19`), deep purple (`#1F1235`), and neon teal accent colors.
*   Build the main Shell Route (bottom navigation bar, glass dashboard, settings).

#### Phase 2: Manual Logging, Cards & Loans
*   Create forms for manual expense inputs.
*   Develop the Credit Card Manager (store credit cards, list statements, input interest parameters).
*   Implement the Loans Ledger (add loan, specify EMI, compound/simple interest calculators).

#### Phase 3: Automation (SMS, IMAP & Statements)
*   **Android SMS**: Background listener parsing banking SMS formats (HDFC, ICICI, SBI, Axis, etc.) using configurable regex patterns.
*   **Statement Reader & Email Automation**: 
    *   Store bank-specific statement PDF passwords securely in `flutter_secure_storage`.
    *   Extend the IMAP sync service to search the user's email at month-end for statement emails from specific banks (e.g., HDFC, ICICI).
    *   Automatically download statement PDF attachments to local app storage.
    *   Decrypt the PDFs *locally* on the device using the stored statement passwords.
    *   Extract transaction data and active EMIs using the PDF parser library (`syncfusion_flutter_pdf`), and save them directly to Isar.

#### Phase 4: Investment Tracker (Zerodha/Coin)
We will build local parser services and real-time public API price fetchers:
*   **Holding File Import Service**:
    *   Create [portfolio_parser_service.dart](file:///e:/Projects/Money_Tracker/lib/features/investments/services/portfolio_parser_service.dart) using `file_picker` and `excel` libraries.
    *   Implement CSV/XLSX parser for **Zerodha Console holdings**:
        *   Supports CSV and Excel (`.xlsx`, `.xls`) formats.
        *   Extracts Symbol/Instrument (e.g., `RELIANCE`), Quantity, Buy Average price, and ISIN.
    *   Implement CSV/XLSX parser for **Coin Mutual Fund holdings**:
        *   Extracts Scheme Name, Units/Quantity, Average NAV/Buy Price, and ISIN.
    *   Inserts or updates records dynamically in the local Isar database.
*   **Public Price Sync Service**:
    *   Create [investment_sync_service.dart](file:///e:/Projects/Money_Tracker/lib/features/investments/services/investment_sync_service.dart) to fetch live valuations:
        *   **Stocks**: Calls Yahoo Finance API (`https://query1.finance.yahoo.com/v8/finance/chart/{symbol}.NS`) to retrieve the live regular market price (regularMarketPrice).
        *   **Mutual Funds**: Searches by scheme name/ISIN using AMFI Search API (`https://api.mfapi.in/mf/search?q={schemeName}`) to map the scheme code, then fetches the latest NAV (`https://api.mfapi.in/mf/{schemeCode}/latest`).
        *   Updates the `currentPrice` and `lastUpdated` timestamp in Isar.
*   **Premium Holdings & Asset Allocation Dashboard**:
    *   Modify `InvestmentsView` in [main.dart](file:///e:/Projects/Money_Tracker/lib/main.dart) to:
        *   Expose a file upload flow using the new `PortfolioParserService`.
        *   Add a live "Refresh Prices" loading button wired to `InvestmentSyncService`.
        *   Integrate a premium glassmorphic PieChart using `fl_chart` displaying Stock vs. Mutual Fund asset allocation.
        *   List individual holding cards with dynamic return calculations (absolute profit/loss and total return percentages).

#### Phase 5: Mid-Month Forecasting & Advisor Engine
*   **Quant Engine**: Modern portfolio theory analytics, asset allocation charts, future spend projection (velocity engine + recurring EMI schedule).
*   **AI Engine (Privacy-First)**:
    *   *Local AI on Desktop*: Connect to local Ollama API.
    *   *Local AI on Android*: MediaPipe LLM Inference setup to load locally downloaded model.
    *   *Cloud API Fallback (Both)*: Optional input fields for Gemini/OpenAI API keys, stored in local secure storage.
    *   *Mandatory Local Sanitization*: Any data sent to cloud APIs *must* be sanitized locally first. Raw item descriptions (e.g., "Samsung Buds 2 Pro at Croma") are generalized to broad categories and numbers (e.g., "₹15,000 spent on Electronics") to ensure zero confidential item details ever leave the device.

#### Phase 6: Encrypted Backup & Sync
*   Create a local sync worker.
*   Encrypt database exports using AES-256 with a master password key.
*   Upload/download backups from the user's private Google Drive (App Data folder) or WebDAV endpoint.

---

## Verification Plan

### Automated/Unit Tests
*   **Database Tests**: Verify CRUD operations, relations, and transactions.
*   **Parsing Tests**: Mock banking SMS messages and IMAP email contents to ensure regex parsing accuracy.
*   **Import Parsers**: Test parser functions with mock Zerodha holdings `.csv` and `.xlsx` files.
*   **Financial Calculations**: Test interest compounding, EMI splits, and Holt-Winters forecasting outputs.

### Manual Verification
*   Run the app on Windows Desktop to test UI layout, local Ollama integration, file picking, and Yahoo Finance fetches.
*   Compile to Android and test on the Samsung S24 Ultra to verify SMS permissions, background receiving, and MediaPipe local inference.
