import 'package:chatty/utils/models/message_model.dart';
import 'package:chatty/utils/state_status.dart';

class ChatState {
  final StateStatus status;
  final String textStatus; // when an error occured
  final List<MessageModel> messages;
  final String quotedText;
  final String quotedMessageId;

  // Sidebar
  final bool isExpanded;

  // Find text in chat screen
  final bool isSearching;
  final String searchQuery;
  final List<int> matchIndices; // Added to track indices of matched text
  final int currentMatchIndex; // Added to track the current match index

  const ChatState({
    this.status = StateStatus.idle,
    this.textStatus = '',
    this.messages = const [],
    this.quotedMessageId = '',
    this.quotedText = '',
    this.isExpanded = true,
    this.isSearching = false,
    this.searchQuery = '',
    this.matchIndices = const [],
    this.currentMatchIndex = 0,
  });

  ChatState copyWith({
    StateStatus? status,
    String? textStatus,
    List<MessageModel>? messages,
    String? quotedMessageId,
    String? quotedText,
    bool? isExpanded,
    bool? isSearching,
    String? searchQuery,
    List<int>? matchIndices,
    int? currentMatchIndex,
  }) {
    return ChatState(
      status: status ?? this.status,
      textStatus: textStatus ?? this.textStatus,
      messages: messages ?? this.messages,
      quotedMessageId: quotedMessageId ?? this.quotedMessageId,
      quotedText: quotedText ?? this.quotedText,
      isExpanded: isExpanded ?? this.isExpanded,
      isSearching: isSearching ?? this.isSearching,
      searchQuery: searchQuery ?? this.searchQuery,
      matchIndices: matchIndices ?? this.matchIndices,
      currentMatchIndex: currentMatchIndex ?? this.currentMatchIndex,
    );
  }
}
