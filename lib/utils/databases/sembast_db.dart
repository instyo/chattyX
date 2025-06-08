import 'dart:async';

import 'package:chatty/utils/initial_data.dart';
import 'package:chatty/utils/models/ai_assistant.dart';
import 'package:chatty/utils/models/ai_model.dart';
import 'package:chatty/utils/models/base_message_model.dart';
import 'package:chatty/utils/databases/chat_database.dart';
import 'package:chatty/utils/models/message_model.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sembast/sembast_io.dart';
import 'package:sembast_web/sembast_web.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class SembastChatDatabase extends BaseChatDatabase {
  late final Database _db;

  final _chatStore = stringMapStoreFactory.store('chats');
  final _messageStore = stringMapStoreFactory.store('messages');
  final _assistantStore = stringMapStoreFactory.store('assistants');
  final _modelStore = stringMapStoreFactory.store('models');
  final uuid = Uuid();

  Future<void> init() async {
    try {
      if (kIsWeb) {
        _db = await databaseFactoryWeb.openDatabase('/assets/db');
      } else {
        final appDir = await getApplicationDocumentsDirectory();
        final dbPath = join(appDir.path, 'chat.db');
        _db = await databaseFactoryIo.openDatabase(dbPath);
      }

      await insertDefaultDataIfFirstRun();
    } catch (e, s) {
      debugPrint('$e, $s');
    }
  }

  Future<void> insertDefaultDataIfFirstRun() async {
    final prefs = await SharedPreferences.getInstance();
    final firstRun = !(prefs.getBool('defaults_inserted') ?? false);

    if (firstRun) {
      await insertDefaultDataIfNeeded();
      await prefs.setBool('defaults_inserted', true);
    }
  }

  Future<void> insertDefaultDataIfNeeded() async {
    await Future.forEach(kModels, (item) async {
      await insertAIModel(item);
    });

    await Future.forEach(kAssistants, (item) async {
      await insertAssistant(item);
    });
  }

  @override
  Future<List<BaseMessageModel>> getAllChats() async {
    final records = await _chatStore.find(_db);
    return records.map((e) => BaseMessageModel.fromMap(e.value)).toList();
  }

  @override
  Future<void> insertNewChat(BaseMessageModel message) async {
    await _chatStore.record(message.id).put(_db, message.toMap());
  }

  @override
  Future<void> deleteChat(String id) async {
    await _chatStore.record(id).delete(_db);
  }

  @override
  Future<List<MessageModel>> getMessagesForChat(String baseMessageId) async {
    try {
      final finder = Finder(
        filter: Filter.equals('baseMessageId', baseMessageId),
      );

      final records = await _messageStore.find(_db, finder: finder);

      return records.map((e) => MessageModel.fromMap(e.value)).toList();
    } catch (e, s) {
      debugPrint(">> GAMS : $e, $s");
      return [];
    }
  }

  @override
  Future<void> insertMessage(String baseMessageId, MessageModel message) async {
    try {
      await _db.transaction((txn) async {
        await _messageStore.add(txn, message.toMap());
      });
    } catch (e, s) {
      debugPrint('$e, $s');
    }
  }

  @override
  Future<void> insertAssistant(AiAssistant assistant) async {
    await _db.transaction((txn) async {
      await _assistantStore.add(txn, assistant.toMap());
    });
  }

  @override
  Future<void> insertAIModel(AIModel model) async {
    await _db.transaction((txn) async {
      await _modelStore.add(txn, model.toMap());
    });
  }

  @override
  Future<List<AIModel>> getAIModels() async {
    final records = await _modelStore.find(_db);
    return records.map((e) => AIModel.fromMap(e.value)).toList();
  }

  @override
  Future<List<AiAssistant>> getAssistants() async {
    final records = await _assistantStore.find(_db);
    return records.map((e) => AiAssistant.fromMap(e.value)).toList();
  }

  @override
  Stream<List<BaseMessageModel>> getAllChats$(String keyword) {
    // final finder = Finder(
    //   filter:
    //       keyword.isNotEmpty
    //           ? Filter.arrayContains(
    //             'title',
    //             keyword,
    //           ) // Assuming 'title' is the field to search
    //           : null,
    // );

    var regExp = RegExp(keyword, caseSensitive: false);

    final filter = Filter.and([
      Filter.or([
        Filter.matchesRegExp('title', regExp),
        Filter.matchesRegExp('description', regExp),
      ]),
    ]);

    final finder = Finder(filter: filter, sortOrders: [SortOrder('createdAt')]);

    return _chatStore
        .query(finder: finder) // Apply the finder to the query
        .onSnapshots(_db)
        .transform(kBaseMessageModelTransformer);
  }

  @override
  Stream<List<AIModel>> get listAIModels$ {
    return _modelStore
        .query() // Apply the finder to the query
        .onSnapshots(_db)
        .transform(kAIModelsTransformer);
  }

  @override
  Stream<List<AiAssistant>> get listAiAssistants$ {
    return _assistantStore
        .query() // Apply the finder to the query
        .onSnapshots(_db)
        .transform(kAiAssistantsTransformer);
  }

  @override
  Future<void> deleteAIModel(String id) async {
    await _db.transaction((txn) async {
      await _modelStore.delete(
        txn,
        finder: Finder(filter: Filter.equals('id', id)),
      );
    });
  }

  @override
  Future<void> deleteAssistant(String id) async {
    await _db.transaction((txn) async {
      await _assistantStore.delete(
        txn,
        finder: Finder(filter: Filter.equals('id', id)),
      );
    });
  }

  @override
  Future<void> updateAIModel(AIModel model) async {
    await _db.transaction((txn) async {
      // Don't know why sembast not updating the data
      // to fix this (hacky way) i will delete latest data and insert new data after
      await _modelStore.delete(
        txn,
        finder: Finder(filter: Filter.equals('id', model.id)),
      );

      await _modelStore.record(model.id).put(txn, model.toMap());
    });
  }

  @override
  Future<void> updateAssistant(AiAssistant assistant) async {
    await _db.transaction((txn) async {
      await _assistantStore.record(assistant.id).put(txn, assistant.toMap());
    });
  }
}

final kBaseMessageModelTransformer = StreamTransformer<
  List<RecordSnapshot<String, Map<String, Object?>>>,
  List<BaseMessageModel>
>.fromHandlers(
  handleData: (snapshotList, sink) {
    sink.add(
      snapshotList.map((e) => BaseMessageModel.fromMap(e.value)).toList(),
    );
  },
);

final kAIModelsTransformer = StreamTransformer<
  List<RecordSnapshot<String, Map<String, Object?>>>,
  List<AIModel>
>.fromHandlers(
  handleData: (snapshotList, sink) {
    sink.add(snapshotList.map((e) => AIModel.fromMap(e.value)).toList());
  },
);

final kAiAssistantsTransformer = StreamTransformer<
  List<RecordSnapshot<String, Map<String, Object?>>>,
  List<AiAssistant>
>.fromHandlers(
  handleData: (snapshotList, sink) {
    sink.add(snapshotList.map((e) => AiAssistant.fromMap(e.value)).toList());
  },
);
