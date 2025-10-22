import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:modern_player/modern_player.dart';

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

  @override
  void initState() {
    super.initState();
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
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    // إلغاء الـ Timer عند تدمير الـ widget لتجنب التسريبات
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // التأكد من تعديل اتجاه الشاشة إلى الوضع الأفقي (Landscape)
    SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeRight, DeviceOrientation.landscapeLeft]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);  // إخفاء شريط الحالة والأزرار

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: SizedBox(
                height: MediaQuery.of(context).size.height,  // ملء الشاشة ارتفاعًا
                width: MediaQuery.of(context).size.width,  // ملء الشاشة عرضًا
                child: ModernPlayer.createPlayer(
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
                      defaultQualitySelectors: [DefaultSelectorLabel('360p')]
                  ),
                  video: ModernPlayerVideo.youtubeWithUrl(
                    url: widget.url,  // رابط الفيديو
                    fetchQualities: true,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 20,
              left: 20,
              child: IconButton(
                icon: Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () {
                  // إعادة الوضع الرأسي عند العودة
                  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
                  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);  // عرض شريط الحالة والأزرار
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
              duration: Duration(seconds: 1),  // مدة الحركة
              // الحساب لتحديد مكان العلامة المائية أفقيًا ورأسيًا في وسط الفيديو
              right: _watermarkPositionX == 0.0
                  ? 20 // الزاوية العلوية اليسرى
                  : (MediaQuery.of(context).size.width / 2) - 100, // المنتصف أفقياً (للسهولة، قمنا بطرح 100 لأن عرض النص سيكون 200 تقريبًا)
              top: _watermarkPositionY == (MediaQuery.of(context).size.height / 2)
                  ? 20 // الزاوية العلوية اليسرى
                  : (MediaQuery.of(context).size.height / 2) - 50, // المنتصف رأسياً (حيث أن ارتفاع الشاشة هو 250، نقوم بتحديد المنتصف عن طريق الحساب)
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
          ],
        ),
      ),
    );
  }
}
