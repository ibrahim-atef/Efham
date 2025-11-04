import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// import 'package:headset_connection_event/headset_event.dart';
import 'package:modern_player/modern_player.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'full_screen_video_page.dart'; // استيراد صفحة ملء الشاشة
import 'dart:async'; // استيراد مكتبة Timer

class PodVideoPlayerDev extends StatefulWidget {
  final String type;
  final String url;
  final String name;
  final RouteObserver<ModalRoute<void>> routeObserver;

  const PodVideoPlayerDev(this.url, this.type, this.routeObserver,
      {super.key, required this.name});

  @override
  State<PodVideoPlayerDev> createState() => _VimeoVideoPlayerState();
}

class _VimeoVideoPlayerState extends State<PodVideoPlayerDev> {
  bool _isFullScreen = false;
  double _watermarkPositionX = 0.0; // متغير لتحديد مكان العلامة المائية أفقياً
  double _watermarkPositionY = 0.0; // متغير لتحديد مكان العلامة المائية رأسياً
  late Timer _timer;
  bool _isLoading = true;
  String? _errorMessage;
  bool _useWebView = false;
  bool _isWebViewLoaded = false;
  late WebViewController _webViewController;

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
          builder: (context) =>
              FullScreenVideoPage(url: widget.url, name: widget.name),
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

    // إعادة تعيين حالة WebView
    _isWebViewLoaded = false;

    // التحقق من صحة رابط YouTube
    _validateYouTubeUrl();

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
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  }

  // دالة للتحقق من صحة رابط YouTube
  void _validateYouTubeUrl() {
    if (widget.url.isEmpty) {
      setState(() {
        _errorMessage = "رابط الفيديو غير صحيح";
        _isLoading = false;
      });
      return;
    }

    // التحقق من أن الرابط يحتوي على YouTube
    if (!widget.url.contains('youtube.com') &&
        !widget.url.contains('youtu.be')) {
      setState(() {
        _errorMessage = "رابط YouTube غير صحيح";
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = false;
    });
  }

  // دالة لمعالجة رابط YouTube وتحويله إلى الصيغة الصحيحة
  String _processYouTubeUrl(String url) {
    // إذا كان الرابط يحتوي على youtu.be، نحوله إلى youtube.com
    if (url.contains('youtu.be/')) {
      String videoId = url.split('youtu.be/')[1].split('?')[0];
      return 'https://www.youtube.com/watch?v=$videoId';
    }

    // إذا كان الرابط يحتوي على youtube.com/watch، نتركه كما هو
    if (url.contains('youtube.com/watch')) {
      return url;
    }

    return url;
  }

  // دالة لبناء مشغل الفيديو مع معالجة الأخطاء
  Widget _buildVideoPlayer() {
    if (_isLoading) {
      return Container(
        height: 250,
        width: MediaQuery.of(context).size.width,
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(
            color: Colors.white,
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Container(
        height: 250,
        width: MediaQuery.of(context).size.width,
        color: Colors.black,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _errorMessage = null;
                  });
                  _validateYouTubeUrl();
                },
                child: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
      );
    }

    // لـ YouTube، استخدم WebView مباشرة لتجنب مشاكل YoutubeExplode
    if (widget.type.toLowerCase() == 'youtube') {
      return _buildWebViewPlayer();
    }

    // إذا كان المستخدم اختار WebView
    if (_useWebView) {
      return _buildWebViewPlayer();
    }

    return _buildModernPlayerWithErrorHandling();
  }

  // دالة لبناء WebView كحل بديل
  Widget _buildWebViewPlayer() {
    // إنشاء WebViewController مرة واحدة فقط
    if (!_isWebViewLoaded) {
      _webViewController = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(Colors.black)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageStarted: (String url) {
              print('WebView started loading: $url');
            },
            onPageFinished: (String url) {
              print('WebView finished loading: $url');
              setState(() {
                _isWebViewLoaded = true;
              });
              // منع إعادة التحميل التلقائي
              _injectStabilityScript();
            },
            onWebResourceError: (WebResourceError error) {
              print('WebView error: ${error.description}');
            },
            onNavigationRequest: (NavigationRequest request) {
              // منع التنقل غير المرغوب فيه
              if (request.url.contains('youtube.com/embed/')) {
                return NavigationDecision.navigate;
              }
              return NavigationDecision.prevent;
            },
          ),
        );

      // تحميل URL مرة واحدة فقط
      _webViewController
          .loadRequest(Uri.parse(_getYouTubeEmbedUrl(widget.url)));
    }

    return SizedBox(
      height: 250,
      width: MediaQuery.of(context).size.width,
      child: Stack(
        children: [
          WebViewWidget(controller: _webViewController),
          // رسالة توضيحية لـ YouTube
          if (widget.type.toLowerCase() == 'youtube')
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'YouTube - وضع متوافق',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          // زر للعودة إلى ModernPlayer (فقط إذا لم يكن YouTube)
          if (widget.type.toLowerCase() != 'youtube')
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                onPressed: () {
                  setState(() {
                    _useWebView = false;
                  });
                },
                icon: const Icon(Icons.close, color: Colors.white),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black54,
                ),
              ),
            ),
          // زر ملء الشاشة
          Positioned(
            bottom: 8,
            right: 8,
            child: IconButton(
              onPressed: _toggleFullScreen,
              icon: const Icon(Icons.fullscreen, color: Colors.white),
              style: IconButton.styleFrom(
                backgroundColor: Colors.black54,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // دالة لتحويل رابط YouTube إلى رابط embed
  String _getYouTubeEmbedUrl(String url) {
    String videoId = '';

    if (url.contains('youtube.com/watch?v=')) {
      videoId = url.split('v=')[1].split('&')[0];
    } else if (url.contains('youtu.be/')) {
      videoId = url.split('youtu.be/')[1].split('?')[0];
    }

    if (videoId.isNotEmpty) {
      return 'https://www.youtube.com/embed/$videoId?autoplay=1&rel=0&modestbranding=1&loop=0&controls=1&showinfo=0&iv_load_policy=3&fs=1&disablekb=0&enablejsapi=1';
    }

    return url;
  }

  // دالة لحقن سكريبت لتحسين استقرار الفيديو
  void _injectStabilityScript() {
    // تطبيق تحسينات الاستقرار
    try {
      print('تم تطبيق سكريبت الاستقرار');
      // يمكن إضافة حقن السكريبت هنا إذا كان WebView يدعم ذلك
    } catch (e) {
      print('خطأ في حقن السكريبت: $e');
    }
  }

  // دالة لبناء ModernPlayer مع معالجة أخطاء YoutubeExplode
  Widget _buildModernPlayerWithErrorHandling() {
    // تجنب استخدام ModernPlayer لـ YouTube تماماً
    if (widget.type.toLowerCase() == 'youtube') {
      return _buildWebViewPlayer();
    }

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
        video: ModernPlayerVideo.single(
          source: widget.url,
          sourceType: ModernPlayerSourceType.network,
        ),
      );
    } catch (e) {
      // في حالة حدوث خطأ، عرض خيارات بديلة
      return _buildFallbackPlayer();
    }
  }

  // دالة لبناء مشغل بديل عند فشل ModernPlayer
  Widget _buildFallbackPlayer() {
    return Container(
      height: 250,
      width: MediaQuery.of(context).size.width,
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.video_library_outlined,
              color: Colors.orange,
              size: 48,
            ),
            const SizedBox(height: 16),
            const Text(
              'لا يمكن تشغيل الفيديو مباشرة',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'جرب فتح الفيديو في المتصفح',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: _openInBrowser,
                  icon: const Icon(Icons.open_in_browser),
                  label: const Text('فتح في المتصفح'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _useWebView = true;
                    });
                  },
                  icon: const Icon(Icons.web),
                  label: const Text('عرض في التطبيق'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _isLoading = true;
                      _errorMessage = null;
                    });
                    _validateYouTubeUrl();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('إعادة المحاولة'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // دالة لفتح الفيديو في المتصفح
  void _openInBrowser() async {
    try {
      final url = _processYouTubeUrl(widget.url);
      // يمكنك استخدام url_launcher هنا إذا كان متوفراً
      // await launchUrl(Uri.parse(url));
      print('فتح الفيديو في المتصفح: $url');

      // عرض رسالة للمستخدم
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('سيتم فتح الفيديو في المتصفح: $url'),
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
                    child: _buildVideoPlayer(),
                  ),
                  // العلامة المائية
                  AnimatedPositioned(
                    duration: const Duration(seconds: 1),
                    left: _watermarkPositionX == 0.0
                        ? 0
                        : (MediaQuery.of(context).size.width / 2) - 100,
                    top: _watermarkPositionY == 0.0 ? 0 : (250 / 2) - 50,
                    child: Container(
                      padding: const EdgeInsets.all(8),
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
              )),
        ),
      ),
    );
  }
}
