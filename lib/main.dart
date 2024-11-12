import 'package:convert_audio/text.dart';
import 'package:path_provider/path_provider.dart' as pathProvider;
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:flutter/scheduler.dart';
import 'package:just_audio/just_audio.dart';

void main() {
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
  final FlutterTts flutterTts = FlutterTts();
  final AudioPlayer audioPlayer = AudioPlayer();
  bool isConverting = false;
  bool isPlaying = false;
  int totalChunks = 0;
  int completedChunks = 0;
  List<String> audioFilePaths = [];
  bool isComplete = false;
  Map<int, String> tempPaths = {};

  @override
  void initState() {
    super.initState();

    flutterTts.setCompletionHandler(() {
      setState(() {
        completedChunks++;
        audioFilePaths.add(tempPaths[completedChunks - 1]!);
      });
      print("Đã tạo xong file audio, $completedChunks/$totalChunks");
      if (completedChunks == totalChunks) {
        print("Đây là file cuối cùng!");
        setState(() {
          isComplete = true;
        });
      }
    });
  }

  @override
  void dispose() {
    audioPlayer.dispose();
    super.dispose();
  }

  Future<void> convertLongTextToAudio(String longText) async {
    setState(() {
      isConverting = true;
      isComplete = false;
      completedChunks = 0;
      audioFilePaths = [];
      tempPaths.clear();
    });

    final chunks = <String>[];
    for (var i = 0; i < longText.length; i += 1000) {
      chunks.add(longText.substring(
          i, i + 1000 > longText.length ? longText.length : i + 1000));
    }

    totalChunks = chunks.length;

    for (var i = 0; i < chunks.length; i++) {
      final filePath =
          '${(await pathProvider.getApplicationDocumentsDirectory()).path}/output_$i.wav';
      tempPaths[i] = filePath;
      await flutterTts.synthesizeToFile(chunks[i], filePath);
    }

    setState(() {
      isConverting = false;
    });
  }

  Future<void> convertToAudio(String text) async {
    final dir = await pathProvider.getApplicationDocumentsDirectory();
    final filePath = '${dir.path}/output.wav';

    try {
      var result = await flutterTts.synthesizeToFile(text, filePath, true);
      if (result == 1) {
        // Success
        print("Bắt đầu tạo file");
      }
    } catch (e) {
      print("Lỗi: $e");
    }
  }

  Future<bool> isAudioFileReady(String filePath) async {
    final file = File(filePath);
    if (await file.exists()) {
      final fileSize = await file.length();
      return fileSize > 0; // File đã được tạo và có dữ liệu
    }
    return false;
  }

  Future<void> playAudio() async {
    if (audioFilePaths.isEmpty) return;

    setState(() => isPlaying = true);

    // Lấy đường dẫn đến thư mục Music
    final musicDir = Directory('/storage/emulated/0/Music');

    try {
      // Tìm file trong Music folder
      final files = musicDir.listSync().whereType<File>().where((file) {
        return file.path.contains('convert_audio_app') &&
            file.path.endsWith('.wav');
      }).toList();

      // Sắp xếp theo số thứ tự
      files.sort((a, b) {
        final aNum = int.parse(a.path.split('output_').last.split('.').first);
        final bNum = int.parse(b.path.split('output_').last.split('.').first);
        return aNum.compareTo(bNum);
      });

      for (File file in files) {
        try {
          print('Đang phát: ${file.path}');
          await audioPlayer.setFilePath(file.path);
          await audioPlayer.play();
          await audioPlayer.playerStateStream.firstWhere(
              (state) => state.processingState == ProcessingState.completed);
        } catch (e) {
          print('Lỗi phát audio: $e');
        }
      }
    } catch (e) {
      print('Lỗi khi tìm file: $e');
    }

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
                      value:
                          totalChunks > 0 ? completedChunks / totalChunks : 0,
                    ),
                    const SizedBox(height: 8),
                    Text(
                        '${((completedChunks / totalChunks) * 100).toStringAsFixed(1)}%'),
                    Text('Đang tạo file: $completedChunks/$totalChunks'),
                  ],
                ),
              ),
              if (audioFilePaths.isNotEmpty) ...[
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
