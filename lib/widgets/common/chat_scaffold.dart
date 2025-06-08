import 'package:flutter/material.dart';

class ChatScaffold extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final Widget body;

  const ChatScaffold({super.key, this.appBar, required this.body});

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: appBar, body: body);
  }
}
