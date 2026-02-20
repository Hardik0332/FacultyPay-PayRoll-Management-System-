import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ReportService {
  /// Generates a PDF Report/Ledger
  static Future<void> printHistoryReport({
    required String title,
    required String subtitle,
    required List<QueryDocumentSnapshot> docs,
    required bool isAdminReport,
    Map<String, String>? facultyNames,
    Map<String, double>? facultyRates, // ✅ Added for Admin Salary Calc
    String? singleFacultyName, // ✅ Added for Individual Info Header
    String? singleFacultyDept, // ✅ Added for Individual Info Header
    double? singleFacultyRate, // ✅ Added for Individual Info Header
    required double totalAmountPaid,
  }) async {
    final doc = pw.Document();

    // Load Font (Required for Rupee Symbol)
    final ttf = await PdfGoogleFonts.robotoRegular();
    final ttfBold = await PdfGoogleFonts.robotoBold();

    // Prepare Data for Table
    final tableData = <List<String>>[];

    // ✅ Header Row: Added 'Earned' column only for Admin Report
    final headers = isAdminReport
        ? ['Date', 'Faculty', 'Class - Subject', 'Lectures', 'Status', 'Earned']
        : ['Date', 'Class - Subject', 'Lectures', 'Status'];

    tableData.add(headers);

    // Rows
    for (var d in docs) {
      final data = d.data() as Map<String, dynamic>;
      final date = (data['date'] as Timestamp).toDate();
      final dateStr = DateFormat('dd MMM yyyy').format(date);
      final subject = data['subject'] ?? '-';
      final int lecturesCount = data['lectures'] as int? ?? 0;
      final lectures = lecturesCount.toString();
      final status = data['status'] ?? 'Pending';

      if (isAdminReport) {
        final uid = data['uid'] ?? '';
        final name = facultyNames?[uid] ?? 'Unknown';
        final rate = facultyRates?[uid] ?? 0.0;
        final earned = (lecturesCount * rate).toStringAsFixed(2);

        // ✅ Add Earned Calculation to Row
        tableData.add([dateStr, name, subject, lectures, status, "₹ $earned"]);
      } else {
        tableData.add([dateStr, subject, lectures, status]);
      }
    }

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(base: ttf, bold: ttfBold),
        build: (context) => [
          // HEADER
          pw.Header(
            level: 0,
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text("FacultyPay", style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
                pw.Text("HISTORY REPORT", style: pw.TextStyle(fontSize: 16, color: PdfColors.grey)),
              ],
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Text(title, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
          pw.Text(subtitle, style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
          pw.SizedBox(height: 20),

          // ✅ INDIVIDUAL REPORT INFO HEADER
          if (!isAdminReport && singleFacultyName != null) ...[
            pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text("Faculty: $singleFacultyName", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
                        pw.Text("Department: ${singleFacultyDept?.toUpperCase()}", style: const pw.TextStyle(fontSize: 12)),
                      ]
                  ),
                  pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text("Hourly Rate: ₹ ${singleFacultyRate?.toStringAsFixed(2)}", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14, color: PdfColors.green)),
                      ]
                  )
                ]
            ),
            pw.SizedBox(height: 20),
          ],

          // TABLE
          pw.Table.fromTextArray(
            headers: tableData.first,
            data: tableData.sublist(1),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
            headerDecoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xff45a182)),
            rowDecoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300))),
            cellHeight: 25,
            cellAlignments: isAdminReport
                ? {
              0: pw.Alignment.centerLeft,
              1: pw.Alignment.centerLeft,
              2: pw.Alignment.centerLeft,
              3: pw.Alignment.center,
              4: pw.Alignment.center,
              5: pw.Alignment.centerRight, // ✅ Earned Column Alignment
            }
                : {
              0: pw.Alignment.centerLeft,
              1: pw.Alignment.centerLeft,
              2: pw.Alignment.center,
              3: pw.Alignment.center,
            },
          ),

          pw.SizedBox(height: 20),
          pw.Divider(),

          // FOOTER WITH TOTAL AMOUNT PAID
          pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text("Total Records: ${docs.length}", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.Text("Total Amount Paid: ₹ ${totalAmountPaid.toStringAsFixed(2)}",
                    style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.green)),
              ]
          ),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
      name: 'Report_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
  }
}