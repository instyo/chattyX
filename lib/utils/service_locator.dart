import 'package:chatty/utils/repository/chat_repository.dart';
import 'package:chatty/utils/databases/firebase_db.dart';
import 'package:chatty/utils/databases/sembast_db.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:get_it/get_it.dart';
import 'package:image_picker/image_picker.dart';
import 'package:openai_dart/openai_dart.dart';

final sl = GetIt.instance;

Future<void> setupServiceLocator({bool useFirebase = false}) async {
  try {
    // Libs
    sl.registerFactory<ImagePicker>(() => ImagePicker());
    sl.registerFactory<Dio>(() => Dio());
    sl.registerFactory<OpenAIClient>(() => OpenAIClient());

    // Service

    if (useFirebase) {
      // Storage
      sl.registerFactory<FirebaseDb>(() => FirebaseDb());

      // Repositories
      sl.registerSingleton<ChatRepository>(
        ChatRepository(db: sl<FirebaseDb>(), dio: sl<Dio>()),
      );
    } else {
      // Storage
      // sl.registerSingleton<BaseChatDatabase>(LocalChatDatabase());
      sl.registerSingleton<SembastChatDatabase>(SembastChatDatabase());

      // Repositories
      sl.registerSingleton<ChatRepository>(
        ChatRepository(db: sl<SembastChatDatabase>(), dio: sl<Dio>()),
      );

      // Services

      // Helper/Utils

      // Initialize local db
      await sl<SembastChatDatabase>().init(); // Initialize the database
    }
  } catch (e, s) {
    debugPrint(">> ERR : $e, $s");
  }
}
