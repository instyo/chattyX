import 'package:chatty/utils/models/ai_assistant.dart';
import 'package:chatty/utils/models/ai_model.dart';
import 'package:chatty/utils/models/base_message_model.dart';
import 'package:chatty/utils/models/message_model.dart';

abstract class BaseChatDatabase {
  Future<List<BaseMessageModel>> getAllChats();
  Future<void> insertNewChat(BaseMessageModel message);
  Future<void> deleteChat(String id);
  Future<List<MessageModel>> getMessagesForChat(String baseMessageId);
  Future<void> insertMessage(String baseMessageId, MessageModel message);
  Future<void> insertAssistant(AiAssistant assistant);
  Future<void> insertAIModel(AIModel model);
  Future<List<AIModel>> getAIModels();
  Future<List<AiAssistant>> getAssistants();
  Stream<List<BaseMessageModel>> getAllChats$(String keyword);
  Stream<List<AIModel>> get listAIModels$;
  Stream<List<AiAssistant>> get listAiAssistants$;
  Future<void> deleteAIModel(String id);
  Future<void> deleteAssistant(String id);
  Future<void> updateAssistant(AiAssistant assistant);
  Future<void> updateAIModel(AIModel model);
}
