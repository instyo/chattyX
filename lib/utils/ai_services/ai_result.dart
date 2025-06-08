import 'ai_provider.dart';
import 'ai_response.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class AIError {
  final String message;
  final int? statusCode;

  AIError({required this.message, this.statusCode});

  @override
  String toString() => 'AIError($statusCode): $message';
}

// Sealed Result Type
sealed class AIResult {
  const AIResult();
}

class AISuccess extends AIResult {
  final AIResponse data;
  const AISuccess(this.data);
}

class AIErrorResult extends AIResult {
  final AIError error;
  const AIErrorResult(this.error);
}

// Response Parser
class AIResponseParser {
  static AIResponse parse(AIProvider provider, Map<String, dynamic> json) {
    switch (provider) {
      case AIProvider.deepInfra:
      case AIProvider.openAI:
        return OpenAIResponse.fromJson(json);
      case AIProvider.google:
        return GoogleAIResponse.fromJson(json);
    }
  }
}

// Error Parser
class AIErrorParser {
  static AIError parse(
    AIProvider provider,
    Map<String, dynamic> json,
    int statusCode,
  ) {
    switch (provider) {
      case AIProvider.openAI:
        return AIError(
          message: json['error']?['message'] ?? 'Unknown OpenAI error',
          statusCode: statusCode,
        );
      case AIProvider.google:
        return AIError(
          message: json['error']?['message'] ?? 'Unknown Google error',
          statusCode: statusCode,
        );
      case AIProvider.deepInfra:
        return AIError(
          message: json['detail'] ?? 'Unknown deepInfra error',
          statusCode: statusCode,
        );
    }
  }
}

// Unified API Call
Future<AIResult> fetchAIResponse(
  AIProvider provider,
  Uri url,
  Map<String, dynamic> body,
  String apiKey,
) async {
  try {
    final response = await http.post(
      url,
      body: jsonEncode(body),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey', // Replace if needed
      },
    );

    final json = jsonDecode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final parsed = AIResponseParser.parse(provider, json);
      return AISuccess(parsed);
    } else {
      final error = AIErrorParser.parse(provider, json, response.statusCode);
      return AIErrorResult(error);
    }
  } catch (e) {
    return AIErrorResult(AIError(message: 'Unexpected error: ${e.toString()}'));
  }
}
