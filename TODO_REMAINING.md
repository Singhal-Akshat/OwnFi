# Remaining Tasks (Excluding CI/CD)

## Completed
- [x] Split lib/ui/settings/settings_view.dart (998 lines) into feature widgets
- [x] Split lib/app.dart into AppShell, StartupOrchestrator, SyncReviewGate, OnboardingGate
- [x] Extract Deduplication & Transaction Merge Logic (from app.dart) into a shared utility
- [x] Lazy-init Gemma (move from main.dart)
- [x] Split lib/core/google_sync_service.dart (1144 lines) into DriveBackupService, GmailSyncService, GoogleAuthManager
- [x] Unify WebDAV and Google Drive Sync/Backup Orchestration

## Pending
- [x] Add automated tests (unit + integration)
- [x] Add Isar migration strategy
- [x] Add platform abstraction layer
- [x] Add structured logging / crash reporting
- [x] Fix dependency version pins

## Notes
- CI/CD related tasks (adding GitHub Actions and build_runner to CI) are intentionally omitted as per user request to focus on non-CI/CD tasks first.