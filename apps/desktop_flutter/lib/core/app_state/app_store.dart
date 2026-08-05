import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../../features/authentication/domain/session_models.dart';
import 'app_repositories.dart';
import 'app_services.dart';

class AppStore extends ChangeNotifier {
  AppStore({
    required this.repositories,
    AppServices? services,
  }) : services = services ?? AppServices.demo();

  factory AppStore.demo() {
    return AppStore(
      repositories: AppRepositories.demo(),
      services: AppServices.demo(),
    );
  }

  final AppRepositories repositories;
  final AppServices services;
  AppSession? _session;
  int _revision = 0;

  AppSession? get session => _session;
  int get revision => _revision;

  Future<AppSession> signIn(SignInCredentials credentials) async {
    final session = await services.authentication.signIn(credentials);
    _session = session;
    notifyListeners();
    return session;
  }

  Future<void> signOut() async {
    await services.authentication.signOut();
    _session = null;
    notifyListeners();
  }

  /// Feature controllers call this after a repository mutation when they are
  /// migrated. It gives cross-module listeners one lightweight invalidation
  /// signal without coupling repositories to presentation state.
  void markDataChanged() {
    _revision++;
    notifyListeners();
  }
}

class AppStoreScope extends InheritedNotifier<AppStore> {
  const AppStoreScope({
    super.key,
    required AppStore store,
    required super.child,
  }) : super(notifier: store);

  static AppStore of(BuildContext context, {bool listen = true}) {
    final scope = listen
        ? context.dependOnInheritedWidgetOfExactType<AppStoreScope>()
        : context.getInheritedWidgetOfExactType<AppStoreScope>();
    assert(scope != null, 'No AppStoreScope found in this context');
    return scope!.notifier!;
  }
}

class AppStoreProvider extends StatefulWidget {
  const AppStoreProvider({
    super.key,
    this.store,
    required this.child,
  });

  final AppStore? store;
  final Widget child;

  @override
  State<AppStoreProvider> createState() => _AppStoreProviderState();
}

class _AppStoreProviderState extends State<AppStoreProvider> {
  late AppStore _store;
  late bool _ownsStore;

  @override
  void initState() {
    super.initState();
    _setStore(widget.store);
  }

  @override
  void didUpdateWidget(AppStoreProvider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.store == widget.store) return;
    if (_ownsStore) _store.dispose();
    _setStore(widget.store);
  }

  void _setStore(AppStore? suppliedStore) {
    _ownsStore = suppliedStore == null;
    _store = suppliedStore ?? AppStore.demo();
  }

  @override
  void dispose() {
    if (_ownsStore) _store.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppStoreScope(store: _store, child: widget.child);
  }
}
