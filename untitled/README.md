# ITM Connect

## Overview
ITM Connect is a Flutter application designed to provide a centralized platform for Information Technology and Management (ITM) information. The app features various functionalities for both users and administrators, including login screens, home screens, and access to important resources.

## Features
- **Landing Screen**: An animated entry point with a logo and navigation to the user home screen.
- **User Home Screen**: A dynamic interface with a bottom navigation bar that allows users to access different sections such as class routines, notices, and contact information.
- **Admin Login**: A dedicated screen for administrators to log in and manage the application.
- **Feedback and Contact Us**: Features that allow users to provide feedback and reach out for support.

## File Structure
```
lib/
├── features/
│   ├── admin/
│   │   └── login/
│   │       └── admin_login_screen.dart
│   ├── landing/
│   │   └── landing_screen.dart
│   └── user/
│       ├── home/
│       │   └── user_home_screen.dart
│       ├── class_routine/
│       │   └── class_routine_screen.dart
│       ├── contact/
│       │   └── contact_us_screen.dart
│       ├── feedback/
│       │   └── feedback_screen.dart
│       ├── notice/
│       │   └── notice_board_screen.dart
│       └── teacher/
│           └── list/
│               └── teacher_list_screen.dart
└── widgets/
    └── app_layout.dart
```

## Setup Instructions
1. Clone the repository to your local machine.
2. Navigate to the project directory.
3. Run `flutter pub get` to install the necessary dependencies.
4. Use `flutter run` to start the application on your preferred device.

## Usage
- Launch the app to view the landing screen.
- After a few seconds, the app will automatically navigate to the user home screen.
- Users can explore various features through the bottom navigation bar.

## Contributing
Contributions are welcome! Please feel free to submit a pull request or open an issue for any suggestions or improvements.

## License
This project is licensed under the MIT License. See the LICENSE file for more details.