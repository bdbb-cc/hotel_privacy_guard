# Hotel Privacy Guard

Flutter starter app for a hotel room privacy check assistant.

The product direction is a lawful anti-spy-camera workflow: guided room sweep,
optical and infrared clues, risk notes, and an evidence report. It does not
scan for unknown camera streams, try credentials, or open devices without
authorization.

## Current MVP

- Guided room-zone sweep with completion progress.
- Zone-specific manual checklists for lawful visual room checks.
- Sweep screen suggests the next remaining manual checklist step and opens its
  checklist directly with the suggested step marked.
- Per-zone checklist step completion saved in local device state.
- Report screen and report drafts include overall and per-zone checklist
  progress.
- Report coverage gaps list remaining manual checklist steps.
- Report readiness highlights missing hotel/room details, unresolved findings,
  missing evidence photos, and unfinished manual checks before sharing.
- Manual reviewed findings with signal type, risk level, and location.
- Structured room-zone selection for every reviewed finding.
- Review status for findings: needs review, documented, or false alarm.
- Review status summary in the report screen and exported report content.
- Confirmed deletion for individual findings.
- Automatic UTC recorded timestamp for each reviewed finding.
- User-initiated camera/gallery evidence attachment for findings.
- Chinese first-pass headings and report labels while retaining existing
  English operational copy.
- Evidence report draft built from checked zones and reviewed findings.
- CJK-capable PDF report export saved into the app documents directory using a
  bundled Noto Sans SC TrueType font.
- System share action for exported PDF reports, with copy-path fallback.
- Attachment filenames in finding cards and reports without exposing full local
  device paths.
- Generated-at timestamp in report drafts and PDF content.
- Stay details for hotel, room, booking platform, and support contact.
- Risk-based action checklist for evidence preservation and escalation.
- Local persistence for checked zones, findings, notes, and attachment paths.
- Confirmed new-check reset that clears the current room state locally.
- Explainable risk score with visible factors for active findings, evidence
  attachments, unchecked room coverage, and excluded false alarms.
- False alarm findings are kept in the log but do not raise the risk score.
- Compact room risk map with `Flagged`, `Checked`, and `Unchecked` zone states.
- Local-first safety boundary: no unknown streams, credential attempts, or
  unauthorized device access.

## Permissions

- Android: camera permission is used only when the user taps `Take photo`.
- iOS: camera and photo library usage descriptions are configured for
  user-initiated evidence capture and selection.

## Known Limitations

- Chinese localization is currently a first pass: primary headings and report
  labels are localized, while detailed form labels and operational controls
  still include English copy.

## Run

```powershell
flutter run
```

## Check

```powershell
flutter test
```
