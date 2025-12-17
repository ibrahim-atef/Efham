import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:modern_player/modern_player.dart';
import 'package:pod_player/pod_player.dart';

class FullScreenVideoPage extends StatefulWidget {
  final String url;
  final String name;

  const FullScreenVideoPage({super.key, required this.url, required this.name});

  @override
  _FullScreenVideoPageState createState() => _FullScreenVideoPageState();
}

class _FullScreenVideoPageState extends State<FullScreenVideoPage> {
  double _watermarkPositionX = 0.0; // متغير لتحديد مكان العلامة المائية أفقياً
  double _watermarkPositionY = 0.0; // متغير لتحديد مكان العلامة المائية رأسياً
  late Timer _timer;
  PodPlayerController? _podPlayerController;

  @override
  void initState() {
    super.initState();
    // تهيئة PodPlayer
    _initializePodPlayer();
    // إعداد الـ Timer لتحريك العلامة المائية كل 3 ثواني
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
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
  }

  // دالة لتهيئة PodPlayer
  void _initializePodPlayer() {
    try {
      String videoId = '';
      if (widget.url.contains('youtube.com/watch?v=')) {
        videoId = widget.url.split('v=')[1].split('&')[0];
      } else if (widget.url.contains('youtu.be/')) {
        videoId = widget.url.split('youtu.be/')[1].split('?')[0];
      } else if (widget.url.contains('youtube.com/embed/')) {
        videoId = widget.url.split('embed/')[1].split('?')[0];
      }

      if (videoId.isNotEmpty) {
        final videoUrl = 'https://www.youtube.com/watch?v=$videoId';
        _podPlayerController = PodPlayerController(
          playVideoFrom: PlayVideoFrom.youtube(videoUrl),
          podPlayerConfig: const PodPlayerConfig(
            autoPlay: true,
            isLooping: false,
            videoQualityPriority: [2160, 1440, 1080, 720, 480, 360, 240],
          ),
        )..initialise();
      }
    } catch (e) {
      print('Error initializing PodPlayer: $e');
    }
  }

  // دالة لبناء مشغل الفيديو
  Widget _buildVideoPlayer() {
    if (_podPlayerController == null) {
      return Container(
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(
            color: Colors.white,
          ),
        ),
      );
    }

    return SizedBox(
      height: MediaQuery.of(context).size.height,
      width: MediaQuery.of(context).size.width,
      child: PodVideoPlayer(
        controller: _podPlayerController!,
        alwaysShowProgressBar: true,
        podProgressBarConfig: const PodProgressBarConfig(
          circleHandlerColor: Colors.red,
          backgroundColor: Colors.white24,
        ),
      ),
    );
  }

  // دالة لتحويل رابط YouTube إلى رابط embed محسّن
  String _getYouTubeEmbedUrl(String url) {
    // إذا كان الرابط فارغاً، إرجاعه كما هو
    if (url.isEmpty) {
      return url;
    }

    // إذا كان الرابط يحتوي على embed بالفعل، استخدمه مباشرة
    if (url.contains('youtube.com/embed/')) {
      return url;
    }

    String videoId = '';

    // استخراج معرف الفيديو من روابط مختلفة
    if (url.contains('youtube.com/watch?v=')) {
      videoId = url.split('v=')[1].split('&')[0];
    } else if (url.contains('youtu.be/')) {
      videoId = url.split('youtu.be/')[1].split('?')[0];
    }

    if (videoId.isNotEmpty) {
      // استخدام رابط embed مباشر بدون HTML wrapper
      return 'https://www.youtube.com/embed/$videoId?'
          'autoplay=1&'
          'rel=0&'
          'modestbranding=1&'
          'controls=1&'
          'fs=1&'
          'playsinline=1&'
          'enablejsapi=1';
    }

    // إذا لم نتمكن من استخراج videoId، استخدم الرابط الأصلي مباشرة
    print('Using original URL directly: $url');
    return url;
  }

  // دالة لبناء ModernPlayer مع معالجة أخطاء YoutubeExplode
  Widget _buildModernPlayerWithErrorHandling() {
    try {
      return ModernPlayer.createPlayer(
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
        ),
        defaultSelectionOptions: ModernPlayerDefaultSelectionOptions(
            defaultQualitySelectors: [DefaultSelectorLabel('360p')]),
        video: ModernPlayerVideo.youtubeWithUrl(
          url: widget.url, // رابط الفيديو
          fetchQualities: false, // تعطيل جلب الجودات لتجنب مشاكل التشفير
        ),
      );
    } catch (e) {
      // في حالة حدوث خطأ YoutubeExplode، عرض خيارات بديلة
      return _buildFallbackPlayer();
    }
  }

  // دالة لبناء مشغل بديل عند فشل ModernPlayer
  Widget _buildFallbackPlayer() {
    return Container(
      height: MediaQuery.of(context).size.height,
      width: MediaQuery.of(context).size.width,
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.video_library_outlined,
              color: Colors.orange,
              size: 64,
            ),
            const SizedBox(height: 24),
            const Text(
              'لا يمكن تشغيل الفيديو مباشرة',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              'جرب فتح الفيديو في المتصفح',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _openInBrowser,
              icon: const Icon(Icons.open_in_browser),
              label: const Text('فتح في المتصفح'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // دالة لفتح الفيديو في المتصفح
  void _openInBrowser() async {
    try {
      print('فتح الفيديو في المتصفح: ${widget.url}');

      // عرض رسالة للمستخدم
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('سيتم فتح الفيديو في المتصفح: ${widget.url}'),
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      print('خطأ في فتح المتصفح: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('خطأ في فتح المتصفح'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    // إلغاء الـ Timer عند تدمير الـ widget لتجنب التسريبات
    _timer.cancel();
    // إيقاف وتحرير PodPlayer
    _podPlayerController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // التأكد من تعديل اتجاه الشاشة إلى الوضع الأفقي (Landscape)
    SystemChrome.setPreferredOrientations(
        [DeviceOrientation.landscapeRight, DeviceOrientation.landscapeLeft]);
    SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.immersiveSticky); // إخفاء شريط الحالة والأزرار

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: SizedBox(
                height:
                    MediaQuery.of(context).size.height, // ملء الشاشة ارتفاعًا
                width: MediaQuery.of(context).size.width, // ملء الشاشة عرضًا
                child: _buildVideoPlayer(),
              ),
            ),
            Positioned(
              top: 20,
              left: 20,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () {
                  // إعادة الوضع الرأسي عند العودة
                  SystemChrome.setPreferredOrientations(
                      [DeviceOrientation.portraitUp]);
                  SystemChrome.setEnabledSystemUIMode(
                      SystemUiMode.edgeToEdge); // عرض شريط الحالة والأزرار
                  print("Icon fullscreen");

                  print("Navigator.pop(context);");
                  // العودة للصفحة السابقة
                  Navigator.pop(context);

                  // SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
                },
              ),
            ),
            // إضافة العلامة المائية في وسط الشاشة عند التبديل إلى وضع ملء الشاشة
            AnimatedPositioned(
              duration: const Duration(seconds: 1), // مدة الحركة
              // الحساب لتحديد مكان العلامة المائية أفقيًا ورأسيًا في وسط الفيديو
              right: _watermarkPositionX == 0.0
                  ? 20 // الزاوية العلوية اليسرى
                  : (MediaQuery.of(context).size.width / 2) -
                      100, // المنتصف أفقياً (للسهولة، قمنا بطرح 100 لأن عرض النص سيكون 200 تقريبًا)
              top: _watermarkPositionY ==
                      (MediaQuery.of(context).size.height / 2)
                  ? 20 // الزاوية العلوية اليسرى
                  : (MediaQuery.of(context).size.height / 2) -
                      50, // المنتصف رأسياً (حيث أن ارتفاع الشاشة هو 250، نقوم بتحديد المنتصف عن طريق الحساب)
              child: Container(
                padding: const EdgeInsets.all(8),
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
          ],
        ),
      ),
    );
  }
}
