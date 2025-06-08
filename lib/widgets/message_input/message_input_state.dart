class MessageInputState {
  final bool showSendButton;
  final bool isFocused;
  final List<String> images;
  final String quotedText;
  final String quotedMessageId;

  const MessageInputState({
    this.showSendButton = false,
    this.isFocused = false,
    this.images = const [],
    this.quotedMessageId = '',
    this.quotedText = '',
  });

  MessageInputState copyWith({
    bool? showSendButton,
    bool? isFocused,
    List<String>? images,
    String? quotedText,
    String? quotedMessageId,
  }) {
    return MessageInputState(
      showSendButton: showSendButton ?? this.showSendButton,
      isFocused: isFocused ?? this.isFocused,
      images: images ?? this.images,
      quotedText: quotedText ?? this.quotedText,
      quotedMessageId: quotedMessageId ?? this.quotedMessageId,
    );
  }
}
