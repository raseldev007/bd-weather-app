---
description: How to build your APK using GitHub Actions (Cloud Build)
---
# Build APK in the Cloud (No Android Studio Required)

Since you don't have Android Studio installed locally, we have set up a **GitHub Action** to build the app for you.

### Step 1: Create a GitHub Repository
1.  Go to [github.com/new](https://github.com/new).
2.  Name your repository (e.g., `weather-app-bd`).
3.  Keep it **Public** (easiest) or **Private**.
4.  Click **Create repository**.

### Step 2: Push Your Code
Open your terminal in the project folder (`rogue-stellar`) and run these commands one by one:

```bash
# 1. Initialize Git (if not done)
git init

# 2. Add all files
git add .

# 3. Commit changes
git commit -m "Setup cloud build for APK"

# 4. Link to your new GitHub repo (Replace URL with yours!)
git remote add origin https://github.com/YOUR_USERNAME/weather-app-bd.git

# 5. Push code
git push -u origin main
```

### Step 3: Download Your APK
1.  Go to your repository page on GitHub.
2.  Click the **Actions** tab at the top.
3.  You will see a workflow named **"Build Android APK"** running (yellow circle).
4.  Wait for it to turn **Green** (success).
5.  Click on the workflow run.
6.  Scroll down to the **Artifacts** section.
7.  Click **release-apks** to download a ZIP file containing your Android app!
