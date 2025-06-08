import 'package:chatty/utils/models/ai_assistant.dart';
import 'package:chatty/utils/models/ai_model.dart';
import 'package:flutter/cupertino.dart';

enum MessageStatus { loaded, loading, error }

class MessageModel {
  final String id;
  final String baseMessageId;
  final String message;
  final List<String> images;
  final bool own;
  final MessageStatus status;
  final DateTime createdAt;
  // Quote
  final String quotedText;
  final String quotedMessageId;

  const MessageModel({
    required this.id,
    required this.baseMessageId,
    required this.message,
    this.images = const [],
    required this.own,
    required this.status,
    required this.createdAt,
    this.quotedText = '',
    this.quotedMessageId = '',
  });

  factory MessageModel.create({
    required String id,
    required String baseMessageId,
    required String message,
    required List<String> images,
    required bool own,
    required MessageStatus status,
    String quotedText = '',
    String quotedMessageId = '',
    AIModel? model,
    AiAssistant? assistant,
  }) => MessageModel(
    id: id,
    baseMessageId: baseMessageId,
    message: message,
    images: images,
    own: own,
    status: status,
    createdAt: DateTime.now(),
    quotedMessageId: quotedMessageId,
    quotedText: quotedText,
  );

  bool get waitingForResponse => status == MessageStatus.loading;

  bool get isError => status == MessageStatus.error;

  bool get isImage => images.isNotEmpty;

  bool get isLoading => status == MessageStatus.loading;

  Map<String, dynamic> toJson() {
    return {'role': own ? 'user' : 'assistant', 'content': _buildContent()};
  }

  dynamic _buildContent() {
    if (!isImage) {
      // If user quote a reply
      if (quotedText.isNotEmpty) {
        return """
User quoted this text from your answer : $quotedText

User message : $message
""";
      }

      return message;
    }

    return [
      {"type": "text", "text": message},
      ...images.map(
        (image) => {
          "type": "image_url",
          "image_url": {"url": "data:image/png;base64,$image"},
        },
      ),
    ];
  }

  // Factory constructor to create a MessageModel from a Map
  factory MessageModel.fromMap(Map<String, dynamic> map) {
    return MessageModel(
      id: map['id'] ?? '',
      baseMessageId: map['baseMessageId'] ?? '',
      message: map['message'] ?? '',
      images: List<String>.from(map['images'] ?? []),
      own: map['own'] ?? false,
      quotedMessageId: map['quotedMessageId'] ?? '',
      quotedText: map['quotedText'] ?? '',
      // Assuming status is stored as an integer
      status: MessageStatus.values[map['status'] ?? 0],
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'baseMessageId': baseMessageId,
      'message': message,
      'images': images,
      'own': own,
      'status': status.index,
      'quotedText': quotedText,
      'quotedMessageId': quotedMessageId,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

extension ListMessageModelX on List<MessageModel> {
  List<Map<String, dynamic>> takeLastMessages({required int count}) {
    try {
      if (isEmpty) {
        return [];
      }

      List<MessageModel> messages = [];
      final rawMessages =
          where((e) => !e.isError && e.message.isNotEmpty).toList();
      final lastMessage = rawMessages.last;

      // Check if last message is quoted text
      if (lastMessage.quotedMessageId.isNotEmpty) {
        // Handle quoted text
        // to keep context between AI and user, we need to include quoted message
        // the simplest way is to move message near last message
        // for example, the quoted message is in index 2 and the latest message is on index 10
        // we need to move message[2] to message[9] (near last message)

        final quotedMessageIndex = rawMessages.indexWhere(
          (e) => e.id == lastMessage.quotedMessageId,
        );

        if (quotedMessageIndex >= 0) {
          messages = rawMessages.move(
            quotedMessageIndex,
            rawMessages.length - 2,
          );
        } else {
          messages = rawMessages;
        }
      } else {
        messages = rawMessages;
      }

      final takeFor = count > messages.length ? messages.length : count;

      if (messages.last.isImage) {
        return messages.map((item) => item.toJson()).takeLast(takeFor).toList();
      }

      // exclude image to save tokens usage because image saved in base64 string
      final res = messages.where((e) => !e.isImage && e.message.isNotEmpty);
      final takeFor2 = count > res.length ? res.length : count;

      return res.map((item) => item.toJson()).takeLast(takeFor2).toList();
    } catch (e, s) {
      debugPrint(">> ERR : $e, $s");
      return [];
    }
  }
}

extension ListUtils<T> on List<T> {
  T? firstOrNull() {
    return isEmpty ? null : this[0];
  }

  T? lastOrNull() {
    return isEmpty ? null : this[length - 1];
  }

  List<T> takeLast(int n) {
    return skip(length - n).toList();
  }
}

extension IterableExtension<T> on Iterable<T> {
  Iterable<T> takeLast(int n) {
    return skip(length - n).toList();
  }

  Iterable<T> move(int fromIndex, int toIndex) {
    var list = toList();

    if (fromIndex < 0 ||
        fromIndex >= list.length ||
        toIndex < 0 ||
        toIndex >= list.length) {
      throw RangeError('Index out of range');
    }

    T element = list.removeAt(fromIndex);
    list.insert(toIndex, element);

    return list; // Return a new iterable
  }
}

extension ListExtension<T> on List<T> {
  List<T> move(int fromIndex, int toIndex) {
    if (fromIndex < 0 ||
        fromIndex >= length ||
        toIndex < 0 ||
        toIndex >= length) {
      throw RangeError('Index out of range');
    }

    // Create a copy of the current list
    List<T> newList = List.from(this);

    // Remove the element at the fromIndex and insert it at toIndex
    T element = newList.removeAt(fromIndex);
    newList.insert(toIndex, element);

    return newList; // Return the new list
  }
}
