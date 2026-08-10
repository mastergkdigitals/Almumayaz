import 'package:erp/core/printing/document_output_service.dart';
import 'package:erp/core/services/service_failure.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const service = DemoDocumentOutputService();
  const request = DocumentOutputRequest(
    title: 'قائمة تجريبية رقم 7',
    subtitle: 'طرف تجريبي',
    fileNameBase: 'قائمة تجريبية 7',
    fields: [
      DocumentField(label: 'المخزن', value: 'الرئيسي'),
      DocumentField(
        label: 'المجموع',
        value: '98,765',
        isPrice: true,
      ),
    ],
    columns: [
      DocumentColumn(label: 'المادة'),
      DocumentColumn(label: 'الكمية'),
      DocumentColumn(label: 'السعر', isPrice: true),
    ],
    rows: [
      ['دفتر', '3', '12,345'],
    ],
  );

  test('creates deterministic full and without-prices print previews', () async {
    final full = await service.createPreview(request);
    final withoutPrices = await service.createPreview(
      request,
      includePrices: false,
    );

    expect(full.action, DocumentOutputAction.print);
    expect(full.content, contains('المجموع: 98,765'));
    expect(full.content, contains('السعر'));
    expect(full.content, contains('12,345'));

    expect(
      withoutPrices.action,
      DocumentOutputAction.printWithoutPrices,
    );
    expect(withoutPrices.title, 'معاينة الطباعة بدون أسعار');
    expect(withoutPrices.content, contains('دفتر | 3'));
    expect(withoutPrices.content, isNot(contains('المجموع')));
    expect(withoutPrices.content, isNot(contains('السعر')));
    expect(withoutPrices.content, isNot(contains('12,345')));
    expect(withoutPrices.content, isNot(contains('98,765')));
  });

  test('creates deterministic PDF and Excel result names and content', () async {
    final pdf = await service.export(request, DocumentExportFormat.pdf);
    final excel = await service.export(
      request,
      DocumentExportFormat.excel,
    );

    expect(pdf.action, DocumentOutputAction.pdf);
    expect(pdf.fileName, 'قائمة_تجريبية_7.pdf');
    expect(pdf.content, contains('دفتر | 3 | 12,345'));

    expect(excel.action, DocumentOutputAction.excel);
    expect(excel.fileName, 'قائمة_تجريبية_7.xlsx');
    expect(excel.content, contains('دفتر\t3\t12,345'));
  });

  test('rejects rows that do not match the declared document columns', () {
    const invalidRequest = DocumentOutputRequest(
      title: 'مستند',
      columns: [DocumentColumn(label: 'عمودان')],
      rows: [
        ['قيمة', 'قيمة زائدة'],
      ],
    );

    expect(
      service.createPreview(invalidRequest),
      throwsA(
        isA<ServiceFailure>().having(
          (failure) => failure.code,
          'code',
          'document_columns_mismatch',
        ),
      ),
    );
  });
}
