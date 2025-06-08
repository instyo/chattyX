import 'dart:async';
import 'dart:convert';
// import 'dart:async';
import 'package:chatty/utils/ai_services/ai_result.dart';
import 'package:chatty/utils/models/ai_assistant.dart';
import 'package:chatty/utils/models/ai_model.dart';
import 'package:chatty/utils/models/base_message_model.dart';
import 'package:chatty/utils/databases/chat_database.dart';
import 'package:chatty/utils/models/message_model.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
// ignore: depend_on_referenced_packages
import 'package:http/http.dart' as http;

class ChatRepository {
  final BaseChatDatabase db;
  final Dio dio;

  const ChatRepository({required this.db, required this.dio});

  Future<List<BaseMessageModel>> getAllChats() async {
    return await db.getAllChats();
  }

  Future<void> insertNewChat(BaseMessageModel baseMessage) async {
    await db.insertNewChat(baseMessage);
  }

  Future<List<AIModel>> getAIModels() async {
    return await db.getAIModels();
  }

  Future<List<AiAssistant>> getAssistants() async {
    return await db.getAssistants();
  }

  Future<List<MessageModel>> getMessagesForChat(String baseMessageId) async {
    return await db.getMessagesForChat(baseMessageId);
  }

  Future<void> insertAIModel(AIModel model) async {
    return await db.insertAIModel(model);
  }

  Future<void> insertAssistant(AiAssistant assistant) async {
    return await db.insertAssistant(assistant);
  }

  Future<void> insertMessage(String baseMessageId, MessageModel message) async {
    return await db.insertMessage(baseMessageId, message);
  }

  Future<void> deleteAIModel(String id) async {
    await db.deleteAIModel(id);
  }

  Future<void> deleteAssistant(String id) async {
    await db.deleteAssistant(id);
  }

  Future<void> updateAIModel(AIModel model) async {
    await db.updateAIModel(model);
  }

  Future<void> updateAssistant(AiAssistant assistant) async {
    await db.updateAssistant(assistant);
  }

  Future<void> deleteChat(List<String> ids) async {
    await Future.forEach(ids, (id) async {
      await db.deleteChat(id);
    });
  }

  Stream<List<BaseMessageModel>> getAllChats$(String keyword) =>
      db.getAllChats$(keyword);

  Stream<List<AIModel>> get listAIModels$ => db.listAIModels$;

  Stream<List<AiAssistant>> get listAiAssistants$ => db.listAiAssistants$;

  Future<String> sendMessage(
    List<MessageModel> messages, {
    required AIModel model,
    required AiAssistant assistant,
  }) async {
    final result = await fetchAIResponse(model.type, model.uri, {
      'messages': [
        //
        {'role': 'system', 'content': assistant.prompt},
        // To keep context between AI and user, we need to take last `model.contextSize` messages
        ...messages.takeLastMessages(count: model.contextSize),
      ],
      'model': model.model,
      'max_tokens': model.maxToken,
      'stream': model.streamResponses,
    }, model.token);

    switch (result) {
      case AISuccess(:final data):
        return data.text;
      case AIErrorResult(:final error):
        throw error.message;
    }
  }

  Future<String> summarizeChat(
    List<MessageModel> messages, {
    required AIModel model,
  }) async {
    final result = await fetchAIResponse(model.type, model.uri, {
      'messages': [
        {
          'role': 'system',
          'content':
              "Return a short chat name as summary for this chat based on the previous message content and system message if it's not default. Start chat name with one appropriate emoji. Don't answer to my message, just generate a name.",
        },
        ...messages.map((e) => {'role': 'user', 'content': e.message}),
      ],
      'model': model.model,
      'max_tokens': model.maxToken,
      'stream': false,
    }, model.token);

    switch (result) {
      case AISuccess(:final data):
        return data.text;
      case AIErrorResult(:final error):
        return error.message;
    }
  }

  Stream<String> streamChatCompletion(
    List<MessageModel> messages, {
    required AIModel model,
    required AiAssistant assistant,
  }) async* {
    final Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${model.token}',
      'Accept': 'text/event-stream',
      'Cache-Control': 'no-cache',
      'Connection': 'keep-alive',
    };

    final Map<String, dynamic> body = {
      'messages': [
        {'role': 'system', 'content': assistant.prompt},
        ...messages.takeLastMessages(count: model.contextSize),
      ],
      'model': model.model,
      'max_tokens': model.maxToken,
      'stream': true,
    };

    try {
      final request =
          http.Request('POST', Uri.parse(model.url))
            ..headers.addAll(headers)
            ..body = jsonEncode(body);

      final http.StreamedResponse response = await request.send();

      if (response.statusCode == 200) {
        // Listen to the stream and parse SSE events
        await for (var chunk in response.stream.transform(utf8.decoder)) {
          // OpenAI sends data in 'data: {json}\n\n' format.
          // There can be multiple events in a single chunk, or partial events.
          // We need to split by '\n\n' and process each event.
          final List<String> events = chunk.split('\n\n');

          for (String event in events) {
            if (event.isEmpty) continue; // Skip empty strings from split

            // Remove the "data: " prefix
            if (event.startsWith('data: ')) {
              final String jsonString = event.substring(6).trim();

              if (jsonString == '[DONE]') {
                break; // End of stream
              }

              try {
                final Map<String, dynamic> parsedData = jsonDecode(jsonString);
                if (parsedData['choices'] != null &&
                    parsedData['choices'].isNotEmpty) {
                  final String? content =
                      parsedData['choices'][0]['delta']['content'];
                  if (content != null && content.isNotEmpty) {
                    yield content; // Yield each new token
                  }
                }
              } catch (e) {
                debugPrint("Error parsing SSE chunk: $e\nChunk: $jsonString");
                // Depending on your error handling strategy, you might yield an error
                // or rethrow. For streaming text, logging might be enough.
              }
            } else {
              // Handle cases where a chunk might not start with "data: "
              // (e.g., partial event, keep-alive, or other server messages)
              debugPrint("Received non-data event chunk: $event");
            }
          }
        }
      } else {
        final errorBody = await response.stream.bytesToString();
        throw Exception(
          'OpenAI API Error: ${response.statusCode} - $errorBody',
        );
      }
    } catch (e) {
      // Catch network errors, JSON parsing errors, etc.
      throw Exception('Failed to connect to OpenAI API or parse response: $e');
    }
  }
}
