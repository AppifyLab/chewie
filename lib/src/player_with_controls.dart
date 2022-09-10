import 'package:chewie/src/chewie_player.dart';
import 'package:chewie/src/material/material_desktop_controls.dart';
import 'package:chewie/src/notifiers/index.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

class PlayerWithControls extends StatelessWidget {
  const PlayerWithControls({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ChewieController chewieController = ChewieController.of(context);

    double _calculateAspectRatio(BuildContext context) {
      final size = MediaQuery.of(context).size;
      final width = size.width;
      final height = size.height;

      return width > height ? width / height : height / width;
    }

    Widget _buildControls(BuildContext context, ChewieController chewieController) {
      return chewieController.showControls ? chewieController.customControls ?? const MaterialDesktopControls() : Container();
    }

    Widget _buildPlayerWithControls(ChewieController chewieController, BuildContext context) {
      return Stack(
        children: <Widget>[
          if (chewieController.placeholder != null) chewieController.placeholder!,
          InteractiveViewer(
            transformationController: chewieController.transformationController,
            maxScale: chewieController.maxScale,
            panEnabled: chewieController.zoomAndPan,
            scaleEnabled: chewieController.zoomAndPan,
            child: Center(
              child: AspectRatio(
                aspectRatio: chewieController.aspectRatio ?? chewieController.videoPlayerController.value.aspectRatio,
                child:
                    //  DoubleTapPlayerView(
                    //   doubleTapConfig: DoubleTapConfig.create(
                    //     onDoubleTap: (lr) {
                    //       // print('double tapped: $lr');
                    //       if (lr == Lr.LEFT) {
                    //         chewieController.videoPlayerController
                    //             .seekTo(Duration(seconds: chewieController.videoPlayerController.value.position.inSeconds - 10));
                    //       } else {
                    //         chewieController.videoPlayerController
                    //             .seekTo(Duration(seconds: chewieController.videoPlayerController.value.position.inSeconds + 10));
                    //       }
                    //     },
                    //   ),
                    //   swipeConfig: SwipeConfig.create(overlayBuilder: _overlay),
                    //   child:
                    VideoPlayer(chewieController.videoPlayerController),
                // ),
              ),
            ),
          ),
          if (chewieController.overlay != null) chewieController.overlay!,
          if (Theme.of(context).platform != TargetPlatform.iOS)
            Consumer<PlayerNotifier>(
              builder: (
                BuildContext context,
                PlayerNotifier notifier,
                Widget? widget,
              ) =>
                  Visibility(
                visible: !notifier.hideStuff,
                child: AnimatedOpacity(
                  opacity: notifier.hideStuff ? 0.0 : 0.8,
                  duration: const Duration(milliseconds: 250),
                  child: DecoratedBox(
                    decoration: const BoxDecoration(color: Colors.black54),
                    child: Container(),
                  ),
                ),
              ),
            ),
          if (!chewieController.isFullScreen)
            _buildControls(context, chewieController)
          else
            SafeArea(
              bottom: false,
              child: _buildControls(context, chewieController),
            )
        ],
      );
    }

    return Center(
      child: SizedBox(
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        child: AspectRatio(
          aspectRatio: _calculateAspectRatio(context),
          child: _buildPlayerWithControls(chewieController, context),
        ),
      ),
    );
  }

  // Widget _overlay(SwipeData data) {
  //   final dxDiff = (data.currentDx - data.startDx).toInt();
  //   Duration diffDuration = Duration(seconds: dxDiff);
  //   final prefix = diffDuration.isNegative ? '-' : '+';
  //   final positionText = '$prefix${diffDuration.printDuration()}';
  //   final aimedDuration = diffDuration + const Duration(minutes: 5);
  //   final diffText = aimedDuration.printDuration();

  //   return Center(
  //     child: Column(
  //       mainAxisAlignment: MainAxisAlignment.center,
  //       children: [
  //         Text(
  //           positionText,
  //           style: const TextStyle(fontSize: 30, color: Colors.white),
  //         ),
  //         const SizedBox(height: 4),
  //         Text(
  //           diffText,
  //           style: const TextStyle(fontSize: 20, color: Colors.white),
  //         ),
  //       ],
  //     ),
  //   );
  // }

}
