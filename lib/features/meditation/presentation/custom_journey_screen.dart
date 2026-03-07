import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:eirafocus/core/data/database_helper.dart';
import 'package:eirafocus/features/meditation/domain/meditation_journey.dart';

class CustomJourneyScreen extends StatefulWidget {
  const CustomJourneyScreen({super.key});

  @override
  State<CustomJourneyScreen> createState() => _CustomJourneyScreenState();
}

class _CustomJourneyScreenState extends State<CustomJourneyScreen> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  int _durationMinutes = 5;
  final List<_PromptEntry> _prompts = [
    _PromptEntry(timestampSeconds: 0, text: ''),
  ];

  bool get _isValid =>
      _nameController.text.trim().isNotEmpty &&
      _prompts.isNotEmpty &&
      _prompts.every((p) => p.text.isNotEmpty);

  Future<void> _save() async {
    if (!_isValid) return;
    final prompts = _prompts
        .map((p) => GuidedPrompt(
              timestamp: Duration(seconds: p.timestampSeconds),
              text: p.text,
            ))
        .toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    await DatabaseHelper.instance.insertCustomJourney(
      _nameController.text.trim(),
      _descController.text.trim().isEmpty
          ? 'Custom guided journey'
          : _descController.text.trim(),
      _durationMinutes,
      prompts,
    );
    if (mounted) Navigator.pop(context, true);
  }

  void _addPrompt() {
    // Default to next logical timestamp
    final lastTs = _prompts.isEmpty ? 0 : _prompts.last.timestampSeconds;
    setState(() {
      _prompts.add(_PromptEntry(timestampSeconds: lastTs + 30, text: ''));
    });
  }

  void _removePrompt(int index) {
    if (_prompts.length > 1) {
      setState(() => _prompts.removeAt(index));
    }
  }

  String _formatTimestamp(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m}m ${s.toString().padLeft(2, '0')}s';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Journey'),
        actions: [
          TextButton(
            onPressed: _isValid ? _save : null,
            child: Text(
              'Save',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                color: _isValid ? cs.primary : cs.onSurface.withAlpha(60),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        children: [
          // Name
          TextField(
            controller: _nameController,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              labelText: 'Journey Name',
              hintText: 'e.g. Morning Calm',
            ),
          ),
          const SizedBox(height: 14),

          // Description
          TextField(
            controller: _descController,
            decoration: const InputDecoration(
              labelText: 'Description (optional)',
              hintText: 'A short description of this journey',
            ),
          ),
          const SizedBox(height: 20),

          // Duration
          Text('DURATION', style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 1,
            color: cs.onSurface.withAlpha(90),
          )),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [3, 5, 10, 15, 20, 30].map((m) {
              final selected = _durationMinutes == m;
              return GestureDetector(
                onTap: () => setState(() => _durationMinutes = m),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: selected ? cs.primary.withAlpha(20) : cs.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: selected ? cs.primary.withAlpha(80) : cs.outline.withAlpha(80),
                    ),
                  ),
                  child: Text(
                    '$m min',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: selected ? cs.primary : cs.onSurface.withAlpha(120),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 24),

          // Prompts
          Row(
            children: [
              Expanded(
                child: Text('PROMPTS', style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                  color: cs.onSurface.withAlpha(90),
                )),
              ),
              GestureDetector(
                onTap: _addPrompt,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: cs.primary.withAlpha(20),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_rounded, size: 16, color: cs.primary),
                      const SizedBox(width: 4),
                      Text('Add',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: cs.primary,
                          )),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          ..._prompts.asMap().entries.map((entry) {
            final i = entry.key;
            final p = entry.value;
            return _PromptTile(
              index: i,
              prompt: p,
              maxSeconds: _durationMinutes * 60,
              onTextChanged: (text) => setState(() => p.text = text),
              onTimestampChanged: (ts) => setState(() => p.timestampSeconds = ts),
              onRemove: _prompts.length > 1 ? () => _removePrompt(i) : null,
              formatTimestamp: _formatTimestamp,
            );
          }),

          const SizedBox(height: 16),
          Text(
            'Prompts appear at the specified time during the session.',
            style: tt.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _PromptEntry {
  int timestampSeconds;
  String text;
  _PromptEntry({required this.timestampSeconds, required this.text});
}

class _PromptTile extends StatelessWidget {
  final int index;
  final _PromptEntry prompt;
  final int maxSeconds;
  final ValueChanged<String> onTextChanged;
  final ValueChanged<int> onTimestampChanged;
  final VoidCallback? onRemove;
  final String Function(int) formatTimestamp;

  const _PromptTile({
    required this.index,
    required this.prompt,
    required this.maxSeconds,
    required this.onTextChanged,
    required this.onTimestampChanged,
    this.onRemove,
    required this.formatTimestamp,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cs.outline.withAlpha(80)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: cs.primary.withAlpha(15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    formatTimestamp(prompt.timestampSeconds),
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: cs.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Slider(
                    value: prompt.timestampSeconds.toDouble(),
                    min: 0,
                    max: maxSeconds.toDouble(),
                    divisions: maxSeconds > 0 ? maxSeconds ~/ 5 : 1,
                    onChanged: (v) => onTimestampChanged(v.toInt()),
                  ),
                ),
                if (onRemove != null)
                  GestureDetector(
                    onTap: onRemove,
                    child: Icon(Icons.close_rounded, size: 18, color: cs.onSurface.withAlpha(80)),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              onChanged: onTextChanged,
              controller: TextEditingController(text: prompt.text)
                ..selection = TextSelection.collapsed(offset: prompt.text.length),
              maxLines: 2,
              style: GoogleFonts.inter(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Prompt text...',
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
