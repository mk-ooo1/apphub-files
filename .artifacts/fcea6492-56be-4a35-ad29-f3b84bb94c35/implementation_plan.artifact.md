# Implementation Plan - Fix AppHub Authentication

This plan resolves the `Authentication failed` error (Exit code 128) when pushing the APK to the `apphub-files` repository by switching to a more robust authentication method in the GitHub Actions workflow.

## User Review Required

> [!IMPORTANT]
> **Secret Verification**: Please ensure you have added the secret exactly as named: `APPHUB_TOKEN` in the **money_manage_app** repository (not the apphub-files repository).
>
> **Token Scope**: Double-check that your Personal Access Token (PAT) has the **`repo`** (Full control of private repositories) scope enabled.

## Proposed Changes

### GitHub Actions

#### [MODIFY] [release.yml](file:///D:/FlutterProjects/money_manage_app/.github/workflows/release.yml)
- Add a check to verify if the `APPHUB_TOKEN` is present before attempting the push.
- Update the "Push to AppHub" step to use a more direct authentication format in the remote URL.
- Use the repository owner name explicitly in the authentication string.

## Verification Plan

### Manual Verification
- Push the workflow change and monitor the "Push to AppHub" step.
- If it still fails, the error message will be clearer about whether the token is missing or rejected.
