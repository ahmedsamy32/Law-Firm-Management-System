import 'package:flutter/material.dart';
import '../models/case.dart';
import '../models/session.dart';

class DashboardScreen extends StatelessWidget {
  final List<Session> todaySessions;
  final List<Case> cases;
  final int clientsCount;
  final int casesCount;

  const DashboardScreen({
    super.key,
    required this.todaySessions,
    required this.cases,
    required this.clientsCount,
    required this.casesCount,
  });

  Widget _buildStatCard(String title, String val, IconData icon) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFD4AF37), width: 0.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFD4AF37).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: const Color(0xFFFFD700), size: 32),
            ),
            const SizedBox(width: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 14, color: Colors.white70)),
                const SizedBox(height: 6),
                Text(
                  val,
                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFFD4AF37)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktopLarge = width > 950;
    final now = DateTime.now();

    // تصميم بطاقات الإحصائيات
    final statsWidgets = Column(
      children: [
        _buildStatCard('عدد الموكلين المسجلين', '$clientsCount', Icons.people),
        const SizedBox(height: 16),
        _buildStatCard('عدد القضايا المفتوحة', '$casesCount', Icons.folder_open),
      ],
    );

    // تصميم جدول أجندة الجلسات
    final agendaWidget = Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Colors.white10, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.calendar_today, color: Color(0xFFFFD700)),
                const SizedBox(width: 12),
                Text(
                  'أجندة جلسات اليوم (${now.year}-${now.month}-${now.day})',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFD4AF37)),
                ),
              ],
            ),
            const Divider(height: 24, color: Colors.white24),
            if (todaySessions.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40.0),
                child: Center(
                  child: Text(
                    'لا توجد جلسات مجدولة اليوم.',
                    style: TextStyle(color: Colors.white70, fontSize: 15),
                  ),
                ),
              )
            else
              LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minWidth: constraints.maxWidth),
                      child: DataTable(
                        columnSpacing: 12,
                        horizontalMargin: 8,
                        headingRowColor: WidgetStateProperty.all(const Color(0xFF161616)),
                        columns: const [
                          DataColumn(label: Text('الموعد', style: TextStyle(color: Color(0xFFD4AF37)))),
                          DataColumn(label: Text('رقم القضية', style: TextStyle(color: Color(0xFFD4AF37)))),
                          DataColumn(label: Text('المحكمة / الدائرة', style: TextStyle(color: Color(0xFFD4AF37)))),
                          DataColumn(label: Text('القرار المتوقع/السابق', style: TextStyle(color: Color(0xFFD4AF37)))),
                        ],
                        rows: todaySessions.map((session) {
                          final relatedCase = cases.firstWhere((c) => c.id == session.caseId,
                              orElse: () => Case(caseNumber: 'مجهول', caseType: '', court: '', circle: '', clientId: 0));
                          return DataRow(
                            cells: [
                              DataCell(Text(
                                '${session.sessionDate.hour}:${session.sessionDate.minute.toString().padLeft(2, '0')}',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFFFD700)),
                              )),
                              DataCell(Text(relatedCase.caseNumber)),
                              DataCell(Text('${relatedCase.court} - ${relatedCase.circle}')),
                              DataCell(Text(session.decision ?? 'لا يوجد')),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('لوحة التحكم الرئيسية', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFFD4AF37))),
          const SizedBox(height: 24),
          if (isDesktopLarge)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // الجانب الأيمن (كروت إحصائية)
                SizedBox(width: 320, child: statsWidgets),
                const SizedBox(width: 24),
                // الجانب الأيسر (أجندة جلسات اليوم)
                Expanded(child: agendaWidget),
              ],
            )
          else
            Column(
              children: [
                statsWidgets,
                const SizedBox(height: 24),
                agendaWidget,
              ],
            ),
        ],
      ),
    );
  }
}
