# 🏘️ Society Management App — Complete Project Plan

> A community app for 150–200 residents to manage issues, notices, rules, funds, events, and get AI-powered answers about their society.

---

## ✅ Is it possible?

100% yes. Apps like **MyGate, ApnaComplex, NoBrokerHood** do exactly this at scale. For 150–200 users, it's very manageable with a small team of 4 people in 2 weeks.

---

## 👥 User Roles

| Role | What they can do |
|---|---|
| **Resident** | Post issues, view notices, check rules & funds, use AI chatbot |
| **Admin** | Post notices, manage events, update funds, resolve issues |
| **Super Admin** | Manage users, assign admin roles |

---

## 📱 Key Features

- Login / Auth (phone OTP)
- Notice Board (admin posts events, festivals, maintenance alerts)
- Issue Board (residents report complaints, admin resolves them)
- Rules & Documents section
- Fund / Balance transparency display
- AI Chatbot (society-specific Q&A in Hindi/Hinglish/English)
- Push Notifications

---

## 🛠️ Tech Stack

| Layer | Technology | Why |
|---|---|---|
| Mobile App | **Flutter** | One codebase = Android + iOS |
| Backend | **Node.js + Express** | Simple, fast REST APIs |
| Database | **Firebase Firestore** | Real-time, free tier, no server needed to start |
| Auth | **Firebase Auth** | Phone OTP + Google login built-in |
| AI Chatbot | **Claude API (Anthropic)** | Society-specific Q&A, Hindi/Hinglish support |
| Web Prototype | **Flutter Web** | Same Flutter code, runs in browser first |
| Notifications | **Firebase Cloud Messaging** | Free push notifications |
| Deployment | **Railway.app** | Free Node.js hosting, deploy in 2 minutes |

---

## 👨‍💻 Team Split (4 People)

| Person | Role | Owns |
|---|---|---|
| **You** | Project Lead | Planning, AI integration, Firebase setup |
| **Dev 1** | Flutter Frontend | UI screens, navigation, bottom nav |
| **Dev 2** | Flutter Frontend | Auth, chatbot UI, notifications |
| **Dev 3** | Node.js Backend | All APIs, admin logic, rules/funds |

---

## 📅 2-Week Day-by-Day Plan

### Week 1 — Foundation

| Day | You | Dev 1 | Dev 2 | Dev 3 |
|---|---|---|---|---|
| **Day 1** | Firebase project setup, Firestore rules, repo + GitHub setup | Flutter project init, folder structure, routing | Firebase Auth integration (phone OTP) | Node.js project setup, Express boilerplate |
| **Day 2** | Define all Firestore collections (users, posts, notices, rules, funds) | Bottom nav bar + 5 screen skeletons | Login & Registration screens | User API (create, get profile) |
| **Day 3** | Claude API setup + system prompt for society bot | Notice Board screen (list UI) | Issue Post screen (form UI) | Notices API (CRUD) |
| **Day 4** | Write society data into Firestore (rules, timings, funds) | Rules & Documents screen | Fund display screen | Issues API + Fund API |
| **Day 5** | Test all APIs + Firebase security rules | Connect Notice Board to real API | Connect Issue screen to real API | Admin APIs (post notice, update fund) |

### Week 2 — Features + Polish

| Day | You | Dev 1 | Dev 2 | Dev 3 |
|---|---|---|---|---|
| **Day 6** | Build AI chatbot endpoint (Node.js → Claude API) | Admin panel screens | AI Chatbot screen UI | Admin auth middleware |
| **Day 7** | Test chatbot with real society questions | Events & Festival screen | Connect chatbot UI to backend | FCM notification trigger on new notice |
| **Day 8** | End-to-end testing (resident flow) | UI polish — colors, fonts, icons | Notification permission + display | Bug fixes on APIs |
| **Day 9** | End-to-end testing (admin flow) | Flutter Web build + test in browser | Loading states, error handling | API error handling + validation |
| **Day 10** | Demo prep + deploy Node.js to Railway.app | Final screen fixes | Record demo video / screenshots | Deploy APIs, share Postman collection |

---

## 📁 Flutter Folder Structure

```
lib/
├── main.dart
├── app/
│   ├── app.dart                   # MaterialApp, routes, theme
│   └── theme.dart                 # Colors, fonts (primary: #1a3a2a deep green)
├── models/
│   ├── user.dart
│   ├── notice.dart
│   ├── issue.dart
│   ├── fund.dart
│   └── event.dart
├── services/
│   ├── auth_service.dart          # Firebase Auth (phone OTP)
│   ├── firestore_service.dart     # All Firestore reads/writes
│   ├── ai_service.dart            # Claude API calls via Node.js backend
│   └── notification_service.dart  # FCM push notifications
├── screens/
│   ├── auth/
│   │   ├── login_screen.dart
│   │   └── otp_screen.dart
│   ├── home/
│   │   └── home_screen.dart
│   ├── issues/
│   │   ├── issues_screen.dart
│   │   └── post_issue_screen.dart
│   ├── rules/
│   │   └── rules_screen.dart
│   ├── funds/
│   │   └── funds_screen.dart
│   ├── ai_chat/
│   │   └── ai_chat_screen.dart
│   └── admin/
│       ├── admin_home.dart
│       ├── post_notice_screen.dart
│       └── manage_issues_screen.dart
└── widgets/
    ├── notice_card.dart
    ├── issue_card.dart
    ├── fund_bar.dart
    └── chat_bubble.dart
```

---

## 🗄️ Firestore Collections

```
/users/{uid}
    name, flatNumber, phone, role (resident/admin), createdAt

/notices/{id}
    title, body, type (general/event/maintenance/festival), postedBy, createdAt

/issues/{id}
    title, description, category, status (open/in_progress/resolved),
    postedBy, adminNote, createdAt, updatedAt

/rules/{id}
    title, content, category (timings/parking/pets/noise/general), order, updatedAt

/transactions/{id}
    title, amount, type (credit/debit), note, addedBy, createdAt

/events/{id}
    title, description, date, location, createdBy, createdAt
```

---

## 🖥️ Node.js Backend Structure

```
society-backend/
├── server.js                      # Entry point, middleware, route mounting
├── .env.example                   # Environment variable template
├── package.json
├── config/
│   └── firebase.js                # Firebase Admin SDK init
├── middleware/
│   └── auth.js                    # JWT verification + adminOnly guard
├── services/
│   └── aiService.js               # Claude API integration (reads Firestore live)
└── routes/
    ├── users.js                   # Register, profile, list users, set role
    ├── notices.js                 # CRUD notices
    ├── issues.js                  # CRUD issues + status updates
    ├── funds.js                   # Transactions, summary, ledger
    ├── rules.js                   # CRUD rules
    ├── events.js                  # CRUD events
    └── ai.js                      # POST /ai/chat → Claude API
```

---

## 📡 API Reference

All routes require Firebase JWT in header:
```
Authorization: Bearer <firebase_id_token>
```

### 👤 Users

| Method | Route | Auth | Description |
|---|---|---|---|
| POST | `/users/register` | Any | Save profile after first login |
| GET | `/users/me` | Any | Get own profile |
| GET | `/users` | Admin | List all residents |
| PATCH | `/users/:uid/role` | Superadmin | Promote to admin |

### 📢 Notices

| Method | Route | Auth | Description |
|---|---|---|---|
| GET | `/notices` | Any | Get all notices (newest first) |
| GET | `/notices/:id` | Any | Get single notice |
| POST | `/notices` | Admin | Post a notice |
| DELETE | `/notices/:id` | Admin | Delete a notice |

**POST body:**
```json
{ "title": "Diwali Celebration", "body": "Oct 31 at 7 PM in garden.", "type": "festival" }
```
Types: `general` | `event` | `maintenance` | `festival`

### 🔧 Issues

| Method | Route | Auth | Description |
|---|---|---|---|
| GET | `/issues` | Any | List issues (filter: `?status=open`) |
| GET | `/issues/:id` | Any | Get single issue |
| POST | `/issues` | Any | Report an issue |
| PATCH | `/issues/:id/status` | Admin | Update status |
| DELETE | `/issues/:id` | Admin / Owner | Delete issue |

**POST body:**
```json
{ "title": "Lift not working", "description": "Block B lift stopped.", "category": "maintenance" }
```

**PATCH status body:**
```json
{ "status": "in_progress", "adminNote": "Engineer visit scheduled tomorrow." }
```
Statuses: `open` | `in_progress` | `resolved`

### 💰 Funds

| Method | Route | Auth | Description |
|---|---|---|---|
| GET | `/funds/summary` | Any | Total collected / spent / balance |
| GET | `/funds/transactions` | Any | Full transaction ledger |
| POST | `/funds/transactions` | Admin | Add a credit or debit entry |

**POST transaction body:**
```json
{ "title": "Lift maintenance", "amount": 18000, "type": "debit", "note": "Annual service" }
```

### 📜 Rules

| Method | Route | Auth | Description |
|---|---|---|---|
| GET | `/rules` | Any | Get all rules (ordered) |
| POST | `/rules` | Admin | Add a rule |
| PUT | `/rules/:id` | Admin | Update a rule |
| DELETE | `/rules/:id` | Admin | Delete a rule |

### 🎉 Events

| Method | Route | Auth | Description |
|---|---|---|---|
| GET | `/events` | Any | Upcoming events |
| POST | `/events` | Admin | Create an event |
| DELETE | `/events/:id` | Admin | Delete an event |

### 🤖 AI Chatbot

| Method | Route | Auth | Description |
|---|---|---|---|
| POST | `/ai/chat` | Any | Chat with society AI |

**POST body:**
```json
{
  "message": "Aaj gym kab tak khula hai?",
  "history": [
    { "role": "user", "content": "Hello" },
    { "role": "assistant", "content": "Namaste! How can I help?" }
  ]
}
```

**Response:**
```json
{ "reply": "Aaj gym ka timing hai: Subah 6–10 AM aur Shaam 5–9 PM." }
```

---

## 🤖 How the AI Chatbot Works

The Claude AI reads your **live Firestore rules** on every request — so when admin updates gym timings, the AI immediately knows the new answer without any code changes.

```
Resident asks question
        ↓
POST /ai/chat (Node.js backend)
        ↓
Fetch latest rules from Firestore
        ↓
Build system prompt with live society data
        ↓
Send to Claude API (claude-sonnet-4-20250514)
        ↓
Reply shown in Flutter chat UI
```

**System prompt includes:**
- Society name and city
- All rules fetched live from Firestore
- Upcoming events from Firestore
- Instructions to respond in Hindi/Hinglish/English based on user's language
- Instruction to say "contact admin" for unknown info

---

## ⚙️ Environment Variables

```env
PORT=3000
NODE_ENV=development

# Anthropic — get from console.anthropic.com
ANTHROPIC_API_KEY=your_anthropic_api_key_here

# Firebase
FIREBASE_PROJECT_ID=your_firebase_project_id
FIREBASE_SERVICE_ACCOUNT_PATH=./config/serviceAccountKey.json

# Society info used by AI
SOCIETY_NAME=Sunset Valley Society
SOCIETY_CITY=Mumbai
```

---

## ☁️ Deploy to Railway (free, 2 minutes)

```bash
npm install -g @railway/cli
railway login
railway init
railway up

# Set environment variables
railway variables set ANTHROPIC_API_KEY=your_key
railway variables set FIREBASE_PROJECT_ID=your_project_id
```

Your API goes live at `https://your-app.railway.app`.

---

## 🚀 Getting Started Today

### Step 1 — Set up tools
- Create Firebase project at [console.firebase.google.com](https://console.firebase.google.com)
- Create GitHub repo and share with team
- Get Anthropic API key at [console.anthropic.com](https://console.anthropic.com)

### Step 2 — Backend
```bash
unzip society-backend.zip && cd society-backend
cp .env.example .env       # Fill in your keys
# Save Firebase service account JSON → config/serviceAccountKey.json
npm install && npm run dev
```

### Step 3 — Flutter
```bash
flutter create society_app
# Follow the folder structure above
# Add firebase_core, cloud_firestore, firebase_auth to pubspec.yaml
```

### Step 4 — Test AI chatbot
```bash
curl -X POST http://localhost:3000/ai/chat \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"message": "Gym kab khulta hai?"}'
```

---

## 📋 Screens Summary

| Screen | Resident | Admin |
|---|---|---|
| **Home** | Notices, stats, recent issues | Same + pending issues count |
| **Issues** | Post & track own issues, see all | Resolve/update any issue |
| **Rules** | View rules, timings, documents | Add/edit/delete rules |
| **Funds** | View balance & transactions | Add credit/debit entries |
| **AI Chat** | Ask anything in Hindi/English | Same |
| **Admin Panel** | ❌ | Post notices, manage events, manage users |

---

*Built with Flutter · Node.js · Firebase · Claude AI*

---

## 🔥 Firebase Setup (sero app ↔ Firebase ↔ society-backend)

> **Firebase project:** `sero-73976` · **Package name:** `sero.com`

### 1 — Android Gradle (already done ✅)

**Project-level** `android/build.gradle.kts`:
```kotlin
plugins {
    id("com.google.gms.google-services") version "4.4.4" apply false
}

allprojects {
    repositories { google(); mavenCentral() }
}
```

**App-level** `android/app/build.gradle.kts`:
```kotlin
plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")   // ← activate here
}

android {
    namespace = "sero.com"          // must match google-services.json
    defaultConfig {
        applicationId = "sero.com"  // must match google-services.json
        ...
    }
}

dependencies {
    implementation(platform("com.google.firebase:firebase-bom:34.0.0"))
    implementation("com.google.firebase:firebase-auth")
    implementation("com.google.firebase:firebase-firestore")
    implementation("com.google.firebase:firebase-messaging")
}
```

### 2 — google-services.json (already done ✅)

Place `google-services.json` at:
```
sero/android/app/google-services.json
```
Values from it:
| Key | Value |
|---|---|
| `project_id` | `sero-73976` |
| `project_number` | `290536796232` |
| `package_name` | `sero.com` |
| `mobilesdk_app_id` | `1:290536796232:android:98b522c0825f26f2c1e87d` |

### 3 — Flutter pubspec.yaml (already done ✅)

```yaml
dependencies:
  firebase_core: ^3.6.0
  firebase_auth: ^5.3.1
  cloud_firestore: ^5.4.4
  firebase_messaging: ^15.1.3
```

Run: `flutter pub get`

### 4 — firebase_options.dart (already done ✅)

`lib/firebase_options.dart` auto-generated from `google-services.json` values.  
> ⚠️ For **web**, add a Web app in Firebase Console and replace `YOUR_WEB_APP_ID`.

### 5 — main.dart Firebase init (already done ✅)

```dart
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const SocietyApp());
}
```

### 6 — society-backend .env

Create `society-backend/.env` from `.env.example`:
```env
PORT=3000
NODE_ENV=development
ANTHROPIC_API_KEY=your_anthropic_api_key_here

# Firebase — fill in from your Firebase project
FIREBASE_PROJECT_ID=sero-73976
FIREBASE_SERVICE_ACCOUNT_PATH=./config/serviceAccountKey.json

SOCIETY_NAME=Your Society Name
SOCIETY_CITY=Your City
```

### 7 — society-backend serviceAccountKey.json

1. Go to [Firebase Console](https://console.firebase.google.com) → Project `sero-73976`
2. **Project Settings** → **Service Accounts** tab
3. Click **"Generate new private key"** → saves a JSON file
4. Rename it `serviceAccountKey.json`
5. Place it at: `society-backend/config/serviceAccountKey.json`
6. Add to `.gitignore`: `config/serviceAccountKey.json` (never commit this!)

Then start the backend:
```bash
cd society-backend
npm install
npm run dev
```

You should see: `✅ Firebase connected`
