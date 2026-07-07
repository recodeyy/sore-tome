# Society App — Updated Project Plan

## Current Status

### Backend (Done)
- Auth: register, login, approve/reject, JWT middleware
- Routes: users, notices, issues, funds, rules, events, AI chat
- Claude AI chatbot with live Firestore system prompt
- Admin-only middleware in place

### Flutter App (Partial)
- All screens exist with UI structure
- `firestore_service.dart` → still returning mock data
- `ai_service.dart` → local placeholder, not calling backend
- `otp_screen.dart` → fake delay, not real auth
- `rules_screen.dart` → hardcoded static data
- Not wired to backend APIs yet

---

## New Features to Add

### 1. State Management — Use Riverpod
**Recommendation: Riverpod over BLoC**

BLoC is powerful but heavy for a 3-person team on a 2-week sprint. Riverpod is simpler, less boilerplate, and works great with async API calls.

**Providers to create:**
```
lib/providers/
├── auth_provider.dart          # login, logout, current user state
├── notices_provider.dart       # fetch + post notices
├── issues_provider.dart        # fetch + post + update issues
├── funds_provider.dart         # transactions + summary
├── rules_provider.dart         # fetch + admin CRUD
├── channels_provider.dart      # channel list + messages stream
└── ai_provider.dart            # chat history + send message
```

**Pattern to use — AsyncNotifierProvider:**
```dart
@riverpod
class NoticesNotifier extends _$NoticesNotifier {
  @override
  Future<List<Notice>> build() async {
    return await NoticesService.getAll();
  }

  Future<void> addNotice(String title, String body, String type) async {
    await NoticesService.post(title: title, body: body, type: type);
    ref.invalidateSelf(); // refresh list
  }
}
```

**pubspec.yaml additions:**
```yaml
riverpod: ^2.5.1
flutter_riverpod: ^2.5.1
riverpod_annotation: ^2.3.5
shared_preferences: ^2.2.2
http: ^1.2.0
```

---

### 2. Chat Channels

Admin creates channels (Wing A, Wing B, General, Announcements, etc.). Residents post messages in channels they have access to. Real-time via Firestore streams.

**Firestore structure:**
```
/channels/{channelId}
    name: "Wing A"
    description: "For Wing A residents only"
    createdBy: uid
    createdAt: timestamp
    allowedRoles: ["resident", "admin"]   // or restrict to specific flats later
    isReadOnly: false                      // if true, only admin can post

/channels/{channelId}/messages/{msgId}
    text: "message text"
    senderId: uid
    senderName: "Rahul"
    senderFlat: "4B"
    createdAt: timestamp
```

**Backend routes to add in routes/channels.js:**
```
GET    /channels                    Any logged-in user — list all channels
POST   /channels                    Admin only — create channel
DELETE /channels/:id                Admin only — delete channel
GET    /channels/:id/messages       Any — get last 50 messages
POST   /channels/:id/messages       Any — send a message
```

**Flutter — use Firestore stream for real-time chat:**
```dart
Stream<List<Message>> channelMessages(String channelId) {
  return FirebaseFirestore.instance
    .collection('channels')
    .doc(channelId)
    .collection('messages')
    .orderBy('createdAt', descending: true)
    .limit(50)
    .snapshots()
    .map((snap) => snap.docs.map(Message.fromDoc).toList());
}
```

**Screens to build:**
```
lib/screens/channels/
├── channels_list_screen.dart      # list of all channels
├── channel_chat_screen.dart       # real-time chat in one channel
└── create_channel_screen.dart     # admin only
```

---

### 3. Three Admin Panels

Three admin roles with different permissions and different home screens in Flutter.

#### Roles

| Role | Firestore value | What they can do |
|---|---|---|
| Main admin | `main_admin` | Everything — approve users, create channels, manage all data, assign roles |
| Treasurer | `treasurer` | Add/view transactions, fund summary only |
| Secretary | `secretary` | Post notices, manage issues, view rules — no funds, no user approval |

#### Backend changes

**Update middleware/auth.js — add role helpers:**
```javascript
function mainAdminOnly(req, res, next) {
  if (req.user?.role !== "main_admin") {
    return res.status(403).json({ error: "Main admin access required" });
  }
  next();
}

function canManageFunds(req, res, next) {
  const allowed = ["main_admin", "treasurer"];
  if (!allowed.includes(req.user?.role)) {
    return res.status(403).json({ error: "Treasurer or admin access required" });
  }
  next();
}

function canManageContent(req, res, next) {
  const allowed = ["main_admin", "secretary"];
  if (!allowed.includes(req.user?.role)) {
    return res.status(403).json({ error: "Secretary or admin access required" });
  }
  next();
}
```

**Update route guards:**
```javascript
// funds.js — only treasurer + main_admin
router.post("/transactions", authMiddleware, canManageFunds, async (req, res) => { ... });

// notices.js — only secretary + main_admin
router.post("/", authMiddleware, canManageContent, async (req, res) => { ... });

// auth.js — only main_admin approves users
router.post("/approve/:uid", authMiddleware, mainAdminOnly, async (req, res) => { ... });
```

#### Flutter — role-based navigation

In `main_shell.dart`, redirect to the right home after login:

```dart
Widget _getHomeForRole(String role) {
  switch (role) {
    case 'main_admin':   return const AdminMainHomeScreen();
    case 'treasurer':    return const AdminTreasuryHomeScreen();
    case 'secretary':    return const AdminSecretaryHomeScreen();
    default:             return const ResidentHomeScreen();
  }
}
```

**Flutter screens to build:**
```
lib/screens/admin/
├── main/
│   ├── admin_main_home.dart          # pending approvals + all stats
│   ├── admin_user_list.dart          # all users + edit
│   ├── admin_edit_user.dart          # edit name/flat/role/status
│   └── admin_create_channel.dart     # create/delete channels
├── treasury/
│   ├── treasury_home.dart            # fund summary + add transaction
│   └── treasury_ledger.dart          # full transaction history
└── secretary/
    ├── secretary_home.dart           # pending issues + notices
    ├── secretary_post_notice.dart    # post notice/event
    └── secretary_manage_issues.dart  # update issue status
```

---

### 4. Admin — Edit User After Approval

**Backend — add to routes/users.js:**
```javascript
// PATCH /users/:uid — main_admin can edit any user's details
router.patch("/:uid", authMiddleware, mainAdminOnly, async (req, res) => {
  try {
    const { name, flatNumber, blockName, role, status } = req.body;
    const db = getDb();
    const updates = { updatedAt: getAdmin().firestore.FieldValue.serverTimestamp() };

    if (name)       updates.name = name;
    if (flatNumber) updates.flatNumber = flatNumber;
    if (blockName !== undefined) updates.blockName = blockName;
    if (role)       updates.role = role;
    if (status)     updates.status = status;

    await db.collection("users").doc(req.params.uid).update(updates);

    // If role changed, update JWT claims too
    if (role) {
      await getAdmin().auth().setCustomUserClaims(req.params.uid, { role });
    }

    res.json({ message: "User updated successfully" });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});
```

**Flutter — edit user screen fields:**
- Name (text field)
- Flat number (text field)
- Block name (text field)
- Role dropdown: resident / treasurer / secretary / main_admin
- Status dropdown: pending / approved / rejected

---

## Updated Firestore Collections

```
/users/{uid}
    name, phone, password (hashed), flatNumber, blockName
    role: "resident" | "treasurer" | "secretary" | "main_admin"
    status: "pending" | "approved" | "rejected"
    createdAt, approvedAt, approvedBy

/channels/{channelId}
    name, description, isReadOnly, allowedRoles, createdBy, createdAt

/channels/{channelId}/messages/{msgId}
    text, senderId, senderName, senderFlat, createdAt

/notices/{id}       title, body, type, postedBy, createdAt
/issues/{id}        title, description, category, status, postedBy, adminNote, createdAt
/rules/{id}         title, content, category, order, updatedAt
/transactions/{id}  title, amount, type (credit/debit), note, addedBy, createdAt
/events/{id}        title, description, date, location, createdBy
/notifications/{id} type, title, body, targetRole, targetUserId, read, createdAt
```

---

## Updated Firestore Security Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    function isLoggedIn() { return request.auth != null; }
    function role() { return get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role; }
    function isMainAdmin() { return role() == 'main_admin'; }
    function isTreasurer() { return role() in ['main_admin', 'treasurer']; }
    function isSecretary() { return role() in ['main_admin', 'secretary']; }
    function isAnyAdmin() { return role() in ['main_admin', 'secretary', 'treasurer']; }

    match /users/{uid} {
      allow read: if isLoggedIn();
      allow write: if request.auth.uid == uid || isMainAdmin();
    }

    match /channels/{channelId} {
      allow read: if isLoggedIn();
      allow create, delete: if isMainAdmin();

      match /messages/{msgId} {
        allow read: if isLoggedIn();
        allow create: if isLoggedIn();
        allow delete: if isMainAdmin();
      }
    }

    match /notices/{id} {
      allow read: if isLoggedIn();
      allow write: if isSecretary();
    }

    match /issues/{id} {
      allow read: if isLoggedIn();
      allow create: if isLoggedIn();
      allow update, delete: if isSecretary();
    }

    match /rules/{id} {
      allow read: if isLoggedIn();
      allow write: if isSecretary();
    }

    match /transactions/{id} {
      allow read: if isLoggedIn();
      allow write: if isTreasurer();
    }

    match /events/{id} {
      allow read: if isLoggedIn();
      allow write: if isSecretary();
    }

    match /notifications/{id} {
      allow read: if isLoggedIn();
      allow write: if isAnyAdmin();
    }
  }
}
```

---

## 14-Day Sprint Plan

### Phase 1 — Wire Flutter to real backend (Days 1–3)

| Task | Owner |
|---|---|
| Replace `firestore_service.dart` mock data with real HTTP calls | Dev 1 + Dev 2 |
| Set up Riverpod — all providers | Dev 1 |
| Wire `ai_service.dart` to `POST /ai/chat` | Dev 2 |
| Replace OTP screen with phone + password login | Dev 2 |
| Replace hardcoded rules screen with API data | Dev 1 |
| Connect admin posting/issue screens to backend | Dev 3 (support) |

### Phase 2 — 3 admin roles + user edit (Days 4–6)

| Task | Owner |
|---|---|
| Add `main_admin`, `treasurer`, `secretary` roles to JWT + middleware | Dev 3 |
| Update route guards per role | Dev 3 |
| Build 3 admin home screens in Flutter | Dev 1 |
| Role-based navigation in `main_shell.dart` | Dev 2 |
| `PATCH /users/:uid` endpoint | Dev 3 |
| Edit user Flutter screen | Dev 2 |

### Phase 3 — Chat channels (Days 7–10)

| Task | Owner |
|---|---|
| Firestore `/channels` + `/messages` structure | You |
| `routes/channels.js` — all 5 endpoints | Dev 3 |
| `channels_list_screen.dart` | Dev 1 |
| `channel_chat_screen.dart` with Firestore stream | Dev 2 |
| `create_channel_screen.dart` (admin) | Dev 1 |
| `channels_provider.dart` in Riverpod | Dev 1 |

### Phase 4 — Polish + deploy (Days 11–14)

| Task | Owner |
|---|---|
| Updated Firestore security rules | You |
| Deploy backend to Railway | Dev 3 |
| Update `BASE_URL` in Flutter to production URL | Dev 2 |
| End-to-end test: register → approve → login → chat → issue | All |
| Build Flutter APK for internal testing | Dev 1 |
| Fix bugs from testing | All |

---

## What to start TODAY

1. Install Riverpod in Flutter: `flutter pub add flutter_riverpod riverpod_annotation`
2. Wrap `main.dart` with `ProviderScope`
3. Dev 3: add the 3 new role values to `routes/auth.js` + `middleware/auth.js`
4. Dev 1: start replacing `firestore_service.dart` — start with `getNotices()`
5. You: create the `/channels` collection in Firestore manually with 2-3 test channels

---

*Society App · Flutter + Node.js + Firebase + Claude AI*

---

## Issues Resolved: Missing Imports in Shell
- **Problem**: When attempting `flutter run`, the Dart compiler threw multiple `Error when reading 'lib/*'` tracing back to missing paths on imports inside `main_shell.dart`. 
- **Cause**: The application UI layers were cleanly nested into a `screens/` subdirectory, but the imports within `main_shell.dart` were still incorrectly pointing to `../home/home_screen.dart` instead of `../screens/home/home_screen.dart`.
- **Solution**: Patched all 9 import references in `main_shell.dart` globally to accurately map into `../screens/...` restoring the build engine connection.

---

## Phase 4 Completed: Code Additions
- **Admin Dashboard Modules:** Created `admin_main_home.dart` serving as the primary admin hub, pointing toward management paths.
- **User Processing Algorithm:** Appended `residentType` (`tenant`, `owner`, `guest`) and `maintenanceExempt` flags inside `users.js` + mapped full logic spanning `admin_users_screen.dart` for approving lists and controlling resident details.
- **Maintenance Status Tracker:** Built `GET /funds/maintenance-status` merging resident exemption properties identically over `credit` based transactions dynamically for live tracking inside `admin_maintenance_screen.dart`.
- **Channel Control Logic:** `admin_channels_screen.dart` now executes frontend CRUD pipelines dynamically binding deletion mechanisms onto API calls routing from the backend.

---

## Issues Resolved: Admin Screens Compilation Typos
- **Problem:** Flutter threw 'file not found' missing exports alongside a local variable collision (`c.name`) resulting in `BuildContext` inference errors. Also thrown was an undefined getter error for `channelsProvider`.
- **Solution:** Patched the relative depths of paths inside `admin_channels_screen.dart` and `admin_main_home.dart`. Replaced `showDialog` closure context variable from `c` to `ctx` eliminating the collision. Directed `admin_channels_screen.dart` to observe `channelsListProvider` matching the actual exported Riverpod Future.

---

## Profile Section Added
- **Feature:** New `ProfileScreen` (under `screens/profile/profile_screen.dart`) displays authenticated user details (name, phone, flat, role, resident type) and includes a prominent **Sign Out** button.
- **Integration:** Added a profile avatar button to the top‑right of both the resident `HomeScreen` and the admin dashboard `AdminMainHome`. Tapping it navigates to the profile screen.
- **Logout Logic:** The sign‑out button invokes `ref.read(authProvider.notifier).logout()` which clears the JWT and returns the user to the splash/login flow.
- **State Management:** Updated `HomeScreen` and `AdminMainHome` to be `ConsumerWidget/ConsumerStatefulWidget` and pull user data via `authProvider` for dynamic greetings and flat numbers.

These changes complete the user profile view and logout flow, finalizing the admin UI polish.

---

## Post-Completion Fixes 
- **Sign Out Routing:** When pressing the logout button, the Flutter Navigator was retaining the primary tab screens within its stack. Traced the `_SplashRoute` map and discovered that `/home` evaluates as the true routing root rather than the Splash. Upgraded the logout back button mechanism to explicitly run `Navigator.pushNamedAndRemoveUntil('/login', ...)` entirely erasing the stack and forcing the framework into the `LoginScreen` directly without relying on organic StateNotifier rebuilding.
- **Database Backed Admins:** Shifted away from hardcoded auth bypasses directly into Firebase natively! Wrote a `seed_admins.js` executor injecting the 3 admin accounts directly into your Firestore `users` schema with fully configured credentials and hashed `bcryptjs` passwords. The backend router was subsequently stripped of all custom admin intercepts allowing all users (admins and residents alike) to flow cleanly through exactly the same Firebase validation pipelines using:
    - `username/phone: admin` / **password: 123123,33** (main admin)
    - `username/phone: treasurer` / password: 123,23
    - `username/phone: secretary` / password: 123,23

---

## Premium UI & Infrastructure Overhaul
- **Home-S Branding:** Implemented a high-end, minimalist brand identity across the application. This includes a custom green-blue gradient palette and glassmorphism effects for a "premium" feel.
- **Splash Screen Logic:** Created a dedicated `SplashScreen` that handles initial authentication routing and displays the new `BrandLogo` with smooth entry animations.
- **Theme Refinement:** Overhauled `theme.dart` to support dynamic interaction states, modern typography, and high-contrast elements.
- **Android Native Alignment:** Refactored the Android project structure, moving `MainActivity.kt` to the `sero.com` package to match the application identity and updating `gradle.properties` for better build compatibility.
- **Repository Synchronization:** Performed a comprehensive cleanup and push of the optimized codebase, ensuring all core UI components and logic are versioned while maintaining security by excluding local secrets.


