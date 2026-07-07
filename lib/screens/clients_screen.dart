import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import '../models/client.dart';
import '../models/case.dart';
import '../models/power_of_attorney.dart';
import '../services/document_helper.dart';

class ClientsScreen extends StatelessWidget {
  final List<Client> clients;
  final List<PowerOfAttorney> poas;
  final List<Case> cases;
  final VoidCallback onAddClient;
  final Function(int) onDeleteClient;

  const ClientsScreen({
    super.key,
    required this.clients,
    required this.poas,
    required this.cases,
    required this.onAddClient,
    required this.onDeleteClient,
  });

  void _showClientDetails(BuildContext context, Client client) {
    final clientCases = cases.where((c) => c.clientId == client.id).toList();
    final clientPoas = poas.where((p) => p.clientId == client.id).toList();

    showDialog(
      context: context,
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: Text('تفاصيل الموكل: ${client.name}', style: const TextStyle(color: Color(0xFFD4AF37))),
            content: SizedBox(
              width: 600,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListTile(
                      leading: const Icon(Icons.badge, color: Color(0xFFFFD700)),
                      title: const Text('الرقم القومي'),
                      subtitle: Text(client.nationalId),
                    ),
                    ListTile(
                      leading: const Icon(Icons.phone, color: Color(0xFFFFD700)),
                      title: const Text('الهاتف'),
                      subtitle: Text(client.phone ?? 'غير متوفر'),
                    ),
                    ListTile(
                      leading: const Icon(Icons.home, color: Color(0xFFFFD700)),
                      title: const Text('العنوان'),
                      subtitle: Text(client.address ?? 'غير متوفر'),
                    ),
                    const Divider(color: Colors.white24),
                    const Text('القضايا المرتبطة:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFD4AF37))),
                    const SizedBox(height: 8),
                    if (clientCases.isEmpty)
                      const Text('لا توجد قضايا لهذا الموكل حالياً.')
                    else
                      ...clientCases.map((c) => Card(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            color: const Color(0xFF161616),
                            child: ListTile(
                              title: Text('رقم القضية: ${c.caseNumber} - ${c.caseType}'),
                              subtitle: Text('المحكمة: ${c.court} - الدائرة: ${c.circle}'),
                            ),
                          )),
                    const Divider(color: Colors.white24),
                    const Text('التوكيلات الرسمية:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFD4AF37))),
                    const SizedBox(height: 8),
                    if (clientPoas.isEmpty)
                      const Text('لا توجد توكيلات لهذا الموكل حالياً.')
                    else
                      ...clientPoas.map((poa) => Card(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            color: const Color(0xFF161616),
                            child: ListTile(
                              title: Text('توكيل رقم: ${poa.poaNumber}'),
                              subtitle: Text('مكتب التوثيق: ${poa.documentationOffice}\nالملف: ${poa.filePath != null ? p.basename(poa.filePath!) : "غير مرفق"}'),
                              trailing: poa.filePath != null && poa.filePath!.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.open_in_new, color: Color(0xFFFFD700)),
                                      tooltip: 'عرض الملف المرفق',
                                      onPressed: () async {
                                        final success = await DocumentHelper.openDocument(poa.filePath!);
                                        if (!success && context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('عذراً، تعذر فتح الملف أو الملف غير موجود محلياً.', style: TextStyle(color: Colors.white)),
                                              backgroundColor: Colors.redAccent,
                                            ),
                                          );
                                        }
                                      },
                                    )
                                  : null,
                            ),
                          )),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('إغلاق', style: TextStyle(color: Color(0xFFD4AF37))),
              )
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('سجل الموكلين', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFFD4AF37))),
            ElevatedButton.icon(
              onPressed: onAddClient,
              icon: const Icon(Icons.add),
              label: const Text('إضافة موكل'),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Expanded(
          child: clients.isEmpty
              ? const Center(child: Text('لا يوجد موكلين مسجلين بعد.'))
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
                                  DataColumn(label: Text('الاسم', style: TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('الرقم القومي', style: TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('الهاتف', style: TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('العنوان', style: TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('الإجراءات', style: TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold))),
                                ],
                                rows: clients.map((client) {
                                  return DataRow(
                                    cells: [
                                      DataCell(Text(client.name, style: const TextStyle(fontWeight: FontWeight.bold))),
                                      DataCell(Text(client.nationalId)),
                                      DataCell(Text(client.phone ?? 'غير متوفر')),
                                      DataCell(Text(client.address ?? 'غير متوفر')),
                                      DataCell(
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.visibility_outlined, color: Color(0xFFD4AF37)),
                                              tooltip: 'عرض التفاصيل والتوكيلات والقضايا',
                                              onPressed: () => _showClientDetails(context, client),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                              tooltip: 'حذف الموكل',
                                              onPressed: () => onDeleteClient(client.id!),
                                            ),
                                          ],
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
