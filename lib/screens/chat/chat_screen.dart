import 'package:chatty/screens/ai_models/models_screen.dart';
import 'package:chatty/screens/ai_models/widgets/model_picker.dart';
import 'package:chatty/screens/assistants/assistants_setting.dart';
import 'package:chatty/screens/assistants/widgets/assistant_picker.dart';
import 'package:chatty/utils/models/base_message_model.dart';
import 'package:chatty/screens/chat/chat_controller.dart';
import 'package:chatty/screens/chat/chat_state.dart';
import 'package:chatty/screens/chat/sidebar.dart';
import 'package:chatty/widgets/common/chat_scaffold.dart';
import 'package:chatty/utils/context_extension.dart';
import 'package:chatty/utils/state_status.dart';
import 'package:chatty/widgets/common/touchable_opacity.dart';
import 'package:chatty/widgets/message_input/message_input.dart';
import 'package:chatty/widgets/common/message_item.dart';
import 'package:cupertino_sidemenu/cupertino_sidemenu.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rxdart/rxdart.dart';

class ChatScreen extends StatelessWidget {
  final BaseMessageModel? baseMessage;

  const ChatScreen({super.key, this.baseMessage});

  @override
  Widget build(BuildContext context) {
    final sideMenuController = CupertinoSidemenuController();
    return Provider(
      create: (_) => ChatController()..setupBaseMessage(baseMessage),
      child: ChatScaffold(
        body: Builder(
          builder: (context) {
            if (context.isMobile) {
              return CupertinoSidemenu(
                menuWidthOfScreen: 0.70,
                controller: sideMenuController,
                leftMenu: SidebarMenu(sideMenuController: sideMenuController),
                centerPage: _buildContent(
                  context,
                  sideMenuController: sideMenuController,
                  leading: TouchableOpacity(
                    onTap: () {
                      sideMenuController.openLeftMenu();
                    },
                    child: Icon(CupertinoIcons.sidebar_left, size: 18),
                  ),
                ),
              );
            } else {
              final controller = context.read<ChatController>();
              return _buildContent(
                context,
                sideMenuController: sideMenuController,
                leading:
                    context.isMobile
                        ? null
                        : TouchableOpacity(
                          onTap: () {
                            controller.toggleSidebar();
                          },
                          child: Icon(CupertinoIcons.sidebar_left, size: 18),
                        ),
              );
            }
          },
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context, {
    required CupertinoSidemenuController sideMenuController,
    Widget? leading,
  }) {
    return Builder(
      builder: (context) {
        final controller = context.read<ChatController>();
        final modelController = context.read<ModelsController>();
        final assistantController = context.read<AssistantsController>();

        return GestureDetector(
          onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
          child: Row(
            children: [
              if (!context.isMobile)
                SidebarMenu(sideMenuController: sideMenuController),
              Expanded(
                child: ChatScaffold(
                  appBar: AppBar(
                    leading: leading,
                    actions: [
                      AIAssistantPicker(),
                      const SizedBox(width: 8),
                      ModelPicker(),
                      const SizedBox(width: 8),
                    ],
                  ),
                  body: Column(
                    children: [
                      Expanded(
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                          ).copyWith(top: 8),
                          child: SizedBox.expand(
                            child: StreamBuilder<ChatState>(
                              initialData: ChatState(),
                              stream: controller.stream,
                              builder: (context, snapshot) {
                                final ChatState state = snapshot.data!;

                                if (state.status == StateStatus.loading) {
                                  return Center(
                                    child: CupertinoActivityIndicator(),
                                  );
                                }

                                if (state.status == StateStatus.error) {
                                  return Column(
                                    children: [
                                      Text(state.textStatus),
                                      TextButton(
                                        onPressed: () {},
                                        child: Text("Retry"),
                                      ),
                                    ],
                                  );
                                }

                                return StreamBuilder(
                                  initialData: (null, null),
                                  stream: Rx.combineLatest2(
                                    modelController.selected$,
                                    assistantController.selected$,
                                    (model, assistant) {
                                      return (model, assistant);
                                    },
                                  ),
                                  builder: (context, snapshot) {
                                    final (model, assistant) = snapshot.data!;

                                    return Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        if (state.messages.isEmpty)
                                          Text("")
                                        // Text("What can I help with?")
                                        else
                                          Expanded(
                                            child: SingleChildScrollView(
                                              child: Column(
                                                children:
                                                    state.messages
                                                        .map(
                                                          (item) => MessageItem(
                                                            message: item,
                                                            onRetry: () {
                                                              controller
                                                                  .resendMessage(
                                                                    item,
                                                                    model:
                                                                        model,
                                                                    assistant:
                                                                        assistant,
                                                                  );
                                                            },
                                                            onQuote: (value) {
                                                              controller
                                                                  .quoteMessage(
                                                                    value,
                                                                    item,
                                                                  );
                                                            },
                                                          ),
                                                        )
                                                        .toList(),
                                              ),
                                            ),
                                          ),
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          // Force the input to be rebuilt based on model & assistant
                                          child: MessageInput(
                                            key: ValueKey(
                                              '${model?.id}-${assistant?.id}',
                                            ), // or whatever uniquely identifies them
                                            enableSafeArea:
                                                state.messages.isNotEmpty,
                                            onSubmit: (data) {
                                              controller.sendMessage(
                                                data,
                                                model: model,
                                                assistant: assistant,
                                              );
                                            },
                                            quotedMessage:
                                                controller.$quotedMessage,
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
