# VenueMate

VenueMate is a centralized venue booking and management platform that connects customers, hall administrators, and system administrators in a single unified system. Customers can search and filter verified venues, customize events with menus and service packages, upload payment receipts, and chat with hall admins in real time. Hall admins manage their listings, bookings, and services end-to-end. System admins verify hall authenticity and maintain platform integrity. Built with Flutter and Firebase — featuring role-based access control, location-based search, push notifications, and cloud-based payment verification.

> **Platform:** Android · Web &nbsp;|&nbsp; **Language:** Dart · Flutter 3.7.2+ &nbsp;|&nbsp; **Backend:** Firebase

---

## 📸 Screenshots

| Customer Dashboard | Hall Admin Dashboard | System Admin Dashboard |
|---|---|---|
| <img width="250" height="500" alt="customer_dashboard" src="https://github.com/user-attachments/assets/fb2e767d-2e57-4c0e-bfdb-332d6546851e" /> | <img width="250" height="500" alt="hall_admin_dashboard" src="https://github.com/user-attachments/assets/866990e6-51cf-4b54-9a88-dd874e81e617" /> | <img width="250" height="500" alt="system_admin_dashboard" src="https://github.com/user-attachments/assets/af503179-b585-4866-96f7-b376494b1310" /> |

---

## 🎬 Demo

https://github.com/user-attachments/assets/f60141f3-1a53-4eb0-9800-96c87ffb72b8

---

## ✨ Features

### 👤 Customer
- Browse and search venues with real-time availability
- View venue locations on Google Maps
- Customise events — select menu items, service packages, time slots, and guest count
- Upload payment receipt and track booking status
- Save favourite venues and view recently visited halls
- Real-time chat with Hall Admins
- Push notifications for booking updates via Firebase Cloud Messaging
- File complaints through the in-app complaint centre

### 🏢 Hall Admin
- Register and manage hall profile, photos, and location (picked via Google Maps)
- Create and manage menus, vendor services, and event packages
- View and respond to customer bookings
- Chat with customers and send notifications
- View feedback and analytics on booking patterns
- Pending review state while awaiting System Admin approval

### 🛡️ System Admin
- Review and approve or reject Hall Admin registrations
- Manage all users and hall listings
- Handle customer complaints with resolution workflow
- Monitor platform activity from a centralised dashboard

---

## 🏗️ Architecture

```
lib/
├── main.dart                  # App entry point, Firebase + FCM init
├── Models/                    # Data layer — typed models for all entities
│   ├── user_model.dart
│   ├── booking_model.dart
│   ├── hall_model.dart
│   ├── menu_item_model.dart
│   ├── package_model.dart
│   └── service_item_model.dart
├── Services/                  # Business logic — all Firebase interactions
│   ├── auth_service.dart
│   ├── booking_service.dart
│   ├── hall_service.dart
│   ├── notification_service.dart
│   └── storage_service.dart
├── Screens/
│   ├── Customers/             # 20+ customer-facing screens
│   ├── HallAdmin/             # Hall management screens
│   ├── SystemAdmin/           # Admin control screens
│   └── Shared/                # Common screens (settings, complaints, notifications)
├── Widgets/                   # Reusable UI components
└── Utils/                     # Navigation helpers and guards
```

**Data flow:** UI (Screens) → Service Layer → Firebase (Firestore / Auth / Storage / FCM)

---

## 🛠️ Tech Stack

| Layer | Technology |
|-------|-----------|
| Framework | Flutter 3.7.2+ / Dart |
| State Management | Provider pattern + Service classes |
| Authentication | Firebase Auth + Google Sign-In |
| Database | Cloud Firestore (real-time) |
| Storage | Firebase Storage |
| Push Notifications | Firebase Cloud Messaging + flutter_local_notifications |
| Maps | Google Maps Flutter + Geolocator + Geocoding |
| Chat | dash_chat_2 |
| Local Persistence | SharedPreferences |
| Charts | fl_chart |
| UI | Material Design 3, carousel_slider, animations |

---

## 🚀 Getting Started

### Prerequisites

- Flutter SDK 3.7.2+
- Dart SDK (bundled with Flutter)
- Android Studio or VS Code with Flutter extension
- A Firebase project with the following enabled:
  - Authentication (Email/Password + Google Sign-In)
  - Cloud Firestore
  - Firebase Storage
  - Firebase Cloud Messaging
- Google Maps API key (with Maps SDK for Android and Maps JavaScript API enabled)

### Installation

```bash
# 1. Clone the repo
git clone https://github.com/muhammadSaadXCII/VenueMate_System.git
cd VenueMate_System

# 2. Install dependencies
flutter pub get
```

### Firebase Configuration

1. Go to [Firebase Console](https://console.firebase.google.com/) and create a project
2. Add an Android app and download `google-services.json` → place in `android/app/`
3. Update `lib/firebase_options.dart` with your project credentials
4. Add your Google Maps API key to `android/app/src/main/AndroidManifest.xml`

### Run the App

```bash
# Android
flutter run

# Web
flutter run -d chrome

# Release APK
flutter build apk --release
```

---

## 🔐 Security Notes

- Firebase API keys in `main.dart` are **restricted by Firebase Security Rules** and package name — they are safe to expose in client-side Flutter code (this is standard Flutter/Firebase practice)
- Firestore Security Rules enforce role-based access — customers cannot access admin collections and vice versa
- All file uploads go through authenticated Firebase Storage paths
