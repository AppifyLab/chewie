import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:chewie/src/animated_play_pause.dart';
import 'package:chewie/src/center_play_button.dart';
import 'package:chewie/src/chewie_player.dart';
import 'package:chewie/src/chewie_progress_colors.dart';
import 'package:chewie/src/helpers/utils.dart';
import 'package:chewie/src/material/material_progress_bar.dart';
import 'package:chewie/src/material/widgets/custom_switch_button.dart';
import 'package:chewie/src/material/widgets/options_dialog.dart';
import 'package:chewie/src/material/widgets/playback_speed_dialog.dart';
import 'package:chewie/src/models/option_item.dart';
import 'package:chewie/src/notifiers/index.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_to_airplay/flutter_to_airplay.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

class MaterialDesktopControls extends StatefulWidget {
  const MaterialDesktopControls({this.showPlayButton = true, Key? key})
      : super(key: key);

  final bool showPlayButton;

  @override
  State<StatefulWidget> createState() {
    return _MaterialDesktopControlsState();
  }
}

class _MaterialDesktopControlsState extends State<MaterialDesktopControls>
    with SingleTickerProviderStateMixin {
  final _autoPlaySwitchController = ValueNotifier<bool>(false);
  late PlayerNotifier notifier;
  late VideoPlayerValue _latestValue;
  double? _latestVolume;
  Timer? _hideTimer;
  Timer? _initTimer;
  // late var _subtitlesPosition = Duration.zero;
  bool _subtitleOn = false;
  Timer? _showAfterExpandCollapseTimer;
  bool _dragging = false;
  double tempX = 0;
  bool _displayTapped = false;
  Timer? _bufferingDisplayTimer;
  // bool _displayBufferingIndicator = false;

  /// Mark video is buffering if video has not ended, has no error,
  ///  and position is equal to buffered duration.
  bool _isBuffering = false;

  final barHeight = 48.0 * 1.5;
  final marginSize = 5.0;

  late VideoPlayerController controller;
  ChewieController? _chewieController;

  // We know that _chewieController is set in didChangeDependencies
  ChewieController get chewieController => _chewieController!;

  @override
  void initState() {
    super.initState();
    notifier = Provider.of<PlayerNotifier>(context, listen: false);
    onSwitchedAutoplay();
  }

  Future<void> onSwitchedAutoplay() async {
    await Future<dynamic>.delayed(const Duration(seconds: 1));

    _autoPlaySwitchController.value = chewieController.onInitAutoPlay;

    if (chewieController.showAutoPlaySwitch) {
      _autoPlaySwitchController.addListener(() {
        chewieController.onSwitchedAutoPlay!(_autoPlaySwitchController.value);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    /// Mark video is buffering if video has not ended, has no error,
    /// and position is equal to buffered duration.

    /// TODO :: Also check if paused/playing
    _isBuffering = _chewieController!.videoPlayerController.value.position !=
            _chewieController!.videoPlayerController.value.duration &&
        !_chewieController!.videoPlayerController.value.hasError &&
        _chewieController!.videoPlayerController.value.isPlaying &&
        _chewieController!.videoPlayerController.value.buffered.isNotEmpty ==
            true &&
        _chewieController!.videoPlayerController.value.position.inSeconds >=
            _chewieController!
                .videoPlayerController.value.buffered[0].end.inSeconds;

    if (_latestValue.hasError) {
      return chewieController.errorBuilder?.call(
            context,
            chewieController.videoPlayerController.value.errorDescription!,
          ) ??
          const Center(
            child: Icon(
              Icons.error,
              color: Colors.white,
              size: 42,
            ),
          );
    }

    return MouseRegion(
      onHover: (_) {
        _cancelAndRestartTimer();
      },
      child: GestureDetector(
        onTap: () => _cancelAndRestartTimer(),
        child: AbsorbPointer(
          absorbing: notifier.hideStuff,
          child: Stack(
            children: [
              if (_isBuffering)
                const Center(child: CircularProgressIndicator())
              else
                _buildHitArea(),
              // if (_displayBufferingIndicator) const Center(child: CircularProgressIndicator()) else _buildHitArea(),
              _buildTopBar(),
              Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  if (_subtitleOn)
                    Transform.translate(
                      offset: Offset(
                        0.0,
                        notifier.hideStuff
                            ? barHeight * 0.8
                            : chewieController.isFullScreen
                                ? 0
                                : barHeight * 0.8,
                      ),
                      child: ClosedCaption(
                        text: _chewieController
                            ?.videoPlayerController.value.caption.text,
                        textStyle:
                            const TextStyle(fontSize: 14, color: Colors.white),
                      ),
                    ),
                  // on hover thumbnail preview container
                  _buildBottomBar(context),
                ],
              ),
              if (_dragging &&
                  chewieController.sectionDurationRange != null &&
                  chewieController.sectionDurationRange!.indexWhere(
                        (element) =>
                            _latestValue.position >=
                                element.durationRange.start &&
                            _latestValue.position <= element.durationRange.end,
                      ) !=
                      -1 &&
                  chewieController.momentsList!.indexWhere(
                        (element) =>
                            Duration(seconds: element.timestamp).inSeconds ==
                            _latestValue.position.inSeconds,
                      ) ==
                      -1)
                Positioned(
                  bottom: 65,
                  left: tempX,
                  child: Column(
                    children: [
                      Text(
                        chewieController.sectionDurationRange!
                            .where(
                              (element) =>
                                  _latestValue.position >=
                                      element.durationRange.start &&
                                  _latestValue.position <=
                                      element.durationRange.end,
                            )
                            .first
                            .title,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        formatDuration(_latestValue.position),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              if (_dragging &&
                  chewieController.momentsList!.indexWhere(
                        (element) =>
                            Duration(seconds: element.timestamp).inSeconds ==
                            _latestValue.position.inSeconds,
                      ) !=
                      -1)
                Positioned(
                  bottom: 65,
                  left: tempX,
                  child: Column(
                    children: [
                      Text(
                        chewieController.momentsList!
                            .where(
                              (element) =>
                                  Duration(seconds: element.timestamp)
                                      .inSeconds ==
                                  _latestValue.position.inSeconds,
                            )
                            .first
                            .title,
                        //     .where(
                        //       (element) => _latestValue.position >= element.durationRange.start && _latestValue.position <= element.durationRange.end,
                        //     )
                        //     .first
                        //     .title,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        formatDuration(_latestValue.position),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _dispose();
    super.dispose();
  }

  void _dispose() {
    controller.removeListener(_updateState);
    _hideTimer?.cancel();
    _initTimer?.cancel();
    _showAfterExpandCollapseTimer?.cancel();
  }

  @override
  void didChangeDependencies() {
    final _oldController = _chewieController;
    _chewieController = ChewieController.of(context);
    controller = chewieController.videoPlayerController;

    if (_oldController != chewieController) {
      _dispose();
      _initialize();
    }

    super.didChangeDependencies();
  }

  Widget _buildSubtitleToggle({bool isPadded = false}) {
    return IconButton(
      padding: isPadded ? const EdgeInsets.all(8.0) : EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
      icon: Icon(
        _subtitleOn ? Icons.subtitles : Icons.subtitles_off,
        color: _chewieController!.subtitlesDisabled
            ? Colors.white38
            : Colors.white,
      ),
      onPressed: _chewieController!.subtitlesDisabled ? null : _onSubtitleTap,
    );
  }

  Widget _buildOptionsButton({IconData? icon, bool isPadded = false}) {
    final options = <OptionItem>[
      OptionItem(
        onTap: () async {
          Navigator.pop(context);
          _onSpeedButtonTap();
        },
        iconData: Icons.speed,
        title: chewieController.optionsTranslation?.playbackSpeedButtonText ??
            'Playback speed',
      )
    ];

    if (chewieController.additionalOptions != null &&
        chewieController.additionalOptions!(context).isNotEmpty) {
      options.addAll(chewieController.additionalOptions!(context));
    }

    return AnimatedOpacity(
      opacity: notifier.hideStuff ? 0.0 : 1.0,
      duration: const Duration(milliseconds: 250),
      child: IconButton(
        padding: isPadded ? const EdgeInsets.all(8.0) : EdgeInsets.zero,
        visualDensity: VisualDensity.compact,
        onPressed: () async {
          _hideTimer?.cancel();

          if (chewieController.optionsBuilder != null) {
            await chewieController.optionsBuilder!(context, options);
          } else {
            await showModalBottomSheet<OptionItem>(
              context: context,
              isScrollControlled: true,
              useRootNavigator: chewieController.useRootNavigator,
              builder: (context) => OptionsDialog(
                options: options,
                cancelButtonText:
                    chewieController.optionsTranslation?.cancelButtonText,
              ),
            );
          }

          if (_latestValue.isPlaying) {
            _startHideTimer();
          }
        },
        icon: Icon(icon ?? Icons.more_vert, color: Colors.white),
      ),
    );
  }

  // Widget _buildSubtitles(BuildContext context, Subtitles subtitles) {
  //   if (!_subtitleOn) {
  //     return Container();
  //   }
  //   final currentSubtitle = subtitles.getByPosition(_subtitlesPosition);
  //   if (currentSubtitle.isEmpty) {
  //     return Container();
  //   }

  //   if (chewieController.subtitleBuilder != null) {
  //     return chewieController.subtitleBuilder!(
  //       context,
  //       currentSubtitle.first!.text,
  //     );
  //   }

  //   return Padding(
  //     padding: EdgeInsets.all(marginSize),
  //     child: Container(
  //       padding: const EdgeInsets.all(5),
  //       decoration: BoxDecoration(
  //         color: const Color(0x96000000),
  //         borderRadius: BorderRadius.circular(10.0),
  //       ),
  //       child: Text(
  //         currentSubtitle.first!.text.toString(),
  //         style: const TextStyle(fontSize: 18),
  //         textAlign: TextAlign.center,
  //       ),
  //     ),
  //   );
  // }

  Widget _buildTopBar() {
    return Positioned(
      top: 0,
      right: 0,
      child: SafeArea(
        child: AnimatedOpacity(
          opacity: notifier.hideStuff ? 0.0 : 1.0,
          duration: const Duration(milliseconds: 250),
          child: Row(
            children: [
              if (chewieController.showAutoPlaySwitch)
                _buildAutoPlaySwitchButton(),
              if (Platform.isIOS) ...[
                if (chewieController.showAirPlay)
                  const SizedBox(
                    height: 44.0,
                    width: 44.0,
                    child: AirPlayIconButton(
                      padding: EdgeInsets.zero,
                      color: Colors.white,
                    ),
                  ),
              ],
              if (chewieController.showDownloadOption)
                _buildDownloadButton()
              else
                const Padding(
                  padding: EdgeInsets.only(right: 10, top: 25,bottom: 25),
                ),
              if (chewieController.popupMenuButton != null)
                chewieController.popupMenuButton!,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAutoPlaySwitchButton() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4, top: 4),
      child: AdvancedSwitch(
        controller: _autoPlaySwitchController,
        activeColor: Colors.white.withOpacity(0.2),
        inactiveColor: Colors.white.withOpacity(0.2),
        height: 20,
        width: 40,
        borderRadius: const BorderRadius.all(Radius.circular(10)),
        thumb: ValueListenableBuilder(
          valueListenable: _autoPlaySwitchController,
          builder: (_, bool value, __) {
            return Icon(
              value ? Icons.play_arrow : Icons.pause_outlined,
              color: value ? Colors.black : Colors.black45,
              size: value ? 16 : 14,
            );
          },
        ),
      ),
    );
  }

  Widget _buildDownloadButton() {
    return GestureDetector(
      onTap: () {
        chewieController.onTapDownload!();
      },
      child: Container(
        height: barHeight,
        color: Colors.transparent,
        margin: const EdgeInsets.only(left: 8.0, right: 4.0),
        padding: EdgeInsets.only(
          left: 10,
          right: chewieController.popupMenuButton == null ? 10 : 0,
        ),
        child: const Icon(CupertinoIcons.cloud_download, color: Colors.white),
      ),
    );
  }

  AnimatedOpacity _buildBottomBar(BuildContext context) {
    final iconColor = Theme.of(context).textTheme.labelLarge!.color;

    return AnimatedOpacity(
      opacity: notifier.hideStuff ? 0.0 : 1.0,
      duration: const Duration(milliseconds: 300),
      child: Container(
        height: barHeight + (chewieController.isFullScreen ? 20.0 : 0),
        padding:
            EdgeInsets.only(bottom: chewieController.isFullScreen ? 10.0 : 15),
        child: SafeArea(
          bottom: chewieController.isFullScreen,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            verticalDirection: VerticalDirection.up,
            children: [
              Flexible(
                child: Row(
                  children: <Widget>[
                    _buildPlayPause(controller),
                    _buildMuteButton(controller),
                    if (chewieController.isLive)
                      const Expanded(child: Text('LIVE'))
                    else
                      _buildPosition(iconColor),
                    const Spacer(),
                    if (chewieController.showControls &&
                        chewieController.showSubtitle)
                      _buildSubtitleToggle(),
                    if (chewieController.showOptions)
                      _buildOptionsButton(icon: Icons.settings),
                    if (chewieController.allowFullScreen) _buildExpandButton(),
                  ],
                ),
              ),
              if (!chewieController.isLive)
                Expanded(
                  child: Container(
                    padding: EdgeInsets.only(
                      right: 20,
                      left: 20,
                      bottom: chewieController.isFullScreen ? 5.0 : 0,
                    ),
                    child: Row(
                      children: [
                        _buildProgressBar(),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  GestureDetector _buildExpandButton() {
    return GestureDetector(
      onTap: _onExpandCollapse,
      child: AnimatedOpacity(
        opacity: notifier.hideStuff ? 0.0 : 1.0,
        duration: const Duration(milliseconds: 300),
        child: Container(
          height: barHeight + (chewieController.isFullScreen ? 15.0 : 0),
          margin: const EdgeInsets.only(right: 10),
          padding: const EdgeInsets.only(left: 4, right: 6),
          child: Center(
            child: Icon(
              chewieController.isFullScreen
                  ? Icons.fullscreen_exit
                  : Icons.fullscreen,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHitArea() {
    final bool isFinished = _latestValue.position >= _latestValue.duration;
    final bool showPlayButton =
        widget.showPlayButton && !_dragging && !notifier.hideStuff;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      color: notifier.hideStuff
          ? Colors.transparent
          : Colors.black.withOpacity(0.5),
      child: Row(
        children: [
          const Spacer(),
          _buildSkipForwardBackward(isForward: false),
          const Spacer(),
          GestureDetector(
            onTap: () {
              if (_latestValue.isPlaying) {
                if (_displayTapped) {
                  setState(() {
                    notifier.hideStuff = true;
                  });
                } else {
                  _cancelAndRestartTimer();
                }
              } else {
                _playPause();

                setState(() {
                  notifier.hideStuff = true;
                });
              }
            },
            child: CenterPlayButton(
              backgroundColor: Colors.black54,
              iconColor: Colors.white,
              isFinished: isFinished,
              isPlaying: controller.value.isPlaying,
              show: showPlayButton,
              onPressed: _playPause,
            ),
          ),
          const Spacer(),
          _buildSkipForwardBackward(),
          const Spacer(),
        ],
      ),
    );
  }

  Future<void> _onSpeedButtonTap() async {
    _hideTimer?.cancel();

    final chosenSpeed = await showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: chewieController.useRootNavigator,
      builder: (context) => PlaybackSpeedDialog(
        speeds: chewieController.playbackSpeeds,
        selected: _latestValue.playbackSpeed,
      ),
    );

    if (chosenSpeed != null) {
      controller.setPlaybackSpeed(chosenSpeed);
    }

    if (_latestValue.isPlaying) {
      _startHideTimer();
    }
  }

  GestureDetector _buildMuteButton(VideoPlayerController controller) {
    return GestureDetector(
      onTap: () {
        _cancelAndRestartTimer();

        if (_latestValue.volume == 0) {
          controller.setVolume(_latestVolume ?? 0.5);
        } else {
          _latestVolume = controller.value.volume;
          controller.setVolume(0.0);
        }
      },
      child: AnimatedOpacity(
        opacity: notifier.hideStuff ? 0.0 : 1.0,
        duration: const Duration(milliseconds: 300),
        child: ClipRect(
          child: Container(
            height: barHeight,
            padding: const EdgeInsets.only(right: 12.0),
            child: Icon(
              _latestValue.volume > 0 ? Icons.volume_up : Icons.volume_off,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  GestureDetector _buildPlayPause(VideoPlayerController controller) {
    return GestureDetector(
      onTap: _playPause,
      child: Container(
        height: barHeight,
        color: Colors.transparent,
        margin: const EdgeInsets.only(left: 8.0, right: 4.0),
        padding: const EdgeInsets.only(left: 10, right: 10),
        child: AnimatedPlayPause(
          playing: controller.value.isPlaying,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildSkipForwardBackward({bool isForward = true}) {
    return AnimatedOpacity(
      opacity: notifier.hideStuff ? 0.0 : 1.0,
      duration: const Duration(milliseconds: 300),
      child: GestureDetector(
        onTap: () => _skipForwardBackward(isForward: isForward),
        child: Container(
          height: barHeight,
          color: Colors.transparent,
          padding: const EdgeInsets.only(left: 6.0, right: 8.0),
          margin: const EdgeInsets.only(right: 8.0),
          child: Icon(
            isForward
                ? CupertinoIcons.goforward_10
                : CupertinoIcons.gobackward_10,
            color: Colors.white,
            size: chewieController.isFullScreen ? 30 : 24,
          ),
        ),
      ),
    );
  }

  void _skipForwardBackward({bool isForward = true}) {
    _cancelAndRestartTimer();

    if (isForward) {
      final end = _latestValue.duration.inMilliseconds;
      final skip =
          (_latestValue.position + const Duration(seconds: 10)).inMilliseconds;
      controller.seekTo(Duration(milliseconds: math.min(skip, end)));
    } else {
      final beginning = Duration.zero.inMilliseconds;
      final skip =
          (_latestValue.position - const Duration(seconds: 15)).inMilliseconds;
      controller.seekTo(Duration(milliseconds: math.max(skip, beginning)));
    }
  }

  bool showRemainingDuration = false;

  Widget _buildPosition(Color? iconColor) {
    final position = _latestValue.position;
    final duration = _latestValue.duration;

    final durationRemaining = duration - position;

    return InkWell(
      onTap: () {
        // print('showRemainingDuration =  $showRemainingDuration');
        setState(() {
          showRemainingDuration = !showRemainingDuration;
        });
      },
      child: Text(
        showRemainingDuration
            ? '-${formatDuration(durationRemaining)} / ${formatDuration(duration)}'
            : '${formatDuration(position)} / ${formatDuration(duration)}',
        style: const TextStyle(fontSize: 12.0, color: Colors.white),
      ),
    );
  }

  void _onSubtitleTap() {
    setState(() {
      _subtitleOn = !_subtitleOn;
    });
  }

  void _cancelAndRestartTimer() {
    _hideTimer?.cancel();
    _startHideTimer();

    setState(() {
      notifier.hideStuff = false;
      _displayTapped = true;
    });
  }

  Future<void> _initialize() async {
    _subtitleOn = chewieController.showSubtitle;
    controller.addListener(_updateState);

    _updateState();

    if (controller.value.isPlaying || chewieController.autoPlay) {
      _startHideTimer();
    }

    if (chewieController.showControlsOnInitialize) {
      _initTimer = Timer(const Duration(milliseconds: 200), () {
        setState(() {
          notifier.hideStuff = false;
        });
      });
    }
  }

  void _onExpandCollapse() {
    setState(() {
      notifier.hideStuff = true;

      chewieController.toggleFullScreen();
      _showAfterExpandCollapseTimer =
          Timer(const Duration(milliseconds: 300), () {
        setState(() {
          _cancelAndRestartTimer();
        });
      });
    });
  }

  void _playPause() {
    final isFinished = _latestValue.position >= _latestValue.duration;

    setState(() {
      if (controller.value.isPlaying) {
        notifier.hideStuff = false;
        _hideTimer?.cancel();
        controller.pause();
      } else {
        _cancelAndRestartTimer();

        if (!controller.value.isInitialized) {
          controller.initialize().then((_) {
            controller.play();
          });
        } else {
          if (isFinished) {
            controller.seekTo(Duration.zero);
          }
          controller.play();
        }
      }
    });
  }

  void _startHideTimer() {
    final hideControlsTimer = chewieController.hideControlsTimer.isNegative
        ? ChewieController.defaultHideControlsTimer
        : chewieController.hideControlsTimer;
    _hideTimer = Timer(hideControlsTimer, () {
      setState(() {
        notifier.hideStuff = true;
      });
    });
  }

  void _bufferingTimerTimeout() {
    // _displayBufferingIndicator = true;
    if (mounted) {
      setState(() {});
    }
  }

  void _updateState() {
    if (!mounted) return;

    // display the progress bar indicator only after the buffering delay if it has been set
    if (chewieController.progressIndicatorDelay != null) {
      if (controller.value.isBuffering) {
        _bufferingDisplayTimer ??= Timer(
          chewieController.progressIndicatorDelay!,
          _bufferingTimerTimeout,
        );
      } else {
        _bufferingDisplayTimer?.cancel();
        _bufferingDisplayTimer = null;
        // _displayBufferingIndicator = false;
      }
    } else {
      // _displayBufferingIndicator = controller.value.isBuffering;
    }

    setState(() {
      _latestValue = controller.value;
      // _subtitlesPosition = controller.value.position;
    });
  }

  Widget _buildProgressBar() {
    return Expanded(
      child: MaterialVideoProgressBar(
        controller,
        onDragStart: () {
          setState(() {
            _dragging = true;
          });

          _hideTimer?.cancel();
        },
        onDragUpdate: () {
          final pos = controller.value.position.inSeconds;
          final dur = controller.value.duration.inSeconds;
          tempX = pos / dur;
          tempX *= MediaQuery.of(context).size.width - 80;

          // print('pos = $pos');
          // print('dur = $dur');
          // print('tempX = $tempX');
          setState(() {});
        },
        onDragEnd: () {
          setState(() {
            _dragging = false;
          });

          _startHideTimer();
        },
        colors:
            chewieController.materialProgressColors ?? ChewieProgressColors(),
        sectionDurationRange: chewieController.sectionDurationRange,
        momentsList: chewieController.momentsList,
      ),
    );
  }
}
