part of 'assistants_setting.dart';

class AssistantsState {
  final List<AiAssistant> aiAssistants;
  final StateStatus status;
  final bool showEditField;
  final AiAssistant? selectedAssistant;

  const AssistantsState({
    this.aiAssistants = const [],
    this.status = StateStatus.idle,
    this.showEditField = false,
    this.selectedAssistant,
  });

  bool get isEdit => selectedAssistant != null && showEditField;

  AssistantsState copyWith({
    List<AiAssistant>? aiAssistants,
    StateStatus? status,
    bool? showEditField,
    AiAssistant? selectedAssistant,
  }) {
    return AssistantsState(
      aiAssistants: aiAssistants ?? this.aiAssistants,
      status: status ?? this.status,
      showEditField: showEditField ?? this.showEditField,
      selectedAssistant: selectedAssistant ?? this.selectedAssistant,
    );
  }

  AssistantsState withoutModel({bool? showEditField}) {
    return AssistantsState(
      aiAssistants: aiAssistants,
      status: status,
      showEditField: showEditField ?? this.showEditField,
      selectedAssistant: null,
    );
  }
}
