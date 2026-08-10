import '../../features/permissions/domain/permission_models.dart';
import 'app_store.dart';

/// Applies action permissions inside an already-open feature screen.
///
/// A null session is allowed for isolated widget previews/tests. In the real
/// application, the session activity guard prevents feature access before
/// sign-in.
extension FeatureActionPermissions on AppStore {
  bool allowsFeatureAction(String module, PermissionAction action) {
    return session == null || allows(module, action);
  }
}
