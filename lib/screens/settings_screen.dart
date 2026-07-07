import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../database/database_helper.dart';

class SettingsScreen extends StatefulWidget {
  final String currentUsername;
  final String? customLogoPath;
  final VoidCallback onLogoChanged;
  final Function(String, {bool isError}) showSnackBar;

  const SettingsScreen({
    super.key,
    required this.currentUsername,
    required this.customLogoPath,
    required this.onLogoChanged,
    required this.showSnackBar,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final DatabaseHelper _db = DatabaseHelper.instance;
  List<Map<String, dynamic>> _users = [];
  bool _isLoadingUsers = true;

  // Controllers for adding user
  final _addUsernameController = TextEditingController();
  final _addPasswordController = TextEditingController();
  final _addUserFormKey = GlobalKey<FormState>();

  // Controllers for changing password of current user
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmNewPasswordController = TextEditingController();
  final _changePasswordFormKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _addUsernameController.dispose();
    _addPasswordController.dispose();
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmNewPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoadingUsers = true);
    try {
      final usersList = await _db.getAllUsers();
      setState(() {
        _users = usersList;
        _isLoadingUsers = false;
      });
    } catch (e) {
      widget.showSnackBar('خطأ أثناء تحميل المستخدمين: $e', isError: true);
      setState(() => _isLoadingUsers = false);
    }
  }

  Future<void> _changePassword() async {
    if (_changePasswordFormKey.currentState!.validate()) {
      try {
        // Validate current user credentials
        final user = await _db.validateUser(widget.currentUsername, _oldPasswordController.text);
        if (user == null) {
          widget.showSnackBar('كلمة المرور الحالية غير صحيحة!', isError: true);
          return;
        }

        final int userId = user['id'];
        await _db.updateUser(userId, widget.currentUsername, _newPasswordController.text);

        _oldPasswordController.clear();
        _newPasswordController.clear();
        _confirmNewPasswordController.clear();

        widget.showSnackBar('تم تغيير كلمة المرور بنجاح');
      } catch (e) {
        widget.showSnackBar('فشل تغيير كلمة المرور: $e', isError: true);
      }
    }
  }

  Future<void> _addNewUser() async {
    if (_addUserFormKey.currentState!.validate()) {
      final username = _addUsernameController.text.trim();
      final password = _addPasswordController.text;

      // Check if username already exists
      final exists = _users.any((u) => u['username'].toString().toLowerCase() == username.toLowerCase());
      if (exists) {
        widget.showSnackBar('اسم المستخدم موجود بالفعل!', isError: true);
        return;
      }

      try {
        await _db.createUser(username, password);
        _addUsernameController.clear();
        _addPasswordController.clear();
        widget.showSnackBar('تم إضافة المستخدم بنجاح');
        _loadUsers();
      } catch (e) {
        widget.showSnackBar('فشل إضافة المستخدم: $e', isError: true);
      }
    }
  }

  Future<void> _deleteUser(int id, String username) async {
    if (username == widget.currentUsername) {
      widget.showSnackBar('لا يمكنك حذف حسابك الحالي أثناء تسجيل الدخول به!', isError: true);
      return;
    }

    if (_users.length <= 1) {
      widget.showSnackBar('يجب أن يتبقى مستخدم واحد على الأقل في النظام!', isError: true);
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text('تأكيد الحذف', style: TextStyle(color: Colors.redAccent)),
            content: Text('هل أنت متأكد من رغبتك في حذف حساب المستخدم ($username)؟'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('إلغاء', style: TextStyle(color: Colors.white70)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
                onPressed: () async {
                  Navigator.pop(context);
                  try {
                    await _db.deleteUser(id);
                    widget.showSnackBar('تم حذف المستخدم بنجاح');
                    _loadUsers();
                  } catch (e) {
                    widget.showSnackBar('فشل حذف المستخدم: $e', isError: true);
                  }
                },
                child: const Text('حذف'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickAndSaveLogo() async {
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['png', 'jpg', 'jpeg'],
      );

      if (result != null && result.files.single.path != null) {
        final srcPath = result.files.single.path!;
        final fileExtension = p.extension(srcPath);

        // إنشاء مجلد الأصول داخل Documents
        final documentsDir = await getApplicationDocumentsDirectory();
        final assetsDir = Directory(p.join(documentsDir.path, 'LawFirmApp', 'Assets'));
        if (!await assetsDir.exists()) {
          await assetsDir.create(recursive: true);
        }

        // حفظ الملف باسم فريد
        final fileName = 'logo_${DateTime.now().millisecondsSinceEpoch}$fileExtension';
        final destPath = p.join(assetsDir.path, fileName);

        // نسخ الملف
        await File(srcPath).copy(destPath);

        // حفظ المسار في الإعدادات
        await _db.saveSetting('logo_path', destPath);

        widget.onLogoChanged();
        widget.showSnackBar('تم تحديث شعار التطبيق بنجاح');
      }
    } catch (e) {
      widget.showSnackBar('حدث خطأ أثناء تحميل الشعار: $e', isError: true);
    }
  }

  Future<void> _resetToDefaultLogo() async {
    try {
      await _db.saveSetting('logo_path', '');
      widget.onLogoChanged();
      widget.showSnackBar('تمت إعادة الشعار الافتراضي بنجاح');
    } catch (e) {
      widget.showSnackBar('حدث خطأ أثناء إعادة تعيين الشعار: $e', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktopLarge = width > 950;

    // جزء تعديل شعار التطبيق
    final logoCustomizerWidget = Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Colors.white10, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.palette_outlined, color: Color(0xFFFFD700)),
                SizedBox(width: 12),
                Text(
                  'مظهر وشعار النظام',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFD4AF37)),
                ),
              ],
            ),
            const Divider(height: 24, color: Colors.white24),
            Center(
              child: Column(
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: widget.customLogoPath != null && File(widget.customLogoPath!).existsSync()
                          ? Colors.transparent
                          : const Color(0xFFD4AF37).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFD4AF37), width: 1),
                    ),
                    child: widget.customLogoPath != null && File(widget.customLogoPath!).existsSync()
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(60),
                            child: Image.file(
                              File(widget.customLogoPath!),
                              width: 120,
                              height: 120,
                              fit: BoxFit.cover,
                            ),
                          )
                        : const Icon(Icons.gavel, color: Color(0xFFFFD700), size: 60),
                  ),
                  const SizedBox(height: 16),
                  const Text('قم بتخصيص شعار مكتبك الخاص ليظهر في واجهة تسجيل الدخول والبرنامج.',
                      textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: Colors.white60)),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _pickAndSaveLogo,
                        icon: const Icon(Icons.upload_file),
                        label: const Text('رفع شعار جديد'),
                      ),
                      if (widget.customLogoPath != null && widget.customLogoPath!.isNotEmpty) ...[
                        const SizedBox(width: 12),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.redAccent,
                            side: const BorderSide(color: Colors.redAccent),
                          ),
                          onPressed: _resetToDefaultLogo,
                          icon: const Icon(Icons.restore),
                          label: const Text('إعادة الافتراضي'),
                        ),
                      ],
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );

    // جزء تعديل كلمة مرور المستخدم الحالي
    final changePasswordWidget = Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Colors.white10, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _changePasswordFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.lock_outline, color: Color(0xFFFFD700)),
                  const SizedBox(width: 12),
                  Text(
                    'تعديل كلمة مرور حسابك الحالي (${widget.currentUsername})',
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFFD4AF37)),
                  ),
                ],
              ),
              const Divider(height: 24, color: Colors.white24),
              TextFormField(
                controller: _oldPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'كلمة المرور الحالية',
                  prefixIcon: Icon(Icons.lock_open, color: Color(0xFFD4AF37)),
                  border: OutlineInputBorder(),
                ),
                validator: (val) {
                  if (val == null || val.isEmpty) {
                    return 'يرجى إدخال كلمة المرور الحالية';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _newPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'كلمة المرور الجديدة',
                  prefixIcon: Icon(Icons.lock_outline, color: Color(0xFFD4AF37)),
                  border: OutlineInputBorder(),
                ),
                validator: (val) {
                  if (val == null || val.isEmpty) {
                    return 'يرجى إدخال كلمة المرور الجديدة';
                  }
                  if (val.length < 4) {
                    return 'يجب ألا تقل كلمة المرور عن 4 أحرف';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirmNewPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'تأكيد كلمة المرور الجديدة',
                  prefixIcon: Icon(Icons.lock_reset, color: Color(0xFFD4AF37)),
                  border: OutlineInputBorder(),
                ),
                validator: (val) {
                  if (val != _newPasswordController.text) {
                    return 'كلمات المرور الجديدة غير متطابقة!';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 40,
                child: ElevatedButton(
                  onPressed: _changePassword,
                  child: const Text('تحديث كلمة المرور'),
                ),
              )
            ],
          ),
        ),
      ),
    );

    // جزء إدارة مستخدمي النظام
    final usersManagerWidget = Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Colors.white10, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.manage_accounts, color: Color(0xFFFFD700)),
                SizedBox(width: 12),
                Text(
                  'إدارة حسابات مستخدمي النظام',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFD4AF37)),
                ),
              ],
            ),
            const Divider(height: 24, color: Colors.white24),

            // فورمة إضافة مستخدم جديد
            Form(
              key: _addUserFormKey,
              child: Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _addUsernameController,
                      decoration: const InputDecoration(
                        labelText: 'اسم مستخدم جديد',
                        prefixIcon: Icon(Icons.person_add_alt_1, color: Color(0xFFD4AF37)),
                        border: OutlineInputBorder(),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'يرجى كتابة اسم المستخدم';
                        }
                        if (val.trim().length < 3) {
                          return 'يجب ألا يقل عن 3 أحرف';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _addPasswordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'كلمة المرور للمستخدم الجديد',
                        prefixIcon: Icon(Icons.lock_outline, color: Color(0xFFD4AF37)),
                        border: OutlineInputBorder(),
                      ),
                      validator: (val) {
                        if (val == null || val.isEmpty) {
                          return 'يرجى كتابة كلمة المرور';
                        }
                        if (val.length < 4) {
                          return 'يجب ألا تقل عن 4 أحرف';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _addNewUser,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(120, 52),
                    ),
                    child: const Text('إضافة حساب'),
                  )
                ],
              ),
            ),
            const SizedBox(height: 20),

            // جدول عرض المستخدمين
            _isLoadingUsers
                ? const Center(child: CircularProgressIndicator())
                : LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(minWidth: constraints.maxWidth),
                          child: DataTable(
                            headingRowColor: WidgetStateProperty.all(const Color(0xFF161616)),
                            columns: const [
                              DataColumn(label: Text('اسم المستخدم', style: TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('نوع الحساب', style: TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('الإجراءات', style: TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold))),
                            ],
                            rows: _users.map((u) {
                              final uname = u['username'] as String;
                              final uid = u['id'] as int;
                              final isCurrent = uname == widget.currentUsername;
                              return DataRow(
                                cells: [
                                  DataCell(
                                    Row(
                                      children: [
                                        Text(uname, style: const TextStyle(fontWeight: FontWeight.bold)),
                                        if (isCurrent) ...[
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFD4AF37).withValues(alpha: 0.2),
                                              borderRadius: BorderRadius.circular(4),
                                              border: Border.all(color: const Color(0xFFD4AF37), width: 0.5),
                                            ),
                                            child: const Text('الحساب الحالي', style: TextStyle(fontSize: 10, color: Color(0xFFFFD700))),
                                          )
                                        ],
                                      ],
                                    ),
                                  ),
                                  DataCell(Text(uid == 1 ? 'مدير عام بالنظام' : 'مستخدم فرعي')),
                                  DataCell(
                                    isCurrent
                                        ? const Text('الحساب النشط حالياً', style: TextStyle(color: Colors.white38, fontSize: 12))
                                        : IconButton(
                                            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                            tooltip: 'حذف حساب المستخدم',
                                            onPressed: () => _deleteUser(uid, uname),
                                          ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      );
                    },
                  )
          ],
        ),
      ),
    );

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('إعدادات النظام والتحكم', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFFD4AF37))),
          const SizedBox(height: 24),
          if (isDesktopLarge)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // الجانب الأيمن (مظهر وشعار النظام)
                Expanded(flex: 2, child: logoCustomizerWidget),
                const SizedBox(width: 24),
                // الجانب الأيسر (تعديل كلمة المرور للحساب الحالي)
                Expanded(flex: 3, child: changePasswordWidget),
              ],
            )
          else ...[
            logoCustomizerWidget,
            const SizedBox(height: 24),
            changePasswordWidget,
          ],
          const SizedBox(height: 24),
          usersManagerWidget,
        ],
      ),
    );
  }
}
