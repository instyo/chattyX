part of '../message_input.dart';

class _QuotedMessageSection extends StatelessWidget {
  const _QuotedMessageSection();

  @override
  Widget build(BuildContext context) {
    final controller = context.read<MessageInputController>();

    return StreamBuilder(
      stream: controller.quotedMessage$,
      initialData: ('', ''),
      builder: (context, snapshot) {
        final (quotedText, quotedMessageId) = snapshot.data!;

        return AnimatedSwitcher(
          duration: Duration(milliseconds: 300),
          reverseDuration: Duration(milliseconds: 300),
          child:
              quotedText.isEmpty
                  ? const SizedBox()
                  : Container(
                    padding: EdgeInsets.all(8),
                    margin: EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey.shade300,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          margin: EdgeInsets.only(right: 12),
                          child: Icon(
                            CupertinoIcons.arrow_turn_down_right,
                            size: 16,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            '"$quotedText"',
                            style: TextStyle(color: Colors.grey.shade600),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        TouchableOpacity(
                          child: Container(
                            padding: EdgeInsets.only(left: 12),
                            child: Icon(CupertinoIcons.clear, size: 20),
                          ),
                          onTap: () {
                            controller.clearQuotedMessage();
                          },
                        ),
                      ],
                    ),
                  ),
        );
      },
    );
  }
}
