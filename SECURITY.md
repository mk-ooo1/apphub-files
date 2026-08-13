# Security Policy

## Supported Versions

Currently, only the latest release of Money Manage is supported with security updates.

| Version | Supported          |
| ------- | ------------------ |
| 1.0.x   | :white_check_mark: |
| < 1.0.0 | :x:                |

## Reporting a Vulnerability

If you discover a security vulnerability within this project, please do not report it publicly through the issue tracker. Instead, please report it privately.

You can contact the lead developer directly:
- **Lead Developer**: [mk-ooo1](https://github.com/mk-ooo1)

Please provide a detailed description of the vulnerability and steps to reproduce it. We will acknowledge your report and provide a timeline for a fix.

## Note on Google API Keys

This repository includes a `google-services.json` file which contains public API keys for Firebase integration. These keys are intended to be embedded in the app and are **not** a secret in the traditional sense. 

To prevent abuse, these keys are restricted to the app's package name and SHA-1 fingerprint within the Google Cloud Console. This is the recommended security practice for mobile applications.
