# Remaining Tasks (Excluding CI/CD)

## Completed
- [x] Split lib/app.dart (534 lines) into AppShell, StartupOrchestrator, SyncReviewGate, OnboardingGate
- [x] Split lib/ui/settings/settings_view.dart (998 lines) into feature widgets

## Pending
- [ ] Split lib/core/google_sync_service.dart (1144 lines) into DriveBackupService, GmailSyncService, GoogleAuthManager
- [ ] Add automated tests (unit + integration)
- [ ] Add Isar migration strategy
- [ ] Add platform abstraction layer
- [ ] Add structured logging / crash reporting
- [ ] Lazy-init Gemma (move from main.dart)
- [ ] Fix dependency version pins

## Notes
- CI/CD related tasks (adding GitHub Actions and build_runner to CI) are intentionally omitted as per user request to focus on non-CI/CD tasks first.