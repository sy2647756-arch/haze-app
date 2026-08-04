import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/cognitive_correction_repository.dart';

export '../data/cognitive_correction_repository.dart';

class CognitiveCorrectionPage extends StatefulWidget {
  const CognitiveCorrectionPage({super.key});

  @override
  State<CognitiveCorrectionPage> createState() =>
      _CognitiveCorrectionPageState();
}

class _CognitiveCorrectionPageState extends State<CognitiveCorrectionPage> {
  static const _magenta = Color(0xFFC640A3);
  static const _yellow = Color(0xFFFFE229);

  static const _evidenceOptions = [
    'I saw or heard it directly',
    'I am interpreting a message or silence',
    'Someone else told me',
    'I do not have direct evidence yet',
  ];
  static const _alternativeOptions = [
    'They may be busy, tired, or distracted',
    'I may be missing important context',
    'This could be about their situation, not my worth',
    'I can wait for one clearer signal before deciding',
  ];

  final _situation = TextEditingController();
  final _evidenceNotes = TextEditingController();
  final _alternativeNotes = TextEditingController();
  final _balancedNotes = TextEditingController();
  final _evidence = <String>{};
  final _alternatives = <String>{};
  int? _emotionIntensity;
  int _step = 0;
  CcRecord? _result;
  bool _saving = false;

  @override
  void dispose() {
    _situation.dispose();
    _evidenceNotes.dispose();
    _alternativeNotes.dispose();
    _balancedNotes.dispose();
    super.dispose();
  }

  bool get _canContinue => switch (_step) {
    0 => _situation.text.trim().isNotEmpty,
    1 => _evidence.isNotEmpty,
    2 => _alternatives.isNotEmpty,
    3 => _emotionIntensity != null,
    _ => true,
  };

  Future<void> _next() async {
    if (!_canContinue || _saving) return;
    if (_step < 3) {
      setState(() => _step++);
      return;
    }
    setState(() => _saving = true);
    final record = _buildResult();
    await CcRepo.add(record);
    if (!mounted) return;
    setState(() {
      _result = record;
      _step = 4;
      _saving = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Saved to Correction History and Report.')),
    );
  }

  void _back() {
    if (_step == 0) {
      Navigator.of(context).maybePop();
    } else if (_step < 4) {
      setState(() => _step--);
    } else {
      Navigator.of(context).maybePop();
    }
  }

  CcRecord _buildResult() {
    final biases = _detectBiases(_situation.text);
    final balanced = _balancedNotes.text.trim().isNotEmpty
        ? _balancedNotes.text.trim()
        : _suggestBalancedThought();
    final explanation = _biasExplanation(biases.first);
    final intensity = _emotionIntensity ?? 0;
    return CcRecord(
      situation: _situation.text,
      distortions: biases,
      evidenceChoices: _evidence.toList(),
      evidenceNotes: _evidenceNotes.text,
      alternativeChoices: _alternatives.toList(),
      alternativeNotes: _alternativeNotes.text,
      emotionIntensity: intensity,
      balancedThought: balanced,
      explanation: explanation,
      confidenceNote:
          'This reflection is based on your answers. It is a guide, not a diagnosis or proof of another person’s intentions.',
      nextAction: intensity >= 80
          ? 'Pause for two minutes, then revisit this thought when the feeling is less intense.'
          : 'Wait for one concrete signal before drawing a conclusion, then choose one calm next step.',
      createdAt: DateTime.now(),
    );
  }

  List<String> _detectBiases(String value) {
    final text = value.toLowerCase();
    final biases = <String>[];
    if (text.contains('should') ||
        text.contains('must') ||
        text.contains('have to')) {
      biases.add('Should Statements');
    }
    if (text.contains('always') ||
        text.contains('never') ||
        text.contains('everyone') ||
        text.contains('no one') ||
        text.contains('failure')) {
      biases.add('All-or-Nothing Thinking');
    }
    if (text.contains('worst') ||
        text.contains('ruined') ||
        text.contains('disaster') ||
        text.contains('everything is over')) {
      biases.add('Catastrophizing');
    }
    if (text.contains('think') ||
        text.contains('care') ||
        text.contains('ignore') ||
        text.contains('reply') ||
        _evidence.contains('I do not have direct evidence yet') ||
        _evidence.contains('I am interpreting a message or silence')) {
      biases.add('Mind Reading');
    }
    if (biases.isEmpty) biases.add('Emotional Reasoning');
    return biases.take(2).toList();
  }

  String _suggestBalancedThought() {
    if (_alternatives.contains(
      'This could be about their situation, not my worth',
    )) {
      return 'This situation may reflect what they are dealing with, not my worth. I can wait for clearer evidence before deciding what it means.';
    }
    if (_alternatives.contains('They may be busy, tired, or distracted')) {
      return 'There are ordinary reasons for this situation. A delay or brief response does not tell me the whole story.';
    }
    if (_alternatives.contains('I may be missing important context')) {
      return 'I may not have the full context yet. I can hold more than one explanation until I know more.';
    }
    return 'I can pause this conclusion and wait for one clearer signal before deciding what it means.';
  }

  String _biasExplanation(String bias) => switch (bias) {
    'Mind Reading' =>
      'Mind reading means treating a guess about someone’s thoughts as if it were a confirmed fact.',
    'Catastrophizing' =>
      'Catastrophizing means jumping from one difficult moment to the worst possible outcome.',
    'All-or-Nothing Thinking' =>
      'All-or-nothing thinking turns a mixed situation into an absolute success or failure.',
    'Should Statements' =>
      'Should statements apply rigid rules that can intensify guilt, pressure, or resentment.',
    _ =>
      'Emotional reasoning means treating a strong feeling as proof that a conclusion must be true.',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/cc/bg.png',
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) =>
                  const ColoredBox(color: Color(0xFFF2F5FF)),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _header(),
                if (_step < 4) _progress(),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 260),
                    child: _stepBody(),
                  ),
                ),
                if (_step < 4) _continueButton(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _header() {
    return SizedBox(
      height: 96,
      child: Padding(
        padding: const EdgeInsets.only(top: 38),
        child: Stack(
          alignment: Alignment.center,
          children: [
            const Center(
              child: Text(
                'Cognitive Correction',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ),
            Positioned(
              left: 8,
              child: IconButton(
                onPressed: _back,
                icon: const Icon(Icons.chevron_left),
              ),
            ),
            Positioned(
              right: 48,
              child: IconButton(
                tooltip: 'Correction History',
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CcHistoryPage()),
                ),
                icon: const Icon(Icons.history, color: _magenta, size: 21),
              ),
            ),
            Positioned(
              right: 10,
              child: GestureDetector(
                key: const ValueKey('correction-close'),
                onTap: () => Navigator.of(context).maybePop(),
                child: const CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.close, size: 20, color: Colors.black87),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _progress() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(27, 2, 27, 10),
      child: Row(
        children: [
          for (var index = 0; index < 5; index++) ...[
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                height: 4,
                decoration: BoxDecoration(
                  color: index <= _step ? _magenta : Colors.white60,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            if (index < 4) const SizedBox(width: 6),
          ],
        ],
      ),
    );
  }

  Widget _stepBody() => switch (_step) {
    0 => _sceneStep(),
    1 => _evidenceStep(),
    2 => _alternativeStep(),
    3 => _emotionStep(),
    _ => _resultStep(),
  };

  Widget _page({
    required String title,
    required String subtitle,
    required List<Widget> children,
  }) {
    return ListView(
      key: ValueKey(_step),
      padding: const EdgeInsets.fromLTRB(27, 4, 27, 14),
      children: [
        Text(
          'STEP ${_step + 1} OF 5',
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: _magenta,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: _magenta,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 12,
            height: 1.45,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 18),
        ...children,
      ],
    );
  }

  Widget _sceneStep() {
    return _page(
      title: 'What exactly happened?',
      subtitle:
          'Describe one specific moment: who was involved, what happened, and what thought appeared.',
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF8D8),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Text(
            'Example: “They read my message two hours ago and did not reply. I thought they no longer cared about me.”',
            style: TextStyle(fontSize: 13, height: 1.4),
          ),
        ),
        const SizedBox(height: 16),
        _textBox(
          controller: _situation,
          hint: 'Describe the specific scene…',
          minLines: 6,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 10),
        const Text(
          'Private reflection · Used only to create this correction result.',
          style: TextStyle(fontSize: 11, color: Colors.black45),
        ),
      ],
    );
  }

  Widget _evidenceStep() {
    return _page(
      title: 'What facts do you actually have?',
      subtitle:
          'Choose the closest answer. Facts are things you directly saw, heard, or can verify.',
      children: [
        for (final option in _evidenceOptions)
          _choiceTile(
            option,
            selected: _evidence.contains(option),
            onTap: () => setState(() {
              _evidence
                ..clear()
                ..add(option);
            }),
          ),
        const SizedBox(height: 12),
        _optionalLabel('Optional details'),
        _textBox(
          controller: _evidenceNotes,
          hint: 'Add a verifiable detail if it helps…',
          minLines: 3,
        ),
      ],
    );
  }

  Widget _alternativeStep() {
    return _page(
      title: 'What else could explain it?',
      subtitle:
          'Select one or more plausible explanations. You do not have to believe them completely yet.',
      children: [
        for (final option in _alternativeOptions)
          _choiceTile(
            option,
            selected: _alternatives.contains(option),
            onTap: () => setState(() {
              _alternatives.contains(option)
                  ? _alternatives.remove(option)
                  : _alternatives.add(option);
            }),
          ),
        const SizedBox(height: 12),
        _optionalLabel('Optional alternative'),
        _textBox(
          controller: _alternativeNotes,
          hint: 'Write another possible explanation…',
          minLines: 3,
        ),
      ],
    );
  }

  Widget _emotionStep() {
    return _page(
      title: 'How intense is the feeling now?',
      subtitle:
          'Choose the closest level. This helps Haze suggest a realistic next action.',
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final value in [20, 40, 60, 80, 100])
              ChoiceChip(
                key: ValueKey('emotion-$value'),
                label: Text('$value%'),
                selected: _emotionIntensity == value,
                selectedColor: _yellow,
                side: BorderSide(
                  color: _emotionIntensity == value ? _magenta : Colors.white,
                ),
                onSelected: (_) => setState(() => _emotionIntensity = value),
              ),
          ],
        ),
        const SizedBox(height: 24),
        _optionalLabel('Optional balanced wording'),
        const SizedBox(height: 4),
        const Text(
          'Leave this blank and Haze will create a balanced thought from your choices.',
          style: TextStyle(fontSize: 12, color: Colors.black45),
        ),
        const SizedBox(height: 10),
        _textBox(
          controller: _balancedNotes,
          hint: 'Example: I do not know the full story yet…',
          minLines: 4,
        ),
      ],
    );
  }

  Widget _resultStep() {
    final result = _result!;
    return ListView(
      key: const ValueKey('correction-result'),
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
      children: [
        const Icon(Icons.auto_awesome, color: _magenta, size: 34),
        const SizedBox(height: 6),
        const Text(
          'Your correction is ready',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 23, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        const Text(
          'Saved automatically to Correction History and Report.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: Colors.black54),
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _resultSection('Original thought', result.situation),
              _resultSection(
                'Thinking pattern',
                result.distortions.join(' · '),
                accent: _magenta,
              ),
              _resultSection('Balanced thought', result.balancedThought),
              _resultSection('Why this pattern fits', result.explanation),
              _resultSection('Confidence note', result.confidenceNote),
              _resultSection('Next action', result.nextAction, last: true),
            ],
          ),
        ),
        const SizedBox(height: 16),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: _magenta,
            foregroundColor: _yellow,
            minimumSize: const Size.fromHeight(50),
          ),
          onPressed: () => Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const CcHistoryPage())),
          child: const Text('View Correction History'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).maybePop(),
          child: const Text('Done'),
        ),
      ],
    );
  }

  Widget _resultSection(
    String label,
    String value, {
    Color accent = Colors.black87,
    bool last = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: _magenta,
              letterSpacing: 0.25,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              height: 1.45,
              fontWeight: label == 'Thinking pattern'
                  ? FontWeight.w700
                  : FontWeight.w400,
              color: accent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _continueButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
      child: Center(
        child: SizedBox(
          width: 247,
          height: 48,
          child: FilledButton(
            key: const ValueKey('correction-next'),
            style: FilledButton.styleFrom(
              backgroundColor: _magenta,
              disabledBackgroundColor: _magenta.withValues(alpha: 0.28),
              foregroundColor: _yellow,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            onPressed: _canContinue && !_saving
                ? () => unawaited(_next())
                : null,
            child: Text(_saving ? 'Creating result…' : 'Next'),
          ),
        ),
      ),
    );
  }

  Widget _choiceTile(
    String label, {
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: selected ? const Color(0xFFFFF8D8) : Colors.white70,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: [
                Icon(
                  selected ? Icons.check_circle : Icons.circle_outlined,
                  color: selected ? _magenta : Colors.black26,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(label, style: const TextStyle(height: 1.3)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _textBox({
    required TextEditingController controller,
    required String hint,
    required int minLines,
    ValueChanged<String>? onChanged,
  }) {
    return TextField(
      controller: controller,
      minLines: minLines,
      maxLines: minLines + 2,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.88),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _optionalLabel(String value) => Text(
    value,
    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
  );
}

class CcHistoryPage extends StatefulWidget {
  const CcHistoryPage({super.key});

  @override
  State<CcHistoryPage> createState() => _CcHistoryPageState();
}

class _CcHistoryPageState extends State<CcHistoryPage> {
  List<CcRecord>? _records;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final records = await CcRepo.all();
    if (mounted) setState(() => _records = records);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Correction History'),
        backgroundColor: const Color(0xFFFCEEF6),
      ),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFCEEF6), Color(0xFFE8EEFF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: _records == null
            ? const Center(child: CircularProgressIndicator())
            : _records!.isEmpty
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text(
                    'No corrections yet.\nYour completed results will appear here automatically.',
                    textAlign: TextAlign.center,
                    style: TextStyle(height: 1.5, color: Colors.black54),
                  ),
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
                itemCount: _records!.length,
                separatorBuilder: (_, _) => const SizedBox(height: 14),
                itemBuilder: (_, index) => _recordCard(_records![index]),
              ),
      ),
    );
  }

  Widget _recordCard(CcRecord record) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            DateFormat('MMM d, yyyy · HH:mm').format(record.createdAt),
            style: const TextStyle(fontSize: 11, color: Colors.black45),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final bias in record.distortions)
                Chip(
                  label: Text(bias),
                  visualDensity: VisualDensity.compact,
                  backgroundColor: const Color(0xFFFCE1F0),
                ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Original thought',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          Text(record.situation, style: const TextStyle(height: 1.4)),
          const SizedBox(height: 10),
          const Text(
            'Balanced thought',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          Text(record.balancedThought, style: const TextStyle(height: 1.4)),
          if (record.explanation.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              record.explanation,
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ],
        ],
      ),
    );
  }
}
