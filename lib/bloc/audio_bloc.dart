// lib/bloc/audio_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'audio_event.dart';
import 'audio_state.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart' as pathProvider;
import 'dart:io';

class AudioBloc extends Bloc<AudioEvent, AudioState> {
  final FlutterTts flutterTts = FlutterTts();
  final AudioPlayer audioPlayer = AudioPlayer();

  AudioBloc() : super(AudioInitial()) {
    on<ConvertLongTextToAudio>(_onConvertLongTextToAudio);
    on<PlayAudio>(_onPlayAudio);
  }

  Future<void> _onConvertLongTextToAudio(
      ConvertLongTextToAudio event, Emitter<AudioState> emit) async {
    emit(AudioConverting());

    final chunks = <String>[];
    for (var i = 0; i < event.longText.length; i += 1000) {
      chunks.add(event.longText.substring(i,
          i + 1000 > event.longText.length ? event.longText.length : i + 1000));
    }

    final audioFilePaths = <String>[];
    for (var i = 0; i < chunks.length; i++) {
      final filePath =
          '${(await pathProvider.getApplicationDocumentsDirectory()).path}/output_$i.wav';
      await flutterTts.synthesizeToFile(chunks[i], filePath);
      audioFilePaths.add(filePath);
    }

    emit(AudioConverted(audioFilePaths));
  }

  Future<void> _onPlayAudio(PlayAudio event, Emitter<AudioState> emit) async {
    emit(AudioPlaying());

    // Implement play audio logic here

    emit(AudioInitial());
  }
}
