import 'package:chatty/utils/ai_services/ai_provider.dart';
import 'package:chatty/utils/models/ai_model.dart';
import 'package:chatty/utils/repository/chat_repository.dart';
import 'package:chatty/utils/service_locator.dart';
import 'package:chatty/utils/rx_controller.dart';
import 'package:chatty/utils/state_status.dart';
import 'package:chatty/widgets/common/touchable_opacity.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:emoji_selector/emoji_selector.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' as foundation;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

part 'models_controller.dart';
part 'models_state.dart';

class ModelsSetting extends StatelessWidget {
  const ModelsSetting({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.read<ModelsController>();

    return SizedBox(
      width: double.maxFinite,
      child: StreamBuilder<(bool, AIModel?)>(
        initialData: (false, null),
        stream: controller.isEdit$,
        builder: (context, snapshot) {
          final (isEdit, data) = snapshot.data!;

          return AnimatedSwitcher(
            duration: Duration(milliseconds: 300),
            child: isEdit ? AddModelScreen(model: data) : _buildList(context),
          );
        },
      ),
    );
  }

  Container _buildList(BuildContext context) {
    final controller = context.read<ModelsController>();
    return Container(
      constraints: BoxConstraints(maxHeight: 500),
      child: Column(
        children: [
          Flexible(
            child: StreamBuilder(
              stream: sl<ChatRepository>().listAIModels$,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Text("No data, please create a model to start");
                }

                final models = snapshot.data ?? [];

                return ListView.builder(
                  itemCount: models.length,
                  shrinkWrap: true,
                  itemBuilder: (context, index) {
                    final model = models[index];

                    return ListTile(
                      onTap: () => controller.edit(model),
                      title: Text(model.name),
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

class AddModelScreen extends StatefulWidget {
  final AIModel? model;

  const AddModelScreen({super.key, this.model});

  @override
  State<StatefulWidget> createState() => _AddModelScreenState();
}

class _AddModelScreenState extends State<AddModelScreen> {
  final _formKey = GlobalKey<FormState>();
  final uuid = Uuid();
  AIModel _model = AIModel.placeholder();
  final iconController = TextEditingController();

  @override
  void initState() {
    super.initState();

    setState(() {
      if (widget.model != null) {
        _model = widget.model!;
        iconController.text = _model.icon;
      } else {
        _model = AIModel.placeholder().copyWith(id: uuid.v8());
      }
    });
  }

  void _resetFields() {
    _model = AIModel.placeholder();
    _formKey.currentState?.reset();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.read<ModelsController>();
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
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
            const SizedBox(height: 16),
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
                    _model = _model.copyWith(icon: selectedEmoji);
                    print(">> Changed Model : ${_model.toMap()}");
                  }
                });
              },
              decoration: InputDecoration(labelText: 'Icon'),
              onChanged: (val) {},
              keyboardType: TextInputType.text,
            ),
            TextFormField(
              decoration: InputDecoration(labelText: 'Name'),
              initialValue: _model.name, // Set initial value
              onSaved: (value) => _model = _model.copyWith(name: value ?? ''),
              validator: (value) => value!.isEmpty ? 'Enter a name' : null,
              keyboardType: TextInputType.text,
            ),
            DropdownButtonFormField<AIProvider>(
              decoration: InputDecoration(labelText: 'Type'),
              value: _model.type,
              items:
                  AIProvider.values.map((AIProvider type) {
                    return DropdownMenuItem<AIProvider>(
                      value: type,
                      child: Text(type.name),
                    );
                  }).toList(),
              onChanged: (value) {
                setState(() {
                  _model = _model.copyWith(type: value ?? AIProvider.openAI);
                });
              },
              validator: (value) => value == null ? 'Select a type' : null,
            ),
            TextFormField(
              decoration: InputDecoration(labelText: 'URL'),
              initialValue: _model.url, // Set initial value
              onSaved: (value) => _model = _model.copyWith(url: value ?? ''),
              validator: (value) => value!.isEmpty ? 'Enter a URL' : null,
            ),
            TextFormField(
              decoration: InputDecoration(labelText: 'Token'),
              initialValue: _model.token, // Set initial value
              onSaved: (value) => _model = _model.copyWith(token: value ?? ''),
              validator: (value) => value!.isEmpty ? 'Enter a token' : null,
            ),
            TextFormField(
              decoration: InputDecoration(labelText: 'Model'),
              initialValue: _model.model, // Set initial value
              onSaved: (value) => _model = _model.copyWith(model: value ?? ''),
              validator: (value) => value!.isEmpty ? 'Enter a model' : null,
            ),
            TextFormField(
              decoration: InputDecoration(labelText: 'Max Token'),
              keyboardType: TextInputType.number,
              initialValue: _model.maxToken.toString(), // Set initial value
              onSaved:
                  (value) =>
                      _model = _model.copyWith(
                        maxToken: int.tryParse(value ?? '') ?? 0,
                      ),
              validator: (value) => value!.isEmpty ? 'Enter max token' : null,
            ),

            Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Stream Response'),
                  CupertinoSwitch(
                    value: _model.streamResponses,
                    onChanged: (value) {
                      setState(() {
                        _model = _model.copyWith(streamResponses: value);
                      });
                    },
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Expanded(child: Text('Context Size: ${_model.contextSize}')),
                  Slider(
                    value: _model.contextSize.toDouble(),
                    min: 5,
                    max: 100,
                    divisions: 95,
                    label: _model.contextSize.toString(),
                    onChanged: (value) {
                      setState(() {
                        _model = _model.copyWith(contextSize: value.toInt());
                      });
                    },
                  ),
                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                if (widget.model != null)
                  TextButton.icon(
                    onPressed: () {
                      controller.deleteAiModel(widget.model!.id);
                      controller.toggleEditField(
                        showEditFiled: false,
                        data: null,
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Successfully delete the model."),
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

                      if (widget.model != null) {
                        controller.updateAiModel(_model);
                      } else {
                        controller.addAiModel(_model);
                      }

                      controller.toggleEditField(
                        showEditFiled: false,
                        data: null,
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Successfully save the model.")),
                      );
                    }
                  },
                  child: Text("Save Model"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
