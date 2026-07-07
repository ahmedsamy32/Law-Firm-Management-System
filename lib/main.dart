import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:path/path.dart' as p;
import 'database/database_helper.dart';
import 'models/client.dart';
import 'models/case.dart';
import 'models/session.dart';
import 'models/power_of_attorney.dart';
import 'services/document_helper.dart';

// استيراد الشاشات المنفصلة (Separate Screens)
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/clients_screen.dart';
import 'screens/cases_screen.dart';
import 'screens/sessions_screen.dart';
import 'screens/settings_screen.dart';

void main() async {
  // التأكد من تهيئة Flutter قبل بدء تشغيل قاعدة البيانات
  WidgetsFlutterBinding.ensureInitialized();

  // فتح قاعدة البيانات والتأكد من تهيئتها
  final dbHelper = DatabaseHelper.instance;
  await dbHelper.database;

  runApp(const LawFirmApp());
}

class LawFirmApp extends StatelessWidget {
  const LawFirmApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'نظام إدارة مكتب المحاماة',
      debugShowCheckedModeBanner: false,
      locale: const Locale('ar', 'EG'),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ar', 'EG'),
      ],
      theme: ThemeData(
        brightness: Brightness.dark, // عشان يفهم إن السيستم Dark Mode
        scaffoldBackgroundColor: const Color(0xFF121212), // أسود غامق مريح جداً للعين (Material Dark)
        primaryColor: const Color(0xFF1E1E1E), // رمادي قريب للأسود (للـ Sidebar والكروت)
        
        colorScheme: const ColorScheme.dark().copyWith(
          primary: const Color(0xFFD4AF37), // اللون الذهبي الملكي (Metallic Gold) للأزرار والعناوين
          secondary: const Color(0xFFFFD700), // أصفر ذهبي أفتح شوية للتنبهمات أو الـ Icons
          surface: const Color(0xFF1E1E1E), // خلفية الجداول والكروت
        ),

        textSelectionTheme: const TextSelectionThemeData(
          cursorColor: Color(0xFFD4AF37), // لون مؤشر الكتابة يكون ذهبي
        ),

        cardTheme: const CardThemeData(
          color: Color(0xFF1E1E1E),
          elevation: 2,
          margin: EdgeInsets.zero,
        ),

        dialogTheme: const DialogThemeData(
          backgroundColor: Color(0xFF1E1E1E),
          surfaceTintColor: Colors.transparent,
          titleTextStyle: TextStyle(fontFamily: 'Inter', fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFFD4AF37)),
        ),

        navigationRailTheme: const NavigationRailThemeData(
          backgroundColor: Color(0xFF1E1E1E),
          selectedIconTheme: IconThemeData(color: Color(0xFFD4AF37), size: 28),
          unselectedIconTheme: IconThemeData(color: Colors.white60, size: 24),
          selectedLabelTextStyle: TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold, fontSize: 13),
          unselectedLabelTextStyle: TextStyle(color: Colors.white60, fontSize: 12),
        ),

        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFD4AF37),
            foregroundColor: const Color(0xFF121212),
            textStyle: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ),
      home: const MainDashboard(),
    );
  }
}

class MainDashboard extends StatefulWidget {
  const MainDashboard({super.key});

  @override
  State<MainDashboard> createState() => _MainDashboardState();
}

class _MainDashboardState extends State<MainDashboard> {
  int _selectedTab = 0; // 0: Dashboard, 1: Clients, 2: Cases, 3: Sessions
  final DatabaseHelper _db = DatabaseHelper.instance;

  List<Client> _clients = [];
  List<Case> _cases = [];
  List<Session> _sessions = [];
  List<PowerOfAttorney> _poas = [];

  bool _isLoading = true;

  // إعدادات نظام تسجيل الدخول (Authentication State)
  bool _isLoggedIn = false;
  String? _customLogoPath;
  String _currentUsername = 'admin';

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);
    try {
      final clientList = await _db.getAllClients();
      final caseList = await _db.getAllCases();

      // جلب جميع الجلسات والتوكيلات من قاعدة البيانات
      final db = await _db.database;
      final sessionMaps = await db.query('sessions', orderBy: 'session_date ASC');
      final poaMaps = await db.query('power_of_attorneys', orderBy: 'created_at DESC');
      final logoPath = await _db.getSetting('logo_path');

      setState(() {
        _clients = clientList;
        _cases = caseList;
        _sessions = sessionMaps.map((m) => Session.fromJson(m)).toList();
        _poas = poaMaps.map((m) => PowerOfAttorney.fromJson(m)).toList();
        _customLogoPath = (logoPath != null && logoPath.isNotEmpty) ? logoPath : null;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar('حدث خطأ أثناء تحميل البيانات: $e', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isError ? Colors.white : const Color(0xFF121212),
          ),
        ),
        backgroundColor: isError ? Colors.redAccent : const Color(0xFFD4AF37),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _insertMockData() async {
    try {
      // 1. إضافة موكلين
      final c1 = await _db.createClient(Client(
        name: 'جمال عبد الناصر رفعت',
        nationalId: '29010041209876',
        phone: '01099887766',
        address: 'شارع الهرم، الجيزة',
      ));
      final c2 = await _db.createClient(Client(
        name: 'منى محمود الشافعي',
        nationalId: '29508120102345',
        phone: '01233445566',
        address: 'الدقي، الجيزة',
      ));

      // 2. إضافة قضايا
      final case1 = await _db.createCase(Case(
        caseNumber: '4321 لسنة 2026',
        caseType: 'مدني كلي',
        court: 'محكمة الجيزة الابتدائية',
        circle: 'الدائرة 3 مدني',
        clientId: c1.id!,
      ));
      final case2 = await _db.createCase(Case(
        caseNumber: '8765 لسنة 2026',
        caseType: 'أسرة طلاق',
        court: 'محكمة أسرة الدقي',
        circle: 'الدائرة 11 أسرة',
        clientId: c2.id!,
      ));

      // 3. إضافة جلسات (منها واحدة اليوم لتظهر في الأجندة)
      await _db.createSession(Session(
        sessionDate: DateTime.now().add(const Duration(hours: 2)), // جلسة اليوم بعد ساعتين
        decision: 'مؤجلة للاطلاع وتقديم المستندات',
        nextRequirements: 'تقديم أصل عقد البيع الابتدائي',
        caseId: case1.id!,
      ));
      await _db.createSession(Session(
        sessionDate: DateTime.now().add(const Duration(days: 12)),
        decision: 'حجز الدعوى للحكم في نهاية الجلسة',
        nextRequirements: 'تقديم مذكرة ختامية',
        caseId: case2.id!,
      ));

      // 4. إضافة توكيلات
      await _db.createPowerOfAttorney(PowerOfAttorney(
        poaNumber: '1254أ توثيق الجيزة',
        documentationOffice: 'مكتب توثيق الأهرام الكائن بـ الجيزة',
        filePath: 'C:/docs/poa_gamal.pdf',
        clientId: c1.id!,
      ));

      _showSnackBar('تم تحميل البيانات التجريبية بنجاح!');
      _loadAllData();
    } catch (e) {
      _showSnackBar('خطأ أثناء إضافة البيانات التجريبية: $e', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: !_isLoggedIn
            ? LoginScreen(
                onLoginSuccess: (username) {
                  setState(() {
                    _isLoggedIn = true;
                    _currentUsername = username;
                  });
                },
                showSnackBar: (msg, {isError = false}) {
                  _showSnackBar(msg, isError: isError);
                },
                customLogoPath: _customLogoPath,
              )
            : Row(
                children: [
                  // 1. شريط التنقل الجانبي (NavigationRail)
                  NavigationRail(
                    selectedIndex: _selectedTab,
                    onDestinationSelected: (int index) {
                      setState(() => _selectedTab = index);
                    },
                    labelType: NavigationRailLabelType.all,
                    destinations: const [
                      NavigationRailDestination(
                        icon: Icon(Icons.dashboard_outlined),
                        selectedIcon: Icon(Icons.dashboard),
                        label: Text('الرئيسية'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.people_outline),
                        selectedIcon: Icon(Icons.people),
                        label: Text('الموكلين'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.gavel_outlined),
                        selectedIcon: Icon(Icons.gavel),
                        label: Text('القضايا'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.calendar_today_outlined),
                        selectedIcon: Icon(Icons.calendar_today),
                        label: Text('الجلسات'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.settings_outlined),
                        selectedIcon: Icon(Icons.settings),
                        label: Text('الإعدادات'),
                      ),
                    ],
                    trailing: Padding(
                      padding: const EdgeInsets.only(top: 24.0, bottom: 24.0),
                      child: Column(
                        children: [
                          // زر إضافة توكيل سريع
                          IconButton(
                            icon: const Icon(Icons.assignment_turned_in_outlined, color: Color(0xFFFFD700)),
                            tooltip: 'تسجيل توكيل جديد',
                            onPressed: _showAddPoaDialog,
                          ),
                          const SizedBox(height: 12),
                          IconButton(
                            icon: const Icon(Icons.data_usage_outlined, color: Color(0xFFFFD700)),
                            tooltip: 'إضافة بيانات تجريبية',
                            onPressed: _insertMockData,
                          ),
                          const SizedBox(height: 12),
                          IconButton(
                            icon: const Icon(Icons.logout_outlined, color: Colors.redAccent),
                            tooltip: 'تسجيل الخروج',
                            onPressed: () {
                              setState(() {
                                _isLoggedIn = false;
                              });
                              _showSnackBar('تم تسجيل الخروج بنجاح');
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const VerticalDivider(thickness: 1, width: 1, color: Colors.white12),
                  // 2. المحتوى الرئيسي للمشروع
                  Expanded(
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : Container(
                            padding: const EdgeInsets.all(24.0),
                            child: IndexedStack(
                              index: _selectedTab,
                              children: [
                                DashboardScreen(
                                  todaySessions: _sessions.where((session) {
                                    final now = DateTime.now();
                                    return session.sessionDate.year == now.year &&
                                        session.sessionDate.month == now.month &&
                                        session.sessionDate.day == now.day;
                                  }).toList(),
                                  cases: _cases,
                                  clientsCount: _clients.length,
                                  casesCount: _cases.length,
                                ),
                                ClientsScreen(
                                  clients: _clients,
                                  poas: _poas,
                                  cases: _cases,
                                  onAddClient: _showAddClientDialog,
                                  onDeleteClient: (id) async {
                                    await _db.deleteClient(id);
                                    _showSnackBar('تم حذف الموكل بنجاح');
                                    _loadAllData();
                                  },
                                ),
                                CasesScreen(
                                  cases: _cases,
                                  clients: _clients,
                                  onAddCase: _showAddCaseDialog,
                                  onDeleteCase: (id) async {
                                    await _db.deleteCase(id);
                                    _showSnackBar('تم حذف القضية بنجاح');
                                    _loadAllData();
                                  },
                                ),
                                SessionsScreen(
                                  sessions: _sessions,
                                  cases: _cases,
                                  onAddSession: _showAddSessionDialog,
                                  onDeleteSession: (id) async {
                                    await _db.deleteSession(id);
                                    _showSnackBar('تم حذف الجلسة بنجاح');
                                    _loadAllData();
                                  },
                                ),
                                SettingsScreen(
                                  currentUsername: _currentUsername,
                                  customLogoPath: _customLogoPath,
                                  onLogoChanged: _loadAllData,
                                  showSnackBar: (msg, {isError = false}) {
                                    _showSnackBar(msg, isError: isError);
                                  },
                                ),
                              ],
                            ),
                          ),
                  ),
                ],
              ),
      ),
    );
  }

  // =========================================================================
  // نوافذ إضافة البيانات (Form Dialogs)
  // =========================================================================

  void _showAddClientDialog() {
    final nameController = TextEditingController();
    final nationalIdController = TextEditingController();
    final phoneController = TextEditingController();
    final addressController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text('إضافة موكل جديد'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: nameController, decoration: const InputDecoration(labelText: 'الاسم الكامل')),
                  TextField(controller: nationalIdController, decoration: const InputDecoration(labelText: 'الرقم القومي (14 رقم)')),
                  TextField(controller: phoneController, decoration: const InputDecoration(labelText: 'رقم الهاتف')),
                  TextField(controller: addressController, decoration: const InputDecoration(labelText: 'العنوان')),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء', style: TextStyle(color: Color(0xFFD4AF37)))),
              ElevatedButton(
                onPressed: () async {
                  if (nameController.text.isEmpty || nationalIdController.text.isEmpty) {
                    _showSnackBar('يرجى تعبئة الحقول الأساسية', isError: true);
                    return;
                  }
                  final navigator = Navigator.of(context);
                  await _db.createClient(Client(
                    name: nameController.text,
                    nationalId: nationalIdController.text,
                    phone: phoneController.text.isNotEmpty ? phoneController.text : null,
                    address: addressController.text.isNotEmpty ? addressController.text : null,
                  ));
                  navigator.pop();
                  if (!mounted) return;
                  _showSnackBar('تم إضافة الموكل بنجاح');
                  _loadAllData();
                },
                child: const Text('حفظ'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAddCaseDialog() {
    if (_clients.isEmpty) {
      _showSnackBar('يجب إضافة موكل أولاً قبل إنشاء قضية', isError: true);
      return;
    }

    final caseNumberController = TextEditingController();
    final caseTypeController = TextEditingController();
    final courtController = TextEditingController();
    final circleController = TextEditingController();
    int? selectedClientId = _clients.first.id;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Directionality(
              textDirection: TextDirection.rtl,
              child: AlertDialog(
                title: const Text('إضافة قضية جديدة'),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<int>(
                        // ignore: deprecated_member_use
                        value: selectedClientId,
                        decoration: const InputDecoration(labelText: 'اختر الموكل'),
                        items: _clients.map((c) {
                          return DropdownMenuItem<int>(
                            value: c.id,
                            child: Text(c.name),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setDialogState(() => selectedClientId = val);
                        },
                      ),
                      TextField(controller: caseNumberController, decoration: const InputDecoration(labelText: 'رقم القضية (مثال: 123 لسنة 2026)')),
                      TextField(controller: caseTypeController, decoration: const InputDecoration(labelText: 'نوع القضية (جنح، مدني، أسرة)')),
                      TextField(controller: courtController, decoration: const InputDecoration(labelText: 'المحكمة المختصة')),
                      TextField(controller: circleController, decoration: const InputDecoration(labelText: 'الدائرة')),
                    ],
                  ),
                ),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء', style: TextStyle(color: Color(0xFFD4AF37)))),
                  ElevatedButton(
                    onPressed: () async {
                      if (caseNumberController.text.isEmpty ||
                          caseTypeController.text.isEmpty ||
                          courtController.text.isEmpty ||
                          selectedClientId == null) {
                        _showSnackBar('يرجى إدخال جميع البيانات المطلوبة', isError: true);
                        return;
                      }
                      final navigator = Navigator.of(context);
                      await _db.createCase(Case(
                        caseNumber: caseNumberController.text,
                        caseType: caseTypeController.text,
                        court: courtController.text,
                        circle: circleController.text,
                        clientId: selectedClientId!,
                      ));
                      navigator.pop();
                      if (!mounted) return;
                      _showSnackBar('تم تسجيل القضية بنجاح');
                      _loadAllData();
                    },
                    child: const Text('حفظ'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showAddSessionDialog() {
    if (_cases.isEmpty) {
      _showSnackBar('يجب إضافة قضية أولاً لإرفاق الجلسات بها', isError: true);
      return;
    }

    final decisionController = TextEditingController();
    final requirementsController = TextEditingController();
    int? selectedCaseId = _cases.first.id;
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Directionality(
              textDirection: TextDirection.rtl,
              child: AlertDialog(
                title: const Text('إضافة جلسة جديدة'),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<int>(
                        // ignore: deprecated_member_use
                        value: selectedCaseId,
                        decoration: const InputDecoration(labelText: 'اختر القضية المرتبطة'),
                        items: _cases.map((c) {
                          return DropdownMenuItem<int>(
                            value: c.id,
                            child: Text('رقم ${c.caseNumber} - ${c.caseType}'),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setDialogState(() => selectedCaseId = val);
                        },
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('تاريخ الجلسة: ${selectedDate.year}-${selectedDate.month}-${selectedDate.day}'),
                          TextButton(
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: selectedDate,
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2030),
                              );
                              if (picked != null) {
                                setDialogState(() => selectedDate = picked);
                              }
                            },
                            child: const Text('تغيير التاريخ', style: TextStyle(color: Color(0xFFD4AF37))),
                          ),
                        ],
                      ),
                      TextField(controller: decisionController, decoration: const InputDecoration(labelText: 'القرار أو الحالة الحالية')),
                      TextField(controller: requirementsController, decoration: const InputDecoration(labelText: 'الطلبات القادمة')),
                    ],
                  ),
                ),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء', style: TextStyle(color: Color(0xFFD4AF37)))),
                  ElevatedButton(
                    onPressed: () async {
                      if (selectedCaseId == null) return;
                      final navigator = Navigator.of(context);
                      await _db.createSession(Session(
                        sessionDate: selectedDate,
                        decision: decisionController.text.isNotEmpty ? decisionController.text : null,
                        nextRequirements: requirementsController.text.isNotEmpty ? requirementsController.text : null,
                        caseId: selectedCaseId!,
                      ));
                      navigator.pop();
                      if (!mounted) return;
                      _showSnackBar('تم إضافة الجلسة بنجاح');
                      _loadAllData();
                    },
                    child: const Text('حفظ'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showAddPoaDialog() {
    if (_clients.isEmpty) {
      _showSnackBar('يجب إضافة موكل أولاً لتسجيل توكيل له', isError: true);
      return;
    }

    final poaNumberController = TextEditingController();
    final officeController = TextEditingController();
    String? uploadedFilePath;
    int? selectedClientId = _clients.first.id;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Directionality(
              textDirection: TextDirection.rtl,
              child: AlertDialog(
                title: const Text('تسجيل توكيل رسمي'),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<int>(
                        // ignore: deprecated_member_use
                        value: selectedClientId,
                        decoration: const InputDecoration(labelText: 'اختر الموكل'),
                        items: _clients.map((c) {
                          return DropdownMenuItem<int>(
                            value: c.id,
                            child: Text(c.name),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setDialogState(() => selectedClientId = val);
                        },
                      ),
                      TextField(controller: poaNumberController, decoration: const InputDecoration(labelText: 'رقم التوكيل (مثال: 5432أ لسنة 2026)')),
                      TextField(controller: officeController, decoration: const InputDecoration(labelText: 'مكتب توثيق الشهر العقاري')),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              uploadedFilePath == null
                                  ? 'لم يتم إرفاق ملف بعد'
                                  : 'الملف المرفق: ${p.basename(uploadedFilePath!)}',
                              style: TextStyle(
                                  fontSize: 13,
                                  color: uploadedFilePath == null ? Colors.white60 : const Color(0xFFFFD700)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 12),
                          OutlinedButton.icon(
                            onPressed: () async {
                              final newPath = await DocumentHelper.pickAndSaveDocument();
                              if (newPath != null) {
                                setDialogState(() {
                                  uploadedFilePath = newPath;
                                });
                              }
                            },
                            icon: const Icon(Icons.upload_file, size: 18),
                            label: const Text('رفع ملف'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFFD4AF37),
                              side: const BorderSide(color: Color(0xFFD4AF37)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء', style: TextStyle(color: Color(0xFFD4AF37)))),
                  ElevatedButton(
                    onPressed: () async {
                      if (poaNumberController.text.isEmpty || officeController.text.isEmpty || selectedClientId == null) {
                        _showSnackBar('يرجى تعبئة الحقول الأساسية', isError: true);
                        return;
                      }
                      final navigator = Navigator.of(context);
                      await _db.createPowerOfAttorney(PowerOfAttorney(
                        poaNumber: poaNumberController.text,
                        documentationOffice: officeController.text,
                        filePath: uploadedFilePath,
                        clientId: selectedClientId!,
                      ));
                      navigator.pop();
                      if (!mounted) return;
                      _showSnackBar('تم تسجيل التوكيل بنجاح');
                      _loadAllData();
                    },
                    child: const Text('حفظ'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
