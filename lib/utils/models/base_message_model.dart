class BaseMessageModel {
  final String id;
  final String title;
  final String description;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isPinned;

  const BaseMessageModel({
    required this.id,
    required this.title,
    required this.description,
    required this.createdAt,
    required this.updatedAt,
    required this.isPinned,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isPinned': isPinned ? 1 : 0,
    };
  }

  factory BaseMessageModel.fromMap(Map<String, dynamic> map) {
    return BaseMessageModel(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      createdAt: DateTime.tryParse(map['createdAt']) ?? DateTime.now(),
      updatedAt: DateTime.tryParse(map['updatedAt']) ?? DateTime.now(),
      isPinned: map['isPinned'] == 1,
    );
  }

  factory BaseMessageModel.create({required String id}) {
    return BaseMessageModel(
      id: id,
      title: '',
      description: '',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isPinned: false,
    );
  }

  BaseMessageModel copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isPinned,
  }) {
    return BaseMessageModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isPinned: isPinned ?? this.isPinned,
    );
  }
}
