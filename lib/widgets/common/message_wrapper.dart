
import 'package:chatty/widgets/common/message_item.dart';
import 'package:flutter/material.dart';

class MessageWrapper extends StatefulWidget {
  final Function(String) onCopy;
  final Function(String) onReply;
  final Function(String) onSearch;
  final bool enabled;
  final Widget child;

  const MessageWrapper({
    super.key,
    required this.child,
    required this.onCopy,
    required this.onReply,
    required this.onSearch,
    this.enabled = true,
  });

  @override
  State<MessageWrapper> createState() => _MessageWrapperState();
}

class _MessageWrapperState extends State<MessageWrapper> {
  String _text = '';
  Offset _offset = Offset(0, 0);
  FocusNode focus = FocusNode();

  void _clear() {
    _text = '';
    focus.unfocus();
    if (!mounted) return;
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown:
          !widget.enabled
              ? null
              : (event) {
                _offset = event.position;
              },
      child: SelectionArea(
        focusNode: focus,
        onSelectionChanged:
            !widget.enabled
                ? null
                : (value) {
                  DeBouncer.run(() {
                    if (value?.plainText.isNotEmpty == true) {
                      _text = value!.plainText;
    
                      final overlay = Overlay.of(context);
                      late OverlayEntry overlayEntry;
    
                      overlayEntry = OverlayEntry(
                        canSizeOverlay: true,
                        builder:
                            (context) => Material(
                              color: Colors.transparent,
                              child: SizedBox.expand(
                                child: Stack(
                                  children: [
                                    // This absorbs all taps and dismisses the overlay
                                    Positioned.fill(
                                      child: GestureDetector(
                                        behavior: HitTestBehavior.translucent,
                                        onTap: () {
                                          overlayEntry.remove();
                                        },
                                      ),
                                    ),
                                    Positioned(
                                      top: _offset.dy + 16,
                                      left: _offset.dx,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.black87,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          children: [
                                            GestureDetector(
                                              onTap: () {
                                                widget.onReply(_text);
                                                overlayEntry.remove();
                                                _clear();
                                              },
                                              child: Container(
                                                padding: EdgeInsets.all(8),
                                                child: Text(
                                                  "💬 Reply",
                                                  style: TextStyle(
                                                    color: Colors.grey.shade200,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            Container(
                                              height: 38,
                                              width: 1,
                                              color: Colors.white70,
                                            ),
                                            GestureDetector(
                                              onTap: () {
                                                widget.onCopy(_text);
                                                overlayEntry.remove();
                                  
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  SnackBar(
                                                    content: Text("Copied"),
                                                  ),
                                                );
                                                _clear();
                                              },
                                              child: Container(
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: 16,
                                                  vertical: 8,
                                                ),
                                                child: Text(
                                                  "Copy",
                                                  style: TextStyle(
                                                    color: Colors.grey.shade200,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            Container(
                                              height: 38,
                                              width: 1,
                                              color: Colors.white70,
                                            ),
                                            GestureDetector(
                                              onTap: () {
                                                widget.onSearch(_text);
                                                overlayEntry.remove();
                                                _clear();
                                              },
                                              child: Container(
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: 16,
                                                  vertical: 8,
                                                ),
                                                child: Text(
                                                  "Search",
                                                  style: TextStyle(
                                                    color: Colors.grey.shade200,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                      );
    
                      overlay.insert(overlayEntry);
                    }
                  });
                },
        child: widget.child,
      ),
    );
  }
}
