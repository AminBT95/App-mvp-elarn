# LinguaPath MVP

Local-first Flutter demonstration app based on the LinguaPath product specification and visual boards.

## Included

- Five-tab learner application: Home, Courses, Practice, Premium and Profile
- English/Arabic direction switch
- Local course catalogue, lessons, library content and exercises
- A1-C2 programme structure with General English, Business English, IELTS and TEFL samples
- Lesson reader with audio UI, Arabic support, vocabulary cards and completion flow
- Daily quiz with feedback, scoring and result dialog
- Local Premium demonstration state
- Persistent local progress, Premium state, saved items and downloads
- Search across courses and library content
- Placement test with a suggested A1-B1 starting point
- Notifications centre and reminder preferences
- Progress dashboard, certificate preview, saved content and offline management
- Responsive Material 3 interface inspired by the supplied blue, white and black designs
- GitHub Actions release APK build

## Generate the APK with GitHub

1. Create an empty GitHub repository.
2. Upload the complete contents of this folder to the repository root.
3. Rename the default branch to `main` if needed.
4. Open **Actions > Build Android APK > Run workflow**.
5. When the workflow finishes, download `LinguaPath-release-apk` from the Artifacts section.

The workflow creates the Android platform wrapper before compiling. No local Flutter installation is required.

## Run locally

```bash
flutter create --platforms=android --org org.linguapath .
flutter pub get
flutter run
```

## Edit local content

All demonstration data is stored in:

```text
assets/data/catalog.json
```

The file contains `courses`, `library` and `questions`. Keep IDs unique and regenerate the APK after changing content.

## Production limitations

This MVP deliberately has no external backend. Authentication, cloud sync, real store billing, server notifications, remote content publishing and public certificate verification are represented only as interface flows. They require a secured backend in the production phase.

## Recommended next phase

- Persist progress and preferences with a local database
- Add production audio and image assets
- Connect Supabase authentication and row-level security
- Add the web content-management dashboard
- Connect Google Play Billing and Apple StoreKit with server verification
- Implement signed offline entitlement leases and cross-device synchronisation
- Complete accessibility, device and store sandbox testing
