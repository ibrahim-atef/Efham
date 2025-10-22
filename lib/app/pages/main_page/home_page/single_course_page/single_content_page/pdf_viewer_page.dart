import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';

import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:webinar/common/common.dart';
import 'package:webinar/common/components.dart';
import 'package:webinar/common/data/app_data.dart';
import 'package:webview_flutter/webview_flutter.dart';


import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';


class PdfViewerPage extends StatefulWidget {
  static const String pageName = '/pdf-viewer';
  const PdfViewerPage({super.key});

  @override
  State<PdfViewerPage> createState() => _PdfViewerPageState();
}

class _PdfViewerPageState extends State<PdfViewerPage> {
  String? title;
  String? path;
  late String name;
  bool isNetworkFile = false;

  final GlobalKey<SfPdfViewerState> _pdfViewerKey = GlobalKey();
  PdfViewerController pdfViewerController = PdfViewerController();


  InAppWebViewController? webViewController;




  late final WebViewController _controller;


  @override
  void initState() {
    getUser();
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      final args = ModalRoute.of(context)!.settings.arguments as List;
      path = args[0];
      title = args[1];

      print("📂 ملف PDF المستلم في PdfViewerPage: $path");

      // التحقق مما إذا كان الرابط من الإنترنت
      if (path!.startsWith("http") || path!.startsWith("https")) {
        isNetworkFile = true;
      }

      setState(() {});

      // _controller = WebViewController()
      //   ..setJavaScriptMode(JavaScriptMode.unrestricted)
      //   ..loadHtmlString('''
      //   <html>
      //     <body style="margin: 0; padding: 0; overflow: hidden;">
      //       <iframe src="https://appabdulrahmanaboelmaaty.anmka.com/store/1/7,,8.pdf"
      //         width="100%" height="100%" style="border: none;"></iframe>
      //     </body>
      //   </html>
      // ''');
    });
  }

  getUser() async {
    name = await AppData.getName();
  }

  @override
  Widget build(BuildContext context) {
    String encodedUrl = Uri.encodeFull(path ?? '');
    String correctedUrl = path!.replaceAll(",,", "%2C%2C"); // تحويل الفواصل

    print(path);
    print("path");
    return directionality(
      child: Scaffold(
        appBar: appbar(title: title ?? ''),

        body: path != null
            ? Stack(
          children: [
            isNetworkFile
                ?

            // WebViewWidget(controller: _controller)

            // PDFView(filePath: path)

        InAppWebView(
          initialUrlRequest: URLRequest(
            url: WebUri(
                // "https://docs.google.com/gview?embedded=true&url=$path"
              // path??''
                // "https://docs.google.com/gview?embedded=true&url=$correctedUrl"
              // "https://appabdulrahmanaboelmaaty.anmka.com/store/1/7,,8.pdf"
              //   "https://docs.google.com/gview?embedded=true&url=$encodedUrl"
                "https://mozilla.github.io/pdf.js/web/viewer.html?file=${Uri.encodeFull(path ?? '')}"
            ),
          ),

      onWebViewCreated: (controller) {
        webViewController = controller;
      },
    )

            // SfPdfViewer.network(
            //   path!,
            //   key: _pdfViewerKey,
            //   controller: pdfViewerController,
            // )
                : SfPdfViewer.file(
              File(path!),
              key: _pdfViewerKey,
              controller: pdfViewerController,
            ),

            // Watermark Layer
            Center(
              child: Opacity(
                opacity: 0.2, // Adjust the transparency of the watermark
                child: Transform.rotate(
                  angle: -0.3, // Rotate the watermark text
                  child: Text(
                    name ?? 'CONFIDENTIAL', // Your watermark text
                    style: const TextStyle(
                      fontSize: 100,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                ),
              ),
            ),
          ],
        )
            : const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  @override
  void dispose() {
    pdfViewerController.dispose();
    super.dispose();
  }
}













class DownloadAndOpenPdf extends StatefulWidget {
  final String pdfUrl;
  DownloadAndOpenPdf(this.pdfUrl);
  @override
  _DownloadAndOpenPdfState createState() => _DownloadAndOpenPdfState();
}

class _DownloadAndOpenPdfState extends State<DownloadAndOpenPdf> {

  // "https://abdulrahman.anmka.com/store/1050/Assignment 2 - General Chemistry 1 - CHM1101.pdf";

  String? localPath;

  Future<bool> requestStoragePermission() async {
    var status = await Permission.storage.request();
    return status.isGranted;
  }

  Future<void> downloadPdf() async {
    if (await requestStoragePermission()) {
      try {
        final directory = await getExternalStorageDirectory();
        String savePath = "${directory!.path}/assignment.pdf";

        var dio = Dio();
        await dio.download(widget.pdfUrl, savePath);
        print("File downloaded to: $savePath");

        setState(() {
          localPath = savePath;
        });

        // عرض ملف PDF بعد التنزيل
        openPdfViewer(context, savePath);
      } catch (e) {
        print("Error downloading file: $e");
      }
    } else {
      print("Storage permission denied.");
    }
  }

  void openPdfViewer(BuildContext context, String filePath) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(title: Text("PDF Viewer")),
          body: SfPdfViewer.file(File(filePath)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Download and Open PDF"),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            await downloadPdf();
          },
          child: Text("Download and Open PDF"),
        ),
      ),
    );
  }
}
