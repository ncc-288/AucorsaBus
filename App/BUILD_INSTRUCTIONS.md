# How to Build the Aucorsa App (Android APK)

Since this is your first time building a Flutter app, follow these steps to set up your environment.

## 1. Install Flutter
If you haven't already:
1. Download the **Flutter SDK** for Windows: [https://storage.googleapis.com/flutter_infra_release/releases/stable/windows/flutter_windows_3.16.9-stable.zip](https://storage.googleapis.com/flutter_infra_release/releases/stable/windows/flutter_windows_3.16.9-stable.zip)
2. Extract the zip file to a simple path like `C:\src\flutter`.
3. Add `C:\src\flutter\bin` to your **User Path Environment Variable**:
   - Search "Edit environment variables for your account" in Windows Start.
   - Select `Path` -> Edit -> New -> Paste `C:\src\flutter\bin`.

## 2. Install Android Studio (Required for Android SDK)
1. Download **Android Studio**: [https://developer.android.com/studio](https://developer.android.com/studio)
2. Run the installer. Keep all default options (ensure "Android Virtual Device" is checked).
3. **Open Android Studio** once to complete the setup wizard. It will download the **Android SDK** and **Command-line tools**.
4. Go to **More Actions > SDK Manager** -> **SDK Tools** tab.
5. Check named **"Android SDK Command-line Tools"** and click **Apply** to install it.

## 3. Accept Licenses
Open your terminal (PowerShell or CMD) and run:
```powershell
flutter doctor --android-licenses
```
Type `y` (yes) to all prompts to accept the licenses.

## 4. Build the APK
Now you are ready to build the app!

1. Open a terminal in this folder (`D:\Documents\Tests\Antigravity\Aucorsa\App`).
2. Download the app dependencies:
   ```powershell
   flutter pub get
   ```
3. Build the release APK:
   ```powershell
   flutter build apk --release
   ```

## 5. Install on Phone
Once the build finishes (it takes a few minutes the first time), your APK will be at:
`build\app\outputs\flutter-apk\app-release.apk`

Copy this file to your Android phone and open it to install!
