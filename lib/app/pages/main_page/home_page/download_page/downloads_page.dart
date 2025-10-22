import 'dart:io';
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:webinar/common/common.dart';
import '../../../../../common/components.dart';

class DownloadsPage extends StatefulWidget {
  static const String pageName = '/downloads';
  const DownloadsPage({super.key});

  @override
  State<DownloadsPage> createState() => _DownloadsPageState();
}

class _DownloadsPageState extends State<DownloadsPage> {
  List<FileSystemEntity> pdfFiles = [];

  @override
  void initState() {
    super.initState();
    fetchDownloads();
  }

  Future<void> fetchDownloads() async {
    PermissionStatus res = await Permission.storage.request();
    if (!res.isGranted) {
      print("❌ الإذن مرفوض، لا يمكن الوصول إلى الملفات.");
      return;
    }

    try {
      String directory = (await getApplicationSupportDirectory()).path;
      List<FileSystemEntity> allFiles = Directory(directory).listSync();

      // تصفية الملفات لإظهار ملفات PDF فقط
      setState(() {
        pdfFiles = allFiles.where((file) => file.path.endsWith('.pdf')).toList();
      });

      print("📂 تم العثور على ${pdfFiles.length} ملفات PDF.");
    } catch (e) {
      print("❌ خطأ أثناء جلب الملفات: $e");
    }
  }

  void deleteFile(FileSystemEntity file) async {
    try {
      await file.delete();
      setState(() {
        pdfFiles.remove(file);
      });
      print("🗑️ تم حذف الملف: ${file.path}");
      showSnackBarMessage("تم حذف الملف بنجاح");
    } catch (e) {
      print("❌ خطأ أثناء حذف الملف: $e");
      showSnackBarMessage("فشل حذف الملف");
    }
  }

  void showSnackBarMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return directionality(
      child: Scaffold(
        appBar: appbar(title: "📂 ملفات PDF"),
        body: pdfFiles.isEmpty
            ? const Center(child: Text("لا توجد ملفات PDF متاحة"))
            : ListView.builder(
          itemCount: pdfFiles.length,
          itemBuilder: (context, index) {
            FileSystemEntity file = pdfFiles[index];
            String fileName = file.path.split('/').last;

            return ListTile(
              leading: Icon(Icons.picture_as_pdf, size: 30, color: Colors.red),
              title: Text(fileName, style: const TextStyle(fontSize: 16)),
              // subtitle: Text(file.path, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              onTap: () {
                print("📂 فتح ملف PDF: $fileName");
                OpenFile.open(file.path);
              },
              trailing: IconButton(
                icon: Icon(Icons.delete, color: Colors.red),
                onPressed: () {
                  deleteFile(file);
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
