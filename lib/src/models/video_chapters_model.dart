import 'package:video_player/video_player.dart';

class VideoChaptersModel {
  VideoChaptersModel({
    required this.durationRange,
    required this.title,
  });

  final DurationRange durationRange;
  final String title;
}
