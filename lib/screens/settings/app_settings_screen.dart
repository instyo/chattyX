import 'package:chatty/utils/repository/chat_repository.dart';
import 'package:chatty/utils/service_locator.dart';
import 'package:chatty/screens/settings/app_setting_controller.dart';
import 'package:chatty/utils/context_extension.dart';
import 'package:chatty/screens/assistants/assistants_setting.dart';
import 'package:chatty/screens/ai_models/models_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AppSettingsScreen extends StatefulWidget {
  const AppSettingsScreen({super.key});

  @override
  State<AppSettingsScreen> createState() => _AppSettingsScreenState();
}

class _AppSettingsScreenState extends State<AppSettingsScreen> {
  int index = 0;

  void changeIndex(int val) {
    setState(() {
      index = val;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(
        16.0,
      ).copyWith(top: context.isMobile ? 32 : 16),
      child: Column(
        children: [
          // Align(
          //   alignment: Alignment.topRight,
          //   child: IconButton(onPressed: () {}, icon: Icon(CupertinoIcons.clear)),
          // ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildItem(
                context,
                index: 0,
                icon: CupertinoIcons.gear,
                title: "General",
              ),
              _buildItem(
                context,
                index: 1,
                icon: CupertinoIcons.bolt_circle,
                title: "Models",
              ),
              _buildItem(
                context,
                index: 2,
                icon: CupertinoIcons.person_3,
                title: "Assistants",
              ),
            ],
          ),
          IndexedStack(
            index: index,
            children: [_GeneralSetting(), ModelsSetting(), AssistantsSetting()],
          ),
        ],
      ),
    );
  }

  GestureDetector _buildItem(
    BuildContext context, {
    required int index,
    String title = "",
    IconData icon = CupertinoIcons.circle,
  }) {
    final color = index == this.index ? Theme.of(context).primaryColor : null;
    return GestureDetector(
      onTap: () {
        changeIndex(index);
      },
      child: SizedBox(
        height: 52,
        child: Column(
          children: [
            Icon(icon, color: color),
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }
}

class _GeneralSetting extends StatelessWidget {
  const _GeneralSetting();

  @override
  Widget build(BuildContext context) {
    final appSettingController = context.read<AppSettingController>();

    return StreamBuilder(
      stream: appSettingController.stream,
      builder: (context, snapshot) {
        final state = snapshot.data;
        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Toggle for dark/light mode
              Row(
                children: [
                  const Text('Dark Mode'),
                  Spacer(),
                  CupertinoSwitch(
                    value: state?.theme == ThemeMode.dark,
                    onChanged: (value) {
                      appSettingController.setTheme(
                        value ? ThemeMode.dark : ThemeMode.light,
                      );
                    },
                    activeTrackColor:
                        Theme.of(
                          context,
                        ).primaryColor, // Set the active color to primary color
                  ),
                ],
              ),
              // Slider for font size
              Row(
                children: [
                  const Text('Font Size'),
                  Expanded(
                    child: Slider(
                      value: state?.fontSize ?? 14,
                      min: 12,
                      max: 30,
                      divisions: 18,
                      label: state?.fontSize.round().toString(),
                      onChanged: (value) {
                        appSettingController.setFontSize(value);
                      },
                    ),
                  ),
                  Text(state?.fontSize.round().toString() ?? ''),
                ],
              ),
              const SizedBox(height: 16),
              _buildDefaultAssistantDropdown(
                context,
                state,
                appSettingController,
              ),
              const SizedBox(height: 16),
              _buildModelDropdown(context, state, appSettingController),
            ],
          ),
        );
      },
    );
  }

  /// Extracted method for Default Assistant Dropdown
  Widget _buildDefaultAssistantDropdown(
    BuildContext context,
    dynamic state,
    AppSettingController controller,
  ) {
    final assistantController = context.read<AssistantsController>();

    return Row(
      children: [
        const Text('Default Assistant'),
        Spacer(),
        StreamBuilder(
          stream: sl<ChatRepository>().listAiAssistants$,
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const SizedBox();

            final assistants = snapshot.data ?? [];
            final currentId = state?.defaultAssistantId;
            final isValidId = assistants.any((a) => a.id == currentId);
            final dropdownValue = isValidId ? currentId : null;

            return DropdownButton<String>(
              elevation: 0,
              // isDense: true,
              // isExpanded: true,
              value: dropdownValue,
              alignment: Alignment.centerRight,
              underline: const SizedBox(),
              items:
                  assistants
                      .map(
                        (a) => DropdownMenuItem(
                          value: a.id,
                          child: Container(
                            alignment: Alignment.centerRight,
                            width: 240,
                            child: Text(
                              a.name,
                              textAlign: TextAlign.end,
                              style: TextStyle(color: Colors.grey.shade600),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      )
                      .toList(),
              onChanged: (value) {
                if (value != null) {
                  controller.setDefaultAssistant(value);
                  assistantController.setAiAssistant(
                    assistants.firstWhere((e) => e.id == value),
                  );
                }
              },
            );
          },
        ),
      ],
    );
  }

  /// Extracted method for Model Dropdown
  Widget _buildModelDropdown(
    BuildContext context,
    dynamic state,
    AppSettingController controller,
  ) {
    final modelController = context.read<ModelsController>();
    return Row(
      children: [
        const Text('Default Model'),
        const Spacer(),
        StreamBuilder(
          stream: sl<ChatRepository>().listAIModels$,
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const SizedBox();

            final models = snapshot.data ?? [];
            final currentId = state?.defaultModelId;
            final isValidId = models.any((m) => m.id == currentId);
            final dropdownValue = isValidId ? currentId : null;

            return DropdownButton<String>(
              underline: const SizedBox(),
              value: dropdownValue,
              isDense: true,
              items:
                  models
                      .map(
                        (m) => DropdownMenuItem(
                          value: m.id,
                          child: SizedBox(
                            width: 220,
                            child: Text(
                              m.model,
                              style: TextStyle(color: Colors.grey.shade600),
                              textAlign: TextAlign.end,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      )
                      .toList(),
              onChanged: (value) {
                if (value != null) {
                  controller.setDefaultModel(value);
                  modelController.setAiModel(
                    models.firstWhere((e) => e.id == value),
                  );
                }
              },
            );
          },
        ),
      ],
    );
  }
}
