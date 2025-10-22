import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// import 'package:headset_connection_event/headset_event.dart';
import 'package:modern_player/modern_player.dart';
import 'full_screen_video_page.dart'; // استيراد صفحة ملء الشاشة
import 'dart:async'; // استيراد مكتبة Timer

class PodVideoPlayerDev extends StatefulWidget {
  final String type;
  final String url;
  final String name;
  final RouteObserver<ModalRoute<void>> routeObserver;

  const PodVideoPlayerDev(this.url, this.type, this.routeObserver, {super.key, required this.name});

  @override
  State<PodVideoPlayerDev> createState() => _VimeoVideoPlayerState();
}

class _VimeoVideoPlayerState extends State<PodVideoPlayerDev> {
  bool _isFullScreen = false;
  double _watermarkPositionX = 0.0;  // متغير لتحديد مكان العلامة المائية أفقياً
  double _watermarkPositionY = 0.0;  // متغير لتحديد مكان العلامة المائية رأسياً
  late Timer _timer;

  // دالة لتبديل الوضع بين ملء الشاشة والوضع الطبيعي
  void _toggleFullScreen() {
    setState(() {
      _isFullScreen = !_isFullScreen;
    });

    if (_isFullScreen) {
      // الانتقال إلى الوضع الأفقي (ملء الشاشة)
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FullScreenVideoPage(url: widget.url, name: widget.name),
        ),
      ).then((_) {
        // إعادة تعيين الحالة بعد العودة من ملء الشاشة
        setState(() {

          SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
          _isFullScreen = false;
          SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
        });
          SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
      });
    }
  }
  // final _headsetPlugin = HeadsetEvent();
  // HeadsetState? _headsetState;

  @override
  void initState() {
    super.initState();
    ///Request Permissions (Required for Android 12)
    // _headsetPlugin.requestPermission();


    /// if headset is plugged
    // _headsetPlugin.getCurrentState.then((_val) {
    //   setState(() {
    //     _headsetState = _val;
    //     print(_headsetState);
    //     print("_headsetState1");
    //   });
    // });

    /// Detect the moment headset is plugged or unplugged
    // _headsetPlugin.setListener((_val) {
    //   setState(() {
    //     _headsetState = _val;
    //     print(_headsetState);
    //     print("_headsetState2");
    //   });
    // });




    // إعداد الـ Timer لتحريك العلامة المائية كل 3 ثواني
    _timer = Timer.periodic(Duration(seconds: 3), (timer) {
      setState(() {
        // التبديل بين مكانين مختلفين للعلامة المائية: من الزاوية العلوية اليسرى إلى المنتصف
        if (_watermarkPositionX == 0.0 && _watermarkPositionY == 0.0) {
          _watermarkPositionX = 0.5; // التحرك نحو المنتصف أفقياً
          _watermarkPositionY = 0.5; // التحرك نحو المنتصف رأسياً
        } else {
          _watermarkPositionX = 0.0; // العودة إلى الزاوية العلوية اليسرى أفقياً
          _watermarkPositionY = 0.0; // العودة إلى الزاوية العلوية اليسرى رأسياً
        }
      });
    });
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  }

  @override
  void dispose() {
    // إلغاء الـ Timer عند تدمير الـ widget لتجنب التسريبات
    _timer.cancel();
    super.dispose();
  }

  @override
  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Padding(
        padding: const EdgeInsets.only(top: 16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            height: 400, // ارتفاع العرض الطبيعي
            width: MediaQuery.of(context).size.width,
            child: // إذا كانت السماعة متصلة، عرض الفيديو
            Stack(
              children: [
                SizedBox(
                  height: 250,
                  width: MediaQuery.of(context).size.width,
                  child: ModernPlayer.createPlayer(
                    options: ModernPlayerOptions(),
                    controlsOptions: ModernPlayerControlsOptions(
                      showControls: true,
                      doubleTapToSeek: true,
                      showMenu: true,
                      showMute: false,
                      showBackbutton: false,
                      enableVolumeSlider: true,
                      enableBrightnessSlider: true,
                      showBottomBar: true,
                      customActionButtons: [
                        ModernPlayerCustomActionButton(
                          onPressed: _toggleFullScreen,
                          icon: Icon(
                            _isFullScreen ? Icons.fullscreen_exit : Icons.fullscreen,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    defaultSelectionOptions: ModernPlayerDefaultSelectionOptions(
                      defaultQualitySelectors: [DefaultSelectorLabel('360p')],
                    ),
                    video: ModernPlayerVideo.youtubeWithUrl(
                      url: widget.url,
                      fetchQualities: true,
                    ),
                  ),
                ),
                // العلامة المائية
                AnimatedPositioned(
                  duration: Duration(seconds: 1),
                  left: _watermarkPositionX == 0.0
                      ? 0
                      : (MediaQuery.of(context).size.width / 2) - 100,
                  top: _watermarkPositionY == 0.0 ? 0 : (250 / 2) - 50,
                  child: Container(
                    padding: EdgeInsets.all(8),
                    color: Colors.transparent,
                    child: Text(
                      widget.name,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.white.withOpacity(0.5),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            )
             
          ),
        ),
      ),
    );
  }

}
