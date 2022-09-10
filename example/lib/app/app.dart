import 'package:chewie/chewie.dart';
import 'package:chewie_example/app/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart';
// ignore: depend_on_referenced_packages
import 'package:video_player/video_player.dart';

class ChewieDemo extends StatefulWidget {
  const ChewieDemo({
    Key? key,
    this.title = 'Chewie Demo',
  }) : super(key: key);

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

  List<String> srcs = [
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
    _videoPlayerController1 = VideoPlayerController.network(
      srcs[currPlayIndex],
      closedCaptionFile: loadCaptions('https://letcheck.b-cdn.net/test.srt'),
    );
    _videoPlayerController2 = VideoPlayerController.network(srcs[currPlayIndex]);
    await Future.wait([_videoPlayerController1.initialize(), _videoPlayerController2.initialize()]);
    _createChewieController();
    setState(() {});
  }

  void _createChewieController() {
    // final subtitles = [
    //     Subtitle(
    //       index: 0,
    //       start: Duration.zero,
    //       end: const Duration(seconds: 10),
    //       text: 'Hello from subtitles',
    //     ),
    //     Subtitle(
    //       index: 0,
    //       start: const Duration(seconds: 10),
    //       end: const Duration(seconds: 20),
    //       text: 'Whats up? :)',
    //     ),
    //   ];

    // final subtitles = [
    //   Subtitle(
    //     index: 0,
    //     start: Duration.zero,
    //     end: const Duration(seconds: 10),
    //     text: const TextSpan(
    //       children: [
    //         TextSpan(
    //           text: 'Hello',
    //           style: TextStyle(color: Colors.red, fontSize: 22),
    //         ),
    //         TextSpan(
    //           text: ' from ',
    //           style: TextStyle(color: Colors.green, fontSize: 20),
    //         ),
    //         TextSpan(
    //           text: 'subtitles',
    //           style: TextStyle(color: Colors.blue, fontSize: 18),
    //         )
    //       ],
    //     ),
    //   ),
    //   Subtitle(
    //     index: 0,
    //     start: const Duration(seconds: 10),
    //     end: const Duration(seconds: 20),
    //     text: 'Whats up? :)',
    //     // text: const TextSpan(
    //     //   text: 'Whats up? :)',
    //     //   style: TextStyle(color: Colors.amber, fontSize: 22, fontStyle: FontStyle.italic),
    //     // ),
    //   ),
    // ];

    _chewieController = ChewieController(
      videoPlayerController: _videoPlayerController1,
      autoPlay: true,
      looping: true,
      progressIndicatorDelay: bufferDelay != null ? Duration(milliseconds: bufferDelay!) : null,

      additionalOptions: (context) {
        return <OptionItem>[
          OptionItem(
            onTap: toggleVideo,
            iconData: Icons.live_tv_sharp,
            title: 'Toggle Video Src',
          ),
        ];
      },
      // subtitleBuilder: (context, dynamic subtitle) => Container(),
      // subtitle: Subtitles([]),
      // showSubtitle: true,
      // subtitle: Subtitles([]),
      // subtitleBuilder: (context, dynamic subtitle) => Container(
      //   padding: const EdgeInsets.all(10.0),
      //   child: Text(
      //     subtitle.toString(),
      //     style: const TextStyle(color: Colors.black),
      //   ),
      // ),
      showDownloadOption: true,
      hideControlsTimer: const Duration(seconds: 1),
      deviceOrientationsAfterFullScreen: [DeviceOrientation.portraitUp],
      deviceOrientationsOnEnterFullScreen: [DeviceOrientation.portraitUp, DeviceOrientation.landscapeRight, DeviceOrientation.landscapeLeft],

      // Try playing around with some of these other options:

      // showControls: false,
      // materialProgressColors: ChewieProgressColors(
      //   playedColor: Colors.red,
      //   handleColor: Colors.blue,
      //   backgroundColor: Colors.grey,
      //   bufferedColor: Colors.lightGreen,
      // ),
      // placeholder: Container(
      //   color: Colors.grey,
      // ),
      // autoInitialize: true,
    );
  }

  int currPlayIndex = 0;

  Future<void> toggleVideo() async {
    await _videoPlayerController1.pause();
    currPlayIndex += 1;
    if (currPlayIndex >= srcs.length) {
      currPlayIndex = 0;
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
                child: _chewieController != null && _chewieController!.videoPlayerController.value.isInitialized
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
