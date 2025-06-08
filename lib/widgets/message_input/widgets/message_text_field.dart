part of '../message_input.dart';

class _MessageTextField extends StatelessWidget {
  const _MessageTextField();

  @override
  Widget build(BuildContext context) {
    final controller = context.read<MessageInputController>();
    return StreamBuilder<(bool, bool)>(
      initialData: (false, false),
      stream: controller.textFieldState$,
      builder: (context, snapshot) {
        final (showSendButton, isFocused) = snapshot.data!;

        return AnimatedCrossFade(
          duration: Duration(milliseconds: 500),
          firstChild: const SizedBox(),
          secondChild: KeyboardListener(
            focusNode: FocusNode(),
            onKeyEvent: (event) {
              if (event is KeyDownEvent &&
                  event.logicalKey == LogicalKeyboardKey.enter) {
                // Action to perform when Enter is pressed
                controller.sendMessage(isDesktop: true);

                Future.delayed(Duration(milliseconds: 100), () {
                  controller.textController.clear();
                });
              }
            },
            child: TextField(
              controller: controller.textController,
              focusNode: controller.focusNode,
              minLines: 1,
              maxLines: 6,
              onChanged: (text) {
                controller.toggleSendButton(text.isNotEmpty == true);
              },
              // placeholder: "What's on your mind?",
              // decoration: BoxDecoration(color: Colors.transparent),
              decoration: InputDecoration(
                hintText: "What's on your mind?",
                border: InputBorder.none,
                suffixIcon:
                    !showSendButton
                        ? null
                        : TouchableOpacity(
                          onTap: () => controller.sendMessage(),
                          child: Icon(
                            Icons.send_rounded,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
              ),
            ),
          ),
          crossFadeState:
              !isFocused ? CrossFadeState.showFirst : CrossFadeState.showSecond,
        );
      },
    );
  }
}
