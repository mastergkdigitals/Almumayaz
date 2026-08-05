import 'package:erp/core/data/app_repository.dart';
import 'package:erp/core/domain/business_values.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('business values', () {
    test('parses currencies and money without floating point drift', () {
      expect(AppCurrency.parse('usd'), AppCurrency.usd);
      expect(Money.parse('15.30', AppCurrency.usd).minorUnits, 1530);
      expect(Money.parse('١٬٣١٠', AppCurrency.iqd).minorUnits, 1310);
      expect(
        Money.parse('15.305', AppCurrency.usd).toPlainString(),
        '15.31',
      );
    });

    test('keeps money arithmetic inside one currency', () {
      final total = Money.parse('100.00', AppCurrency.usd);
      final discount = total.percentage(Percentage.parse('15.30'));

      expect(discount.toPlainString(), '15.30');
      expect((total - discount).toPlainString(), '84.70');
      expect(
        () => total + Money.parse('1', AppCurrency.iqd),
        throwsArgumentError,
      );
      expect((-discount).toPlainString(), '-15.30');
      expect((-discount).absolute, discount);
      expect(
        Money.parse('120.00', AppCurrency.usd).clamp(
          maximum: total,
        ),
        total,
      );
      expect(
        Money.parse('-5.00', AppCurrency.usd).clamp(
          minimum: Money.zero(AppCurrency.usd),
        ),
        Money.zero(AppCurrency.usd),
      );
    });

    test('validates exchange rates percentages and whole quantities', () {
      expect(ExchangeRate.parse('1,310').toPlainString(), '1310');
      expect(
        const ExchangeRate.fromTenThousandths(13100000),
        ExchangeRate.parse('1310'),
      );
      expect(Percentage.parse('15.30').basisPoints, 1530);
      expect(WholeQuantity.parse('٢٥').value, 25);
      expect(() => ExchangeRate.parse('0'), throwsArgumentError);
      expect(() => Percentage.parse('100.01'), throwsArgumentError);
      expect(() => WholeQuantity.parse('1.5'), throwsFormatException);
      expect(
        WholeQuantity(7) + WholeQuantity(5),
        WholeQuantity(12),
      );
      expect(
        WholeQuantity(7) - WholeQuantity(5),
        WholeQuantity(2),
      );
      expect(
        () => WholeQuantity(5) - WholeQuantity(7),
        throwsStateError,
      );
    });

    test('normalizes business dates and audit timestamps', () {
      final date = BusinessDate.fromDateTime(DateTime(2026, 8, 5, 23, 45));
      final timestamp = AuditTimestamp(
        DateTime.parse('2026-08-05T12:00:00+03:00'),
      );

      expect(date.toString(), '2026-08-05');
      expect(BusinessDate.parse('2026-08-05'), date);
      expect(date.atTime(hour: 9).hour, 9);
      expect(timestamp.utcDate, BusinessDate(2026, 8, 5));
      expect(timestamp.toString(), '2026-08-05T09:00:00.000Z');
      expect(() => BusinessDate(2026, 2, 30), throwsArgumentError);
      expect(() => BusinessDate.parse('05/08/2026'), throwsFormatException);
    });

    test('creates stable demo entity IDs separately from visible numbers', () {
      expect(EntityId.demo('sale', 12).value, 'demo-sale-12');
      expect(EntityId.demo('sale', 12), EntityId('demo-sale-12'));
      expect(() => EntityId('  '), throwsArgumentError);
    });
  });

  group('repository foundation', () {
    test('represents every shared screen state', () {
      expect(const AppDataState<int>.loading().status, AppDataStatus.loading);
      expect(const AppDataState<int>.ready(1).hasData, isTrue);
      expect(const AppDataState<int>.empty().status, AppDataStatus.empty);
      expect(
        const AppDataState<int>.missingReference('missing').status,
        AppDataStatus.missingReference,
      );
      expect(
        const AppDataState<int>.error('failed').status,
        AppDataStatus.error,
      );
    });

    test('supports reusable in-memory demo repositories', () async {
      final repository = _TestRepository([
        _TestRecord(EntityId.demo('record', 1), 'الأول'),
      ]);

      final second = _TestRecord(EntityId.demo('record', 2), 'الثاني');
      await repository.save(second);
      expect(await repository.getById(second.id), second);
      expect(
        await repository.canDelete(second.id),
        isA<DeleteDecision>().having(
          (value) => value.isAllowed,
          'allowed',
          true,
        ),
      );
      await repository.delete(second.id);
      expect(await repository.getById(second.id), isNull);
    });
  });
}

class _TestRecord {
  const _TestRecord(this.id, this.name);

  final EntityId id;
  final String name;
}

class _TestRepository extends InMemoryDemoRepository<_TestRecord> {
  _TestRepository(Iterable<_TestRecord> values)
      : super(initialValues: values, idOf: (value) => value.id);
}
