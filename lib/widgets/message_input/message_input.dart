import 'package:chatty/utils/models/message_model.dart';
import 'package:chatty/utils/context_extension.dart';
import 'package:chatty/widgets/common/cached_base64_image.dart';
import 'package:chatty/widgets/common/touchable_opacity.dart';
import 'package:chatty/widgets/message_input/message_input_controller.dart';
import 'package:custom_pop_up_menu/custom_pop_up_menu.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
part 'widgets/message_input_actions.dart';
part 'widgets/message_text_field.dart';
part 'widgets/uploaded_image_section.dart';
part 'widgets/quoted_message_section.dart';

typedef QuotedMessageStream =
    Stream<(String quotedText, String quotedMessageId)>;

class MessageInput extends StatelessWidget {
  final Function(MessageModel data) onSubmit;
  final QuotedMessageStream quotedMessage;
  final bool enableSafeArea;

  const MessageInput({
    super.key,
    required this.onSubmit,
    required this.quotedMessage,
    this.enableSafeArea = true,
  });

  @override
  Widget build(BuildContext context) {
    return Provider(
      create:
          (_) =>
              MessageInputController()
                ..setSubmitCallback(onSubmit)
                ..listenOnQuotedMessage(quotedMessage),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
              color:
                  context.isDark ? Colors.grey.shade800 : Colors.grey.shade200,
            ),
            child: SafeArea(
              top: false,
              left: enableSafeArea,
              right: enableSafeArea,
              bottom: enableSafeArea,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _QuotedMessageSection(),
                  _MessageTextField(),
                  _UploadedImageSection(),
                  _InputActions(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
