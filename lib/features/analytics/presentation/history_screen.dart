import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:eirafocus/core/theme/theme.dart';
import 'package:eirafocus/core/data/database_helper.dart';
import 'package:eirafocus/features/meditation/domain/meditation_models.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<MeditationSession> _allSessions = [];
  bool _loading = true;

  // Search & filter state
  String _searchQuery = '';
  String _typeFilter = 'All'; // 'All', 'Breathing', 'Meditation'
  String? _tagFilter;
  DateTimeRange? _dateRange;

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    final sessions = await DatabaseHelper.instance.getSessions();
    if (mounted) {
      setState(() {
        _allSessions = sessions;
        _loading = false;
      });
    }
  }

  Set<String> get _allTags {
    final tags = <String>{};
    for (final s in _allSessions) {
      tags.addAll(s.tags);
    }
    return tags;
  }

  List<MeditationSession> get _filteredSessions {
    return _allSessions.where((s) {
      if (_typeFilter != 'All' && s.type != _typeFilter) return false;
      if (_searchQuery.isNotEmpty &&
          !s.method.toLowerCase().contains(_searchQuery.toLowerCase())) {
        return false;
      }
      if (_tagFilter != null && !s.tags.contains(_tagFilter)) return false;
      if (_dateRange != null) {
        final date = DateTime(s.timestamp.year, s.timestamp.month, s.timestamp.day);
        if (date.isBefore(_dateRange!.start) || date.isAfter(_dateRange!.end)) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  String _formatDuration(int secs) {
    final m = secs ~/ 60;
    final s = secs % 60;
    if (m > 0) return '${m}m ${s}s';
    return '${s}s';
  }

  Future<void> _exportCsv() async {
    final sessions = _filteredSessions;
    if (sessions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No sessions to export')),
      );
      return;
    }
    final buf = StringBuffer();
    buf.writeln('date,type,method,duration_minutes,tags,journal');
    for (final s in sessions) {
      final date = DateFormat('yyyy-MM-dd HH:mm').format(s.timestamp);
      final mins = (s.durationSeconds / 60).toStringAsFixed(1);
      final tags = s.tags.join(';');
      final journal = (s.journal ?? '').replaceAll('"', '""');
      buf.writeln('$date,${s.type},${s.method},$mins,"$tags","$journal"');
    }
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/eirafocus_sessions.csv');
    await file.writeAsString(buf.toString());
    await Share.shareXFiles([XFile(file.path)], text: 'EiraFocus Sessions');
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: now,
      initialDateRange: _dateRange,
    );
    if (range != null) {
      setState(() => _dateRange = range);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download_outlined),
            tooltip: 'Export CSV',
            onPressed: _exportCsv,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
          : Column(
              children: [
                // Search bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 4, 24, 8),
                  child: TextField(
                    onChanged: (v) => setState(() => _searchQuery = v),
                    decoration: InputDecoration(
                      hintText: 'Search methods...',
                      prefixIcon: const Icon(Icons.search_rounded, size: 20),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),

                // Filter chips
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      _FilterChip(
                        label: 'All',
                        selected: _typeFilter == 'All',
                        onTap: () => setState(() => _typeFilter = 'All'),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Breathing',
                        selected: _typeFilter == 'Breathing',
                        onTap: () => setState(() => _typeFilter = 'Breathing'),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Meditation',
                        selected: _typeFilter == 'Meditation',
                        onTap: () => setState(() => _typeFilter = 'Meditation'),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: _pickDateRange,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: _dateRange != null
                                ? cs.primary.withAlpha(20)
                                : cs.surface,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: _dateRange != null
                                  ? cs.primary.withAlpha(80)
                                  : cs.outline.withAlpha(80),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.calendar_today_rounded,
                                  size: 14,
                                  color: _dateRange != null ? cs.primary : cs.onSurface.withAlpha(100)),
                              if (_dateRange != null) ...[
                                const SizedBox(width: 4),
                                GestureDetector(
                                  onTap: () => setState(() => _dateRange = null),
                                  child: Icon(Icons.close_rounded, size: 14, color: cs.primary),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Tag filter
                if (_allTags.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(left: 24, right: 24, top: 8),
                    child: SizedBox(
                      height: 32,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          _FilterChip(
                            label: 'All Tags',
                            selected: _tagFilter == null,
                            onTap: () => setState(() => _tagFilter = null),
                          ),
                          ..._allTags.map((tag) => Padding(
                            padding: const EdgeInsets.only(left: 6),
                            child: _FilterChip(
                              label: tag,
                              selected: _tagFilter == tag,
                              onTap: () => setState(() => _tagFilter = _tagFilter == tag ? null : tag),
                            ),
                          )),
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: 8),

                // Sessions list
                Expanded(child: _buildSessionsList(cs, tt)),
              ],
            ),
    );
  }

  Widget _buildSessionsList(ColorScheme cs, TextTheme tt) {
    final sessions = _filteredSessions;
    if (sessions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(48),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.history_rounded, size: 56, color: cs.onSurface.withAlpha(50)),
              const SizedBox(height: 16),
              Text(
                _allSessions.isEmpty ? 'No sessions yet' : 'No matching sessions',
                style: tt.titleLarge?.copyWith(color: cs.onSurface.withAlpha(120)),
              ),
              const SizedBox(height: 8),
              Text(
                _allSessions.isEmpty
                    ? 'Your completed sessions will show up here'
                    : 'Try adjusting your search or filters',
                textAlign: TextAlign.center,
                style: tt.bodySmall,
              ),
            ],
          ),
        ),
      );
    }

    // Group by date
    final Map<String, List<MeditationSession>> grouped = {};
    for (final s in sessions) {
      final key = DateFormat('MMM dd, yyyy').format(s.timestamp);
      grouped.putIfAbsent(key, () => []).add(s);
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
      itemCount: grouped.length,
      itemBuilder: (context, i) {
        final date = grouped.keys.elementAt(i);
        final items = grouped[date]!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (i > 0) const SizedBox(height: 20),
            Text(
              date,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: cs.onSurface.withAlpha(90),
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 8),
            ...items.map((s) => _buildSessionTile(s, cs)),
          ],
        );
      },
    );
  }

  Widget _buildSessionTile(MeditationSession session, ColorScheme cs) {
    final isBreathing = session.type == 'Breathing';
    final color = isBreathing ? EiraTheme.breathingColor : EiraTheme.meditationColor;
    final time = DateFormat('h:mm a').format(session.timestamp);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cs.outline.withAlpha(80)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withAlpha(18),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isBreathing ? Icons.air_rounded : Icons.self_improvement_rounded,
                    color: color,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(session.method, style: Theme.of(context).textTheme.titleSmall),
                      const SizedBox(height: 2),
                      Text(
                        time,
                        style: GoogleFonts.inter(fontSize: 12, color: cs.onSurface.withAlpha(90)),
                      ),
                    ],
                  ),
                ),
                Text(
                  _formatDuration(session.durationSeconds),
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ],
            ),
            if (session.tags.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: session.tags.map((tag) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: cs.primary.withAlpha(12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(SessionTag.emojiFor(tag), style: const TextStyle(fontSize: 10)),
                      const SizedBox(width: 3),
                      Text(tag, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w500, color: cs.primary.withAlpha(180))),
                    ],
                  ),
                )).toList(),
              ),
            ],
            if (session.journal != null && session.journal!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: cs.primary.withAlpha(8),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.edit_note_rounded, size: 16, color: cs.onSurface.withAlpha(80)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        session.journal!,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: cs.onSurface.withAlpha(150),
                          fontStyle: FontStyle.italic,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? cs.primary.withAlpha(20) : cs.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? cs.primary.withAlpha(80) : cs.outline.withAlpha(80),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? cs.primary : cs.onSurface.withAlpha(120),
          ),
        ),
      ),
    );
  }
}
