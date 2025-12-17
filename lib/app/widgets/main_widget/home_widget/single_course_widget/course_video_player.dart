import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pod_player/pod_player.dart';
import 'package:webinar/app/widgets/main_widget/home_widget/single_course_widget/full_screen_video_player.dart';
import 'package:webinar/common/utils/date_formater.dart';
import 'package:webinar/common/utils/download_manager.dart';
import 'package:webinar/config/assets.dart';
import 'package:webinar/config/colors.dart';
import 'package:webinar/config/styles.dart';

import '../../../../../common/common.dart';

class CourseVideoPlayer extends StatefulWidget {
  final String url;
  final String name;
  final String imageCover;

  final bool isLoadNetwork;
  final String? localFileName;
  final RouteObserver<ModalRoute<void>> routeObserver;

  const CourseVideoPlayer(this.url, this.imageCover, this.routeObserver,
      {this.isLoadNetwork = true,
      this.localFileName,
      super.key,
      required this.name});

  @override
  State<CourseVideoPlayer> createState() => _CourseVideoPlayerState();
}

class _CourseVideoPlayerState extends State<CourseVideoPlayer> with RouteAware {
  PodPlayerController? _podPlayerController;
  bool isShowPlayButton = false;
  bool isPlaying = false;
  bool isMuted = false;

  Duration videoDuration = const Duration(seconds: 0);
  Duration videoPosition = const Duration(seconds: 0);

  bool isShowVideoPlayer = false;
  bool isInitialized = false;

  // متغيرات لتحديد مكان النص
  double _watermarkPositionX = 0.0;
  double _watermarkPositionY = 0.0;
  late Timer _timer;
  Timer? _positionTimer;

  @override
  void initState() {
    super.initState();
    initVideo();

    // إعداد الـ Timer لتحريك النص
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      setState(() {
        if (_watermarkPositionX == 0.0 && _watermarkPositionY == 0.0) {
          _watermarkPositionX = 0.5; // التحرك نحو المنتصف أفقياً
          _watermarkPositionY = 0.5; // التحرك نحو المنتصف رأسياً
        } else {
          _watermarkPositionX = 0.0; // العودة إلى الزاوية العلوية اليسرى
          _watermarkPositionY = 0.0; // العودة إلى الزاوية العلوية اليسرى
        }
      });
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    widget.routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    widget.routeObserver.unsubscribe(this);
    _timer.cancel();
    _positionTimer?.cancel();
    _podPlayerController?.dispose();
    super.dispose();
  }

  @override
  void didPush() {}

  @override
  void didPushNext() {
    _podPlayerController?.pause();
  }

  @override
  void didPopNext() {
    _podPlayerController?.play();
  }

  initVideo() async {
    if (widget.isLoadNetwork) {
      try {
        _podPlayerController = PodPlayerController(
          playVideoFrom: PlayVideoFrom.network(widget.url),
          podPlayerConfig: const PodPlayerConfig(
            autoPlay: true,
            isLooping: false,
            // جميع الجودات المتاحة: 2160p, 1440p, 1080p, 720p, 480p, 360p, 240p
            videoQualityPriority: [2160, 1440, 1080, 720, 480, 360, 240],
          ),
        )..initialise().then((_) {
            print('تم تهيئة pod_player بنجاح مع جميع الجودات المتاحة');
            if (mounted) {
              isShowVideoPlayer = true;
              isInitialized = true;
              controllerListener();
              setState(() {});
            }
          }).catchError((error) {
            print('PodPlayer initialization error: $error');
            if (mounted) {
              setState(() {
                isShowVideoPlayer = false;
              });
            }
          });
      } catch (e) {
        print('Error initializing PodPlayer: $e');
        if (mounted) {
          setState(() {
            isShowVideoPlayer = false;
          });
        }
      }
    } else {
      String directory = (await getApplicationSupportDirectory()).path;
      print('${directory.toString()}/${widget.localFileName}');

      bool isExistFile = await DownloadManager.findFile(
          directory, widget.localFileName!,
          isOpen: false);

      if (isExistFile) {
        try {
          final filePath = '${directory.toString()}/${widget.localFileName}';
          _podPlayerController = PodPlayerController(
            playVideoFrom: PlayVideoFrom.file(File(filePath)),
            podPlayerConfig: const PodPlayerConfig(
              autoPlay: true,
              isLooping: false,
            ),
          )..initialise().then((_) {
              if (mounted) {
                isShowVideoPlayer = true;
                isInitialized = true;
                controllerListener();
                setState(() {});
              }
            }).catchError((error) {
              print('PodPlayer file initialization error: $error');
              if (mounted) {
                setState(() {
                  isShowVideoPlayer = false;
                });
              }
            });
        } catch (e) {
          print('Error initializing PodPlayer from file: $e');
          if (mounted) {
            setState(() {
              isShowVideoPlayer = false;
            });
          }
        }
      }
    }
  }

  void _showQualitySelector(BuildContext context) {
    // قائمة بجميع الجودات المتاحة - جميع الجودات معروضة
    final List<Map<String, dynamic>> qualities = [
      {
        'label': 'تلقائي (أفضل جودة متاحة)',
        'quality': null,
        'priority': [1080, 720, 480, 360, 240]
      },
      {
        'label': '1080p (Full HD)',
        'quality': 1080,
        'priority': [1080]
      },
      {
        'label': '720p (HD)',
        'quality': 720,
        'priority': [720]
      },
      {
        'label': '480p (SD)',
        'quality': 480,
        'priority': [480]
      },
      {
        'label': '360p',
        'quality': 360,
        'priority': [360]
      },
      {
        'label': '240p',
        'quality': 240,
        'priority': [240]
      },
    ];

    print('عرض قائمة الجودة - عدد الجودات: ${qualities.length}');
    for (var quality in qualities) {
      print('  - ${quality['label']}');
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              child: const Text(
                'اختر جودة الفيديو',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Divider(),
            Expanded(
              child: ListView.builder(
                shrinkWrap: true,
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: qualities.length,
                itemBuilder: (context, index) {
                  final quality = qualities[index];
                  return ListTile(
                    leading: const Icon(Icons.high_quality, color: Colors.blue),
                    title: Text(
                      quality['label'] as String,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      Navigator.pop(context);
                      print('تم اختيار الجودة: ${quality['label']}');
                      if (quality['quality'] == null) {
                        // تلقائي - استخدام جميع الجودات
                        print(
                            'تطبيق الجودة التلقائية مع الأولويات: ${quality['priority']}');
                        _changeQualityWithPriority(
                            quality['priority'] as List<int>);
                      } else {
                        // جودة محددة
                        print('تطبيق الجودة المحددة: ${quality['quality']}');
                        _changeQuality(quality['quality'] as int);
                      }
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _changeQualityWithPriority(List<int> priorities) {
    if (_podPlayerController == null) return;

    try {
      final wasPlaying = isPlaying;

      _podPlayerController?.dispose();

      _podPlayerController = PodPlayerController(
        playVideoFrom: PlayVideoFrom.network(widget.url),
        podPlayerConfig: PodPlayerConfig(
          autoPlay: wasPlaying,
          isLooping: false,
          videoQualityPriority: priorities,
        ),
      )..initialise().then((_) {
          if (mounted) {
            isShowVideoPlayer = true;
            isInitialized = true;
            controllerListener();
            if (wasPlaying) {
              _podPlayerController?.play();
            }
            setState(() {});
          }
        });
    } catch (e) {
      print('Error changing quality with priority: $e');
    }
  }

  void _changeQuality(int quality) {
    if (_podPlayerController == null) return;

    try {
      // إعادة تهيئة المشغل بالجودة المحددة
      final wasPlaying = isPlaying;

      _podPlayerController?.dispose();

      // استخدام قائمة أولويات تبدأ بالجودة المحددة ثم باقي الجودات كبدائل
      final qualityPriority = [
        quality,
        ...([1080, 720, 480, 360, 240]..remove(quality))
      ];

      _podPlayerController = PodPlayerController(
        playVideoFrom: PlayVideoFrom.network(widget.url),
        podPlayerConfig: PodPlayerConfig(
          autoPlay: wasPlaying,
          isLooping: false,
          videoQualityPriority: qualityPriority,
        ),
      )..initialise().then((_) {
          if (mounted) {
            isShowVideoPlayer = true;
            isInitialized = true;
            controllerListener();
            if (wasPlaying) {
              // محاولة الانتقال إلى نفس الموضع
              Future.delayed(const Duration(milliseconds: 500), () {
                if (mounted && _podPlayerController != null) {
                  try {
                    // pod_player قد لا يدعم seekTo مباشرة، لذا سنبدأ التشغيل فقط
                    _podPlayerController?.play();
                  } catch (e) {
                    print('Error seeking: $e');
                  }
                }
              });
            }
            setState(() {});
          }
        }).catchError((error) {
          print('PodPlayer quality change error: $error');
          // في حالة الخطأ، إعادة المحاولة بجودة تلقائية
          if (mounted) {
            _changeQualityWithPriority([1080, 720, 480, 360, 240]);
          }
        });
    } catch (e) {
      print('Error changing quality: $e');
      // في حالة الخطأ، إعادة المحاولة بجودة تلقائية
      _changeQualityWithPriority([1080, 720, 480, 360, 240]);
    }
  }

  controllerListener() {
    if (_podPlayerController == null) return;

    // Listen to video position updates
    _positionTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      final currentPosition = _podPlayerController!.currentVideoPosition;

      if (videoPosition.inSeconds != currentPosition.inSeconds) {
        setState(() {
          videoPosition = currentPosition;
        });
      }

      // Duration will be updated when available from pod_player
      // For now, we'll rely on pod_player's built-in duration display
    });

    // Listen to play/pause state - pod_player manages this internally
    // We'll track play/pause state via button clicks
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // video
        if (isShowVideoPlayer && _podPlayerController != null) ...{
          ClipRRect(
            borderRadius: borderRadius(),
            child: isInitialized
                ? Stack(
                    children: [
                      SizedBox(
                        height: 250,
                        width: MediaQuery.of(context).size.width,
                        child: Stack(
                          children: [
                            PodVideoPlayer(
                              controller: _podPlayerController!,
                              alwaysShowProgressBar: true,
                              podProgressBarConfig: const PodProgressBarConfig(
                                circleHandlerColor: Colors.red,
                                backgroundColor: Colors.white24,
                              ),
                            ),
                            // زر اختيار الجودة
                            Positioned(
                              top: 8,
                              right: 8,
                              child: GestureDetector(
                                onTap: () {
                                  _showQualitySelector(context);
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.6),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.high_quality,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        'جودة',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      AnimatedPositioned(
                        duration: const Duration(seconds: 1), // مدة الحركة
                        left: _watermarkPositionX == 0.0
                            ? 0 // الزاوية العلوية اليسرى
                            : (MediaQuery.of(context).size.width / 2) -
                                100, // المنتصف أفقياً
                        top: _watermarkPositionY == 0.0
                            ? 0 // الزاوية العلوية اليسرى
                            : (250 / 2) - 50, // المنتصف رأسياً
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          color: Colors.transparent,
                          child: Text(
                            widget.name,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.7),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),

                      // play or pause button
                      Positioned.fill(
                        child: GestureDetector(
                          onTap: () {
                            if (isPlaying) {
                              _podPlayerController?.pause();
                            } else {
                              _podPlayerController?.play();
                            }
                          },
                          behavior: HitTestBehavior.opaque,
                          child: Center(
                            child: AnimatedOpacity(
                              opacity: isShowPlayButton ? 1.0 : 0.0,
                              duration: const Duration(milliseconds: 400),
                              child: Container(
                                width: 65,
                                height: 65,
                                decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.black.withOpacity(.3)),
                                child: Icon(
                                  !isPlaying
                                      ? Icons.play_arrow_rounded
                                      : Icons.pause_rounded,
                                  color: Colors.white,
                                  size: 35,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                : AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Image.network(
                      widget.imageCover,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Image.asset(
                          AppAssets.placePng,
                          width: getSize().width,
                          height: getSize().width,
                        );
                      },
                    ),
                  ),
          ),
          space(12),
          AnimatedCrossFade(
              firstChild: Container(
                padding: padding(horizontal: 16, vertical: 16),
                width: getSize().width,
                decoration: BoxDecoration(
                    color: Colors.white, borderRadius: borderRadius()),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // duration and play button
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              isPlaying = !isPlaying;
                              isShowPlayButton = true;
                            });
                            if (isPlaying) {
                              _podPlayerController?.pause();
                            } else {
                              _podPlayerController?.play();
                            }
                            Future.delayed(const Duration(milliseconds: 1500))
                                .then((value) {
                              if (mounted) {
                                setState(() {
                                  isShowPlayButton = false;
                                });
                              }
                            });
                          },
                          behavior: HitTestBehavior.opaque,
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: greyE7,
                                )),
                            child: Icon(
                              !isPlaying
                                  ? Icons.play_arrow_rounded
                                  : Icons.pause,
                              size: 17,
                            ),
                          ),
                        ),

                        space(0, width: 16),

                        // Duration display - pod_player shows this in its built-in controls
                        // Keeping minimal display here
                        if (videoPosition.inSeconds > 0)
                          Text(
                            secondDurationToString(videoPosition.inSeconds),
                            style: style12Regular().copyWith(color: greyB2),
                          ),
                      ],
                    ),

                    // Note: Rewind/Forward and Volume controls are handled by pod_player's built-in controls
                    // Custom controls removed to avoid API compatibility issues

                    // full screen
                    GestureDetector(
                      onTap: () async {
                        if (_podPlayerController != null) {
                          _podPlayerController!.pause();

                          await navigatorKey.currentState!.push(
                              MaterialPageRoute(
                                  builder: (context) =>
                                      FullScreenVideoPlayerPod(
                                        podPlayerController:
                                            _podPlayerController!,
                                        name: widget.name,
                                      )));

                          SystemChrome.setPreferredOrientations([
                            DeviceOrientation.portraitUp,
                          ]);
                        }
                      },
                      behavior: HitTestBehavior.opaque,
                      child: SvgPicture.asset(AppAssets.fullscreenSvg),
                    ),
                  ],
                ),
              ),
              secondChild: SizedBox(width: getSize().width),
              crossFadeState: isInitialized
                  ? CrossFadeState.showFirst
                  : CrossFadeState.showSecond,
              duration: const Duration(milliseconds: 300))
        },
      ],
    );
  }
}
