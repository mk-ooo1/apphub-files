# Implementation Plan - Dashboard UI Cleanup

This plan addresses the UI clutter on the Dashboard screen (Contacts tab) by condensing the summary card, improving the search bar styling, and combining the multiple Floating Action Buttons (FABs) into a single, clean menu.

## Proposed Changes

### Dashboard Screen (`dashboard_screen.dart`)

1.  **Condense Summary Card (`_SummaryCard`)**:
    - Convert the vertical layout into a compact horizontal `Row`.
    - Place the "Net Profit/Loss" on the left and the "You will get / You will give" stats on the right.
    - Remove the redundant "Reports" button from the card (as it already exists in the top AppBar), saving significant vertical space.

2.  **Combine Floating Action Buttons (FABs)**:
    - Replace the stacked "Split Bill" and "Add Contact" FABs with a single `+` (Add) FAB.
    - Tapping the `+` FAB will open a sleek Modal Bottom Sheet presenting the "Add Contact" and "Split Bill" options. This immediately reduces visual clutter on the bottom right.

3.  **Refine Search Bar**:
    - Make the search bar denser (using `isDense: true` and smaller padding) to match the cleaner aesthetic of the Account tab.
    - Adjust background colors for better contrast.

## Verification Plan

### Manual Verification
- Open the app to the Dashboard.
- Verify the Summary Card is now a compact horizontal strip.
- Verify the search bar is slimmer.
- Tap the new single `+` FAB and ensure the bottom sheet opens smoothly.
- Test that "Add Contact" and "Split Bill" from the bottom sheet navigate to their respective screens correctly.
