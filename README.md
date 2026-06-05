# MypersonalTracker 📱💼

MypersonalTracker is a premium, design-first personal finance ecosystem built with Flutter. It combines a local-first philosophy, on-device AI capabilities, real-time background syncing, and 100% end-to-end data encryption.

---

## 📸 Core Features Overview

### 1. Unified Expenses & Accounts Dashboard (`dashboard_view`)
*   **Dynamic Visualizations**: Beautiful, interactive charts showing expense categories and trends powered by `fl_chart`.
*   **Balance Tracking**: Auto-updating balances across bank accounts, credit cards, and cash.
*   **Advanced Transaction Entry**: Log transactions manually with support for custom categories, accounts, self-transfers, loan payback flags, and automated debt linking.
*   **Search & Filters**: Search, sort, and filter transaction histories instantly.

### 2. Cards & Loans Management (`cards_loans_view`)
*   **Credit Card Manager**: Track card limits, due dates, billing cycles, and current outstanding balances.
*   **NFC Quick-Read**: Interface with bank cards via NFC manager to trigger actions or read card details.
*   **Loan & Debt Ledger**: Log EMIs, track lending/borrowing, calculate compound interest intervals, and associate payback transactions automatically.
*   **Statement Parser**: Upload and decrypt Credit Card statements in PDF format (using Syncfusion PDF) to bulk import transactions.

### 3. Investment Portfolio Tracker (`investments_view`)
*   **Multi-Asset Support**: Track holdings in Stocks, Mutual Funds, Cryptocurrencies, and Stable Assets.
*   **Profit & Loss Analysis**: Track buy average price, current market price, quantity, and real-time gain/loss ratios.
*   **Broker Imports**: Support for importing statement data from brokers via PDF/Excel uploads.

### 4. Financial AI Advisor (`advisor_view`)
*   **Local Offline Inference**: Run `Gemma 2` or `Gemma 2b` models 100% locally on your device via Flutter Gemma (Ollama on desktop builds).
*   **Cloud API Fallbacks**: Integrated Gemini 3.5 API keys for heavy forecasting when offline limits aren't preferred.
*   **Quant Forecasts**: Run custom quantitative projections on savings, investment plans, and budget forecasts.

### 5. Automated Data Sync & Recovery
*   **Gmail & SMS Sync**: Auto-fetch transactions by querying Gmail inbox (IMAP) and Android SMS inbox.
*   **Cloud Backup**: Secure, encrypted backups pushed directly to Google Drive (AppData folder). The backup includes:
    *   **Isar Database** (`money_tracker_backup.isar`): Holds transactions, accounts, budgets, goals, and loans.
    *   **API Keys & Preferences** (`money_tracker_keys.json`): Securely stores Gemini/OpenAI keys, selected AI model ID, onboarding state, and custom category lists, icons, and colors.
*   **Recovery Bin**: Built-in trash bin allowing you to restore deleted accounts, loans, or transactions before they are permanently purged.
*   **Regex Skipped SMS Logs**: Access a scrollable log of skipped non-transactional messages under Settings. Tap any message to open it in the Interactive Sync Review Dialog and import it directly into your ledger.

---

## 🛠️ Technology Stack

*   **Framework**: Flutter (Dart)
*   **State Management**: Flutter Riverpod & Riverpod Generator
*   **Local Database**: Isar Database (NoSQL, fast, strongly typed)
*   **Security & Encryption**: Biometrics (`local_auth`), AES Key Storage (`flutter_secure_storage`)
*   **Data Formats**: Excel parsing, Syncfusion PDF statement reading, JSON export/import
*   **AI Integration**: `google_generative_ai` (Gemini), `flutter_gemma` (Local Gemma)

---

## 🚀 Setup & Installation

### Build and Install Release APK (Direct on Android)
To run MypersonalTracker as a standalone application on your Android device (with active real-time background SMS listeners):

1.  **Generate Release Build**:
    ```bash
    flutter build apk --release
    ```
2.  **Locate Installer**:
    The APK will be generated at:
    `build/app/outputs/flutter-apk/app-release.apk`
3.  **Install**:
    Transfer this `.apk` to your phone and install it directly.

### Development Quickstart
1.  **Clone & Fetch Dependencies**:
    ```bash
    flutter pub get
    ```
2.  **Generate Database & Riverpod Bindings**:
    ```bash
    dart run build_runner build --delete-conflicting-outputs
    ```
3.  **Run Application**:
    ```bash
    flutter run
    ```

---

## 🔒 Security & Privacy
*   **Local-First Design**: Your data never leaves your device unless you initiate a Google Drive or Google Sheets backup.
*   **Device Verification**: Lock screen gate utilizing Biometrics (Fingerprint/FaceID) or device Passcode fallback.
*   **Secure API Storage**: Cloud API Keys for Gemini, Hugging Face, or OpenAI are stored securely inside the Android KeyStore/iOS Keychain.
