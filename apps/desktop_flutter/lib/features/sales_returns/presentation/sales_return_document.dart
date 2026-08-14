import 'package:flutter/material.dart';

import '../../../core/design/app_formatters.dart';
import '../../../core/printing/document_output_service.dart';
import '../domain/sales_return.dart';

DocumentOutputRequest salesReturnDocumentRequest(SalesReturn value) {
  final dateTime = value.date.atTime(
    hour: value.minuteOfDay ~/ Duration.minutesPerHour,
    minute: value.minuteOfDay % Duration.minutesPerHour,
  );
  final decimalPlaces = value.currency.decimalPlaces;
  return DocumentOutputRequest(
    title: 'مرتجع بيع رقم ${value.documentNumber}',
    subtitle: value.customerNameSnapshot.trim().isEmpty
        ? 'زبون غير محدد'
        : value.customerNameSnapshot,
    fileNameBase: 'مرتجع بيع ${value.documentNumber}',
    auditTarget: DocumentOutputAuditTarget(
      entityType: 'sales_return',
      entityId: value.id,
    ),
    fields: [
      DocumentField(
        label: 'رقم قائمة البيع الأصلية',
        value: '${value.originalSalesInvoiceNumberSnapshot}',
        spreadsheetCellKind: DocumentSpreadsheetCellKind.integer,
      ),
      DocumentField(
        label: 'التاريخ',
        value: AppFormatters.date(dateTime),
        spreadsheetCellKind: DocumentSpreadsheetCellKind.date,
      ),
      DocumentField(
        label: 'الوقت',
        value: AppFormatters.time(TimeOfDay.fromDateTime(dateTime)),
        spreadsheetCellKind: DocumentSpreadsheetCellKind.time,
      ),
      DocumentField(label: 'العملة', value: value.currency.arabicName),
      DocumentField(
        label: 'سعر الصرف',
        value: value.exchangeRate.toPlainString(),
        spreadsheetCellKind: DocumentSpreadsheetCellKind.decimal,
        spreadsheetDecimalPlaces: 4,
      ),
      DocumentField(
        label: 'قيمة المرتجع',
        value: value.total.toPlainString(),
        isPrice: true,
        spreadsheetCellKind: DocumentSpreadsheetCellKind.decimal,
        spreadsheetDecimalPlaces: decimalPlaces,
      ),
      DocumentField(
        label: 'المبلغ المسترد',
        value: value.refundedAtReturn.toPlainString(),
        isPrice: true,
        spreadsheetCellKind: DocumentSpreadsheetCellKind.decimal,
        spreadsheetDecimalPlaces: decimalPlaces,
      ),
      DocumentField(
        label: 'المضاف إلى رصيد الزبون',
        value: value.creditedToCustomer.toPlainString(),
        isPrice: true,
        spreadsheetCellKind: DocumentSpreadsheetCellKind.decimal,
        spreadsheetDecimalPlaces: decimalPlaces,
      ),
      if (value.notes.trim().isNotEmpty)
        DocumentField(label: 'الملاحظات', value: value.notes),
    ],
    columns: [
      const DocumentColumn(label: 'رمز المادة'),
      const DocumentColumn(label: 'اسم المادة'),
      const DocumentColumn(label: 'المخزن'),
      const DocumentColumn(
        label: 'الكمية',
        spreadsheetCellKind: DocumentSpreadsheetCellKind.integer,
      ),
      DocumentColumn(
        label: 'صافي سعر البيع',
        isPrice: true,
        spreadsheetCellKind: DocumentSpreadsheetCellKind.decimal,
        spreadsheetDecimalPlaces: decimalPlaces,
      ),
      DocumentColumn(
        label: 'قيمة المرتجع',
        isPrice: true,
        spreadsheetCellKind: DocumentSpreadsheetCellKind.decimal,
        spreadsheetDecimalPlaces: decimalPlaces,
      ),
    ],
    rows: [
      for (final line in value.lines)
        [
          line.itemCodeSnapshot,
          line.itemNameSnapshot,
          line.warehouseNameSnapshot,
          '${line.quantity.value}',
          line.sourceNetUnitPrice.toPlainString(),
          line.allocatedRefund.toPlainString(),
        ],
    ],
  );
}
