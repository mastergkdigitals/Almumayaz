import 'package:flutter/widgets.dart';

import 'app/app.dart';
import 'core/app_state/app_store.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(AlmumayazApp(store: AppStore.desktop()));
}
