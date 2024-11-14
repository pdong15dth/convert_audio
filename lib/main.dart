import 'package:convert_audio/text.dart';
import 'package:flutter/material.dart';
import 'services/audio_service.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
    //check nếu chưa có quyền truy cập bộ nhớ thì xin

    requestStoragePermission();

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

  Future<void> requestStoragePermission() async {
    final status = await Permission.storage.status;
    
    if (!(await Permission.manageExternalStorage.status.isDenied)) {
      return;
    }

    if (status.isDenied) {
      if (!mounted) return; // Add this check
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Cấp quyền truy cập'),
          content: const Text(
              'Ứng dụng cần quyền truy cập bộ nhớ để lưu file audio'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                final _ = await Permission.storage.request();
                // if (result.isDenied) {
                //   SystemNavigator.pop(); // Thoát app nếu không được cấp quyền
                // }
                await Permission.manageExternalStorage.request();
              },
              child: const Text('Đồng ý'),
            ),
          ],
        ),
      );
    }
  }
}
