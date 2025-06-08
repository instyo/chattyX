import 'package:chatty/utils/ai_services/ai_provider.dart';

enum AIType { openAI, ollama, claude }

class AIModel {
  final String id;
  final String name;
  final AIProvider type;
  final String url;
  final String token;
  final String model;
  final int contextSize;
  final int maxToken;
  final bool streamResponses;
  final String icon; // New string object named icon

  const AIModel({
    required this.id,
    required this.name,
    required this.type,
    required this.url,
    required this.token,
    required this.model,
    required this.contextSize,
    required this.maxToken,
    required this.streamResponses,
    required this.icon, // Include icon in the constructor
  });

  Uri get uri => Uri.parse(url);

  // Factory constructor to create an AIModel from a Map
  factory AIModel.fromMap(Map<String, dynamic> map) {
    return AIModel.placeholder().copyWith(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      type:
          AIProvider.values
              .where((e) => e.name == (map['type'] ?? ''))
              .firstOrNull ??
          AIProvider.openAI,
      url: map['url'] ?? '',
      token: map['token'] ?? '',
      model: map['model'] ?? '',
      contextSize: map['contextSize'] ?? 0,
      maxToken: map['maxToken'] ?? 0,
      streamResponses: map['streamResponses'] ?? false,
      icon: map['icon'] ?? '', // Extract icon from the map
    );
  }

  factory AIModel.placeholder() {
    return AIModel(
      id: '',
      name: '',
      type: AIProvider.openAI,
      url: '',
      token: '',
      model: '',
      contextSize: 5,
      maxToken: 100,
      streamResponses: false,
      icon: '', // Provide a default value for icon
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'url': url,
      'token': token,
      'model': model,
      'contextSize': contextSize,
      'maxToken': maxToken,
      'streamResponses': streamResponses,
      'icon': icon, // Include icon in the map representation
    };
  }

  AIModel copyWith({
    String? id,
    String? name,
    AIProvider? type,
    String? url,
    String? token,
    String? model,
    int? contextSize,
    int? maxToken,
    bool? streamResponses,
    String? icon, // Add icon to copyWith parameters
  }) {
    return AIModel(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      url: url ?? this.url,
      token: token ?? this.token,
      model: model ?? this.model,
      contextSize: contextSize ?? this.contextSize,
      maxToken: maxToken ?? this.maxToken,
      streamResponses: streamResponses ?? this.streamResponses,
      icon: icon ?? this.icon, // Include icon in copyWith
    );
  }
}
