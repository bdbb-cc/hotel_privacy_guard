# Hotel Privacy Guard Design

## Goal

Create a Flutter mobile app starter for lawful hotel room privacy checks. The
first version focuses on a guided sweep, visible risk signals, user-reviewed
findings, and evidence report preparation.

## Scope

The app supports room-zone progress, optical and infrared check entry points,
network exposure labeling, findings, and report preparation. It does not open
unknown camera streams, try credentials, bypass permissions, or access devices
without authorization.

## Core Screens

- Sweep: five-minute room sweep with zone progress and risk signal modules.
- Findings: add and review suspected optical, environmental, or network
  exposure items after the user has manually checked them.
- Report: prepare a local-first evidence report for hotel, platform, or
  authority follow-up.

## Implemented MVP Behavior

- Users can mark room zones as checked.
- Each sweep zone exposes a manual checklist with safe visual inspection steps;
  steps avoid opening devices or accessing unknown streams.
- The sweep screen suggests the next remaining manual checklist step and shows
  a complete state once all manual checklist steps are checked. When a next
  step exists, users can open that zone's manual checklist directly from the
  sweep header, with the suggested step visibly marked.
- Users can mark individual checklist steps complete, and step progress is
  restored from local device storage with the rest of the current check.
- The report screen and generated report draft include overall and per-zone
  checklist step progress for manual inspection coverage.
- The report screen and generated report draft list remaining manual checklist
  coverage gaps so users can see which visual checks are still open.
- The report screen and generated report draft show report readiness before
  sharing, including missing hotel/room context, unresolved findings, missing
  evidence photos, and unfinished manual checks.
- Users can add reviewed findings with title, location, signal type, risk level,
  room zone, and notes.
- Users can mark findings as `Needs review`, `Documented`, or `False alarm`.
  False alarms remain in the evidence log but are excluded from risk scoring and
  room risk map flagging.
- Users can delete an individual finding after confirmation when they do not
  want it retained in the current local check.
- Each reviewed finding stores an automatic UTC timestamp that appears in the
  finding log and report draft.
- Users can attach evidence photos through explicit camera or gallery actions.
- The main sweep header and report draft include first-pass Chinese primary
  copy while preserving the existing English operational labels.
- Finding cards show attached evidence filenames without exposing full local
  device paths.
- The current check state is restored from local device storage.
- Users can start a new check after confirmation, clearing the current room's
  zones, findings, and stay details from local storage.
- The app calculates an explainable risk score, recommended next action, and
  visible factor breakdown for active findings, evidence attachments,
  unchecked room coverage, and excluded false alarms.
- The sweep screen displays a compact room risk map from checked zones and
  reviewed findings. New findings use a structured `zoneId`; older findings
  without `zoneId` fall back to title/location inference.
- The report page shows checked-zone and finding counts.
- The report page summarizes findings by review status so unresolved,
  documented, and false-alarm items are visible at a glance.
- The report page captures stay details including hotel, room, booking platform,
  and support contact.
- The report page shows a risk-based action checklist for evidence
  preservation, support requests, and escalation.
- The report page can generate a text incident report draft for copying,
  including generated-at time, review status summary, per-finding review
  status, risk factors, photo attachment counts, attachment filenames without
  full local paths, and recommended actions.
- The report page can export a PDF report file into the app documents
  directory with a bundled Noto Sans SC TrueType font for Chinese report
  content.
- After PDF export, users can open the system share sheet for the report file
  or copy the saved path as a fallback.

## Known Limitation

Chinese localization is currently a first pass. Primary headings and report
labels are localized, while detailed form labels and operational controls still
include English copy.

## Design Notes

The first screen is the usable workflow, not a landing page. Visual tone should
be calm, practical, and trustworthy. Cards are limited to individual tool items
and repeated records.
