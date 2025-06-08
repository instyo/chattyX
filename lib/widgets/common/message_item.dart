import 'dart:async';
import 'package:chatty/widgets/common/cached_base64_image.dart';
import 'package:chatty/widgets/common/message_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:chatty/utils/models/message_model.dart';
import 'package:chatty/utils/context_extension.dart';
import 'package:chatty/widgets/common/touchable_opacity.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:gpt_markdown/gpt_markdown.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';

class MessageItem extends StatelessWidget {
  final MessageModel message;
  final Function() onRetry;
  final Function(String text) onQuote;

  const MessageItem({
    super.key,
    required this.message,
    required this.onRetry,
    required this.onQuote,
  });

  Widget _buildSelectable(BuildContext context, {required Widget child}) {
    if (context.isDesktop) {
      return MessageWrapper(
        onReply: onQuote,
        onCopy: (s) {
          Clipboard.setData(ClipboardData(text: s));
        },
        onSearch: (s) {
          final url = Uri.encodeFull(s);
          launchUrl(
            Uri.parse('https://www.google.com/search?q=$url'),
            mode: LaunchMode.externalApplication,
          );
        },
        enabled: !message.own,
        child: child,
      );
    }

    String selectedText = '';

    return SelectionArea(
      onSelectionChanged: (value) {
        DeBouncer.run(() {
          if (value?.plainText.isNotEmpty == true) {
            selectedText = value!.plainText;
          }
        });
      },
      contextMenuBuilder: (context, editableTextState) {
        final List<ContextMenuButtonItem> buttonItems =
            editableTextState.contextMenuButtonItems;

        if (!message.own) {
          buttonItems.insert(
            0,
            ContextMenuButtonItem(
              label: 'Quote',
              onPressed: () {
                editableTextState.hideToolbar();
                onQuote(selectedText);
                editableTextState.clearSelection();
              },
            ),
          );
        }

        return AdaptiveTextSelectionToolbar.buttonItems(
          anchors: editableTextState.contextMenuAnchors,
          buttonItems: buttonItems,
        );
      },
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return _buildSelectable(
      context,
      child: Row(
        mainAxisAlignment:
            message.own ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth:
                    message.own
                        ? context.screenWidth / 1.35
                        : !context.isDesktop
                        ? context.screenWidth / 1.15
                        : context.screenWidth / 1.35,
              ),
              child: _buildMessageItem(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageItem(BuildContext context) {
    double imageSize;
    if (context.isMobile) {
      imageSize = context.screenWidth / 1.5; // Mobile size
    } else if (context.isTablet) {
      imageSize = context.screenWidth / 3; // Tablet size
    } else {
      imageSize = context.screenWidth / 6; // Desktop size
    }

    if (message.isLoading) {
      return Row(
        // crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment:
            message.own ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          Shimmer.fromColors(
            baseColor: Colors.grey,
            highlightColor: Colors.grey.shade300,
            child: _buildMessageWrapper(text: 'Thinking'),
          ),
        ],
      );
    }

    if (message.isError) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMessageWrapper(),
          TouchableOpacity(
            onTap: onRetry,
            child: Row(
              children: [
                Icon(CupertinoIcons.arrow_clockwise, size: 16),
                const SizedBox(width: 8),
                Text('Retry'),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      );
    }

    if (message.isImage) {
      return Column(
        crossAxisAlignment:
            message.own ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          for (final image in message.images)
            Container(
              margin: EdgeInsets.only(bottom: 8),
              child: CachedBase64Image(base64: image, maxSize: imageSize),
            ),
          _buildMessageWrapper(),
        ],
      );
    }

    return _buildMessageWrapper();
  }

  Widget _buildMessageWrapper({String? text}) {
    if (!message.own) {
      return Container(
        margin: EdgeInsets.only(bottom: 8),
        child: GptMarkdown(text ?? message.message),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (message.quotedText.isNotEmpty)
          Container(
            padding: EdgeInsets.only(left: 8),
            decoration: BoxDecoration(
              border: Border(left: BorderSide(width: 2, color: Colors.grey)),
            ),
            margin: EdgeInsets.only(bottom: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Flexible(
                  child: Text(
                    message.quotedText.trim(),
                    style: TextStyle(color: Colors.grey),
                    textAlign: TextAlign.justify,
                  ),
                ),
              ],
            ),
          ),
        Container(
          margin: EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Colors.grey.shade200,
          ),
          padding: EdgeInsets.all(8),
          child: Text(
            text ?? message.message,
            style: TextStyle(color: Colors.black),
          ),
        ),
      ],
    );
  }
}

class DeBouncer {
  int? milliseconds; // The delay time for debouncing in milliseconds
  VoidCallback? action; // The action to be executed

  static Timer? timer; // A static Timer instance to manage the debouncing

  static run(VoidCallback action) {
    if (null != timer) {
      timer!.cancel(); // Cancel any previous Timer instance
    }
    timer = Timer(
      const Duration(milliseconds: 1000),
      action, // Schedule the action after a delay
    );
  }
}
