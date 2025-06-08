import 'package:chatty/utils/repository/chat_repository.dart';
import 'package:chatty/utils/service_locator.dart';
import 'package:chatty/utils/rx_controller.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Import SharedPreferences

// 55:AppSettingController
class AppSettingController extends RxController<AppSettingState> {
  final chatRepository = sl<ChatRepository>();

  @override
  AppSettingState initState() {
    return AppSettingState(
      fontSize: 14.0,
      theme: ThemeMode.light,
      defaultAssistantId: null,
      defaultModelId: null,
    );
  }

  void setDefaultAssistant(String assistantId) {
    setState((state) => state.copyWith(defaultAssistantId: assistantId));
    updatePreferences(
      state.theme == ThemeMode.dark,
      state.fontSize,
      assistantId,
      state.defaultModelId,
    );
  }

  void setDefaultModel(String modelId) {
    setState((state) => state.copyWith(defaultModelId: modelId));
    updatePreferences(
      state.theme == ThemeMode.dark,
      state.fontSize,
      state.defaultAssistantId,
      modelId,
    );
  }

  void setFontSize(double size) {
    setState((state) => state.copyWith(fontSize: size));
    updatePreferences(
      state.theme == ThemeMode.dark,
      size,
      state.defaultAssistantId,
      state.defaultModelId,
    ); // Save font size
  }

  void setTheme(ThemeMode theme) {
    setState((state) => state.copyWith(theme: theme));
    updatePreferences(
      theme == ThemeMode.dark,
      state.fontSize,
      state.defaultAssistantId,
      state.defaultModelId,
    ); // Save theme
  }

  Future<void> loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final models = await chatRepository.getAIModels();
    final assistants = await chatRepository.getAssistants();

    setState((state) {
      final isDarkMode = prefs.getBool('isDarkMode') ?? false;
      final fontSize = prefs.getDouble('fontSize') ?? 14.0;

      // Get available models & assistants

      final omini =
          models.where((e) => e.model == 'gpt-4o-mini').firstOrNull?.id;
      final assistant =
          assistants.where((e) => e.name == '🤖 Default').firstOrNull?.id;
      // End

      final assistantId = prefs.getString('defaultAssistantId') ?? omini;
      final modelId = prefs.getString('defaultModelId') ?? assistant;

      return state.copyWith(
        theme: isDarkMode ? ThemeMode.dark : ThemeMode.light,
        fontSize: fontSize,
        defaultAssistantId: assistantId,
        defaultModelId: modelId,
      );
    });
  }

  Future<void> updatePreferences(
    bool isDarkMode,
    double fontSize,
    String? assistantId,
    String? modelId,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', isDarkMode);
    await prefs.setDouble('fontSize', fontSize);
    if (assistantId != null) {
      await prefs.setString('defaultAssistantId', assistantId);
    }
    if (modelId != null) {
      await prefs.setString('defaultModelId', modelId);
    }
  }
}

// 55:AppSettingState
class AppSettingState {
  final double fontSize;
  final ThemeMode theme;
  final String? defaultAssistantId;
  final String? defaultModelId;

  AppSettingState({
    required this.fontSize,
    required this.theme,
    this.defaultAssistantId,
    this.defaultModelId,
  });

  AppSettingState copyWith({
    double? fontSize,
    ThemeMode? theme,
    String? defaultAssistantId,
    String? defaultModelId,
  }) {
    return AppSettingState(
      fontSize: fontSize ?? this.fontSize,
      theme: theme ?? this.theme,
      defaultAssistantId: defaultAssistantId ?? this.defaultAssistantId,
      defaultModelId: defaultModelId ?? this.defaultModelId,
    );
  }
}
