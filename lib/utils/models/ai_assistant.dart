class AiAssistant {
  final String id;
  final String name;
  final String prompt;
  final String color;
  final String icon; // New string object named icon

  const AiAssistant({
    required this.id,
    required this.name,
    required this.prompt,
    this.color = '#eeeeee',
    this.icon = '', // Include icon in the constructor
  });

  // Factory constructor to create an AiAssistant from a Map
  factory AiAssistant.fromMap(Map<String, dynamic> map) {
    return AiAssistant.placeholder().copyWith(
      id: map['id'],
      name: map['name'],
      prompt: map['prompt'],
      color: map['color'],
      icon: map['icon'], // Extract icon from the map
    );
  }

  factory AiAssistant.placeholder() {
    return AiAssistant(
      id: '',
      name: '',
      prompt: '',
      color: '#cccccc',
      icon: '',
    ); // Provide a default value for icon
  }

  AiAssistant copyWith({
    String? id,
    String? name,
    String? prompt,
    String? color,
    String? icon, // Add icon to copyWith parameters
  }) {
    return AiAssistant(
      id: id ?? this.id,
      name: name ?? this.name,
      prompt: prompt ?? this.prompt,
      color: color ?? this.color,
      icon: icon ?? this.icon, // Include icon in copyWith
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'prompt': prompt,
      'color': color,
      'icon': icon, // Include icon in the map representation
    };
  }
}
