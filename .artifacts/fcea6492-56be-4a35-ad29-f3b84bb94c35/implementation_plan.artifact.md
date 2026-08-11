# Implementation Plan - Cross-Repository Publishing to AppHub

This plan outlines how to automate the publishing of your built APK from this repository to your central `apphub-files` repository.

## User Review Required

> [!IMPORTANT]
> **Personal Access Token (PAT)**: To allow this repository to "talk" to your `apphub-files` repository, you must generate a GitHub PAT and add it as a secret.
>
> **Target Path**: I will configure the APK to be saved in a folder named `money-manage/` within the `apphub-files` repository. Let me know if you prefer a different folder name.

## Proposed Changes

### GitHub Actions

#### [MODIFY] [release.yml](file:///D:/FlutterProjects/money_manage_app/.github/workflows/release.yml)
Update the workflow to include a step that:
1.  Clones the `apphub-files` repository.
2.  Copies the newly built `app-release.apk` into the appropriate folder.
3.  Commits and pushes the change back to `apphub-files`.

## Step-by-Step Instructions for User

### 1. Create a GitHub Personal Access Token (PAT)
1.  Go to your GitHub **Settings > Developer settings > Personal access tokens > Tokens (classic)**.
2.  Generate a new token with the `repo` scope.
3.  **Copy this token immediately.**

### 2. Add the Token to THIS Repository
1.  In this repository (`money_manage_app`), go to **Settings > Secrets and variables > Actions**.
2.  Add a new secret named `APPHUB_TOKEN` and paste your PAT as the value.

## Verification Plan

### Manual Verification
- Push a change to this repo.
- Check the "Actions" tab to ensure the build completes and the "Push to AppHub" step succeeds.
- Open your `apphub-files` repository and verify that the APK is present in the `money-manage/` folder.
