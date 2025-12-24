---
description: Guide to installing Android Studio and configuring the Android SDK for Flutter
---
# Install Android Studio & Configure SDK

To build Android apps (APKs), you must have the Android SDK installed and linked to Flutter.

### 1. Download Android Studio
1.  Go to the official website: [developer.android.com/studio](https://developer.android.com/studio)
2.  Click **Download Android Studio** (it is a large file, ~1GB+).

### 2. Install
1.  Run the downloaded `.exe` installer.
2.  Keep all default options checked (especially **"Android Virtual Device"**).
3.  Click Next/Install until finished.

### 3. Initial Setup (Crucial)
1.  **Open Android Studio** after installation.
2.  A "Setup Wizard" will appear. **Click Next**.
3.  Select **"Standard"** installation type. Click Next.
4.  Accept the licenses. Click **Finish**.
5.  **WAIT.** It will now download the Android SDK and tools (~2-3 GB). *Do not skip this.*

---

### 4. Locate Your SDK Path
Once the download is finished and Android Studio is open:
1.  Click **More Actions** (triple dots) on the Welcome screen -> **SDK Manager**.
2.  Look at the top of the window for **"Android SDK Location"**.
3.  Copy this path! (Usually: `C:\Users\YOUR_NAME\AppData\Local\Android\Sdk`).

---

### 5. Configure Flutter (One-Time Command)
Open your terminal (PowerShell or CMD) and run the following command, replacing `[PATH]` with the path you just copied:

```bash
flutter config --android-sdk "C:\Users\YOUR_NAME\AppData\Local\Android\Sdk"
```

*Example:*
`flutter config --android-sdk "C:\Users\Rasel\AppData\Local\Android\Sdk"`

### 6. Accept Licenses
Finally, run this command to agree to all agreements:
```bash
flutter doctor --android-licenses
```
(Type `y` and Enter for every question).

### 7. Build Your App
Now you can finally run:
```bash
cd weather_app
flutter build apk --release
```
