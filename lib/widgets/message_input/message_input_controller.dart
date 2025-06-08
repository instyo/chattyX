import 'dart:convert';
import 'dart:io';
import 'package:chatty/utils/repository/chat_repository.dart';
import 'package:chatty/utils/models/message_model.dart';
import 'package:chatty/utils/service_locator.dart';
import 'package:chatty/utils/rx_controller.dart';
import 'package:chatty/widgets/message_input/message_input.dart';
import 'package:chatty/widgets/message_input/message_input_state.dart';
import 'package:custom_pop_up_menu/custom_pop_up_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_compression_flutter/image_compression_flutter.dart'
    as img;

class MessageInputController extends RxController<MessageInputState> {
  final TextEditingController textController = TextEditingController();
  FocusNode focusNode = FocusNode();
  final CustomPopupMenuController popupMenuController =
      CustomPopupMenuController();
  final ImagePicker imagePicker = ImagePicker();
  final ScrollController scrollController = ScrollController();
  final ChatRepository chatRepository = sl<ChatRepository>();
  late Function(MessageModel data) onSubmit;

  @override
  MessageInputState initState() {
    focusNode = FocusNode(
      onKeyEvent: (FocusNode node, KeyEvent evt) {
        if (HardwareKeyboard.instance.isShiftPressed &&
            evt.logicalKey.keyLabel == 'Enter') {
          if (evt is KeyDownEvent) {
            // Insert newline at current cursor position
            final currentText = textController.text;
            final selection = textController.selection;
            final newText = currentText.replaceRange(
              selection.start,
              selection.end,
              '\n',
            );
            textController.text = newText;
            // Move cursor after the newline
            textController.selection = TextSelection.collapsed(
              offset: selection.start + 1,
            );
            // Prevent default behavior (like submitting)
          }
          return KeyEventResult.handled;
        } else {
          return KeyEventResult.ignored;
        }
      },
    );
    return MessageInputState();
  }

  void setSubmitCallback(Function(MessageModel data) callbackSubmit) {
    onSubmit = callbackSubmit;
  }

  void listenOnQuotedMessage(QuotedMessageStream stream) {
    stream.distinct().listen((res) {
      setState(
        (state) => state.copyWith(quotedMessageId: res.$2, quotedText: res.$1),
      );
    });
  }

  void clearQuotedMessage() {
    setState((state) => state.copyWith(quotedMessageId: '', quotedText: ''));
  }

  Stream<(String, String)> get quotedMessage$ =>
      stream
          .map((state) => (state.quotedText, state.quotedMessageId))
          .distinct();

  Stream<List<String>> get images$ =>
      stream.map((state) => state.images).distinct();

  Stream<(bool, bool)> get textFieldState$ =>
      stream.map((state) => (state.showSendButton, state.isFocused)).distinct();

  // If send message from desktop, keep textfield active
  void sendMessage({bool isDesktop = false}) {
    final String text = textController.text.trim();

    onSubmit(
      MessageModel.create(
        id: '',
        baseMessageId: '',
        message: text,
        images: state.images,
        own: true,
        status: MessageStatus.loaded,
      ),
    );

    textController.clear();
    clearAllImages();
    clearQuotedMessage();

    // scrollToBottom();

    if (!isDesktop) {
      focusNode.unfocus();
      setState(
        (state) => state.copyWith(showSendButton: false, isFocused: false),
      );
    }
  }

  void toggleFocus() {
    setState((state) => state.copyWith(isFocused: !state.isFocused));
  }

  void toggleSendButton(bool value) {
    setState((state) => state.copyWith(showSendButton: value));
  }

  Future<void> pickImages(ImageSource source) async {
    List<XFile> files = [];

    if (source == ImageSource.camera) {
      final result = await imagePicker.pickImage(source: source);

      if (result == null) return;

      files.add(result);
    } else {
      files = await imagePicker.pickMultiImage();
    }

    if (files.isNotEmpty) {
      List<String> base64Images = [];
      final config = img.Configuration(
        outputType: img.ImageOutputType.webpThenJpg,
        useJpgPngNativeCompressor: !Platform.isMacOS,
        quality: 60,
      );

      await Future.forEach(files, (item) async {
        final bytes = await item.readAsBytes();
        final image = img.ImageFileConfiguration(
          input: img.ImageFile(filePath: item.path, rawBytes: bytes),
          config: config,
        );

        final result = await img.compressor.compress(image);

        print(">> Before compress: ${bytes.length} bytes");
        print(">> After compress: ${result.rawBytes.length} bytes");
        base64Images.add(base64Encode(result.rawBytes));
      });

      setState(
        (state) => state.copyWith(
          images: [...base64Images, ...state.images],
          isFocused: true,
        ),
      );

      Future.delayed(Duration(milliseconds: 100), () {
        focusNode.requestFocus();
      });
    }
  }

  void clearImage({required int at}) {
    final items = List<String>.from(state.images);
    items.removeAt(at);

    setState((state) => state.copyWith(images: items));
  }

  void clearAllImages() {
    setState((state) => state.copyWith(images: []));
  }

  void scrollToBottom() {
    scrollController.animateTo(
      scrollController.position.maxScrollExtent,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    focusNode.dispose();
    textController.dispose();
    super.dispose();
  }
}
