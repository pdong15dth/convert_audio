import 'dart:io';

import 'package:flutter_tts/flutter_tts.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:just_audio_background/just_audio_background.dart';

class AudioService {
  final FlutterTts flutterTts = FlutterTts();
  final AudioPlayer audioPlayer = AudioPlayer();

  Function(int, int)? onProgressChanged;
  Function()? onComplete;

  AudioService() {
    flutterTts.setCompletionHandler(() {
      _handleCompletion();
    });
  }

  int totalChunks = 0;
  int completedChunks = 0;
  Map<int, String> tempPaths = {};
  List<String> audioFilePaths = [];

  void _handleCompletion() {
    completedChunks++;
    audioFilePaths.add(tempPaths[completedChunks - 1]!);
    onProgressChanged?.call(completedChunks, totalChunks);

    if (completedChunks == totalChunks) {
      onComplete?.call();
    }
  }

  Future<void> _deleteExistingOutputFiles() async {
    final musicDir = Directory('/storage/emulated/0/Music');
    try {
      final existingFiles = musicDir.listSync().whereType<File>().where((file) {
        return file.path.contains('convert_audio_app') &&
            file.path.endsWith('.wav');
      });
      for (var file in existingFiles) {
        print('Deleting file: ${file.path}');
        await file.delete();
      }
    } catch (e) {
      print('Error deleting existing files: $e');
    }
  }

  Future<void> convertLongTextToAudio(String longText) async {
    completedChunks = 0;
    audioFilePaths = [];
    tempPaths.clear();

    await _deleteExistingOutputFiles();

    final chunks = <String>[];
    for (var i = 0; i < longText.length; i += 1000) {
      chunks.add(longText.substring(
          i, i + 1000 > longText.length ? longText.length : i + 1000));
    }

    totalChunks = chunks.length;

    for (var i = 0; i < chunks.length; i++) {
      final filePath =
          '${(await path_provider.getApplicationDocumentsDirectory()).path}/output_$i.wav';
      tempPaths[i] = filePath;
      await flutterTts.synthesizeToFile(chunks[i], filePath);
    }
  }

  Future<void> playAudio() async {
    if (audioFilePaths.isEmpty) return;

    final musicDir = Directory('/storage/emulated/0/Music');

    try {
      final files = musicDir.listSync().whereType<File>().where((file) {
        return file.path.contains('convert_audio_app') &&
            file.path.endsWith('.wav');
      }).toList();

      files.sort((a, b) {
        final aNum = int.parse(a.path.split('output_').last.split('.').first);
        final bNum = int.parse(b.path.split('output_').last.split('.').first);
        return aNum.compareTo(bNum);
      });

      // Create playlist
      final playlist = ConcatenatingAudioSource(
        children: files.map((file) {
          return AudioSource.file(
            file.path,
            tag: MediaItem(
              id: file.path,
              title: 'Audio Part ${files.indexOf(file) + 1}',
              artist: 'Text to Speech',
              // Optional: Add more metadata
              // artUri: Uri.parse('https://example.com/albumart.jpg'),
            ),
          );
        }).toList(),
      );

      // Set and play the playlist
      await audioPlayer.setAudioSource(playlist);
      await audioPlayer.play();
    } catch (e) {
      print('Error playing audio: $e');
    }
  }

  void dispose() {
    audioPlayer.dispose();
  }
}
