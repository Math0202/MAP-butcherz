# Namibia Hockey Union Mobile App - Backend Implementation

## Overview
This repository contains the backend implementation for the Namibia Hockey Union mobile application. The backend is built using MongoDB and Flutter/Dart, providing services for team registration, event management, player profiles, and real-time information sharing.

## Features
- User Authentication with SMS Verification
- Team Registration and Management
- Event Entry System
- Player Profile Management
- Real-time Updates
- Secure Password Handling (SHA-256)

## Technical Stack
- **Database**: MongoDB Atlas
- **Backend Framework**: Dart/Flutter
- **Authentication**: Custom implementation with SMS verification
- **Security**: SHA-256 password hashing

## Project Structure
```
lib/
├── config/
│   └── mongodb_config.dart    # MongoDB connection configuration
├── services/
│   ├── mongodb_service.dart   # Database operations wrapper
│   └── user_service.dart      # User management and authentication
└── screens/
    └── verification_screen.dart # SMS verification UI
```

## Setup Instructions

### Prerequisites
1. Flutter SDK (2.19.0 or higher)
2. MongoDB Atlas account
3. IDE (VS Code or Android Studio recommended)

### Environment Setup
1. Clone the repository:
   ```bash
   git clone https://github.com/Math0202/MAP-butcherz.git
   cd MAP-butcherz
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Configure MongoDB:
   - Create a MongoDB Atlas cluster
   - Copy your connection string
   - Update `lib/config/mongodb_config.dart` with your connection string

### MongoDB Configuration
1. Create the following collections in your MongoDB database:
   - users
   - verification_codes
   - teams
   - events
   - players

2. Set up indexes for better query performance:
   ```javascript
   db.users.createIndex({ "username": 1 }, { unique: true })
   db.users.createIndex({ "email": 1 }, { unique: true })
   ```

## Security Considerations
- All passwords are hashed using SHA-256
- Sensitive configuration is stored in environment variables
- Phone number verification required for account activation
- Input validation and sanitization implemented

## API Documentation
The backend provides the following core services:

### User Service
- Registration
- Authentication
- Profile management
- Password management
- Phone verification

### MongoDB Service
- Generic CRUD operations
- Connection management
- Collection helpers

## Testing
Run the tests using:
```bash
flutter test
```

## Contributing
1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## License
This project is licensed under the MIT License - see the LICENSE file for details.

## Contact
For any queries regarding the backend implementation, please contact the development team. 