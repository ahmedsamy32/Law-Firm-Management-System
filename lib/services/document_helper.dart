import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class DocumentHelper {
  /// اختيار ملف (صورة أو PDF) ونسخه إلى مجلد مخصص داخل جهاز الكمبيوتر
  /// يعيد المسار الجديد للملف المحفوظ، أو null إذا تم الإلغاء
  static Future<String?> pickAndSaveDocument() async {
    try {
      // 1. فتح نافذة اختيار الملفات
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg', 'doc', 'docx'],
      );

      if (result == null || result.files.single.path == null) {
        return null; // إلغاء الاختيار
      }

      String selectedPath = result.files.single.path!;

      // 2. الحصول على مسار مجلد المستندات الخاص بالمستخدم (Documents)
      Directory appDocDir = await getApplicationDocumentsDirectory();
      
      // 3. تحديد مجلد الحفظ المخصص
      String targetDirPath = p.join(appDocDir.path, 'LawFirmApp', 'Files');
      Directory targetDir = Directory(targetDirPath);
      
      // إنشاء المجلد إذا لم يكن موجوداً
      if (!await targetDir.exists()) {
        await targetDir.create(recursive: true);
      }

      // 4. إنشاء اسم ملف فريد باستخدام بصمة زمنية لتجنب الكتابة فوق ملف بنفس الاسم
      String baseNameWithoutExt = p.basenameWithoutExtension(selectedPath);
      String ext = p.extension(selectedPath);
      String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      String uniqueFileName = '${baseNameWithoutExt}_$timestamp$ext';
      String targetFilePath = p.join(targetDirPath, uniqueFileName);

      // 5. نسخ الملف من مكانه الحالي إلى المجلد الجديد
      File sourceFile = File(selectedPath);
      await sourceFile.copy(targetFilePath);

      // إعادة المسار الجديد لحفظه في قاعدة البيانات
      return targetFilePath;
    } catch (e) {
      debugPrint('خطأ أثناء اختيار وحفظ المستند: $e');
      return null;
    }
  }

  /// فتح المستند المحفوظ باستخدام مستعرض النظام الافتراضي (Windows Explorer)
  static Future<bool> openDocument(String filePath) async {
    try {
      if (filePath.isEmpty) return false;
      
      File file = File(filePath);
      if (!await file.exists()) {
        return false; // الملف غير موجود
      }

      if (Platform.isWindows) {
        // تشغيل الملف على نظام ويندوز باستخدام explorer
        await Process.start('explorer.exe', [filePath]);
        return true;
      } else if (Platform.isMacOS) {
        // تشغيل الملف على نظام ماك باستخدام open
        await Process.start('open', [filePath]);
        return true;
      }
      
      return false;
    } catch (e) {
      debugPrint('خطأ أثناء فتح المستند: $e');
      return false;
    }
  }
}
