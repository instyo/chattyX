import 'package:chatty/app.dart';
import 'package:chatty/screens/ai_models/models_screen.dart';
import 'package:chatty/screens/assistants/assistants_setting.dart';
import 'package:chatty/utils/service_locator.dart';
import 'package:chatty/screens/settings/app_setting_controller.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Ensure Flutter is initialized
  await setupServiceLocator();
  if (kIsWeb) {
    BrowserContextMenu.disableContextMenu();
  }
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
