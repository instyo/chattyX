import 'dart:async';
import 'package:chatty/utils/models/ai_assistant.dart';
import 'package:chatty/utils/models/ai_model.dart';
import 'package:chatty/utils/models/base_message_model.dart';
import 'package:chatty/utils/repository/chat_repository.dart';
import 'package:chatty/screens/chat/chat_state.dart';
import 'package:chatty/utils/models/message_model.dart';
import 'package:chatty/utils/service_locator.dart';
import 'package:chatty/utils/rx_controller.dart';
import 'package:chatty/utils/state_status.dart';
import 'package:flutter/cupertino.dart';
import 'package:uuid/uuid.dart';

class ChatController extends RxController<ChatState> {
  final chatRepository = sl<ChatRepository>();
  final uuid = Uuid();

  BaseMessageModel? baseMessage;

  @override
  ChatState initState() {
    return ChatState();
  }

  Stream<bool> get $isExpanded =>
      stream.map((state) => state.isExpanded).distinct();

  Stream<List<MessageModel>> get $messages =>
      stream.map((state) => state.messages).distinct();

  Stream<(String, String)> get $quotedMessage =>
      stream
          .map((state) => (state.quotedText, state.quotedMessageId))
          .distinct();

  // If there's a history, this will not be empty
  // if not, we need to create new base message
  void setupBaseMessage(BaseMessageModel? data) {
    if (data != null) {
      baseMessage = data;
      getMessages();
      return;
    }

    baseMessage = BaseMessageModel.create(id: uuid.v8());
  }

  void createNewChatSession({String? title}) {
    // save to db
    chatRepository.insertNewChat(
      baseMessage!.copyWith(
        title: title ?? 'New chat @${DateTime.now().toString()}',
      ),
    );
  }

  Future<void> getMessages() async {
    try {
      if (baseMessage == null) {
        throw FormatException('base message not found');
      }

      debugPrint("Get messages");

      setState((state) => state.copyWith(status: StateStatus.loading));

      final result = await chatRepository.getMessagesForChat(baseMessage!.id);

      debugPrint("Messages : ${result.length}");

      setState(
        (state) =>
            state.copyWith(status: StateStatus.success, messages: result),
      );
    } catch (e, s) {
      debugPrint(">> ERR : $e, $s");
      setState(
        (state) => state.copyWith(
          status: StateStatus.error,
          textStatus: 'Failed to get messages : $e',
        ),
      );
    }
  }

  Future<void> resendMessage(
    MessageModel data, {
    AIModel? model,
    AiAssistant? assistant,
  }) async {
    if (model == null || assistant == null) return;
    final lastMessage = state.messages.last;

    if (state.messages.isEmpty) {
      debugPrint("No messages to resend.");
      return;
    }

    // Update the latest message with an empty string to show loading on message item (Thinking..)
    updateMessage(
      '',
      id: lastMessage.id,
      saveToDB: false,
      status: MessageStatus.loading,
    );

    try {
      final botResponse = await chatRepository.sendMessage(
        state.messages,
        model: model,
        assistant: assistant,
      );

      updateMessage(
        botResponse,
        id: lastMessage.id,
        saveToDB: true,
        status: MessageStatus.loaded,
      );
    } catch (e, s) {
      debugPrint(">> ERR : $e, $s");
      updateMessage(
        e is String ? e : "Failed to resend message: $e",
        id: lastMessage.id,
        saveToDB: false,
        status: MessageStatus.error,
      );
    }
  }

  Future<void> sendMessage(
    MessageModel data, {
    AIModel? model,
    AiAssistant? assistant,
  }) async {
    if (model == null || assistant == null) {
      return;
    }

    // If messageList is empty, assume it was initial chat so we will save base message to db
    if (state.messages.isEmpty) {
      createNewChatSession(title: data.message);
    }

    // Add user message
    addMessage(
      data.message,
      images: data.images,
      own: true,
      saveToDB: true,
      quotedMessageId: data.quotedMessageId,
      quotedText: data.quotedText,
    );

    final String messageId = uuid.v8();

    // Add empty message from bot (We need to show loading on message item (Thinking..))
    addMessage('', own: false, id: messageId);

    // Post request start
    try {
      if (model.streamResponses != true) {
        final botResponse = await chatRepository.sendMessage(
          state.messages,
          model: model,
          assistant: assistant,
        );

        updateMessage(
          botResponse,
          id: messageId,
          saveToDB: true,
          assistant: assistant,
          model: model,
        );

        generateSummaries(model);
      } else {
        String message = '';

        chatRepository
            .streamChatCompletion(
              state.messages,
              model: model,
              assistant: assistant,
            )
            .listen(
              (event) {
                message += event;
                updateMessage(
                  message,
                  id: messageId,
                  saveToDB: false,
                  status: MessageStatus.loaded,
                  assistant: assistant,
                  model: model,
                );
              },
              onDone: () {
                updateMessage(
                  message,
                  id: messageId,
                  saveToDB: true,
                  assistant: assistant,
                  model: model,
                );
                generateSummaries(model);
              },
            );
      }
    } catch (e) {
      updateMessage(
        e is String ? e : "Failed to send message",
        id: messageId,
        status: MessageStatus.error,
      );
    }
  }

  void generateSummaries(AIModel model) {
    // Generate message summary when user starts new chat session
    // we can check that with (if messages length is == 2 -> 1 message from user, 1 message is answer from ai)
    if (state.messages.length == 2 &&
        state.messages[1].status == MessageStatus.loaded) {
      chatRepository.summarizeChat(state.messages, model: model).then((
        summarized,
      ) async {
        // Update base chat title
        baseMessage = baseMessage?.copyWith(title: summarized);
        await chatRepository.insertNewChat(baseMessage!);
      });
    }
  }

  void addMessage(
    String message, {
    required bool own,
    bool saveToDB = false,
    List<String> images = const [],
    String? id,
    String quotedText = '',
    String quotedMessageId = '',
    AIModel? model,
    AiAssistant? assistant,
  }) {
    try {
      final msg = MessageModel.create(
        id: id ?? uuid.v8(),
        baseMessageId: baseMessage!.id,
        message: message,
        images: images,
        own: own,
        quotedMessageId: quotedMessageId,
        quotedText: quotedText,
        // if message is from user itself, no need to wait for the response
        status: own ? MessageStatus.loaded : MessageStatus.loading,
        assistant: assistant,
        model: model,
      );

      setState((state) => state.copyWith(messages: [...state.messages, msg]));

      // Save chat to database
      if (saveToDB) {
        chatRepository.insertMessage(baseMessage!.id, msg);
      }
    } catch (e, s) {
      debugPrint('>> EX : $e, $s');
    }
  }

  void updateMessage(
    String message, {
    required String id,
    bool saveToDB = false,
    MessageStatus status = MessageStatus.loaded,
    AiAssistant? assistant,
    AIModel? model,
  }) {
    try {
      // Find the index of the message to update
      final index = state.messages.indexWhere((msg) => msg.id == id);

      // If the message is found, update it
      if (index != -1) {
        final updatedMsg = MessageModel.create(
          id: id,
          baseMessageId: baseMessage!.id,
          message: message,
          own: state.messages[index].own,
          status: status,
          images: state.messages[index].images,
          assistant: assistant,
          model: model,
        );

        // Create a new list with the updated message
        final updatedMessages = List<MessageModel>.from(state.messages);
        updatedMessages[index] = updatedMsg;

        // Emit the updated messages list
        setState((state) => state.copyWith(messages: updatedMessages));

        // Save chat to database
        if (saveToDB) {
          chatRepository.insertMessage(baseMessage!.id, updatedMsg);
        }
      }
    } catch (e, s) {
      debugPrint(">> JO $e, $s");
    }
  }

  void starNewSession(BaseMessageModel? data) {
    setState((state) => ChatState());
    setupBaseMessage(data);
  }

  void quoteMessage(String text, MessageModel message) {
    setState(
      (state) => state.copyWith(quotedText: text, quotedMessageId: message.id),
    );
  }

  void toggleSidebar() {
    setState((state) => state.copyWith(isExpanded: !state.isExpanded));
  }
}
