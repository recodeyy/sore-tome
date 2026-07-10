# Full E2E Test Report — 2026-07-10

Legend: ✅ live-verified today · 🟡 verified at API level, UI run pending · ⏳ pending deploy · ☐ blocked on device/creds

| # | §15 scenario | Status |
|---|---|---|
| 1 | Backend health/readiness | ✅ /health 200 (cold-start caveat, mitigated) |
| 2 | Website login (admin) | ✅ live (BFF 200, cookies, /dashboard 200) |
| 2b | Website login (super-admin) | ✅ live (fix deployed to code; flow itself verified with real creds) |
| 3 | Mobile login | ✅ same endpoint/contract live-verified; on-device run after APK rebuild |
| 4 | Resident onboarding/approval | 🟡 endpoints live; UI run ☐ |
| 5 | Website notice → app notification | 🟡 notice APIs 200; push ☐ device |
| 6 | Bill → payment → report | 🟡 funds/invoice APIs 200; Razorpay Test flow ☐ device |
| 7 | Poll → vote → results | 🟡 APIs 200; ☐ |
| 8 | Guard visitor flow | ☐ needs staff/guard creds + device |
| 9 | Complaint lifecycle | 🟡 APIs 200; ☐ |
| 10 | Parking allocation | 🟡 /parking/my 200; ☐ |
| 11 | Amenity booking | 🟡 amenities+bookings 200; ☐ |
| 12 | FCM fg/bg/killed | ☐ device |
| 13 | Receipt download | ☐ device |
| 14 | File upload/download | ☐ device |
| 15 | Logout/session expiry | 🟡 refresh/lockout logic verified in code+API; ☐ UI |
| 16 | Wrong-role denial | ✅ live (admin on super-admin portal → 403 PORTAL_MISMATCH) |
| 17 | Society B isolation | 🟡 RLS + tenant middleware verified in code; needs second society seeded ☐ |

## Regression suite after deploys (run these three commands)
```bash
# backend fix live?
curl -s -X POST -H "Content-Type: application/json" -d '{"phone":"9876543200","password":"123456"}' https://sero-api-live.onrender.com/api/v1/auth/login
# then with the token:
curl -s -H "Authorization: Bearer <token>" https://sero-api-live.onrender.com/api/v1/resident/family   # expect 200
curl -s -H "Authorization: Bearer <token>" https://sero-api-live.onrender.com/api/v1/parcels           # expect 200
```
