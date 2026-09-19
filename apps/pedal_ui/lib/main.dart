import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() => runApp(const PedalApp());

class PedalApp extends StatelessWidget {
  const PedalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xffed6a2c),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const RigScreen(),
    );
  }
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
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Text('PEDAL',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Tuner',
                    onPressed: _engine.connected ? _showTuner : null,
                    icon: Icon(
                      Icons.tune,
                      color:
                          _engine.tunerEnabled ? const Color(0xffb8ff79) : null,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _showTone3000,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    icon: const Icon(Icons.cloud_download_outlined, size: 18),
                    label: const Text('TONE3000'),
                  ),
                  TextButton.icon(
                    onPressed: _showAudioOutputs,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    icon: const Icon(Icons.volume_up_outlined, size: 18),
                    label: const Text('OUTPUT'),
                  ),
                  const SizedBox(width: 6),
                  Tooltip(
                    message: _engine.connected ? 'Engine online' : 'Connecting',
                    child: _StatusDot(connected: _engine.connected),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: _engine.connected ? _showPresets : null,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        _engine.presetTitle,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 30, fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.expand_more, size: 22),
                  ],
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
                child: Pedalboard(
                  snapshot: _engine,
                  onSlotOpen: _showSlotControls,
                  onSlotToggle: (slot, bypassed) => _toggleSlot(slot, bypassed),
                  onEffectOpen: _showEffectControls,
                  onEffectToggle: _toggleEffect,
                  onLooperOpen: _showLooperControls,
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 58,
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _showModelLibrary,
                        icon: const Icon(Icons.library_music),
                        label: const Text('TONES'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _engine.connected && !_previewBusy
                            ? _previewPlaying
                                ? _stopPreview
                                : _choosePreview
                            : null,
                        icon: _previewBusy
                            ? const SizedBox.square(
                                dimension: 16,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Icon(_previewPlaying
                                ? Icons.stop
                                : Icons.play_arrow),
                        label: Text(_previewPlaying ? 'STOP' : 'TEST AUDIO'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: FilledButton.tonal(
                        onPressed: _engine.connected
                            ? () => _client.setBypass(!_engine.bypassed)
                            : _client.connect,
                        style: FilledButton.styleFrom(
                          backgroundColor: _engine.bypassed
                              ? Theme.of(context).colorScheme.errorContainer
                              : Theme.of(context).colorScheme.primaryContainer,
                        ),
                        child: Text(
                          _engine.connected
                              ? (_engine.bypassed
                                  ? 'BYPASSED — ENGAGE'
                                  : 'ENGAGED — BYPASS')
                              : 'RECONNECT',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showModelLibrary() {
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
          onClear: () {
            Navigator.pop(sheetContext);
            _clearSlot(slot);
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

  void _showEffectControls(EffectKind effect) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => FractionallySizedBox(
        heightFactor: 0.82,
        child: EffectControlsSheet(
          effect: effect,
          snapshot: _engine,
          onChanged: _client.setControl,
        ),
      ),
    );
  }

  void _showLooperControls() {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => LooperControlsSheet(
        mode: _engine.looperMode,
        onAction: _client.looperAction,
      ),
    );
  }

  Future<void> _clearSlot(ModelSlot slot) async {
    final label = slot == ModelSlot.pre ? 'pedal' : 'amp';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Clear $label?'),
        content: Text('Remove the current $label model from this rig?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('CLEAR'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await _client.clearModel(slot);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$error')),
        );
      }
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
        EffectKind.gate => const Color(0xff6874c9),
        EffectKind.compressor => const Color(0xffdb5c8d),
        EffectKind.eq => const Color(0xff41a99a),
        EffectKind.chorus => const Color(0xff4267bf),
        EffectKind.delay => const Color(0xffd68742),
        EffectKind.reverb => const Color(0xff9567c7),
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
    super.key,
  });

  final EngineSnapshot snapshot;
  final ValueChanged<ModelSlot> onSlotOpen;
  final Future<void> Function(ModelSlot, bool) onSlotToggle;
  final ValueChanged<EffectKind> onEffectOpen;
  final Future<void> Function(EffectKind, bool) onEffectToggle;
  final VoidCallback onLooperOpen;

  @override
  Widget build(BuildContext context) {
    final postNamEffects = [
      EffectKind.eq,
      EffectKind.chorus,
      EffectKind.delay,
      EffectKind.reverb,
    ];
    _PedalTile effectTile(EffectKind effect) => _PedalTile(
          label: effect.label,
          sublabel: snapshot.effectEnabled(effect) ? 'ON' : 'BYPASS',
          icon: effect.icon,
          color: effect.color,
          active: snapshot.effectEnabled(effect),
          disabled: !snapshot.connected,
          onTap: () => onEffectOpen(effect),
          onFootswitch: () =>
              onEffectToggle(effect, snapshot.effectEnabled(effect)),
        );
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xff171330),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xff564c81), width: 2),
        boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 7)],
      ),
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(12, 7, 12, 2),
            child: Row(
              children: [
                Icon(Icons.cable, size: 14, color: Color(0xffa6ffdd)),
                SizedBox(width: 5),
                Text('SIGNAL PATH',
                    style: TextStyle(
                      color: Color(0xffa6ffdd),
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.4,
                      fontSize: 11,
                    )),
                Spacer(),
                Text('TAP PEDAL TO EDIT',
                    style: TextStyle(color: Color(0xff9a94bd), fontSize: 10)),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(9, 3, 9, 8),
              children: [
                effectTile(EffectKind.gate),
                const _SignalArrow(),
                effectTile(EffectKind.compressor),
                const _SignalArrow(),
                _PedalTile(
                  label: 'NAM',
                  sublabel: 'DRIVE',
                  icon: Icons.bolt,
                  color: const Color(0xffc15062),
                  active: snapshot.preModel != null && !snapshot.preBypassed,
                  disabled: !snapshot.connected,
                  onTap: () => onSlotOpen(ModelSlot.pre),
                  onFootswitch: () =>
                      onSlotToggle(ModelSlot.pre, !snapshot.preBypassed),
                ),
                const _SignalArrow(),
                _PedalTile(
                  label: 'NAM',
                  sublabel: 'AMP',
                  icon: Icons.speaker,
                  color: const Color(0xffd08a3c),
                  active: snapshot.model != null && !snapshot.ampBypassed,
                  disabled: !snapshot.connected,
                  onTap: () => onSlotOpen(ModelSlot.amp),
                  onFootswitch: () =>
                      onSlotToggle(ModelSlot.amp, !snapshot.ampBypassed),
                ),
                for (final effect in postNamEffects) ...[
                  const _SignalArrow(),
                  effectTile(effect),
                ],
                const _SignalArrow(),
                _PedalTile(
                  label: 'LOOPER',
                  sublabel: snapshot.looperMode.toUpperCase(),
                  icon: Icons.loop,
                  color: const Color(0xff49b36b),
                  active: snapshot.looperMode != 'stopped',
                  disabled: !snapshot.connected,
                  onTap: onLooperOpen,
                  onFootswitch: onLooperOpen,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SignalArrow extends StatelessWidget {
  const _SignalArrow();

  @override
  Widget build(BuildContext context) => const SizedBox(
        width: 18,
        child: Icon(Icons.chevron_right, size: 18, color: Color(0xff6d6592)),
      );
}

class _PedalTile extends StatelessWidget {
  const _PedalTile({
    required this.label,
    required this.sublabel,
    required this.icon,
    required this.color,
    required this.active,
    required this.disabled,
    required this.onTap,
    required this.onFootswitch,
  });

  final String label;
  final String sublabel;
  final IconData icon;
  final Color color;
  final bool active;
  final bool disabled;
  final VoidCallback onTap;
  final VoidCallback onFootswitch;

  @override
  Widget build(BuildContext context) {
    final face = active ? color : const Color(0xff3c3858);
    return SizedBox(
      width: 86,
      child: Opacity(
        opacity: disabled ? 0.5 : 1,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(9),
            onTap: disabled ? null : onTap,
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 3),
              padding: const EdgeInsets.fromLTRB(7, 7, 7, 6),
              decoration: BoxDecoration(
                color: face,
                borderRadius: BorderRadius.circular(9),
                border: Border.all(
                    color: active ? Colors.white70 : const Color(0xff766d99)),
                boxShadow: [
                  BoxShadow(
                    color:
                        active ? color.withValues(alpha: 0.55) : Colors.black54,
                    blurRadius: active ? 9 : 3,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(icon, size: 17, color: Colors.white),
                      const Spacer(),
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: active
                              ? const Color(0xffb8ff79)
                              : const Color(0xff27243b),
                          boxShadow: active
                              ? const [
                                  BoxShadow(
                                      color: Color(0xffb8ff79), blurRadius: 5)
                                ]
                              : null,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.w900, fontSize: 12)),
                  Text(sublabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 9, letterSpacing: 0.7)),
                  const SizedBox(height: 6),
                  InkWell(
                    borderRadius: BorderRadius.circular(4),
                    onTap: disabled ? null : onFootswitch,
                    child: Container(
                      height: 20,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xffded9c4),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: const Color(0xff4a4557)),
                      ),
                      child: const Icon(Icons.circle,
                          size: 11, color: Color(0xff504b5d)),
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
            FilledButton.icon(
              onPressed: _busyId == null ? _saveCurrent : null,
              icon: const Icon(Icons.save),
              label: const Text('SAVE CURRENT RIG'),
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
    required this.onClear,
    super.key,
  });

  final ModelSlot slot;
  final EngineSnapshot snapshot;
  final Future<void> Function(String, double) onChanged;
  final VoidCallback onClear;

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
              onPressed: widget.onClear,
              icon: const Icon(Icons.delete_outline),
              label: Text('CLEAR $label MODEL'),
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
    super.key,
  });

  final EffectKind effect;
  final EngineSnapshot snapshot;
  final Future<void> Function(String, double) onChanged;

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
                style: TextStyle(color: Color(0xffaaa5c4))),
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
          ],
        ),
      ),
    );
  }
}

class LooperControlsSheet extends StatelessWidget {
  const LooperControlsSheet(
      {required this.mode, required this.onAction, super.key});

  final String mode;
  final Future<void> Function(String) onAction;

  @override
  Widget build(BuildContext context) {
    Future<void> choose(String action) async {
      try {
        await onAction(action);
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(children: [
              const Icon(Icons.loop, color: Color(0xffb8ff79)),
              const SizedBox(width: 8),
              const Text('30 SECOND LOOPER',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 19)),
              const Spacer(),
              IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close)),
            ]),
            Text(
                'Now: ${mode.toUpperCase()}  •  loop audio clears after a restart',
                style: const TextStyle(color: Color(0xffaaa5c4))),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                FilledButton.icon(
                    onPressed: () => choose('record'),
                    icon: const Icon(Icons.fiber_manual_record),
                    label: const Text('RECORD')),
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
          ],
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

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: StreamBuilder<MeterSnapshot>(
        stream: widget.meters,
        initialData: const MeterSnapshot.silent(),
        builder: (context, snapshot) {
          final reading = _TunerReading.fromMeter(snapshot.data!, _tuning);
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Icon(Icons.tune, color: Color(0xffb8ff79)),
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
                    style: TextStyle(color: Color(0xffaaa5c4))),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xff171330),
                    borderRadius: BorderRadius.circular(14),
                    border:
                        Border.all(color: const Color(0xff564c81), width: 2),
                  ),
                  child: Column(
                    children: [
                      Text(reading.note ?? '—',
                          style: const TextStyle(
                            fontSize: 55,
                            height: 1,
                            fontWeight: FontWeight.w900,
                            color: Color(0xfff2eedf),
                          )),
                      const SizedBox(height: 6),
                      Text(
                        reading.note == null
                            ? 'PLAY ONE STRING'
                            : '${reading.frequency.toStringAsFixed(1)} Hz  •  ${reading.cents >= 0 ? '+' : ''}${reading.cents.round()} cents',
                        style: const TextStyle(
                          color: Color(0xffb8ff79),
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _TunerNeedle(
                          cents: reading.cents,
                          hasSignal: reading.note != null),
                      const SizedBox(height: 3),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: const [
                          Text('FLAT',
                              style: TextStyle(
                                  fontSize: 10, color: Color(0xffaaa5c4))),
                          Text('IN TUNE',
                              style: TextStyle(
                                  fontSize: 10, color: Color(0xffaaa5c4))),
                          Text('SHARP',
                              style: TextStyle(
                                  fontSize: 10, color: Color(0xffaaa5c4))),
                        ],
                      ),
                    ],
                  ),
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
                        onSelected: (_) => setState(() => _tuning = tuning),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  _tuning.notes.join('  '),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xffa6ffdd),
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
                  color: const Color(0xff504a70),
                  borderRadius: BorderRadius.circular(4))),
          Container(width: 2, height: 18, color: const Color(0xfff2eedf)),
          Align(
            alignment: Alignment(x, 0),
            child: Container(
              width: 15,
              height: 15,
              decoration: BoxDecoration(
                color:
                    inTune ? const Color(0xffb8ff79) : const Color(0xffffc45e),
                shape: BoxShape.circle,
                boxShadow: hasSignal
                    ? [
                        BoxShadow(
                            color: inTune
                                ? const Color(0xffb8ff79)
                                : const Color(0xffffc45e),
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
      {required this.frequency, required this.cents, this.note});

  factory _TunerReading.fromMeter(MeterSnapshot meter, _Tuning tuning) {
    if (meter.tunerHz <= 0 || meter.tunerConfidence < .55) {
      return const _TunerReading(frequency: 0, cents: 0);
    }
    String? closest;
    var closestCents = double.infinity;
    for (final note in tuning.notes) {
      final cents =
          1200 * math.log(meter.tunerHz / _noteFrequency(note)) / math.ln2;
      if (cents.abs() < closestCents.abs()) {
        closest = note;
        closestCents = cents;
      }
    }
    return _TunerReading(
      frequency: meter.tunerHz,
      cents: closestCents,
      note: closest,
    );
  }

  final double frequency;
  final double cents;
  final String? note;
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

class ModelLibrarySheet extends StatefulWidget {
  const ModelLibrarySheet({
    required this.catalog,
    required this.engineConnected,
    required this.selectedPrePath,
    required this.selectedAmpPath,
    required this.onSelected,
    super.key,
  });

  final CatalogClient catalog;
  final bool engineConnected;
  final String? selectedPrePath;
  final String? selectedAmpPath;
  final Future<void> Function(CatalogModel, ModelSlot) onSelected;

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
    super.key,
  });

  final CatalogClient catalog;
  final bool engineConnected;
  final Future<void> Function(CatalogModel, ModelSlot) onSelected;

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
      final slot = await showDialog<ModelSlot>(
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
        color: connected ? Colors.greenAccent : Colors.orangeAccent,
      ),
    );
  }
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
            ? Colors.amberAccent
            : Colors.greenAccent;
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
    required this.eqLowDb,
    required this.eqMidDb,
    required this.eqHighDb,
    required this.chorusEnabled,
    required this.chorusRateHz,
    required this.chorusDepth,
    required this.chorusMix,
    required this.delayEnabled,
    required this.delayTimeMs,
    required this.delayFeedback,
    required this.delayMix,
    required this.reverbEnabled,
    required this.reverbDecaySeconds,
    required this.reverbMix,
    required this.looperMode,
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
        eqLowDb = 0,
        eqMidDb = 0,
        eqHighDb = 0,
        chorusEnabled = false,
        chorusRateHz = .8,
        chorusDepth = .5,
        chorusMix = .35,
        delayEnabled = false,
        delayTimeMs = 360,
        delayFeedback = .35,
        delayMix = .25,
        reverbEnabled = false,
        reverbDecaySeconds = 2.5,
        reverbMix = .25,
        looperMode = 'stopped',
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
      eqLowDb: (json['eq_low_db'] as num?)?.toDouble() ?? 0,
      eqMidDb: (json['eq_mid_db'] as num?)?.toDouble() ?? 0,
      eqHighDb: (json['eq_high_db'] as num?)?.toDouble() ?? 0,
      chorusEnabled: json['chorus_enabled'] as bool? ?? false,
      chorusRateHz: (json['chorus_rate_hz'] as num?)?.toDouble() ?? .8,
      chorusDepth: (json['chorus_depth'] as num?)?.toDouble() ?? .5,
      chorusMix: (json['chorus_mix'] as num?)?.toDouble() ?? .35,
      delayEnabled: json['delay_enabled'] as bool? ?? false,
      delayTimeMs: (json['delay_time_ms'] as num?)?.toDouble() ?? 360,
      delayFeedback: (json['delay_feedback'] as num?)?.toDouble() ?? .35,
      delayMix: (json['delay_mix'] as num?)?.toDouble() ?? .25,
      reverbEnabled: json['reverb_enabled'] as bool? ?? false,
      reverbDecaySeconds:
          (json['reverb_decay_seconds'] as num?)?.toDouble() ?? 2.5,
      reverbMix: (json['reverb_mix'] as num?)?.toDouble() ?? .25,
      looperMode: json['looper_mode'] as String? ?? 'stopped',
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
  final double eqLowDb;
  final double eqMidDb;
  final double eqHighDb;
  final bool chorusEnabled;
  final double chorusRateHz;
  final double chorusDepth;
  final double chorusMix;
  final bool delayEnabled;
  final double delayTimeMs;
  final double delayFeedback;
  final double delayMix;
  final bool reverbEnabled;
  final double reverbDecaySeconds;
  final double reverbMix;
  final String looperMode;
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
        (_) => _send('get_meters', const {}),
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

  Future<void> looperAction(String action) => _request(
        'looper_action',
        {'action': action},
        timeoutMessage: 'Looper command timed out',
      );

  Future<void> setTunerEnabled(bool enabled) => _request(
        'set_tuner_enabled',
        {'enabled': enabled},
        timeoutMessage: 'Tuner change timed out',
      );

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
        {'path': model.path, 'preset': model.name, 'slot': slot.name},
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
