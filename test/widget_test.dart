import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:hotel_privacy_guard/main.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('shows the privacy sweep starter screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('酒店隐私守护'), findsOneWidget);
    expect(find.text('5 分钟隐私检查'), findsOneWidget);
    expect(find.text('Hotel Privacy Guard'), findsOneWidget);
    expect(find.text('Room Sweep'), findsOneWidget);
    expect(find.text('Start sweep'), findsOneWidget);
    expect(find.byIcon(Icons.shield_outlined), findsOneWidget);
  });

  testWidgets('navigates to findings and report tabs', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());

    await tester.tap(find.text('Findings'));
    await tester.pumpAndSettle();
    expect(find.text('Findings Log'), findsOneWidget);

    await tester.tap(find.text('Report'));
    await tester.pumpAndSettle();
    expect(find.text('Evidence Report'), findsOneWidget);
  });

  testWidgets('opens a zone-specific manual checklist from the sweep', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());

    await tester.tap(find.widgetWithText(TextButton, 'Checklist').first);
    await tester.pumpAndSettle();

    expect(find.text('Bedside checklist'), findsOneWidget);
    expect(
      find.text('Use a flashlight to look for pinhole reflections.'),
      findsOneWidget,
    );
    expect(
      find.text('Photograph anything suspicious before touching it.'),
      findsOneWidget,
    );
  });

  testWidgets('tracks checklist step completion from the sweep', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());

    await tester.tap(find.widgetWithText(TextButton, 'Checklist').first);
    await tester.pumpAndSettle();

    expect(find.text('0 of 3 steps checked'), findsOneWidget);

    await tester.tap(
      find.widgetWithText(
        CheckboxListTile,
        'Use a flashlight to look for pinhole reflections.',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('1 of 3 steps checked'), findsOneWidget);

    final prefs = await SharedPreferences.getInstance();
    final saved = decodePrivacyCheckSnapshot(
      prefs.getString(privacyCheckStorageKey)!,
    );

    expect(saved.completedChecklistStepIndexesByZone['bedside'], contains(1));
  });

  testWidgets('shows the next suggested manual check on the sweep', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Next check'), findsOneWidget);
    expect(
      find.text(
        'Bedside: Scan lamps, outlets, hooks, and clocks from eye level.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('opens the next suggested checklist from the sweep header', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());

    await tester.tap(find.widgetWithText(TextButton, 'Open'));
    await tester.pumpAndSettle();

    expect(find.text('Bedside checklist'), findsOneWidget);
    expect(
      find.text('Scan lamps, outlets, hooks, and clocks from eye level.'),
      findsOneWidget,
    );
    expect(find.text('Suggested next step'), findsOneWidget);
  });

  testWidgets(
    'shows complete next-check state when all checklist steps are done',
    (WidgetTester tester) async {
      final encoded = encodePrivacyCheckSnapshot(
        const PrivacyCheckSnapshot(
          completedZoneIds: {
            'bedside',
            'tv_wall',
            'ceiling',
            'bathroom',
            'desk',
          },
          completedChecklistStepIndexesByZone: {
            'bedside': {0, 1, 2},
            'tv_wall': {0, 1, 2},
            'ceiling': {0, 1, 2},
            'bathroom': {0, 1, 2},
            'desk': {0, 1, 2},
          },
          findings: [],
        ),
      );
      SharedPreferences.setMockInitialValues({privacyCheckStorageKey: encoded});

      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      expect(find.text('Next check'), findsOneWidget);
      expect(
        find.text('All manual checklist steps are complete'),
        findsOneWidget,
      );
    },
  );

  testWidgets('shows checklist progress on the report screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());

    await tester.tap(find.widgetWithText(TextButton, 'Checklist').first);
    await tester.pumpAndSettle();
    await tester.tap(
      find.widgetWithText(
        CheckboxListTile,
        'Use a flashlight to look for pinhole reflections.',
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Report'));
    await tester.pumpAndSettle();

    expect(find.text('Checklist steps: 1 of 15 checked'), findsOneWidget);
  });

  testWidgets('shows remaining checklist coverage gaps on the report screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());

    await tester.tap(find.widgetWithText(TextButton, 'Checklist').first);
    await tester.pumpAndSettle();
    await tester.tap(
      find.widgetWithText(
        CheckboxListTile,
        'Use a flashlight to look for pinhole reflections.',
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Report'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Coverage gaps'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('Coverage gaps'), findsOneWidget);
    expect(find.text('14 checklist steps remaining'), findsOneWidget);
    expect(
      find.text(
        'Bedside: Scan lamps, outlets, hooks, and clocks from eye level.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('adds a reviewed finding and includes it in the report', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());

    await tester.tap(find.text('Findings'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add finding'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('finding-title-field')),
      'Mirror pinhole reflection',
    );
    await tester.enterText(
      find.byKey(const Key('finding-location-field')),
      'Bathroom mirror upper right',
    );
    await tester.tap(find.text('High'));
    await tester.pump();
    await tester.tap(find.text('Save finding'));
    await tester.pumpAndSettle();

    expect(find.text('Mirror pinhole reflection'), findsOneWidget);
    expect(find.text('Bathroom mirror upper right'), findsOneWidget);

    await tester.tap(find.text('Report'));
    await tester.pumpAndSettle();

    expect(find.text('1 reviewed finding'), findsOneWidget);
  });

  testWidgets('builds a report draft from checked zones and findings', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());

    await tester.tap(find.text('Bedside'));
    await tester.pump();

    await tester.tap(find.text('Findings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add finding'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('finding-title-field')),
      'Mirror pinhole reflection',
    );
    await tester.enterText(
      find.byKey(const Key('finding-location-field')),
      'Bathroom mirror upper right',
    );
    await tester.tap(find.text('High'));
    await tester.pump();
    await tester.tap(find.text('Save finding'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Report'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Build report'));
    await tester.pumpAndSettle();

    expect(find.text('Incident report draft'), findsOneWidget);
    expect(find.textContaining('Checked zones: Bedside'), findsOneWidget);
    expect(
      find.textContaining('High - Mirror pinhole reflection'),
      findsOneWidget,
    );
  });

  test('report draft includes evidence attachment counts', () {
    final draft = buildReportDraft(
      completedZoneIds: const {'bedside'},
      findings: const [
        Finding(
          title: 'Outlet lens reflection',
          location: 'Bedside outlet',
          type: FindingType(
            label: 'Optical reflection',
            icon: Icons.radio_button_checked,
          ),
          risk: RiskLevel.high,
          notes: 'Tiny reflection inside lower socket.',
          evidencePaths: ['evidence/outlet.jpg'],
        ),
      ],
    );

    expect(draft, contains('Photo attachments: 1'));
    expect(draft, contains('High - Outlet lens reflection'));
  });

  test(
    'report draft lists evidence attachment filenames without local paths',
    () {
      final draft = buildReportDraft(
        completedZoneIds: const {'bedside'},
        findings: const [
          Finding(
            title: 'Outlet lens reflection',
            location: 'Bedside outlet',
            type: FindingType(
              label: 'Optical reflection',
              icon: Icons.radio_button_checked,
            ),
            risk: RiskLevel.high,
            notes: '',
            evidencePaths: [
              r'C:\Users\wxg\Pictures\outlet.jpg',
              'evidence/mirror-close.png',
            ],
          ),
        ],
      );

      expect(draft, contains('Attachment files: outlet.jpg, mirror-close.png'));
      expect(draft, isNot(contains(r'C:\Users\wxg\Pictures')));
    },
  );

  testWidgets('attaches an evidence photo to a finding', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MyApp(evidencePicker: FakeEvidencePicker('evidence/mirror.jpg')),
    );

    await tester.tap(find.text('Findings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add finding'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Take photo'));
    await tester.pumpAndSettle();
    expect(find.text('1 photo attached'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('finding-title-field')),
      'Mirror pinhole reflection',
    );
    await tester.enterText(
      find.byKey(const Key('finding-location-field')),
      'Bathroom mirror upper right',
    );
    await tester.tap(find.text('Save finding'));
    await tester.pumpAndSettle();

    expect(find.text('1 photo'), findsOneWidget);

    await tester.tap(find.text('Report'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Build report'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Photo attachments: 1'), findsOneWidget);
  });

  test('encodes and decodes local privacy check snapshots', () {
    final encoded = encodePrivacyCheckSnapshot(
      const PrivacyCheckSnapshot(
        completedZoneIds: {'bedside'},
        completedChecklistStepIndexesByZone: {
          'bedside': {1, 2},
        },
        findings: [
          Finding(
            title: 'Outlet lens reflection',
            location: 'Bedside outlet',
            type: FindingType(
              label: 'Optical reflection',
              icon: Icons.radio_button_checked,
            ),
            risk: RiskLevel.high,
            notes: 'Tiny reflection inside lower socket.',
            evidencePaths: ['evidence/outlet.jpg'],
          ),
        ],
      ),
    );

    final decoded = decodePrivacyCheckSnapshot(encoded);

    expect(decoded.completedZoneIds, contains('bedside'));
    expect(decoded.completedChecklistStepIndexesByZone['bedside'], {1, 2});
    expect(decoded.findings.single.title, 'Outlet lens reflection');
    expect(decoded.findings.single.evidencePaths.single, 'evidence/outlet.jpg');
  });

  test('preserves finding timestamps and includes them in report drafts', () {
    final encoded = jsonEncode({
      'completedZoneIds': ['bedside'],
      'findings': [
        {
          'title': 'Outlet lens reflection',
          'location': 'Bedside outlet',
          'zoneId': 'bedside',
          'createdAtIso': '2026-05-22T13:45:00.000Z',
          'typeLabel': 'Optical reflection',
          'risk': 'high',
          'notes': 'Tiny reflection inside lower socket.',
          'evidencePaths': ['evidence/outlet.jpg'],
        },
      ],
    });

    final decoded = decodePrivacyCheckSnapshot(encoded);
    final roundTripped = encodePrivacyCheckSnapshot(decoded);
    final draft = buildReportDraft(
      completedZoneIds: decoded.completedZoneIds,
      findings: decoded.findings,
    );

    expect(roundTripped, contains('createdAtIso'));
    expect(roundTripped, contains('2026-05-22T13:45:00.000Z'));
    expect(draft, contains('Recorded at: 2026-05-22 13:45 UTC'));
  });

  test('high risk report draft includes an escalation action checklist', () {
    final draft = buildReportDraft(
      completedZoneIds: const {'bathroom'},
      findings: const [
        Finding(
          title: 'Mirror pinhole reflection',
          location: 'Bathroom mirror upper right',
          zoneId: 'bathroom',
          type: FindingType(
            label: 'Optical reflection',
            icon: Icons.radio_button_checked,
          ),
          risk: RiskLevel.high,
          notes: '',
          evidencePaths: ['evidence/mirror.jpg'],
        ),
      ],
    );

    expect(draft, contains('Recommended actions:'));
    expect(draft, contains('Do not touch or remove the suspected object.'));
    expect(
      draft,
      contains('Ask the hotel or platform for a written incident note.'),
    );
  });

  test('report draft includes risk factor breakdown', () {
    final draft = buildReportDraft(
      completedZoneIds: const {'bedside', 'bathroom'},
      findings: const [
        Finding(
          title: 'Outlet lens reflection',
          location: 'Bedside outlet',
          type: FindingType(
            label: 'Optical reflection',
            icon: Icons.radio_button_checked,
          ),
          risk: RiskLevel.medium,
          notes: '',
          evidencePaths: ['evidence/outlet.jpg'],
        ),
        Finding(
          title: 'Mirror pinhole reflection',
          location: 'Bathroom mirror upper right',
          type: FindingType(
            label: 'Optical reflection',
            icon: Icons.radio_button_checked,
          ),
          risk: RiskLevel.high,
          notes: '',
          evidencePaths: ['evidence/mirror.jpg', 'evidence/mirror-close.jpg'],
        ),
        Finding(
          title: 'Chrome screw reflection',
          location: 'Desk lamp base',
          reviewStatus: ReviewStatus.falseAlarm,
          type: FindingType(
            label: 'Optical reflection',
            icon: Icons.radio_button_checked,
          ),
          risk: RiskLevel.high,
          notes: '',
          evidencePaths: ['evidence/lamp.jpg'],
        ),
      ],
    );

    expect(draft, contains('Risk factors:'));
    expect(draft, contains('- Active findings: 2'));
    expect(draft, contains('- Evidence attachments: 3'));
    expect(draft, contains('- Unchecked zones: 3 of 5'));
    expect(draft, contains('- False alarms excluded: 1'));
    expect(draft, isNot(contains('- Evidence attachments: 4')));
  });

  test('report draft includes checklist progress', () {
    final draft = buildReportDraft(
      completedZoneIds: const {'bedside'},
      completedChecklistStepIndexesByZone: const {
        'bedside': {0, 1},
        'desk': {0},
        'unknown': {99},
      },
      findings: const [],
    );

    expect(draft, contains('Checklist progress: 3 of 15 steps checked'));
    expect(draft, contains('- Bedside: 2 of 3 steps checked'));
    expect(draft, contains('- Desk area: 1 of 3 steps checked'));
    expect(draft, isNot(contains('- unknown')));
  });

  test('report draft includes remaining checklist coverage gaps', () {
    final draft = buildReportDraft(
      completedZoneIds: const {'bedside'},
      completedChecklistStepIndexesByZone: const {
        'bedside': {0, 1},
        'desk': {0},
      },
      findings: const [],
    );

    expect(draft, contains('Coverage gaps:'));
    expect(draft, contains('Remaining checklist steps: 12'));
    expect(
      draft,
      contains('- Bedside: Photograph anything suspicious before touching it.'),
    );
    expect(
      draft,
      contains(
        '- Desk area: Look for unexpected indicator lights, holes, or mismatched objects.',
      ),
    );
  });

  test('report draft includes share readiness gaps', () {
    final draft = buildReportDraft(
      completedZoneIds: const {},
      findings: const [
        Finding(
          title: 'Mirror pinhole reflection',
          location: 'Bathroom mirror upper right',
          zoneId: 'bathroom',
          type: FindingType(
            label: 'Optical reflection',
            icon: Icons.radio_button_checked,
          ),
          risk: RiskLevel.high,
          notes: '',
          evidencePaths: [],
        ),
      ],
    );

    expect(draft, contains('Report readiness:'));
    expect(draft, contains('Needs attention'));
    expect(
      draft,
      contains(
        '- Add hotel and room: Add the hotel name and room number before sharing.',
      ),
    );
    expect(
      draft,
      contains('- Review unresolved findings: 1 finding still needs review.'),
    );
    expect(
      draft,
      contains(
        '- Attach evidence photos: 1 active finding has no evidence photo.',
      ),
    );
    expect(
      draft,
      contains('- Finish manual checks: 15 checklist steps still open.'),
    );
  });

  test('report draft includes stay details when provided', () {
    final draft = buildReportDraft(
      completedZoneIds: const {'bedside'},
      findings: const [],
      stayDetails: const StayDetails(
        hotelName: 'Harbor Hotel',
        roomNumber: '1806',
        bookingPlatform: 'TripGo',
        supportContact: 'Front desk Maya',
      ),
    );

    expect(draft, contains('Stay details:'));
    expect(draft, contains('Hotel: Harbor Hotel'));
    expect(draft, contains('Room: 1806'));
    expect(draft, contains('Booking/platform: TripGo'));
    expect(draft, contains('Support contact: Front desk Maya'));
  });

  test('report draft includes the generated timestamp', () {
    final draft = buildReportDraft(
      completedZoneIds: const {'bedside'},
      findings: const [],
      generatedAtIso: '2026-05-23T10:30:00.000Z',
    );

    expect(draft, contains('酒店隐私检查报告'));
    expect(draft, contains('生成时间：2026-05-23 10:30 UTC'));
    expect(draft, contains('风险分数：0'));
    expect(draft, contains('Generated at: 2026-05-23 10:30 UTC'));
  });

  test('encodes and decodes stay details in local snapshots', () {
    final encoded = encodePrivacyCheckSnapshot(
      const PrivacyCheckSnapshot(
        completedZoneIds: {'bedside'},
        stayDetails: StayDetails(
          hotelName: 'Harbor Hotel',
          roomNumber: '1806',
          bookingPlatform: 'TripGo',
          supportContact: 'Front desk Maya',
        ),
        findings: [],
      ),
    );

    final decoded = decodePrivacyCheckSnapshot(encoded);

    expect(decoded.stayDetails.hotelName, 'Harbor Hotel');
    expect(decoded.stayDetails.roomNumber, '1806');
    expect(decoded.stayDetails.bookingPlatform, 'TripGo');
    expect(decoded.stayDetails.supportContact, 'Front desk Maya');
  });

  test('encodes finding review status and includes it in report drafts', () {
    final encoded = encodePrivacyCheckSnapshot(
      const PrivacyCheckSnapshot(
        completedZoneIds: {'bathroom'},
        findings: [
          Finding(
            title: 'Mirror pinhole reflection',
            location: 'Bathroom mirror upper right',
            zoneId: 'bathroom',
            reviewStatus: ReviewStatus.documented,
            type: FindingType(
              label: 'Optical reflection',
              icon: Icons.radio_button_checked,
            ),
            risk: RiskLevel.high,
            notes: '',
            evidencePaths: ['evidence/mirror.jpg'],
          ),
        ],
      ),
    );

    final decoded = decodePrivacyCheckSnapshot(encoded);
    final draft = buildReportDraft(
      completedZoneIds: decoded.completedZoneIds,
      findings: decoded.findings,
    );

    expect(decoded.findings.single.reviewStatus, ReviewStatus.documented);
    expect(draft, contains('Review status: Documented'));
  });

  test('report draft includes a review status summary', () {
    final draft = buildReportDraft(
      completedZoneIds: const {'bedside'},
      findings: const [
        Finding(
          title: 'Outlet lens reflection',
          location: 'Bedside outlet',
          reviewStatus: ReviewStatus.needsReview,
          type: FindingType(
            label: 'Optical reflection',
            icon: Icons.radio_button_checked,
          ),
          risk: RiskLevel.medium,
          notes: '',
          evidencePaths: [],
        ),
        Finding(
          title: 'Mirror pinhole reflection',
          location: 'Bathroom mirror upper right',
          reviewStatus: ReviewStatus.documented,
          type: FindingType(
            label: 'Optical reflection',
            icon: Icons.radio_button_checked,
          ),
          risk: RiskLevel.high,
          notes: '',
          evidencePaths: ['evidence/mirror.jpg'],
        ),
        Finding(
          title: 'Chrome screw reflection',
          location: 'Desk lamp base',
          reviewStatus: ReviewStatus.falseAlarm,
          type: FindingType(
            label: 'Optical reflection',
            icon: Icons.radio_button_checked,
          ),
          risk: RiskLevel.low,
          notes: '',
          evidencePaths: [],
        ),
      ],
    );

    expect(draft, contains('Review summary:'));
    expect(draft, contains('Needs review: 1'));
    expect(draft, contains('Documented: 1'));
    expect(draft, contains('False alarm: 1'));
  });

  test('false alarm findings do not raise the risk score', () {
    final summary = calculateRiskSummary(
      completedZoneIds: const {'bedside'},
      findings: const [
        Finding(
          title: 'Outlet lens reflection',
          location: 'Bedside outlet',
          zoneId: 'bedside',
          reviewStatus: ReviewStatus.falseAlarm,
          type: FindingType(
            label: 'Optical reflection',
            icon: Icons.radio_button_checked,
          ),
          risk: RiskLevel.high,
          notes: '',
          evidencePaths: ['evidence/outlet.jpg'],
        ),
      ],
    );

    expect(summary.score, 0);
    expect(summary.band, RiskBand.baseline);
  });

  test('decodes malformed local snapshots as empty state', () {
    final decoded = decodePrivacyCheckSnapshot('not-json');

    expect(decoded.completedZoneIds, isEmpty);
    expect(decoded.findings, isEmpty);
  });

  testWidgets('restores saved zones and findings from local storage', (
    WidgetTester tester,
  ) async {
    final encoded = encodePrivacyCheckSnapshot(
      const PrivacyCheckSnapshot(
        completedZoneIds: {'bedside'},
        findings: [
          Finding(
            title: 'Outlet lens reflection',
            location: 'Bedside outlet',
            type: FindingType(
              label: 'Optical reflection',
              icon: Icons.radio_button_checked,
            ),
            risk: RiskLevel.high,
            notes: '',
            evidencePaths: ['evidence/outlet.jpg'],
          ),
        ],
      ),
    );
    SharedPreferences.setMockInitialValues({privacyCheckStorageKey: encoded});

    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.text('20% complete'), findsOneWidget);

    await tester.tap(find.text('Findings'));
    await tester.pumpAndSettle();

    expect(find.text('Outlet lens reflection'), findsOneWidget);
    expect(find.text('1 photo'), findsOneWidget);
  });

  testWidgets('finding cards list evidence filenames without local paths', (
    WidgetTester tester,
  ) async {
    final encoded = encodePrivacyCheckSnapshot(
      const PrivacyCheckSnapshot(
        completedZoneIds: {'bedside'},
        findings: [
          Finding(
            title: 'Outlet lens reflection',
            location: 'Bedside outlet',
            type: FindingType(
              label: 'Optical reflection',
              icon: Icons.radio_button_checked,
            ),
            risk: RiskLevel.high,
            notes: '',
            evidencePaths: [
              r'C:\Users\wxg\Pictures\outlet.jpg',
              'evidence/mirror-close.png',
            ],
          ),
        ],
      ),
    );
    SharedPreferences.setMockInitialValues({privacyCheckStorageKey: encoded});

    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Findings'));
    await tester.pumpAndSettle();

    expect(find.text('2 photos'), findsOneWidget);
    expect(find.text('Files: outlet.jpg, mirror-close.png'), findsOneWidget);
    expect(find.textContaining(r'C:\Users\wxg\Pictures'), findsNothing);
  });

  testWidgets('starts a new check and clears saved room state', (
    WidgetTester tester,
  ) async {
    final encoded = encodePrivacyCheckSnapshot(
      const PrivacyCheckSnapshot(
        completedZoneIds: {'bedside'},
        stayDetails: StayDetails(
          hotelName: 'Harbor Hotel',
          roomNumber: '1806',
          bookingPlatform: 'TripGo',
          supportContact: 'Front desk Maya',
        ),
        findings: [
          Finding(
            title: 'Outlet lens reflection',
            location: 'Bedside outlet',
            zoneId: 'bedside',
            type: FindingType(
              label: 'Optical reflection',
              icon: Icons.radio_button_checked,
            ),
            risk: RiskLevel.high,
            notes: '',
            evidencePaths: ['evidence/outlet.jpg'],
          ),
        ],
      ),
    );
    SharedPreferences.setMockInitialValues({privacyCheckStorageKey: encoded});

    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.text('20% complete'), findsOneWidget);

    await tester.tap(find.byTooltip('New check'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start new check'));
    await tester.pumpAndSettle();

    expect(find.text('0% complete'), findsOneWidget);

    await tester.tap(find.text('Findings'));
    await tester.pumpAndSettle();
    expect(find.text('No findings yet'), findsOneWidget);

    await tester.tap(find.text('Report'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('stay-hotel-field')),
      180,
      scrollable: find.byType(Scrollable).first,
    );
    final hotelField = tester.widget<TextField>(
      find.byKey(const Key('stay-hotel-field')),
    );
    expect(hotelField.controller?.text, isEmpty);

    final prefs = await SharedPreferences.getInstance();
    final saved = decodePrivacyCheckSnapshot(
      prefs.getString(privacyCheckStorageKey) ?? '',
    );
    expect(saved.completedZoneIds, isEmpty);
    expect(saved.findings, isEmpty);
    expect(saved.stayDetails.hasAny, isFalse);
  });

  testWidgets('deletes a finding after confirmation and persists the removal', (
    WidgetTester tester,
  ) async {
    final encoded = encodePrivacyCheckSnapshot(
      const PrivacyCheckSnapshot(
        completedZoneIds: {'bedside'},
        findings: [
          Finding(
            title: 'Outlet lens reflection',
            location: 'Bedside outlet',
            zoneId: 'bedside',
            type: FindingType(
              label: 'Optical reflection',
              icon: Icons.radio_button_checked,
            ),
            risk: RiskLevel.high,
            notes: '',
            evidencePaths: ['evidence/outlet.jpg'],
          ),
        ],
      ),
    );
    SharedPreferences.setMockInitialValues({privacyCheckStorageKey: encoded});

    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Findings'));
    await tester.pumpAndSettle();
    expect(find.text('Outlet lens reflection'), findsOneWidget);

    await tester.tap(find.byTooltip('Delete finding'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete finding').last);
    await tester.pumpAndSettle();

    expect(find.text('No findings yet'), findsOneWidget);
    expect(find.text('Outlet lens reflection'), findsNothing);

    final prefs = await SharedPreferences.getInstance();
    final saved = decodePrivacyCheckSnapshot(
      prefs.getString(privacyCheckStorageKey) ?? '',
    );
    expect(saved.findings, isEmpty);
  });

  testWidgets('restores and displays a finding recorded timestamp', (
    WidgetTester tester,
  ) async {
    final encoded = jsonEncode({
      'completedZoneIds': ['bedside'],
      'findings': [
        {
          'title': 'Outlet lens reflection',
          'location': 'Bedside outlet',
          'zoneId': 'bedside',
          'createdAtIso': '2026-05-22T13:45:00.000Z',
          'typeLabel': 'Optical reflection',
          'risk': 'high',
          'notes': '',
          'evidencePaths': ['evidence/outlet.jpg'],
        },
      ],
    });
    SharedPreferences.setMockInitialValues({privacyCheckStorageKey: encoded});

    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Findings'));
    await tester.pumpAndSettle();

    expect(find.text('Recorded: 2026-05-22 13:45 UTC'), findsOneWidget);
  });

  test('calculates an elevated risk summary from findings and coverage', () {
    final summary = calculateRiskSummary(
      completedZoneIds: const {'bedside', 'bathroom'},
      findings: const [
        Finding(
          title: 'Outlet lens reflection',
          location: 'Bedside outlet',
          type: FindingType(
            label: 'Optical reflection',
            icon: Icons.radio_button_checked,
          ),
          risk: RiskLevel.medium,
          notes: '',
          evidencePaths: ['evidence/outlet.jpg'],
        ),
        Finding(
          title: 'Mirror pinhole reflection',
          location: 'Bathroom mirror upper right',
          type: FindingType(
            label: 'Optical reflection',
            icon: Icons.radio_button_checked,
          ),
          risk: RiskLevel.high,
          notes: '',
          evidencePaths: ['evidence/mirror.jpg', 'evidence/mirror-close.jpg'],
        ),
      ],
    );

    expect(summary.band, RiskBand.high);
    expect(summary.score, 89);
    expect(summary.uncheckedZoneCount, 3);
    expect(summary.primaryAction, contains('Preserve evidence'));
  });

  testWidgets('shows risk summary on the sweep and report screens', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Risk baseline'), findsOneWidget);

    await tester.tap(find.text('Findings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add finding'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('finding-title-field')),
      'Mirror pinhole reflection',
    );
    await tester.enterText(
      find.byKey(const Key('finding-location-field')),
      'Bathroom mirror upper right',
    );
    await tester.tap(find.text('High'));
    await tester.pump();
    await tester.tap(find.text('Save finding'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Sweep'));
    await tester.pumpAndSettle();
    expect(find.text('High risk'), findsOneWidget);

    await tester.tap(find.text('Report'));
    await tester.pumpAndSettle();
    expect(find.text('Risk score 62'), findsOneWidget);
  });

  testWidgets('shows risk factor breakdown on the report screen', (
    WidgetTester tester,
  ) async {
    final encoded = encodePrivacyCheckSnapshot(
      const PrivacyCheckSnapshot(
        completedZoneIds: {'bedside'},
        findings: [
          Finding(
            title: 'Outlet lens reflection',
            location: 'Bedside outlet',
            type: FindingType(
              label: 'Optical reflection',
              icon: Icons.radio_button_checked,
            ),
            risk: RiskLevel.high,
            notes: '',
            evidencePaths: ['evidence/outlet.jpg', 'evidence/outlet-close.jpg'],
          ),
          Finding(
            title: 'Chrome screw reflection',
            location: 'Desk lamp base',
            reviewStatus: ReviewStatus.falseAlarm,
            type: FindingType(
              label: 'Optical reflection',
              icon: Icons.radio_button_checked,
            ),
            risk: RiskLevel.medium,
            notes: '',
            evidencePaths: ['evidence/lamp.jpg'],
          ),
        ],
      ),
    );
    SharedPreferences.setMockInitialValues({privacyCheckStorageKey: encoded});

    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Report'));
    await tester.pumpAndSettle();

    expect(find.text('Risk factors'), findsOneWidget);
    expect(find.text('Active findings: 1'), findsOneWidget);
    expect(find.text('Evidence attachments: 2'), findsOneWidget);
    expect(find.text('Unchecked zones: 4 of 5'), findsOneWidget);
    expect(find.text('False alarms excluded: 1'), findsOneWidget);
  });

  testWidgets('shows a high risk action checklist on the report screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());

    await tester.tap(find.text('Findings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add finding'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('finding-title-field')),
      'Mirror pinhole reflection',
    );
    await tester.enterText(
      find.byKey(const Key('finding-location-field')),
      'Bathroom mirror upper right',
    );
    await tester.tap(find.text('High'));
    await tester.pump();
    await tester.tap(find.text('Save finding'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Report'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Action checklist'),
      220,
      scrollable: find.byType(Scrollable).first,
    );

    expect(find.text('Action checklist'), findsOneWidget);
    expect(find.text('Preserve the scene'), findsOneWidget);
    expect(find.text('Request written support'), findsOneWidget);
  });

  testWidgets('shows report readiness gaps on the report screen', (
    WidgetTester tester,
  ) async {
    final encoded = encodePrivacyCheckSnapshot(
      const PrivacyCheckSnapshot(
        completedZoneIds: {},
        findings: [
          Finding(
            title: 'Mirror pinhole reflection',
            location: 'Bathroom mirror upper right',
            zoneId: 'bathroom',
            type: FindingType(
              label: 'Optical reflection',
              icon: Icons.radio_button_checked,
            ),
            risk: RiskLevel.high,
            notes: '',
            evidencePaths: [],
          ),
        ],
      ),
    );
    SharedPreferences.setMockInitialValues({privacyCheckStorageKey: encoded});

    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Report'));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView).last, const Offset(0, -520));
    await tester.pumpAndSettle();

    expect(find.text('Report readiness'), findsOneWidget);
    expect(find.text('Needs attention'), findsOneWidget);
    expect(find.text('Add hotel and room'), findsOneWidget);
    expect(find.text('Attach evidence photos'), findsOneWidget);
    expect(find.text('Finish manual checks'), findsOneWidget);
  });

  testWidgets('shows a review status summary on the report screen', (
    WidgetTester tester,
  ) async {
    final encoded = encodePrivacyCheckSnapshot(
      const PrivacyCheckSnapshot(
        completedZoneIds: {'bedside'},
        findings: [
          Finding(
            title: 'Outlet lens reflection',
            location: 'Bedside outlet',
            reviewStatus: ReviewStatus.needsReview,
            type: FindingType(
              label: 'Optical reflection',
              icon: Icons.radio_button_checked,
            ),
            risk: RiskLevel.medium,
            notes: '',
            evidencePaths: [],
          ),
          Finding(
            title: 'Mirror pinhole reflection',
            location: 'Bathroom mirror upper right',
            reviewStatus: ReviewStatus.documented,
            type: FindingType(
              label: 'Optical reflection',
              icon: Icons.radio_button_checked,
            ),
            risk: RiskLevel.high,
            notes: '',
            evidencePaths: ['evidence/mirror.jpg'],
          ),
          Finding(
            title: 'Chrome screw reflection',
            location: 'Desk lamp base',
            reviewStatus: ReviewStatus.falseAlarm,
            type: FindingType(
              label: 'Optical reflection',
              icon: Icons.radio_button_checked,
            ),
            risk: RiskLevel.low,
            notes: '',
            evidencePaths: [],
          ),
        ],
      ),
    );
    SharedPreferences.setMockInitialValues({privacyCheckStorageKey: encoded});

    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Report'));
    await tester.pumpAndSettle();

    expect(find.text('Review summary'), findsOneWidget);
    expect(find.text('Needs review 1'), findsOneWidget);
    expect(find.text('Documented 1'), findsOneWidget);
    expect(find.text('False alarm 1'), findsOneWidget);
  });

  testWidgets(
    'saves stay details from the report screen into the report draft',
    (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());

      await tester.tap(find.text('Report'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byKey(const Key('stay-hotel-field')),
        180,
        scrollable: find.byType(Scrollable).first,
      );

      await tester.enterText(
        find.byKey(const Key('stay-hotel-field')),
        'Harbor Hotel',
      );
      await tester.enterText(find.byKey(const Key('stay-room-field')), '1806');
      await tester.enterText(
        find.byKey(const Key('stay-platform-field')),
        'TripGo',
      );
      await tester.enterText(
        find.byKey(const Key('stay-contact-field')),
        'Front desk Maya',
      );
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Build report'),
        -220,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Build report'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Hotel: Harbor Hotel'), findsOneWidget);
      expect(find.textContaining('Room: 1806'), findsOneWidget);
      expect(find.textContaining('Booking/platform: TripGo'), findsOneWidget);
      expect(
        find.textContaining('Support contact: Front desk Maya'),
        findsOneWidget,
      );
    },
  );

  testWidgets('updates finding review status and includes it in the report', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());

    await tester.tap(find.text('Findings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add finding'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('finding-title-field')),
      'Mirror pinhole reflection',
    );
    await tester.enterText(
      find.byKey(const Key('finding-location-field')),
      'Bathroom mirror upper right',
    );
    await tester.tap(find.text('Save finding'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ChoiceChip, 'Documented'));
    await tester.pumpAndSettle();

    expect(find.text('Status: Documented'), findsOneWidget);

    await tester.tap(find.text('Report'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Build report'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Review status: Documented'), findsOneWidget);
  });

  test('classifies room zones as flagged checked or unchecked', () {
    final statuses = calculateZoneRiskStatuses(
      completedZoneIds: const {'bedside', 'tv_wall'},
      findings: const [
        Finding(
          title: 'Mirror pinhole reflection',
          location: 'Bathroom mirror upper right',
          type: FindingType(
            label: 'Optical reflection',
            icon: Icons.radio_button_checked,
          ),
          risk: RiskLevel.high,
          notes: '',
          evidencePaths: [],
        ),
      ],
    );

    expect(statuses['bathroom'], ZoneRiskState.flagged);
    expect(statuses['bedside'], ZoneRiskState.checked);
    expect(statuses['ceiling'], ZoneRiskState.unchecked);
  });

  test('uses structured finding zone before title and location guessing', () {
    final statuses = calculateZoneRiskStatuses(
      completedZoneIds: const {},
      findings: const [
        Finding(
          title: 'Tiny reflection',
          location: 'Upper right corner',
          zoneId: 'bathroom',
          type: FindingType(
            label: 'Optical reflection',
            icon: Icons.radio_button_checked,
          ),
          risk: RiskLevel.high,
          notes: '',
          evidencePaths: [],
        ),
      ],
    );

    expect(statuses['bathroom'], ZoneRiskState.flagged);
  });

  testWidgets('saves the selected room zone with a finding', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());

    await tester.tap(find.text('Findings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add finding'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('finding-zone-field')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bathroom').last);
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('finding-title-field')),
      'Tiny reflection',
    );
    await tester.enterText(
      find.byKey(const Key('finding-location-field')),
      'Upper right corner',
    );
    await tester.tap(find.text('Save finding'));
    await tester.pumpAndSettle();

    expect(find.text('Zone: Bathroom'), findsOneWidget);

    await tester.tap(find.text('Sweep'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Bathroom: Flagged'),
      180,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Bathroom: Flagged'), findsOneWidget);
  });

  test('builds a non-empty PDF report document', () async {
    final bytes = await buildReportPdfBytes(
      completedZoneIds: const {'bedside'},
      findings: const [
        Finding(
          title: 'Outlet lens reflection',
          location: 'Bedside outlet',
          type: FindingType(
            label: 'Optical reflection',
            icon: Icons.radio_button_checked,
          ),
          risk: RiskLevel.high,
          notes: 'Tiny reflection inside lower socket.',
          evidencePaths: ['evidence/outlet.jpg'],
        ),
      ],
    );

    expect(bytes.length, greaterThan(800));
    expect(String.fromCharCodes(bytes.take(4)), '%PDF');
  });

  test('embeds a CJK PDF font for Chinese report content', () async {
    final bytes = await buildReportPdfBytes(
      completedZoneIds: const {'bedside'},
      stayDetails: const StayDetails(
        hotelName: '海港酒店',
        roomNumber: '1806',
        bookingPlatform: '携程',
        supportContact: '前台小林',
      ),
      findings: const [
        Finding(
          title: '插座内有异常反光点',
          location: '床头插座',
          type: FindingType(label: '光学反光', icon: Icons.radio_button_checked),
          risk: RiskLevel.high,
          notes: '下方插孔内有细小反光。',
          evidencePaths: ['evidence/outlet.jpg'],
        ),
      ],
      generatedAtIso: '2026-05-23T10:30:00.000Z',
    );
    final pdfText = latin1.decode(bytes, allowInvalid: true);

    expect(String.fromCharCodes(bytes.take(4)), '%PDF');
    expect(pdfText, contains('NotoSansSC'));
    expect(pdfText, isNot(contains('/Helvetica')));
  });

  testWidgets('exports a PDF report from the report screen', (
    WidgetTester tester,
  ) async {
    final reportSharer = FakeReportSharer();

    await tester.pumpWidget(
      MyApp(
        reportExporter: FakeReportExporter('tmp/privacy-check.pdf'),
        reportSharer: reportSharer,
      ),
    );

    await tester.tap(find.text('Report'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Export PDF'));
    await tester.pumpAndSettle();

    expect(find.text('PDF report ready'), findsOneWidget);
    expect(find.text('tmp/privacy-check.pdf'), findsOneWidget);
    expect(find.text('Share PDF'), findsOneWidget);

    await tester.tap(find.text('Share PDF'));
    await tester.pumpAndSettle();

    expect(reportSharer.sharedPath, 'tmp/privacy-check.pdf');
    expect(find.text('PDF share opened'), findsOneWidget);
  });
}

class FakeEvidencePicker implements EvidencePicker {
  const FakeEvidencePicker(this.path);

  final String path;

  @override
  Future<String?> pickFromCamera() async => path;

  @override
  Future<String?> pickFromGallery() async => path;
}

class FakeReportExporter implements ReportExporter {
  const FakeReportExporter(this.path);

  final String path;

  @override
  Future<ExportedReport> export({
    required Set<String> completedZoneIds,
    required Map<String, Set<int>> completedChecklistStepIndexesByZone,
    required List<Finding> findings,
    required StayDetails stayDetails,
  }) async {
    return ExportedReport(fileName: 'privacy-check.pdf', path: path);
  }
}

class FakeReportSharer implements ReportSharer {
  String? sharedPath;

  @override
  Future<void> share(ExportedReport report) async {
    sharedPath = report.path;
  }
}
