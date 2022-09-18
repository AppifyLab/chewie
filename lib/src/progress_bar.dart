import 'package:chewie/src/chewie_progress_colors.dart';
import 'package:chewie/src/models/video_chapters_model.dart';
import 'package:chewie/src/models/video_moments_model.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoProgressBar extends StatefulWidget {
  VideoProgressBar(
    this.controller, {
    ChewieProgressColors? colors,
    this.onDragEnd,
    this.onDragStart,
    this.onDragUpdate,
    Key? key,
    required this.barHeight,
    required this.handleHeight,
    required this.drawShadow,
    required this.durationRange,
    required this.momentsList,
  })  : colors = colors ?? ChewieProgressColors(),
        super(key: key);

  final VideoPlayerController controller;
  final ChewieProgressColors colors;
  final Function()? onDragStart;
  final Function()? onDragEnd;
  final Function()? onDragUpdate;

  final double barHeight;
  final double handleHeight;
  final bool drawShadow;

  final List<VideoChaptersModel> durationRange;
  final List<VideoMomentsModel> momentsList;

  @override
  // ignore: library_private_types_in_public_api
  _VideoProgressBarState createState() {
    return _VideoProgressBarState();
  }
}

class _VideoProgressBarState extends State<VideoProgressBar> {
  void listener() {
    if (!mounted) return;
    setState(() {});
  }

  bool _controllerWasPlaying = false;

  VideoPlayerController get controller => widget.controller;

  @override
  void initState() {
    super.initState();
    controller.addListener(listener);
  }

  @override
  void deactivate() {
    controller.removeListener(listener);
    super.deactivate();
  }

  void _seekToRelativePosition(Offset globalPosition) {
    final box = context.findRenderObject()! as RenderBox;
    final Offset tapPos = box.globalToLocal(globalPosition);
    final double relative = tapPos.dx / box.size.width;
    final Duration position = controller.value.duration * relative;
    controller.seekTo(position);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragStart: (DragStartDetails details) {
        if (!controller.value.isInitialized) {
          return;
        }
        _controllerWasPlaying = controller.value.isPlaying;
        if (_controllerWasPlaying) {
          controller.pause();
        }

        widget.onDragStart?.call();
      },
      onHorizontalDragUpdate: (DragUpdateDetails details) {
        if (!controller.value.isInitialized) {
          return;
        }
        // // Should only seek if it's not running on Android, or if it is,
        // // then the VideoPlayerController cannot be buffering.
        // // On Android, we need to let the player buffer when scrolling
        // // in order to let the player buffer. https://github.com/flutter/flutter/issues/101409
        // final shouldSeekToRelativePosition = !Platform.isAndroid || !controller.value.isBuffering;
        // if (shouldSeekToRelativePosition) {
        _seekToRelativePosition(details.globalPosition);
        // }

        widget.onDragUpdate?.call();
      },
      onHorizontalDragEnd: (DragEndDetails details) {
        if (_controllerWasPlaying) {
          controller.play();
        }

        widget.onDragEnd?.call();
      },
      onTapDown: (TapDownDetails details) {
        if (!controller.value.isInitialized) {
          return;
        }
        _seekToRelativePosition(details.globalPosition);
      },
      child: Center(
        child: Container(
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
          color: Colors.transparent,
          child: CustomPaint(
            painter: _TestProgressBarPainter(
              value: controller.value,
              colors: widget.colors,
              barHeight: widget.barHeight,
              handleHeight: widget.handleHeight,
              drawShadow: widget.drawShadow,
              durationRange: widget.durationRange,
              momentsList: widget.momentsList,
            ),
          ),
        ),
      ),
    );
  }
}

class _TestProgressBarPainter extends CustomPainter {
  _TestProgressBarPainter({
    required this.value,
    required this.colors,
    required this.barHeight,
    required this.handleHeight,
    required this.drawShadow,
    required this.durationRange,
    required this.momentsList,
  });

  VideoPlayerValue value;
  ChewieProgressColors colors;

  final double barHeight;
  final double handleHeight;
  final bool drawShadow;
  final List<VideoChaptersModel> durationRange;
  final List<VideoMomentsModel> momentsList;

  @override
  bool shouldRepaint(CustomPainter painter) {
    return true;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final baseOffset = size.height / 2 - barHeight / 2;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromPoints(
          Offset(0.0, baseOffset),
          Offset(size.width, baseOffset + barHeight),
        ),
        const Radius.circular(4.0),
      ),
      colors.backgroundPaint,
    );

    if (!value.isInitialized) {
      return;
    }

    final double playedPartPercent = value.position.inMilliseconds / value.duration.inMilliseconds;
    final double playedPart = playedPartPercent > 1 ? size.width : playedPartPercent * size.width;

    for (final DurationRange range in value.buffered) {
      final double start = range.startFraction(value.duration) * size.width;
      final double end = range.endFraction(value.duration) * size.width;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromPoints(
            Offset(start, baseOffset),
            Offset(end, baseOffset + barHeight),
          ),
          const Radius.circular(4.0),
        ),
        colors.bufferedPaint,
      );
    }
    if (durationRange.isEmpty) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromPoints(
            Offset(0.0, baseOffset),
            Offset(playedPart, baseOffset + barHeight),
          ),
          const Radius.circular(4.0),
        ),
        colors.playedPaint,
      );
    } else {
      for (int j = 0; j < durationRange.length; j++) {
        final DurationRange range = durationRange[j].durationRange;
        final double start = range.startFraction(value.duration) * size.width;
        final double end = range.endFraction(value.duration) * size.width;

        /// Played part bar
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromPoints(
              Offset(start, baseOffset),
              Offset(playedPart, playedPart >= start && playedPart <= end ? baseOffset + 6 : baseOffset + barHeight),
            ),
            const Radius.circular(4),
          ),
          Paint()..color = value.position >= range.start && value.position <= range.end ? Colors.red : Colors.transparent,
        );

        /// Playing section bar
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromPoints(
              Offset(playedPart, baseOffset),
              Offset(end, playedPart >= start && playedPart <= end ? baseOffset + 6 : baseOffset + barHeight),
            ),
            const Radius.circular(4),
          ),
          Paint()..color = value.position >= range.start && value.position <= range.end ? Colors.white.withOpacity(0.9) : Colors.transparent,
        );
      }
    }

    /// General progress bar
    for (int i = 0; i < durationRange.length; i++) {
      final DurationRange range = durationRange[i].durationRange;
      final double start = range.startFraction(value.duration) * size.width;
      final double end = range.endFraction(value.duration) * size.width;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromPoints(Offset(start, baseOffset), Offset(end - 2.5, baseOffset + barHeight)),
          const Radius.circular(4),
        ),
        Paint()..color = value.position >= range.end ? Colors.red : Colors.white12,
      );
    }

    /// Moment
    final Paint momentPaint = Paint()..color = Colors.white.withOpacity(0.5);
    final Paint momentColoredPaint = Paint()..color = Colors.white;

    for (int i = 0; i < momentsList.length; i++) {
      final double moment = Duration(seconds: (i + 1) * 10).inMilliseconds / value.duration.inMilliseconds * size.width;
      canvas.drawCircle(Offset(moment, baseOffset + barHeight / 2), 5.5, momentPaint);
      canvas.drawCircle(Offset(moment, baseOffset + barHeight / 2), 2.75, momentColoredPaint);
    }

    canvas.drawCircle(
      Offset(playedPart, baseOffset + barHeight / 2),
      handleHeight,
      colors.handlePaint,
    );
  }
}
