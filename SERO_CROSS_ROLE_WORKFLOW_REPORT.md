# SERO — Cross-Role Workflow & Notification Report (verified)

> Date: 2026-06-25 · Verified by live probes against local backend (`localhost:3001`) + DB evidence from `sero_dev`.
> Pattern: every canonical state change emits an **outbox event** + inserts **notification rows** for the correct cross-role recipients, all inside the same DB transaction. Reuses `OutboxService` + `src/services/notifications/Recipients.ts` (`fanOut`). Deep links use `sero://<domain>/<id>`.

## Recipient resolution (`Recipients.ts`, tenant-scoped by `society_id`)
- `adminUserIds` → approved members with admin/committee role (main_admin, admin, secretary, treasurer, president, committee, manager).
- `unitResidentUserIds` → approved members of a unit + open `unit_occupancies` (tenant isolation: only that unit).
- `staffUserIds` / `securityStaffUserIds` → active staff, optionally role-filtered (guard, security_manager, …).

## Wired domain events (13)

| Workflow (prompt §) | Event type(s) | Recipients | Service | Status |
|---|---|---|---|---|
| Complaint (§6.4) | `complaint.created`, `complaint.assigned`, `complaint.commented` | create→admins; assign→staff; update→resident | `ComplaintService.ts` (3 fanOuts) | ✅ live-verified |
| Visitor/Guard (§6.3, §6.9) | `visitor.logged`, `visitor.entered`, `visitor.exited`, `visitor.denied` | target unit's residents; guard | `GuardService.ts` (7 fanOuts) | ✅ wired |
| Parking (§6.5) | `parking.allocated`, `parking.updated` | unit residents | `ParkingService.ts` (2 fanOuts) | ✅ wired |
| Poll (§6.6) | `poll.published` | eligible residents | `PollService.ts` | ✅ wired |
| Event (§6.7) | `event.published` | residents | `EventService.ts` | ✅ wired |
| SOS/Incident (§6.9) | `incident.reported`, `incident.status_changed` | security staff + admins; resident | `GuardService.ts` | ✅ wired |
| Notice (§6.1) | `notice.published` | audience members | `NoticeService.ts` | ✅ live-verified (prior pass) |
| Amenity booking (§6.8) | `amenity.booked`, `amenity.approved`, `amenity.cancelled` | book/request→admins + booking resident; approve→resident; cancel→resident + admins | `BookingService.ts` (book/cancel/requestBooking/approveBooking/cancelBooking — 8 fanOuts) | ✅ live-verified |

## Live evidence — Complaint create (§6.4)

Resident (`8Lm9vDSenHMyIqcJlHAv`, A-1402) `POST /complaints` → **201**, ref `CMP-0003`.

```
outbox_events:  complaint.created | topic society:hubtown-sunmist | published=t
notifications:  3 rows → admin-001, secretary-001, treasurer-001
                type=complaint, title="New complaint CMP-0003",
                data.deepLink = sero://complaints/3867d431-...-2069f
```

Tenant isolation holds: only Hubtown admins/committee were notified; no cross-society rows.

## Live evidence — Notice publish (§6.1, prior pass)
`POST /notices-v2` → `notices` row + 1 `outbox_events` (`notice.published`, drained) + 2 `notifications` (resident + admin) with `sero://notices/<id>`.

## Live evidence — Amenity booking (§6.8)

Wired in `src/services/amenities/BookingService.ts` (all fan-outs INSIDE the existing `withTx`; `book`/`cancel` were promoted to `withTx` to host them). Event types + recipients:
- `book` (POST `/amenities/:id/book`, instant-confirm) → `amenity.booked` to admins (+ confirmation to the booking resident).
- `requestBooking` (POST `/amenities/:id/request`, approval flow) → `amenity.booked` to admins + resident; copy reflects pending vs confirmed.
- `approveBooking` (POST `/amenities/bookings/:id/approve`) → `amenity.approved` to the booking resident.
- `cancelBooking` (POST `/amenities/bookings/:id/cancel`) and legacy `cancel` (DELETE `/amenities/bookings/:id`) → `amenity.cancelled` to resident + admins.

The booking resident is `amenity_bookings.member_id` (the route passes the caller's `uid`). Deep link `sero://amenities/<bookingId>`, notification `type=amenity`.

Resident (`8Lm9vDSenHMyIqcJlHAv`, A-1402) drove the full flow over HTTP on a throwaway `PORT=3013` (JWT minted from `JWT_SECRET`):

```
POST /amenities/<gym>/book        → 201 confirmed booking 8772c07f
  outbox:        amenity.booked (confirmed, published=t)
  notifications: admin-001 / secretary-001 / treasurer-001 "New Gym booking"
                 + 8Lm9…(resident) "Gym booked"  · all sero://amenities/8772c07f

POST /amenities/<clubhouse>/request → 201 pending booking a401973f
  outbox:        amenity.booked (pending)        → 3 admins "Clubhouse booking awaiting approval"
                                                  + resident "Clubhouse booking requested"
POST /amenities/bookings/a401973f/approve (admin) → 200 confirmed
  outbox:        amenity.approved                → resident "Clubhouse booking approved"
POST /amenities/bookings/a401973f/cancel {withRefund:true} → 200 cancelled
  outbox:        amenity.cancelled               → resident + 3 admins "Clubhouse booking cancelled"
```

All `amenity.%` outbox rows `published=t` (drained by the publisher loop); every notification carries `data.deepLink = sero://amenities/<id>`. Tenant isolation holds (only Hubtown committee + the unit resident).

Side fix (in-scope, `src/routes/amenities.ts` only): the shared `validate` middleware reassigns `req.params` to the schema's parsed `params`, so body-only schemas were stripping the `:id` path param and the `/book` `/request` `/cancel` routes 500'd with "reading 'id'" — a pre-existing latent bug, independent of notifications. Fixed by declaring `params:{id}` on the booking/cancel route schemas (`BookWithIdSchema`, `CancelSchema`). The service layer was already correct (proven by direct calls before the route fix).

## Gaps / follow-ups
- FCM **push delivery** of these notification rows depends on `notificationService.js` worker + device tokens; in-app + realtime (SSE via outbox) are proven. Physical-device push verification (§17) requires a real Android device + Firebase `sero-73976` and is a separate effort.
- These backend changes are **local**; they reach teammates only after a Render redeploy of `sero-api`.
