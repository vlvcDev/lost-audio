import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pedal_ui/main.dart';

void main() {
  testWidgets('shows the disconnected rig shell', (tester) async {
    await tester.pumpWidget(const PedalApp());

    expect(find.text('PEDAL'), findsNWidgets(2));
    expect(find.text('AMP'), findsOneWidget);
    expect(find.text('EMPTY'), findsNWidgets(2));
    expect(find.text('Waiting for engine'), findsOneWidget);
    expect(find.text('RECONNECT'), findsOneWidget);
    expect(find.text('TONES'), findsOneWidget);
    expect(find.text('TEST AUDIO'), findsOneWidget);
    expect(find.text('TONE3000'), findsOneWidget);
    expect(find.text('OUTPUT'), findsOneWidget);
    expect(find.text('IN'), findsOneWidget);
    expect(find.text('OUT'), findsOneWidget);
    expect(find.textContaining('XRUN 0'), findsOneWidget);
  });

  testWidgets('rig shell fits the target 480x320 touchscreen', (tester) async {
    tester.view.physicalSize = const Size(480, 320);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const PedalApp());
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('TONES'), findsOneWidget);
    expect(find.text('TEST AUDIO'), findsOneWidget);
    expect(find.text('TONE3000'), findsOneWidget);
    expect(find.text('OUTPUT'), findsOneWidget);
  });

  test('catalog model formats offline metadata for the touch UI', () {
    final model = CatalogModel.fromJson({
      'name': 'Clean Combo',
      'path': '/var/lib/pedal/models/clean.nam',
      'size_bytes': 1572864,
      'source': 'tone3000:model:42',
      'favorite': false,
    });

    expect(model.sourceLabel, 'TONE3000');
    expect(model.sizeLabel, '1.5 MB');
  });

  test('TONE3000 response models parse catalog protocol data', () {
    final status = Tone3000Status.fromJson({
      'available': true,
      'connected': true,
      'auth_pending': false,
      'selected_tone_id': '7',
    });
    final tone = RemoteTone.fromJson({
      'id': '7',
      'name': 'Clean Combo',
      'author': 'Ada',
      'gear': 'amp',
    });
    final model = RemoteModel.fromJson({
      'id': '9',
      'tone_id': '7',
      'name': 'Bright',
    });

    expect(status.connected, isTrue);
    expect(status.selectedToneId, '7');
    expect(tone.author, 'Ada');
    expect(model.toneId, '7');
  });

  test('preview response parses the rendered audio file', () {
    final preview = PreviewAudio.fromJson({
      'path': '/tmp/pedal-preview.wav',
      'duration_seconds': 4.25,
    });

    expect(preview.path, '/tmp/pedal-preview.wav');
    expect(preview.durationSeconds, 4.25);
  });

  test('system output parser finds sinks and their active selection', () {
    final outputs = SystemAudioService.parseOutputs('''
Audio
 ├─ Sinks:
 │  *   63. Laptop Speakers [vol: 0.35]
 │     132. Lil Buds [vol: 0.27]
 ├─ Sources:
 │      64. Microphone [vol: 1.00]
''');

    expect(outputs, hasLength(2));
    expect(outputs.first.name, 'Laptop Speakers');
    expect(outputs.first.isDefault, isTrue);
    expect(outputs.last.isBluetooth, isTrue);
  });

  testWidgets('online tone browser fits the target touchscreen',
      (tester) async {
    tester.view.physicalSize = const Size(480, 320);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      PedalAppTestShell(
        child: Tone3000BrowserSheet(
          catalog: FakeCatalogClient(),
          engineConnected: false,
          onSelected: (_, __) async {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('TONE3000'), findsOneWidget);
    expect(find.text('Clean Combo'), findsOneWidget);
    expect(find.text('Bright'), findsOneWidget);
    expect(find.text('NAM A2'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('online tone browser clearly explains missing configuration',
      (tester) async {
    tester.view.physicalSize = const Size(480, 320);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      PedalAppTestShell(
        child: Tone3000BrowserSheet(
          catalog: UnconfiguredCatalogClient(),
          engineConnected: false,
          onSelected: (_, __) async {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('TONE3000'), findsOneWidget);
    expect(find.textContaining('not configured'), findsOneWidget);
    expect(find.textContaining('still work offline'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('engine snapshot displays the pedal into amp chain', () {
    final snapshot = EngineSnapshot.fromJson({
      'bypassed': false,
      'pre_bypassed': true,
      'amp_bypassed': false,
      'preset': 'Drive Rig',
      'preset_id': 'preset-2',
      'preset_dirty': true,
      'pre_model': '/models/drive.nam',
      'model': '/models/amp.nam',
      'pedal_drive_db': 8.5,
      'pedal_mix': 0.75,
      'pedal_level_db': -2.0,
      'amp_bass_db': 2.5,
      'amp_mid_db': -1.0,
      'amp_treble_db': 3.0,
      'amp_volume_db': -4.0,
      'sample_rate': 48000,
      'buffer_frames': 64,
    });

    expect(snapshot.modelName, 'drive.nam → amp.nam');
    expect(snapshot.preBypassed, isTrue);
    expect(snapshot.ampBypassed, isFalse);
    expect(snapshot.pedalMix, 0.75);
    expect(snapshot.ampBassDb, 2.5);
    expect(snapshot.presetTitle, 'Drive Rig *');
  });

  test('meter snapshot parses safety and health telemetry', () {
    final meters = MeterSnapshot.fromJson({
      'input_db': -12.5,
      'output_db': -3.0,
      'clipped': true,
      'cpu_percent': 8.25,
      'xruns': 2,
    });

    expect(meters.inputDb, -12.5);
    expect(meters.outputDb, -3.0);
    expect(meters.clipped, isTrue);
    expect(meters.cpuPercent, 8.25);
    expect(meters.xruns, 2);
  });

  test('preset summary describes its saved model chain', () {
    final preset = PresetSummary.fromJson({
      'id': 'preset-1',
      'name': 'Crunch',
      'pre_model': '/models/drive.nam',
      'model': '/models/amp.nam',
    });

    expect(preset.name, 'Crunch');
    expect(preset.modelSummary, 'drive.nam → amp.nam');
  });

  testWidgets('amp controls fit and expose the expected tone stack',
      (tester) async {
    tester.view.physicalSize = const Size(480, 320);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final snapshot = EngineSnapshot.fromJson({
      'bypassed': false,
      'preset': 'Test',
      'pre_model': '/models/drive.nam',
      'model': '/models/amp.nam',
    });

    await tester.pumpWidget(
      PedalAppTestShell(
        child: SlotControlsSheet(
          slot: ModelSlot.amp,
          snapshot: snapshot,
          onChanged: (_, __) async {},
          onClear: () {},
        ),
      ),
    );

    expect(find.text('AMP CONTROLS'), findsOneWidget);
    expect(find.text('BASS'), findsOneWidget);
    expect(find.text('MID'), findsOneWidget);
    expect(find.text('TREBLE'), findsOneWidget);
    expect(find.text('VOLUME'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('preset library fits the target touchscreen', (tester) async {
    tester.view.physicalSize = const Size(480, 320);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final client = FakeControlClient();
    addTearDown(client.dispose);

    await tester.pumpWidget(
      PedalAppTestShell(
        child: PresetLibrarySheet(
          client: client,
          currentPresetId: 'preset-1',
          suggestedName: 'Crunch',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('PRESETS'), findsOneWidget);
    expect(find.text('Crunch'), findsOneWidget);
    expect(find.text('SAVE CURRENT RIG'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class FakeControlClient extends ControlClient {
  FakeControlClient() : super(socketPath: '/tmp/pedal-unused-test.sock');

  @override
  Future<List<PresetSummary>> listPresets() async => const [
        PresetSummary(
          id: 'preset-1',
          name: 'Crunch',
          preModel: '/models/drive.nam',
          model: '/models/amp.nam',
        ),
      ];
}

class FakeCatalogClient extends CatalogClient {
  FakeCatalogClient() : super(socketPath: '/tmp/pedal-unused-catalog.sock');

  @override
  Future<Tone3000Status> tone3000Status() async => const Tone3000Status(
      available: true, connected: true, selectedToneId: '7');

  @override
  Future<SelectedTone> selectedTone3000() async => const SelectedTone(
        tone: RemoteTone(
            id: '7', name: 'Clean Combo', author: 'Ada', gear: 'amp'),
        models: [RemoteModel(id: '9', toneId: '7', name: 'Bright')],
      );
}

class UnconfiguredCatalogClient extends CatalogClient {
  UnconfiguredCatalogClient()
      : super(socketPath: '/tmp/pedal-unused-catalog.sock');

  @override
  Future<Tone3000Status> tone3000Status() async =>
      const Tone3000Status(available: false, connected: false);
}

class PedalAppTestShell extends StatelessWidget {
  const PedalAppTestShell({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) => MaterialApp(
        theme: ThemeData.dark(useMaterial3: true),
        home: Scaffold(body: child),
      );
}
