<div style="text-align: center;">
  <img src="assets/logos/shopsync.png" alt="ShopSync Logo"/>

# ShopSync

[![Code Style Check](https://github.com/aadishsamir123/asdev-shopsync/actions/workflows/check-code-style.yml/badge.svg)](https://github.com/aadishsamir123/asdev-shopsync/actions/workflows/check-code-style.yml)
[![Flutter Deploy](https://github.com/aadishsamir123/asdev-shopsync/actions/workflows/flutter-deploy.yml/badge.svg)](https://github.com/aadishsamir123/asdev-shopsync/actions/workflows/flutter-deploy.yml)
![Flutter Version](https://img.shields.io/badge/Flutter-^3.29.2-blue.svg)
![License](https://img.shields.io/badge/license-MIT-green.svg)

*Sync shopping lists with family and friends*
</div>

## 📱 Overview

ShopSync is an intuitive Flutter application that simplifies shared shopping experiences. Create and
manage shopping lists in real-time with family and friends.

## ✨ Features

- 🔄 Real-time cloud synchronization
- 📴 Offline access capability
- 🗑️ Recycle bin for deleted items
- 👥 Multi-user collaboration
- 🌓 Dark/Light theme support

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (^3.29.2)
- Dart SDK
- Firebase account
- Android Studio / VS Code

### Installation

1. Clone the repository
   ```bash
   git clone https://github.com/aadishsamir123/asdev-shopsync.git
   cd asdev-shopsync
   ```

2. Install dependencies
   ```bash
   flutter pub get
    ```

3. Configure Firebase
    - Create a new firebase project
    - Add your `google-services.json` to `/android/app/`
    - Add your `GoogleService-Info.plist` to `/ios/Runner/`(optional since this app currently does
      not support iOS)
    - Follow
      the [Firebase setup guide](https://firebase.google.com/docs/flutter/setup?platform=android)

4. Run the app
   ```bash
   flutter run
    ```

[//]: # (## 📱 Screenshots)

[//]: # ()

[//]: # (<div align="center">)

[//]: # (  <table>)

[//]: # (    <tr>)

[//]: # (      <td><img src="assets/screenshots/home.png" width="200"/></td>)

[//]: # (      <td><img src="assets/screenshots/list.png" width="200"/></td>)

[//]: # (      <td><img src="assets/screenshots/settings.png" width="200"/></td>)

[//]: # (    </tr>)

[//]: # (  </table>)

[//]: # (</div>)

## 🛠️ Tech Stack

- Flutter
- Firebase
- Dart
- Provider State Management
- Shared Preferences
- Cloud Firestore

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the GNU General Public License v3.0 - see the [LICENSE](LICENSE) file for details.
