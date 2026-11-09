import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:charge_mate/app/app.dart';
import 'package:charge_mate/injection.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await configureDependencies();
  runApp(const ChargeMateApp());
}
