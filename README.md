# LoopAir

Campus attendance and society management for Air University, built with Flutter (Android, iOS, web).

Created by **Abdul Rafay, Sinan M Shoaib and Abdul Sattar**.

## What it solves

| Problem | How LoopAir handles it |
|---|---|
| Manual sign-in sheets at seminars (e.g. the Seerah seminar) | The advisor opens a check-in session that shows a **QR code that changes every 20 s**. Students scan it at the gate, tap **Check in** in the app, or type the 6-digit code. On arrival and on **Leave**, the app saves a **time stamp and a location stamp**. |
| Proxy marks at society meetings | Students tap **Mark present**, then the society's **faculty focal person** verifies each one (Present / Not present, with a reason). |
| "I was at a society event during your class" | Every valid record produces a **slip code** (e.g. `LA-7K3D-92QX`). Instructors check it on the login screen, no account needed. |
| Double-booked venues | Event creation warns about **venue and time clashes**. |
| Bad data nobody notices | **Anomaly detection** flags check-ins outside the venue radius, missing location or check-out, being at two events at once, leaving early, unverified marks, and societies with no focal person. |
| Lost items | A shared **Lost & found** board. |
| Starting a society | A **proposal form**. The admin approves it and chooses to publish it straight away or keep it hidden. |

## Roles

- **Student**: check in and leave, scan the QR, mark meetings, attendance history and activity hours, slips, join societies, lost & found, propose a society, give feedback after events.
- **Faculty focal person**: verification queue, bulk-verify records that have no flags, add students by hand (for students without phones), export attendance as CSV.
- **Society account**: dashboard with turnout chart and ratings; create, edit and cancel events; live check-in QR screen; member requests; notices.
- **Admin (developer console)**: KPI dashboard, 7-day check-in chart, data-health gauge, society leaderboard, full create/edit/delete for users, societies, events, attendance records, lost & found and notices, an anomaly inbox, an audit log, and reset to demo data.

## Demo accounts

| Role | Email | Password |
|---|---|---|
| Student | student@au.edu.pk | student123 |
| Faculty (AUCIS) | faculty@au.edu.pk | faculty123 |
| Society (Seerah & Islamic Society) | seerah@au.edu.pk | society123 |
| Admin | dev@loopair.app | admin123 |

New students can self-register with an `@au.edu.pk` email.

## Security

- Passwords are stored as **salted PBKDF2-HMAC-SHA256** hashes (`lib/services/security.dart`), compared in constant time. Plain text is never stored.
- **Login lockout** after 5 failed attempts, with growing lock periods. Unknown email and wrong password give the same error, so accounts can't be discovered by guessing.
- **Role-based authorisation** is enforced inside the data layer (`Perm` and `AppStore._guard`), not just by hiding buttons. For example, only the focal person of *that* society can verify its meetings.
- Password policy on sign-up and password change; users can delete their own account (a Play Store requirement); the admin audit log records every change.
- Unit tests: `flutter test` (13 tests covering hashing, policy, lockout, QR tokens, permissions and slip codes).

## Run

```bash
flutter pub get
flutter run            # pick an Android emulator or device
flutter run -d chrome  # web
flutter test
```

## Project layout

```
lib/
  core/        theme tokens, shared widgets, formatting
  data/        models, demo seed, AppStore (state + persistence + rules)
  services/    location + rotating QR tokens, security (hashing, policy, permissions)
  features/    splash, onboarding, auth, shell, student, events, attendance,
               faculty, society, societies, announcements, lost_found,
               notifications, profile, verify, admin
```

## Before publishing on the Play Store

The app is local-first: data lives on the device (`shared_preferences`). For real multi-user use:

1. **Add a backend** (Firebase Auth + Firestore, or Supabase). `AppStore` is the only class that touches storage, so the screens don't need to change. Move hashing, the authorisation rules and QR token checks to the server.
2. **App identity**: set `applicationId` in `android/app/build.gradle.kts` (currently `com.loopair.loopair`), add a launcher icon (e.g. `flutter_launcher_icons`) and a signing key.
3. **Privacy policy URL**: host the in-app policy text publicly. Fill in the Data safety form (location is collected only at check-in and leave, never in the background).
4. Test the QR scanner and location on a real device. Browsers and emulators often deny location, so records get flagged "No location".
