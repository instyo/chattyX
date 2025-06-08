part of 'models_screen.dart';

class ModelsState {
  final List<AIModel> aiModels;
  final StateStatus status;
  final bool showEditField;
  final AIModel? selectedModel;

  const ModelsState({
    this.aiModels = const [],
    this.status = StateStatus.idle,
    this.showEditField = false,
    this.selectedModel,
  });

  bool get isEdit => selectedModel != null && showEditField;

  ModelsState copyWith({
    List<AIModel>? aiModels,
    StateStatus? status,
    bool? showEditField,
    AIModel? selectedModel,
  }) {
    return ModelsState(
      aiModels: aiModels ?? this.aiModels,
      status: status ?? this.status,
      showEditField: showEditField ?? this.showEditField,
      selectedModel: selectedModel ?? this.selectedModel,
    );
  }

  ModelsState withoutModel({bool? showEditField}) {
    return ModelsState(
      aiModels: aiModels,
      status: status,
      showEditField: showEditField ?? this.showEditField,
      selectedModel: null,
    );
  }
}
