import 'dart:async';
import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pod_player/pod_player.dart';
import 'package:video_player/video_player.dart';

class FullScreenVideoPlayer extends StatefulWidget {
  final String name;
  final VideoPlayerController videoPlayerController;

  const FullScreenVideoPlayer(this.videoPlayerController,
      {super.key, required this.name});

  @override
  State<FullScreenVideoPlayer> createState() => _FullScreenVideoPlayerState();
}

class _FullScreenVideoPlayerState extends State<FullScreenVideoPlayer> {
  late ChewieController chewieController;

  // متغيرات لتحديد مكان النص
  double _watermarkPositionX = 0.0;
  double _watermarkPositionY = 0.0;
  late Timer _timer;

  @override
  void initState() {
    super.initState();

    // إعداد ChewieController
    chewieController = ChewieController(
      videoPlayerController: widget.videoPlayerController,


      // overlay: Align(
      //   alignment: Alignment.center,
      //   child: Text(widget.name,style: TextStyle(
      //     fontSize: 50,  // زيادة حجم الخط
      //     color: Colors.white.withOpacity(0.1),  // تقليل الشفافية لجعل النص أكثر وضوحاً
      //     fontWeight: FontWeight.bold,
      //     backgroundColor: Colors.black.withOpacity(0.1), // خلفية مظللة لتوضيح النص
      //   ),),
      // ),
    );

    // إعداد الـ Timer لتحريك النص
    _timer = Timer.periodic(Duration(seconds: 3), (timer) {
      setState(() {
        if (_watermarkPositionX == 0.0 && _watermarkPositionY == 0.0) {
          // تحريك النص نحو المنتصف
          _watermarkPositionX = 0.5; // المنتصف أفقياً
          _watermarkPositionY = 0.5; // المنتصف رأسياً
        } else {
          // العودة إلى الزاوية العلوية اليسرى
          _watermarkPositionX = 0.0;
          _watermarkPositionY = 0.0;
        }
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel(); // إيقاف الـ Timer عند التخلص من الشاشة
    chewieController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: true,
        top: true,
        child: Stack(
          children: [
            // عرض الفيديو باستخدام Chewie
            Chewie(
              controller: chewieController,
            ),
            AnimatedPositioned(
              duration: Duration(seconds: 1),
              // مدة الحركة
              // الحساب لتحديد مكان العلامة المائية أفقيًا ورأسيًا في وسط الفيديو
              right: _watermarkPositionX == 0.0
                  ? 20 // الزاوية العلوية اليسرى
                  : (MediaQuery.of(context).size.width / 2) - 100,
              // المنتصف أفقياً (للسهولة، قمنا بطرح 100 لأن عرض النص سيكون 200 تقريبًا)
              top: _watermarkPositionY ==
                      (MediaQuery.of(context).size.height / 2)
                  ? 20 // الزاوية العلوية اليسرى
                  : (MediaQuery.of(context).size.height / 2) - 50,
              // المنتصف رأسياً (حيث أن ارتفاع الشاشة هو 250، نقوم بتحديد المنتصف عن طريق الحساب)
              child: Container(
                padding: EdgeInsets.all(8),
                color: Colors.transparent,
                child: Text(
                  widget.name,
                  style: TextStyle(
                    fontSize: 10, // حجم الخط
                    color: Colors.black.withOpacity(0.5), // شفافية النص
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            // أزرار التقديم والتأخير
            Positioned(
              bottom: 50,
              left: 20,
              right: 20,
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // زر التأخير
                    GestureDetector(
                      onTap: () {
                        final currentPosition =
                            widget.videoPlayerController.value.position;
                        final rewindPosition =
                            currentPosition - Duration(seconds: 10);
                        widget.videoPlayerController.seekTo(
                          rewindPosition > Duration.zero
                              ? rewindPosition
                              : Duration.zero,
                        );
                      },
                      child: Container(
                        width: 25,
                        height: 25,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          // color: Colors.black.withOpacity(0.5),
                        ),
                        child: Icon(
                          Icons.replay_10,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                    ),
                    SizedBox(width: 20),
                    // زر التقديم
                    GestureDetector(
                      onTap: () {
                        final currentPosition =
                            widget.videoPlayerController.value.position;
                        final maxDuration =
                            widget.videoPlayerController.value.duration;
                        final forwardPosition =
                            currentPosition + Duration(seconds: 10);
                        widget.videoPlayerController.seekTo(
                          forwardPosition < maxDuration
                              ? forwardPosition
                              : maxDuration,
                        );
                      },
                      child: Container(
                        width: 25,
                        height: 25,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          // color: Colors.black.withOpacity(0.5),
                        ),
                        child: Icon(
                          Icons.forward_10,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                    ),
                  ]),
            ),
          ],
        ),
      ),
    );
  }
}

class FullScreenVideoPlayerPod extends StatefulWidget {
  final String name;
  final PodPlayerController podPlayerController;

  const FullScreenVideoPlayerPod({
    super.key,
    required this.podPlayerController,
    required this.name,
  });

  @override
  State<FullScreenVideoPlayerPod> createState() => _FullScreenVideoPlayerPodState();
}

class _FullScreenVideoPlayerPodState extends State<FullScreenVideoPlayerPod> {
  // متغيرات لتحديد مكان النص
  double _watermarkPositionX = 0.0;
  double _watermarkPositionY = 0.0;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    
    // Set landscape orientation
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    // إعداد الـ Timer لتحريك النص
    _timer = Timer.periodic(Duration(seconds: 3), (timer) {
      if(mounted){
        setState(() {
          if (_watermarkPositionX == 0.0 && _watermarkPositionY == 0.0) {
            // تحريك النص نحو المنتصف
            _watermarkPositionX = 0.5; // المنتصف أفقياً
            _watermarkPositionY = 0.5; // المنتصف رأسياً
          } else {
            // العودة إلى الزاوية العلوية اليسرى
            _watermarkPositionX = 0.0;
            _watermarkPositionY = 0.0;
          }
        });
      }
    });

    // Play video when entering fullscreen
    widget.podPlayerController.play();
  }

  @override
  void dispose() {
    _timer.cancel(); // إيقاف الـ Timer عند التخلص من الشاشة
    // Reset orientation
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        bottom: true,
        top: true,
        child: Stack(
          children: [
            // عرض الفيديو باستخدام PodPlayer
            SizedBox(
              height: MediaQuery.of(context).size.height,
              width: MediaQuery.of(context).size.width,
              child: PodVideoPlayer(
                controller: widget.podPlayerController,
                alwaysShowProgressBar: true,
                podProgressBarConfig: const PodProgressBarConfig(
                  circleHandlerColor: Colors.red,
                  backgroundColor: Colors.white24,
                ),
              ),
            ),
            // Back button
            Positioned(
              top: 20,
              left: 20,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ),
            AnimatedPositioned(
              duration: Duration(seconds: 1),
              // مدة الحركة
              // الحساب لتحديد مكان العلامة المائية أفقيًا ورأسيًا في وسط الفيديو
              right: _watermarkPositionX == 0.0
                  ? 20 // الزاوية العلوية اليسرى
                  : (MediaQuery.of(context).size.width / 2) - 100,
              // المنتصف أفقياً (للسهولة، قمنا بطرح 100 لأن عرض النص سيكون 200 تقريبًا)
              top: _watermarkPositionY == 0.0
                  ? 20 // الزاوية العلوية اليسرى
                  : (MediaQuery.of(context).size.height / 2) - 50,
              // المنتصف رأسياً
              child: Container(
                padding: EdgeInsets.all(8),
                color: Colors.transparent,
                child: Text(
                  widget.name,
                  style: TextStyle(
                    fontSize: 10, // حجم الخط
                    color: Colors.white.withOpacity(0.7), // شفافية النص
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            // أزرار التقديم والتأخير
            Positioned(
              bottom: 50,
              left: 20,
              right: 20,
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // زر التأخير
                    GestureDetector(
                      onTap: () {
                        // Rewind functionality - pod_player handles this via double-tap
                        // Using pod_player's built-in double-tap to seek instead
                      },
                      child: Container(
                        width: 25,
                        height: 25,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.replay_10,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                    ),
                    SizedBox(width: 20),
                    // زر التقديم
                    GestureDetector(
                      onTap: () {
                        // Forward functionality - pod_player handles this via double-tap
                        // Using pod_player's built-in double-tap to seek instead
                      },
                      child: Container(
                        width: 25,
                        height: 25,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.forward_10,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                    ),
                  ]),
            ),
          ],
        ),
      ),
    );
  }
}
