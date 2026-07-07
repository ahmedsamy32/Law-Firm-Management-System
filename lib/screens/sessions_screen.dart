import 'package:flutter/material.dart';
import '../models/case.dart';
import '../models/session.dart';

class SessionsScreen extends StatelessWidget {
  final List<Session> sessions;
  final List<Case> cases;
  final VoidCallback onAddSession;
  final Function(int) onDeleteSession;

  const SessionsScreen({
    super.key,
    required this.sessions,
    required this.cases,
    required this.onAddSession,
    required this.onDeleteSession,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('سجل الجلسات والمواعيد', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFFD4AF37))),
            ElevatedButton.icon(
              onPressed: onAddSession,
              icon: const Icon(Icons.add),
              label: const Text('إضافة جلسة جديدة'),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Expanded(
          child: sessions.isEmpty
              ? const Center(child: Text('لا توجد جلسات مسجلة.'))
              : Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: Colors.white10, width: 1),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: SingleChildScrollView(
                            child: ConstrainedBox(
                              constraints: BoxConstraints(minWidth: constraints.maxWidth),
                              child: DataTable(
                                columnSpacing: 24,
                                headingRowColor: WidgetStateProperty.all(const Color(0xFF161616)),
                                columns: const [
                                  DataColumn(label: Text('التاريخ والوقت', style: TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('رقم القضية', style: TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('المحكمة / الدائرة', style: TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('القرار الصادر', style: TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('الطلبات القادمة', style: TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('الإجراءات', style: TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold))),
                                ],
                                rows: sessions.map((session) {
                                  final relatedCase = cases.firstWhere((c) => c.id == session.caseId,
                                      orElse: () => Case(caseNumber: 'مجهول', caseType: '', court: '', circle: '', clientId: 0));
                                  return DataRow(
                                    cells: [
                                      DataCell(Text(
                                        session.sessionDate.toLocal().toString().split('.')[0],
                                        style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFFFD700)),
                                      )),
                                      DataCell(Text(relatedCase.caseNumber)),
                                      DataCell(Text('${relatedCase.court} - ${relatedCase.circle}')),
                                      DataCell(Text(session.decision ?? 'لا يوجد')),
                                      DataCell(Text(session.nextRequirements ?? 'لا يوجد')),
                                      DataCell(
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                          tooltip: 'حذف الجلسة',
                                          onPressed: () => onDeleteSession(session.id!),
                                        ),
                                      ),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}
