import 'package:flutter/material.dart';
import '../models/case.dart';
import '../models/client.dart';

class CasesScreen extends StatelessWidget {
  final List<Case> cases;
  final List<Client> clients;
  final VoidCallback onAddCase;
  final Function(int) onDeleteCase;

  const CasesScreen({
    super.key,
    required this.cases,
    required this.clients,
    required this.onAddCase,
    required this.onDeleteCase,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('سجل القضايا والملفات القانونية', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFFD4AF37))),
            ElevatedButton.icon(
              onPressed: onAddCase,
              icon: const Icon(Icons.add),
              label: const Text('إضافة قضية جديدة'),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Expanded(
          child: cases.isEmpty
              ? const Center(child: Text('لا توجد قضايا مسجلة.'))
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
                                  DataColumn(label: Text('رقم القضية', style: TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('نوع القضية', style: TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('المحكمة', style: TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('الدائرة', style: TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('الموكل', style: TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('الإجراءات', style: TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold))),
                                ],
                                rows: cases.map((item) {
                                  final client = clients.firstWhere((c) => c.id == item.clientId,
                                      orElse: () => Client(name: 'موكل مجهول', nationalId: ''));
                                  return DataRow(
                                    cells: [
                                      DataCell(Text(item.caseNumber, style: const TextStyle(fontWeight: FontWeight.bold))),
                                      DataCell(Text(item.caseType)),
                                      DataCell(Text(item.court)),
                                      DataCell(Text(item.circle)),
                                      DataCell(Text(client.name)),
                                      DataCell(
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                          tooltip: 'حذف القضية',
                                          onPressed: () => onDeleteCase(item.id!),
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
