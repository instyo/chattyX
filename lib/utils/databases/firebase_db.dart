import 'package:chatty/utils/initial_data.dart';
import 'package:chatty/utils/models/ai_assistant.dart';
import 'package:chatty/utils/models/ai_model.dart';
import 'package:chatty/utils/models/base_message_model.dart';
import 'package:chatty/utils/databases/chat_database.dart';
import 'package:chatty/utils/models/message_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:uuid/uuid.dart';

class FirebaseDb implements BaseChatDatabase {
  final _chatStore = FirebaseFirestore.instance.collection('chats');
  final _messageStore = FirebaseFirestore.instance.collection('messages');
  final _assistantStore = FirebaseFirestore.instance.collection('assistants');
  final _modelStore = FirebaseFirestore.instance.collection('models');
  final _metaStore = FirebaseFirestore.instance.collection('meta');
  final uuid = Uuid();

  Future<void> init() async {
    try {
      await insertDefaultDataIfFirstRun();
    } catch (e, s) {
      debugPrint('Error during init: $e\n$s');
    }
  }

  Future<void> insertDefaultDataIfFirstRun() async {
    final docRef = _metaStore.doc('app_metadata');
    final docSnapshot = await docRef.get();

    final data = docSnapshot.data() ?? {};
    final defaultsInserted = data['defaults_inserted'] ?? false;

    if (!defaultsInserted) {
      await insertDefaultDataIfNeeded();
      await docRef.set({'defaults_inserted': true}, SetOptions(merge: true));
    }
  }

  Future<void> insertDefaultDataIfNeeded() async {
    final batch = FirebaseFirestore.instance.batch(); // Create a batch
    final docRef = _metaStore.doc('app_metadata');

    try {
      // Check if defaults are already inserted
      final docSnapshot = await docRef.get();
      final data = docSnapshot.data() ?? {};
      final defaultsInserted = data['defaults_inserted'] ?? false;

      if (!defaultsInserted) {
        // Add models to batch
        for (var model in kModels.reversed) {
          final docRef = _modelStore.doc(model.id);
          batch.set(docRef, model.toMap(), SetOptions(merge: true));
        }

        // Add assistants to batch
        for (var assistant in kAssistants.reversed) {
          final docRef = _assistantStore.doc(assistant.id);
          batch.set(docRef, assistant.toMap(), SetOptions(merge: true));
        }

        // Commit the batch
        await batch.commit();

        // Set the flag in meta document
        batch.set(docRef, {'defaults_inserted': true}, SetOptions(merge: true));
        await batch.commit();
      }
    } catch (e, s) {
      debugPrint('Error during insertDefaultDataIfNeeded: $e\n$s');
    }
  }

  @override
  Future<void> deleteAIModel(String id) async {
    await _modelStore.doc(id).delete();
  }

  @override
  Future<void> deleteAssistant(String id) async {
    await _assistantStore.doc(id).delete();
  }

  @override
  Future<void> deleteChat(String id) async {
    await _chatStore.doc(id).delete();
    // Also delete conversations
    final conversations =
        await _messageStore.where('baseMessageId', isEqualTo: id).get();

    await Future.forEach(conversations.docs, (item) async {
      await item.reference.delete();
    });
  }

  @override
  Future<List<AIModel>> getAIModels() async {
    try {
      final result = await _modelStore.get();
      return result.docs
          .map((doc) => AIModel.fromMap({"id": doc.id, ...doc.data()}))
          .toList();
    } catch (e, s) {
      debugPrint('Error fetching AIModels: $e\n$s');
      return []; // or handle as needed
    }
  }

  @override
  Future<List<BaseMessageModel>> getAllChats() async {
    final result = await _chatStore.get();
    return result.docs
        .map((doc) => BaseMessageModel.fromMap({"id": doc.id, ...doc.data()}))
        .toList();
  }

  @override
  Stream<List<BaseMessageModel>> getAllChats$(String keyword) {
    if (keyword.isEmpty) {
      // If no keyword, return all chats
      return _chatStore.snapshots().map(
        (snapshot) =>
            snapshot.docs
                .map(
                  (doc) =>
                      BaseMessageModel.fromMap({"id": doc.id, ...doc.data()}),
                )
                .toList(),
      );
    } else {
      // If keyword is provided, filter chats where title or description contains the keyword (case-insensitive)
      final lowerKeyword = keyword.toLowerCase();
      return _chatStore.snapshots().map((snapshot) {
        final allDocs =
            snapshot.docs
                .map(
                  (doc) =>
                      BaseMessageModel.fromMap({"id": doc.id, ...doc.data()}),
                )
                .toList();
        if (keyword.isEmpty) {
          return allDocs; // Return all chats if no keyword
        }
        return allDocs.where((chat) {
          final title = chat.title.toLowerCase();
          final description = chat.description.toLowerCase();
          return title.contains(lowerKeyword) ||
              description.contains(lowerKeyword);
        }).toList();
      });
    }
  }

  @override
  Future<List<AiAssistant>> getAssistants() async {
    final result = await _assistantStore.get();
    return result.docs
        .map((doc) => AiAssistant.fromMap({"id": doc.id, ...doc.data()}))
        .toList();
  }

  @override
  Future<List<MessageModel>> getMessagesForChat(String baseMessageId) async {
    final result =
        await _messageStore
            .where('baseMessageId', isEqualTo: baseMessageId)
            .orderBy('createdAt')
            .get();

    // Note: Currently fetches all messages; consider filtering by baseMessageId if needed
    return result.docs.map((doc) {
      return MessageModel.fromMap({"id": doc.id, ...doc.data()});
    }).toList();
  }

  @override
  Future<void> insertAIModel(AIModel model) async {
    try {
      await _modelStore
          .doc(model.id)
          .set(model.toMap(), SetOptions(merge: true));
    } catch (e, s) {
      debugPrint('Error inserting AIModel with id ${model.id}: $e\n$s');
      // Optionally, rethrow or handle error
      // rethrow;
    }
  }

  @override
  Future<void> insertAssistant(AiAssistant assistant) async {
    try {
      await _assistantStore
          .doc(assistant.id)
          .set(assistant.toMap(), SetOptions(merge: true));
    } catch (e, s) {
      debugPrint('Error inserting AiAssistant with id ${assistant.id}: $e\n$s');
      // Optionally, rethrow or handle error
      // rethrow;
    }
  }

  @override
  Future<void> insertMessage(String baseMessageId, MessageModel message) async {
    await _messageStore.add({
      'baseMessageId': baseMessageId,
      ...message.toMap(),
    });
  }

  @override
  Future<void> insertNewChat(BaseMessageModel message) async {
    await _chatStore
        .doc(message.id) // Use doc() with the baseMessageId
        .set(message.toMap(), SetOptions(merge: true)); // Merge to allow upsert
  }

  @override
  Stream<List<AIModel>> get listAIModels$ => _modelStore.snapshots().map(
    (snapshot) =>
        snapshot.docs
            .map((doc) => AIModel.fromMap({"id": doc.id, ...doc.data()}))
            .toList(),
  );

  @override
  Stream<List<AiAssistant>> get listAiAssistants$ =>
      _assistantStore.snapshots().map(
        (snapshot) =>
            snapshot.docs
                .map(
                  (doc) => AiAssistant.fromMap({"id": doc.id, ...doc.data()}),
                )
                .toList(),
      );

  @override
  Future<void> updateAIModel(AIModel model) async {
    await _modelStore.doc(model.id).update(model.toMap());
  }

  @override
  Future<void> updateAssistant(AiAssistant assistant) async {
    await _assistantStore.doc(assistant.id).update(assistant.toMap());
  }
}
