abstract class AudioState {}

class AudioInitial extends AudioState {}

class AudioConverting extends AudioState {}

class AudioConverted extends AudioState {
  final List<String> audioFilePaths;
  AudioConverted(this.audioFilePaths);
}

class AudioPlaying extends AudioState {}

class AudioError extends AudioState {
  final String message;
  AudioError(this.message);
}
