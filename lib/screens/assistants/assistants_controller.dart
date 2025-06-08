part of 'assistants_setting.dart';

class AssistantsController extends RxController<AssistantsState> {
  final ChatRepository chatRepository = sl<ChatRepository>();
  Stream<List<AiAssistant>> get list$ =>
      stream.map((state) => state.aiAssistants.reversed.toList()).distinct();

  Stream<AiAssistant?> get selected$ =>
      stream.map((state) => state.selectedAssistant).distinct();

  Stream<(bool, AiAssistant?)> get isEdit$ =>
      stream
          .map((state) => (state.showEditField, state.selectedAssistant))
          .distinct();

  void setAiAssistant(AiAssistant assistant) {
    setState(
      (state) =>
          state.copyWith(selectedAssistant: assistant, showEditField: false),
    );
  }

  Future<void> setDefaultAiAssistant() async {
    final prefs = await SharedPreferences.getInstance();
    final defaultAssistantId = prefs.getString('defaultAssistantId');

    if (defaultAssistantId != null) {
      final assistants = await chatRepository.getAssistants();
      final defaultAssistant = assistants.firstWhere(
        (assistant) => assistant.id == defaultAssistantId,
        orElse: () => AiAssistant.placeholder(),
      );

      setState((state) => state.copyWith(selectedAssistant: defaultAssistant));
    } else {
      setState(
        (state) => state.copyWith(selectedAssistant: state.aiAssistants.first),
      );
    }
  }

  Future<void> getAiAssistants() async {
    try {
      setState((state) => state.copyWith(status: StateStatus.loading));

      final data = await chatRepository.getAssistants();

      setState(
        (state) =>
            state.copyWith(aiAssistants: data, status: StateStatus.success),
      );

      setDefaultAiAssistant();
    } catch (e) {
      // Handle error appropriately
      setState((state) => state.copyWith(status: StateStatus.error));
    }
  }

  Future<void> addAiAssistant(AiAssistant data) async {
    await chatRepository.insertAssistant(data);
  }

  void edit(AiAssistant data) {
    setState(
      (state) => state.copyWith(showEditField: true, selectedAssistant: data),
    );
  }

  void toggleEditField({AiAssistant? data, bool showEditFiled = true}) {
    setState(
      (state) =>
          data == null
              ? state.withoutModel(showEditField: showEditFiled)
              : state.copyWith(showEditField: showEditFiled),
    );
  }

  Future<void> deleteAiAssistant(String id) async {
    try {
      await chatRepository.deleteAssistant(id);
      // Optionally, refresh the list of AI models after deletion
      await getAiAssistants();
    } catch (e) {
      // Handle error appropriately
      debugPrint('Error deleting AI model: $e');
    }
  }

  Future<void> updateAiAssistant(AiAssistant data) async {
    setState((state) => state.copyWith(status: StateStatus.loading));
    try {
      await chatRepository.updateAssistant(data);
    } catch (e) {
      debugPrint('Error updating AI model: $e');
    } finally {
      setState((state) => state.copyWith(status: StateStatus.success));
    }
  }

  @override
  AssistantsState initState() {
    return AssistantsState();
  }
}
