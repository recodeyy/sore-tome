# SERO Member / Resident App — Frontend Audit

This document reviews the current state of the resident module in the frontend Flutter client (`sero`) and outlines the gaps, alignment with the branding design language, and shared integration points.

---

## 1. Current State of the Codebase (Resident Module)

### 1.1 Existing Files and Directory Structure
*   **Shell & Core Layout**: `lib/app/resident_shell.dart` exists but only maps a 4-tab floating bar (`Home`, `Hub`, `Support`, `Assistant`) using `FloatingPillNavbar` rather than the canonical 5-tab navigation (`Home`, `Community`, `Pay` center action, `Complaints`, `More`).
*   **Home Screen**: `lib/screens/resident/home/resident_home_screen.dart` is partially implemented. It displays greeting, society and flat context, guest gate preview, quick actions (`Book Amenity`, `Digital Polls`), and "Society Pulse" cards with latest notices and recent issues.
*   **Support/Complaints**: `lib/screens/resident/issues/resident_issues_screen.dart` and `post_issue_screen.dart` exist for viewing and submitting complaints/issues.
*   **Facilities/Amenities**: `lib/screens/resident/facilities/facilities_screen.dart` exists for browsing and booking facility slots.
*   **Polls**: `lib/screens/resident/polls/polls_screen.dart` exists for viewing and voting on polls.
*   **Rules & Bylaws**: `lib/screens/resident/rules/resident_rules_screen.dart` exists for viewing society regulations.
*   **Voice Assistant**: `lib/screens/resident/voice/voice_mode_screen.dart` exists for the AI voice copilot.
*   **Access Control / Visitors**: `lib/screens/resident/visitors/visitor_approval_screen.dart` exists but has limited features.
*   **Registration Status**: `lib/screens/resident/registration/registration_pending_screen.dart` exists to gatekeep unapproved residents.

---

## 2. Identified Design and Alignment Gaps

1.  **Tab Shell Structure**: Currently uses a 4-tab bar. Must be updated to a 5-tab shell:
    1.  `Home`
    2.  `Community` (Notice board, Events, Polls, Marketplace, Carpool, Lost & Found)
    3.  `Pay` (Centered circular emerald button with a wallet or rupee `₹` icon)
    4.  `Complaints` (Interactive list and creation panel)
    5.  `More` (Grid/list of remaining utilities, including KYC, Vehicles, NOCs, and Emergency Directory)
2.  **Branding Consistencies**:
    *   Colors: Screen headers must align to `kPrimaryGreen` (#064E3B) and `kPrimaryBlue` (#1E3A8A) with Outfit typography.
    *   Radii: Ensure all cards, buttons, and inputs conform to the premium SERO design system tokens.
3.  **Realtime and Capabilities**: Missing deep-link notification routing and real capability check checks on routes.
4.  **No Fallback Mocks**: Screens currently rely on static providers or in-memory arrays. These must be replaced with robust, authenticated HTTP services connecting to the PostgreSQL/Express backend.

---

## 3. Recommended Remediation Path

*   Update `resident_shell.dart` to a 5-tab shell using the canonical `SeroBottomNav` widget or a custom `ResidentBottomNav` matching the pay-center icon action.
*   Reorganize screens to separate "Hub" into `Community` and "More" configurations.
*   Refactor the Riverpod data flows to clear cache on user change or logout.
