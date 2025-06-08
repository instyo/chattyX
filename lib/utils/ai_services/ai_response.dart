abstract class AIResponse {
  String get text;
}

class OpenAIResponse implements AIResponse {
  final String id;
  final String content;

  OpenAIResponse({required this.id, required this.content});

  factory OpenAIResponse.fromJson(Map<String, dynamic> json) {
    return OpenAIResponse(
      id: json['id'],
      content: json['choices'][0]['message']['content'],
    );
  }

  @override
  String get text => content;
}

class GoogleAIResponse implements AIResponse {
  final String responseText;

  GoogleAIResponse({required this.responseText});

  factory GoogleAIResponse.fromJson(Map<String, dynamic> json) {
    return GoogleAIResponse(responseText: json['predictions'][0]['content']);
  }

  @override
  String get text => responseText;
}
