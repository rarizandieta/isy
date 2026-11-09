import 'package:flutter/material.dart';

import 'app.dart';
import 'core/http_client_factory.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final httpClient = await buildHttpClient();
  runApp(IsyApp(httpClient: httpClient));
}
