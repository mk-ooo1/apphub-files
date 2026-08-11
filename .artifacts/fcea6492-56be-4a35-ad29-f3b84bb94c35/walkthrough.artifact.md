# Walkthrough - GitHub Actions for Signed APKs

I have configured a GitHub Actions workflow that will automatically build and sign your APK using the package name `com.MKDevOps.moneyManage`. This ensures that APKs downloaded from your GitHub repository will have the same signature as your local builds, avoiding package conflicts.

## Changes Made

### 1. Reverted Package Name
- **[build.gradle.kts](file:///D:/FlutterProjects/money_manage_app/android/app/build.gradle.kts)**: Set `namespace` and `applicationId` back to `com.MKDevOps.moneyManage` as requested.

### 2. Created Build Workflow
- **[.github/workflows/release.yml](file:///D:/FlutterProjects/money_manage_app/.github/workflows/release.yml)**: A new workflow file that runs on every push to `main`. It handles:
    - Environment setup (Java & Flutter).
    - Keystore restoration from secrets.
    - Signed APK building.
    - **New**: Automatically pushes the signed APK to your `apphub-files` repository in the `money-manage/` folder.

## Critical Setup Steps for You

To make this work, you must add your signing credentials and the `APPHUB_TOKEN` to **THIS** repository (`money_manage_app`) on GitHub.

### Step 1: Encode your Keystore
You need to convert your `upload-keystore.jks` file into a text string that GitHub can handle. Run this command in your terminal:

```powershell
[Convert]::ToBase64String([IO.File]::ReadAllBytes("android/app/upload-keystore.jks")) | Out-File -FilePath keystore_base64.txt
```
*Open `keystore_base64.txt` and copy the entire long string.*

### Step 2: Add GitHub Secrets
1.  Go to your GitHub repository on the web.
2.  Navigate to **Settings > Secrets and variables > Actions**.
3.  Click **New repository secret** for each of these:

| Secret Name | Value |
| :--- | :--- |
| `KEYSTORE_BASE64` | The long text string from `keystore_base64.txt` |
| `KEYSTORE_PASSWORD` | The password for your `.jks` file (e.g., `102003`) |
| `KEY_ALIAS` | `upload` |
| `KEY_PASSWORD` | The password for the alias (e.g., `102003`) |
| `APPHUB_TOKEN` | Your GitHub Personal Access Token (PAT) |

> [!IMPORTANT]
> The `APPHUB_TOKEN` allows the build process to "write" to your other repository.

### Step 3: Trigger the Build
Push your code to GitHub (including the new `.github` folder). The build will start automatically. Once finished, you can download the signed APK from the **Actions** tab.

> [!CAUTION]
> Remember to delete the temporary `keystore_base64.txt` file from your computer after you are done! Never commit it to Git.

---

render_diffs(file:///D:/FlutterProjects/money_manage_app/android/app/build.gradle.kts)
render_diffs(file:///D:/FlutterProjects/money_manage_app/.github/workflows/release.yml)
