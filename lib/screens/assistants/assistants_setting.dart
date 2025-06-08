import 'package:chatty/utils/models/ai_assistant.dart';
import 'package:chatty/utils/repository/chat_repository.dart';
import 'package:chatty/utils/service_locator.dart';
import 'package:chatty/utils/rx_controller.dart';
import 'package:chatty/utils/state_status.dart';
import 'package:chatty/widgets/common/color_picker.dart';
import 'package:chatty/widgets/common/touchable_opacity.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' as foundation;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

part 'assistants_controller.dart';
part 'assistants_state.dart';

class AssistantsSetting extends StatelessWidget {
  const AssistantsSetting({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.read<AssistantsController>();

    return SizedBox(
      width: double.maxFinite,
      child: StreamBuilder<(bool, AiAssistant?)>(
        initialData: (false, null),
        stream: controller.isEdit$,
        builder: (context, snapshot) {
          final (isEdit, data) = snapshot.data!;

          return AnimatedSwitcher(
            duration: Duration(milliseconds: 300),
            child:
                isEdit
                    ? AddAiAssistantScreen(assistant: data)
                    : _buildList(context),
          );
        },
      ),
    );
  }

  Container _buildList(BuildContext context) {
    final controller = context.read<AssistantsController>();
    return Container(
      constraints: BoxConstraints(maxHeight: 500),
      child: Column(
        children: [
          Flexible(
            child: StreamBuilder(
              stream: sl<ChatRepository>().listAiAssistants$,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Text("No data, please create a assistant to start");
                }

                final assistants = snapshot.data ?? [];

                return ListView.builder(
                  itemCount: assistants.length,
                  shrinkWrap: true,
                  itemBuilder: (context, index) {
                    final assistant = assistants[index];

                    return ListTile(
                      onTap: () => controller.edit(assistant),
                      title: Text(assistant.name),
                      trailing: Icon(
                        CupertinoIcons.chevron_right,
                        color: Colors.grey,
                      ),
                    );
                  },
                );
              },
            ),
          ),
          TouchableOpacity(
            child: Row(
              children: [
                Spacer(),
                Icon(CupertinoIcons.add),
                Text("Add New"),
                Spacer(),
              ],
            ),
            onTap: () {
              controller.toggleEditField();
            },
          ),
        ],
      ),
    );
  }
}

class AddAiAssistantScreen extends StatefulWidget {
  final AiAssistant? assistant;

  const AddAiAssistantScreen({super.key, this.assistant});

  @override
  State<StatefulWidget> createState() => _AddAiAssistantScreenState();
}

class _AddAiAssistantScreenState extends State<AddAiAssistantScreen> {
  final _formKey = GlobalKey<FormState>();
  final uuid = Uuid();
  AiAssistant _assistant = AiAssistant.placeholder();
  final iconController = TextEditingController();

  @override
  void initState() {
    super.initState();

    setState(() {
      if (widget.assistant != null) {
        _assistant = widget.assistant!;
        iconController.text = _assistant.icon;
      } else {
        _assistant = AiAssistant.placeholder().copyWith(id: uuid.v8());
      }
    });
  }

  void _resetFields() {
    _assistant = AiAssistant.placeholder();
    _formKey.currentState?.reset();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.read<AssistantsController>();
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Align(
              alignment: Alignment.topLeft,
              child: TouchableOpacity(
                onTap: () {
                  controller.toggleEditField(showEditFiled: false, data: null);
                  _resetFields();
                },
                child: Row(
                  children: [
                    Icon(
                      CupertinoIcons.arrow_left_circle,
                      size: 18,
                      color: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "Back",
                      style: TextStyle(color: Theme.of(context).primaryColor),
                    ),
                  ],
                ),
              ),
            ),
            TextField(
              controller: iconController,
              readOnly: true,
              onTap: () async {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Text('Select an Emoji'),
                      content: SizedBox(
                        width: 300, // Set a fixed width for the dialog
                        height: 256, // Set a fixed height for the dialog
                        child: EmojiPicker(
                          onEmojiSelected: (e, emoji) {
                            Navigator.pop(context, emoji.emoji);
                          },
                          config: Config(
                            height: 256,
                            checkPlatformCompatibility: true,
                            emojiViewConfig: EmojiViewConfig(
                              // Issue: https://github.com/flutter/flutter/issues/28894
                              emojiSizeMax:
                                  18 *
                                  (foundation.defaultTargetPlatform ==
                                          TargetPlatform.iOS
                                      ? 1.20
                                      : 1.0),
                            ),
                            viewOrderConfig: const ViewOrderConfig(
                              top: EmojiPickerItem.categoryBar,
                              middle: EmojiPickerItem.emojiView,
                              // bottom: EmojiPickerItem.searchBar,
                            ),
                            skinToneConfig: const SkinToneConfig(),
                            categoryViewConfig: const CategoryViewConfig(),
                            bottomActionBarConfig:
                                const BottomActionBarConfig(),
                            searchViewConfig: const SearchViewConfig(),
                          ),
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: Text('Cancel'),
                        ),
                      ],
                    );
                  },
                ).then((selectedEmoji) {
                  if (selectedEmoji != null) {
                    iconController.text = selectedEmoji;
                    _assistant = _assistant.copyWith(icon: selectedEmoji);
                  }
                });
              },
              decoration: InputDecoration(labelText: 'Icon'),
              onChanged: (val) {
                _assistant = _assistant.copyWith(icon: val);
              },
              keyboardType: TextInputType.text,
            ),
            const SizedBox(height: 16),
            // Assistant Name (required)
            TextFormField(
              decoration: InputDecoration(labelText: 'Name'),
              initialValue: _assistant.name,
              onSaved:
                  (value) =>
                      _assistant = _assistant.copyWith(name: value ?? ''),
              validator:
                  (value) =>
                      (value == null || value.isEmpty) ? 'Enter a name' : null,
            ),
            // AI Prompt (required)
            TextFormField(
              maxLines: 3,
              decoration: InputDecoration(labelText: 'Prompt'),
              initialValue: _assistant.prompt,
              onSaved:
                  (value) =>
                      _assistant = _assistant.copyWith(prompt: value ?? ''),
              validator:
                  (value) =>
                      (value == null || value.isEmpty)
                          ? 'Enter a prompt'
                          : null,
            ),
            const SizedBox(height: 20),
            Text("Select a color"),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: ColorPicker(
                initialColorHex: _assistant.color,
                onColorSelected: (color) {
                  _assistant = _assistant.copyWith(color: color);
                },
              ),
            ),
            // Save and Delete buttons
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                if (widget.assistant != null)
                  TextButton.icon(
                    onPressed: () {
                      controller.deleteAiAssistant(widget.assistant!.id);
                      controller.toggleEditField(
                        showEditFiled: false,
                        data: null,
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Successfully delete the assistant."),
                        ),
                      );
                    },
                    label: Text("Delete"),
                    icon: Icon(CupertinoIcons.delete),
                  ),
                ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      _formKey.currentState!.save();

                      if (widget.assistant != null) {
                        controller.updateAiAssistant(_assistant);
                      } else {
                        controller.addAiAssistant(_assistant);
                      }

                      controller.toggleEditField(
                        showEditFiled: false,
                        data: null,
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Successfully save the assistant."),
                        ),
                      );
                    }
                  },
                  child: Text("Save assistant"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
