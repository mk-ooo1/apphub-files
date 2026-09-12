# Walkthrough - Monetag Direct Link Integration

I have integrated your Monetag direct link into the app's Dashboard and Settings screens to help increase clicks and support development.

## Changes Made

### 1. Dashboard Integration
- **[dashboard_screen.dart](file:///D:/FlutterProjects/money_manage_app/lib/screens/dashboard_screen.dart)**:
    - Added an attractive "Support Project Development" card in the Contacts tab.
    - Placed it right below the main summary card for maximum visibility.
    - Styled it with an amber theme to make it stand out as a "special" feature.

### 2. Settings Integration
- **[settings_screen.dart](file:///D:/FlutterProjects/money_manage_app/lib/screens/settings_screen.dart)**:
    - Added a new "Support Development" item at the top of the "Support & Feedback" section.
    - This provides a secondary, permanent location for users to find the link.

### 3. URL Launching
- Used `url_launcher` with `LaunchMode.externalApplication` to ensure the link opens in the user's default browser instead of an internal webview, which is often required by ad platforms like Monetag.

## Verification

- [x] Verified the "Support" card appears in the Dashboard.
- [x] Verified the "Support Development" item appears in Settings.
- [x] Confirmed that clicking both items correctly opens `https://omg10.com/4/11783062` in an external browser.

---

render_diffs(file:///D:/FlutterProjects/money_manage_app/lib/screens/dashboard_screen.dart)
render_diffs(file:///D:/FlutterProjects/money_manage_app/lib/screens/settings_screen.dart)
