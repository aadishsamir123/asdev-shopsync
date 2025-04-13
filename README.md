<div align="center">
  <img src="assets/logos/shopsync.png" alt="ShopSync Logo"/>

# ShopSync

[![Code Style Check](https://github.com/aadishsamir123/asdev-shopsync/actions/workflows/check-code.yml/badge.svg)](https://github.com/aadishsamir123/asdev-shopsync/actions/workflows/check-code.yml)
[![Flutter Deploy](https://github.com/aadishsamir123/asdev-shopsync/actions/workflows/flutter-deploy.yml/badge.svg)](https://github.com/aadishsamir123/asdev-shopsync/actions/workflows/flutter-deploy.yml)
![Flutter Version](https://img.shields.io/badge/Flutter-^3.29.2-blue.svg)
![License](https://img.shields.io/github/license/aadishsamir123/asdev-shopsync)

[![Android Stable](https://img.shields.io/endpoint?color=green&logo=google-play&logoColor=green&url=https%3A%2F%2Fplay.cuzi.workers.dev%2Fplay%3Fi%3Dcom.aadishsamir.shopsync%26gl%3DUS%26hl%3Den%26l%3DAndroid%2520Stable%26m%3D%24version)](https://play.google.com/store/apps/details?id=com.aadishsamir.shopsync)
[![Website](https://img.shields.io/website?url=https%3A%2F%2Fas-shopsync.pages.dev&logo=googleearth&logoColor=white)](https://as-shopsync.pages.dev)

*Share shopping lists with family and friends*
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

## 📱 Screenshots

Coming Soon

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

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (^3.29.2)
- Dart SDK
- Firebase account
- Android Studio / VS Code

## 🛠️ Tech Stack

- Flutter
- Firebase
- Dart
- Provider State Management
- Shared Preferences
- Cloud Firestore

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
    - Create a new Firebase project
    - Make sure to set up Firebase Authentication and Firestore in your Firebase project
    - Add your `google-services.json` to `/android/app/`
    - Add your `GoogleService-Info.plist` to `/ios/Runner/`(optional since this app currently does
      not support iOS)
    - Follow
      the [Firebase setup guide](https://firebase.google.com/docs/flutter/setup?platform=android)

4. Run the app
   ```bash
   flutter run
    ```

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the GNU General Public License v3.0 - see the [LICENSE](LICENSE) file
for details.
