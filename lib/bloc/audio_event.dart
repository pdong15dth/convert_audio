abstract class AudioEvent {}

class ConvertLongTextToAudio extends AudioEvent {
  final String longText;
  ConvertLongTextToAudio(this.longText);
}

class PlayAudio extends AudioEvent {}
