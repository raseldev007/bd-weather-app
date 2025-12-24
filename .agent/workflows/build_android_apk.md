---
description: Build an Android APK for the application
---
# Build Android APK

To create a release APK for your Android application, follow these steps:

1.  **Open your terminal** to the project directory: `weather_app`
2.  **Run the build command**:
    ```bash
    flutter build apk --release
    ```
    *   *Optional:* To reduce file size, you can build separate APKs for different device architectures:
        ```bash
        flutter build apk --split-per-abi
        ```

3.  **Locate the APK**:
    *   Once the build completes, your APK file will be located at:
        `build/app/outputs/flutter-apk/app-release.apk`

4.  **Install on Device**:
    *   Transfer this file to your Android phone and open it to install.
    *   Or, if your phone is connected via USB with Developer Mode enabled:
        ```bash
        flutter install
        ```
