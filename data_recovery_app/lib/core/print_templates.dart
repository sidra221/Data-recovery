import 'dart:typed_data';

import 'package:barcode/barcode.dart' show Barcode;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/job.dart';
import 'pdf_theme.dart';

/// مطبوعات الاستلام: الستيكر يلي بينلزق على القطعة، وسند الاستلام للعميل.
///
/// الاتنين بيتولّدوا من نفس بيانات العملية، وبيستعملوا نفس الخطوط المدمجة
/// حتى العربي يطلع صح.
class PrintTemplates {
  /// مقاس ملصق الطابعة الحرارية.
  ///
  /// **هون بتتغيّر المقاسات لو الطابعة مختلفة.** مقاسات شائعة تانية:
  /// 100×50، 57×40، 50×30 ملم. لو المقاس غلط، الطابعة إما بتقص المحتوى
  /// أو بتطلع ورقة فاضية — فلازم يطابق الملصق الفعلي.
  static const stickerWidthMm = 100.0;
  static const stickerHeightMm = 70.0;

  static PdfPageFormat get _stickerFormat => PdfPageFormat(
        stickerWidthMm * PdfPageFormat.mm,
        stickerHeightMm * PdfPageFormat.mm,
        marginAll: 3 * PdfPageFormat.mm,
      );

  static String _date(DateTime value) =>
      DateFormat('dd/MM/yyyy', 'en').format(value.toLocal());

  static String _dateTime(DateTime value) =>
      DateFormat('dd/MM/yyyy hh:mm:ss a', 'en').format(value.toLocal());

  /// الستيكر يلي بينلزق فوق القطعة المستلمة.
  ///
  /// الباركود هو رقم الفاتورة نفسه — مسحه بيفتح العملية مباشرة.
  static Future<Uint8List> sticker({
    required Job job,
    required String companyName,
  }) async {
    final theme = await PdfTheme.load();
    final doc = pw.Document(theme: theme);

    doc.addPage(
      pw.Page(
        pageFormat: _stickerFormat,
        theme: theme,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              // رأس: اسم الشركة يسار، الباركود يمين.
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(3),
                      decoration: pw.BoxDecoration(border: pw.Border.all(width: 0.6)),
                      child: pw.Center(
                        child: rtlAware(
                          companyName,
                          style: pw.TextStyle(
                            fontSize: 8,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  pw.SizedBox(width: 6),
                  pw.Expanded(
                    flex: 2,
                    child: pw.BarcodeWidget(
                      barcode: Barcode.code128(),
                      data: job.barcode,
                      drawText: false,
                      height: 34,
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 4),
              pw.Expanded(
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(
                      flex: 3,
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          _stickerLine('Inv', job.invoiceNumber, bold: true),
                          _stickerLine('Name', job.customerName),
                          _stickerLine('Mobile', job.customerPhone),
                          _stickerLine('RDate', _date(job.createdAt)),
                          _stickerLine('Model', job.deviceModel),
                          _stickerLine('Types', job.hardDiskTypeLabel),
                        ],
                      ),
                    ),
                    pw.SizedBox(width: 5),
                    pw.Expanded(
                      flex: 2,
                      child: pw.Container(
                        height: double.infinity,
                        padding: const pw.EdgeInsets.all(3),
                        decoration: pw.BoxDecoration(border: pw.Border.all(width: 0.6)),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              'Description',
                              style: const pw.TextStyle(fontSize: 6.5, color: PdfColors.grey700),
                            ),
                            pw.SizedBox(height: 2),
                            pw.Expanded(
                              child: rtlAware(
                                job.problem,
                                style: const pw.TextStyle(fontSize: 7.5),
                                maxLines: 6,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
    return doc.save();
  }

  static pw.Widget _stickerLine(String label, String value, {bool bold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 1.5),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 34,
            child: pw.Text(
              '$label :',
              style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey800),
            ),
          ),
          pw.Expanded(
            child: rtlAware(
              value.isEmpty ? '—' : value,
              style: pw.TextStyle(
                fontSize: 8,
                fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
              ),
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }

  /// سند الاستلام يلي بياخده العميل كإثبات إن القطعة عندنا.
  ///
  /// ثنائي اللغة دايماً (إنكليزي يسار / عربي يمين) متل النموذج المعتمد، مو
  /// حسب لغة التطبيق — لأنه ورقة بتنعطى للعميل وممكن يقرأها حدا تاني.
  static Future<Uint8List> receivingReceipt({
    required Job job,
    required String companyName,
  }) async {
    final theme = await PdfTheme.load();
    final doc = pw.Document(theme: theme);

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        theme: theme,
        margin: const pw.EdgeInsets.all(32),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              pw.Center(
                child: pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: pw.BoxDecoration(border: pw.Border.all(width: 0.8)),
                  child: pw.Text(
                    'Receiving Receipt',
                    style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
                  ),
                ),
              ),
              pw.SizedBox(height: 14),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Row(
                    children: [
                      pw.Text('Bill No.. ', style: const pw.TextStyle(fontSize: 10)),
                      pw.Text(
                        job.invoiceNumber,
                        style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
                      ),
                    ],
                  ),
                  pw.Row(
                    children: [
                      pw.Text('Print Dated : ', style: const pw.TextStyle(fontSize: 10)),
                      pw.Text(_date(DateTime.now()), style: const pw.TextStyle(fontSize: 10)),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 8),
              pw.Table(
                border: pw.TableBorder.all(width: 0.6, color: PdfColors.grey600),
                columnWidths: const {
                  0: pw.FlexColumnWidth(2.2),
                  1: pw.FlexColumnWidth(5),
                  2: pw.FlexColumnWidth(2.2),
                },
                children: [
                  _receiptRow('Client Name', job.customerName, 'اسم العميل'),
                  _receiptRow('Client Mobile', job.customerPhone, 'جوال العميل'),
                  _receiptRow('Client Email', job.customerEmail, 'ايميل العميل'),
                  _receiptRow('Receive Date', _dateTime(job.createdAt), 'تاريخ الاستلام'),
                  _receiptRow('Model', job.deviceModel, 'موديل الجهاز'),
                  _receiptRow('Types', job.hardDiskTypeLabel, 'نوع الجهاز'),
                  _receiptRow('S/N', job.serialNumber, 'الرقم التسلسلي'),
                ],
              ),
              pw.SizedBox(height: 14),
              _receiptBox('Customer Comments', 'ملاحظات العميل', job.problem),
              pw.SizedBox(height: 12),
              _receiptBox(
                'Equipment Attach with',
                'الملحقات المرافقة',
                job.attachedEquipment,
              ),
              pw.SizedBox(height: 16),
              pw.Row(
                children: [
                  pw.Text('Status', style: const pw.TextStyle(fontSize: 10)),
                  pw.SizedBox(width: 24),
                  pw.Text(
                    job.statusLabel.isEmpty ? job.status : job.statusLabel,
                    style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
                  ),
                ],
              ),
              pw.Spacer(),
              pw.Center(
                child: rtlAware(
                  companyName,
                  style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
                ),
              ),
            ],
          );
        },
      ),
    );
    return doc.save();
  }

  static pw.TableRow _receiptRow(String english, String value, String arabic) {
    pw.Widget cell(String text, {bool bold = false, pw.TextAlign? align}) {
      return pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: rtlAware(
          text,
          align: align,
          style: pw.TextStyle(
            fontSize: 9.5,
            fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ),
      );
    }

    return pw.TableRow(
      children: [
        cell(english),
        cell(value, bold: true),
        cell(arabic, align: pw.TextAlign.right),
      ],
    );
  }

  static pw.Widget _receiptBox(String english, String arabic, String value) {
    return pw.Container(
      decoration: pw.BoxDecoration(border: pw.Border.all(width: 0.6, color: PdfColors.grey600)),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: const pw.BoxDecoration(
              border: pw.Border(bottom: pw.BorderSide(width: 0.6, color: PdfColors.grey600)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(english, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey800)),
                rtlAware(arabic, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey800)),
              ],
            ),
          ),
          pw.Container(
            height: 62,
            width: double.infinity,
            padding: const pw.EdgeInsets.all(6),
            child: rtlAware(value, style: const pw.TextStyle(fontSize: 10)),
          ),
        ],
      ),
    );
  }
}
