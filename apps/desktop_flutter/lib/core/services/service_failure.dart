/// Failure categories shared by Flutter service and repository contracts.
///
/// Implementations may translate HTTP, database, file-system, or demo errors
/// into these stable categories without leaking infrastructure details into
/// widgets.
enum ServiceFailureKind {
  validation,
  authenticationRequired,
  permissionDenied,
  notFound,
  conflict,
  unavailable,
  securityRejected,
  cancelled,
  unknown,
}

class ServiceFailure implements Exception {
  const ServiceFailure({
    required this.kind,
    required this.message,
    this.code,
    this.cause,
  });

  final ServiceFailureKind kind;
  final String message;
  final String? code;
  final Object? cause;

  @override
  String toString() {
    final failureCode = code == null ? '' : ' [$code]';
    return 'ServiceFailure.${kind.name}$failureCode: $message';
  }
}
