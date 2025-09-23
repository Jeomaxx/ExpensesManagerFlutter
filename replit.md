# Finance App - Flutter Project

## Overview
A comprehensive Flutter finance management application imported from GitHub. This is a full-featured mobile app that has been successfully configured to run in the Replit environment as a web application.

## Current State
- ✅ **Successfully running** on web at port 5000 (0.0.0.0:5000)
- ✅ **Flutter SDK installed** and configured
- ✅ **Dependencies resolved** and assets configured
- ✅ **Deployment configured** for autoscale web deployment
- ✅ **Multi-language support** (English/Arabic)

## Project Architecture

### Technology Stack
- **Framework**: Flutter 3.32.0 (Dart SDK 3.8.0+)
- **State Management**: Riverpod 2.5.1
- **Navigation**: GoRouter 14.2.3
- **Database**: SQLite (sqflite)
- **Localization**: EasyLocalization with English/Arabic support
- **Charts**: FL Chart & Syncfusion Charts
- **Secure Storage**: Flutter Secure Storage

### Key Features
- **Dashboard**: Financial overview with charts and insights
- **Transactions**: Add, edit, view transaction history
- **Accounts**: Multiple account management
- **Budgets**: Budget creation and tracking
- **Goals**: Financial goal setting and monitoring
- **Reports**: Financial reports and analytics
- **Investments**: Investment portfolio tracking
- **Loans**: Loan management
- **Settings**: User preferences and configuration

### Project Structure
```
finance_app/
├── lib/
│   ├── src/
│   │   ├── core/           # Core functionality
│   │   │   ├── models/     # Data models
│   │   │   ├── providers/  # State management
│   │   │   ├── repositories/ # Data access
│   │   │   ├── services/   # Business logic
│   │   │   └── utils/      # Utilities
│   │   ├── features/       # Feature modules
│   │   │   ├── auth/       # Authentication
│   │   │   ├── dashboard/  # Main dashboard
│   │   │   ├── transactions/ # Transaction management
│   │   │   ├── accounts/   # Account management
│   │   │   ├── budgets/    # Budget features
│   │   │   ├── goals/      # Financial goals
│   │   │   └── reports/    # Financial reports
│   │   └── shared/         # Shared components
│   ├── main.dart           # Main entry point (full app)
│   └── main_simple.dart    # Simplified web version
├── assets/                 # Asset files
├── web/                    # Web platform files
├── android/                # Android platform files
└── ios/                    # iOS platform files
```

## Development Setup
The application is configured with:
- **Development Server**: Flutter web server on port 5000
- **Hot Reload**: Enabled for development
- **Debug Mode**: Currently running in debug mode
- **Host Configuration**: Configured for 0.0.0.0 to work with Replit proxy

## Deployment Configuration
- **Target**: Autoscale deployment (stateless web app)
- **Build Command**: `flutter build web --release`
- **Run Command**: `flutter run -d web-server --web-port 5000 --web-hostname 0.0.0.0 --release`
- **Platform**: Web (responsive design for mobile/desktop)

## Known Platform Support
- ✅ **Web**: Fully functional in browser
- ⚠️ **Android**: Configured but requires signing for production
- ⚠️ **iOS**: Configured but requires macOS/Xcode for builds

## Recent Changes
- **2025-09-23**: Successfully imported and configured for Replit environment
  - ✅ Installed Flutter SDK (3.32.0)
  - ✅ Fixed missing asset directories (assets/images/, assets/icons/)
  - ✅ Configured web deployment workflow on port 5000
  - ✅ Resolved build dependencies with flutter pub get
  - ✅ Set up autoscale deployment configuration
  - ✅ Application successfully running on development server at 0.0.0.0:5000
  - ✅ Hot reload and Flutter development tools working correctly

- **2025-09-23**: Enhanced Arabic finance management system
  - ✅ **Arabic Category System**: Created comprehensive Arabic categories (8 income + 22 expense)
    - **Income**: راتب شهري، مكافآت وحوافز، أعمال حرة، مشروع خاص، أرباح استثمارات، إيجار عقارات، عمولات، هدايا نقدية
    - **Expenses**: طعام ومشروبات، بقالة ومستلزمات، مواصلات، وقود، صحة وعلاج، أدوية وصيدلية، تعليم ودورات، كتب ومراجع، فواتير وخدمات، كهرباء ومياه، إنترنت واتصالات، ترفيه وتسلية، رياضة ولياقة، تسوق عام، ملابس وأحذية، سفر وسياحة، فنادق وإقامة، منزل وأثاث، أطفال وأسرة، هدايا ومناسبات، اشتراكات وخدمات رقمية، متفرقات
  - ✅ **Complete Arabic RTL Interface**: Full right-to-left layout with Cairo font
  - ✅ **Repository Integration**: Transaction form connected to CategoryRepository and TransactionRepository
  - ✅ **Arabic Sample Data**: Default transactions with Arabic names, notes, and tags
  - ✅ **Optimized Data Creation**: Idempotent category creation preventing duplicates

## User Preferences
- **Language**: Arabic with RTL support prioritized
- **Categories**: Comprehensive Arabic income/expense categorization system
- **Interface**: Arabic-first design with proper RTL layout

## Notes
- The app includes comprehensive finance management features
- Multi-language support with RTL (Arabic) capability
- Secure storage implementation for sensitive data
- Chart visualization for financial data
- Mobile-first design that works well on web