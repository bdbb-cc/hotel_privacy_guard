import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart' as share_plus;
import 'package:shared_preferences/shared_preferences.dart';

const privacyCheckStorageKey = 'hotel_privacy_guard.snapshot.v1';
const reportPdfCjkFontAsset = 'assets/fonts/NotoSansSC-Regular.ttf';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({
    super.key,
    this.evidencePicker,
    this.reportExporter,
    this.reportSharer,
  });

  final EvidencePicker? evidencePicker;
  final ReportExporter? reportExporter;
  final ReportSharer? reportSharer;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hotel Privacy Guard',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0E7C86),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF6F7F4),
        cardTheme: const CardThemeData(
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
            side: BorderSide(color: Color(0xFFE0E5DF)),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        useMaterial3: true,
      ),
      home: PrivacyGuardHome(
        evidencePicker: evidencePicker ?? ImagePickerEvidencePicker(),
        reportExporter: reportExporter ?? PdfReportExporter(),
        reportSharer: reportSharer ?? SharePlusReportSharer(),
      ),
    );
  }
}

class PrivacyGuardHome extends StatefulWidget {
  const PrivacyGuardHome({
    required this.evidencePicker,
    required this.reportExporter,
    required this.reportSharer,
    super.key,
  });

  final EvidencePicker evidencePicker;
  final ReportExporter reportExporter;
  final ReportSharer reportSharer;

  @override
  State<PrivacyGuardHome> createState() => _PrivacyGuardHomeState();
}

class _PrivacyGuardHomeState extends State<PrivacyGuardHome> {
  int _selectedIndex = 0;
  final Set<String> _completedZoneIds = <String>{};
  final Map<String, Set<int>> _completedChecklistStepIndexesByZone =
      <String, Set<int>>{};
  final List<Finding> _findings = <Finding>[];
  StayDetails _stayDetails = const StayDetails();

  double get _progress => _completedZoneIds.length / sweepZones.length;

  @override
  void initState() {
    super.initState();
    _restoreSnapshot();
  }

  void _toggleZone(String id, bool checked) {
    setState(() {
      if (checked) {
        _completedZoneIds.add(id);
      } else {
        _completedZoneIds.remove(id);
      }
    });
    _saveSnapshot();
  }

  void _toggleChecklistStep(String zoneId, int stepIndex, bool checked) {
    setState(() {
      final completedSteps = Set<int>.from(
        _completedChecklistStepIndexesByZone[zoneId] ?? const <int>{},
      );

      if (checked) {
        completedSteps.add(stepIndex);
      } else {
        completedSteps.remove(stepIndex);
      }

      if (completedSteps.isEmpty) {
        _completedChecklistStepIndexesByZone.remove(zoneId);
      } else {
        _completedChecklistStepIndexesByZone[zoneId] = completedSteps;
      }
    });
    _saveSnapshot();
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      SweepPage(
        completedZoneIds: _completedZoneIds,
        completedChecklistStepIndexesByZone:
            _completedChecklistStepIndexesByZone,
        findings: _findings,
        progress: _progress,
        onZoneChanged: _toggleZone,
        onChecklistStepChanged: _toggleChecklistStep,
      ),
      FindingsPage(
        findings: _findings,
        onAddFinding: () => _showAddFindingSheet(context),
        onReviewStatusChanged: _updateFindingReviewStatus,
        onDeleteFinding: _confirmDeleteFinding,
      ),
      ReportPage(
        progress: _progress,
        completedZoneIds: _completedZoneIds,
        completedChecklistStepIndexesByZone:
            _completedChecklistStepIndexesByZone,
        findings: _findings,
        stayDetails: _stayDetails,
        onStayDetailsChanged: _updateStayDetails,
        reportExporter: widget.reportExporter,
        reportSharer: widget.reportSharer,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hotel Privacy Guard'),
        actions: [
          IconButton(
            tooltip: 'New check',
            onPressed: () => _confirmNewCheck(context),
            icon: const Icon(Icons.restart_alt_outlined),
          ),
          IconButton(
            tooltip: 'Safety notes',
            onPressed: () => _showSafetyNotes(context),
            icon: const Icon(Icons.privacy_tip_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: IndexedStack(index: _selectedIndex, children: pages),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.travel_explore_outlined),
            selectedIcon: Icon(Icons.travel_explore),
            label: 'Sweep',
          ),
          NavigationDestination(
            icon: Icon(Icons.radar_outlined),
            selectedIcon: Icon(Icons.radar),
            label: 'Findings',
          ),
          NavigationDestination(
            icon: Icon(Icons.description_outlined),
            selectedIcon: Icon(Icons.description),
            label: 'Report',
          ),
        ],
      ),
    );
  }

  void _confirmNewCheck(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Start new check?'),
          content: const Text(
            'This clears the current room progress, findings, and stay details '
            'stored on this device.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                _startNewCheck();
              },
              child: const Text('Start new check'),
            ),
          ],
        );
      },
    );
  }

  void _showSafetyNotes(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Safety boundary',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              const Text(
                'This app is designed for visible room checks, optical clues, '
                'and evidence notes. It does not open unknown camera streams, '
                'try credentials, or access devices without authorization.',
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Got it'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAddFindingSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return AddFindingSheet(
          evidencePicker: widget.evidencePicker,
          onSave: (finding) {
            setState(() => _findings.add(finding));
            _saveSnapshot();
            Navigator.pop(context);
          },
        );
      },
    );
  }

  Future<void> _restoreSnapshot() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = prefs.getString(privacyCheckStorageKey);

    if (encoded == null || encoded.isEmpty) {
      return;
    }

    final snapshot = decodePrivacyCheckSnapshot(encoded);

    if (!mounted) {
      return;
    }

    setState(() {
      _completedZoneIds
        ..clear()
        ..addAll(snapshot.completedZoneIds);
      _completedChecklistStepIndexesByZone
        ..clear()
        ..addAll(
          copyChecklistStepIndexesByZone(
            snapshot.completedChecklistStepIndexesByZone,
          ),
        );
      _findings
        ..clear()
        ..addAll(snapshot.findings);
      _stayDetails = snapshot.stayDetails;
    });
  }

  void _updateStayDetails(StayDetails stayDetails) {
    setState(() => _stayDetails = stayDetails);
    _saveSnapshot();
  }

  void _updateFindingReviewStatus(Finding finding, ReviewStatus status) {
    final index = _findings.indexOf(finding);
    if (index == -1) {
      return;
    }

    setState(() {
      _findings[index] = finding.copyWith(reviewStatus: status);
    });
    _saveSnapshot();
  }

  void _confirmDeleteFinding(Finding finding) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete finding?'),
          content: Text('Remove "${finding.title}" from this check?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                _deleteFinding(finding);
              },
              child: const Text('Delete finding'),
            ),
          ],
        );
      },
    );
  }

  void _deleteFinding(Finding finding) {
    setState(() => _findings.remove(finding));
    _saveSnapshot();
  }

  void _startNewCheck() {
    setState(() {
      _selectedIndex = 0;
      _completedZoneIds.clear();
      _completedChecklistStepIndexesByZone.clear();
      _findings.clear();
      _stayDetails = const StayDetails();
    });
    _saveSnapshot();
  }

  Future<void> _saveSnapshot() async {
    final prefs = await SharedPreferences.getInstance();
    final snapshot = PrivacyCheckSnapshot(
      completedZoneIds: Set.unmodifiable(_completedZoneIds),
      completedChecklistStepIndexesByZone: copyChecklistStepIndexesByZone(
        _completedChecklistStepIndexesByZone,
      ),
      stayDetails: _stayDetails,
      findings: List.unmodifiable(_findings),
    );

    await prefs.setString(
      privacyCheckStorageKey,
      encodePrivacyCheckSnapshot(snapshot),
    );
  }
}

class SweepPage extends StatelessWidget {
  const SweepPage({
    required this.completedZoneIds,
    required this.completedChecklistStepIndexesByZone,
    required this.findings,
    required this.progress,
    required this.onZoneChanged,
    required this.onChecklistStepChanged,
    super.key,
  });

  final Set<String> completedZoneIds;
  final Map<String, Set<int>> completedChecklistStepIndexesByZone;
  final List<Finding> findings;
  final double progress;
  final void Function(String id, bool checked) onZoneChanged;
  final void Function(String zoneId, int stepIndex, bool checked)
  onChecklistStepChanged;

  @override
  Widget build(BuildContext context) {
    final riskSummary = calculateRiskSummary(
      completedZoneIds: completedZoneIds,
      findings: findings,
    );
    final coverageGaps = calculateChecklistCoverageGaps(
      completedChecklistStepIndexesByZone,
    );
    final nextGap = coverageGaps.firstOrNull;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        HeaderPanel(
          progress: progress,
          nextGap: nextGap,
          onOpenNextChecklist: nextGap == null
              ? null
              : () {
                  final zone = zoneForId(nextGap.zoneId);
                  showZoneChecklistSheet(
                    context,
                    zone: zone,
                    completedStepIndexes:
                        completedChecklistStepIndexesByZone[zone.id] ??
                        const <int>{},
                    suggestedStepIndex: nextGap.stepIndex,
                    onChecklistStepChanged: (stepIndex, checked) {
                      onChecklistStepChanged(zone.id, stepIndex, checked);
                    },
                  );
                },
        ),
        const SizedBox(height: 16),
        RiskSummaryPanel(summary: riskSummary),
        const SizedBox(height: 16),
        Text('Room Sweep', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        for (final zone in sweepZones) ...[
          SweepZoneTile(
            zone: zone,
            checked: completedZoneIds.contains(zone.id),
            completedStepIndexes:
                completedChecklistStepIndexesByZone[zone.id] ?? const <int>{},
            onChanged: (checked) => onZoneChanged(zone.id, checked),
            onChecklistStepChanged: (stepIndex, checked) {
              onChecklistStepChanged(zone.id, stepIndex, checked);
            },
          ),
          const SizedBox(height: 8),
        ],
        RoomRiskMap(completedZoneIds: completedZoneIds, findings: findings),
        const SizedBox(height: 8),
        const SignalGrid(),
      ],
    );
  }
}

class HeaderPanel extends StatelessWidget {
  const HeaderPanel({
    required this.progress,
    required this.nextGap,
    required this.onOpenNextChecklist,
    super.key,
  });

  final double progress;
  final ChecklistCoverageGap? nextGap;
  final VoidCallback? onOpenNextChecklist;

  @override
  Widget build(BuildContext context) {
    final percent = (progress * 100).round();

    return Card(
      color: const Color(0xFFEAF5F3),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0E7C86),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.shield_outlined, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '酒店隐私守护',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '5 分钟隐私检查',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      Text(
                        '$percent% complete',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(value: progress),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Start sweep'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _NextCheckInline(
                    nextGap: nextGap,
                    onOpen: onOpenNextChecklist,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class RiskSummaryPanel extends StatelessWidget {
  const RiskSummaryPanel({
    required this.summary,
    this.showFactors = false,
    super.key,
  });

  final RiskSummary summary;
  final bool showFactors;

  @override
  Widget build(BuildContext context) {
    final band = riskBandStyles[summary.band]!;
    final factorLines = riskFactorLines(summary);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: band.color.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(band.icon, color: band.color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        band.label,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text('Risk score ${summary.score}'),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(summary.primaryAction),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: summary.score / 100,
              color: band.color,
              backgroundColor: band.color.withValues(alpha: 0.14),
            ),
            const SizedBox(height: 8),
            Text(
              '${summary.uncheckedZoneCount} zones still unchecked',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (showFactors) ...[
              const SizedBox(height: 8),
              Text(
                'Risk factors',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 12,
                runSpacing: 4,
                children: [
                  for (final line in factorLines)
                    Text(line, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _NextCheckInline extends StatelessWidget {
  const _NextCheckInline({required this.nextGap, required this.onOpen});

  final ChecklistCoverageGap? nextGap;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(Icons.next_plan_outlined, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Next check',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  nextGap == null
                      ? 'All manual checklist steps are complete'
                      : '${nextGap!.zoneName}: ${nextGap!.step}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          if (onOpen != null) ...[
            const SizedBox(width: 4),
            TextButton(onPressed: onOpen, child: const Text('Open')),
          ],
        ],
      ),
    );
  }
}

class SignalGrid extends StatelessWidget {
  const SignalGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth >= 560 ? 4 : 2;

        return GridView.builder(
          itemCount: signalModules.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: constraints.maxWidth >= 560 ? 1.45 : 1.25,
          ),
          itemBuilder: (context, index) {
            return SignalCard(module: signalModules[index]);
          },
        );
      },
    );
  }
}

class SignalCard extends StatelessWidget {
  const SignalCard({required this.module, super.key});

  final SignalModule module;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(module.icon, color: module.color),
            const Spacer(),
            Text(
              module.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 2),
            Text(
              module.status,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class SweepZoneTile extends StatelessWidget {
  const SweepZoneTile({
    required this.zone,
    required this.checked,
    required this.completedStepIndexes,
    required this.onChanged,
    required this.onChecklistStepChanged,
    super.key,
  });

  final SweepZone zone;
  final bool checked;
  final Set<int> completedStepIndexes;
  final ValueChanged<bool> onChanged;
  final void Function(int stepIndex, bool checked) onChecklistStepChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: CheckboxListTile(
        value: checked,
        onChanged: (value) => onChanged(value ?? false),
        secondary: Icon(zone.icon),
        title: Row(
          children: [
            Expanded(child: Text(zone.name)),
            TextButton.icon(
              onPressed: () {
                showZoneChecklistSheet(
                  context,
                  zone: zone,
                  completedStepIndexes: completedStepIndexes,
                  onChecklistStepChanged: onChecklistStepChanged,
                );
              },
              icon: const Icon(Icons.checklist_outlined, size: 18),
              label: const Text('Checklist'),
            ),
          ],
        ),
        subtitle: Text(
          '${zone.focus}\nChecklist '
          '${completedStepIndexes.length}/${zone.checklist.length} done',
        ),
        controlAffinity: ListTileControlAffinity.trailing,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}

void showZoneChecklistSheet(
  BuildContext context, {
  required SweepZone zone,
  required Set<int> completedStepIndexes,
  int? suggestedStepIndex,
  required void Function(int stepIndex, bool checked) onChecklistStepChanged,
}) {
  final localCompletedStepIndexes = Set<int>.from(completedStepIndexes);

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setSheetState) {
          final completedCount = localCompletedStepIndexes.length;

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${zone.name} checklist',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$completedCount of ${zone.checklist.length} steps checked',
                  ),
                  const SizedBox(height: 12),
                  for (final entry in zone.checklist.indexed)
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: entry.$1 == suggestedStepIndex
                            ? Theme.of(
                                context,
                              ).colorScheme.primary.withValues(alpha: 0.08)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CheckboxListTile(
                            key: Key('checklist-step-${zone.id}-${entry.$1}'),
                            value: localCompletedStepIndexes.contains(entry.$1),
                            onChanged: (value) {
                              final checked = value ?? false;

                              setSheetState(() {
                                if (checked) {
                                  localCompletedStepIndexes.add(entry.$1);
                                } else {
                                  localCompletedStepIndexes.remove(entry.$1);
                                }
                              });
                              onChecklistStepChanged(entry.$1, checked);
                            },
                            contentPadding: EdgeInsets.zero,
                            controlAffinity: ListTileControlAffinity.leading,
                            title: Text(entry.$2),
                          ),
                          if (entry.$1 == suggestedStepIndex)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                              child: Text(
                                'Suggested next step',
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                    ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 8),
                  FilledButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Done'),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

class RoomRiskMap extends StatelessWidget {
  const RoomRiskMap({
    required this.completedZoneIds,
    required this.findings,
    super.key,
  });

  final Set<String> completedZoneIds;
  final List<Finding> findings;

  @override
  Widget build(BuildContext context) {
    final statuses = calculateZoneRiskStatuses(
      completedZoneIds: completedZoneIds,
      findings: findings,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Room risk map',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final zone in sweepZones)
                  ZoneStatusChip(
                    zone: zone,
                    state: statuses[zone.id] ?? ZoneRiskState.unchecked,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ZoneStatusChip extends StatelessWidget {
  const ZoneStatusChip({required this.zone, required this.state, super.key});

  final SweepZone zone;
  final ZoneRiskState state;

  @override
  Widget build(BuildContext context) {
    final style = zoneRiskStateStyles[state]!;

    return Chip(
      avatar: Icon(zone.icon, size: 18, color: style.color),
      label: Text('${zone.name}: ${style.label}'),
      side: BorderSide(color: style.color.withValues(alpha: 0.32)),
      backgroundColor: style.color.withValues(alpha: 0.10),
    );
  }
}

class FindingsPage extends StatelessWidget {
  const FindingsPage({
    required this.findings,
    required this.onAddFinding,
    required this.onReviewStatusChanged,
    required this.onDeleteFinding,
    super.key,
  });

  final List<Finding> findings;
  final VoidCallback onAddFinding;
  final void Function(Finding finding, ReviewStatus status)
  onReviewStatusChanged;
  final ValueChanged<Finding> onDeleteFinding;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Text('Findings Log', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        if (findings.isEmpty)
          const EmptyFindingsCard()
        else
          for (final finding in findings) ...[
            FindingCard(
              finding: finding,
              onReviewStatusChanged: (status) =>
                  onReviewStatusChanged(finding, status),
              onDelete: () => onDeleteFinding(finding),
            ),
            const SizedBox(height: 8),
          ],
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: onAddFinding,
          icon: const Icon(Icons.add_a_photo_outlined),
          label: const Text('Add finding'),
        ),
      ],
    );
  }
}

class FindingCard extends StatelessWidget {
  const FindingCard({
    required this.finding,
    required this.onReviewStatusChanged,
    required this.onDelete,
    super.key,
  });

  final Finding finding;
  final ValueChanged<ReviewStatus> onReviewStatusChanged;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final level = riskLevels[finding.risk]!;
    final recordedAt = formatRecordedAt(finding.createdAtIso);
    final reviewStatus = reviewStatusStyles[finding.reviewStatus]!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          children: [
            ListTile(
              leading: Icon(finding.type.icon, color: level.color),
              title: Text(finding.title),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (finding.zoneId.isNotEmpty)
                    Text('Zone: ${zoneNameForId(finding.zoneId)}'),
                  Text(finding.location),
                  Text('Status: ${reviewStatus.label}'),
                  if (recordedAt.isNotEmpty) Text('Recorded: $recordedAt'),
                  if (finding.evidencePaths.isNotEmpty) ...[
                    Text(photoCountLabel(finding.evidencePaths.length)),
                    Text(
                      'Files: ${finding.evidencePaths.map(evidenceFileName).join(', ')}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
              trailing: Chip(
                label: Text(level.label),
                side: BorderSide.none,
                backgroundColor: level.color.withValues(alpha: 0.14),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final entry in reviewStatusStyles.entries)
                    ChoiceChip(
                      label: Text(entry.value.label),
                      selected: finding.reviewStatus == entry.key,
                      onSelected: (_) => onReviewStatusChanged(entry.key),
                    ),
                  IconButton.outlined(
                    tooltip: 'Delete finding',
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class EmptyFindingsCard extends StatelessWidget {
  const EmptyFindingsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.fact_check_outlined),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'No findings yet',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Add reviewed clues only after you have checked them in the room.',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AddFindingSheet extends StatefulWidget {
  const AddFindingSheet({
    required this.evidencePicker,
    required this.onSave,
    super.key,
  });

  final EvidencePicker evidencePicker;
  final ValueChanged<Finding> onSave;

  @override
  State<AddFindingSheet> createState() => _AddFindingSheetState();
}

class _AddFindingSheetState extends State<AddFindingSheet> {
  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  final _notesController = TextEditingController();
  final List<String> _evidencePaths = <String>[];
  SweepZone _zone = sweepZones.first;
  FindingType _type = findingTypes.first;
  RiskLevel _risk = RiskLevel.medium;

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final sheetHeight = MediaQuery.sizeOf(context).height * 0.86;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, bottomInset + 16),
      child: SizedBox(
        height: sheetHeight,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Add reviewed finding',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      key: const Key('finding-title-field'),
                      controller: _titleController,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Finding',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      key: const Key('finding-location-field'),
                      controller: _locationController,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Room location',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      children: [
                        for (final entry in riskLevels.entries)
                          ChoiceChip(
                            label: Text(entry.value.label),
                            selected: _risk == entry.key,
                            onSelected: (_) =>
                                setState(() => _risk = entry.key),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<SweepZone>(
                      key: const Key('finding-zone-field'),
                      initialValue: _zone,
                      decoration: const InputDecoration(
                        labelText: 'Room zone',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        for (final zone in sweepZones)
                          DropdownMenuItem(value: zone, child: Text(zone.name)),
                      ],
                      onChanged: (zone) {
                        if (zone != null) {
                          setState(() => _zone = zone);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<FindingType>(
                      initialValue: _type,
                      decoration: const InputDecoration(
                        labelText: 'Signal type',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        for (final type in findingTypes)
                          DropdownMenuItem(
                            value: type,
                            child: Text(type.label),
                          ),
                      ],
                      onChanged: (type) {
                        if (type != null) {
                          setState(() => _type = type);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    EvidenceAttachmentPanel(
                      count: _evidencePaths.length,
                      onTakePhoto: () =>
                          _attachEvidence(widget.evidencePicker.pickFromCamera),
                      onChoosePhoto: () => _attachEvidence(
                        widget.evidencePicker.pickFromGallery,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _notesController,
                      minLines: 2,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Notes',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.check),
              label: const Text('Save finding'),
            ),
          ],
        ),
      ),
    );
  }

  void _save() {
    final title = _titleController.text.trim();
    final location = _locationController.text.trim();

    if (title.isEmpty || location.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Finding and location are required')),
      );
      return;
    }

    widget.onSave(
      Finding(
        title: title,
        location: location,
        zoneId: _zone.id,
        createdAtIso: DateTime.now().toUtc().toIso8601String(),
        type: _type,
        risk: _risk,
        notes: _notesController.text.trim(),
        evidencePaths: List.unmodifiable(_evidencePaths),
      ),
    );
  }

  Future<void> _attachEvidence(Future<String?> Function() pick) async {
    final path = await pick();

    if (path == null || path.trim().isEmpty) {
      return;
    }

    setState(() => _evidencePaths.add(path));
  }
}

class EvidenceAttachmentPanel extends StatelessWidget {
  const EvidenceAttachmentPanel({
    required this.count,
    required this.onTakePhoto,
    required this.onChoosePhoto,
    super.key,
  });

  final int count;
  final VoidCallback onTakePhoto;
  final VoidCallback onChoosePhoto;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFFF9FAF7),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.attachment_outlined),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    count == 0
                        ? 'No photos attached'
                        : photoAttachedLabel(count),
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onTakePhoto,
                    icon: const Icon(Icons.photo_camera_outlined),
                    label: const Text('Take photo'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onChoosePhoto,
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('Choose photo'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ReportPage extends StatelessWidget {
  const ReportPage({
    required this.progress,
    required this.completedZoneIds,
    required this.completedChecklistStepIndexesByZone,
    required this.findings,
    required this.stayDetails,
    required this.onStayDetailsChanged,
    required this.reportExporter,
    required this.reportSharer,
    super.key,
  });

  final double progress;
  final Set<String> completedZoneIds;
  final Map<String, Set<int>> completedChecklistStepIndexesByZone;
  final List<Finding> findings;
  final StayDetails stayDetails;
  final ValueChanged<StayDetails> onStayDetailsChanged;
  final ReportExporter reportExporter;
  final ReportSharer reportSharer;

  @override
  Widget build(BuildContext context) {
    final completed = (progress * sweepZones.length).round();
    final findingLabel = findings.length == 1
        ? '1 reviewed finding'
        : '${findings.length} reviewed findings';
    final riskSummary = calculateRiskSummary(
      completedZoneIds: completedZoneIds,
      findings: findings,
    );
    final actionSteps = recommendedActionSteps(riskSummary.band);
    final reviewCounts = calculateReviewStatusCounts(findings);
    final checklistProgress = calculateChecklistProgress(
      completedChecklistStepIndexesByZone,
    );
    final coverageGaps = calculateChecklistCoverageGaps(
      completedChecklistStepIndexesByZone,
    );
    final reportReadiness = calculateReportReadiness(
      completedChecklistStepIndexesByZone: completedChecklistStepIndexesByZone,
      findings: findings,
      stayDetails: stayDetails,
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Text('Evidence Report', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$completed of ${sweepZones.length} zones checked',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(findingLabel),
                const SizedBox(height: 4),
                Text(
                  'Checklist steps: '
                  '${checklistProgress.completedStepCount} of '
                  '${checklistProgress.totalStepCount} checked',
                ),
                if (findings.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  ReviewStatusSummary(counts: reviewCounts),
                ],
                const SizedBox(height: 8),
                const Text(
                  'Findings, photos, timestamps, and room zones will be bundled '
                  'into a shareable incident report.',
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => _showReportDraft(context),
                        icon: const Icon(Icons.picture_as_pdf_outlined),
                        label: const Text('Build report'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _exportPdf(context),
                        icon: const Icon(Icons.file_download_outlined),
                        label: const Text('Export PDF'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        RiskSummaryPanel(summary: riskSummary, showFactors: true),
        const SizedBox(height: 16),
        ReportReadinessPanel(readiness: reportReadiness),
        const SizedBox(height: 16),
        StayDetailsPanel(details: stayDetails, onChanged: onStayDetailsChanged),
        const SizedBox(height: 16),
        ActionChecklistPanel(steps: actionSteps),
        const SizedBox(height: 16),
        CoverageGapsPanel(gaps: coverageGaps),
        const SizedBox(height: 16),
        const ReportRow(
          icon: Icons.lock_outline,
          title: 'Local first',
          value: 'No room media leaves the device by default',
        ),
        const ReportRow(
          icon: Icons.fact_check_outlined,
          title: 'Review ready',
          value: 'Each item keeps the reason it was flagged',
        ),
        const ReportRow(
          icon: Icons.support_agent_outlined,
          title: 'Next steps',
          value: 'Export notes for hotel, platform, or authorities',
        ),
      ],
    );
  }

  void _showReportDraft(BuildContext context) {
    final draft = buildReportDraft(
      completedZoneIds: completedZoneIds,
      completedChecklistStepIndexesByZone: completedChecklistStepIndexesByZone,
      findings: findings,
      stayDetails: stayDetails,
    );

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Incident report draft',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                SelectableText(draft),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: draft));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Report draft copied')),
                    );
                  },
                  icon: const Icon(Icons.copy),
                  label: const Text('Copy draft'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _exportPdf(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);

    try {
      final report = await reportExporter.export(
        completedZoneIds: completedZoneIds,
        completedChecklistStepIndexesByZone:
            completedChecklistStepIndexesByZone,
        findings: findings,
        stayDetails: stayDetails,
      );

      if (!context.mounted) {
        return;
      }

      showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (context) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PDF report ready',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                SelectableText(report.path),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () async {
                          await reportSharer.share(report);
                          if (!context.mounted) {
                            return;
                          }
                          Navigator.pop(context);
                          messenger.showSnackBar(
                            const SnackBar(content: Text('PDF share opened')),
                          );
                        },
                        icon: const Icon(Icons.ios_share_outlined),
                        label: const Text('Share PDF'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: report.path));
                          Navigator.pop(context);
                          messenger.showSnackBar(
                            const SnackBar(content: Text('PDF path copied')),
                          );
                        },
                        icon: const Icon(Icons.copy),
                        label: const Text('Copy path'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      );
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('PDF export failed')),
      );
    }
  }
}

class ReviewStatusSummary extends StatelessWidget {
  const ReviewStatusSummary({required this.counts, super.key});

  final Map<ReviewStatus, int> counts;

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.bodySmall;

    return Wrap(
      spacing: 12,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text('Review summary', style: Theme.of(context).textTheme.titleSmall),
        for (final entry in reviewStatusStyles.entries)
          Text(
            '${entry.value.label} ${counts[entry.key] ?? 0}',
            style: textStyle?.copyWith(color: entry.value.color),
          ),
      ],
    );
  }
}

class StayDetailsPanel extends StatefulWidget {
  const StayDetailsPanel({
    required this.details,
    required this.onChanged,
    super.key,
  });

  final StayDetails details;
  final ValueChanged<StayDetails> onChanged;

  @override
  State<StayDetailsPanel> createState() => _StayDetailsPanelState();
}

class _StayDetailsPanelState extends State<StayDetailsPanel> {
  late final TextEditingController _hotelController;
  late final TextEditingController _roomController;
  late final TextEditingController _platformController;
  late final TextEditingController _contactController;

  @override
  void initState() {
    super.initState();
    _hotelController = TextEditingController(text: widget.details.hotelName);
    _roomController = TextEditingController(text: widget.details.roomNumber);
    _platformController = TextEditingController(
      text: widget.details.bookingPlatform,
    );
    _contactController = TextEditingController(
      text: widget.details.supportContact,
    );
  }

  @override
  void didUpdateWidget(covariant StayDetailsPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncController(_hotelController, widget.details.hotelName);
    _syncController(_roomController, widget.details.roomNumber);
    _syncController(_platformController, widget.details.bookingPlatform);
    _syncController(_contactController, widget.details.supportContact);
  }

  @override
  void dispose() {
    _hotelController.dispose();
    _roomController.dispose();
    _platformController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Stay details',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final twoColumns = constraints.maxWidth >= 560;
                final fieldWidth = twoColumns
                    ? (constraints.maxWidth - 12) / 2
                    : constraints.maxWidth;

                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    SizedBox(
                      width: fieldWidth,
                      child: TextField(
                        key: const Key('stay-hotel-field'),
                        controller: _hotelController,
                        onChanged: (_) => _emitChanged(),
                        decoration: const InputDecoration(
                          labelText: 'Hotel',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: fieldWidth,
                      child: TextField(
                        key: const Key('stay-room-field'),
                        controller: _roomController,
                        onChanged: (_) => _emitChanged(),
                        decoration: const InputDecoration(
                          labelText: 'Room',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: fieldWidth,
                      child: TextField(
                        key: const Key('stay-platform-field'),
                        controller: _platformController,
                        onChanged: (_) => _emitChanged(),
                        decoration: const InputDecoration(
                          labelText: 'Booking/platform',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: fieldWidth,
                      child: TextField(
                        key: const Key('stay-contact-field'),
                        controller: _contactController,
                        onChanged: (_) => _emitChanged(),
                        decoration: const InputDecoration(
                          labelText: 'Support contact',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _syncController(TextEditingController controller, String value) {
    if (controller.text == value) {
      return;
    }

    controller.text = value;
    controller.selection = TextSelection.collapsed(offset: value.length);
  }

  void _emitChanged() {
    widget.onChanged(
      StayDetails(
        hotelName: _hotelController.text,
        roomNumber: _roomController.text,
        bookingPlatform: _platformController.text,
        supportContact: _contactController.text,
      ),
    );
  }
}

class ActionChecklistPanel extends StatelessWidget {
  const ActionChecklistPanel({required this.steps, super.key});

  final List<ActionStep> steps;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Action checklist',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            for (final step in steps)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(step.icon),
                title: Text(step.title),
                subtitle: Text(step.detail),
              ),
          ],
        ),
      ),
    );
  }
}

class ReportReadinessPanel extends StatelessWidget {
  const ReportReadinessPanel({required this.readiness, super.key});

  final ReportReadiness readiness;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final ready = readiness.items.isEmpty;
    final statusColor = ready ? const Color(0xFF4F772D) : colorScheme.primary;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  ready
                      ? Icons.check_circle_outline
                      : Icons.pending_actions_outlined,
                  color: statusColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'Report readiness',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              readiness.title,
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(color: statusColor),
            ),
            const SizedBox(height: 4),
            Text(readiness.detail),
            const SizedBox(height: 8),
            if (readiness.items.isEmpty)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.verified_outlined),
                title: const Text('Ready to share'),
                subtitle: const Text(
                  'Core context and review notes are present.',
                ),
              )
            else
              for (final item in readiness.items)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(item.icon),
                  title: Text(item.title),
                  subtitle: Text(item.detail),
                ),
          ],
        ),
      ),
    );
  }
}

class CoverageGapsPanel extends StatelessWidget {
  const CoverageGapsPanel({required this.gaps, super.key});

  final List<ChecklistCoverageGap> gaps;

  @override
  Widget build(BuildContext context) {
    final visibleGaps = gaps.take(5).toList();
    final remainingHiddenCount = gaps.length - visibleGaps.length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Coverage gaps',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(_coverageGapCountLabel(gaps.length)),
            if (visibleGaps.isNotEmpty) ...[
              const SizedBox(height: 12),
              for (final gap in visibleGaps)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.radio_button_unchecked, size: 18),
                      const SizedBox(width: 8),
                      Expanded(child: Text('${gap.zoneName}: ${gap.step}')),
                    ],
                  ),
                ),
              if (remainingHiddenCount > 0)
                Text(
                  '$remainingHiddenCount more checklist steps not shown',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class ReportRow extends StatelessWidget {
  const ReportRow({
    required this.icon,
    required this.title,
    required this.value,
    super.key,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(value),
    );
  }
}

class SweepZone {
  const SweepZone({
    required this.id,
    required this.name,
    required this.focus,
    required this.checklist,
    required this.icon,
  });

  final String id;
  final String name;
  final String focus;
  final List<String> checklist;
  final IconData icon;
}

class SignalModule {
  const SignalModule({
    required this.title,
    required this.status,
    required this.icon,
    required this.color,
  });

  final String title;
  final String status;
  final IconData icon;
  final Color color;
}

class Finding {
  const Finding({
    required this.title,
    required this.location,
    required this.type,
    required this.risk,
    required this.notes,
    required this.evidencePaths,
    this.zoneId = '',
    this.reviewStatus = ReviewStatus.needsReview,
    this.createdAtIso = '',
  });

  final String title;
  final String location;
  final String zoneId;
  final String createdAtIso;
  final ReviewStatus reviewStatus;
  final FindingType type;
  final RiskLevel risk;
  final String notes;
  final List<String> evidencePaths;

  Finding copyWith({ReviewStatus? reviewStatus}) {
    return Finding(
      title: title,
      location: location,
      zoneId: zoneId,
      reviewStatus: reviewStatus ?? this.reviewStatus,
      createdAtIso: createdAtIso,
      type: type,
      risk: risk,
      notes: notes,
      evidencePaths: evidencePaths,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'title': title,
      'location': location,
      'zoneId': zoneId,
      'createdAtIso': createdAtIso,
      'reviewStatus': reviewStatus.name,
      'typeLabel': type.label,
      'risk': risk.name,
      'notes': notes,
      'evidencePaths': evidencePaths,
    };
  }

  static Finding fromJson(Map<String, Object?> json) {
    final typeLabel = json['typeLabel'] as String? ?? findingTypes.first.label;
    final title = json['title'] as String? ?? '';
    final location = json['location'] as String? ?? '';
    final zoneId =
        json['zoneId'] as String? ??
        inferZoneIdFromFindingText(title, location);

    return Finding(
      title: title,
      location: location,
      zoneId: zoneId,
      createdAtIso: json['createdAtIso'] as String? ?? '',
      reviewStatus: ReviewStatus.values.firstWhere(
        (status) => status.name == json['reviewStatus'],
        orElse: () => ReviewStatus.needsReview,
      ),
      type: findingTypes.firstWhere(
        (type) => type.label == typeLabel,
        orElse: () => findingTypes.first,
      ),
      risk: RiskLevel.values.firstWhere(
        (risk) => risk.name == json['risk'],
        orElse: () => RiskLevel.medium,
      ),
      notes: json['notes'] as String? ?? '',
      evidencePaths: List<String>.from(
        json['evidencePaths'] as List<Object?>? ?? const [],
      ),
    );
  }
}

class FindingType {
  const FindingType({required this.label, required this.icon});

  final String label;
  final IconData icon;
}

enum RiskLevel { low, medium, high }

enum ReviewStatus { needsReview, documented, falseAlarm }

class RiskLevelStyle {
  const RiskLevelStyle({required this.label, required this.color});

  final String label;
  final Color color;
}

class ReviewStatusStyle {
  const ReviewStatusStyle({required this.label, required this.color});

  final String label;
  final Color color;
}

enum RiskBand { baseline, watch, elevated, high }

enum ZoneRiskState { unchecked, checked, flagged }

class RiskBandStyle {
  const RiskBandStyle({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;
}

class RiskSummary {
  const RiskSummary({
    required this.score,
    required this.band,
    required this.uncheckedZoneCount,
    required this.primaryAction,
    this.activeFindingCount = 0,
    this.evidenceAttachmentCount = 0,
    this.falseAlarmCount = 0,
  });

  final int score;
  final RiskBand band;
  final int uncheckedZoneCount;
  final String primaryAction;
  final int activeFindingCount;
  final int evidenceAttachmentCount;
  final int falseAlarmCount;
}

class ZoneRiskStateStyle {
  const ZoneRiskStateStyle({required this.label, required this.color});

  final String label;
  final Color color;
}

class ActionStep {
  const ActionStep({
    required this.title,
    required this.detail,
    required this.icon,
  });

  final String title;
  final String detail;
  final IconData icon;
}

class ReportReadiness {
  const ReportReadiness({
    required this.title,
    required this.detail,
    required this.items,
  });

  final String title;
  final String detail;
  final List<ReportReadinessItem> items;
}

class ReportReadinessItem {
  const ReportReadinessItem({
    required this.title,
    required this.detail,
    required this.icon,
  });

  final String title;
  final String detail;
  final IconData icon;
}

class StayDetails {
  const StayDetails({
    this.hotelName = '',
    this.roomNumber = '',
    this.bookingPlatform = '',
    this.supportContact = '',
  });

  final String hotelName;
  final String roomNumber;
  final String bookingPlatform;
  final String supportContact;

  bool get hasAny =>
      hotelName.trim().isNotEmpty ||
      roomNumber.trim().isNotEmpty ||
      bookingPlatform.trim().isNotEmpty ||
      supportContact.trim().isNotEmpty;

  Map<String, Object?> toJson() {
    return {
      'hotelName': hotelName,
      'roomNumber': roomNumber,
      'bookingPlatform': bookingPlatform,
      'supportContact': supportContact,
    };
  }

  static StayDetails fromJson(Map<String, Object?> json) {
    return StayDetails(
      hotelName: json['hotelName'] as String? ?? '',
      roomNumber: json['roomNumber'] as String? ?? '',
      bookingPlatform: json['bookingPlatform'] as String? ?? '',
      supportContact: json['supportContact'] as String? ?? '',
    );
  }
}

class PrivacyCheckSnapshot {
  const PrivacyCheckSnapshot({
    required this.completedZoneIds,
    this.completedChecklistStepIndexesByZone = const {},
    this.stayDetails = const StayDetails(),
    required this.findings,
  });

  final Set<String> completedZoneIds;
  final Map<String, Set<int>> completedChecklistStepIndexesByZone;
  final StayDetails stayDetails;
  final List<Finding> findings;

  Map<String, Object?> toJson() {
    final checklistProgressEntries =
        completedChecklistStepIndexesByZone.entries.toList()
          ..sort((a, b) => a.key.compareTo(b.key));

    return {
      'completedZoneIds': completedZoneIds.toList()..sort(),
      'completedChecklistStepIndexesByZone': {
        for (final entry in checklistProgressEntries)
          if (entry.value.isNotEmpty) entry.key: entry.value.toList()..sort(),
      },
      'stayDetails': stayDetails.toJson(),
      'findings': findings.map((finding) => finding.toJson()).toList(),
    };
  }

  static PrivacyCheckSnapshot fromJson(Map<String, Object?> json) {
    final rawFindings = json['findings'] as List<Object?>? ?? const [];
    final rawStayDetails = json['stayDetails'];

    return PrivacyCheckSnapshot(
      completedZoneIds: Set<String>.from(
        json['completedZoneIds'] as List<Object?>? ?? const [],
      ),
      completedChecklistStepIndexesByZone: parseChecklistStepIndexesByZone(
        json['completedChecklistStepIndexesByZone'],
      ),
      stayDetails: rawStayDetails is Map<String, Object?>
          ? StayDetails.fromJson(rawStayDetails)
          : const StayDetails(),
      findings: [
        for (final item in rawFindings)
          if (item is Map<String, Object?>) Finding.fromJson(item),
      ],
    );
  }
}

class ExportedReport {
  const ExportedReport({required this.fileName, required this.path});

  final String fileName;
  final String path;
}

String encodePrivacyCheckSnapshot(PrivacyCheckSnapshot snapshot) {
  return jsonEncode(snapshot.toJson());
}

PrivacyCheckSnapshot decodePrivacyCheckSnapshot(String encoded) {
  final Object? decoded;

  try {
    decoded = jsonDecode(encoded);
  } on FormatException {
    return const PrivacyCheckSnapshot(completedZoneIds: {}, findings: []);
  }

  if (decoded is! Map<String, Object?>) {
    return const PrivacyCheckSnapshot(completedZoneIds: {}, findings: []);
  }

  return PrivacyCheckSnapshot.fromJson(decoded);
}

Map<String, Set<int>> parseChecklistStepIndexesByZone(Object? raw) {
  if (raw is! Map<String, Object?>) {
    return const {};
  }

  final progress = <String, Set<int>>{};

  for (final entry in raw.entries) {
    final rawStepIndexes = entry.value;
    if (rawStepIndexes is! List<Object?>) {
      continue;
    }

    final stepIndexes = <int>{};
    for (final item in rawStepIndexes) {
      if (item is int && item >= 0) {
        stepIndexes.add(item);
      }
    }

    if (stepIndexes.isNotEmpty) {
      progress[entry.key] = stepIndexes;
    }
  }

  return progress;
}

Map<String, Set<int>> copyChecklistStepIndexesByZone(
  Map<String, Set<int>> source,
) {
  return {
    for (final entry in source.entries)
      if (entry.value.isNotEmpty) entry.key: Set<int>.from(entry.value),
  };
}

abstract class EvidencePicker {
  Future<String?> pickFromCamera();

  Future<String?> pickFromGallery();
}

abstract class ReportExporter {
  Future<ExportedReport> export({
    required Set<String> completedZoneIds,
    required Map<String, Set<int>> completedChecklistStepIndexesByZone,
    required List<Finding> findings,
    required StayDetails stayDetails,
  });
}

abstract class ReportSharer {
  Future<void> share(ExportedReport report);
}

class PdfReportExporter implements ReportExporter {
  @override
  Future<ExportedReport> export({
    required Set<String> completedZoneIds,
    required Map<String, Set<int>> completedChecklistStepIndexesByZone,
    required List<Finding> findings,
    required StayDetails stayDetails,
  }) async {
    final bytes = await buildReportPdfBytes(
      completedZoneIds: completedZoneIds,
      completedChecklistStepIndexesByZone: completedChecklistStepIndexesByZone,
      findings: findings,
      stayDetails: stayDetails,
    );
    final directory = await getApplicationDocumentsDirectory();
    final fileName = 'hotel_privacy_check_${_timestampForFileName()}.pdf';
    final file = File('${directory.path}${Platform.pathSeparator}$fileName');

    await file.writeAsBytes(bytes, flush: true);

    return ExportedReport(fileName: fileName, path: file.path);
  }
}

class SharePlusReportSharer implements ReportSharer {
  @override
  Future<void> share(ExportedReport report) async {
    await share_plus.SharePlus.instance.share(
      share_plus.ShareParams(
        files: [
          share_plus.XFile(
            report.path,
            name: report.fileName,
            mimeType: 'application/pdf',
          ),
        ],
        subject: '酒店隐私检查报告',
        text: '酒店隐私检查报告：${report.fileName}',
        title: '分享酒店隐私检查报告',
      ),
    );
  }
}

class ImagePickerEvidencePicker implements EvidencePicker {
  ImagePickerEvidencePicker({ImagePicker? imagePicker})
    : _imagePicker = imagePicker ?? ImagePicker();

  final ImagePicker _imagePicker;

  @override
  Future<String?> pickFromCamera() async {
    final image = await _imagePicker.pickImage(
      source: ImageSource.camera,
      imageQuality: 88,
    );
    return image?.path;
  }

  @override
  Future<String?> pickFromGallery() async {
    final image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 88,
    );
    return image?.path;
  }
}

String photoCountLabel(int count) => count == 1 ? '1 photo' : '$count photos';

String photoAttachedLabel(int count) =>
    count == 1 ? '1 photo attached' : '$count photos attached';

String evidenceFileName(String path) {
  final normalized = path.replaceAll('\\', '/');
  final parts = normalized.split('/').where((part) => part.isNotEmpty);

  if (parts.isEmpty) {
    return path;
  }

  return parts.last;
}

String formatRecordedAt(String createdAtIso) {
  if (createdAtIso.isEmpty) {
    return '';
  }

  final recordedAt = DateTime.tryParse(createdAtIso);
  if (recordedAt == null) {
    return '';
  }

  final utc = recordedAt.toUtc();
  String two(int value) => value.toString().padLeft(2, '0');

  return '${utc.year}-${two(utc.month)}-${two(utc.day)} '
      '${two(utc.hour)}:${two(utc.minute)} UTC';
}

class ChecklistProgressSummary {
  const ChecklistProgressSummary({
    required this.completedStepCount,
    required this.totalStepCount,
    required this.zoneProgress,
  });

  final int completedStepCount;
  final int totalStepCount;
  final List<ZoneChecklistProgress> zoneProgress;
}

class ZoneChecklistProgress {
  const ZoneChecklistProgress({
    required this.zoneName,
    required this.completedStepCount,
    required this.totalStepCount,
  });

  final String zoneName;
  final int completedStepCount;
  final int totalStepCount;
}

class ChecklistCoverageGap {
  const ChecklistCoverageGap({
    required this.zoneId,
    required this.zoneName,
    required this.stepIndex,
    required this.step,
  });

  final String zoneId;
  final String zoneName;
  final int stepIndex;
  final String step;
}

ChecklistProgressSummary calculateChecklistProgress(
  Map<String, Set<int>> completedStepIndexesByZone,
) {
  var completedStepCount = 0;
  var totalStepCount = 0;
  final zoneProgress = <ZoneChecklistProgress>[];

  for (final zone in sweepZones) {
    final totalForZone = zone.checklist.length;
    final completedForZone =
        (completedStepIndexesByZone[zone.id] ?? const <int>{})
            .where((stepIndex) => stepIndex >= 0 && stepIndex < totalForZone)
            .toSet()
            .length;

    completedStepCount += completedForZone;
    totalStepCount += totalForZone;
    zoneProgress.add(
      ZoneChecklistProgress(
        zoneName: zone.name,
        completedStepCount: completedForZone,
        totalStepCount: totalForZone,
      ),
    );
  }

  return ChecklistProgressSummary(
    completedStepCount: completedStepCount,
    totalStepCount: totalStepCount,
    zoneProgress: zoneProgress,
  );
}

String checklistProgressLine(ChecklistProgressSummary progress) {
  return 'Checklist progress: ${progress.completedStepCount} of '
      '${progress.totalStepCount} steps checked';
}

List<ChecklistCoverageGap> calculateChecklistCoverageGaps(
  Map<String, Set<int>> completedStepIndexesByZone,
) {
  final gaps = <ChecklistCoverageGap>[];

  for (final zone in sweepZones) {
    final completedIndexes =
        (completedStepIndexesByZone[zone.id] ?? const <int>{})
            .where(
              (stepIndex) =>
                  stepIndex >= 0 && stepIndex < zone.checklist.length,
            )
            .toSet();

    for (final entry in zone.checklist.indexed) {
      if (completedIndexes.contains(entry.$1)) {
        continue;
      }

      gaps.add(
        ChecklistCoverageGap(
          zoneId: zone.id,
          zoneName: zone.name,
          stepIndex: entry.$1,
          step: entry.$2,
        ),
      );
    }
  }

  return gaps;
}

String _coverageGapCountLabel(int gapCount) {
  if (gapCount == 0) {
    return 'All checklist steps checked';
  }

  if (gapCount == 1) {
    return '1 checklist step remaining';
  }

  return '$gapCount checklist steps remaining';
}

String buildReportDraft({
  required Set<String> completedZoneIds,
  Map<String, Set<int>> completedChecklistStepIndexesByZone = const {},
  required List<Finding> findings,
  StayDetails stayDetails = const StayDetails(),
  String generatedAtIso = '',
}) {
  final generatedAt = formatRecordedAt(
    generatedAtIso.isEmpty
        ? DateTime.now().toUtc().toIso8601String()
        : generatedAtIso,
  );
  final riskSummary = calculateRiskSummary(
    completedZoneIds: completedZoneIds,
    findings: findings,
  );
  final checkedZones = sweepZones
      .where((zone) => completedZoneIds.contains(zone.id))
      .map((zone) => zone.name)
      .toList();
  final checklistProgress = calculateChecklistProgress(
    completedChecklistStepIndexesByZone,
  );
  final coverageGaps = calculateChecklistCoverageGaps(
    completedChecklistStepIndexesByZone,
  );
  final reportReadiness = calculateReportReadiness(
    completedChecklistStepIndexesByZone: completedChecklistStepIndexesByZone,
    findings: findings,
    stayDetails: stayDetails,
  );
  final buffer = StringBuffer()
    ..writeln('酒店隐私检查报告')
    ..writeln('Hotel privacy check report')
    ..writeln('生成时间：$generatedAt')
    ..writeln('风险分数：${riskSummary.score}')
    ..writeln('Generated at: $generatedAt')
    ..writeln('Risk: ${riskBandStyles[riskSummary.band]!.label}')
    ..writeln('Risk score: ${riskSummary.score}')
    ..writeln('Risk factors:');
  for (final line in riskFactorLines(riskSummary)) {
    buffer.writeln('- $line');
  }
  buffer
    ..writeln(
      'Checked zones: ${checkedZones.isEmpty ? 'None' : checkedZones.join(', ')}',
    )
    ..writeln(checklistProgressLine(checklistProgress))
    ..writeln('Reviewed findings: ${findings.length}');

  buffer.writeln('Checklist progress by zone:');
  for (final zoneProgress in checklistProgress.zoneProgress) {
    buffer.writeln(
      '- ${zoneProgress.zoneName}: ${zoneProgress.completedStepCount} of '
      '${zoneProgress.totalStepCount} steps checked',
    );
  }

  buffer
    ..writeln('Coverage gaps:')
    ..writeln('Remaining checklist steps: ${coverageGaps.length}');
  for (final gap in coverageGaps) {
    buffer.writeln('- ${gap.zoneName}: ${gap.step}');
  }

  buffer
    ..writeln('Report readiness:')
    ..writeln(reportReadiness.title)
    ..writeln(reportReadiness.detail);
  for (final item in reportReadiness.items) {
    buffer.writeln('- ${item.title}: ${item.detail}');
  }

  if (findings.isNotEmpty) {
    final reviewCounts = calculateReviewStatusCounts(findings);
    buffer.writeln('Review summary:');
    for (final entry in reviewStatusStyles.entries) {
      buffer.writeln('${entry.value.label}: ${reviewCounts[entry.key] ?? 0}');
    }
  }

  if (stayDetails.hasAny) {
    buffer.writeln('Stay details:');
    if (stayDetails.hotelName.trim().isNotEmpty) {
      buffer.writeln('Hotel: ${stayDetails.hotelName.trim()}');
    }
    if (stayDetails.roomNumber.trim().isNotEmpty) {
      buffer.writeln('Room: ${stayDetails.roomNumber.trim()}');
    }
    if (stayDetails.bookingPlatform.trim().isNotEmpty) {
      buffer.writeln('Booking/platform: ${stayDetails.bookingPlatform.trim()}');
    }
    if (stayDetails.supportContact.trim().isNotEmpty) {
      buffer.writeln('Support contact: ${stayDetails.supportContact.trim()}');
    }
  }

  if (findings.isEmpty) {
    buffer.writeln('Findings: No reviewed findings recorded.');
  } else {
    buffer.writeln('Findings:');
    for (final finding in findings) {
      final risk = riskLevels[finding.risk]!.label;
      buffer.writeln('$risk - ${finding.title} (${finding.location})');
      if (finding.zoneId.isNotEmpty) {
        buffer.writeln('Zone: ${zoneNameForId(finding.zoneId)}');
      }
      final recordedAt = formatRecordedAt(finding.createdAtIso);
      if (recordedAt.isNotEmpty) {
        buffer.writeln('Recorded at: $recordedAt');
      }
      buffer.writeln(
        'Review status: ${reviewStatusStyles[finding.reviewStatus]!.label}',
      );
      buffer.writeln('Photo attachments: ${finding.evidencePaths.length}');
      if (finding.evidencePaths.isNotEmpty) {
        final fileNames = finding.evidencePaths
            .map(evidenceFileName)
            .join(', ');
        buffer.writeln('Attachment files: $fileNames');
      }
      if (finding.notes.isNotEmpty) {
        buffer.writeln('Notes: ${finding.notes}');
      }
    }
  }

  buffer.writeln('Recommended actions:');
  for (final step in recommendedActionSteps(riskSummary.band)) {
    buffer.writeln('- ${step.title}: ${step.detail}');
  }

  buffer
    ..writeln(
      'Boundary: This report records visible room checks and user-reviewed clues only.',
    )
    ..writeln('No unknown camera streams were opened or accessed.');

  return buffer.toString().trim();
}

Future<Uint8List> buildReportPdfBytes({
  required Set<String> completedZoneIds,
  Map<String, Set<int>> completedChecklistStepIndexesByZone = const {},
  required List<Finding> findings,
  StayDetails stayDetails = const StayDetails(),
  String generatedAtIso = '',
}) async {
  final draft = buildReportDraft(
    completedZoneIds: completedZoneIds,
    completedChecklistStepIndexesByZone: completedChecklistStepIndexesByZone,
    findings: findings,
    stayDetails: stayDetails,
    generatedAtIso: generatedAtIso,
  );
  final cjkFontData = await rootBundle.load(reportPdfCjkFontAsset);
  final cjkFont = pw.Font.ttf(cjkFontData);
  final document = pw.Document(title: '酒店隐私检查报告');
  final lines = draft.split('\n');

  document.addPage(
    pw.MultiPage(
      margin: const pw.EdgeInsets.all(32),
      theme: pw.ThemeData.withFont(base: cjkFont, bold: cjkFont),
      build: (context) {
        return [
          pw.Header(
            level: 0,
            child: pw.Text(
              '酒店隐私检查报告',
              style: pw.TextStyle(
                font: cjkFont,
                fontSize: 22,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.SizedBox(height: 8),
          for (final line in lines.skip(1))
            pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 6),
              child: pw.Text(line, style: pw.TextStyle(font: cjkFont)),
            ),
        ];
      },
    ),
  );

  return document.save();
}

RiskSummary calculateRiskSummary({
  required Set<String> completedZoneIds,
  required List<Finding> findings,
}) {
  final uncheckedZoneCount = sweepZones.length - completedZoneIds.length;
  final activeFindings = findings
      .where((finding) => finding.reviewStatus != ReviewStatus.falseAlarm)
      .toList();
  final falseAlarmCount = findings.length - activeFindings.length;

  if (activeFindings.isEmpty) {
    return RiskSummary(
      score: 0,
      band: RiskBand.baseline,
      uncheckedZoneCount: uncheckedZoneCount,
      primaryAction: _primaryActionForBand(RiskBand.baseline),
      falseAlarmCount: falseAlarmCount,
    );
  }

  final riskPoints = activeFindings.fold<int>(0, (total, finding) {
    return total +
        switch (finding.risk) {
          RiskLevel.low => 10,
          RiskLevel.medium => 25,
          RiskLevel.high => 45,
        };
  });
  final attachmentCount = activeFindings.fold<int>(
    0,
    (total, finding) => total + finding.evidencePaths.length,
  );
  final evidencePoints = (attachmentCount * 3).clamp(0, 15);
  final uncertaintyPoints = ((uncheckedZoneCount / sweepZones.length) * 17)
      .round();
  final score = (riskPoints + evidencePoints + uncertaintyPoints).clamp(0, 100);
  final band = switch (score) {
    >= 60 => RiskBand.high,
    >= 35 => RiskBand.elevated,
    > 0 => RiskBand.watch,
    _ => RiskBand.baseline,
  };

  return RiskSummary(
    score: score,
    band: band,
    uncheckedZoneCount: uncheckedZoneCount,
    primaryAction: _primaryActionForBand(band),
    activeFindingCount: activeFindings.length,
    evidenceAttachmentCount: attachmentCount,
    falseAlarmCount: falseAlarmCount,
  );
}

List<String> riskFactorLines(RiskSummary summary) {
  return [
    'Active findings: ${summary.activeFindingCount}',
    'Evidence attachments: ${summary.evidenceAttachmentCount}',
    'Unchecked zones: ${summary.uncheckedZoneCount} of ${sweepZones.length}',
    if (summary.falseAlarmCount > 0)
      'False alarms excluded: ${summary.falseAlarmCount}',
  ];
}

Map<ReviewStatus, int> calculateReviewStatusCounts(List<Finding> findings) {
  final counts = <ReviewStatus, int>{
    for (final status in ReviewStatus.values) status: 0,
  };

  for (final finding in findings) {
    counts[finding.reviewStatus] = (counts[finding.reviewStatus] ?? 0) + 1;
  }

  return counts;
}

List<ActionStep> recommendedActionSteps(RiskBand band) {
  return switch (band) {
    RiskBand.high => const [
      ActionStep(
        title: 'Preserve the scene',
        detail: 'Do not touch or remove the suspected object.',
        icon: Icons.pan_tool_alt_outlined,
      ),
      ActionStep(
        title: 'Capture context photos',
        detail: 'Photograph the room position and close-up evidence.',
        icon: Icons.add_a_photo_outlined,
      ),
      ActionStep(
        title: 'Request written support',
        detail: 'Ask the hotel or platform for a written incident note.',
        icon: Icons.description_outlined,
      ),
      ActionStep(
        title: 'Escalate if needed',
        detail: 'Contact local authorities if you believe recording occurred.',
        icon: Icons.support_agent_outlined,
      ),
    ],
    RiskBand.elevated => const [
      ActionStep(
        title: 'Capture context photos',
        detail: 'Photograph the object, surrounding wall, and room position.',
        icon: Icons.add_a_photo_outlined,
      ),
      ActionStep(
        title: 'Re-check the zone',
        detail: 'Compare the clue from another angle before escalating.',
        icon: Icons.search_outlined,
      ),
      ActionStep(
        title: 'Request another room',
        detail: 'Ask staff or platform support for a safer room if uneasy.',
        icon: Icons.meeting_room_outlined,
      ),
    ],
    RiskBand.watch => const [
      ActionStep(
        title: 'Finish unchecked zones',
        detail:
            'Complete the remaining room sweep before drawing a conclusion.',
        icon: Icons.fact_check_outlined,
      ),
      ActionStep(
        title: 'Re-check flagged clues',
        detail: 'Review the same spot from two angles before adding evidence.',
        icon: Icons.visibility_outlined,
      ),
    ],
    RiskBand.baseline => const [
      ActionStep(
        title: 'Finish unchecked zones',
        detail: 'Complete the guided sweep and record reviewed clues only.',
        icon: Icons.fact_check_outlined,
      ),
      ActionStep(
        title: 'Keep evidence local',
        detail: 'Attach photos only when you decide they are useful.',
        icon: Icons.lock_outline,
      ),
    ],
  };
}

ReportReadiness calculateReportReadiness({
  required Map<String, Set<int>> completedChecklistStepIndexesByZone,
  required List<Finding> findings,
  required StayDetails stayDetails,
}) {
  final activeFindings = findings
      .where((finding) => finding.reviewStatus != ReviewStatus.falseAlarm)
      .toList();
  final unresolvedReviewCount = activeFindings
      .where((finding) => finding.reviewStatus == ReviewStatus.needsReview)
      .length;
  final findingsWithoutEvidenceCount = activeFindings
      .where((finding) => finding.evidencePaths.isEmpty)
      .length;
  final coverageGapCount = calculateChecklistCoverageGaps(
    completedChecklistStepIndexesByZone,
  ).length;
  final items = <ReportReadinessItem>[];

  if (stayDetails.hotelName.trim().isEmpty ||
      stayDetails.roomNumber.trim().isEmpty) {
    items.add(
      const ReportReadinessItem(
        title: 'Add hotel and room',
        detail: 'Add the hotel name and room number before sharing.',
        icon: Icons.meeting_room_outlined,
      ),
    );
  }

  if (unresolvedReviewCount > 0) {
    items.add(
      ReportReadinessItem(
        title: 'Review unresolved findings',
        detail: _unresolvedFindingLabel(unresolvedReviewCount),
        icon: Icons.rate_review_outlined,
      ),
    );
  }

  if (findingsWithoutEvidenceCount > 0) {
    items.add(
      ReportReadinessItem(
        title: 'Attach evidence photos',
        detail: _missingEvidenceLabel(findingsWithoutEvidenceCount),
        icon: Icons.add_a_photo_outlined,
      ),
    );
  }

  if (coverageGapCount > 0) {
    items.add(
      ReportReadinessItem(
        title: 'Finish manual checks',
        detail: _openChecklistStepLabel(coverageGapCount),
        icon: Icons.fact_check_outlined,
      ),
    );
  }

  if (items.isEmpty) {
    return const ReportReadiness(
      title: 'Ready to share',
      detail:
          'Core context, review status, evidence notes, and checklist '
          'coverage are ready.',
      items: [],
    );
  }

  final itemLabel = items.length == 1 ? '1 item' : '${items.length} items';

  return ReportReadiness(
    title: 'Needs attention',
    detail: '$itemLabel to resolve before sharing.',
    items: items,
  );
}

String _unresolvedFindingLabel(int count) {
  if (count == 1) {
    return '1 finding still needs review.';
  }

  return '$count findings still need review.';
}

String _missingEvidenceLabel(int count) {
  if (count == 1) {
    return '1 active finding has no evidence photo.';
  }

  return '$count active findings have no evidence photo.';
}

String _openChecklistStepLabel(int count) {
  if (count == 1) {
    return '1 checklist step still open.';
  }

  return '$count checklist steps still open.';
}

Map<String, ZoneRiskState> calculateZoneRiskStatuses({
  required Set<String> completedZoneIds,
  required List<Finding> findings,
}) {
  final statuses = <String, ZoneRiskState>{
    for (final zone in sweepZones)
      zone.id: completedZoneIds.contains(zone.id)
          ? ZoneRiskState.checked
          : ZoneRiskState.unchecked,
  };

  for (final finding in findings) {
    if (finding.reviewStatus == ReviewStatus.falseAlarm) {
      continue;
    }

    if (finding.zoneId.isNotEmpty && isKnownZoneId(finding.zoneId)) {
      statuses[finding.zoneId] = ZoneRiskState.flagged;
      continue;
    }

    final text = '${finding.title} ${finding.location}'.toLowerCase();
    for (final zone in sweepZones) {
      if (_findingMatchesZone(text, zone)) {
        statuses[zone.id] = ZoneRiskState.flagged;
      }
    }
  }

  return statuses;
}

String inferZoneIdFromFindingText(String title, String location) {
  final text = '$title $location'.toLowerCase();
  for (final zone in sweepZones) {
    if (_findingMatchesZone(text, zone)) {
      return zone.id;
    }
  }

  return '';
}

bool isKnownZoneId(String zoneId) {
  return sweepZones.any((zone) => zone.id == zoneId);
}

SweepZone zoneForId(String zoneId) {
  return sweepZones.firstWhere(
    (zone) => zone.id == zoneId,
    orElse: () => SweepZone(
      id: zoneId,
      name: zoneId,
      focus: '',
      checklist: const [],
      icon: Icons.place_outlined,
    ),
  );
}

String zoneNameForId(String zoneId) {
  return zoneForId(zoneId).name;
}

bool _findingMatchesZone(String normalizedFindingText, SweepZone zone) {
  final zoneName = zone.name.toLowerCase();
  final zoneIdWords = zone.id.replaceAll('_', ' ').toLowerCase();

  return normalizedFindingText.contains(zoneName) ||
      normalizedFindingText.contains(zoneIdWords);
}

String _primaryActionForBand(RiskBand band) {
  return switch (band) {
    RiskBand.high =>
      'Preserve evidence and ask the hotel, platform, or authorities for help.',
    RiskBand.elevated =>
      'Re-check the flagged area and capture a clear evidence photo.',
    RiskBand.watch =>
      'Finish the remaining sweep zones before drawing a conclusion.',
    RiskBand.baseline =>
      'Continue the guided sweep and only record clues you can review.',
  };
}

String _timestampForFileName() {
  final now = DateTime.now();
  String two(int value) => value.toString().padLeft(2, '0');

  return '${now.year}${two(now.month)}${two(now.day)}_'
      '${two(now.hour)}${two(now.minute)}${two(now.second)}';
}

const sweepZones = <SweepZone>[
  SweepZone(
    id: 'bedside',
    name: 'Bedside',
    focus: 'Lamps, outlets, hooks, clocks',
    checklist: [
      'Scan lamps, outlets, hooks, and clocks from eye level.',
      'Use a flashlight to look for pinhole reflections.',
      'Photograph anything suspicious before touching it.',
    ],
    icon: Icons.bed_outlined,
  ),
  SweepZone(
    id: 'tv_wall',
    name: 'TV wall',
    focus: 'Set-top boxes, vents, decor',
    checklist: [
      'Check set-top boxes, vents, frames, and decorations from the front.',
      'Look for unusual holes, lenses, loose wires, or fresh adhesive marks.',
      'Record suspicious items as findings instead of opening devices.',
    ],
    icon: Icons.tv_outlined,
  ),
  SweepZone(
    id: 'ceiling',
    name: 'Ceiling',
    focus: 'Smoke sensors, sprinklers, air vents',
    checklist: [
      'Visually inspect sensors, sprinklers, air vents, and ceiling corners.',
      'Use zoom or a photo from floor level before getting close.',
      'Do not remove covers or tamper with safety equipment.',
    ],
    icon: Icons.sensors_outlined,
  ),
  SweepZone(
    id: 'bathroom',
    name: 'Bathroom',
    focus: 'Mirrors, shelves, towel hooks',
    checklist: [
      'Check mirror edges, shelves, towel hooks, and outlets.',
      'Use oblique light to look for reflective dots in dark surfaces.',
      'Capture context photos before moving personal items.',
    ],
    icon: Icons.bathtub_outlined,
  ),
  SweepZone(
    id: 'desk',
    name: 'Desk area',
    focus: 'Chargers, routers, ornaments',
    checklist: [
      'Inspect chargers, routers, clocks, and ornaments without opening them.',
      'Look for unexpected indicator lights, holes, or mismatched objects.',
      'Document concerns and ask staff before handling property.',
    ],
    icon: Icons.desk_outlined,
  ),
];

const signalModules = <SignalModule>[
  SignalModule(
    title: 'Optical',
    status: 'Flash reflection',
    icon: Icons.flare_outlined,
    color: Color(0xFF0E7C86),
  ),
  SignalModule(
    title: 'Infrared',
    status: 'Dark-room check',
    icon: Icons.nightlight_outlined,
    color: Color(0xFF6B5B95),
  ),
  SignalModule(
    title: 'Room map',
    status: 'Zone priority',
    icon: Icons.map_outlined,
    color: Color(0xFF4F772D),
  ),
  SignalModule(
    title: 'Network',
    status: 'Exposure only',
    icon: Icons.wifi_protected_setup_outlined,
    color: Color(0xFFB7791F),
  ),
];

const findingTypes = <FindingType>[
  FindingType(label: 'Optical reflection', icon: Icons.radio_button_checked),
  FindingType(label: 'Infrared light', icon: Icons.nightlight_outlined),
  FindingType(label: 'Object anomaly', icon: Icons.outlet_outlined),
  FindingType(label: 'Network exposure', icon: Icons.wifi_tethering),
];

const riskLevels = <RiskLevel, RiskLevelStyle>{
  RiskLevel.low: RiskLevelStyle(label: 'Low', color: Color(0xFF2F6B7D)),
  RiskLevel.medium: RiskLevelStyle(label: 'Medium', color: Color(0xFFB7791F)),
  RiskLevel.high: RiskLevelStyle(label: 'High', color: Color(0xFFB42318)),
};

const reviewStatusStyles = <ReviewStatus, ReviewStatusStyle>{
  ReviewStatus.needsReview: ReviewStatusStyle(
    label: 'Needs review',
    color: Color(0xFF64706A),
  ),
  ReviewStatus.documented: ReviewStatusStyle(
    label: 'Documented',
    color: Color(0xFF2F6B7D),
  ),
  ReviewStatus.falseAlarm: ReviewStatusStyle(
    label: 'False alarm',
    color: Color(0xFF4F772D),
  ),
};

const riskBandStyles = <RiskBand, RiskBandStyle>{
  RiskBand.baseline: RiskBandStyle(
    label: 'Risk baseline',
    icon: Icons.verified_user_outlined,
    color: Color(0xFF2F6B7D),
  ),
  RiskBand.watch: RiskBandStyle(
    label: 'Watch list',
    icon: Icons.visibility_outlined,
    color: Color(0xFF4F772D),
  ),
  RiskBand.elevated: RiskBandStyle(
    label: 'Elevated risk',
    icon: Icons.priority_high_outlined,
    color: Color(0xFFB7791F),
  ),
  RiskBand.high: RiskBandStyle(
    label: 'High risk',
    icon: Icons.report_problem_outlined,
    color: Color(0xFFB42318),
  ),
};

const zoneRiskStateStyles = <ZoneRiskState, ZoneRiskStateStyle>{
  ZoneRiskState.unchecked: ZoneRiskStateStyle(
    label: 'Unchecked',
    color: Color(0xFF64706A),
  ),
  ZoneRiskState.checked: ZoneRiskStateStyle(
    label: 'Checked',
    color: Color(0xFF2F6B7D),
  ),
  ZoneRiskState.flagged: ZoneRiskStateStyle(
    label: 'Flagged',
    color: Color(0xFFB42318),
  ),
};
