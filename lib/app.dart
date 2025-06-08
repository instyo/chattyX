import 'package:chatty/screens/chat/chat_screen.dart';
import 'package:chatty/screens/settings/app_setting_controller.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class ChatApp extends StatelessWidget {
  const ChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).requestFocus(FocusNode());
      },
      child: StreamBuilder(
        stream: context.read<AppSettingController>().stream,
        builder: (context, state) {
          final fontSize = state.data?.fontSize ?? 14.0;
          final themeMode = state.data?.theme ?? ThemeMode.system;
          final isDark = themeMode == ThemeMode.dark;
          final textTheme = GoogleFonts.interTextTheme(
            Theme.of(context).textTheme.apply(
              fontSizeFactor: fontSize / 14.0,
              displayColor: isDark ? Colors.white : Colors.black,
              bodyColor: isDark ? Colors.white : Colors.black,
            ),
          ); // Apply font size

          return MaterialApp(
            home: ChatScreen(),
            debugShowCheckedModeBanner: false,
            theme: FlexThemeData.light(
              scheme: FlexScheme.mandyRed,
              textTheme: textTheme,
            ),
            darkTheme: FlexThemeData.dark(
              scheme: FlexScheme.mandyRed,
              textTheme: textTheme,
            ),
            themeMode: themeMode, // Set theme mode
          );
        },
      ),
    );
  }
}
