# DocSync Doctor

A comprehensive doctor-side Flutter application for the DocSync telemedicine platform, built with Flutter and Supabase.

## 🏥 About

DocSync Doctor is a mobile and web application designed for healthcare professionals to manage their practice digitally. It enables doctors to:

- Manage their professional profile
- Handle online consultations (video, audio, chat)
- View and manage appointments
- Access patient health records
- Create and manage prescriptions
- Track earnings and analytics

## ✨ Features

### Implemented

- ✅ User Authentication (Login/Register/Password Reset)
- ✅ Doctor Profile Management
- ✅ Bottom Navigation with 4 main sections
- ✅ Home Dashboard with stats overview
- ✅ Profile viewing and editing
- ✅ Online/Offline status toggle
- ✅ Responsive UI with Material Design

### Coming Soon

- 🔄 Video Consultations
- 🔄 Appointment Management
- 🔄 Prescription Creation
- 🔄 Patient Health Records Access
- 🔄 Push Notifications
- 🔄 Earnings & Analytics
- 🔄 Rating & Reviews

## 🚀 Quick Start

### Prerequisites

- Flutter SDK (3.9.2 or higher)
- Supabase account
- Android SDK / Xcode (for mobile)

### Setup

1. **Clone the repository**

   ```bash
   git clone <repository-url>
   cd DocSync_Doctor
   ```

2. **Install dependencies**

   ```bash
   flutter pub get
   ```

3. **Configure Supabase**

   - Create a `.env` file in the root directory
   - Add your Supabase credentials:
     ```env
     SUPABASE_URL=your_supabase_url
     SUPABASE_ANON_KEY=your_supabase_anon_key
     ```
   - Run the SQL policies from `supabase_rls_policies.sql` in your Supabase SQL Editor

4. **Run the app**
   ```bash
   flutter run
   ```

## 📚 Documentation

- **[Quick Start Guide](QUICK_START.md)** - Step-by-step setup instructions
- **[Implementation Guide](IMPLEMENTATION_GUIDE.md)** - Detailed technical documentation
- **[Supabase RLS Policies](supabase_rls_policies.sql)** - Database security policies

## 🏗️ Architecture

This project follows Clean Architecture principles with the following layers:

```
lib/
├── features/           # Feature modules
│   ├── auth/          # Authentication
│   └── doctor/        # Doctor features
│       ├── data/      # Data layer (API, models, repositories)
│       ├── domain/    # Business logic (entities, use cases)
│       └── presentation/ # UI layer (pages, providers)
├── core/              # Core functionality
│   ├── routing/       # Navigation
│   ├── theme/         # Theming
│   └── constants/     # App constants
└── shared/            # Shared widgets and utilities
```

## 🛠️ Tech Stack

- **Framework**: Flutter 3.9.2
- **State Management**: Riverpod 2.4.10
- **Routing**: GoRouter 14.1.0
- **Backend**: Supabase 2.5.3
- **UI**: Material Design
- **Architecture**: Clean Architecture

## 📱 Screens

1. **Authentication**

   - Login
   - Register (with professional info)
   - Password Reset

2. **Main App (Bottom Navigation)**

   - Home/Dashboard
   - Consultations
   - Schedule
   - Profile

3. **Profile Management**
   - View Profile
   - Edit Profile

## 🔐 Security

- Row Level Security (RLS) policies implemented in Supabase
- Secure authentication using Supabase Auth
- Environment variables for sensitive data

## 🧪 Testing

```bash
flutter test
```

## 📦 Build

```bash
# Android APK
flutter build apk

# iOS (macOS only)
flutter build ios

# Web
flutter build web
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

This project is part of the DocSync telemedicine platform.

## 📞 Support

For issues or questions, please check the documentation files or create an issue in the repository.

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Supabase for the excellent backend platform
- All contributors and testers
