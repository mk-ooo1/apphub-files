# Implementation Plan - Fix AppHub Permission Error

This plan addresses the `403 Forbidden` error encountered when pushing the APK to the `apphub-files` repository. It involves refining the authentication logic in the workflow and verifying token scopes.

## User Review Required

> [!IMPORTANT]
> **Verify Token Permissions**: Please ensure your `APPHUB_TOKEN` has the correct permissions:
> 1. If using a **Classic Token**: Ensure the **`repo`** checkbox is checked.
> 2. If using a **Fine-grained Token**: Ensure it has **"Contents: Read and Write"** access for the `apphub-files` repository.

## Proposed Changes

### GitHub Actions

#### [MODIFY] [release.yml](file:///D:/FlutterProjects/money_manage_app/.github/workflows/release.yml)
- Update the "Push to AppHub" step to explicitly set the authenticated remote URL right before pushing. This ensures Git uses the PAT instead of any default environment credentials.
- Use a more robust authentication format for the Git remote.

## Verification Plan

### Manual Verification
- Push the change and monitor the "Push to AppHub" step in GitHub Actions.
- If it still fails with 403, it confirms the token itself lacks write permission for that specific repository.
