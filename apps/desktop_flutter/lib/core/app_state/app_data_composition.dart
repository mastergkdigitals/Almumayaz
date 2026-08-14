import '../../features/audit_log/data/demo_business_audit.dart';
import '../../features/authentication/data/demo_authentication_service.dart';
import '../../features/authentication/data/demo_identity_state.dart';
import '../data/demo_transaction_runner.dart';
import 'app_data_profile.dart';
import 'app_repositories.dart';
import 'app_services.dart';

typedef AppDataCompositionBuilder = AppDataComposition Function(
  AppDataProfile profile,
);

/// A complete repository/service graph prepared before it becomes live.
class AppDataComposition {
  const AppDataComposition({
    required this.repositories,
    required this.services,
  });

  factory AppDataComposition.demo(AppDataProfile profile) {
    final transactionRunner = DemoTransactionRunner();
    final identityState = _identityStateForProfile(
      profile,
      transactionRunner: transactionRunner,
    );
    final identity = DemoIdentityServiceBundle(
      startsAuthenticated: false,
      state: identityState,
    );
    final repositories = AppRepositories.forProfile(
      profile,
      transactionRunner: transactionRunner,
      businessAudit: DemoBusinessAudit(state: identityState),
    );
    return AppDataComposition(
      repositories: repositories,
      services: AppServices.demo(
        profile: profile,
        identityBundle: identity,
      ),
    );
  }

  factory AppDataComposition.desktop(AppDataProfile profile) {
    final transactionRunner = DemoTransactionRunner();
    final identityState = _identityStateForProfile(
      profile,
      transactionRunner: transactionRunner,
    );
    final identity = DemoIdentityServiceBundle(
      startsAuthenticated: false,
      state: identityState,
    );
    final repositories = AppRepositories.forProfile(
      profile,
      transactionRunner: transactionRunner,
      businessAudit: DemoBusinessAudit(state: identityState),
    );
    return AppDataComposition(
      repositories: repositories,
      services: AppServices.desktop(
        deviceSettings: repositories.deviceSettings,
        profile: profile,
        identityBundle: identity,
      ),
    );
  }

  final AppRepositories repositories;
  final AppServices services;
}

DemoIdentityState _identityStateForProfile(
  AppDataProfile profile, {
  required DemoTransactionRunner transactionRunner,
}) {
  return profile == AppDataProfile.cleared
      ? DemoIdentityState.bootstrap(transactionRunner: transactionRunner)
      : DemoIdentityState(transactionRunner: transactionRunner);
}
