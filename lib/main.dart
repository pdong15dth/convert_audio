import 'package:convert_audio/text.dart';
import 'package:flutter/material.dart';
import 'services/audio_service.dart';
import 'package:just_audio_background/just_audio_background.dart';

void main() async {
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.convert_audio.app.audio',
    androidNotificationChannelName: 'Audio playback',
    androidNotificationOngoing: true,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final AudioService _audioService = AudioService();
  bool isConverting = false;
  bool isPlaying = false;
  bool isComplete = false;

  @override
  void initState() {
    super.initState();

    _audioService.onProgressChanged = (completed, total) {
      setState(() {});
    };

    _audioService.onComplete = () {
      setState(() {
        isComplete = true;
      });
    };
  }

  @override
  void dispose() {
    _audioService.dispose();
    super.dispose();
  }

  Future<void> convertLongTextToAudio(String longText) async {
    setState(() {
      isConverting = true;
      isComplete = false;
    });

    await _audioService.convertLongTextToAudio(longText);

    setState(() {
      isConverting = false;
    });
  }

  Future<void> playAudio() async {
    setState(() => isPlaying = true);
    await _audioService.playAudio();
    setState(() => isPlaying = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isConverting) ...[
              CircularProgressIndicator(),
              const SizedBox(height: 16),
            ] else ...[
              if (isComplete) const Text('Đã tạo xong tất cả file audio!'),
              ElevatedButton(
                onPressed: () => convertLongTextToAudio(longText),
                child: const Text('Chuyển thành audio'),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    LinearProgressIndicator(
                      value: _audioService.totalChunks > 0
                          ? _audioService.completedChunks /
                              _audioService.totalChunks
                          : 0,
                    ),
                    const SizedBox(height: 8),
                    Text(
                        'Đang tạo file: ${_audioService.completedChunks}/${_audioService.totalChunks}'),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  print('object');
                },
                child: Text(isPlaying ? 'Đang phát...' : 'Phát audio'),
              ),
              if (_audioService.audioFilePaths.isNotEmpty &&
                  _audioService.completedChunks ==
                      _audioService.totalChunks) ...[
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: isPlaying ? null : playAudio,
                  child: Text(isPlaying ? 'Đang phát...' : 'Phát audio'),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
