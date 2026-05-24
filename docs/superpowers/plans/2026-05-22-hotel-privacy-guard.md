# Hotel Privacy Guard Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the initial Flutter app shell for a lawful hotel room privacy check assistant.

**Architecture:** A single Material app hosts three primary tabs: Sweep,
Findings, and Report. Static domain models define the starter room zones and
risk signal modules so the UI can later be wired to camera, local storage, and
report export services.

**Tech Stack:** Flutter 3.41.9, Dart 3.11.5, Material 3, flutter_test.

---

### Task 1: Scaffold App Shell

**Files:**
- Create: `lib/main.dart`
- Modify: `pubspec.yaml`
- Test: `test/widget_test.dart`

- [x] **Step 1: Create a Flutter project**

Run:

```powershell
flutter create --platforms=android,ios --org com.codex.hotelprivacy hotel_privacy_guard
```

Expected: project files are generated under `E:\DATA\source-code\flutter-project\hotel_privacy_guard`.

- [x] **Step 2: Replace the counter app**

Create a Material 3 app with `Sweep`, `Findings`, and `Report` tabs. Keep the
starter safe by excluding unknown stream access, credential attempts, and
unauthorized device controls.

- [x] **Step 3: Add widget smoke tests**

Verify the starter screen renders and bottom navigation reaches the Findings
and Report pages.

- [x] **Step 4: Run verification**

Run:

```powershell
flutter test
flutter analyze
```

Expected: tests pass and analyzer reports no project issues.

### Task 2: Add Reviewed Findings and Report Drafts

**Files:**
- Modify: `lib/main.dart`
- Modify: `test/widget_test.dart`
- Modify: `README.md`

- [x] **Step 1: Write failing widget tests**

Add tests for adding a reviewed finding and building a report draft from checked
zones and findings.

- [x] **Step 2: Implement reviewed findings**

Add state, an add-finding bottom sheet, risk chips, signal type selection, and
validation for required title and room location.

- [x] **Step 3: Implement report draft generation**

Build a text draft from checked zones and reviewed findings. Include a safety
boundary stating that no unknown camera streams were opened or accessed.

- [x] **Step 4: Run verification**

Run:

```powershell
dart format lib test
flutter test
flutter analyze
```

Expected: tests pass and analyzer reports no project issues.

### Task 3: Add Evidence Attachments and Local Persistence

**Files:**
- Modify: `lib/main.dart`
- Modify: `test/widget_test.dart`
- Modify: `pubspec.yaml`
- Modify: `android/app/src/main/AndroidManifest.xml`
- Modify: `ios/Runner/Info.plist`
- Modify: `README.md`

- [x] **Step 1: Write failing tests**

Add tests for photo attachment counts in reports, attaching a fake evidence
photo through the finding sheet, serializing snapshots, and restoring local
state.

- [x] **Step 2: Add dependencies**

Run:

```powershell
flutter pub add image_picker
flutter pub add shared_preferences
```

- [x] **Step 3: Implement evidence picker abstraction**

Use `EvidencePicker` for testability and `ImagePickerEvidencePicker` for the
real system camera/gallery picker.

- [x] **Step 4: Implement local snapshot persistence**

Save checked zone ids, reviewed findings, notes, risk levels, signal types, and
evidence attachment paths under `hotel_privacy_guard.snapshot.v1`.

- [x] **Step 5: Run verification**

Run:

```powershell
dart format lib test
flutter test
flutter analyze
```

Expected: tests pass and analyzer reports no project issues.

### Task 4: Add Risk Summary and Room Risk Map

**Files:**
- Modify: `lib/main.dart`
- Modify: `test/widget_test.dart`
- Modify: `README.md`

- [x] **Step 1: Write failing tests**

Add tests for risk score calculation, sweep/report risk summary display, and
zone status classification.

- [x] **Step 2: Implement explainable risk scoring**

Calculate risk from reviewed finding severity, evidence attachment count, and
remaining unchecked zones. Do not treat unchecked zones alone as suspicious
when there are no reviewed findings.

- [x] **Step 3: Implement room risk map**

Show each sweep zone as `Flagged`, `Checked`, or `Unchecked`. Flagged status is
derived from reviewed finding title/location text in this MVP.

- [ ] **Step 4: Run verification**

Run:

```powershell
dart format lib test
flutter test
flutter analyze
flutter build apk --debug
```

Expected: tests pass, analyzer reports no project issues, and Android debug APK
builds successfully.

### Task 5: Add PDF Evidence Report Export

**Files:**
- Modify: `lib/main.dart`
- Modify: `test/widget_test.dart`
- Modify: `pubspec.yaml`
- Modify: `README.md`

- [x] **Step 1: Write failing tests**

Add tests that verify PDF bytes are generated and the report screen can call an
injected exporter.

- [x] **Step 2: Add dependencies**

Run:

```powershell
flutter pub add pdf
flutter pub add path_provider
```

- [x] **Step 3: Implement PDF byte generation**

Use the existing report draft content to generate a PDF document with risk
summary, checked zones, findings, attachments, and safety boundary.

- [x] **Step 4: Implement app document export**

Save the generated PDF into the app documents directory and display the saved
path with a copy action.

- [x] **Step 5: Run verification**

Run:

```powershell
dart format lib test
flutter test
flutter analyze
flutter build apk --debug
```

Expected: tests pass, analyzer reports no project issues, and Android debug APK
builds successfully.

### Task 6: Add Structured Finding Zones

**Files:**
- Modify: `lib/main.dart`
- Modify: `test/widget_test.dart`
- Modify: `README.md`

- [x] **Step 1: Write failing tests**

Add tests that verify structured `zoneId` drives room risk map classification
and the selected zone is saved from the add-finding sheet.

- [x] **Step 2: Extend finding model**

Add optional `zoneId` to `Finding`, serialize it, and infer a fallback zone from
title/location for older locally stored records.

- [x] **Step 3: Add room-zone selector**

Add a `Room zone` dropdown to the add-finding sheet and save the selected zone
with each finding.

- [ ] **Step 4: Run verification**

Run:

```powershell
dart format lib test
flutter test
flutter analyze
flutter build apk --debug
```

Expected: tests pass, analyzer reports no project issues, and Android debug APK
builds successfully.

### Task 7: Add Evidence Chain Timestamps

**Files:**
- Modify: `lib/main.dart`
- Modify: `test/widget_test.dart`
- Modify: `README.md`

- [x] **Step 1: Write failing tests**

Add tests that verify stored finding timestamps round-trip through local
snapshots, appear in report drafts, and render on restored finding cards.

- [x] **Step 2: Extend finding model**

Add an optional `createdAtIso` field to `Finding`, serialize it, and keep older
local records compatible when the timestamp is absent.

- [x] **Step 3: Surface recorded time**

Set a UTC timestamp when a finding is saved, show it in the Findings log, and
include it in report drafts and PDF exports through the shared draft builder.

- [x] **Step 4: Run verification**

Run:

```powershell
dart format lib test
flutter test
flutter analyze
flutter build apk --debug
```

Expected: tests pass, analyzer reports no project issues, and Android debug APK
builds successfully.

### Task 8: Add Risk-Based Action Checklist

**Files:**
- Modify: `lib/main.dart`
- Modify: `test/widget_test.dart`
- Modify: `README.md`

- [x] **Step 1: Write failing tests**

Add tests that verify high-risk reports include recommended actions and the
Report screen surfaces an action checklist.

- [x] **Step 2: Model recommended actions**

Map each risk band to safe, lawful next steps that focus on preserving
evidence, requesting support, and escalation without touching unauthorized
devices.

- [x] **Step 3: Render and export actions**

Show the checklist on the Report screen and include the same actions in the
report draft so PDF exports inherit them.

- [x] **Step 4: Run verification**

Run:

```powershell
dart format lib test
flutter test
flutter analyze
flutter build apk --debug
```

Expected: tests pass, analyzer reports no project issues, and Android debug APK
builds successfully.

### Task 9: Add Stay Details to Reports

**Files:**
- Modify: `lib/main.dart`
- Modify: `test/widget_test.dart`
- Modify: `README.md`

- [x] **Step 1: Write failing tests**

Add tests that verify stay details appear in report drafts, round-trip through
local snapshots, and can be entered from the Report screen.

- [x] **Step 2: Add stay details model**

Add `StayDetails` with hotel, room, booking platform, and support contact
fields. Keep old local snapshots compatible when the details are absent.

- [x] **Step 3: Render and persist details**

Add a Report-screen details card, save changes locally, and include the same
fields in report drafts and PDF exports.

- [x] **Step 4: Run verification**

Run:

```powershell
dart format lib test
flutter test
flutter analyze
flutter build apk --debug
```

Expected: tests pass, analyzer reports no project issues, and Android debug APK
builds successfully.

### Task 10: Add Finding Review Status

**Files:**
- Modify: `lib/main.dart`
- Modify: `test/widget_test.dart`
- Modify: `README.md`

- [x] **Step 1: Write failing tests**

Add tests that verify review status round-trips through local snapshots,
appears in report drafts, false alarms do not raise risk score, and the
Findings screen can update a finding status.

- [x] **Step 2: Extend finding model**

Add `ReviewStatus` with `Needs review`, `Documented`, and `False alarm`, plus
serialization and `Finding.copyWith` for status changes.

- [x] **Step 3: Render and apply status**

Show status chips on finding cards, persist status changes, include review
status in reports, and exclude false alarms from risk scoring and room flagging.

- [x] **Step 4: Run verification**

Run:

```powershell
dart format lib test
flutter test
flutter analyze
flutter build apk --debug
```

Expected: tests pass, analyzer reports no project issues, and Android debug APK
builds successfully.

### Task 11: Add New Check Reset

**Files:**
- Modify: `lib/main.dart`
- Modify: `test/widget_test.dart`
- Modify: `README.md`

- [x] **Step 1: Write failing tests**

Add a widget test that restores an existing local check, starts a new check,
and verifies UI state plus persisted snapshot are cleared.

- [x] **Step 2: Add reset entry point**

Add a `New check` app bar action with confirmation before clearing local room
state.

- [x] **Step 3: Clear and persist empty state**

Reset checked zones, findings, stay details, and selected tab, then persist the
empty snapshot to local storage.

- [x] **Step 4: Run verification**

Run:

```powershell
dart format lib test
flutter test
flutter analyze
flutter build apk --debug
```

Expected: tests pass, analyzer reports no project issues, and Android debug APK
builds successfully.

### Task 12: Add Individual Finding Deletion

**Files:**
- Modify: `lib/main.dart`
- Modify: `test/widget_test.dart`
- Modify: `README.md`

- [x] **Step 1: Write failing tests**

Add a widget test that restores a saved finding, confirms deletion, and verifies
the UI plus persisted snapshot no longer contain that finding.

- [x] **Step 2: Add delete affordance**

Add a `Delete finding` icon action to finding cards and show a confirmation
dialog before removing the record.

- [x] **Step 3: Persist removal**

Remove the finding from in-memory state and write the updated snapshot to local
storage.

- [x] **Step 4: Run verification**

Run:

```powershell
dart format lib test
flutter test
flutter analyze
flutter build apk --debug
```

Expected: tests pass, analyzer reports no project issues, and Android debug APK
builds successfully.

### Task 13: Add Report Generated Timestamp

**Files:**
- Modify: `lib/main.dart`
- Modify: `test/widget_test.dart`
- Modify: `README.md`

- [x] **Step 1: Write failing tests**

Add a report draft test that passes a fixed UTC timestamp and expects the
generated report text to include a human-readable generated time.

- [x] **Step 2: Extend report generation**

Add an optional `generatedAtIso` parameter to report draft and PDF generation.
Use current UTC time when the caller does not provide one.

- [x] **Step 3: Surface timestamp in reports**

Write `Generated at` near the top of the report draft so copied text and PDF
exports carry the same timestamped record.

- [x] **Step 4: Run verification**

Run:

```powershell
dart format lib test
flutter test
flutter analyze
flutter build apk --debug
```

Expected: tests pass, analyzer reports no project issues, and Android debug APK
builds successfully.

### Task 14: Add Review Status Summary

**Files:**
- Modify: `lib/main.dart`
- Modify: `test/widget_test.dart`
- Modify: `README.md`

- [x] **Step 1: Write failing tests**

Add tests that verify report drafts include a review-status count summary and
the Report screen renders the same summary.

- [x] **Step 2: Add status count helper**

Add shared review-status counting logic so UI and report text cannot drift.

- [x] **Step 3: Render and export summary**

Show a compact summary on the Report screen and write `Review summary` to
report drafts and inherited PDF content.

- [x] **Step 4: Run verification**

Run:

```powershell
dart format lib test
flutter test
flutter analyze
flutter build apk --debug
```

Expected: tests pass, analyzer reports no project issues, and Android debug APK
builds successfully.

### Task 15: Add Evidence Attachment Filenames to Reports

**Files:**
- Modify: `lib/main.dart`
- Modify: `test/widget_test.dart`
- Modify: `README.md`

- [x] **Step 1: Write failing tests**

Add a report draft test that verifies attachment file names are listed while
full local device paths are not exposed.

- [x] **Step 2: Add filename helper**

Normalize `/` and `\` separators and extract only the final file-name segment.

- [x] **Step 3: Write filenames into reports**

For findings with evidence paths, write an `Attachment files` line after the
photo attachment count so copied text and PDF exports inherit it.

- [x] **Step 4: Run verification**

Run:

```powershell
dart format lib test
flutter test
flutter analyze
flutter build apk --debug
```

Expected: tests pass, analyzer reports no project issues, and Android debug APK
builds successfully.

### Task 16: Add Evidence Attachment Filenames to Finding Cards

**Files:**
- Modify: `lib/main.dart`
- Modify: `test/widget_test.dart`
- Modify: `README.md`
- Modify: `docs/superpowers/specs/2026-05-22-hotel-privacy-guard-design.md`
- Modify: `docs/superpowers/plans/2026-05-22-hotel-privacy-guard.md`

- [x] **Step 1: Write failing tests**

Add a widget test that restores a finding with two evidence paths and expects
the Findings card to show only `outlet.jpg, mirror-close.png`, not the full
local device path.

- [x] **Step 2: Display sanitized filenames in cards**

Reuse `evidenceFileName` next to the existing photo count and constrain the
text to two lines with ellipsis for long attachment lists.

- [x] **Step 3: Update docs**

Record that attachment filenames now appear in both finding cards and report
content without exposing full local paths.

- [x] **Step 4: Run verification**

Run:

```powershell
dart format lib test
flutter test
flutter analyze
flutter build apk --debug
```

Expected: tests pass, analyzer reports no project issues, and Android debug APK
builds successfully.

### Task 17: Add Risk Factor Explanations

**Files:**
- Modify: `lib/main.dart`
- Modify: `test/widget_test.dart`
- Modify: `README.md`
- Modify: `docs/superpowers/specs/2026-05-22-hotel-privacy-guard-design.md`
- Modify: `docs/superpowers/plans/2026-05-22-hotel-privacy-guard.md`

- [x] **Step 1: Write failing tests**

Add tests that expect report drafts and the Report screen to show active
findings, evidence attachment count, unchecked zone coverage, and excluded
false alarms.

- [x] **Step 2: Extend risk summary data**

Store active finding count, active evidence attachment count, and excluded false
alarm count on `RiskSummary` while preserving the existing score calculation.

- [x] **Step 3: Surface factor explanations**

Render compact risk factor lines on the Report screen and write the same lines
into report drafts so copied text and PDF exports inherit the explanation.

- [x] **Step 4: Run verification**

Run:

```powershell
dart format lib test
flutter test
flutter analyze
flutter build apk --debug
```

Expected: tests pass, analyzer reports no project issues, and Android debug APK
builds successfully.

### Task 18: Add Chinese First Pass and CJK PDF Font

**Files:**
- Modify: `lib/main.dart`
- Modify: `test/widget_test.dart`
- Modify: `pubspec.yaml`
- Modify: `README.md`
- Modify: `docs/superpowers/specs/2026-05-22-hotel-privacy-guard-design.md`
- Modify: `docs/superpowers/plans/2026-05-22-hotel-privacy-guard.md`
- Add: `assets/fonts/NotoSansSC-Regular.ttf`
- Add: `assets/licenses/NotoSansSC-OFL.txt`

- [x] **Step 1: Write failing tests**

Add tests that expect Chinese primary UI copy, Chinese report header fields,
and a PDF document that embeds a `NotoSansSC` font instead of Helvetica for
Chinese content.

- [x] **Step 2: Bundle licensed CJK font assets**

Register the Noto Sans SC TrueType font and its OFL license file in
`pubspec.yaml` so PDF generation can load the asset in tests and app builds.

- [x] **Step 3: Use CJK font in PDF generation**

Load the font through `rootBundle`, use it as the PDF base and bold font, and
write a Chinese report title so CJK report content renders without Helvetica
fallback warnings.

- [x] **Step 4: Add Chinese first-pass copy**

Add Chinese primary sweep headings and Chinese report draft header fields while
keeping existing English labels for current workflows.

- [x] **Step 5: Run verification**

Run:

```powershell
dart format lib test
flutter test
flutter analyze
flutter build apk --debug
```

Expected: tests pass, analyzer reports no project issues, and Android debug APK
builds successfully.

### Task 19: Add System PDF Sharing

**Files:**
- Modify: `lib/main.dart`
- Modify: `test/widget_test.dart`
- Modify: `pubspec.yaml`
- Modify: `README.md`
- Modify: `docs/superpowers/specs/2026-05-22-hotel-privacy-guard-design.md`
- Modify: `docs/superpowers/plans/2026-05-22-hotel-privacy-guard.md`

- [x] **Step 1: Write failing test**

Extend the PDF export widget test to expect a `Share PDF` action after export
and verify that tapping it passes the exported report path to an injected
report sharer.

- [x] **Step 2: Add sharing dependency**

Add `share_plus` and inspect its local package API. Use
`SharePlus.instance.share(ShareParams(files: ...))` for file sharing.

- [x] **Step 3: Add report sharing abstraction**

Introduce `ReportSharer` so tests can inject a fake sharer while production
uses `SharePlusReportSharer`.

- [x] **Step 4: Wire share action into export sheet**

Add `Share PDF` as the primary action in the PDF-ready sheet and keep `Copy
path` as a fallback.

- [x] **Step 5: Run verification**

Run:

```powershell
dart format lib test
flutter test
flutter analyze
flutter build apk --debug
```

Expected: tests pass, analyzer reports no project issues, and Android debug APK
builds successfully.

### Task 20: Add Zone Manual Checklists

**Files:**
- Modify: `lib/main.dart`
- Modify: `test/widget_test.dart`
- Modify: `README.md`
- Modify: `docs/superpowers/specs/2026-05-22-hotel-privacy-guard-design.md`
- Modify: `docs/superpowers/plans/2026-05-22-hotel-privacy-guard.md`

- [x] **Step 1: Write failing test**

Add a widget test that opens the first sweep zone checklist and expects the
zone-specific title and manual inspection steps to appear.

- [x] **Step 2: Add checklist data to sweep zones**

Extend each room sweep zone with safe manual inspection steps for visual checks
that do not require opening devices or accessing unknown video streams.

- [x] **Step 3: Show checklist action in zone cards**

Add a compact checklist action to each sweep zone row and show the steps in a
bottom sheet so users can review them without leaving the sweep.

- [x] **Step 4: Update product documentation**

Document the zone manual checklists in the README, design spec, and task plan.

- [x] **Step 5: Run verification**

Run:

```powershell
dart format lib test
flutter test
flutter analyze
flutter build apk --debug
```

Expected: tests pass, analyzer reports no project issues, and Android debug APK
builds successfully.

### Task 21: Persist Zone Checklist Step Progress

**Files:**
- Modify: `lib/main.dart`
- Modify: `test/widget_test.dart`
- Modify: `README.md`
- Modify: `docs/superpowers/specs/2026-05-22-hotel-privacy-guard-design.md`
- Modify: `docs/superpowers/plans/2026-05-22-hotel-privacy-guard.md`

- [x] **Step 1: Write failing tests**

Add widget coverage for checking a manual checklist step and snapshot coverage
for encoding/decoding completed step indexes per zone.

- [x] **Step 2: Extend snapshot state**

Store completed checklist step indexes by room zone in the local snapshot while
keeping older snapshots compatible with an empty progress map.

- [x] **Step 3: Make checklist steps interactive**

Render checklist steps as checkbox rows in a scrollable bottom sheet, update
the step count immediately, and save each user change locally.

- [x] **Step 4: Update product documentation**

Document persisted checklist step completion in the README, design spec, and
task plan.

- [x] **Step 5: Run verification**

Run:

```powershell
dart format lib test
flutter test
flutter analyze
flutter build apk --debug
```

Expected: tests pass, analyzer reports no project issues, and Android debug APK
builds successfully.

### Task 22: Add Checklist Progress to Reports

**Files:**
- Modify: `lib/main.dart`
- Modify: `test/widget_test.dart`
- Modify: `README.md`
- Modify: `docs/superpowers/specs/2026-05-22-hotel-privacy-guard-design.md`
- Modify: `docs/superpowers/plans/2026-05-22-hotel-privacy-guard.md`

- [x] **Step 1: Write failing tests**

Add tests for checklist step progress appearing on the Report screen and in
the generated incident report draft.

- [x] **Step 2: Add checklist progress summary helpers**

Calculate valid completed checklist steps across known sweep zones and expose
overall and per-zone progress lines.

- [x] **Step 3: Pass checklist progress through report/export flow**

Pass completed checklist step indexes into `ReportPage`, `ReportExporter`,
`buildReportDraft`, and PDF generation so copied drafts and exported PDFs use
the same report content.

- [x] **Step 4: Update product documentation**

Document report-visible checklist progress in the README, design spec, and
task plan.

- [x] **Step 5: Run verification**

Run:

```powershell
dart format lib test
flutter test
flutter analyze
flutter build apk --debug
```

Expected: tests pass, analyzer reports no project issues, and Android debug APK
builds successfully.

### Task 23: Add Report Coverage Gaps

**Files:**
- Modify: `lib/main.dart`
- Modify: `test/widget_test.dart`
- Modify: `README.md`
- Modify: `docs/superpowers/specs/2026-05-22-hotel-privacy-guard-design.md`
- Modify: `docs/superpowers/plans/2026-05-22-hotel-privacy-guard.md`

- [x] **Step 1: Write failing tests**

Add widget and report-draft tests that expect remaining checklist coverage gaps
to appear after some manual checklist steps are still open.

- [x] **Step 2: Add coverage gap helpers**

Calculate remaining checklist steps across known sweep zones while ignoring
unknown zone ids and out-of-range completed step indexes.

- [x] **Step 3: Show coverage gaps in Report**

Add a compact `Coverage gaps` panel to the Report screen with the remaining
step count and the first visible manual checks to finish.

- [x] **Step 4: Include gaps in report draft/PDF content**

Write the same remaining checklist gap count and per-zone step list into the
incident report draft so PDF export inherits it.

- [x] **Step 5: Update product documentation**

Document report coverage gaps in the README, design spec, and task plan.

- [x] **Step 6: Run verification**

Run:

```powershell
dart format lib test
flutter test
flutter analyze
flutter build apk --debug
```

Expected: tests pass, analyzer reports no project issues, and Android debug APK
builds successfully.

### Task 24: Add Next Suggested Manual Check

**Files:**
- Modify: `lib/main.dart`
- Modify: `test/widget_test.dart`
- Modify: `README.md`
- Modify: `docs/superpowers/specs/2026-05-22-hotel-privacy-guard-design.md`
- Modify: `docs/superpowers/plans/2026-05-22-hotel-privacy-guard.md`

- [x] **Step 1: Write failing tests**

Add widget tests that expect the Sweep screen to show the first remaining
manual checklist step and a completion state when every checklist step is done.

- [x] **Step 2: Reuse coverage gap calculation**

Use the existing remaining checklist gap calculation to select the next
suggested manual check.

- [x] **Step 3: Add Sweep next-check panel**

Show a compact `Next check` panel near the top of the Sweep screen with either
the next zone-specific manual step or the all-complete message.

- [x] **Step 4: Update product documentation**

Document the next suggested manual check in the README, design spec, and task
plan.

- [x] **Step 5: Run verification**

Run:

```powershell
dart format lib test
flutter test
flutter analyze
flutter build apk --debug
```

Expected: tests pass, analyzer reports no project issues, and Android debug APK
builds successfully.

### Task 25: Open Next Suggested Checklist

**Files:**
- Modify: `lib/main.dart`
- Modify: `test/widget_test.dart`
- Modify: `README.md`
- Modify: `docs/superpowers/specs/2026-05-22-hotel-privacy-guard-design.md`
- Modify: `docs/superpowers/plans/2026-05-22-hotel-privacy-guard.md`

- [x] **Step 1: Write failing test**

Add a widget test that taps the `Open` action in the Sweep header and expects
the next suggested zone checklist to appear.

- [x] **Step 2: Reuse checklist bottom sheet**

Extract the zone checklist bottom sheet into a shared helper so both zone cards
and the header action use the same interactive checklist UI.

- [x] **Step 3: Wire the header action**

Extend coverage gaps with zone ids and step indexes, then use the first gap to
open the matching zone checklist from the `Next check` header area.

- [x] **Step 4: Update product documentation**

Document the direct-open next checklist action in the README, design spec, and
task plan.

- [x] **Step 5: Run verification**

Run:

```powershell
dart format lib test
flutter test
flutter analyze
flutter build apk --debug
```

Expected: tests pass, analyzer reports no project issues, and Android debug APK
builds successfully.

### Task 26: Mark Suggested Checklist Step

**Files:**
- Modify: `lib/main.dart`
- Modify: `test/widget_test.dart`
- Modify: `README.md`
- Modify: `docs/superpowers/specs/2026-05-22-hotel-privacy-guard-design.md`
- Modify: `docs/superpowers/plans/2026-05-22-hotel-privacy-guard.md`

- [x] **Step 1: Write failing test**

Extend the `Next check` open test to expect a `Suggested next step` marker in
the opened checklist sheet.

- [x] **Step 2: Pass suggested step index**

Pass the first coverage gap step index into the shared checklist sheet only
when opening through the `Next check` header action.

- [x] **Step 3: Mark the suggested row**

Highlight the matching checklist row and add a small `Suggested next step`
label while preserving the normal zone card checklist behavior.

- [x] **Step 4: Update product documentation**

Document the suggested-step marker in the README, design spec, and task plan.

- [x] **Step 5: Run verification**

Run:

```powershell
dart format lib test
flutter test
flutter analyze
flutter build apk --debug
```

Expected: tests pass, analyzer reports no project issues, and Android debug APK
builds successfully.

### Task 27: Add Report Readiness Checks

**Files:**
- Modify: `lib/main.dart`
- Modify: `test/widget_test.dart`
- Modify: `README.md`
- Modify: `docs/superpowers/specs/2026-05-22-hotel-privacy-guard-design.md`
- Modify: `docs/superpowers/plans/2026-05-22-hotel-privacy-guard.md`

- [x] **Step 1: Write failing tests**

Add report draft and widget tests that expect readiness gaps before sharing,
including missing hotel/room context, unresolved findings, missing evidence
photos, and unfinished manual checks.

- [x] **Step 2: Add readiness model and calculation**

Calculate readiness from stay details, active finding review status, evidence
attachments, and remaining manual checklist coverage while ignoring false
alarms for evidence and review gaps.

- [x] **Step 3: Show readiness on Report**

Add a `Report readiness` panel to the Report screen with either a ready state
or concrete action items to resolve before sharing.

- [x] **Step 4: Include readiness in report drafts**

Write the readiness status and action items into the text report draft so PDF
export inherits the same pre-share checklist.

- [x] **Step 5: Update product documentation**

Document report readiness in the README, design spec, and task plan.

- [x] **Step 6: Run verification**

Run:

```powershell
dart format lib test
flutter test
flutter analyze
flutter build apk --debug
```

Expected: tests pass, analyzer reports no project issues, and Android debug APK
builds successfully.
