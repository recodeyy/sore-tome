# 🏘️ Society Management App — Node.js Backend

Complete backend for the Flutter society app with Claude AI chatbot.

---

## 🚀 Setup (5 minutes)

### 1. Install dependencies
```bash
npm install
```

### 2. Configure environment
```bash
cp .env.example .env
# Edit .env and fill in your keys
```

### 3. Add Firebase service account
- Go to Firebase Console → Project Settings → Service Accounts
- Click "Generate new private key" → download the JSON
- Save it as `config/serviceAccountKey.json`

### 4. Run the server
```bash
npm run dev        # development (auto-restart)
npm start          # production
```

---

## 📡 API Reference

All routes (except `/health`) require a Firebase JWT in the header:
```
Authorization: Bearer <firebase_id_token>
```

The Flutter app gets this token after Firebase Auth login:
```dart
final token = await FirebaseAuth.instance.currentUser!.getIdToken();
```

---

### 👤 Users
| Method | Route | Auth | Description |
|--------|-------|------|-------------|
| POST | `/users/register` | Any | Save profile after first login |
| GET | `/users/me` | Any | Get own profile |
| GET | `/users` | Admin | List all residents |
| PATCH | `/users/:uid/role` | Superadmin | Promote to admin |

**POST /users/register body:**
```json
{ "name": "Rahul Shah", "flatNumber": "4B", "phone": "+91 98765 43210" }
```

---

### 📢 Notices
| Method | Route | Auth | Description |
|--------|-------|------|-------------|
| GET | `/notices` | Any | Get all notices |
| GET | `/notices/:id` | Any | Get single notice |
| POST | `/notices` | Admin | Post a notice |
| DELETE | `/notices/:id` | Admin | Delete a notice |

**POST /notices body:**
```json
{ "title": "Diwali Celebration", "body": "Oct 31 at 7 PM in the garden.", "type": "festival" }
```
Types: `general` | `event` | `maintenance` | `festival`

---

### 🔧 Issues
| Method | Route | Auth | Description |
|--------|-------|------|-------------|
| GET | `/issues` | Any | List issues (filter: `?status=open`) |
| GET | `/issues/:id` | Any | Get single issue |
| POST | `/issues` | Any | Report an issue |
| PATCH | `/issues/:id/status` | Admin | Update issue status |
| DELETE | `/issues/:id` | Admin/Owner | Delete issue |

**POST /issues body:**
```json
{ "title": "Lift not working", "description": "Block B lift stopped working.", "category": "maintenance" }
```
Categories: `maintenance` | `security` | `cleanliness` | `other`

**PATCH /issues/:id/status body:**
```json
{ "status": "in_progress", "adminNote": "Engineer visit scheduled for tomorrow." }
```
Statuses: `open` | `in_progress` | `resolved`

---

### 💰 Funds
| Method | Route | Auth | Description |
|--------|-------|------|-------------|
| GET | `/funds` | Any | Get monthly fund records |
| GET | `/funds/summary` | Any | Total collected / spent / balance |
| GET | `/funds/transactions` | Any | Full transaction ledger |
| POST | `/funds/transactions` | Admin | Add credit or debit entry |

**POST /funds/transactions body:**
```json
{ "title": "Lift maintenance", "amount": 18000, "type": "debit", "note": "Annual service" }
```
Types: `credit` | `debit`

---

### 📜 Rules
| Method | Route | Auth | Description |
|--------|-------|------|-------------|
| GET | `/rules` | Any | Get all rules |
| POST | `/rules` | Admin | Add a rule |
| PUT | `/rules/:id` | Admin | Update a rule |
| DELETE | `/rules/:id` | Admin | Delete a rule |

**POST /rules body:**
```json
{ "title": "Gym timings", "content": "Mon–Sat: 6–10 AM & 5–9 PM. Sunday closed.", "category": "timings", "order": 1 }
```

---

### 🎉 Events
| Method | Route | Auth | Description |
|--------|-------|------|-------------|
| GET | `/events` | Any | Get upcoming events |
| POST | `/events` | Admin | Create an event |
| DELETE | `/events/:id` | Admin | Delete an event |

**POST /events body:**
```json
{ "title": "Diwali Night", "description": "Celebration in garden area.", "date": "2025-10-31T19:00:00", "location": "Garden area" }
```

---

### 🤖 AI Chatbot (Claude)
| Method | Route | Auth | Description |
|--------|-------|------|-------------|
| POST | `/ai/chat` | Any | Chat with society AI |

**POST /ai/chat body:**
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

The AI automatically reads your latest rules from Firestore, so it always gives up-to-date answers!

---

## 🗂️ Firestore Collections

```
/users/{uid}           name, flatNumber, phone, role, createdAt
/notices/{id}          title, body, type, postedBy, createdAt
/issues/{id}           title, description, category, status, postedBy, adminNote, createdAt
/rules/{id}            title, content, category, order, updatedAt
/funds/{id}            month, totalCollected, totalSpent (optional summary docs)
/transactions/{id}     title, amount, type (credit/debit), note, createdAt
/events/{id}           title, description, date, location, createdBy
```

---

## ☁️ Deploy to Railway (free)

```bash
# Install Railway CLI
npm install -g @railway/cli

# Login and deploy
railway login
railway init
railway up

# Set env vars on Railway dashboard or:
railway variables set ANTHROPIC_API_KEY=your_key
railway variables set FIREBASE_PROJECT_ID=your_project_id
```

Your API will be live at `https://your-app.railway.app` in under 2 minutes!
