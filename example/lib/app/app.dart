// ignore_for_file: implementation_imports

import 'package:chewie/chewie.dart';
import 'package:chewie/src/models/video_chapters_model.dart';
import 'package:chewie/src/models/video_moments_model.dart';
import 'package:chewie_example/app/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart';
// ignore: depend_on_referenced_packages
import 'package:video_player/video_player.dart';

class ChewieDemo extends StatefulWidget {
  const ChewieDemo({Key? key, this.title = 'Chewie Demo'}) : super(key: key);

  final String title;

  @override
  State<StatefulWidget> createState() {
    return _ChewieDemoState();
  }
}

class _ChewieDemoState extends State<ChewieDemo> {
  TargetPlatform? _platform;
  late VideoPlayerController _videoPlayerController1;
  late VideoPlayerController _videoPlayerController2;
  ChewieController? _chewieController;
  int? bufferDelay;

  @override
  void initState() {
    super.initState();
    initializePlayer();
  }

  @override
  void dispose() {
    _videoPlayerController1.dispose();
    _videoPlayerController2.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  List<String> sources = [
    "https://vz-7671715e-3da.b-cdn.net/12518df0-0200-4b88-883b-b3042aea7fa7/playlist.m3u8",
    "https://assets.mixkit.co/videos/preview/mixkit-spinning-around-the-earth-29351-large.mp4",
    "https://assets.mixkit.co/videos/preview/mixkit-daytime-city-traffic-aerial-view-56-large.mp4",
    "https://assets.mixkit.co/videos/preview/mixkit-a-girl-blowing-a-bubble-gum-at-an-amusement-park-1226-large.mp4"
  ];

  Future<ClosedCaptionFile> loadCaptions(String captionUrl) async {
    final Response response = await get(Uri.parse(captionUrl));

    // print('response body = ${response.body}');
    final fileContents = response.body;
    // print('fileContents = $fileContents');
    return SubRipCaptionFile(fileContents);
  }

  Future<void> initializePlayer() async {
    _videoPlayerController1 = VideoPlayerController.networkUrl(
      Uri.parse(sources[currentPlayIndex]),
      // closedCaptionFile: loadCaptions('https://letcheck.b-cdn.net/test.srt'),
    );
    _videoPlayerController2 =
        VideoPlayerController.networkUrl(Uri.parse(sources[currentPlayIndex]));
    await Future.wait([
      _videoPlayerController1.initialize(),
      _videoPlayerController2.initialize()
    ]);
    _createChewieController();
    setState(() {});
  }

  void _createChewieController() {
    _chewieController = ChewieController(
      showAirPlay: true,

      videoPlayerController: _videoPlayerController1,
      autoPlay: true,
      looping: true,
      progressIndicatorDelay:
          bufferDelay != null ? Duration(milliseconds: bufferDelay!) : null,
      additionalOptions: (context) {
        return <OptionItem>[
          OptionItem(
            onTap: toggleVideo,
            iconData: Icons.live_tv_sharp,
            title: 'Toggle Video Src',
          ),
        ];
      },
      // showDownloadOption: true,
      showAutoPlaySwitch: true,
      popupMenuButton: PopupMenuButton(
        icon: const Icon(Icons.more_vert, color: Colors.white),
        itemBuilder: (context) =>
            [const PopupMenuItem<String>(child: Text('test'))],
        padding: EdgeInsets.zero,
      ),
      onSwitchedAutoPlay: (value) {
        // print('value = $value');
      },
      sectionDurationRange: [
        VideoChaptersModel(
          title: 'Chapter 1',
          durationRange:
              DurationRange(Duration.zero, const Duration(seconds: 20)),
        ),
        VideoChaptersModel(
          title: 'Chapter 2',
          durationRange: DurationRange(
              const Duration(seconds: 20), const Duration(seconds: 50)),
        ),
        VideoChaptersModel(
          title: 'Chapter 3',
          durationRange: DurationRange(
              const Duration(seconds: 50), const Duration(seconds: 163)),
        ),
      ],
      momentsList: [
        VideoMomentsModel(
          title: 'Moment 1',
          timestamp: 10,
        ),
        VideoMomentsModel(
          title: 'Moment 2',
          timestamp: 20,
        ),
      ],
      hideControlsTimer: const Duration(seconds: 1),
      deviceOrientationsAfterFullScreen: [DeviceOrientation.portraitUp],
      deviceOrientationsOnEnterFullScreen: [
        DeviceOrientation.portraitUp,
        DeviceOrientation.landscapeRight,
        DeviceOrientation.landscapeLeft
      ],
    );
  }

  int currentPlayIndex = 0;

  Future<void> toggleVideo() async {
    await _videoPlayerController1.pause();
    currentPlayIndex += 1;
    if (currentPlayIndex >= sources.length) {
      currentPlayIndex = 0;
    }
    await initializePlayer();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: widget.title,
      theme: AppTheme.light.copyWith(
        platform: _platform ?? Theme.of(context).platform,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
        ),
        body: Column(
          children: <Widget>[
            SizedBox(
              height: 220,
              child: Center(
                child: _chewieController != null &&
                        _chewieController!
                            .videoPlayerController.value.isInitialized
                    ? Chewie(controller: _chewieController!)
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          CircularProgressIndicator(),
                          SizedBox(height: 20),
                          Text('Loading'),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
