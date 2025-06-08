import 'package:chatty/app.dart';
import 'package:chatty/utils/databases/firebase_db.dart';
import 'package:chatty/firebase_options.dart';
import 'package:chatty/utils/service_locator.dart';
import 'package:chatty/screens/settings/app_setting_controller.dart';
import 'package:chatty/screens/assistants/assistants_setting.dart';
import 'package:chatty/screens/ai_models/models_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    // name: '[DEFAULT]',
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await setupServiceLocator(useFirebase: true);
  await sl<FirebaseDb>().init(); // Initialize the database

  runApp(
    MultiProvider(
      providers: [
        Provider(
          create: (context) => AppSettingController()..loadPreferences(),
        ),
        Provider(create: (context) => ModelsController()..getAiModels()),
        Provider(
          create: (context) => AssistantsController()..getAiAssistants(),
        ),
      ],
      child: const ChatApp(),
    ),
  );
}
