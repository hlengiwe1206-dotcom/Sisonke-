# Sisonke Live MVP — Version 2

**South Africans Helping South Africans**

This build connects the Sisonke application architecture to a real Supabase backend.

## Live functionality included

- Email/password authentication
- Automatic profile creation
- Live Help Exchange feed
- Create a real help request
- Offer help to another user
- Request owner reviews offers
- Secure transactional acceptance of one offer
- Automatic creation of a Help Connection
- Automatic creation of a private conversation
- Automatic notification to the accepted helper
- Complete a Help Connection
- PostgreSQL database
- Row Level Security policies
- Basic Realtime configuration

## Launch the backend

### 1. Create a Supabase project

Create a project in your Supabase account.

### 2. Run the database migration

Open the Supabase SQL Editor and run:

`supabase/live_schema.sql`

### 3. Add credentials

Open:

`lib/core/supabase_config.dart`

Replace:

- `YOUR_SUPABASE_URL`
- `YOUR_SUPABASE_ANON_KEY`

### 4. Run Flutter

```bash
flutter pub get
flutter run
```

## Production hardening still recommended

Before a public national launch, add:

- SMS/phone verification
- CAPTCHA and abuse controls
- Human moderation dashboard
- Content scanning
- Push notification service
- File upload scanning
- Full conversation UI
- Blocking/reporting UI
- POPIA privacy notices and consent flows
- Terms and community guidelines
- Monitoring and backups
- Security testing

## Version 3 live integration update
This package is configured for the connected Sisonke Supabase project and adds live private messaging and live My Connections screens. After uploading/deploying the app, run `supabase/phase7_app_support.sql` in Supabase SQL Editor. The core Help Exchange backend is already compatible with Phases 1–6.
