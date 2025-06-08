part of 'models_screen.dart';

class ModelsController extends RxController<ModelsState> {
  final ChatRepository chatRepository = sl<ChatRepository>();
  Stream<List<AIModel>> get list$ =>
      stream.map((state) => state.aiModels.reversed.toList()).distinct();

  Stream<AIModel?> get selected$ =>
      stream.map((state) => state.selectedModel).distinct();

  Stream<(bool, AIModel?)> get isEdit$ =>
      stream
          .map((state) => (state.showEditField, state.selectedModel))
          .distinct();

  void setAiModel(AIModel model) {
    setState(
      (state) => state.copyWith(selectedModel: model, showEditField: false),
    );
  }

  Future<void> setDefaultAIModel() async {
    final prefs = await SharedPreferences.getInstance();
    final defaultModelId = prefs.getString('defaultModelId');

    if (defaultModelId != null) {
      final models = await chatRepository.getAIModels();
      final defaultModel = models.firstWhere(
        (model) => model.id == defaultModelId,
        orElse: () => AIModel.placeholder(),
      );

      setState((state) => state.copyWith(selectedModel: defaultModel));
    } else {
      setState((state) => state.copyWith(selectedModel: state.aiModels.first));
    }
  }

  Future<void> getAiModels() async {
    try {
      setState((state) => state.copyWith(status: StateStatus.loading));

      final models = await chatRepository.getAIModels();
      setState(
        (state) =>
            state.copyWith(aiModels: models, status: StateStatus.success),
      );

      // Call set default ai model when all models loaded
      setDefaultAIModel();
    } catch (e) {
      // Handle error appropriately
      debugPrint('Error fetching AI models: $e');
      setState((state) => state.copyWith(status: StateStatus.error));
    }
  }

  Future<void> addAiModel(AIModel data) async {
    await chatRepository.insertAIModel(data);
  }

  void edit(AIModel data) {
    setState(
      (state) => state.copyWith(showEditField: true, selectedModel: data),
    );
  }

  void toggleEditField({AIModel? data, bool showEditFiled = true}) {
    setState(
      (state) =>
          data == null
              ? state.withoutModel(showEditField: showEditFiled)
              : state.copyWith(showEditField: showEditFiled),
    );
  }

  Future<void> deleteAiModel(String id) async {
    try {
      await chatRepository.deleteAIModel(id);
      // Optionally, refresh the list of AI models after deletion
      await getAiModels();
    } catch (e) {
      // Handle error appropriately
      debugPrint('Error deleting AI model: $e');
    }
  }

  Future<void> updateAiModel(AIModel model) async {
    setState((state) => state.copyWith(status: StateStatus.loading));
    try {
      await chatRepository.updateAIModel(model);
    } catch (e) {
      debugPrint('Error updating AI model: $e');
    } finally {
      setState((state) => state.copyWith(status: StateStatus.success));
    }
  }

  @override
  ModelsState initState() {
    return ModelsState();
  }
}
