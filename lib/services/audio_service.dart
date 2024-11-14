import 'dart:io';

import 'package:flutter_tts/flutter_tts.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:just_audio_background/just_audio_background.dart';
import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';

class AudioService {
  final FlutterTts flutterTts = FlutterTts();
  final AudioPlayer audioPlayer = AudioPlayer();

  Function(int, int)? onProgressChanged;
  Function()? onComplete;
  Function(Duration)? onPositionChanged;
  Function(Duration)? onDurationChanged;

  AudioService() {
    flutterTts.setCompletionHandler(() {
      _handleCompletion();
    });

    audioPlayer.positionStream.listen((position) {
      onPositionChanged?.call(position);
    });
    
    audioPlayer.durationStream.listen((duration) {
      if (duration != null) onDurationChanged?.call(duration);
    });
  }

  int totalChunks = 0;
  int completedChunks = 0;
  Map<int, String> tempPaths = {};
  List<String> audioFilePaths = [];
  String mergedFilePath = '';

  void _handleCompletion() {
    completedChunks++;
    audioFilePaths.add(tempPaths[completedChunks - 1]!);
    onProgressChanged?.call(completedChunks, totalChunks);

    if (completedChunks == totalChunks) {
      onComplete?.call();
      _mergeAudioFiles().then((mergedPath) async {
        mergedFilePath = mergedPath;
        print('Merged audio file created at: $mergedPath');
        await _deleteExistingFiles('output_');
      }).catchError((error) {
        print('Error merging audio files: $error');
      });
    }
  }

  Future<void> _deleteExistingFiles(String filePattern) async {
    final musicDir = Directory('/storage/emulated/0/Music');
    try {
      final existingFiles = musicDir.listSync().whereType<File>().where((file) {
        return file.path.contains(filePattern) && file.path.endsWith('.wav');
      });
      for (var file in existingFiles) {
        print('Deleting file: ${file.path}');
        await file.delete();
      }
    } catch (e) {
      print('Error deleting existing files: $e');
    }
  }

  Future<String> _mergeAudioFiles() async {
    final musicDir = Directory('/storage/emulated/0/Music');
    final mergedFilePath = '${musicDir.path}/convert_audio_app_merged.wav';

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

      final inputFiles = files.map((f) => "file '${f.path}'").join('\n');
      final listFilePath = '${musicDir.path}/files.txt';
      await File(listFilePath).writeAsString(inputFiles);

      await FFmpegKit.execute(
          '-f concat -safe 0 -i $listFilePath -c copy $mergedFilePath');

      // Delete temp files after successful merge
      await File(listFilePath).delete();

      return mergedFilePath;
    } catch (e) {
      print('Error merging audio files: $e');
      rethrow;
    }
  }

  Future<void> convertLongTextToAudio(String longText) async {
    await _deleteExistingFiles('output_');
    await _deleteExistingFiles('convert_audio_app_merged');

    completedChunks = 0;
    audioFilePaths = [];
    tempPaths.clear();

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
    try {
      await audioPlayer.setAudioSource(
        AudioSource.file(
          mergedFilePath,
          tag: MediaItem(
            id: mergedFilePath,
            title: 'Complete Audio',
            artist: 'Text to Speech',
          ),
        ),
      );
      await audioPlayer.play();
    } catch (e) {
      print('Error playing audio: $e');
    }
  }

  void dispose() {
    audioPlayer.dispose();
  }

  Future<void> seek(Duration position) async {
    await audioPlayer.seek(position);
  }
}
