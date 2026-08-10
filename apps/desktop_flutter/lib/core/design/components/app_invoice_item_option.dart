import 'package:flutter/foundation.dart';

/// Stable item identity plus the two labels shown by invoice editors.
///
/// The shared table stays independent from feature repositories while still
/// returning an entity reference instead of guessing identity from free text.
@immutable
class AppInvoiceItemOption {
  const AppInvoiceItemOption({
    required this.id,
    required this.code,
    required this.name,
  });

  final String id;
  final String code;
  final String name;
}
