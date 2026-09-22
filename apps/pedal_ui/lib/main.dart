import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() => runApp(const PedalApp());

abstract final class LostChrome {
  static const midnight = Color(0xff030a1a);
  static const navy = Color(0xff071b42);
  static const ocean = Color(0xff083d86);
  static const cobalt = Color(0xff126dc3);
  static const electric = Color(0xff29b9ff);
  static const ice = Color(0xffbceeff);
  static const pearl = Color(0xffeffbff);
  static const lime = Color(0xffc9ff68);
  static const glass = Color(0xff102b5b);
}

class PedalApp extends StatelessWidget {
  const PedalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: const ColorScheme.dark(
          primary: LostChrome.electric,
          onPrimary: LostChrome.midnight,
          secondary: LostChrome.ice,
          onSecondary: LostChrome.midnight,
          surface: LostChrome.glass,
          onSurface: LostChrome.pearl,
          error: Color(0xffff6c8c),
          onError: LostChrome.midnight,
        ),
        scaffoldBackgroundColor: LostChrome.midnight,
        textTheme: ThemeData.dark().textTheme.apply(
              bodyColor: LostChrome.pearl,
              displayColor: LostChrome.pearl,
              fontFamily: 'Arial',
            ),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: Color(0xff081938),
          modalBackgroundColor: Color(0xff081938),
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            side: BorderSide(color: Color(0xff5bcfff), width: 1.2),
          ),
        ),
        dialogTheme: const DialogThemeData(
          backgroundColor: Color(0xff0a2048),
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(20)),
            side: BorderSide(color: Color(0xff5bcfff)),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            foregroundColor: LostChrome.midnight,
            backgroundColor: LostChrome.ice,
            textStyle:
                const TextStyle(fontWeight: FontWeight.w900, letterSpacing: .5),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: LostChrome.ice,
            side: const BorderSide(color: Color(0xff6bcfff)),
            textStyle:
                const TextStyle(fontWeight: FontWeight.w800, letterSpacing: .4),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
          ),
        ),
        sliderTheme: const SliderThemeData(
          activeTrackColor: LostChrome.electric,
          inactiveTrackColor: Color(0xff254a81),
          thumbColor: LostChrome.pearl,
          overlayColor: Color(0x3329b9ff),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: const Color(0xff0d2b59),
          selectedColor: LostChrome.ice,
          secondarySelectedColor: LostChrome.ice,
          labelStyle: const TextStyle(
              color: LostChrome.pearl, fontWeight: FontWeight.w700),
          secondaryLabelStyle: const TextStyle(
              color: LostChrome.midnight, fontWeight: FontWeight.w900),
          side: const BorderSide(color: Color(0xff4d8ec9)),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        useMaterial3: true,
      ),
      home: const RigScreen(),
    );
  }
}

class _AeroDspBrand extends StatelessWidget {
  const _AeroDspBrand();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'AERO>>DSP',
          style: TextStyle(
            color: LostChrome.ice,
            fontSize: 17,
            fontWeight: FontWeight.w900,
            fontStyle: FontStyle.italic,
            letterSpacing: -0.9,
            shadows: [
              Shadow(color: LostChrome.electric, blurRadius: 9),
              Shadow(color: Color(0xff2c55c9), offset: Offset(2, 2)),
            ],
          ),
        ),
        Text(
          'PEDALBOARD // V0',
          style: TextStyle(
            color: LostChrome.lime,
            fontSize: 8,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }
}

class _ChromeBackdrop extends StatelessWidget {
  const _ChromeBackdrop({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                LostChrome.midnight,
                Color(0xff061d4a),
                LostChrome.midnight
              ],
            ),
          ),
        ),
        const IgnorePointer(
          child: CustomPaint(painter: _ChromeRipplePainter()),
        ),
        Positioned(
          top: -85,
          right: -35,
          child: _GlassOrb(size: 210, color: Color(0x3329b9ff)),
        ),
        Positioned(
          bottom: 22,
          left: -68,
          child: _GlassOrb(size: 180, color: Color(0x222f7ee9)),
        ),
        child,
      ],
    );
  }
}

class _GlassOrb extends StatelessWidget {
  const _GlassOrb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withValues(alpha: .95),
              color.withValues(alpha: .08),
              Colors.transparent
            ],
          ),
          border: Border.all(color: LostChrome.ice.withValues(alpha: .2)),
          boxShadow: [BoxShadow(color: color, blurRadius: 44)],
        ),
      );
}

class _ChromeRipplePainter extends CustomPainter {
  const _ChromeRipplePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = LostChrome.ice.withValues(alpha: .16);
    final path = Path()
      ..moveTo(-30, size.height * .27)
      ..cubicTo(size.width * .19, size.height * .06, size.width * .36,
          size.height * .48, size.width * .58, size.height * .22)
      ..cubicTo(size.width * .75, size.height * .02, size.width * .87,
          size.height * .36, size.width + 30, size.height * .13);
    canvas.drawPath(path, paint);
    canvas.drawPath(path.shift(Offset(0, 9)),
        paint..color = LostChrome.electric.withValues(alpha: .1));
    canvas.drawCircle(Offset(size.width * .16, size.height * .78), 96,
        paint..color = LostChrome.ice.withValues(alpha: .08));
  }

  @override
  bool shouldRepaint(covariant _ChromeRipplePainter oldDelegate) => false;
}

class RigScreen extends StatefulWidget {
  const RigScreen({super.key});

  @override
  State<RigScreen> createState() => _RigScreenState();
}

class _RigScreenState extends State<RigScreen> {
  final ControlClient _client = ControlClient();
  final CatalogClient _catalog = CatalogClient();
  EngineSnapshot _engine = const EngineSnapshot.disconnected();
  MeterSnapshot _meters = const MeterSnapshot.silent();
  StreamSubscription<EngineSnapshot>? _subscription;
  StreamSubscription<MeterSnapshot>? _meterSubscription;
  Process? _previewPlayer;
  bool _previewBusy = false;
  bool _previewPlaying = false;
  String? _importedPreviewPath;

  @override
  void initState() {
    super.initState();
    _subscription = _client.snapshots.listen((snapshot) {
      if (mounted) setState(() => _engine = snapshot);
    });
    _meterSubscription = _client.meters.listen((snapshot) {
      if (mounted) setState(() => _meters = snapshot);
    });
    _client.connect();
  }

  @override
  void dispose() {
    _previewPlayer?.kill();
    _subscription?.cancel();
    _meterSubscription?.cancel();
    _client.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final compactHeader = MediaQuery.sizeOf(context).width < 600;
    return Scaffold(
      body: _ChromeBackdrop(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                IconButtonTheme(
                  data: IconButtonThemeData(
                    style: IconButton.styleFrom(
                      // The Pi's 480px-wide touch display needs all primary
                      // controls in one row, including Daily Drill.
                      minimumSize: Size.square(compactHeader ? 36 : 48),
                      padding: EdgeInsets.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                  child: Row(
                    children: [
                      const _AeroDspBrand(),
                      const Spacer(),
                      IconButton(
                        tooltip: 'Tuner',
                        onPressed: _engine.connected ? _showTuner : null,
                        icon: Icon(
                          Icons.tune,
                          color: _engine.tunerEnabled ? LostChrome.lime : null,
                        ),
                      ),
                      IconButton(
                        tooltip: 'Daily Drill',
                        onPressed: _engine.connected ? _showDailyLesson : null,
                        icon: const Icon(Icons.school_outlined),
                      ),
                      IconButton(
                        tooltip: 'AI Tone Maker',
                        onPressed: _showToneMaker,
                        icon: const Icon(Icons.auto_awesome),
                      ),
                      IconButton(
                        tooltip:
                            _previewPlaying ? 'Stop test audio' : 'Test audio',
                        onPressed: _engine.connected && !_previewBusy
                            ? _previewPlaying
                                ? _stopPreview
                                : _choosePreview
                            : null,
                        icon: _previewBusy
                            ? const SizedBox.square(
                                dimension: 17,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Icon(_previewPlaying
                                ? Icons.stop_circle_outlined
                                : Icons.music_note),
                      ),
                      IconButton(
                        tooltip: _engine.connected
                            ? (_engine.bypassed ? 'Engage rig' : 'Bypass rig')
                            : 'Reconnect engine',
                        onPressed: _engine.connected
                            ? () => _client.setBypass(!_engine.bypassed)
                            : _client.connect,
                        icon: Icon(
                          Icons.power_settings_new,
                          color: !_engine.connected
                              ? LostChrome.ice
                              : _engine.bypassed
                                  ? Theme.of(context).colorScheme.error
                                  : LostChrome.lime,
                        ),
                      ),
                      if (!compactHeader) ...[
                        TextButton.icon(
                          onPressed: _showTone3000,
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                          ),
                          icon: const Icon(Icons.cloud_download_outlined,
                              size: 18),
                          label: const Text('T3K'),
                        ),
                        TextButton.icon(
                          onPressed: _showAudioOutputs,
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                          ),
                          icon: const Icon(Icons.volume_up_outlined, size: 18),
                          label: const Text('SND'),
                        ),
                      ] else ...[
                        IconButton(
                          tooltip: 'TONE3000',
                          onPressed: _showTone3000,
                          icon: const Icon(Icons.cloud_download_outlined),
                        ),
                        IconButton(
                          tooltip: 'Output',
                          onPressed: _showAudioOutputs,
                          icon: const Icon(Icons.volume_up_outlined),
                        ),
                      ],
                      const SizedBox(width: 6),
                      Tooltip(
                        message:
                            _engine.connected ? 'Engine online' : 'Connecting',
                        child: _StatusDot(connected: _engine.connected),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: _engine.connected ? _showPresets : null,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0x991a5eac),
                          Color(0x774fc9ee),
                          Color(0x992a5598)
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xffa9eaff)),
                      boxShadow: const [
                        BoxShadow(color: Color(0x6639bfff), blurRadius: 16)
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.album,
                            size: 17, color: LostChrome.ice),
                        const SizedBox(width: 7),
                        Flexible(
                          child: Text(
                            _engine.presetTitle,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -.8,
                            ),
                          ),
                        ),
                        const SizedBox(width: 3),
                        const Icon(Icons.expand_more,
                            size: 22, color: LostChrome.ice),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _engine.modelName,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(context).colorScheme.secondary),
                ),
                const SizedBox(height: 6),
                _MeterStrip(snapshot: _meters),
                const SizedBox(height: 8),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final boardHeight = math.max(
                        118.0,
                        constraints.maxHeight * .6,
                      );
                      final utilityHeight = math.max(
                        90.0,
                        constraints.maxHeight - boardHeight - 8,
                      );
                      return SingleChildScrollView(
                        child: ConstrainedBox(
                          constraints:
                              BoxConstraints(minHeight: constraints.maxHeight),
                          child: Column(
                            children: [
                              SizedBox(
                                height: boardHeight,
                                child: Pedalboard(
                                  snapshot: _engine,
                                  onSlotOpen: _showSlotControls,
                                  onSlotToggle: (slot, bypassed) =>
                                      _toggleSlot(slot, bypassed),
                                  onEffectOpen: _showEffectControls,
                                  onEffectToggle: _toggleEffect,
                                  onLooperOpen: _showLooperControls,
                                  onAddPedal: _showAddPedal,
                                ),
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                height: utilityHeight,
                                child: _UtilityDeck(
                                  snapshot: _meters,
                                  onOpenRiffVault: _showRiffVault,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showModelLibrary({ModelSlot? initialSlot}) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => FractionallySizedBox(
        heightFactor: 0.78,
        child: ModelLibrarySheet(
          catalog: _catalog,
          engineConnected: _engine.connected,
          selectedPrePath: _engine.preModel,
          selectedAmpPath: _engine.model,
          onSelected: _client.selectModel,
          initialSlot: initialSlot,
        ),
      ),
    );
  }

  void _stopPreview() {
    _previewPlayer?.kill();
    setState(() {
      _previewPlayer = null;
      _previewPlaying = false;
    });
  }

  Future<void> _choosePreview() async {
    final choice = await showModalBottomSheet<PreviewChoice>(
      context: context,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('TEST AUDIO',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              const Text(
                  'Compare the same clean guitar with and without your rig.'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pop(
                        context,
                        const PreviewChoice(PreviewSource.builtIn, false),
                      ),
                      icon: const Icon(Icons.hearing),
                      label: const Text('DRY'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => Navigator.pop(
                        context,
                        const PreviewChoice(PreviewSource.builtIn, true),
                      ),
                      icon: const Icon(Icons.graphic_eq),
                      label: const Text('YOUR RIG'),
                    ),
                  ),
                ],
              ),
              if (_importedPreviewPath != null) ...[
                const SizedBox(height: 10),
                Text('IMPORTED: ${_importedPreviewPath!.split('/').last}',
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(
                          context,
                          PreviewChoice(PreviewSource.file, false,
                              path: _importedPreviewPath),
                        ),
                        child: const Text('PLAY DRY'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton.tonal(
                        onPressed: () => Navigator.pop(
                          context,
                          PreviewChoice(PreviewSource.file, true,
                              path: _importedPreviewPath),
                        ),
                        child: const Text('PLAY THROUGH RIG'),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () => Navigator.pop(
                  context,
                  const PreviewChoice(PreviewSource.pickFile, true),
                ),
                icon: const Icon(Icons.audio_file),
                label: const Text('CHOOSE YOUR OWN WAV'),
              ),
              TextButton.icon(
                onPressed: () => Navigator.pop(
                  context,
                  const PreviewChoice(PreviewSource.synthetic, true),
                ),
                icon: const Icon(Icons.science_outlined),
                label: const Text('USE SYNTHETIC TEST RIFF'),
              ),
            ],
          ),
        ),
      ),
    );
    if (choice == null || !mounted) return;
    if (choice.source == PreviewSource.pickFile) {
      final path = await _pickWavFile();
      if (path == null || !mounted) return;
      setState(() => _importedPreviewPath = path);
      await _playPreview(
        PreviewChoice(PreviewSource.file, true, path: path),
      );
      return;
    }
    await _playPreview(choice);
  }

  Future<String?> _pickWavFile() async {
    try {
      final result = await Process.run('zenity', [
        '--file-selection',
        '--title=Choose a clean guitar WAV',
        '--file-filter=Wave audio | *.wav *.WAV',
      ]);
      if (result.exitCode != 0) return null;
      final path = (result.stdout as String).trim();
      return path.isEmpty ? null : path;
    } on ProcessException {
      if (!mounted) return null;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('The system file picker is unavailable')),
      );
      return null;
    }
  }

  Future<void> _playPreview(PreviewChoice choice) async {
    setState(() => _previewBusy = true);
    try {
      final preview = await _client.renderPreview(
        source: choice.source,
        processed: choice.processed,
        path: choice.path,
      );
      final player = await _startPreviewPlayer(preview.path);
      if (!mounted) {
        player.kill();
        return;
      }
      setState(() {
        _previewPlayer = player;
        _previewBusy = false;
        _previewPlaying = true;
      });
      unawaited(player.stdout.drain());
      unawaited(player.stderr.drain());
      await player.exitCode;
      if (mounted && identical(_previewPlayer, player)) {
        setState(() {
          _previewPlayer = null;
          _previewPlaying = false;
        });
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _previewBusy = false;
        _previewPlaying = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Preview failed: $error')),
      );
    }
  }

  Future<Process> _startPreviewPlayer(String path) async {
    try {
      return await Process.start('pw-play', [path]);
    } on ProcessException {
      try {
        return await Process.start('aplay', [path]);
      } on ProcessException {
        throw const EngineException(
            'Install PipeWire tools (pw-play) or ALSA utilities (aplay)');
      }
    }
  }

  void _showTone3000() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => FractionallySizedBox(
        heightFactor: 0.92,
        child: Tone3000BrowserSheet(
          catalog: _catalog,
          engineConnected: _engine.connected,
          onSelected: _client.selectModel,
        ),
      ),
    );
  }

  Future<void> _showToneMaker() async {
    final application = await showModalBottomSheet<AiToneApplication>(
      context: context,
      isScrollControlled: true,
      builder: (context) => FractionallySizedBox(
        heightFactor: .92,
        child: ToneMakerSheet(
          catalog: _catalog,
          engineConnected: _engine.connected,
          onApply: _applyAiTone,
        ),
      ),
    );
    if (!mounted || application == null) return;
    await _showToneMemoryFeedback(application);
  }

  Future<void> _showToneMemoryFeedback(AiToneApplication application) async {
    final note = TextEditingController();
    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('TONE CHECK'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Does this sound like “${application.memoryQuery}”?'),
            const SizedBox(height: 10),
            TextField(
              controller: note,
              maxLength: 280,
              decoration: const InputDecoration(
                labelText: 'OPTIONAL NOTE',
                hintText: 'Great with bridge humbucker…',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('NOT QUITE'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.bookmark_added_outlined),
            label: const Text('YES, SAVE'),
          ),
        ],
      ),
    );
    final message = shouldSave == true
        ? 'Tone saved to local Tone Memory.'
        : 'No tone was saved.';
    if (shouldSave == true) {
      try {
        await _catalog.saveToneMemory(application.memoryCandidate, note.text);
      } catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('$error')));
        }
        note.dispose();
        return;
      }
    }
    note.dispose();
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _applyAiTone(AiToneApplication application) async {
    if (!_engine.connected) {
      throw const EngineException(
          'Connect the audio engine before applying a tone');
    }
    // AI-selected NAM pairs can have very different idle gain. Turn on the
    // board's input-driven gate before loading them so model self-noise stays
    // closed until the player actually picks a note.
    await _client.setEffectBypass(EffectKind.gate, false);
    if (application.preModel case final pedal?) {
      await _client.selectModel(pedal, ModelSlot.pre);
    }
    await _client.selectModel(application.ampModel, ModelSlot.amp);
    for (final control in application.controls.entries) {
      await _client.setControl(control.key, control.value);
    }
    for (final effect in application.effects.entries) {
      if (!effect.value) continue;
      final pedal = switch (effect.key) {
        'eq' => OptionalPedal.eq,
        'chorus' => OptionalPedal.chorus,
        'delay' => OptionalPedal.delay,
        'reverb' => OptionalPedal.reverb,
        _ => null,
      };
      final kind = switch (effect.key) {
        'eq' => EffectKind.eq,
        'chorus' => EffectKind.chorus,
        'delay' => EffectKind.delay,
        'reverb' => EffectKind.reverb,
        _ => null,
      };
      if (pedal != null && kind != null) {
        await _client.setPedalVisible(pedal, true);
        await _client.setEffectBypass(kind, false);
      }
    }
  }

  void _showAudioOutputs() {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: FutureBuilder<List<SystemAudioOutput>>(
            future: SystemAudioService.listOutputs(),
            builder: (context, snapshot) {
              final outputs = snapshot.data;
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('OUTPUT',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  const Text('Choose where live audio and previews are heard.'),
                  const SizedBox(height: 10),
                  if (snapshot.connectionState == ConnectionState.waiting)
                    const Center(child: CircularProgressIndicator())
                  else if (snapshot.hasError ||
                      outputs == null ||
                      outputs.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 18),
                      child: Text(
                        'System output selection is unavailable on this device.',
                        textAlign: TextAlign.center,
                      ),
                    )
                  else
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: outputs.length,
                        itemBuilder: (context, index) {
                          final output = outputs[index];
                          return ListTile(
                            leading: Icon(output.isBluetooth
                                ? Icons.bluetooth_audio
                                : output.isDefault
                                    ? Icons.volume_up
                                    : Icons.speaker),
                            title: Text(output.name),
                            subtitle: output.isBluetooth
                                ? const Text('Bluetooth adds noticeable delay')
                                : null,
                            trailing: output.isDefault
                                ? const Icon(Icons.check_circle)
                                : null,
                            onTap: () async {
                              try {
                                await SystemAudioService.select(output.id);
                                if (!mounted || !context.mounted) return;
                                Navigator.pop(context);
                                ScaffoldMessenger.of(this.context).showSnackBar(
                                  SnackBar(
                                      content: Text(
                                          'Output changed to ${output.name}')),
                                );
                              } catch (error) {
                                if (!mounted || !context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text(
                                          'Could not change output: $error')),
                                );
                              }
                            },
                          );
                        },
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  void _showPresets() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => FractionallySizedBox(
        heightFactor: 0.9,
        child: PresetLibrarySheet(
          client: _client,
          currentPresetId: _engine.presetId,
          suggestedName: _engine.preset,
        ),
      ),
    );
  }

  void _showSlotControls(ModelSlot slot) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => FractionallySizedBox(
        heightFactor: 0.9,
        child: SlotControlsSheet(
          slot: slot,
          snapshot: _engine,
          onChanged: _client.setControl,
          onChangeTone: () {
            Navigator.pop(sheetContext);
            _showModelLibrary(initialSlot: slot);
          },
        ),
      ),
    );
  }

  Future<void> _showTuner() async {
    try {
      await _client.setTunerEnabled(true);
      if (!mounted) return;
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (context) => FractionallySizedBox(
          heightFactor: 0.9,
          child: TunerSheet(meters: _client.meters),
        ),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$error')));
      }
    } finally {
      try {
        await _client.setTunerEnabled(false);
      } catch (_) {
        // The next engine connection starts with the tuner disabled.
      }
    }
  }

  Future<void> _showDailyLesson() async {
    try {
      // Daily Drill uses the same clean-input analyzer as the tuner. Keeping
      // it before the rig means gain, distortion, and ambience cannot alter a
      // practice score.
      await _client.setTunerEnabled(true);
      if (!mounted) return;
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (context) => FractionallySizedBox(
          heightFactor: 0.92,
          child: DailyLessonSheet(
            meters: _client.meters,
            lessons: DailyLesson.dailySession(DateTime.now()),
            onMetronomeChanged: _client.setMetronome,
          ),
        ),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$error')));
      }
    } finally {
      try {
        await _client.setTunerEnabled(false);
      } catch (_) {
        // The next engine connection starts with the analyzer disabled.
      }
    }
  }

  void _showRiffVault() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => FractionallySizedBox(
        heightFactor: .84,
        child: RiffVaultSheet(client: _client, catalog: _catalog),
      ),
    );
  }

  void _showEffectControls(EffectKind effect) {
    final optionalPedal = switch (effect) {
      EffectKind.eq => OptionalPedal.eq,
      EffectKind.chorus => OptionalPedal.chorus,
      EffectKind.delay => OptionalPedal.delay,
      EffectKind.reverb => OptionalPedal.reverb,
      EffectKind.gate || EffectKind.compressor => null,
    };
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => FractionallySizedBox(
        heightFactor: 0.82,
        child: EffectControlsSheet(
          effect: effect,
          snapshot: _engine,
          onChanged: _client.setControl,
          onRemove:
              optionalPedal == null ? null : () => _removePedal(optionalPedal),
        ),
      ),
    );
  }

  void _showLooperControls() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => FractionallySizedBox(
        heightFactor: .82,
        child: LooperControlsSheet(
          mode: _engine.looperMode,
          bpm: _engine.looperBpm,
          bars: _engine.looperBars,
          onAction: _client.looperAction,
          onRemove: () => _removePedal(OptionalPedal.looper),
        ),
      ),
    );
  }

  void _showAddPedal() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => FractionallySizedBox(
        heightFactor: .82,
        child: AddPedalSheet(
          snapshot: _engine,
          onAdd: (pedal) async {
            try {
              await _client.setPedalVisible(pedal, true);
              if (sheetContext.mounted) Navigator.pop(sheetContext);
            } catch (error) {
              if (mounted) {
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text('$error')));
              }
            }
          },
        ),
      ),
    );
  }

  Future<bool> _removePedal(OptionalPedal pedal) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Remove ${pedal.label}?'),
        content: const Text(
          'It will disappear from this board. You can add it back later.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('REMOVE'),
          ),
        ],
      ),
    );
    if (confirmed != true) return false;
    try {
      await _client.setPedalVisible(pedal, false);
      return true;
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$error')));
      }
      return false;
    }
  }

  Future<void> _toggleSlot(ModelSlot slot, bool bypassed) async {
    try {
      await _client.setSlotBypass(slot, bypassed);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$error')),
        );
      }
    }
  }

  Future<void> _toggleEffect(EffectKind effect, bool bypassed) async {
    try {
      await _client.setEffectBypass(effect, bypassed);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$error')));
      }
    }
  }
}

enum EffectKind { gate, compressor, eq, chorus, delay, reverb }

enum OptionalPedal { eq, chorus, delay, reverb, looper }

extension OptionalPedalDetails on OptionalPedal {
  String get label => switch (this) {
        OptionalPedal.eq => 'EQ',
        OptionalPedal.chorus => 'CHORUS',
        OptionalPedal.delay => 'DELAY',
        OptionalPedal.reverb => 'REVERB',
        OptionalPedal.looper => 'LOOPER',
      };

  String get description => switch (this) {
        OptionalPedal.eq => 'Shape low, mid, and high frequencies',
        OptionalPedal.chorus => 'Add width and movement',
        OptionalPedal.delay => 'Repeat your signal over time',
        OptionalPedal.reverb => 'Add space and decay',
        OptionalPedal.looper => 'Capture and layer a performance',
      };

  IconData get icon => switch (this) {
        OptionalPedal.eq => Icons.equalizer,
        OptionalPedal.chorus => Icons.waves,
        OptionalPedal.delay => Icons.repeat,
        OptionalPedal.reverb => Icons.blur_on,
        OptionalPedal.looper => Icons.loop,
      };

  PedalCategory get category => this == OptionalPedal.looper
      ? PedalCategory.looper
      : PedalCategory.effect;

  EffectKind? get effect => switch (this) {
        OptionalPedal.eq => EffectKind.eq,
        OptionalPedal.chorus => EffectKind.chorus,
        OptionalPedal.delay => EffectKind.delay,
        OptionalPedal.reverb => EffectKind.reverb,
        OptionalPedal.looper => null,
      };
}

enum PedalCategory { utility, nam, effect, looper }

extension PedalCategoryDetails on PedalCategory {
  String get label => switch (this) {
        PedalCategory.utility => 'UTILITY',
        PedalCategory.nam => 'NAM',
        PedalCategory.effect => 'EFFECT',
        PedalCategory.looper => 'LOOPER',
      };

  Color get color => switch (this) {
        PedalCategory.utility => const Color(0xff18bfc7),
        PedalCategory.nam => const Color(0xff2679ec),
        PedalCategory.effect => const Color(0xff506bd6),
        PedalCategory.looper => const Color(0xff68bb76),
      };

  IconData get icon => switch (this) {
        PedalCategory.utility => Icons.tune,
        PedalCategory.nam => Icons.memory,
        PedalCategory.effect => Icons.auto_awesome,
        PedalCategory.looper => Icons.loop,
      };
}

extension EffectKindDetails on EffectKind {
  String get wireName => name;

  String get label => switch (this) {
        EffectKind.gate => 'GATE',
        EffectKind.compressor => 'COMP',
        EffectKind.eq => 'EQ',
        EffectKind.chorus => 'CHORUS',
        EffectKind.delay => 'DELAY',
        EffectKind.reverb => 'REVERB',
      };

  IconData get icon => switch (this) {
        EffectKind.gate => Icons.graphic_eq,
        EffectKind.compressor => Icons.compress,
        EffectKind.eq => Icons.equalizer,
        EffectKind.chorus => Icons.waves,
        EffectKind.delay => Icons.repeat,
        EffectKind.reverb => Icons.blur_on,
      };

  Color get color => switch (this) {
        EffectKind.gate => const Color(0xff1c5cc4),
        EffectKind.compressor => const Color(0xff1d8ccf),
        EffectKind.eq => const Color(0xff18b1be),
        EffectKind.chorus => const Color(0xff315ccf),
        EffectKind.delay => const Color(0xff147cd1),
        EffectKind.reverb => const Color(0xff5466cf),
      };
}

class Pedalboard extends StatelessWidget {
  const Pedalboard({
    required this.snapshot,
    required this.onSlotOpen,
    required this.onSlotToggle,
    required this.onEffectOpen,
    required this.onEffectToggle,
    required this.onLooperOpen,
    required this.onAddPedal,
    super.key,
  });

  final EngineSnapshot snapshot;
  final ValueChanged<ModelSlot> onSlotOpen;
  final Future<void> Function(ModelSlot, bool) onSlotToggle;
  final ValueChanged<EffectKind> onEffectOpen;
  final Future<void> Function(EffectKind, bool) onEffectToggle;
  final VoidCallback onLooperOpen;
  final VoidCallback onAddPedal;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final tileHeight =
              (constraints.maxHeight - 42).clamp(72.0, 126.0).toDouble();
          _PedalTile effectTile(EffectKind effect) => _PedalTile(
                label: effect.label,
                category:
                    effect == EffectKind.gate || effect == EffectKind.compressor
                        ? PedalCategory.utility
                        : PedalCategory.effect,
                status: snapshot.effectEnabled(effect) ? 'ON' : 'BYPASS',
                icon: effect.icon,
                active: snapshot.effectEnabled(effect),
                height: tileHeight,
                disabled: !snapshot.connected,
                onTap: () => onEffectOpen(effect),
                onFootswitch: () =>
                    onEffectToggle(effect, snapshot.effectEnabled(effect)),
              );
          final optionalPedals = OptionalPedal.values
              .where(snapshot.pedalVisible)
              .toList(growable: false);
          return ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xee0d3265),
                    Color(0xee08204b),
                    Color(0xee12508d)
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xff9deaff), width: 1.4),
                boxShadow: const [
                  BoxShadow(color: Color(0x6628baff), blurRadius: 18),
                  BoxShadow(
                      color: Color(0x77000418),
                      offset: Offset(0, 7),
                      blurRadius: 9),
                ],
              ),
              child: Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(12, 7, 12, 2),
                    child: Row(
                      children: [
                        Icon(Icons.cable, size: 14, color: LostChrome.lime),
                        SizedBox(width: 5),
                        Text('SIGNAL PATH',
                            style: TextStyle(
                              color: LostChrome.ice,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.4,
                              fontSize: 11,
                            )),
                        Spacer(),
                        Text('SWIPE TO EXPLORE',
                            style: TextStyle(
                                color: Color(0xff9ed9ff), fontSize: 10)),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Scrollbar(
                      child: Semantics(
                        label: 'Scrollable pedal signal path',
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.fromLTRB(9, 3, 9, 16),
                          children: [
                            effectTile(EffectKind.gate),
                            const _SignalArrow(),
                            effectTile(EffectKind.compressor),
                            const _SignalArrow(),
                            _PedalTile(
                              label: 'DRIVE NAM',
                              category: PedalCategory.nam,
                              status: snapshot.preModel == null
                                  ? 'EMPTY'
                                  : snapshot.preBypassed
                                      ? 'BYPASS'
                                      : 'ON',
                              icon: Icons.bolt,
                              active: snapshot.preModel != null &&
                                  !snapshot.preBypassed,
                              height: tileHeight,
                              disabled: !snapshot.connected,
                              onTap: () => onSlotOpen(ModelSlot.pre),
                              onFootswitch: () => onSlotToggle(
                                  ModelSlot.pre, !snapshot.preBypassed),
                            ),
                            const _SignalArrow(),
                            _PedalTile(
                              label: 'AMP NAM',
                              category: PedalCategory.nam,
                              status: snapshot.model == null
                                  ? 'EMPTY'
                                  : snapshot.ampBypassed
                                      ? 'BYPASS'
                                      : 'ON',
                              icon: Icons.speaker,
                              active: snapshot.model != null &&
                                  !snapshot.ampBypassed,
                              height: tileHeight,
                              disabled: !snapshot.connected,
                              onTap: () => onSlotOpen(ModelSlot.amp),
                              onFootswitch: () => onSlotToggle(
                                  ModelSlot.amp, !snapshot.ampBypassed),
                            ),
                            for (final pedal in optionalPedals) ...[
                              const _SignalArrow(),
                              if (pedal.effect case final effect?)
                                effectTile(effect),
                              if (pedal == OptionalPedal.looper)
                                _PedalTile(
                                  label: 'LOOPER',
                                  category: PedalCategory.looper,
                                  status: snapshot.looperMode.toUpperCase(),
                                  icon: Icons.loop,
                                  active: snapshot.looperMode != 'stopped',
                                  height: tileHeight,
                                  disabled: !snapshot.connected,
                                  onTap: onLooperOpen,
                                  onFootswitch: onLooperOpen,
                                ),
                            ],
                            const _SignalArrow(),
                            _AddPedalTile(
                              height: tileHeight,
                              disabled: !snapshot.connected,
                              onTap: onAddPedal,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
}

class _AddPedalTile extends StatelessWidget {
  const _AddPedalTile({
    required this.height,
    required this.disabled,
    required this.onTap,
  });

  final double height;
  final bool disabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final compact = height < 108;
    final dense = height < 90;
    return SizedBox(
      width: dense
          ? 72
          : compact
              ? 82
              : 100,
      height: height,
      child: Opacity(
        opacity: disabled ? .5 : 1,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(13),
            onTap: disabled ? null : onTap,
            child: Container(
              margin: EdgeInsets.symmetric(vertical: dense ? 2 : 3),
              decoration: BoxDecoration(
                color: const Color(0x331a72ba),
                borderRadius: BorderRadius.circular(13),
                border: Border.all(
                  color: LostChrome.electric.withValues(alpha: .75),
                  width: 1.4,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_circle_outline,
                      color: LostChrome.electric, size: dense ? 20 : 30),
                  SizedBox(height: dense ? 2 : 5),
                  Text(
                    'ADD',
                    style: TextStyle(
                      color: LostChrome.pearl,
                      fontSize: dense
                          ? 9
                          : compact
                              ? 11
                              : 13,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                  Text(
                    'PEDAL',
                    style: TextStyle(
                      color: LostChrome.ice.withValues(alpha: .75),
                      fontSize: dense
                          ? 7
                          : compact
                              ? 8
                              : 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: .8,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SignalArrow extends StatelessWidget {
  const _SignalArrow();

  @override
  Widget build(BuildContext context) => const SizedBox(
        width: 18,
        child: Icon(Icons.chevron_right, size: 18, color: Color(0xff9eeaff)),
      );
}

class _PedalTile extends StatelessWidget {
  const _PedalTile({
    required this.label,
    required this.category,
    required this.status,
    required this.icon,
    required this.active,
    required this.height,
    required this.disabled,
    required this.onTap,
    required this.onFootswitch,
  });

  final String label;
  final PedalCategory category;
  final String status;
  final IconData icon;
  final bool active;
  final double height;
  final bool disabled;
  final VoidCallback onTap;
  final VoidCallback onFootswitch;

  @override
  Widget build(BuildContext context) {
    final compact = height < 108;
    final dense = height < 90;
    final face = active ? category.color : const Color(0xff123968);
    return SizedBox(
      width: dense
          ? 88
          : compact
              ? 105
              : 124,
      height: height,
      child: Opacity(
        opacity: disabled ? 0.5 : 1,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(13),
            onTap: disabled ? null : onTap,
            child: Container(
              margin: EdgeInsets.symmetric(vertical: dense ? 2 : 3),
              padding: EdgeInsets.fromLTRB(
                dense
                    ? 5
                    : compact
                        ? 7
                        : 9,
                dense ? 4 : 7,
                dense
                    ? 5
                    : compact
                        ? 7
                        : 9,
                dense ? 4 : 7,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    face.withValues(alpha: .98),
                    face.withValues(alpha: .62),
                    const Color(0xff09275b),
                  ],
                ),
                borderRadius: BorderRadius.circular(13),
                border: Border.all(
                    color: active ? LostChrome.pearl : const Color(0xff6ca6dd)),
                boxShadow: [
                  BoxShadow(
                    color: active
                        ? LostChrome.electric.withValues(alpha: 0.55)
                        : Colors.black54,
                    blurRadius: active ? 13 : 5,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: dense ? 3 : 5, vertical: dense ? 1 : 2),
                        decoration: BoxDecoration(
                          color: category.color.withValues(alpha: .32),
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(
                              color: category.color.withValues(alpha: .8)),
                        ),
                        child: Text(
                          category.label,
                          style: TextStyle(
                            color: LostChrome.pearl,
                            fontSize: dense ? 6 : 7,
                            letterSpacing: dense ? .3 : .6,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        width: dense ? 5 : 7,
                        height: dense ? 5 : 7,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: active
                              ? LostChrome.lime
                              : const Color(0xff071a3a),
                          boxShadow: active
                              ? const [
                                  BoxShadow(
                                      color: LostChrome.lime, blurRadius: 7)
                                ]
                              : null,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(
                      height: dense
                          ? 1
                          : compact
                              ? 3
                              : 6),
                  Icon(icon,
                      size: dense
                          ? 17
                          : compact
                              ? 23
                              : 31,
                      color: LostChrome.pearl),
                  SizedBox(
                      height: dense
                          ? 0
                          : compact
                              ? 2
                              : 4),
                  Text(label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: dense
                              ? 9
                              : compact
                                  ? 11
                                  : 14,
                          letterSpacing: compact ? 0 : .2)),
                  if (!dense)
                    Text(status,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: active
                              ? LostChrome.lime
                              : LostChrome.ice.withValues(alpha: .75),
                          fontSize: compact ? 8 : 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: .8,
                        )),
                  const Spacer(),
                  InkWell(
                    borderRadius: BorderRadius.circular(7),
                    onTap: disabled ? null : onFootswitch,
                    child: Container(
                      height: dense
                          ? 15
                          : compact
                              ? 22
                              : 28,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            LostChrome.pearl,
                            Color(0xff82bce4),
                            Color(0xffe9fbff),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(7),
                        border: Border.all(color: const Color(0xffdfffff)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.power_settings_new,
                              size: dense ? 9 : 13,
                              color: const Color(0xff16447f)),
                          if (!compact) ...[
                            const SizedBox(width: 4),
                            Text(
                              active ? 'ON' : 'OFF',
                              style: const TextStyle(
                                color: Color(0xff16447f),
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class PresetLibrarySheet extends StatefulWidget {
  const PresetLibrarySheet({
    required this.client,
    required this.currentPresetId,
    required this.suggestedName,
    super.key,
  });

  final ControlClient client;
  final String? currentPresetId;
  final String suggestedName;

  @override
  State<PresetLibrarySheet> createState() => _PresetLibrarySheetState();
}

class _PresetLibrarySheetState extends State<PresetLibrarySheet> {
  late Future<List<PresetSummary>> _presets;
  String? _busyId;
  String? _error;

  @override
  void initState() {
    super.initState();
    _presets = widget.client.listPresets();
  }

  void _refresh() => setState(() => _presets = widget.client.listPresets());

  Future<String?> _askName(String title, String initial) async {
    final controller = TextEditingController(text: initial);
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 64,
          decoration: const InputDecoration(labelText: 'Preset name'),
          onSubmitted: (value) => Navigator.pop(context, value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('SAVE'),
          ),
        ],
      ),
    );
    controller.dispose();
    return name?.trim();
  }

  Future<void> _saveCurrent() async {
    final name = await _askName('Save current rig', widget.suggestedName);
    if (name == null || name.isEmpty) return;
    await _run(null, () => widget.client.savePreset(name));
  }

  Future<void> _newPreset() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Start a new preset?'),
        content: const Text(
          'This clears the current NAM models and optional pedals. Saved presets stay safe.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('START NEW'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() {
      _busyId = 'new';
      _error = null;
    });
    try {
      await widget.client.newPreset();
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (mounted) setState(() => _error = '$error');
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  Future<void> _load(PresetSummary preset) async {
    setState(() {
      _busyId = preset.id;
      _error = null;
    });
    try {
      await widget.client.loadPreset(preset.id);
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (mounted) setState(() => _error = '$error');
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  Future<void> _rename(PresetSummary preset) async {
    final name = await _askName('Rename preset', preset.name);
    if (name == null || name.isEmpty || name == preset.name) return;
    await _run(preset.id, () => widget.client.renamePreset(preset.id, name));
  }

  Future<void> _delete(PresetSummary preset) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete preset?'),
        content:
            Text('Delete “${preset.name}”? The current sound stays loaded.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _run(preset.id, () => widget.client.deletePreset(preset.id));
    }
  }

  Future<void> _run(String? id, Future<void> Function() action) async {
    setState(() {
      _busyId = id ?? 'save';
      _error = null;
    });
    try {
      await action();
      if (mounted) _refresh();
    } catch (error) {
      if (mounted) setState(() => _error = '$error');
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text('PRESETS', style: Theme.of(context).textTheme.titleLarge),
                const Spacer(),
                IconButton(
                  tooltip: 'Refresh presets',
                  onPressed: _busyId == null ? _refresh : null,
                  icon: const Icon(Icons.refresh),
                ),
                IconButton(
                  tooltip: 'Close',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            if (_error != null)
              Text(_error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error)),
            Expanded(
              child: FutureBuilder<List<PresetSummary>>(
                future: _presets,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('${snapshot.error}'));
                  }
                  final presets = snapshot.data ?? const [];
                  if (presets.isEmpty) {
                    return const Center(
                      child: Text('No presets saved yet.'),
                    );
                  }
                  return ListView.separated(
                    itemCount: presets.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final preset = presets[index];
                      final selected = preset.id == widget.currentPresetId;
                      final busy = preset.id == _busyId;
                      return ListTile(
                        selected: selected,
                        leading: Icon(selected
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked),
                        title: Text(preset.name),
                        subtitle: Text(preset.modelSummary),
                        enabled: _busyId == null,
                        onTap: () => _load(preset),
                        trailing: busy
                            ? const SizedBox.square(
                                dimension: 22,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : PopupMenuButton<String>(
                                enabled: _busyId == null,
                                onSelected: (action) => action == 'rename'
                                    ? _rename(preset)
                                    : _delete(preset),
                                itemBuilder: (context) => const [
                                  PopupMenuItem(
                                      value: 'rename', child: Text('Rename')),
                                  PopupMenuItem(
                                      value: 'delete', child: Text('Delete')),
                                ],
                              ),
                      );
                    },
                  );
                },
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _busyId == null ? _newPreset : null,
                    icon: const Icon(Icons.add),
                    label: const Text('NEW PRESET'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    onPressed: _busyId == null ? _saveCurrent : null,
                    icon: const Icon(Icons.save),
                    label: const Text('SAVE CURRENT RIG'),
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

class AddPedalSheet extends StatelessWidget {
  const AddPedalSheet({
    required this.snapshot,
    required this.onAdd,
    super.key,
  });

  final EngineSnapshot snapshot;
  final Future<void> Function(OptionalPedal pedal) onAdd;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.add_circle_outline,
                    color: LostChrome.electric),
                const SizedBox(width: 8),
                Text('ADD A PEDAL',
                    style: Theme.of(context).textTheme.titleLarge),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const Text(
              'Effects are added after your amp and saved with this preset.',
              style: TextStyle(color: LostChrome.ice),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView(
                children: [
                  for (final pedal in OptionalPedal.values)
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                      leading: CircleAvatar(
                        backgroundColor:
                            pedal.category.color.withValues(alpha: .28),
                        child: Icon(pedal.icon, color: LostChrome.pearl),
                      ),
                      title: Text(pedal.label),
                      subtitle: Text(pedal.description),
                      trailing: snapshot.pedalVisible(pedal)
                          ? const Chip(label: Text('ON BOARD'))
                          : const Icon(Icons.add_circle_outline),
                      enabled: !snapshot.pedalVisible(pedal),
                      onTap: snapshot.pedalVisible(pedal)
                          ? null
                          : () => onAdd(pedal),
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

class SlotControlsSheet extends StatefulWidget {
  const SlotControlsSheet({
    required this.slot,
    required this.snapshot,
    required this.onChanged,
    required this.onChangeTone,
    super.key,
  });

  final ModelSlot slot;
  final EngineSnapshot snapshot;
  final Future<void> Function(String, double) onChanged;
  final VoidCallback onChangeTone;

  @override
  State<SlotControlsSheet> createState() => _SlotControlsSheetState();
}

class _SlotControlsSheetState extends State<SlotControlsSheet> {
  late final Map<String, double> _values;

  @override
  void initState() {
    super.initState();
    _values = {
      'pedal_drive_db': widget.snapshot.pedalDriveDb,
      'pedal_mix': widget.snapshot.pedalMix,
      'pedal_level_db': widget.snapshot.pedalLevelDb,
      'amp_bass_db': widget.snapshot.ampBassDb,
      'amp_mid_db': widget.snapshot.ampMidDb,
      'amp_treble_db': widget.snapshot.ampTrebleDb,
      'amp_volume_db': widget.snapshot.ampVolumeDb,
    };
  }

  List<_ControlDefinition> get _controls => widget.slot == ModelSlot.pre
      ? const [
          _ControlDefinition('pedal_drive_db', 'DRIVE', 0, 24, 48, 'dB'),
          _ControlDefinition('pedal_mix', 'MIX', 0, 1, 20, '%', percent: true),
          _ControlDefinition('pedal_level_db', 'LEVEL', -24, 12, 72, 'dB'),
        ]
      : const [
          _ControlDefinition('amp_bass_db', 'BASS', -12, 12, 48, 'dB'),
          _ControlDefinition('amp_mid_db', 'MID', -12, 12, 48, 'dB'),
          _ControlDefinition('amp_treble_db', 'TREBLE', -12, 12, 48, 'dB'),
          _ControlDefinition('amp_volume_db', 'VOLUME', -24, 12, 72, 'dB'),
        ];

  Future<void> _commit(_ControlDefinition control, double value) async {
    try {
      await widget.onChanged(control.keyName, value);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$error')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final label = widget.slot == ModelSlot.pre ? 'PEDAL' : 'AMP';
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text('$label CONTROLS',
                    style: Theme.of(context).textTheme.titleLarge),
                const Spacer(),
                IconButton(
                  tooltip: 'Close',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            Expanded(
              child: ListView(
                children: [
                  for (final control in _controls)
                    _ControlSlider(
                      definition: control,
                      value: _values[control.keyName]!,
                      onChanged: (value) =>
                          setState(() => _values[control.keyName] = value),
                      onChangeEnd: (value) => _commit(control, value),
                    ),
                ],
              ),
            ),
            OutlinedButton.icon(
              onPressed: widget.onChangeTone,
              icon: const Icon(Icons.library_music),
              label: const Text('CHANGE TONE'),
            ),
          ],
        ),
      ),
    );
  }
}

class EffectControlsSheet extends StatefulWidget {
  const EffectControlsSheet({
    required this.effect,
    required this.snapshot,
    required this.onChanged,
    this.onRemove,
    super.key,
  });

  final EffectKind effect;
  final EngineSnapshot snapshot;
  final Future<void> Function(String, double) onChanged;
  final Future<bool> Function()? onRemove;

  @override
  State<EffectControlsSheet> createState() => _EffectControlsSheetState();
}

class _EffectControlsSheetState extends State<EffectControlsSheet> {
  late final Map<String, double> _values;

  @override
  void initState() {
    super.initState();
    _values = widget.snapshot.effectControls(widget.effect);
  }

  List<_ControlDefinition> get _controls => switch (widget.effect) {
        EffectKind.gate => const [
            _ControlDefinition(
                'gate_threshold_db', 'THRESHOLD', -80, -10, 70, 'dB'),
          ],
        EffectKind.compressor => const [
            _ControlDefinition(
                'compressor_threshold_db', 'THRESHOLD', -48, 0, 48, 'dB'),
            _ControlDefinition('compressor_ratio', 'RATIO', 1, 20, 38, ':1'),
          ],
        EffectKind.eq => const [
            _ControlDefinition('eq_low_db', 'LOW', -12, 12, 48, 'dB'),
            _ControlDefinition('eq_mid_db', 'MID', -12, 12, 48, 'dB'),
            _ControlDefinition('eq_high_db', 'HIGH', -12, 12, 48, 'dB'),
          ],
        EffectKind.chorus => const [
            _ControlDefinition('chorus_rate_hz', 'RATE', 0.05, 8, 40, 'Hz'),
            _ControlDefinition('chorus_depth', 'DEPTH', 0, 1, 20, '%',
                percent: true),
            _ControlDefinition('chorus_mix', 'MIX', 0, 1, 20, '%',
                percent: true),
          ],
        EffectKind.delay => const [
            _ControlDefinition('delay_time_ms', 'TIME', 20, 1800, 89, 'ms'),
            _ControlDefinition('delay_feedback', 'FEEDBACK', 0, .92, 23, '%',
                percent: true),
            _ControlDefinition('delay_mix', 'MIX', 0, 1, 20, '%',
                percent: true),
          ],
        EffectKind.reverb => const [
            _ControlDefinition(
                'reverb_decay_seconds', 'DECAY', .3, 12, 47, 's'),
            _ControlDefinition('reverb_mix', 'MIX', 0, 1, 20, '%',
                percent: true),
          ],
      };

  Future<void> _commit(_ControlDefinition control, double value) async {
    try {
      await widget.onChanged(control.keyName, value);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$error')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final detail = widget.effect;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(detail.icon, color: detail.color),
                const SizedBox(width: 8),
                Text('${detail.label} PEDAL',
                    style: Theme.of(context).textTheme.titleLarge),
                const Spacer(),
                IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close)),
              ],
            ),
            const Text('Settings are saved with your preset.',
                style: TextStyle(color: Color(0xffa2d5f5))),
            const SizedBox(height: 8),
            Expanded(
              child: ListView(
                children: [
                  for (final control in _controls)
                    _ControlSlider(
                      definition: control,
                      value: _values[control.keyName]!,
                      onChanged: (value) =>
                          setState(() => _values[control.keyName] = value),
                      onChangeEnd: (value) => _commit(control, value),
                    ),
                ],
              ),
            ),
            if (widget.onRemove != null) ...[
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () async {
                  final navigator = Navigator.of(context);
                  final removed = await widget.onRemove!();
                  if (removed && mounted) navigator.pop();
                },
                icon: const Icon(Icons.remove_circle_outline),
                label: const Text('REMOVE FROM BOARD'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class LooperControlsSheet extends StatefulWidget {
  const LooperControlsSheet(
      {required this.mode,
      required this.bpm,
      required this.bars,
      required this.onAction,
      required this.onRemove,
      super.key});

  final String mode;
  final int bpm;
  final int bars;
  final Future<void> Function(String, {int? bpm, int? bars}) onAction;
  final Future<bool> Function() onRemove;

  @override
  State<LooperControlsSheet> createState() => _LooperControlsSheetState();
}

class _LooperControlsSheetState extends State<LooperControlsSheet> {
  late int _bpm;
  late int _bars;

  @override
  void initState() {
    super.initState();
    _bpm = widget.bpm;
    _bars = widget.bars;
  }

  @override
  Widget build(BuildContext context) {
    Future<void> choose(String action) async {
      try {
        await widget.onAction(action,
            bpm: action == 'record' ? _bpm : null,
            bars: action == 'record' ? _bars : null);
        if (context.mounted) {
          Navigator.pop(context);
        }
      } catch (error) {
        if (context.mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('$error')));
        }
      }
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(children: [
                const Icon(Icons.loop, color: LostChrome.lime),
                const SizedBox(width: 8),
                const Text('30 SECOND LOOPER',
                    style:
                        TextStyle(fontWeight: FontWeight.w900, fontSize: 19)),
                const Spacer(),
                IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close)),
              ]),
              Text(
                  'Now: ${widget.mode.toUpperCase()}  •  loop audio clears after a restart',
                  style: const TextStyle(color: Color(0xffa2d5f5))),
              const SizedBox(height: 12),
              const Text('QUANTIZED RECORD',
                  style: TextStyle(
                      fontWeight: FontWeight.w900, letterSpacing: 1.1)),
              const SizedBox(height: 4),
              const Text(
                  'Four ticks, then record exactly on beat one. It stops and plays back on the selected bar boundary.',
                  style: TextStyle(color: Color(0xffa2d5f5))),
              const SizedBox(height: 7),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Text('BPM',
                      style: TextStyle(fontWeight: FontWeight.w800)),
                  IconButton(
                      tooltip: 'Decrease looper BPM',
                      onPressed:
                          _bpm > 30 ? () => setState(() => _bpm -= 5) : null,
                      icon: const Icon(Icons.remove_circle_outline)),
                  Text('$_bpm',
                      style: const TextStyle(
                          fontSize: 19, fontWeight: FontWeight.w900)),
                  IconButton(
                      tooltip: 'Increase looper BPM',
                      onPressed:
                          _bpm < 300 ? () => setState(() => _bpm += 5) : null,
                      icon: const Icon(Icons.add_circle_outline)),
                  for (final bars in [1, 2, 4, 8])
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: ChoiceChip(
                          label: Text('$bars B'),
                          selected: _bars == bars,
                          onSelected: (_) => setState(() => _bars = bars)),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  FilledButton.icon(
                      onPressed: () => choose('record'),
                      icon: const Icon(Icons.fiber_manual_record),
                      label: const Text('COUNT IN + RECORD')),
                  FilledButton.tonalIcon(
                      onPressed: () => choose('play'),
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('PLAY')),
                  FilledButton.tonalIcon(
                      onPressed: () => choose('overdub'),
                      icon: const Icon(Icons.add),
                      label: const Text('OVERDUB')),
                  OutlinedButton.icon(
                      onPressed: () => choose('stop'),
                      icon: const Icon(Icons.stop),
                      label: const Text('STOP')),
                ],
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () async {
                  final removed = await widget.onRemove();
                  if (removed && context.mounted) Navigator.pop(context);
                },
                icon: const Icon(Icons.remove_circle_outline),
                label: const Text('REMOVE FROM BOARD'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A short, deterministic exercise. The AI layer can later choose one of
/// these templates and adapt its key/BPM without being responsible for
/// generating valid fretboard data at audio time.
class DailyLesson {
  const DailyLesson({
    required this.title,
    required this.subtitle,
    required this.coaching,
    required this.bpm,
    required this.events,
  });

  final String title;
  final String subtitle;
  final String coaching;
  final int bpm;
  final List<DailyLessonEvent> events;

  int get stepMilliseconds => (60000 / bpm * .5).round();

  /// The daily session always contains three drills; only its starting order
  /// changes, so a player still gets scales, arpeggios, and picking work.
  static List<DailyLesson> dailySession(DateTime date) => List.unmodifiable([
        today(date),
        today(date.add(const Duration(days: 1))),
        today(date.add(const Duration(days: 2))),
      ]);

  static DailyLesson today(DateTime date) {
    const lessons = [
      DailyLesson(
        title: 'E MINOR PENTATONIC',
        subtitle: 'POSITION 1 // EIGHTH NOTES',
        coaching: 'Use even alternate picking. Let every note speak once.',
        bpm: 80,
        events: [
          DailyLessonEvent('E2', '6 / 0'),
          DailyLessonEvent('G2', '6 / 3'),
          DailyLessonEvent('A2', '5 / 0'),
          DailyLessonEvent('B2', '5 / 2'),
          DailyLessonEvent('D3', '4 / 0'),
          DailyLessonEvent('E3', '4 / 2'),
          DailyLessonEvent('D3', '4 / 0'),
          DailyLessonEvent('B2', '5 / 2'),
          DailyLessonEvent('A2', '5 / 0'),
          DailyLessonEvent('G2', '6 / 3'),
          DailyLessonEvent('E2', '6 / 0'),
        ],
      ),
      DailyLesson(
        title: 'A MAJOR TRIAD',
        subtitle: 'ARPEGGIO // ROOT POSITION',
        coaching:
            'Pick each voice cleanly. Do not let the previous string ring.',
        bpm: 72,
        events: [
          DailyLessonEvent('A2', '5 / 0'),
          DailyLessonEvent('C#3', '5 / 4'),
          DailyLessonEvent('E3', '4 / 2'),
          DailyLessonEvent('A3', '3 / 2'),
          DailyLessonEvent('C#4', '2 / 2'),
          DailyLessonEvent('E4', '1 / 0'),
          DailyLessonEvent('C#4', '2 / 2'),
          DailyLessonEvent('A3', '3 / 2'),
          DailyLessonEvent('E3', '4 / 2'),
          DailyLessonEvent('C#3', '5 / 4'),
          DailyLessonEvent('A2', '5 / 0'),
        ],
      ),
      DailyLesson(
        title: 'CHROMATIC ENGINE',
        subtitle: 'ONE STRING // ALTERNATE PICKING',
        coaching: 'Keep your wrist loose and make each pick stroke identical.',
        bpm: 88,
        events: [
          DailyLessonEvent('E2', '6 / 0'),
          DailyLessonEvent('F2', '6 / 1'),
          DailyLessonEvent('F#2', '6 / 2'),
          DailyLessonEvent('G2', '6 / 3'),
          DailyLessonEvent('G#2', '6 / 4'),
          DailyLessonEvent('A2', '6 / 5'),
          DailyLessonEvent('G#2', '6 / 4'),
          DailyLessonEvent('G2', '6 / 3'),
          DailyLessonEvent('F#2', '6 / 2'),
          DailyLessonEvent('F2', '6 / 1'),
          DailyLessonEvent('E2', '6 / 0'),
        ],
      ),
    ];
    final day = date.difference(DateTime(date.year)).inDays;
    return lessons[day % lessons.length];
  }
}

class DailyLessonEvent {
  const DailyLessonEvent(this.note, this.position);

  final String note;
  final String position;

  /// Positions are stored as guitar-tab `string / fret`, where 1 is the high
  /// e string and 6 is the low E string. Keeping that familiar notation in
  /// the lesson data also makes it straightforward to export later.
  int get stringNumber => int.parse(position.split('/').first.trim());

  int get fret => int.parse(position.split('/').last.trim());
}

class PracticeSessionRecord {
  const PracticeSessionRecord({
    required this.completedAt,
    required this.accuracyPercent,
    required this.hitCount,
    required this.noteCount,
    required this.averageTimingMilliseconds,
    required this.exerciseTitles,
  });

  factory PracticeSessionRecord.fromJson(Map<String, dynamic> json) {
    return PracticeSessionRecord(
      completedAt: DateTime.fromMillisecondsSinceEpoch(
          json['completed_at_ms'] as int? ?? 0),
      accuracyPercent: json['accuracy_percent'] as int? ?? 0,
      hitCount: json['hit_count'] as int? ?? 0,
      noteCount: json['note_count'] as int? ?? 0,
      averageTimingMilliseconds: json['average_timing_ms'] as int? ?? 0,
      exerciseTitles: (json['exercise_titles'] as List<dynamic>? ?? const [])
          .whereType<String>()
          .toList(growable: false),
    );
  }

  final DateTime completedAt;
  final int accuracyPercent;
  final int hitCount;
  final int noteCount;
  final int averageTimingMilliseconds;
  final List<String> exerciseTitles;

  Map<String, dynamic> toJson() => {
        'completed_at_ms': completedAt.millisecondsSinceEpoch,
        'accuracy_percent': accuracyPercent,
        'hit_count': hitCount,
        'note_count': noteCount,
        'average_timing_ms': averageTimingMilliseconds,
        'exercise_titles': exerciseTitles,
      };
}

class PracticeHistoryStore {
  PracticeHistoryStore({String? path}) : path = path ?? _defaultPath();

  final String path;

  static String _defaultPath() {
    final configured = Platform.environment['PEDAL_PRACTICE_HISTORY_FILE'];
    if (configured != null && configured.isNotEmpty) return configured;
    final stateHome = Platform.environment['XDG_STATE_HOME'];
    final home = Platform.environment['HOME'] ?? '.';
    final root =
        stateHome?.isNotEmpty == true ? stateHome! : '$home/.local/state';
    return '$root/lost-audio/practice-history.json';
  }

  Future<List<PracticeSessionRecord>> load() async {
    try {
      final json = jsonDecode(await File(path).readAsString()) as List<dynamic>;
      final records = json
          .whereType<Map<String, dynamic>>()
          .map(PracticeSessionRecord.fromJson)
          .toList(growable: false)
        ..sort((a, b) => b.completedAt.compareTo(a.completedAt));
      return records;
    } on FileSystemException {
      return const [];
    } on FormatException {
      return const [];
    }
  }

  Future<void> add(PracticeSessionRecord record) async {
    final records = await load();
    // A compact local history is enough for now; the newest 100 sessions are
    // plenty for the menu and keep startup/storage work negligible.
    final updated = [record, ...records].take(100).map((item) => item.toJson());
    final destination = File(path);
    await destination.parent.create(recursive: true);
    final temporary = File('$path.new');
    await temporary.writeAsString(jsonEncode(updated));
    await temporary.rename(path);
  }
}

enum _LessonEventState { pending, hit, missed }

class DailyLessonSheet extends StatefulWidget {
  DailyLessonSheet({
    required this.meters,
    DailyLesson? lesson,
    List<DailyLesson>? lessons,
    PracticeHistoryStore? historyStore,
    this.onMetronomeChanged,
    super.key,
  })  : assert(lesson != null || lessons != null),
        lessons = lessons ?? [lesson!],
        historyStore = historyStore ?? PracticeHistoryStore();

  final Stream<MeterSnapshot> meters;
  final List<DailyLesson> lessons;
  final PracticeHistoryStore historyStore;
  final Future<void> Function(bool enabled, int bpm)? onMetronomeChanged;

  @override
  State<DailyLessonSheet> createState() => _DailyLessonSheetState();
}

class _DailyLessonSheetState extends State<DailyLessonSheet> {
  static const _minimumConfidence = .62;
  static const _pitchToleranceCents = 35.0;

  late List<_LessonEventState> _eventStates;
  final List<int> _timingOffsets = [];
  StreamSubscription<MeterSnapshot>? _meterSubscription;
  Timer? _clock;
  DateTime? _startedAt;
  bool _running = false;
  bool _finished = false;
  bool _awaitingNextLesson = false;
  int _lessonIndex = 0;
  int _round = 1;
  int _passCountInMilliseconds = 0;
  int _elapsedMilliseconds = 0;
  int _sessionHitCount = 0;
  int _sessionNoteCount = 0;
  final List<int> _sessionTimingOffsets = [];

  DailyLesson get _lesson => widget.lessons[_lessonIndex];

  @override
  void initState() {
    super.initState();
    _eventStates =
        List.filled(_lesson.events.length, _LessonEventState.pending);
    _meterSubscription = widget.meters.listen(_receiveMeter);
  }

  @override
  void dispose() {
    _meterSubscription?.cancel();
    _clock?.cancel();
    final metronome = widget.onMetronomeChanged;
    if (metronome != null) unawaited(metronome(false, _lesson.bpm));
    super.dispose();
  }

  int get _practiceMilliseconds =>
      _lesson.events.length * _lesson.stepMilliseconds;

  // Four quarter-note pulses, rather than a fixed wall-clock delay, keep the
  // count-in honest as future lessons choose different tempos.
  int get _countInMilliseconds => (60000 / _lesson.bpm * 4).round();

  int get _lessonElapsedMilliseconds =>
      (_elapsedMilliseconds - _passCountInMilliseconds)
          .clamp(0, _practiceMilliseconds);

  int get _activeIndex {
    if (!_running || _elapsedMilliseconds < _passCountInMilliseconds) {
      return -1;
    }
    final index = _lessonElapsedMilliseconds ~/ _lesson.stepMilliseconds;
    return index.clamp(0, _lesson.events.length - 1);
  }

  double get _playheadPosition {
    if (!_running || _elapsedMilliseconds < _passCountInMilliseconds) {
      return -1;
    }
    return (_lessonElapsedMilliseconds / _lesson.stepMilliseconds)
        .clamp(0.0, _lesson.events.length - .001);
  }

  int get _hitCount =>
      _eventStates.where((state) => state == _LessonEventState.hit).length;

  int _averageTiming(List<int> offsets) {
    if (offsets.isEmpty) return 0;
    return (offsets.map((offset) => offset.abs()).reduce((a, b) => a + b) /
            offsets.length)
        .round();
  }

  int get _sessionAccuracyPercent => _sessionNoteCount == 0
      ? 0
      : (_sessionHitCount / _sessionNoteCount * 100).round();

  void _restartSession() {
    _clock?.cancel();
    setState(() {
      _finished = false;
      _awaitingNextLesson = false;
      _lessonIndex = 0;
      _round = 1;
      _sessionHitCount = 0;
      _sessionNoteCount = 0;
      _sessionTimingOffsets.clear();
    });
    unawaited(_beginPass());
  }

  void _startCurrentLesson() {
    unawaited(_beginPass());
  }

  Future<void> _beginPass({bool countIn = true}) async {
    _clock?.cancel();
    if (countIn) {
      try {
        await widget.onMetronomeChanged?.call(true, _lesson.bpm);
      } catch (_) {
        // Practice scoring remains useful if the optional click cannot start.
      }
    }
    if (!mounted) return;
    setState(() {
      _eventStates =
          List.filled(_lesson.events.length, _LessonEventState.pending);
      _timingOffsets.clear();
      _startedAt = DateTime.now();
      _elapsedMilliseconds = 0;
      _passCountInMilliseconds = countIn ? _countInMilliseconds : 0;
      _running = true;
      _awaitingNextLesson = false;
    });
    _clock =
        Timer.periodic(const Duration(milliseconds: 33), (_) => _advance());
  }

  void _advance() {
    final startedAt = _startedAt;
    if (!_running || startedAt == null || !mounted) return;
    final elapsed = DateTime.now().difference(startedAt).inMilliseconds;
    final rawIndex = elapsed < _passCountInMilliseconds
        ? -1
        : (elapsed - _passCountInMilliseconds) ~/ _lesson.stepMilliseconds;
    var passFinished = false;
    setState(() {
      _elapsedMilliseconds = elapsed;
      // When the playhead passes a pending target, it becomes a miss. A later
      // pitch cannot be retroactively matched to an earlier note.
      final lastExpired = rawIndex.clamp(0, _lesson.events.length);
      for (var index = 0; index < lastExpired; index++) {
        if (_eventStates[index] == _LessonEventState.pending) {
          _eventStates[index] = _LessonEventState.missed;
        }
      }
      if (rawIndex >= _lesson.events.length) {
        for (var index = 0; index < _eventStates.length; index++) {
          if (_eventStates[index] == _LessonEventState.pending) {
            _eventStates[index] = _LessonEventState.missed;
          }
        }
        _running = false;
        _clock?.cancel();
        passFinished = true;
      }
    });
    if (passFinished) _finishPass();
  }

  void _finishPass() {
    _sessionHitCount += _hitCount;
    _sessionNoteCount += _lesson.events.length;
    _sessionTimingOffsets.addAll(_timingOffsets);
    final anotherRound = _round < 2;
    final anotherLesson = _lessonIndex < widget.lessons.length - 1;
    if (anotherRound) {
      // The second pass is intentionally immediate: the click continues and
      // only the scoring grid resets, so there is no second count-in.
      setState(() => _round += 1);
      unawaited(_beginPass(countIn: false));
      return;
    }
    if (anotherLesson) {
      setState(() => _awaitingNextLesson = true);
      unawaited(widget.onMetronomeChanged?.call(false, _lesson.bpm));
      return;
    }
    if (!anotherRound && !anotherLesson) {
      setState(() => _finished = true);
      unawaited(_saveSession());
      unawaited(widget.onMetronomeChanged?.call(false, _lesson.bpm));
      return;
    }
  }

  void _nextLesson() {
    if (!_awaitingNextLesson || _lessonIndex >= widget.lessons.length - 1) {
      return;
    }
    setState(() {
      _lessonIndex += 1;
      _round = 1;
      _passCountInMilliseconds = 0;
      _elapsedMilliseconds = 0;
      _eventStates =
          List.filled(_lesson.events.length, _LessonEventState.pending);
      _timingOffsets.clear();
      _awaitingNextLesson = false;
    });
  }

  Future<void> _saveSession() async {
    try {
      await widget.historyStore.add(PracticeSessionRecord(
        completedAt: DateTime.now(),
        accuracyPercent: _sessionAccuracyPercent,
        hitCount: _sessionHitCount,
        noteCount: _sessionNoteCount,
        averageTimingMilliseconds: _averageTiming(_sessionTimingOffsets),
        exerciseTitles: widget.lessons
            .map((lesson) => lesson.title)
            .toList(growable: false),
      ));
    } on FileSystemException {
      // A read-only development filesystem should not turn a completed drill
      // into a failure. The current session result stays visible.
    }
  }

  void _receiveMeter(MeterSnapshot meter) {
    final startedAt = _startedAt;
    if (!_running || startedAt == null || !mounted) return;
    if (meter.tunerHz <= 0 || meter.tunerConfidence < _minimumConfidence) {
      return;
    }
    final elapsed = DateTime.now().difference(startedAt).inMilliseconds;
    if (elapsed < _passCountInMilliseconds) return;
    final index =
        (elapsed - _passCountInMilliseconds) ~/ _lesson.stepMilliseconds;
    if (index < 0 ||
        index >= _lesson.events.length ||
        _eventStates[index] != _LessonEventState.pending) {
      return;
    }
    final target = _lesson.events[index];
    final cents =
        1200 * math.log(meter.tunerHz / _noteFrequency(target.note)) / math.ln2;
    if (cents.abs() > _pitchToleranceCents) return;
    final targetTime =
        _passCountInMilliseconds + index * _lesson.stepMilliseconds;
    setState(() {
      _eventStates[index] = _LessonEventState.hit;
      _timingOffsets.add(elapsed - targetTime);
    });
  }

  String get _headline {
    if (_finished) return 'SESSION COMPLETE';
    if (_awaitingNextLesson) return 'EXERCISE COMPLETE';
    if (!_running) return 'READY WHEN YOU ARE';
    final remaining = _passCountInMilliseconds - _elapsedMilliseconds;
    if (remaining > 0) return 'COUNT IN  ${((remaining - 1) ~/ 1000) + 1}';
    return 'PLAY ${_lesson.events[_activeIndex].note}';
  }

  String get _subheadline {
    if (_finished) {
      return '$_sessionHitCount / $_sessionNoteCount notes • ${_averageTiming(_sessionTimingOffsets)} ms average timing';
    }
    if (_awaitingNextLesson) {
      return 'Two passes complete. Choose NEXT when you are ready for exercise ${_lessonIndex + 2}.';
    }
    if (!_running) {
      return 'Scores clean pitch + timing. Fret position is your choice.';
    }
    if (_elapsedMilliseconds < _passCountInMilliseconds) {
      return 'Feel the pulse. First target comes after the count-in.';
    }
    final event = _lesson.events[_activeIndex];
    return 'STRING ${event.stringNumber} • FRET ${event.fret}  •  ±${_pitchToleranceCents.round()}¢ pitch window';
  }

  void _showHistory() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => FractionallySizedBox(
        heightFactor: .78,
        child: PracticeHistorySheet(store: widget.historyStore),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final progress = _running
        ? (_lessonElapsedMilliseconds / _practiceMilliseconds).clamp(0.0, 1.0)
        : _finished
            ? 1.0
            : 0.0;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 11, 18, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.school_outlined, color: LostChrome.lime),
                const SizedBox(width: 8),
                const Text('DAILY DRILL',
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                const Spacer(),
                IconButton(
                  tooltip: 'Practice history',
                  onPressed: _showHistory,
                  icon: const Icon(Icons.history),
                ),
                IconButton(
                  tooltip: 'Close daily drill',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            Text(_lesson.subtitle,
                style: const TextStyle(
                    color: LostChrome.lime,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.1)),
            const SizedBox(height: 3),
            Text(_lesson.title,
                style:
                    const TextStyle(fontSize: 25, fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            Text(_lesson.coaching,
                style: const TextStyle(color: Color(0xffa2d5f5))),
            const SizedBox(height: 13),
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xee1659a5), Color(0xee081a43)]),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: LostChrome.ice, width: 1.2),
                boxShadow: const [
                  BoxShadow(color: Color(0x5539bfff), blurRadius: 15)
                ],
              ),
              child: Column(
                children: [
                  Text(_headline,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: LostChrome.pearl,
                          fontSize: 25,
                          fontWeight: FontWeight.w900,
                          letterSpacing: .5)),
                  const SizedBox(height: 4),
                  Text(_subheadline,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: LostChrome.ice, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 11),
                  LinearProgressIndicator(
                    value: progress,
                    minHeight: 7,
                    borderRadius: BorderRadius.circular(6),
                    color: LostChrome.lime,
                    backgroundColor: const Color(0xff164276),
                  ),
                  const SizedBox(height: 7),
                  Text(
                      '${_lesson.bpm} BPM  •  EXERCISE ${_lessonIndex + 1}/${widget.lessons.length}  •  PASS $_round/2',
                      style: const TextStyle(
                          color: Color(0xffa2d5f5),
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: .8)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text('TABLATURE',
                style:
                    TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2)),
            const SizedBox(height: 6),
            _TablatureDisplay(
              events: _lesson.events,
              states: _eventStates,
              activeIndex: _activeIndex,
              playheadPosition: _playheadPosition,
              active:
                  _running && _elapsedMilliseconds >= _passCountInMilliseconds,
            ),
            const SizedBox(height: 13),
            if (_finished)
              _DailyDrillResult(
                accuracyPercent: _sessionAccuracyPercent,
                hitCount: _sessionHitCount,
                totalCount: _sessionNoteCount,
                averageTimingMilliseconds:
                    _averageTiming(_sessionTimingOffsets),
              ),
            const SizedBox(height: 10),
            if (_awaitingNextLesson)
              FilledButton.icon(
                onPressed: _nextLesson,
                icon: const Icon(Icons.navigate_next),
                label: Text(
                    'NEXT EXERCISE ${_lessonIndex + 2}/${widget.lessons.length}'),
              )
            else
              FilledButton.icon(
                onPressed: _running
                    ? null
                    : _finished
                        ? _restartSession
                        : _startCurrentLesson,
                icon: Icon(_finished ? Icons.replay : Icons.play_arrow),
                label: Text(_finished
                    ? 'RUN SESSION AGAIN'
                    : 'START EXERCISE ${_lessonIndex + 1}/${widget.lessons.length}'),
              ),
            const SizedBox(height: 8),
            const Text(
              'Uses the clean guitar input before your NAMs and effects. It recognizes pitch and onset timing—not a particular string or fret.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xff8bc5e8), fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

class _TablatureDisplay extends StatelessWidget {
  const _TablatureDisplay({
    required this.events,
    required this.states,
    required this.activeIndex,
    required this.playheadPosition,
    required this.active,
  });

  final List<DailyLessonEvent> events;
  final List<_LessonEventState> states;
  final int activeIndex;
  final double playheadPosition;
  final bool active;

  @override
  Widget build(BuildContext context) {
    // A 42px time column keeps double-digit frets readable. The surface can
    // scroll horizontally when a later lesson is longer than the small Pi UI.
    final naturalWidth = 52.0 + events.length * 42.0;
    return Container(
      height: 146,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xdd081b42),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: LostChrome.ice.withValues(alpha: .78)),
        boxShadow: const [BoxShadow(color: Color(0x3339bfff), blurRadius: 11)],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: math.max(constraints.maxWidth, naturalWidth),
            height: 144,
            child: CustomPaint(
              painter: _TablaturePainter(
                events: events,
                states: states,
                activeIndex: activeIndex,
                playheadPosition: playheadPosition,
                active: active,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TablaturePainter extends CustomPainter {
  const _TablaturePainter({
    required this.events,
    required this.states,
    required this.activeIndex,
    required this.playheadPosition,
    required this.active,
  });

  final List<DailyLessonEvent> events;
  final List<_LessonEventState> states;
  final int activeIndex;
  final double playheadPosition;
  final bool active;

  static const _leftGutter = 38.0;
  static const _columnWidth = 42.0;
  static const _top = 28.0;
  static const _stringGap = 17.0;

  @override
  void paint(Canvas canvas, Size size) {
    final stringPaint = Paint()
      ..color = LostChrome.ice.withValues(alpha: .56)
      ..strokeWidth = 1;
    final strongStringPaint = Paint()
      ..color = LostChrome.ice.withValues(alpha: .82)
      ..strokeWidth = 1.3;
    final labels = ['e', 'B', 'G', 'D', 'A', 'E'];
    for (var index = 0; index < 6; index++) {
      final y = _top + index * _stringGap;
      canvas.drawLine(Offset(_leftGutter, y), Offset(size.width, y),
          index == 0 || index == 5 ? strongStringPaint : stringPaint);
      _paintText(
        canvas,
        labels[index],
        Offset(14, y - 8),
        const TextStyle(
            color: LostChrome.ice, fontSize: 13, fontWeight: FontWeight.w900),
      );
    }

    _paintText(
      canvas,
      'high',
      const Offset(6, 4),
      const TextStyle(color: Color(0xff8bc5e8), fontSize: 8),
    );
    _paintText(
      canvas,
      'low',
      const Offset(8, 119),
      const TextStyle(color: Color(0xff8bc5e8), fontSize: 8),
    );

    for (var index = 0; index < events.length; index++) {
      final event = events[index];
      final x = _leftGutter + _columnWidth * (index + .5);
      final y = _top + (event.stringNumber - 1) * _stringGap;
      final state = states[index];
      final isCurrent = active && index == activeIndex;
      final accent = switch (state) {
        _LessonEventState.hit => LostChrome.lime,
        _LessonEventState.missed => const Color(0xffff7794),
        _LessonEventState.pending => LostChrome.pearl,
      };

      final fretText = '${event.fret}';
      final textPainter = _textPainter(
        fretText,
        TextStyle(
          color: isCurrent ? LostChrome.midnight : accent,
          fontSize: event.fret >= 10 ? 13 : 15,
          fontWeight: FontWeight.w900,
        ),
      );
      final pad = 5.0;
      final rect = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(x, y),
          width: textPainter.width + pad * 2,
          height: textPainter.height + 2,
        ),
        const Radius.circular(5),
      );
      canvas.drawRRect(
        rect,
        Paint()
          ..color = isCurrent
              ? LostChrome.lime
              : const Color(0xff0d2b59).withValues(alpha: .97),
      );
      if (state != _LessonEventState.pending && !isCurrent) {
        canvas.drawRRect(
          rect,
          Paint()
            ..color = accent
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.2,
        );
      }
      textPainter.paint(canvas,
          Offset(x - textPainter.width / 2, y - textPainter.height / 2));
    }

    if (active && playheadPosition >= 0) {
      // The marker follows elapsed musical time, not discrete note indexes,
      // so it visibly glides between tab columns instead of jumping on beats.
      final cursorX = _leftGutter + _columnWidth * (playheadPosition + .5);
      final cursorPaint = Paint()
        ..color = LostChrome.lime
        ..strokeWidth = 2.2;
      canvas.drawLine(Offset(cursorX, _top - 17),
          Offset(cursorX, _top + 5 * _stringGap + 17), cursorPaint);
      final cursor = Path()
        ..moveTo(cursorX - 6, _top - 18)
        ..lineTo(cursorX + 6, _top - 18)
        ..lineTo(cursorX, _top - 10)
        ..close();
      canvas.drawPath(cursor, Paint()..color = LostChrome.lime);
    }

    _paintText(
      canvas,
      'FOLLOW THE LIME CURSOR  •  GREEN = HIT  •  RED = MISS',
      Offset(_leftGutter, 126),
      const TextStyle(
          color: Color(0xff8bc5e8), fontSize: 9, fontWeight: FontWeight.w800),
    );
  }

  static TextPainter _textPainter(String text, TextStyle style) {
    return TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
  }

  static void _paintText(
      Canvas canvas, String text, Offset offset, TextStyle style) {
    _textPainter(text, style).paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant _TablaturePainter oldDelegate) =>
      oldDelegate.events != events ||
      oldDelegate.states != states ||
      oldDelegate.activeIndex != activeIndex ||
      oldDelegate.playheadPosition != playheadPosition ||
      oldDelegate.active != active;
}

class _DailyDrillResult extends StatelessWidget {
  const _DailyDrillResult({
    required this.accuracyPercent,
    required this.hitCount,
    required this.totalCount,
    required this.averageTimingMilliseconds,
  });

  final int accuracyPercent;
  final int hitCount;
  final int totalCount;
  final int averageTimingMilliseconds;

  @override
  Widget build(BuildContext context) {
    final message = accuracyPercent >= 90
        ? 'LOCKED IN'
        : accuracyPercent >= 70
            ? 'SOLID FOUNDATION'
            : 'SLOW IT DOWN + REPEAT';
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: const Color(0xdd0d2b59),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: LostChrome.lime.withValues(alpha: .72)),
      ),
      child: Row(
        children: [
          Text('$accuracyPercent%',
              style: const TextStyle(
                  color: LostChrome.lime,
                  fontSize: 25,
                  fontWeight: FontWeight.w900)),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
                '$message\n$hitCount/$totalCount pitches • $averageTimingMilliseconds ms timing',
                style: const TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }
}

class PracticeHistorySheet extends StatefulWidget {
  const PracticeHistorySheet({required this.store, super.key});

  final PracticeHistoryStore store;

  @override
  State<PracticeHistorySheet> createState() => _PracticeHistorySheetState();
}

class _PracticeHistorySheetState extends State<PracticeHistorySheet> {
  late Future<List<PracticeSessionRecord>> _records;

  @override
  void initState() {
    super.initState();
    _records = widget.store.load();
  }

  void _refresh() => setState(() => _records = widget.store.load());

  @override
  Widget build(BuildContext context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: FutureBuilder<List<PracticeSessionRecord>>(
            future: _records,
            builder: (context, snapshot) {
              final records = snapshot.data ?? const [];
              final best = records.isEmpty
                  ? null
                  : records.reduce(
                      (a, b) => a.accuracyPercent >= b.accuracyPercent ? a : b);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.history, color: LostChrome.lime),
                      const SizedBox(width: 8),
                      const Text('PRACTICE HISTORY',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.w900)),
                      const Spacer(),
                      IconButton(
                        tooltip: 'Refresh history',
                        onPressed: _refresh,
                        icon: const Icon(Icons.refresh),
                      ),
                      IconButton(
                        tooltip: 'Close practice history',
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  if (snapshot.connectionState == ConnectionState.waiting)
                    const Expanded(
                        child: Center(child: CircularProgressIndicator()))
                  else if (records.isEmpty)
                    const Expanded(
                      child: Center(
                        child: Text(
                          'No completed Daily Drill sessions yet.\nFinish one to set your first best score.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Color(0xffa2d5f5)),
                        ),
                      ),
                    )
                  else ...[
                    Container(
                      margin: const EdgeInsets.only(bottom: 9),
                      padding: const EdgeInsets.all(11),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                            colors: [Color(0xee1778bd), Color(0xee0b315d)]),
                        borderRadius: BorderRadius.circular(13),
                        border: Border.all(color: LostChrome.lime),
                      ),
                      child: Text(
                        'BEST SESSION  •  ${best!.accuracyPercent}%  •  ${best.hitCount}/${best.noteCount} NOTES',
                        style: const TextStyle(
                            color: LostChrome.pearl,
                            fontWeight: FontWeight.w900,
                            letterSpacing: .4),
                      ),
                    ),
                    Expanded(
                      child: ListView.separated(
                        itemCount: records.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final record = records[index];
                          return ListTile(
                            leading: Text('${record.accuracyPercent}%',
                                style: const TextStyle(
                                    color: LostChrome.lime,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 18)),
                            title: Text(_practiceDate(record.completedAt),
                                style: const TextStyle(
                                    fontWeight: FontWeight.w900)),
                            subtitle: Text(
                                '${record.hitCount}/${record.noteCount} notes • ${record.averageTimingMilliseconds} ms timing'),
                            trailing: const Icon(Icons.check_circle_outline,
                                color: LostChrome.ice),
                          );
                        },
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ),
      );
}

String _practiceDate(DateTime value) {
  const months = [
    'JAN',
    'FEB',
    'MAR',
    'APR',
    'MAY',
    'JUN',
    'JUL',
    'AUG',
    'SEP',
    'OCT',
    'NOV',
    'DEC'
  ];
  final hour = value.hour == 0 ? 12 : (value.hour - 1) % 12 + 1;
  final period = value.hour < 12 ? 'AM' : 'PM';
  return '${months[value.month - 1]} ${value.day}, ${value.year} • $hour:${value.minute.toString().padLeft(2, '0')} $period';
}

class RiffVaultSheet extends StatefulWidget {
  const RiffVaultSheet(
      {required this.client, required this.catalog, super.key});

  final ControlClient client;
  final CatalogClient catalog;

  @override
  State<RiffVaultSheet> createState() => _RiffVaultSheetState();
}

class _RiffVaultSheetState extends State<RiffVaultSheet> {
  late Future<List<RiffCapture>> _riffs;
  final _name = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _riffs = widget.client.listRiffs();
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.client.saveRiff(_name.text);
      _name.clear();
      if (mounted) {
        setState(() {
          _saving = false;
          _riffs = widget.client.listRiffs();
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = '$error';
        });
      }
    }
  }

  Future<void> _play(String path) async {
    try {
      final player = await Process.start('pw-play', [path]);
      unawaited(player.stdout.drain());
      unawaited(player.stderr.drain());
    } on ProcessException {
      try {
        final player = await Process.start('aplay', [path]);
        unawaited(player.stdout.drain());
        unawaited(player.stderr.drain());
      } on ProcessException {
        if (mounted) setState(() => _error = 'No audio player is available');
      }
    }
  }

  @override
  Widget build(BuildContext context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(children: [
                const Icon(Icons.bookmark_added_outlined,
                    color: LostChrome.lime),
                const SizedBox(width: 8),
                const Text('RIFF VAULT',
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                const Spacer(),
                IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close)),
              ]),
              const Text(
                  'Save the most recent 30 seconds as clean DI and your current rig.',
                  style: TextStyle(color: Color(0xffa2d5f5))),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(
                    child: TextField(
                        controller: _name,
                        maxLength: 64,
                        decoration: const InputDecoration(
                            counterText: '',
                            labelText: 'Riff name (optional)',
                            hintText: 'Untitled Riff'))),
                const SizedBox(width: 8),
                FilledButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: _saving
                        ? const SizedBox.square(
                            dimension: 15,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.save_alt),
                    label: const Text('SAVE')),
              ]),
              if (_error != null)
                Text(_error!,
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.error)),
              const SizedBox(height: 6),
              const Text('SAVED RIFFS',
                  style: TextStyle(
                      fontWeight: FontWeight.w900, letterSpacing: 1.1)),
              Expanded(
                  child: FutureBuilder<List<RiffCapture>>(
                future: _riffs,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final riffs = snapshot.data ?? const [];
                  if (riffs.isEmpty) {
                    return const Center(
                        child: Text(
                            'Play a riff, then tap SAVE to preserve the last 30 seconds.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Color(0xffa2d5f5))));
                  }
                  return ListView.separated(
                    itemCount: riffs.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final riff = riffs[index];
                      return ListTile(
                        leading: const Icon(Icons.music_note,
                            color: LostChrome.electric),
                        title: Text(riff.name,
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Text(
                            '${riff.durationSeconds.toStringAsFixed(1)} sec • ${riff.preset}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        trailing: Wrap(children: [
                          IconButton(
                              tooltip: 'Play clean DI',
                              onPressed: () => _play(riff.cleanPath),
                              icon: const Icon(Icons.hearing)),
                          IconButton(
                              tooltip: 'Play processed rig',
                              onPressed: () => _play(riff.processedPath),
                              icon: const Icon(Icons.graphic_eq)),
                          IconButton(
                              tooltip: 'Make backing track',
                              onPressed: () => _showBackingTracks(riff),
                              icon: const Icon(Icons.auto_awesome,
                                  color: LostChrome.lime)),
                        ]),
                      );
                    },
                  );
                },
              )),
            ],
          ),
        ),
      );

  void _showBackingTracks(RiffCapture riff) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => FractionallySizedBox(
        heightFactor: .78,
        child: BackingTrackSheet(
          catalog: widget.catalog,
          riff: riff,
          onPlay: _play,
        ),
      ),
    );
  }
}

class TunerSheet extends StatefulWidget {
  const TunerSheet({required this.meters, super.key});

  final Stream<MeterSnapshot> meters;

  @override
  State<TunerSheet> createState() => _TunerSheetState();
}

class _TunerSheetState extends State<TunerSheet> {
  _Tuning _tuning = _tunings.first;
  MeterSnapshot _meter = const MeterSnapshot.silent();
  StreamSubscription<MeterSnapshot>? _meterSubscription;
  Timer? _holdTimer;
  int _stringIndex = 0;
  bool _holdingPitch = false;
  bool _completed = false;

  static const _holdDuration = Duration(milliseconds: 1000);

  String get _targetNote => _tuning.notes[_stringIndex];

  @override
  void initState() {
    super.initState();
    _meterSubscription = widget.meters.listen(_receiveMeter);
  }

  @override
  void dispose() {
    _meterSubscription?.cancel();
    _holdTimer?.cancel();
    super.dispose();
  }

  void _receiveMeter(MeterSnapshot meter) {
    if (!mounted) return;
    final reading = _TunerReading.forTarget(meter, _targetNote);
    final isStable =
        !_completed && reading.hasPitch && reading.cents.abs() <= 5;
    if (isStable && !_holdingPitch) {
      _holdTimer = Timer(_holdDuration, _advanceIfStillInTune);
    } else if (!isStable && _holdingPitch) {
      _holdTimer?.cancel();
      _holdTimer = null;
    }
    setState(() {
      _meter = meter;
      _holdingPitch = isStable;
    });
  }

  void _advanceIfStillInTune() {
    if (!mounted || !_holdingPitch) return;
    setState(() {
      _holdTimer = null;
      _holdingPitch = false;
      if (_stringIndex < _tuning.notes.length - 1) {
        _stringIndex += 1;
      } else {
        _completed = true;
      }
    });
  }

  void _chooseString(int index) {
    _holdTimer?.cancel();
    _holdTimer = null;
    setState(() {
      _stringIndex = index;
      _holdingPitch = false;
      _completed = false;
    });
  }

  void _chooseTuning(_Tuning tuning) {
    _holdTimer?.cancel();
    _holdTimer = null;
    setState(() {
      _tuning = tuning;
      _stringIndex = 0;
      _holdingPitch = false;
      _completed = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Builder(
        builder: (context) {
          final reading = _TunerReading.forTarget(_meter, _targetNote);
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Icon(Icons.tune, color: LostChrome.lime),
                    const SizedBox(width: 8),
                    const Text('CLEAN INPUT TUNER',
                        style: TextStyle(
                            fontSize: 19, fontWeight: FontWeight.w900)),
                    const Spacer(),
                    IconButton(
                      tooltip: 'Close tuner',
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const Text(
                    'Listens before NAM and effects. Your sound stays unchanged.',
                    style: TextStyle(color: Color(0xffa2d5f5))),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xee0f407c), Color(0xee081a43)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: LostChrome.ice, width: 1.3),
                  ),
                  child: Column(
                    children: [
                      Text(_targetNote,
                          style: const TextStyle(
                            fontSize: 55,
                            height: 1,
                            fontWeight: FontWeight.w900,
                            color: LostChrome.pearl,
                          )),
                      const SizedBox(height: 6),
                      Text(
                        _completed
                            ? 'ALL STRINGS TUNED'
                            : !reading.hasPitch
                                ? 'PLUCK $_targetNote ONLY'
                                : _holdingPitch
                                    ? 'IN TUNE — HOLD IT…'
                                    : '${reading.frequency.toStringAsFixed(1)} Hz  •  ${reading.cents >= 0 ? '+' : ''}${reading.cents.round()} cents',
                        style: const TextStyle(
                          color: LostChrome.lime,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _TunerNeedle(
                          cents: reading.cents, hasSignal: reading.hasPitch),
                      if (_holdingPitch) ...[
                        const SizedBox(height: 9),
                        const _TunerHoldIndicator(),
                      ],
                      const SizedBox(height: 3),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: const [
                          Text('FLAT',
                              style: TextStyle(
                                  fontSize: 10, color: Color(0xffa2d5f5))),
                          Text('IN TUNE',
                              style: TextStyle(
                                  fontSize: 10, color: Color(0xffa2d5f5))),
                          Text('SHARP',
                              style: TextStyle(
                                  fontSize: 10, color: Color(0xffa2d5f5))),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                const Text('GUIDED STRING',
                    style: TextStyle(
                        fontWeight: FontWeight.w900, letterSpacing: 1.2)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: [
                    for (var index = 0; index < _tuning.notes.length; index++)
                      ChoiceChip(
                        label: Text('${index + 1} ${_tuning.notes[index]}'),
                        selected: index == _stringIndex,
                        onSelected: (_) => _chooseString(index),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  _completed
                      ? 'Finished. Tap any string above to check it again.'
                      : 'Tune $_targetNote first. Other strings are ignored until it locks.',
                  textAlign: TextAlign.center,
                  style:
                      const TextStyle(color: Color(0xffa2d5f5), fontSize: 11),
                ),
                const SizedBox(height: 14),
                const Text('TUNING',
                    style: TextStyle(
                        fontWeight: FontWeight.w900, letterSpacing: 1.2)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: [
                    for (final tuning in _tunings)
                      ChoiceChip(
                        label: Text(tuning.name),
                        selected: tuning == _tuning,
                        onSelected: (_) => _chooseTuning(tuning),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  _tuning.notes.join('  '),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: LostChrome.ice,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class BackingTrackSheet extends StatefulWidget {
  const BackingTrackSheet({
    required this.catalog,
    required this.riff,
    required this.onPlay,
    super.key,
  });

  final CatalogClient catalog;
  final RiffCapture riff;
  final Future<void> Function(String path) onPlay;

  @override
  State<BackingTrackSheet> createState() => _BackingTrackSheetState();
}

class _BackingTrackSheetState extends State<BackingTrackSheet> {
  final _style = TextEditingController(
      text: 'Tight drums and bass, energetic alternative rock, no lead guitar');
  late Future<BackingTrackStatus> _status;
  late Future<List<BackingTrack>> _tracks;
  Timer? _poller;
  bool _submitting = false;
  String? _error;
  int _duration = 20;

  @override
  void initState() {
    super.initState();
    _status = widget.catalog.backingTrackStatus();
    _tracks = widget.catalog.listBackingTracks(widget.riff.id);
    _poller = Timer.periodic(const Duration(seconds: 2), (_) => _refresh());
  }

  @override
  void dispose() {
    _style.dispose();
    _poller?.cancel();
    super.dispose();
  }

  void _refresh() {
    if (!mounted) return;
    setState(() => _tracks = widget.catalog.listBackingTracks(widget.riff.id));
  }

  Future<void> _generate() async {
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await widget.catalog.createBackingTrack(
        riffId: widget.riff.id,
        style: _style.text,
        durationSeconds: _duration,
      );
      if (mounted) {
        setState(() {
          _submitting = false;
          _tracks = widget.catalog.listBackingTracks(widget.riff.id);
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _submitting = false;
          _error = '$error';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              const Icon(Icons.auto_awesome, color: LostChrome.lime),
              const SizedBox(width: 8),
              const Expanded(
                  child: Text('BACKING LAB',
                      style: TextStyle(
                          fontSize: 20, fontWeight: FontWeight.w900))),
              IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close)),
            ]),
            Text(
                'Build a supporting track around “${widget.riff.name}”. Saved results play offline.',
                style: const TextStyle(color: Color(0xffa2d5f5))),
            const SizedBox(height: 12),
            FutureBuilder<BackingTrackStatus>(
              future: _status,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const LinearProgressIndicator();
                }
                if (snapshot.hasError) {
                  return _BackingTrackNotice(text: '${snapshot.error}');
                }
                final available = snapshot.data?.available ?? false;
                if (!available) {
                  return const _BackingTrackNotice(
                      text:
                          'Add PEDAL_STABILITY_API_KEY to deploy/pedal-secrets.env, then restart the catalog service.');
                }
                return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        controller: _style,
                        minLines: 2,
                        maxLines: 3,
                        maxLength: 500,
                        decoration: const InputDecoration(
                          labelText: 'Backing style',
                          hintText: 'Drums, bass, mood, energy…',
                        ),
                      ),
                      Row(children: [
                        const Text('LENGTH',
                            style: TextStyle(fontWeight: FontWeight.w800)),
                        const SizedBox(width: 10),
                        ChoiceChip(
                            label: const Text('20 SEC'),
                            selected: _duration == 20,
                            onSelected: (_) => setState(() => _duration = 20)),
                        const SizedBox(width: 6),
                        ChoiceChip(
                            label: const Text('40 SEC'),
                            selected: _duration == 40,
                            onSelected: (_) => setState(() => _duration = 40)),
                        const Spacer(),
                        FilledButton.icon(
                          onPressed: _submitting ? null : _generate,
                          icon: _submitting
                              ? const SizedBox.square(
                                  dimension: 15,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.auto_awesome),
                          label: const Text('GENERATE'),
                        ),
                      ]),
                    ]);
              },
            ),
            if (_error != null) _BackingTrackNotice(text: _error!),
            const SizedBox(height: 10),
            const Text('CACHED BACKINGS',
                style:
                    TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.1)),
            Expanded(
              child: FutureBuilder<List<BackingTrack>>(
                future: _tracks,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('${snapshot.error}'));
                  }
                  final tracks = snapshot.data ?? const [];
                  if (tracks.isEmpty) {
                    return const Center(
                        child: Text('No backing tracks yet.',
                            style: TextStyle(color: Color(0xffa2d5f5))));
                  }
                  return ListView.separated(
                    itemCount: tracks.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final track = tracks[index];
                      final isReady =
                          track.status == 'ready' && track.path != null;
                      final status = switch (track.status) {
                        'queued' => 'WAITING TO START',
                        'rendering' => 'MAKING YOUR TRACK…',
                        'ready' =>
                          '${track.durationSeconds} SEC • OFFLINE READY',
                        _ => track.error ?? 'FAILED',
                      };
                      return ListTile(
                        leading: Icon(
                            isReady ? Icons.music_note : Icons.hourglass_top,
                            color: isReady
                                ? LostChrome.electric
                                : LostChrome.lime),
                        title: Text(track.style,
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Text(status,
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                        trailing: isReady
                            ? IconButton(
                                tooltip: 'Play backing track',
                                onPressed: () => widget.onPlay(track.path!),
                                icon: const Icon(Icons.play_arrow))
                            : null,
                      );
                    },
                  );
                },
              ),
            ),
          ]),
        ),
      );
}

class _BackingTrackNotice extends StatelessWidget {
  const _BackingTrackNotice({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xff12386b),
          border: Border.all(color: LostChrome.electric),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(text, style: const TextStyle(color: Color(0xffd9f4ff))),
      );
}

class _TunerHoldIndicator extends StatelessWidget {
  const _TunerHoldIndicator();

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: _TunerSheetState._holdDuration,
        builder: (context, value, _) => LinearProgressIndicator(
          value: value,
          minHeight: 4,
          borderRadius: BorderRadius.circular(4),
          color: LostChrome.lime,
          backgroundColor: const Color(0xff20528c),
        ),
      );
}

class _TunerNeedle extends StatelessWidget {
  const _TunerNeedle({required this.cents, required this.hasSignal});

  final double cents;
  final bool hasSignal;

  @override
  Widget build(BuildContext context) {
    final x = hasSignal ? (cents.clamp(-50, 50) / 50).toDouble() : 0.0;
    final inTune = hasSignal && cents.abs() <= 5;
    return SizedBox(
      height: 24,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
              height: 4,
              decoration: BoxDecoration(
                  color: const Color(0xff20528c),
                  borderRadius: BorderRadius.circular(4))),
          Container(width: 2, height: 18, color: LostChrome.pearl),
          Align(
            alignment: Alignment(x, 0),
            child: Container(
              width: 15,
              height: 15,
              decoration: BoxDecoration(
                color: inTune ? LostChrome.lime : LostChrome.ice,
                shape: BoxShape.circle,
                boxShadow: hasSignal
                    ? [
                        BoxShadow(
                            color: inTune ? LostChrome.lime : LostChrome.ice,
                            blurRadius: 8)
                      ]
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Tuning {
  const _Tuning(this.name, this.notes);

  final String name;
  final List<String> notes;
}

const _tunings = [
  _Tuning('Standard', ['E2', 'A2', 'D3', 'G3', 'B3', 'E4']),
  _Tuning('Drop D', ['D2', 'A2', 'D3', 'G3', 'B3', 'E4']),
  _Tuning('D Standard', ['D2', 'G2', 'C3', 'F♯3', 'A3', 'D4']),
  _Tuning('Drop C', ['C2', 'G2', 'C3', 'F3', 'A3', 'D4']),
  _Tuning('Open G', ['D2', 'G2', 'D3', 'G3', 'B3', 'D4']),
  _Tuning('Open D', ['D2', 'A2', 'D3', 'F♯3', 'A3', 'D4']),
];

class _TunerReading {
  const _TunerReading(
      {required this.frequency, required this.cents, required this.hasPitch});

  factory _TunerReading.forTarget(MeterSnapshot meter, String targetNote) {
    if (meter.tunerHz <= 0 || meter.tunerConfidence < .55) {
      return const _TunerReading(frequency: 0, cents: 0, hasPitch: false);
    }
    final cents =
        1200 * math.log(meter.tunerHz / _noteFrequency(targetNote)) / math.ln2;
    return _TunerReading(
      frequency: meter.tunerHz,
      cents: cents,
      hasPitch: true,
    );
  }

  final double frequency;
  final double cents;
  final bool hasPitch;
}

double _noteFrequency(String note) {
  final normalized = note.replaceAll('♯', '#');
  final octave = int.parse(normalized.substring(normalized.length - 1));
  final pitch = normalized.substring(0, normalized.length - 1);
  const semitones = {
    'C': 0,
    'C#': 1,
    'D': 2,
    'D#': 3,
    'E': 4,
    'F': 5,
    'F#': 6,
    'G': 7,
    'G#': 8,
    'A': 9,
    'A#': 10,
    'B': 11,
  };
  final midi = (octave + 1) * 12 + semitones[pitch]!;
  return 440 * math.pow(2, (midi - 69) / 12).toDouble();
}

class _ControlDefinition {
  const _ControlDefinition(
    this.keyName,
    this.label,
    this.minimum,
    this.maximum,
    this.divisions,
    this.unit, {
    this.percent = false,
  });

  final String keyName;
  final String label;
  final double minimum;
  final double maximum;
  final int divisions;
  final String unit;
  final bool percent;

  String format(double value) => percent
      ? '${(value * 100).round()}$unit'
      : '${value >= 0 ? '+' : ''}${value.toStringAsFixed(1)} $unit';
}

class _ControlSlider extends StatelessWidget {
  const _ControlSlider({
    required this.definition,
    required this.value,
    required this.onChanged,
    required this.onChangeEnd,
  });

  final _ControlDefinition definition;
  final double value;
  final ValueChanged<double> onChanged;
  final ValueChanged<double> onChangeEnd;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Text(definition.label,
                style: const TextStyle(fontWeight: FontWeight.w700)),
            const Spacer(),
            Text(definition.format(value)),
          ],
        ),
        Slider(
          value: value.clamp(definition.minimum, definition.maximum),
          min: definition.minimum,
          max: definition.maximum,
          divisions: definition.divisions,
          label: definition.format(value),
          onChanged: onChanged,
          onChangeEnd: onChangeEnd,
        ),
      ],
    );
  }
}

class ToneMakerSheet extends StatefulWidget {
  const ToneMakerSheet({
    required this.catalog,
    required this.engineConnected,
    required this.onApply,
    super.key,
  });

  final CatalogClient catalog;
  final bool engineConnected;
  final Future<void> Function(AiToneApplication application) onApply;

  @override
  State<ToneMakerSheet> createState() => _ToneMakerSheetState();
}

class _ToneMakerSheetState extends State<ToneMakerSheet> {
  final _prompt = TextEditingController();
  ToneMakerStatus? _status;
  AiToneRecommendation? _recommendation;
  int _selectedRig = 0;
  String? _error;
  bool _busy = true;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  @override
  void dispose() {
    _prompt.dispose();
    super.dispose();
  }

  Future<void> _loadStatus() async {
    try {
      final status = await widget.catalog.toneMakerStatus();
      if (!mounted) return;
      setState(() {
        _status = status;
        _busy = false;
        _error = null;
      });
    } catch (error) {
      if (mounted) setState(() => _setError(error));
    }
  }

  Future<void> _recommend() async {
    final prompt = _prompt.text.trim();
    if (prompt.length < 3) {
      setState(() => _error = 'Describe the tone you want first.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
      _recommendation = null;
    });
    try {
      final recommendation = await widget.catalog.requestAiTone(prompt);
      if (mounted) {
        setState(() {
          _recommendation = recommendation;
          _selectedRig = 0;
          _busy = false;
        });
      }
    } catch (error) {
      if (mounted) setState(() => _setError(error));
    }
  }

  Future<void> _apply() async {
    final recommendation = _recommendation;
    if (recommendation == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final application =
          await widget.catalog.applyAiTone(recommendation.id, _selectedRig);
      await widget.onApply(application);
      if (!mounted) return;
      Navigator.pop(context, application);
    } catch (error) {
      if (mounted) setState(() => _setError(error));
    }
  }

  void _setError(Object error) {
    _error = '$error';
    _busy = false;
  }

  void _useExample(String value) {
    _prompt.text = value;
    _prompt.selection = TextSelection.collapsed(offset: value.length);
    setState(() => _error = null);
  }

  @override
  Widget build(BuildContext context) {
    final status = _status;
    final recommendation = _recommendation;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_awesome, color: LostChrome.lime),
                const SizedBox(width: 7),
                Text('TONE MAKER',
                    style: Theme.of(context).textTheme.titleLarge),
                const Spacer(),
                IconButton(
                  tooltip: 'Refresh connection status',
                  onPressed: _busy ? null : _loadStatus,
                  icon: const Icon(Icons.refresh),
                ),
                IconButton(
                  tooltip: 'Close',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            Text(
              'Describe a sound. The device first checks your confirmed Tone Memory, then plans TONE3000 candidates if it needs something new.',
              style: TextStyle(color: LostChrome.ice.withValues(alpha: .78)),
            ),
            const SizedBox(height: 10),
            if (_busy) const LinearProgressIndicator(),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
            if (status == null)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else if (!status.available && !status.toneMemoryAvailable)
              Expanded(
                child: _ToneMakerMessage(
                  icon: Icons.key_off,
                  title: 'OpenAI is not configured',
                  detail:
                      'Add PEDAL_OPENAI_API_KEY to deploy/pedal-secrets.env, then restart the catalog service.',
                ),
              )
            else if (!status.tone3000Connected && !status.toneMemoryAvailable)
              Expanded(
                child: _ToneMakerMessage(
                  icon: Icons.cloud_off,
                  title: 'Connect TONE3000 first',
                  detail:
                      'Close this sheet, tap the cloud button in the header, and sign in once. Your downloaded tones will still work offline afterward.',
                ),
              )
            else
              Expanded(
                child: ListView(
                  children: [
                    if (status.toneMemoryAvailable) ...[
                      const _ToneMemoryReadyBanner(),
                      const SizedBox(height: 10),
                    ],
                    TextField(
                      controller: _prompt,
                      minLines: 2,
                      maxLines: 4,
                      textInputAction: TextInputAction.newline,
                      decoration: const InputDecoration(
                        labelText: 'WHAT SHOULD THIS RIG SOUND LIKE?',
                        hintText:
                            'Tight high-gain thrash rhythm with a dry, cutting lead…',
                        prefixIcon: Icon(Icons.graphic_eq),
                      ),
                    ),
                    const SizedBox(height: 7),
                    Wrap(
                      spacing: 6,
                      runSpacing: 5,
                      children: [
                        _PromptChip(
                          label: 'THRASH',
                          onTap: () => _useExample(
                              'Tight high-gain thrash rhythm with a dry, cutting lead'),
                        ),
                        _PromptChip(
                          label: 'SHOEGAZE',
                          onTap: () => _useExample(
                              'Wide shoegaze wall with soft compression and washed ambience'),
                        ),
                        _PromptChip(
                          label: 'CLEAN',
                          onTap: () => _useExample(
                              'Warm glassy clean with light breakup and a little space'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    FilledButton.icon(
                      onPressed: _busy ? null : _recommend,
                      icon: const Icon(Icons.auto_awesome),
                      label: const Text('PLAN MY TONE'),
                    ),
                    if (recommendation != null) ...[
                      const SizedBox(height: 14),
                      _AiPlanCard(
                        recommendation: recommendation,
                        selectedRig: _selectedRig,
                        onSelectRig: (index) =>
                            setState(() => _selectedRig = index),
                      ),
                      const SizedBox(height: 10),
                      FilledButton.icon(
                        onPressed:
                            _busy || !widget.engineConnected ? null : _apply,
                        icon: const Icon(Icons.download_done),
                        label: const Text('DOWNLOAD + APPLY SELECTED RIG'),
                      ),
                      if (!widget.engineConnected)
                        const Padding(
                          padding: EdgeInsets.only(top: 6),
                          child: Text(
                            'Connect the audio engine before applying this recommendation.',
                            textAlign: TextAlign.center,
                          ),
                        ),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PromptChip extends StatelessWidget {
  const _PromptChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ActionChip(
        label: Text(label,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900)),
        onPressed: onTap,
        backgroundColor: const Color(0x553876d6),
        side: BorderSide(color: LostChrome.ice.withValues(alpha: .45)),
      );
}

class _ToneMemoryReadyBanner extends StatelessWidget {
  const _ToneMemoryReadyBanner();

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0x3320c9a4),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: LostChrome.lime.withValues(alpha: .65)),
        ),
        child: const Row(
          children: [
            Icon(Icons.bookmark_added_outlined,
                color: LostChrome.lime, size: 18),
            SizedBox(width: 7),
            Expanded(
              child: Text(
                'TONE MEMORY READY — matching confirmed rigs can load offline.',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      );
}

class _ToneMakerMessage extends StatelessWidget {
  const _ToneMakerMessage({
    required this.icon,
    required this.title,
    required this.detail,
  });

  final IconData icon;
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: LostChrome.electric, size: 42),
            const SizedBox(height: 10),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 5),
            Text(detail, textAlign: TextAlign.center),
          ],
        ),
      );
}

class _AiPlanCard extends StatelessWidget {
  const _AiPlanCard({
    required this.recommendation,
    required this.selectedRig,
    required this.onSelectRig,
  });

  final AiToneRecommendation recommendation;
  final int selectedRig;
  final ValueChanged<int> onSelectRig;

  @override
  Widget build(BuildContext context) {
    final plan = recommendation.plan;
    final enabledEffects = plan.effects.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key.toUpperCase())
        .join(' • ');
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xdd155bb1), Color(0xdd0a2b63)],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: LostChrome.ice.withValues(alpha: .8)),
        boxShadow: const [BoxShadow(color: Color(0x6639bfff), blurRadius: 14)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('AI RIG PLAN — PICK ONE',
              style: TextStyle(
                  color: LostChrome.lime,
                  fontSize: 10,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w900)),
          const SizedBox(height: 5),
          Text(plan.summary,
              style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(
            switch (recommendation.rankingProvider) {
              'tone_memory' => 'TONE MEMORY • YOUR CONFIRMED CACHED RIG',
              'jev' => 'JEV RANKING • CATALOG METADATA, NOT AUDIO ANALYSIS',
              _ =>
                'OPENAI FALLBACK • ${(recommendation.rankingNote ?? 'Jev unavailable or uncertain.').toUpperCase()}',
            },
            style: TextStyle(
              color: LostChrome.ice.withValues(alpha: .75),
              fontSize: 8,
              letterSpacing: .55,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 9),
          for (final (index, rig) in recommendation.rigs.indexed) ...[
            _AiRigChoice(
              index: index,
              rig: rig,
              selected: index == selectedRig,
              onTap: () => onSelectRig(index),
            ),
            if (index != recommendation.rigs.length - 1)
              const SizedBox(height: 7),
          ],
          const SizedBox(height: 8),
          Text(
            'ENABLING: ${enabledEffects.isEmpty ? 'NO OPTIONAL EFFECTS' : enabledEffects}',
            style: TextStyle(
              color: LostChrome.ice.withValues(alpha: .8),
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: .5,
            ),
          ),
        ],
      ),
    );
  }
}

class _AiRigChoice extends StatelessWidget {
  const _AiRigChoice({
    required this.index,
    required this.rig,
    required this.selected,
    required this.onTap,
  });

  final int index;
  final AiToneRig rig;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        selected: selected,
        button: true,
        label: 'Rig ${index + 1}: ${rig.label}',
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color:
                  selected ? const Color(0xaa41bfff) : const Color(0x44265a9e),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: selected
                    ? LostChrome.lime
                    : LostChrome.ice.withValues(alpha: .38),
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  selected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  color: selected ? LostChrome.lime : LostChrome.ice,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('RIG ${index + 1} • ${rig.label.toUpperCase()}',
                          style: const TextStyle(
                              fontSize: 10,
                              letterSpacing: .75,
                              fontWeight: FontWeight.w900)),
                      const SizedBox(height: 2),
                      Text(
                        '${rig.pedal?.name ?? 'NO DRIVE NAM'}  →  ${rig.amp.name}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: LostChrome.pearl,
                            fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(rig.rationale,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 10,
                              color: LostChrome.ice.withValues(alpha: .78))),
                      if (rig.rankingConfidence != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'JEV CONFIDENCE: ${rig.confidenceLabel} '
                          '• ${(rig.rankingConfidence! * 100).round()}%',
                          style: TextStyle(
                            color: rig.rankingConfidence! >= .8
                                ? LostChrome.lime
                                : LostChrome.ice.withValues(alpha: .8),
                            fontSize: 9,
                            letterSpacing: .55,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

class ModelLibrarySheet extends StatefulWidget {
  const ModelLibrarySheet({
    required this.catalog,
    required this.engineConnected,
    required this.selectedPrePath,
    required this.selectedAmpPath,
    required this.onSelected,
    this.initialSlot,
    super.key,
  });

  final CatalogClient catalog;
  final bool engineConnected;
  final String? selectedPrePath;
  final String? selectedAmpPath;
  final Future<void> Function(CatalogModel, ModelSlot) onSelected;
  final ModelSlot? initialSlot;

  @override
  State<ModelLibrarySheet> createState() => _ModelLibrarySheetState();
}

class _ModelLibrarySheetState extends State<ModelLibrarySheet> {
  late Future<List<CatalogModel>> _models;
  String? _selectingPath;
  String? _selectionError;

  @override
  void initState() {
    super.initState();
    _models = widget.catalog.listModels();
  }

  void _refresh() => setState(() => _models = widget.catalog.refreshAndList());

  Future<void> _chooseSlot(CatalogModel model) async {
    if (widget.initialSlot case final slot?) {
      await _select(model, slot);
      return;
    }
    final slot = await showDialog<ModelSlot>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(model.name),
        content: const Text('Where should this NAM model run?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, ModelSlot.pre),
            child: const Text('PEDAL'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, ModelSlot.amp),
            child: const Text('AMP'),
          ),
        ],
      ),
    );
    if (slot != null) await _select(model, slot);
  }

  Future<void> _select(CatalogModel model, ModelSlot slot) async {
    setState(() {
      _selectingPath = model.path;
      _selectionError = null;
    });
    try {
      await widget.onSelected(model, slot);
      if (mounted) Navigator.of(context).pop();
    } catch (error) {
      if (mounted) {
        setState(() {
          _selectingPath = null;
          _selectionError = '$error';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text('LOCAL TONES',
                    style: Theme.of(context).textTheme.titleLarge),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    builder: (context) => FractionallySizedBox(
                      heightFactor: 0.92,
                      child: Tone3000BrowserSheet(
                        catalog: widget.catalog,
                        engineConnected: widget.engineConnected,
                        onSelected: widget.onSelected,
                        initialSlot: widget.initialSlot,
                      ),
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  icon: const Icon(Icons.cloud_download_outlined, size: 18),
                  label: const Text('TONE3000'),
                ),
                IconButton(
                  tooltip: 'Rescan model folder',
                  onPressed: _refresh,
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            if (!widget.engineConnected)
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Text(
                    'Engine is offline. Browsing is available; selection is disabled.'),
              ),
            if (_selectionError != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  _selectionError!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            Expanded(
              child: FutureBuilder<List<CatalogModel>>(
                future: _models,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return _LibraryMessage(
                      icon: Icons.cloud_off,
                      title: 'Catalog unavailable',
                      detail: '${snapshot.error}',
                      action: _refresh,
                    );
                  }
                  final models = snapshot.data ?? const [];
                  if (models.isEmpty) {
                    return _LibraryMessage(
                      icon: Icons.queue_music,
                      title: 'No local tones yet',
                      detail:
                          'Add a .nam file to the model library, then tap refresh.',
                      action: _refresh,
                    );
                  }
                  return ListView.separated(
                    itemCount: models.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final model = models[index];
                      final usedAsPre = model.path == widget.selectedPrePath;
                      final usedAsAmp = model.path == widget.selectedAmpPath;
                      final selected = usedAsPre || usedAsAmp;
                      final selecting = model.path == _selectingPath;
                      return ListTile(
                        leading: Icon(
                            selected ? Icons.check_circle : Icons.graphic_eq),
                        title: Text(model.name),
                        subtitle: Text([
                          model.sourceLabel,
                          if (usedAsPre) 'PEDAL',
                          if (usedAsAmp) 'AMP',
                        ].join(' • ')),
                        trailing: selecting
                            ? const SizedBox.square(
                                dimension: 22,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Text(model.sizeLabel),
                        selected: selected,
                        enabled:
                            widget.engineConnected && _selectingPath == null,
                        onTap: widget.engineConnected && _selectingPath == null
                            ? () => _chooseSlot(model)
                            : null,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Tone3000BrowserSheet extends StatefulWidget {
  const Tone3000BrowserSheet({
    required this.catalog,
    required this.engineConnected,
    required this.onSelected,
    this.initialSlot,
    super.key,
  });

  final CatalogClient catalog;
  final bool engineConnected;
  final Future<void> Function(CatalogModel, ModelSlot) onSelected;
  final ModelSlot? initialSlot;

  @override
  State<Tone3000BrowserSheet> createState() => _Tone3000BrowserSheetState();
}

class _Tone3000BrowserSheetState extends State<Tone3000BrowserSheet> {
  Tone3000Status? _status;
  SelectedTone? _selection;
  Timer? _loginPoll;
  String? _authorizeUrl;
  String? _error;
  bool _busy = true;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  @override
  void dispose() {
    _loginPoll?.cancel();
    super.dispose();
  }

  Future<void> _loadStatus() async {
    try {
      final status = await widget.catalog.tone3000Status();
      if (!mounted) return;
      setState(() {
        _status = status;
        _busy = false;
        _error = null;
      });
      if (status.selectedToneId != null) {
        _loginPoll?.cancel();
        await _loadSelected();
      } else if (!status.authPending && _authorizeUrl != null) {
        _loginPoll?.cancel();
        setState(() => _authorizeUrl = null);
      }
    } catch (error) {
      if (mounted) setState(() => _setError(error));
    }
  }

  Future<void> _browse() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final url = await widget.catalog.beginTone3000Auth();
      if (!mounted) return;
      setState(() {
        _authorizeUrl = url;
        _busy = false;
      });
      _loginPoll?.cancel();
      _loginPoll = Timer.periodic(
        const Duration(seconds: 2),
        (_) => _loadStatus(),
      );
    } catch (error) {
      if (mounted) setState(() => _setError(error));
    }
  }

  Future<void> _loadSelected() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final selection = await widget.catalog.selectedTone3000();
      if (mounted) {
        setState(() {
          _selection = selection;
          _authorizeUrl = null;
          _busy = false;
        });
      }
    } catch (error) {
      if (mounted) setState(() => _setError(error));
    }
  }

  void _setError(Object error) {
    _error = '$error';
    _busy = false;
  }

  Future<void> _download(RemoteTone tone, RemoteModel remote) async {
    setState(() => _busy = true);
    try {
      final model =
          await widget.catalog.downloadTone3000Model(tone.id, remote.id);
      if (!mounted) return;
      setState(() {
        _busy = false;
        _selection = null;
      });
      if (!widget.engineConnected) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Downloaded for offline use.')),
        );
        return;
      }
      final slot = widget.initialSlot ??
          await showDialog<ModelSlot>(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(model.name),
              content: const Text('Downloaded. Where should this model run?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, ModelSlot.pre),
                  child: const Text('PEDAL'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, ModelSlot.amp),
                  child: const Text('AMP'),
                ),
              ],
            ),
          );
      if (slot != null) {
        await widget.onSelected(model, slot);
        if (mounted) Navigator.of(context).pop();
      }
    } catch (error) {
      if (mounted) setState(() => _setError(error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = _status;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(children: [
              Text('TONE3000', style: Theme.of(context).textTheme.titleLarge),
              const Spacer(),
              if (status?.connected ?? false)
                IconButton(
                  tooltip: 'Disconnect account',
                  onPressed: _busy
                      ? null
                      : () async {
                          await widget.catalog.disconnectTone3000();
                          await _loadStatus();
                        },
                  icon: const Icon(Icons.logout),
                ),
            ]),
            if (_error != null)
              Text(_error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error)),
            if (_busy) const LinearProgressIndicator(),
            const SizedBox(height: 8),
            if (status == null)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else if (!status.available)
              const Expanded(
                child: Center(
                  child: Text(
                    'Online browsing is not configured.\nLocal downloaded tones still work offline.',
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            else if (_authorizeUrl != null)
              Expanded(child: _buildHandoff())
            else if (_selection != null)
              Expanded(child: _buildSelection(_selection!))
            else
              Expanded(child: _buildBrowse()),
          ],
        ),
      ),
    );
  }

  Widget _buildBrowse() => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Browse TONE3000’s community library of NAM captures. '
              'TONE3000 handles sign-in, previews, and tone selection.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: _busy ? null : _browse,
              icon: const Icon(Icons.open_in_browser),
              label: const Text('BROWSE TONE3000'),
            ),
          ],
        ),
      );

  Widget _buildHandoff() {
    return ListView(children: [
      const Text(
          'Open this address to sign in, preview tones, and select one:'),
      const SizedBox(height: 8),
      SelectableText(_authorizeUrl!),
      const SizedBox(height: 8),
      FilledButton.tonalIcon(
        onPressed: () => Clipboard.setData(ClipboardData(text: _authorizeUrl!)),
        icon: const Icon(Icons.copy),
        label: const Text('COPY LINK'),
      ),
      const SizedBox(height: 8),
      const Text('Waiting for tone selection…', textAlign: TextAlign.center),
    ]);
  }

  Widget _buildSelection(SelectedTone selection) => Column(children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(selection.tone.gear == 'pedal'
              ? Icons.tune
              : Icons.speaker_outlined),
          title: Text(selection.tone.name),
          subtitle: Text(
              '${selection.tone.author} • ${selection.tone.gear.toUpperCase()}'),
          trailing: TextButton(
            onPressed: _busy ? null : _browse,
            child: const Text('CHANGE'),
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: selection.models.isEmpty
              ? const Center(child: Text('No compatible NAM A2 models found.'))
              : ListView.separated(
                  itemCount: selection.models.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final model = selection.models[index];
                    return ListTile(
                      dense: true,
                      leading: const Icon(Icons.graphic_eq),
                      title: Text(model.name),
                      subtitle: const Text('NAM A2'),
                      trailing: const Icon(Icons.download),
                      enabled: !_busy,
                      onTap:
                          _busy ? null : () => _download(selection.tone, model),
                    );
                  },
                ),
        ),
      ]);
}

class _LibraryMessage extends StatelessWidget {
  const _LibraryMessage({
    required this.icon,
    required this.title,
    required this.detail,
    required this.action,
  });

  final IconData icon;
  final String title;
  final String detail;
  final VoidCallback action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 42),
          const SizedBox(height: 12),
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(detail, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: action, child: const Text('REFRESH')),
        ],
      ),
    );
  }
}

class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.connected});

  final bool connected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: connected ? LostChrome.lime : LostChrome.ice,
        boxShadow: [
          BoxShadow(
            color: connected ? LostChrome.lime : LostChrome.ice,
            blurRadius: 8,
          ),
        ],
      ),
    );
  }
}

class _UtilityDeck extends StatelessWidget {
  const _UtilityDeck({required this.snapshot, required this.onOpenRiffVault});

  final MeterSnapshot snapshot;
  final VoidCallback onOpenRiffVault;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ChromeUtilityPanel(
            title: 'INPUT SCOPE',
            detail: 'LIVE // PRE NAM',
            icon: Icons.graphic_eq,
            accent: LostChrome.electric,
            action: IconButton(
              tooltip: 'Riff Vault',
              onPressed: onOpenRiffVault,
              constraints: const BoxConstraints.tightFor(width: 25, height: 25),
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.bookmark_added_outlined, size: 16),
            ),
            child: CustomPaint(
              painter: _AudioScopePainter(
                inputDb: snapshot.inputDb,
                outputDb: snapshot.outputDb,
                clipped: snapshot.clipped,
              ),
              child: const SizedBox.expand(),
            ),
          ),
        ),
        const SizedBox(width: 8),
        const Expanded(child: _AeroLagoonTank()),
      ],
    );
  }
}

class _ChromeUtilityPanel extends StatelessWidget {
  const _ChromeUtilityPanel({
    required this.title,
    required this.detail,
    required this.icon,
    required this.accent,
    required this.child,
    this.action,
  });

  final String title;
  final String detail;
  final IconData icon;
  final Color accent;
  final Widget child;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xe6113a72),
            const Color(0xe608214c),
            accent.withValues(alpha: .24),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: LostChrome.ice.withValues(alpha: .8)),
        boxShadow: [
          BoxShadow(color: accent.withValues(alpha: .3), blurRadius: 13),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 7, 10, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icon, size: 13, color: accent),
                const SizedBox(width: 5),
                Text(title,
                    style: const TextStyle(
                      fontSize: 9,
                      letterSpacing: 1.1,
                      fontWeight: FontWeight.w900,
                    )),
                const Spacer(),
                if (action != null) action!,
                if (action != null) const SizedBox(width: 3),
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: accent,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: accent, blurRadius: 6)],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(detail,
                style: TextStyle(
                    color: LostChrome.ice.withValues(alpha: .62),
                    fontWeight: FontWeight.w700,
                    letterSpacing: .8,
                    fontSize: 7)),
            const SizedBox(height: 4),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}

enum _CyberFishShape { glider, prism, byte }

enum _FishPace { steady, coast, dart, pulse }

class _LagoonFish {
  const _LagoonFish({
    required this.shape,
    required this.color,
    required this.fromLeft,
    required this.lane,
    required this.delay,
    required this.travel,
    required this.scale,
    required this.swimAmplitude,
    required this.swimCycles,
    required this.swimPhase,
    required this.tailBeats,
    required this.pace,
  });

  final _CyberFishShape shape;
  final Color color;
  final bool fromLeft;
  final double lane;
  final double delay;
  final double travel;
  final double scale;
  final double swimAmplitude;
  final double swimCycles;
  final double swimPhase;
  final double tailBeats;
  final _FishPace pace;
}

class _AeroLagoonTank extends StatefulWidget {
  const _AeroLagoonTank();

  @override
  State<_AeroLagoonTank> createState() => _AeroLagoonTankState();
}

class _AeroLagoonTankState extends State<_AeroLagoonTank>
    with SingleTickerProviderStateMixin {
  static const _pixelWidth = 6.0;
  static const _pixelHeight = 3.0;
  static const _refreshInterval = Duration(milliseconds: 83);

  final _random = math.Random();
  late final AnimationController _controller;
  late List<_LagoonFish> _fish;
  ui.Image? _pixelFrame;
  Size? _rasterSize;
  DateTime? _lastRasterizedAt;
  Timer? _rasterTimer;
  bool _isRasterizing = false;

  @override
  void initState() {
    super.initState();
    _fish = _spawnFish();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          setState(() => _fish = _spawnFish());
          _controller.forward(from: 0);
        }
      })
      ..addListener(_schedulePixelFrame);
    _controller.forward();
  }

  List<_LagoonFish> _spawnFish() {
    const colors = [
      Color(0xff2bbdff),
      Color(0xffff5c70),
      Color(0xffff963d),
    ];
    final count = 1 + _random.nextInt(2);
    final paceOffset = _random.nextInt(_FishPace.values.length);
    return List.generate(
      count,
      (index) => _LagoonFish(
        shape: _CyberFishShape
            .values[_random.nextInt(_CyberFishShape.values.length)],
        color: colors[_random.nextInt(colors.length)],
        fromLeft: _random.nextBool(),
        lane: .23 + _random.nextDouble() * .48,
        // Every fish finishes offscreen before the next scene is seeded.
        // That keeps the handoff invisible even on a slow display.
        delay: index == 0 ? 0 : .13 + _random.nextDouble() * .12,
        travel: .45 + _random.nextDouble() * .10,
        scale: .72 + _random.nextDouble() * .25,
        // These variations create a mix of slow arcs, tighter figure-eight
        // passes, and differently paced body language without ever reversing
        // a fish's forward travel.
        swimAmplitude: 5 + _random.nextDouble() * 8,
        swimCycles: 1.05 + _random.nextDouble() * 1.15,
        swimPhase: _random.nextDouble() * math.pi * 2,
        tailBeats: 3.5 + _random.nextDouble() * 3.5,
        // Cycle through a shuffled set for each pass, rather than giving
        // every fish the same "slow-fast-slow" easing curve.
        pace: _FishPace.values[(paceOffset + index) % _FishPace.values.length],
      ),
    );
  }

  @override
  void dispose() {
    _rasterTimer?.cancel();
    _pixelFrame?.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _setRasterSize(Size size) {
    if (!size.width.isFinite || !size.height.isFinite || size.isEmpty) return;
    if (_rasterSize == size) return;
    _rasterSize = size;
    WidgetsBinding.instance.addPostFrameCallback((_) => _schedulePixelFrame());
  }

  void _schedulePixelFrame() {
    if (!mounted || _isRasterizing || _rasterSize == null) return;
    final now = DateTime.now();
    final last = _lastRasterizedAt;
    final remaining =
        last == null ? Duration.zero : _refreshInterval - now.difference(last);
    if (remaining > Duration.zero) {
      _rasterTimer ??= Timer(remaining, () {
        _rasterTimer = null;
        _rasterizeLagoon();
      });
      return;
    }
    _rasterizeLagoon();
  }

  Future<void> _rasterizeLagoon() async {
    final size = _rasterSize;
    if (!mounted || _isRasterizing || size == null) return;
    _isRasterizing = true;
    _lastRasterizedAt = DateTime.now();
    final sampleWidth = math.max(1, (size.width / _pixelWidth).ceil());
    final sampleHeight = math.max(1, (size.height / _pixelHeight).ceil());
    final recorder = ui.PictureRecorder();
    final sampleCanvas = Canvas(recorder);
    // Paint the full illustration onto a tiny bitmap, then let the frame
    // painter enlarge it with nearest-neighbour sampling. This is actual
    // raster pixelation rather than a decorative grid over vector artwork.
    sampleCanvas.scale(1 / _pixelWidth, 1 / _pixelHeight);
    _AeroLagoonPainter(
      progress: AlwaysStoppedAnimation(_controller.value),
      fish: _fish,
    ).paint(sampleCanvas, size);
    final picture = recorder.endRecording();
    try {
      final nextFrame = await picture.toImage(sampleWidth, sampleHeight);
      if (!mounted) {
        nextFrame.dispose();
        return;
      }
      final previousFrame = _pixelFrame;
      setState(() => _pixelFrame = nextFrame);
      WidgetsBinding.instance
          .addPostFrameCallback((_) => previousFrame?.dispose());
    } finally {
      picture.dispose();
      _isRasterizing = false;
      _schedulePixelFrame();
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _setRasterSize(constraints.biggest);
        return ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(color: LostChrome.ice.withValues(alpha: .9)),
              borderRadius: BorderRadius.circular(14),
              boxShadow: const [
                BoxShadow(color: Color(0x8029b9ff), blurRadius: 15),
              ],
            ),
            child: Stack(
              children: [
                RepaintBoundary(
                  child: CustomPaint(
                    painter: _pixelFrame == null
                        ? _AeroLagoonPainter(
                            progress: _controller,
                            fish: _fish,
                          )
                        : _PixelatedLagoonFramePainter(_pixelFrame!),
                    child: const SizedBox.expand(),
                  ),
                ),
                IgnorePointer(
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xaa073b7e),
                            borderRadius: BorderRadius.circular(7),
                            border: Border.all(color: LostChrome.ice),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.waves,
                                  size: 11, color: LostChrome.pearl),
                              SizedBox(width: 4),
                              Text('AERO LAGOON',
                                  style: TextStyle(
                                    color: LostChrome.pearl,
                                    fontSize: 8,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: .9,
                                  )),
                            ],
                          ),
                        ),
                        const Spacer(),
                        const _LagoonStatus(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _LagoonStatus extends StatelessWidget {
  const _LagoonStatus();

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xaa073b7e),
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: LostChrome.ice.withValues(alpha: .8)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.circle, color: LostChrome.lime, size: 7),
            SizedBox(width: 3),
            Text('AQUA',
                style: TextStyle(
                  color: LostChrome.pearl,
                  fontSize: 7,
                  letterSpacing: .7,
                  fontWeight: FontWeight.w900,
                )),
          ],
        ),
      );
}

/// Enlarges a low-resolution screenshot with nearest-neighbour sampling.
/// Every visible cell is therefore a real 6 × 3 display pixel, not a grid
/// placed on top of normal vector artwork.
class _PixelatedLagoonFramePainter extends CustomPainter {
  const _PixelatedLagoonFramePainter(this.frame);

  final ui.Image frame;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawImageRect(
      frame,
      Rect.fromLTWH(0, 0, frame.width.toDouble(), frame.height.toDouble()),
      Offset.zero & size,
      Paint()
        ..filterQuality = FilterQuality.none
        ..isAntiAlias = false,
    );
  }

  @override
  bool shouldRepaint(covariant _PixelatedLagoonFramePainter oldDelegate) =>
      frame != oldDelegate.frame;
}

class _AeroLagoonPainter extends CustomPainter {
  const _AeroLagoonPainter({required this.progress, required this.fish})
      : super(repaint: progress);

  final Animation<double> progress;
  final List<_LagoonFish> fish;

  @override
  void paint(Canvas canvas, Size size) {
    // Keep almost the entire window usable as water, with only a thin sky
    // band above the waterline.
    final waterTop = size.height * .10;
    final sky = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xff79ddff), Color(0xffd9f9ff)],
      ).createShader(Offset.zero & Size(size.width, waterTop));
    canvas.drawRect(Offset.zero & size, sky);

    _cloud(canvas, Offset(size.width * .18, size.height * .16), 1);
    _cloud(canvas, Offset(size.width * .77, size.height * .25), .62);

    final water = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xbb8ce9ff), Color(0xdd1caee0), Color(0xee0870b8)],
      ).createShader(Rect.fromLTWH(0, waterTop, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, waterTop, size.width, size.height), water);
    // Keep the field rooted in the bottom forty percent of the aquarium,
    // like a bright old Windows landscape behind the swimming area.
    _hill(canvas, size, .76, const Color(0xffa8ee62), size.height * .55,
        size.height);
    _hill(canvas, size, .32, const Color(0xff4fc34c), size.height * .66,
        size.height);
    _plants(canvas, size);
    _waterLines(canvas, size, waterTop);
    _bubbles(canvas, size, waterTop, progress.value);
    for (final swimmer in fish) {
      _drawFish(canvas, size, waterTop, swimmer, progress.value);
    }
    final shine = Paint()
      ..shader = LinearGradient(
        colors: [Colors.white.withValues(alpha: .42), Colors.transparent],
      ).createShader(Rect.fromLTWH(0, 0, size.width * .22, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), shine);
  }

  void _cloud(Canvas canvas, Offset center, double scale) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: .72)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawOval(
        Rect.fromCenter(center: center, width: 48 * scale, height: 14 * scale),
        paint);
    canvas.drawCircle(
        center + Offset(4 * scale, -7 * scale), 10 * scale, paint);
    canvas.drawCircle(
        center + Offset(-11 * scale, -4 * scale), 7 * scale, paint);
  }

  void _hill(
    Canvas canvas,
    Size size,
    double center,
    Color color,
    double top,
    double bottom,
  ) {
    final path = Path()
      ..moveTo(-size.width * .2, bottom)
      ..quadraticBezierTo(size.width * center, top, size.width * 1.2, bottom)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  void _plants(Canvas canvas, Size size) {
    final vinePaint = Paint()
      ..color = const Color(0xff287e46)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    final leafPaint = Paint()..color = const Color(0xff70d95a);
    for (final vine in [(.10, .25), (.82, .20), (.92, .34)]) {
      final x = size.width * vine.$1;
      final end = size.height * vine.$2;
      final path = Path()
        ..moveTo(x, -4)
        ..cubicTo(x - 10, end * .26, x + 13, end * .6, x - 3, end);
      canvas.drawPath(path, vinePaint);
      _leaf(canvas, Offset(x + 3, end * .56), -0.5, leafPaint);
      _leaf(canvas, Offset(x - 4, end * .78), 0.55, leafPaint);
    }

    final stemPaint = Paint()
      ..color = const Color(0xff1d874f)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (final plant in [(.16, .77), (.58, .82), (.89, .72)]) {
      final root = Offset(size.width * plant.$1, size.height + 2);
      final tip = Offset(size.width * plant.$1 + 4, size.height * plant.$2);
      final stem = Path()
        ..moveTo(root.dx, root.dy)
        ..quadraticBezierTo(root.dx - 10, tip.dy + 15, tip.dx, tip.dy);
      canvas.drawPath(stem, stemPaint);
      _leaf(canvas, Offset(root.dx - 5, tip.dy + 16), -1.05, leafPaint);
      _leaf(canvas, Offset(root.dx + 4, tip.dy + 9), .65, leafPaint);
      _leaf(canvas, tip, -0.25, leafPaint);
    }
  }

  void _leaf(Canvas canvas, Offset center, double angle, Paint paint) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle);
    canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: 11, height: 5), paint);
    canvas.restore();
  }

  void _waterLines(Canvas canvas, Size size, double waterTop) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: .3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (var line = 0; line < 5; line++) {
      final y = waterTop + 7 + line * 12;
      final path = Path()..moveTo(0, y);
      for (var x = 0.0; x <= size.width; x += 10) {
        path.lineTo(x, y + math.sin(x * .09 + line) * 1.5);
      }
      canvas.drawPath(path, paint);
    }
  }

  void _bubbles(Canvas canvas, Size size, double waterTop, double time) {
    const bubbles = [
      (0.13, 4.7, 9.0),
      (0.31, 6.2, 6.0),
      (0.68, 5.4, 11.0),
      (0.85, 7.1, 7.0),
    ];
    for (final bubble in bubbles) {
      // The phase is exactly the same at t=0 and t=1, so controller loops
      // do not create a visible bubble jump.
      final travel = (time + bubble.$1) % 1;
      final radius = bubble.$3 / 2;
      final opacity = math.sin(travel * math.pi).clamp(0.0, 1.0);
      final center = Offset(
        size.width * bubble.$1 + math.sin(travel * math.pi * 2) * 5,
        size.height + radius - travel * (size.height - waterTop + radius * 2),
      );
      final fill = Paint()
        ..shader = RadialGradient(colors: [
          Colors.white.withValues(alpha: .8 * opacity),
          const Color(0xff6ee4ff).withValues(alpha: .34 * opacity),
          const Color(0xff126da8).withValues(alpha: .12 * opacity),
        ]).createShader(Rect.fromCircle(center: center, radius: radius));
      canvas.drawCircle(center, radius, fill);
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = LostChrome.pearl.withValues(alpha: .8 * opacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = .8,
      );
    }
  }

  void _drawFish(
    Canvas canvas,
    Size size,
    double waterTop,
    _LagoonFish swimmer,
    double time,
  ) {
    final phase = (time - swimmer.delay) / swimmer.travel;
    if (phase < 0 || phase > 1) return;
    final position = _swimPosition(size, waterTop, swimmer, phase);
    // Sample the curve just ahead and behind the fish so its nose always
    // leads the route it is actually taking. The horizontal direction stays
    // monotonic; the curve only supplies a gentle pitch into each turn.
    final before =
        _swimPosition(size, waterTop, swimmer, math.max(0, phase - .015));
    final after =
        _swimPosition(size, waterTop, swimmer, math.min(1, phase + .015));
    final path = after - before;
    final pathPitch = math.atan2(path.dy, path.dx.abs()).clamp(-.42, .42);
    canvas.save();
    canvas.translate(position.dx, position.dy);
    // Artwork faces left by default. Rotate first, then flip only for a
    // left-to-right pass, so the eye/nose always faces forward.
    canvas.rotate(swimmer.fromLeft ? pathPitch : -pathPitch);
    if (swimmer.fromLeft) canvas.scale(-1, 1);
    canvas.scale(swimmer.scale);
    _fishBody(
      canvas,
      swimmer.shape,
      swimmer.color,
      phase * swimmer.tailBeats + swimmer.swimPhase / (math.pi * 2),
    );
    canvas.restore();
  }

  Offset _swimPosition(
    Size size,
    double waterTop,
    _LagoonFish swimmer,
    double phase,
  ) {
    final travel = switch (swimmer.pace) {
      // A calm, constant cruise gives the scene a needed visual baseline.
      _FishPace.steady => phase,
      // A quick entry that settles into a leisurely pass.
      _FishPace.coast => Curves.easeOutCubic.transform(phase),
      // A slow approach that turns into a late, decisive dart.
      _FishPace.dart => Curves.easeInCubic.transform(phase),
      // Small, strictly forward speed pulses: derivative stays positive, so
      // the fish never looks as though it reverses direction.
      _FishPace.pulse => phase + math.sin(phase * math.pi * 4) * .035,
    };
    final x = swimmer.fromLeft
        ? -48 + (size.width + 96) * travel
        : size.width + 48 - (size.width + 96) * travel;
    final wave = phase * swimmer.swimCycles * math.pi * 2 + swimmer.swimPhase;
    final y = waterTop +
        (size.height - waterTop) * swimmer.lane +
        math.sin(wave) * swimmer.swimAmplitude +
        math.sin(wave * 2 + .9) * swimmer.swimAmplitude * .28;
    return Offset(x, y);
  }

  void _fishBody(
      Canvas canvas, _CyberFishShape shape, Color color, double swimTime) {
    final light = Color.lerp(color, Colors.white, .58)!;
    final dark = Color.lerp(color, const Color(0xff062766), .55)!;
    final body = switch (shape) {
      _CyberFishShape.glider => Path()
        ..moveTo(-35, 0)
        ..quadraticBezierTo(-23, -20, 19, -17)
        ..quadraticBezierTo(34, -9, 38, 0)
        ..quadraticBezierTo(31, 15, 18, 18)
        ..quadraticBezierTo(-22, 19, -35, 0)
        ..close(),
      _CyberFishShape.prism => Path()
        ..moveTo(-37, 0)
        ..lineTo(-23, -16)
        ..lineTo(20, -18)
        ..lineTo(38, 0)
        ..lineTo(20, 18)
        ..lineTo(-23, 16)
        ..close(),
      _CyberFishShape.byte => Path()
        ..moveTo(-38, 0)
        ..lineTo(-22, -14)
        ..lineTo(22, -14)
        ..lineTo(38, 0)
        ..lineTo(22, 14)
        ..lineTo(-22, 14)
        ..close(),
    };
    final bounds = body.getBounds();
    final paint = Paint()
      ..shader =
          LinearGradient(colors: [light, color, dark]).createShader(bounds);
    canvas.drawPath(body, paint);
    canvas.drawPath(
      body,
      Paint()
        ..color = LostChrome.pearl
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    final tailWag = math.sin(swimTime * math.pi * 2) * 5;
    final tail = Path()
      ..moveTo(31, 0)
      ..lineTo(50, -13 + tailWag)
      ..lineTo(44, 0)
      ..lineTo(50, 13 - tailWag)
      ..close();
    canvas.drawPath(tail, Paint()..color = color);
    canvas.drawPath(
      tail,
      Paint()
        ..color = LostChrome.ice
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    final finLift = math.sin(swimTime * math.pi * 2 + .8) * 3;
    final fin = Path()
      ..moveTo(-2, -13)
      ..lineTo(8, -28 + finLift)
      ..lineTo(17, -13)
      ..close();
    canvas.drawPath(fin, Paint()..color = dark);
    if (shape == _CyberFishShape.prism) {
      for (final x in [-12.0, 4.0, 18.0]) {
        canvas.drawLine(
          Offset(x, -13),
          Offset(x + 8, 13),
          Paint()
            ..color = LostChrome.pearl.withValues(alpha: .55)
            ..strokeWidth = 1.3,
        );
      }
    } else if (shape == _CyberFishShape.byte) {
      canvas.drawLine(
        const Offset(-10, -7),
        const Offset(22, -7),
        Paint()
          ..color = LostChrome.pearl.withValues(alpha: .62)
          ..strokeWidth = 1.2,
      );
      canvas.drawLine(
        const Offset(-10, 1),
        const Offset(24, 1),
        Paint()
          ..color = LostChrome.pearl.withValues(alpha: .45)
          ..strokeWidth = 1.2,
      );
    }
    canvas.drawCircle(
        const Offset(-20, -5), 5, Paint()..color = const Color(0xff062766));
    canvas.drawCircle(
        const Offset(-20, -5), 2.1, Paint()..color = LostChrome.lime);
  }

  @override
  bool shouldRepaint(covariant _AeroLagoonPainter oldDelegate) =>
      fish != oldDelegate.fish;
}

class _AudioScopePainter extends CustomPainter {
  const _AudioScopePainter({
    required this.inputDb,
    required this.outputDb,
    required this.clipped,
  });

  final double inputDb;
  final double outputDb;
  final bool clipped;

  double _level(double db) => ((db.clamp(-60, 0) + 60) / 60).toDouble();

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = LostChrome.ice.withValues(alpha: .13)
      ..strokeWidth = 1;
    for (var column = 1; column < 6; column++) {
      final x = size.width * column / 6;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    for (var row = 1; row < 3; row++) {
      final y = size.height * row / 3;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    _wave(
      canvas,
      size,
      _level(inputDb),
      size.height * .35,
      LostChrome.electric,
      2.2,
    );
    _wave(
      canvas,
      size,
      _level(outputDb),
      size.height * .7,
      clipped ? const Color(0xffff6c8c) : LostChrome.lime,
      3.4,
    );
  }

  void _wave(
    Canvas canvas,
    Size size,
    double level,
    double center,
    Color color,
    double cycles,
  ) {
    final path = Path();
    final amplitude = math.max(2.0, size.height * (.04 + level * .2));
    for (var x = 0.0; x <= size.width; x += 2) {
      final progress = x / size.width;
      final envelope = .55 + .45 * math.sin(progress * math.pi);
      final y = center +
          math.sin(progress * math.pi * cycles * 2) * amplitude * envelope;
      if (x == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    final glow = Paint()
      ..color = color.withValues(alpha: .32)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawPath(path, glow);
    final line = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    canvas.drawPath(path, line);
  }

  @override
  bool shouldRepaint(covariant _AudioScopePainter oldDelegate) =>
      inputDb != oldDelegate.inputDb ||
      outputDb != oldDelegate.outputDb ||
      clipped != oldDelegate.clipped;
}

class _MeterStrip extends StatelessWidget {
  const _MeterStrip({required this.snapshot});

  final MeterSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _LevelMeter(label: 'IN', db: snapshot.inputDb)),
        const SizedBox(width: 10),
        Expanded(
          child: _LevelMeter(
            label: 'OUT',
            db: snapshot.outputDb,
            clipped: snapshot.clipped,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          'CPU ${snapshot.cpuPercent.round()}%\nXRUN ${snapshot.xruns}',
          textAlign: TextAlign.right,
          style: Theme.of(context).textTheme.labelSmall,
        ),
      ],
    );
  }
}

class _LevelMeter extends StatelessWidget {
  const _LevelMeter({
    required this.label,
    required this.db,
    this.clipped = false,
  });

  final String label;
  final double db;
  final bool clipped;

  @override
  Widget build(BuildContext context) {
    final level = ((db.clamp(-60, 0) + 60) / 60).toDouble();
    final color = clipped
        ? Theme.of(context).colorScheme.error
        : level > 0.85
            ? LostChrome.lime
            : LostChrome.electric;
    return Row(
      children: [
        Text(label, style: Theme.of(context).textTheme.labelSmall),
        const SizedBox(width: 5),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: level,
              minHeight: 8,
              color: color,
              backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
            ),
          ),
        ),
      ],
    );
  }
}

class MeterSnapshot {
  const MeterSnapshot({
    required this.inputDb,
    required this.outputDb,
    required this.clipped,
    required this.cpuPercent,
    required this.xruns,
    required this.tunerHz,
    required this.tunerConfidence,
  });

  const MeterSnapshot.silent()
      : inputDb = -120,
        outputDb = -120,
        clipped = false,
        cpuPercent = 0,
        xruns = 0,
        tunerHz = 0,
        tunerConfidence = 0;

  factory MeterSnapshot.fromJson(Map<String, dynamic> json) => MeterSnapshot(
        inputDb: (json['input_db'] as num?)?.toDouble() ?? -120,
        outputDb: (json['output_db'] as num?)?.toDouble() ?? -120,
        clipped: json['clipped'] as bool? ?? false,
        cpuPercent: (json['cpu_percent'] as num?)?.toDouble() ?? 0,
        xruns: json['xruns'] as int? ?? 0,
        tunerHz: (json['tuner_hz'] as num?)?.toDouble() ?? 0,
        tunerConfidence: (json['tuner_confidence'] as num?)?.toDouble() ?? 0,
      );

  final double inputDb;
  final double outputDb;
  final bool clipped;
  final double cpuPercent;
  final int xruns;
  final double tunerHz;
  final double tunerConfidence;
}

class EngineSnapshot {
  const EngineSnapshot({
    required this.connected,
    required this.bypassed,
    required this.preBypassed,
    required this.ampBypassed,
    required this.preset,
    required this.presetId,
    required this.presetDirty,
    required this.preModel,
    required this.model,
    required this.pedalDriveDb,
    required this.pedalMix,
    required this.pedalLevelDb,
    required this.ampBassDb,
    required this.ampMidDb,
    required this.ampTrebleDb,
    required this.ampVolumeDb,
    required this.gateEnabled,
    required this.gateThresholdDb,
    required this.compressorEnabled,
    required this.compressorThresholdDb,
    required this.compressorRatio,
    required this.eqEnabled,
    required this.eqVisible,
    required this.eqLowDb,
    required this.eqMidDb,
    required this.eqHighDb,
    required this.chorusEnabled,
    required this.chorusVisible,
    required this.chorusRateHz,
    required this.chorusDepth,
    required this.chorusMix,
    required this.delayEnabled,
    required this.delayVisible,
    required this.delayTimeMs,
    required this.delayFeedback,
    required this.delayMix,
    required this.reverbEnabled,
    required this.reverbVisible,
    required this.reverbDecaySeconds,
    required this.reverbMix,
    required this.looperMode,
    required this.looperVisible,
    required this.looperBpm,
    required this.looperBars,
    required this.tunerEnabled,
    required this.sampleRate,
    required this.bufferFrames,
  });

  const EngineSnapshot.disconnected()
      : connected = false,
        bypassed = true,
        preBypassed = true,
        ampBypassed = true,
        preset = 'Waiting for engine',
        presetId = null,
        presetDirty = false,
        preModel = null,
        model = null,
        pedalDriveDb = 0,
        pedalMix = 1,
        pedalLevelDb = 0,
        ampBassDb = 0,
        ampMidDb = 0,
        ampTrebleDb = 0,
        ampVolumeDb = 0,
        gateEnabled = false,
        gateThresholdDb = -55,
        compressorEnabled = false,
        compressorThresholdDb = -18,
        compressorRatio = 3,
        eqEnabled = false,
        eqVisible = false,
        eqLowDb = 0,
        eqMidDb = 0,
        eqHighDb = 0,
        chorusEnabled = false,
        chorusVisible = false,
        chorusRateHz = .8,
        chorusDepth = .5,
        chorusMix = .35,
        delayEnabled = false,
        delayVisible = false,
        delayTimeMs = 360,
        delayFeedback = .35,
        delayMix = .25,
        reverbEnabled = false,
        reverbVisible = false,
        reverbDecaySeconds = 2.5,
        reverbMix = .25,
        looperMode = 'stopped',
        looperVisible = false,
        looperBpm = 100,
        looperBars = 4,
        tunerEnabled = false,
        sampleRate = 48000,
        bufferFrames = 64;

  factory EngineSnapshot.fromJson(Map<String, dynamic> json) {
    return EngineSnapshot(
      connected: true,
      bypassed: json['bypassed'] as bool? ?? true,
      preBypassed: json['pre_bypassed'] as bool? ?? false,
      ampBypassed: json['amp_bypassed'] as bool? ?? false,
      preset: json['preset'] as String? ?? 'Default',
      presetId: json['preset_id'] as String?,
      presetDirty: json['preset_dirty'] as bool? ?? false,
      preModel: json['pre_model'] as String?,
      model: json['model'] as String?,
      pedalDriveDb: (json['pedal_drive_db'] as num?)?.toDouble() ?? 0,
      pedalMix: (json['pedal_mix'] as num?)?.toDouble() ?? 1,
      pedalLevelDb: (json['pedal_level_db'] as num?)?.toDouble() ?? 0,
      ampBassDb: (json['amp_bass_db'] as num?)?.toDouble() ?? 0,
      ampMidDb: (json['amp_mid_db'] as num?)?.toDouble() ?? 0,
      ampTrebleDb: (json['amp_treble_db'] as num?)?.toDouble() ?? 0,
      ampVolumeDb: (json['amp_volume_db'] as num?)?.toDouble() ?? 0,
      gateEnabled: json['gate_enabled'] as bool? ?? false,
      gateThresholdDb: (json['gate_threshold_db'] as num?)?.toDouble() ?? -55,
      compressorEnabled: json['compressor_enabled'] as bool? ?? false,
      compressorThresholdDb:
          (json['compressor_threshold_db'] as num?)?.toDouble() ?? -18,
      compressorRatio: (json['compressor_ratio'] as num?)?.toDouble() ?? 3,
      eqEnabled: json['eq_enabled'] as bool? ?? false,
      eqVisible: json['eq_visible'] as bool? ?? false,
      eqLowDb: (json['eq_low_db'] as num?)?.toDouble() ?? 0,
      eqMidDb: (json['eq_mid_db'] as num?)?.toDouble() ?? 0,
      eqHighDb: (json['eq_high_db'] as num?)?.toDouble() ?? 0,
      chorusEnabled: json['chorus_enabled'] as bool? ?? false,
      chorusVisible: json['chorus_visible'] as bool? ?? false,
      chorusRateHz: (json['chorus_rate_hz'] as num?)?.toDouble() ?? .8,
      chorusDepth: (json['chorus_depth'] as num?)?.toDouble() ?? .5,
      chorusMix: (json['chorus_mix'] as num?)?.toDouble() ?? .35,
      delayEnabled: json['delay_enabled'] as bool? ?? false,
      delayVisible: json['delay_visible'] as bool? ?? false,
      delayTimeMs: (json['delay_time_ms'] as num?)?.toDouble() ?? 360,
      delayFeedback: (json['delay_feedback'] as num?)?.toDouble() ?? .35,
      delayMix: (json['delay_mix'] as num?)?.toDouble() ?? .25,
      reverbEnabled: json['reverb_enabled'] as bool? ?? false,
      reverbVisible: json['reverb_visible'] as bool? ?? false,
      reverbDecaySeconds:
          (json['reverb_decay_seconds'] as num?)?.toDouble() ?? 2.5,
      reverbMix: (json['reverb_mix'] as num?)?.toDouble() ?? .25,
      looperMode: json['looper_mode'] as String? ?? 'stopped',
      looperVisible: json['looper_visible'] as bool? ?? false,
      looperBpm: json['looper_bpm'] as int? ?? 100,
      looperBars: json['looper_bars'] as int? ?? 4,
      tunerEnabled: json['tuner_enabled'] as bool? ?? false,
      sampleRate: json['sample_rate'] as int? ?? 48000,
      bufferFrames: json['buffer_frames'] as int? ?? 64,
    );
  }

  final bool connected;
  final bool bypassed;
  final bool preBypassed;
  final bool ampBypassed;
  final String preset;
  final String? presetId;
  final bool presetDirty;
  final String? preModel;
  final String? model;
  final double pedalDriveDb;
  final double pedalMix;
  final double pedalLevelDb;
  final double ampBassDb;
  final double ampMidDb;
  final double ampTrebleDb;
  final double ampVolumeDb;
  final bool gateEnabled;
  final double gateThresholdDb;
  final bool compressorEnabled;
  final double compressorThresholdDb;
  final double compressorRatio;
  final bool eqEnabled;
  final bool eqVisible;
  final double eqLowDb;
  final double eqMidDb;
  final double eqHighDb;
  final bool chorusEnabled;
  final bool chorusVisible;
  final double chorusRateHz;
  final double chorusDepth;
  final double chorusMix;
  final bool delayEnabled;
  final bool delayVisible;
  final double delayTimeMs;
  final double delayFeedback;
  final double delayMix;
  final bool reverbEnabled;
  final bool reverbVisible;
  final double reverbDecaySeconds;
  final double reverbMix;
  final String looperMode;
  final bool looperVisible;
  final int looperBpm;
  final int looperBars;
  final bool tunerEnabled;
  final int sampleRate;
  final int bufferFrames;

  String get presetTitle => presetDirty ? '$preset *' : preset;

  bool effectEnabled(EffectKind effect) => switch (effect) {
        EffectKind.gate => gateEnabled,
        EffectKind.compressor => compressorEnabled,
        EffectKind.eq => eqEnabled,
        EffectKind.chorus => chorusEnabled,
        EffectKind.delay => delayEnabled,
        EffectKind.reverb => reverbEnabled,
      };

  bool pedalVisible(OptionalPedal pedal) => switch (pedal) {
        OptionalPedal.eq => eqVisible,
        OptionalPedal.chorus => chorusVisible,
        OptionalPedal.delay => delayVisible,
        OptionalPedal.reverb => reverbVisible,
        OptionalPedal.looper => looperVisible,
      };

  Map<String, double> effectControls(EffectKind effect) => switch (effect) {
        EffectKind.gate => {'gate_threshold_db': gateThresholdDb},
        EffectKind.compressor => {
            'compressor_threshold_db': compressorThresholdDb,
            'compressor_ratio': compressorRatio,
          },
        EffectKind.eq => {
            'eq_low_db': eqLowDb,
            'eq_mid_db': eqMidDb,
            'eq_high_db': eqHighDb,
          },
        EffectKind.chorus => {
            'chorus_rate_hz': chorusRateHz,
            'chorus_depth': chorusDepth,
            'chorus_mix': chorusMix,
          },
        EffectKind.delay => {
            'delay_time_ms': delayTimeMs,
            'delay_feedback': delayFeedback,
            'delay_mix': delayMix,
          },
        EffectKind.reverb => {
            'reverb_decay_seconds': reverbDecaySeconds,
            'reverb_mix': reverbMix,
          },
      };

  String get modelName {
    final pre = preModel?.split('/').last;
    final amp = model?.split('/').last;
    if (pre != null && amp != null) return '$pre → $amp';
    if (pre != null) return '$pre → clean output';
    return amp ?? 'No NAM model loaded';
  }
}

enum ModelSlot { pre, amp }

class PresetSummary {
  const PresetSummary({
    required this.id,
    required this.name,
    required this.preModel,
    required this.model,
  });

  factory PresetSummary.fromJson(Map<String, dynamic> json) => PresetSummary(
        id: json['id'] as String,
        name: json['name'] as String,
        preModel: json['pre_model'] as String?,
        model: json['model'] as String?,
      );

  final String id;
  final String name;
  final String? preModel;
  final String? model;

  String get modelSummary {
    final pedal = preModel?.split('/').last;
    final amp = model?.split('/').last;
    if (pedal != null && amp != null) return '$pedal → $amp';
    return pedal ?? amp ?? 'Clean rig';
  }
}

class PreviewAudio {
  const PreviewAudio({required this.path, required this.durationSeconds});

  factory PreviewAudio.fromJson(Map<String, dynamic> json) => PreviewAudio(
        path: json['path'] as String,
        durationSeconds: (json['duration_seconds'] as num).toDouble(),
      );

  final String path;
  final double durationSeconds;
}

class RiffCapture {
  const RiffCapture({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.durationSeconds,
    required this.cleanPath,
    required this.processedPath,
    required this.preset,
  });

  factory RiffCapture.fromJson(Map<String, dynamic> json) => RiffCapture(
        id: json['id'] as String,
        name: json['name'] as String,
        createdAt: DateTime.fromMillisecondsSinceEpoch(
            json['created_at_ms'] as int? ?? 0),
        durationSeconds: (json['duration_seconds'] as num?)?.toDouble() ?? 0,
        cleanPath: json['clean_path'] as String,
        processedPath: json['processed_path'] as String,
        preset: json['preset'] as String? ?? 'Default',
      );

  final String id;
  final String name;
  final DateTime createdAt;
  final double durationSeconds;
  final String cleanPath;
  final String processedPath;
  final String preset;
}

class SystemAudioOutput {
  const SystemAudioOutput({
    required this.id,
    required this.name,
    required this.isDefault,
  });

  final int id;
  final String name;
  final bool isDefault;

  bool get isBluetooth =>
      name.toLowerCase().contains('bluetooth') ||
      name.toLowerCase().contains('buds');
}

class SystemAudioService {
  static Future<List<SystemAudioOutput>> listOutputs() async {
    final result = await Process.run('wpctl', ['status']);
    if (result.exitCode != 0) {
      throw const EngineException('Could not read system audio outputs');
    }
    return parseOutputs(result.stdout as String);
  }

  static List<SystemAudioOutput> parseOutputs(String status) {
    final outputs = <SystemAudioOutput>[];
    var inAudioSinks = false;
    final linePattern = RegExp(r'^\s*│\s+(\*)?\s*(\d+)\.\s+(.+?)\s+\[vol:');
    for (final line in const LineSplitter().convert(status)) {
      if (line.contains('Sinks:') && !inAudioSinks && outputs.isEmpty) {
        inAudioSinks = true;
        continue;
      }
      if (inAudioSinks && line.contains('Sources:')) break;
      if (!inAudioSinks) continue;
      final match = linePattern.firstMatch(line);
      if (match == null) continue;
      outputs.add(SystemAudioOutput(
        id: int.parse(match.group(2)!),
        name: match.group(3)!.trim(),
        isDefault: match.group(1) != null,
      ));
    }
    return outputs;
  }

  static Future<void> select(int id) async {
    final selected = await Process.run('wpctl', ['set-default', '$id']);
    if (selected.exitCode != 0) {
      throw const EngineException('The selected output could not be activated');
    }
    await Process.run('wpctl', ['set-mute', '$id', '0']);
  }
}

enum PreviewSource { synthetic, builtIn, file, pickFile }

class PreviewChoice {
  const PreviewChoice(this.source, this.processed, {this.path});

  final PreviewSource source;
  final bool processed;
  final String? path;
}

class ControlClient {
  ControlClient({String? socketPath})
      : socketPath = socketPath ??
            Platform.environment['PEDAL_CONTROL_SOCKET'] ??
            '/tmp/pedal-control.sock';

  final String socketPath;
  final StreamController<EngineSnapshot> _snapshots =
      StreamController.broadcast();
  final StreamController<MeterSnapshot> _meters = StreamController.broadcast();
  Socket? _socket;
  StreamSubscription<String>? _lines;
  Timer? _meterTimer;
  int _requestId = 0;
  final Map<String, Completer<Map<String, dynamic>>> _pending = {};

  Stream<EngineSnapshot> get snapshots => _snapshots.stream;
  Stream<MeterSnapshot> get meters => _meters.stream;

  Future<void> connect() async {
    _meterTimer?.cancel();
    await _lines?.cancel();
    _socket?.destroy();
    try {
      final address =
          InternetAddress(socketPath, type: InternetAddressType.unix);
      _socket =
          await Socket.connect(address, 0, timeout: const Duration(seconds: 2));
      _lines = _socket!
          .cast<List<int>>()
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(_handleLine,
              onDone: _disconnected, onError: (_) => _disconnected());
      _send('get_state', const {});
      _send('get_meters', const {});
      _meterTimer = Timer.periodic(
        const Duration(milliseconds: 100),
        (timer) {
          _send('get_meters', const {});
          // The audio thread can advance a count-in into recording or playing
          // between touches, so refresh authoritative state at a modest rate.
          if (timer.tick % 5 == 0) _send('get_state', const {});
        },
      );
    } on SocketException {
      _disconnected();
    }
  }

  void setBypass(bool bypassed) => _send('set_bypass', {'bypassed': bypassed});

  Future<void> setSlotBypass(ModelSlot slot, bool bypassed) => _request(
        'set_slot_bypass',
        {'slot': slot.name, 'bypassed': bypassed},
        timeoutMessage: 'Bypass change timed out',
      );

  Future<void> setEffectBypass(EffectKind effect, bool bypassed) => _request(
        'set_effect_bypass',
        {'effect': effect.wireName, 'bypassed': bypassed},
        timeoutMessage: 'Effect bypass change timed out',
      );

  Future<void> setPedalVisible(OptionalPedal pedal, bool visible) => _request(
        'set_pedal_visible',
        {'pedal': pedal.name, 'visible': visible},
        timeoutMessage: 'Adding pedal timed out',
      );

  Future<void> looperAction(String action, {int? bpm, int? bars}) => _request(
        'looper_action',
        {
          'action': action,
          if (bpm != null) 'bpm': bpm,
          if (bars != null) 'bars': bars
        },
        timeoutMessage: 'Looper command timed out',
      );

  Future<void> setTunerEnabled(bool enabled) => _request(
        'set_tuner_enabled',
        {'enabled': enabled},
        timeoutMessage: 'Tuner change timed out',
      );

  Future<void> setMetronome(bool enabled, int bpm) => _request(
        'set_metronome',
        {'enabled': enabled, 'bpm': bpm},
        timeoutMessage: 'Metronome change timed out',
      );

  Future<List<RiffCapture>> listRiffs() async {
    final response = await _requestRaw(
      'list_riffs',
      const {},
      timeoutMessage: 'Riff Vault list timed out',
    );
    final payload = response['payload'] as Map<String, dynamic>;
    return (payload['riffs'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(RiffCapture.fromJson)
        .toList(growable: false);
  }

  Future<RiffCapture> saveRiff(String name) async {
    final response = await _requestRaw(
      'save_riff',
      {'name': name},
      timeout: const Duration(seconds: 15),
      timeoutMessage: 'Saving the Riff Vault take timed out',
    );
    return RiffCapture.fromJson(response['payload'] as Map<String, dynamic>);
  }

  Future<void> clearModel(ModelSlot slot) => _request(
        'clear_model',
        {'slot': slot.name},
        timeoutMessage: 'Clearing the model timed out',
      );

  Future<void> setControl(String control, double value) => _request(
        'set_control',
        {'control': control, 'value': value},
        timeoutMessage: 'Control change timed out',
      );

  Future<void> selectModel(CatalogModel model, ModelSlot slot) => _request(
        'select_model',
        {
          'path': model.path,
          'preset': model.name,
          'slot': slot.name,
        },
        timeout: const Duration(seconds: 15),
        timeoutMessage: 'Model preparation timed out',
      );

  Future<PreviewAudio> renderPreview({
    PreviewSource source = PreviewSource.synthetic,
    bool processed = true,
    String? path,
  }) async {
    final sourceName = switch (source) {
      PreviewSource.builtIn => 'built_in',
      PreviewSource.file => 'file',
      _ => 'synthetic',
    };
    final response = await _requestRaw(
      'render_preview',
      {
        'source': sourceName,
        'processed': processed,
        if (path != null) 'path': path,
      },
      timeout: const Duration(minutes: 2),
      timeoutMessage: 'Audio preview rendering timed out',
    );
    return PreviewAudio.fromJson(response['payload'] as Map<String, dynamic>);
  }

  Future<List<PresetSummary>> listPresets() async {
    final response = await _requestRaw(
      'list_presets',
      const {},
      timeoutMessage: 'Preset list timed out',
    );
    final payload = response['payload'] as Map<String, dynamic>;
    final presets = payload['presets'] as List<dynamic>? ?? const [];
    return presets
        .cast<Map<String, dynamic>>()
        .map(PresetSummary.fromJson)
        .toList(growable: false);
  }

  Future<void> savePreset(String name) => _request(
        'save_preset',
        {'name': name},
        timeoutMessage: 'Saving the preset timed out',
      );

  Future<void> newPreset() => _request(
        'new_preset',
        const {},
        timeoutMessage: 'New preset request timed out',
      );

  Future<void> loadPreset(String id) => _request(
        'load_preset',
        {'id': id},
        timeout: const Duration(seconds: 15),
        timeoutMessage: 'Loading the preset timed out',
      );

  Future<void> renamePreset(String id, String name) => _request(
        'rename_preset',
        {'id': id, 'name': name},
        timeoutMessage: 'Renaming the preset timed out',
      );

  Future<void> deletePreset(String id) => _request(
        'delete_preset',
        {'id': id},
        timeoutMessage: 'Deleting the preset timed out',
      );

  Future<void> _request(
    String type,
    Map<String, Object?> payload, {
    Duration timeout = const Duration(seconds: 5),
    required String timeoutMessage,
  }) async {
    await _requestRaw(
      type,
      payload,
      timeout: timeout,
      timeoutMessage: timeoutMessage,
    );
  }

  Future<Map<String, dynamic>> _requestRaw(
    String type,
    Map<String, Object?> payload, {
    Duration timeout = const Duration(seconds: 5),
    required String timeoutMessage,
  }) {
    final socket = _socket;
    if (socket == null) {
      return Future.error(
          const EngineException('Audio engine is not connected'));
    }
    _requestId += 1;
    final id = 'ui-$_requestId';
    final completer = Completer<Map<String, dynamic>>();
    _pending[id] = completer;
    socket.writeln(jsonEncode({
      'api': 1,
      'id': id,
      'type': type,
      'payload': payload,
    }));
    return completer.future.timeout(
      timeout,
      onTimeout: () {
        _pending.remove(id);
        throw EngineException(timeoutMessage);
      },
    );
  }

  void _send(String type, Map<String, Object?> payload) {
    final socket = _socket;
    if (socket == null) return;
    _requestId += 1;
    socket.writeln(jsonEncode(
        {'api': 1, 'id': 'ui-$_requestId', 'type': type, 'payload': payload}));
  }

  void _handleLine(String line) {
    final message = jsonDecode(line) as Map<String, dynamic>;
    final id = message['id'] as String?;
    final pending = id == null ? null : _pending.remove(id);
    if (message['type'] == 'state') {
      _snapshots.add(
          EngineSnapshot.fromJson(message['payload'] as Map<String, dynamic>));
      pending?.complete(message);
    } else if (message['type'] == 'presets') {
      pending?.complete(message);
    } else if (message['type'] == 'preview') {
      pending?.complete(message);
    } else if (message['type'] == 'riff' || message['type'] == 'riffs') {
      pending?.complete(message);
    } else if (message['type'] == 'meters') {
      _meters.add(
          MeterSnapshot.fromJson(message['payload'] as Map<String, dynamic>));
    } else if (message['type'] == 'error') {
      final payload = message['payload'] as Map<String, dynamic>;
      pending?.completeError(EngineException(
          payload['message'] as String? ?? 'Engine request failed'));
    }
  }

  void _disconnected() {
    _meterTimer?.cancel();
    _meterTimer = null;
    _socket = null;
    for (final pending in _pending.values) {
      pending.completeError(const EngineException('Audio engine disconnected'));
    }
    _pending.clear();
    if (!_snapshots.isClosed) {
      _snapshots.add(const EngineSnapshot.disconnected());
    }
    if (!_meters.isClosed) {
      _meters.add(const MeterSnapshot.silent());
    }
  }

  Future<void> dispose() async {
    await _lines?.cancel();
    _meterTimer?.cancel();
    _socket?.destroy();
    await _snapshots.close();
    await _meters.close();
  }
}

class EngineException implements Exception {
  const EngineException(this.message);

  final String message;

  @override
  String toString() => message;
}

class CatalogModel {
  const CatalogModel({
    required this.name,
    required this.path,
    required this.sizeBytes,
    required this.source,
    required this.favorite,
  });

  factory CatalogModel.fromJson(Map<String, dynamic> json) => CatalogModel(
        name: json['name'] as String,
        path: json['path'] as String,
        sizeBytes: json['size_bytes'] as int,
        source: json['source'] as String? ?? 'local',
        favorite: json['favorite'] as bool? ?? false,
      );

  final String name;
  final String path;
  final int sizeBytes;
  final String source;
  final bool favorite;

  String get sourceLabel =>
      source.startsWith('tone3000:') ? 'TONE3000' : 'LOCAL';

  String get sizeLabel {
    if (sizeBytes >= 1024 * 1024) {
      return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(sizeBytes / 1024).toStringAsFixed(0)} KB';
  }
}

class Tone3000Status {
  const Tone3000Status({
    required this.available,
    required this.connected,
    this.authPending = false,
    this.selectedToneId,
  });

  factory Tone3000Status.fromJson(Map<String, dynamic> json) => Tone3000Status(
        available: json['available'] as bool? ?? false,
        connected: json['connected'] as bool? ?? false,
        authPending: json['auth_pending'] as bool? ?? false,
        selectedToneId: json['selected_tone_id'] as String?,
      );

  final bool available;
  final bool connected;
  final bool authPending;
  final String? selectedToneId;
}

class ToneMakerStatus {
  const ToneMakerStatus({
    required this.available,
    required this.tone3000Connected,
    this.toneMemoryAvailable = false,
  });

  factory ToneMakerStatus.fromJson(Map<String, dynamic> json) =>
      ToneMakerStatus(
        available: json['available'] as bool? ?? false,
        tone3000Connected: json['tone3000_connected'] as bool? ?? false,
        toneMemoryAvailable: json['tone_memory_available'] as bool? ?? false,
      );

  final bool available;
  final bool tone3000Connected;
  final bool toneMemoryAvailable;
}

class BackingTrackStatus {
  const BackingTrackStatus({required this.available});

  factory BackingTrackStatus.fromJson(Map<String, dynamic> json) =>
      BackingTrackStatus(available: json['available'] as bool? ?? false);

  final bool available;
}

class BackingTrack {
  const BackingTrack({
    required this.id,
    required this.riffId,
    required this.riffName,
    required this.style,
    required this.createdAt,
    required this.status,
    required this.durationSeconds,
    required this.strength,
    this.path,
    this.error,
  });

  factory BackingTrack.fromJson(Map<String, dynamic> json) => BackingTrack(
        id: json['id'] as String,
        riffId: json['riff_id'] as String,
        riffName: json['riff_name'] as String? ?? 'Untitled Riff',
        style: json['style'] as String? ?? 'Backing track',
        createdAt: DateTime.fromMillisecondsSinceEpoch(
            json['created_at_ms'] as int? ?? 0),
        status: json['status'] as String? ?? 'failed',
        durationSeconds: json['duration_seconds'] as int? ?? 20,
        strength: (json['strength'] as num?)?.toDouble() ?? .65,
        path: json['path'] as String?,
        error: json['error'] as String?,
      );

  final String id;
  final String riffId;
  final String riffName;
  final String style;
  final DateTime createdAt;
  final String status;
  final int durationSeconds;
  final double strength;
  final String? path;
  final String? error;
}

class AiTonePlan {
  const AiTonePlan({
    required this.summary,
    required this.pedalQuery,
    required this.ampQuery,
    required this.controls,
    required this.effects,
  });

  factory AiTonePlan.fromJson(Map<String, dynamic> json) => AiTonePlan(
        summary: json['summary'] as String,
        pedalQuery: json['pedal_query'] as String,
        ampQuery: json['amp_query'] as String,
        controls: (json['controls'] as Map<String, dynamic>).map(
          (key, value) => MapEntry(key, (value as num).toDouble()),
        ),
        effects: (json['effects'] as Map<String, dynamic>).map(
          (key, value) => MapEntry(key, value as bool),
        ),
      );

  final String summary;
  final String pedalQuery;
  final String ampQuery;
  final Map<String, double> controls;
  final Map<String, bool> effects;
}

class AiToneRecommendation {
  const AiToneRecommendation({
    required this.id,
    required this.plan,
    required this.rigs,
    required this.rankingProvider,
    this.rankingNote,
  });

  factory AiToneRecommendation.fromJson(Map<String, dynamic> json) =>
      AiToneRecommendation(
        id: json['recommendation_id'] as String,
        plan: AiTonePlan.fromJson(json['plan'] as Map<String, dynamic>),
        rigs: (json['rigs'] as List<dynamic>? ?? const [])
            .cast<Map<String, dynamic>>()
            .map(AiToneRig.fromJson)
            .toList(growable: false),
        rankingProvider: json['ranking_provider'] as String? ?? 'openai',
        rankingNote: json['ranking_note'] as String?,
      );

  final String id;
  final AiTonePlan plan;
  final List<AiToneRig> rigs;
  final String rankingProvider;
  final String? rankingNote;
}

class AiToneRig {
  const AiToneRig({
    required this.label,
    required this.rationale,
    required this.pedal,
    required this.amp,
    this.rankingConfidence,
    this.rankingScore,
  });

  factory AiToneRig.fromJson(Map<String, dynamic> json) {
    final pedal = json['pedal'];
    return AiToneRig(
      label: json['label'] as String,
      rationale: json['rationale'] as String,
      pedal: pedal is Map<String, dynamic> ? RemoteTone.fromJson(pedal) : null,
      amp: RemoteTone.fromJson(json['amp'] as Map<String, dynamic>),
      rankingConfidence: (json['ranking_confidence'] as num?)?.toDouble(),
      rankingScore: (json['ranking_score'] as num?)?.toDouble(),
    );
  }

  final String label;
  final String rationale;
  final RemoteTone? pedal;
  final RemoteTone amp;
  final double? rankingConfidence;
  final double? rankingScore;

  String get confidenceLabel {
    final confidence = rankingConfidence ?? 0;
    if (confidence >= .8) return 'HIGH';
    if (confidence >= .55) return 'MEDIUM';
    return 'LOW';
  }
}

class AiToneApplication {
  const AiToneApplication({
    required this.summary,
    required this.preModel,
    required this.ampModel,
    required this.controls,
    required this.effects,
    required this.memoryCandidate,
  });

  factory AiToneApplication.fromJson(Map<String, dynamic> json) {
    final preModel = json['pre_model'];
    return AiToneApplication(
      summary: json['summary'] as String,
      preModel: preModel is Map<String, dynamic>
          ? CatalogModel.fromJson(preModel)
          : null,
      ampModel:
          CatalogModel.fromJson(json['amp_model'] as Map<String, dynamic>),
      controls: (json['controls'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(key, (value as num).toDouble()),
      ),
      effects: (json['effects'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(key, value as bool),
      ),
      memoryCandidate: Map<String, dynamic>.from(
          json['tone_memory'] as Map<String, dynamic>),
    );
  }

  final String summary;
  final CatalogModel? preModel;
  final CatalogModel ampModel;
  final Map<String, double> controls;
  final Map<String, bool> effects;
  final Map<String, dynamic> memoryCandidate;

  String get memoryQuery => memoryCandidate['query'] as String? ?? summary;
}

class RemoteTone {
  const RemoteTone({
    required this.id,
    required this.name,
    required this.author,
    required this.gear,
  });

  factory RemoteTone.fromJson(Map<String, dynamic> json) => RemoteTone(
        id: json['id'] as String,
        name: json['name'] as String,
        author: json['author'] as String? ?? 'TONE3000',
        gear: json['gear'] as String? ?? 'NAM',
      );

  final String id;
  final String name;
  final String author;
  final String gear;
}

class RemoteModel {
  const RemoteModel(
      {required this.id, required this.toneId, required this.name});

  factory RemoteModel.fromJson(Map<String, dynamic> json) => RemoteModel(
        id: json['id'] as String,
        toneId: json['tone_id'] as String,
        name: json['name'] as String,
      );

  final String id;
  final String toneId;
  final String name;
}

class SelectedTone {
  const SelectedTone({required this.tone, required this.models});

  factory SelectedTone.fromJson(Map<String, dynamic> json) => SelectedTone(
        tone: RemoteTone.fromJson(json['tone'] as Map<String, dynamic>),
        models: (json['models'] as List<dynamic>? ?? const [])
            .cast<Map<String, dynamic>>()
            .map(RemoteModel.fromJson)
            .toList(growable: false),
      );

  final RemoteTone tone;
  final List<RemoteModel> models;
}

class CatalogClient {
  CatalogClient({String? socketPath})
      : socketPath = socketPath ??
            Platform.environment['PEDAL_CATALOG_SOCKET'] ??
            '/tmp/pedal-catalog.sock';

  final String socketPath;
  int _requestId = 0;

  Future<List<CatalogModel>> listModels() async {
    final response = await _request('list_models', const {});
    if (response['type'] == 'error') {
      final payload = response['payload'] as Map<String, dynamic>;
      throw CatalogException(
          payload['message'] as String? ?? 'Catalog request failed');
    }
    final payload = response['payload'] as Map<String, dynamic>;
    final models = payload['models'] as List<dynamic>? ?? const [];
    return models
        .cast<Map<String, dynamic>>()
        .map(CatalogModel.fromJson)
        .toList(growable: false);
  }

  Future<List<CatalogModel>> refreshAndList() async {
    final response = await _request('refresh_models', const {});
    if (response['type'] == 'error') {
      final payload = response['payload'] as Map<String, dynamic>;
      throw CatalogException(
          payload['message'] as String? ?? 'Catalog refresh failed');
    }
    return listModels();
  }

  Future<Tone3000Status> tone3000Status() async {
    final payload = await _payload('tone3000_status', const {});
    return Tone3000Status.fromJson(payload);
  }

  Future<ToneMakerStatus> toneMakerStatus() async {
    final payload = await _payload('tone_maker_status', const {});
    return ToneMakerStatus.fromJson(payload);
  }

  Future<BackingTrackStatus> backingTrackStatus() async {
    final payload = await _payload('backing_track_status', const {});
    return BackingTrackStatus.fromJson(payload);
  }

  Future<BackingTrack> createBackingTrack({
    required String riffId,
    required String style,
    required int durationSeconds,
  }) async {
    final payload = await _payload(
      'backing_track_create',
      {
        'riff_id': riffId,
        'style': style,
        'duration_seconds': durationSeconds,
        'strength': .65,
      },
      timeout: const Duration(seconds: 10),
    );
    return BackingTrack.fromJson(payload);
  }

  Future<List<BackingTrack>> listBackingTracks(String riffId) async {
    final payload = await _payload('backing_track_list', {'riff_id': riffId});
    return (payload['tracks'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(BackingTrack.fromJson)
        .toList(growable: false);
  }

  Future<AiToneRecommendation> requestAiTone(String prompt) async {
    final payload = await _payload(
      'tone_maker_recommend',
      {'prompt': prompt},
      timeout: const Duration(seconds: 45),
    );
    return AiToneRecommendation.fromJson(payload);
  }

  Future<AiToneApplication> applyAiTone(
    String recommendationId,
    int rigIndex,
  ) async {
    final payload = await _payload(
      'tone_maker_apply',
      {'recommendation_id': recommendationId, 'rig_index': rigIndex},
      timeout: const Duration(seconds: 75),
    );
    return AiToneApplication.fromJson(payload);
  }

  Future<void> saveToneMemory(
    Map<String, dynamic> candidate,
    String note,
  ) =>
      _payload(
        'tone_memory_save',
        {'candidate': candidate, 'note': note},
      );

  Future<String> beginTone3000Auth() async {
    final payload = await _payload('tone3000_begin_auth', const {});
    return payload['authorize_url'] as String;
  }

  Future<void> disconnectTone3000() async {
    await _payload('tone3000_disconnect', const {});
  }

  Future<SelectedTone> selectedTone3000() async {
    final payload = await _payload('tone3000_selected', const {});
    return SelectedTone.fromJson(payload);
  }

  Future<CatalogModel> downloadTone3000Model(
      String toneId, String modelId) async {
    final payload = await _payload(
      'tone3000_download',
      {'tone_id': toneId, 'model_id': modelId},
      timeout: const Duration(seconds: 60),
    );
    return CatalogModel.fromJson(payload['model'] as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> _payload(
    String type,
    Map<String, Object?> request, {
    Duration timeout = const Duration(seconds: 15),
  }) async {
    final response = await _request(type, request, timeout: timeout);
    final payload = response['payload'] as Map<String, dynamic>? ?? const {};
    if (response['type'] == 'error') {
      throw CatalogException(
          payload['message'] as String? ?? 'Catalog request failed');
    }
    return payload;
  }

  Future<Map<String, dynamic>> _request(
    String type,
    Map<String, Object?> payload, {
    Duration timeout = const Duration(seconds: 5),
  }) async {
    _requestId += 1;
    Socket? socket;
    try {
      socket = await Socket.connect(
        InternetAddress(socketPath, type: InternetAddressType.unix),
        0,
        timeout: const Duration(seconds: 2),
      );
      socket.writeln(jsonEncode({
        'api': 1,
        'id': 'catalog-$_requestId',
        'type': type,
        'payload': payload
      }));
      final line = await socket
          .cast<List<int>>()
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .first
          .timeout(timeout);
      return jsonDecode(line) as Map<String, dynamic>;
    } on SocketException {
      throw const CatalogException('Local catalog service is not running');
    } on TimeoutException {
      throw const CatalogException('Local catalog did not respond');
    } finally {
      socket?.destroy();
    }
  }
}

class CatalogException implements Exception {
  const CatalogException(this.message);

  final String message;

  @override
  String toString() => message;
}
