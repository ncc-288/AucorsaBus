![Header](assets/readme/cabecera.png)

# <img src="assets/readme/logo.png" width="40" height="40"> Aucorsa Bus Córdoba

[![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge)](https://opensource.org/licenses/MIT)

Real-time bus tracking and arrival estimations for the **Aucorsa** network in Córdoba, Spain. This application provides a modern, fast, and professional interface to stay updated with your daily commute.

🔗 **Official Website**: [aucorsa.es](https://aucorsa.es/)

---

## ✨ Features

- 🚌 **Real-time Arrival Times**: Live estimations for all stops and lines.
- 🎨 **Official Branding**: Strict professional white theme with official line color mapping.
- 🌓 **Adaptive Theme**: High-contrast light and dark modes with centered headers.
- ❤️ **Favorites**: Save your most-used stops for instant access from the side menu.
- 🔍 **Smart Search**: Find any stop or line quickly with debounced autocomplete.
- 🗺️ **Two-Way Routing**: Intelligent grouping of "Ida" and "Vuelta" (Outbound/Inbound) directions.

---

## 🛠️ Technical Documentation

This project includes extensive research on the Aucorsa API. Whether you are a developer looking to build your own tool or maintain this app, see the detailed mapping here:

📄 **[AUCORSA_API.md](AUCORSA_API.md)** - Documentation of endpoints, nonce-based authentication, and data structures.

---

## 🚀 Getting Started

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install)
- [Dart SDK](https://dart.dev/get-started/sdk)

### Installation
1. Clone the repository:
   ```bash
   git clone https://github.com/ncc-288/AucorsaBus.git
   ```
2. Navigate to the App directory:
   ```bash
   cd AucorsaBus/App
   ```
3. Install dependencies:
   ```bash
   flutter pub get
   ```
4. Run the app:
   ```bash
   flutter run
   ```

### Download Preview
You can download the latest stable release directly from the [GitHub Releases](https://github.com/ncc-288/AucorsaBus/releases/latest/download/app-release.apk) page.

---

## 🔧 Research Tools
The root directory contains PowerShell scripts used for the initial API reverse-engineering:
- `Get-AucorsaEstimation.ps1`: Fetch estimations directly via CLI.
- `Test-AllLines.ps1`: Validate all available lines.

---

## ⚖️ License
Distributed under the MIT License. See `LICENSE` for more information.

---
*Disclaimer: This is an unofficial application. All logos and data belong to AUCORSA S.A.*
