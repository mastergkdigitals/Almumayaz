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
    final repositories = AppRepositories.forProfile(profile);
    return AppDataComposition(
      repositories: repositories,
      services: AppServices.demo(profile: profile),
    );
  }

  factory AppDataComposition.desktop(AppDataProfile profile) {
    final repositories = AppRepositories.forProfile(profile);
    return AppDataComposition(
      repositories: repositories,
      services: AppServices.desktop(
        deviceSettings: repositories.deviceSettings,
        profile: profile,
      ),
    );
  }

  final AppRepositories repositories;
  final AppServices services;
}
