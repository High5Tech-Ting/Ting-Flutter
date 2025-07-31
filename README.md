# Ting - University Communication Platform

**"In tune, Informed, In sync, That's Ting"**

Ting is a comprehensive Flutter-based communication platform designed specifically for university environments. It serves as a centralized hub for students, lecturers, and staff to stay connected, informed, and organized within their academic community.

## 🎯 Project Overview

Ting is an MVP (Minimum Viable Product) of a university communication platform that brings together various essential features needed for academic life. The application facilitates seamless communication between different user types while providing administrative tools for efficient university management.

## ✨ Key Features

### 👥 Multi-User System
- **Students**: Access to courses, events, appointments, and peer communication
- **Lecturers**: Manage appointments, interact with students, access academic resources
- **Staff**: Administrative functions and departmental communication
- **Admins**: Complete system management and user administration

### 💬 Real-time Communication
- **Chat System**: Private messaging between users with real-time updates
- **Forum**: University-wide discussion platform with posts, comments, likes/dislikes
- **AI-Powered Features**: Integrated AI engine for enhanced communication

### 📅 Academic Management
- **Appointments**: Schedule and manage meetings between students and lecturers
- **Events**: Campus-wide event management and notifications
- **Calendar Integration**: Calendar view for appointments and events

### 🛠️ Administrative Tools
- **User Management**: Complete admin dashboard for managing students, lecturers, and staff
- **Support System**: Ticket-based support for handling user issues
- **Widget Management**: Customizable home screen widgets
- **Data Migration**: Tools for migrating and managing user data

### 📱 Enhanced User Experience
- **Profile Management**: Comprehensive user profiles with role-specific information
- **Home Widgets**: Android home screen widgets for quick access
- **Push Notifications**: Real-time notifications for messages, appointments, and updates
- **File Sharing**: Support for images, documents, and media files
- **Background Tasks**: WorkManager integration for background operations

## 🏗️ Technical Architecture

### Core Technologies
- **Framework**: Flutter (SDK ^3.8.1)
- **Backend**: Firebase (Firestore, Authentication, Storage, Messaging)
- **State Management**: Provider pattern with custom services
- **Local Storage**: Shared Preferences & SQLite
- **Background Processing**: WorkManager

### Key Services
- **AuthService**: User authentication and session management
- **AdminService**: Role-based access control and admin functions
- **NotificationService**: Push notifications and local alerts
- **EventService**: Event management and calendar integration
- **WidgetService**: Home screen widget management

### Database Structure
- **Users Collection**: Multi-role user management (students, lecturers, staff, admins)
- **Conversations**: Private messaging system
- **Forum Posts**: Public discussion threads with engagement features
- **Appointments**: Scheduling system with availability management
- **Events**: Campus event management with batch-specific targeting

## 🚀 Getting Started

### Prerequisites
- Flutter SDK ^3.8.1
- Firebase project setup
- Android Studio / VS Code
- Git

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/dilankayasuru/Ting.git
   cd Ting
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Firebase Setup**
   - Create a new Firebase project
   - Enable Authentication, Firestore, Storage, and Cloud Messaging
   - Download and place `google-services.json` in `android/app/`
   - Update `firebase_options.dart` with your project configuration

4. **Run the application**
   ```bash
   flutter run
   ```

### Configuration
- Update Firebase configuration in `lib/firebase_options.dart`
- Configure push notifications in `android/app/src/main/AndroidManifest.xml`
- Set up home widget permissions if using widget features

## 📁 Project Structure

```
lib/
├── core/                    # Core functionality and services
│   ├── models/             # Data models
│   ├── services/           # Business logic services
│   └── widgets/            # Reusable widgets
├── features/               # Feature-based modules
│   ├── auth/              # Authentication
│   ├── chat/              # Messaging system
│   ├── forum/             # Discussion forum
│   ├── admin/             # Administrative features
│   ├── appointments/      # Appointment management
│   ├── events/            # Event management
│   ├── profile/           # User profiles
│   ├── support/           # Support system
│   └── widgets/           # Home widgets
├── services/              # Global services
├── shared/                # Shared utilities and themes
└── main.dart              # Application entry point
```

## 🔧 Key Components

### Authentication System
- Email-based authentication with verification
- Role-based access control
- Session management with automatic token refresh

### Communication Features
- Real-time chat with typing indicators
- Forum with nested comments and reactions
- Push notifications for all communication

### Administrative Dashboard
- User management across all roles
- System analytics and monitoring
- Batch and department management

## 🎛️ Admin Features

Administrators have access to comprehensive management tools:
- **User Management**: Create, edit, and manage users across all roles
- **Event Management**: Create and manage university-wide events
- **System Monitoring**: Track user engagement and system health
- **Data Migration**: Tools for importing and managing user data
- **Support Management**: Handle user support requests

## 🔐 Security Features

- Firebase Authentication with email verification
- Role-based access control (RBAC)
- Secure file upload and storage
- Data validation and sanitization
- Admin privilege verification

## 📱 Platform Support

- **Android**: Full feature support with home widgets
- **iOS**: Core features supported
- **Web**: Limited web support for admin functions

**Developed for modern university communication needs - keeping everyone in tune, informed, and in sync.**
