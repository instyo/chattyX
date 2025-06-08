import 'package:chatty/utils/models/base_message_model.dart';
import 'package:chatty/screens/chat/chat_controller.dart';
import 'package:chatty/utils/repository/chat_repository.dart';
import 'package:chatty/utils/service_locator.dart';
import 'package:chatty/screens/settings/app_settings_screen.dart';
import 'package:chatty/utils/context_extension.dart';
import 'package:chatty/widgets/common/touchable_opacity.dart';
import 'package:cupertino_sidebar/cupertino_sidebar.dart';
import 'package:cupertino_sidemenu/cupertino_sidemenu.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:haptic_feedback/haptic_feedback.dart';
import 'package:provider/provider.dart';
import 'package:rxdart/rxdart.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';

class SidebarMenu extends StatefulWidget {
  final CupertinoSidemenuController sideMenuController;

  const SidebarMenu({super.key, required this.sideMenuController});

  @override
  State<SidebarMenu> createState() => _SidebarMenuState();
}

class _SidebarMenuState extends State<SidebarMenu> {
  ChatController? controller;
  double sidebarWidth = 350.0;
  bool isDragged = false;
  bool _isEditing = false; // Track if in edit mode
  final Set<String> _selectedChats = {}; // Track selected chat IDs for deletion
  final PublishSubject<String> searchKeyword = PublishSubject();
  final ChatRepository chatRepository = sl<ChatRepository>();
  String _activeChat = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller = context.read<ChatController>();

      controller?.$isExpanded.listen((isExpanded) {
        if (isExpanded) {
          sidebarWidth = 350.0;
          isDragged = false;
        } else {
          sidebarWidth = 0.0;
          isDragged = false;
        }

        if (!mounted) return;
        setState(() {});
      });
    });
  }

  String getDateLabel(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0 &&
        now.day == date.day &&
        now.month == date.month &&
        now.year == date.year) {
      return 'Today';
    } else if (difference.inDays == 1 ||
        (difference.inDays == 0 && now.day - date.day == 1)) {
      // Handles cases where the date is yesterday
      return 'Yesterday';
    } else if (difference.inDays <= 7) {
      return 'Last 7 days';
    } else if (difference.inDays <= 30) {
      return 'Last 30 days';
    } else {
      return 'Over a month';
    }
  }

  void _deleteSelectedChats() async {
    final confirm = await showAdaptiveDialog<bool>(
      context: context,
      builder:
          (context) => CupertinoAlertDialog(
            title: Text('Confirm Deletion'),
            content: Text('Are you sure you want to delete these items?'),
            actions: [
              CupertinoButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
              CupertinoButton(
                onPressed: () async {
                  Navigator.of(context).pop(true);
                  await chatRepository.deleteChat(_selectedChats.toList());
                },
                child: Text('Delete'),
              ),
            ],
          ),
    );

    if (confirm == true) {
      // Call your repository or controller to delete chats by IDs
      // Example: sl<ChatRepository>().deleteChatsByIds(chatIdsToDelete);

      // After deletion, clear selection and exit edit mode
      setState(() {
        _selectedChats.clear();
        _isEditing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        AnimatedContainer(
          duration:
              isDragged
                  ? Duration.zero
                  : const Duration(milliseconds: 300), // Animation duration
          curve: Curves.bounceInOut, // Animation curve
          width: sidebarWidth, // Use sidebarWidth for the width
          child: CupertinoSidebar(
            isVibrant: false,
            selectedIndex: null,
            border: Border(),
            onDestinationSelected: (value) {},
            padding: EdgeInsets.symmetric(horizontal: 12),
            // navigationBar: SidebarNavigationBar(title: Text("ChattyX")),
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () {
                      widget.sideMenuController.closeMenu();
                      WoltModalSheet.show<void>(
                        context: context,
                        modalTypeBuilder: (context) {
                          if (context.isMobile) {
                            return WoltModalType.bottomSheet();
                          } else {
                            return WoltModalType.dialog();
                          }
                        },
                        pageListBuilder: (modalSheetContext) {
                          return [
                            WoltModalSheetPage(
                              isTopBarLayerAlwaysVisible: false,
                              hasTopBarLayer: false,
                              child: AppSettingsScreen(),
                            ),
                          ];
                        },
                        onModalDismissedWithBarrierTap: () {
                          debugPrint('Closed modal sheet with barrier tap');
                          Navigator.of(context).pop();
                        },
                      );
                    },
                    icon: Icon(CupertinoIcons.gear),
                  ),
                  Spacer(),
                  IconButton(
                    onPressed: () {
                      controller?.starNewSession(null);
                      _activeChat = '';
                      widget.sideMenuController.closeMenu();
                      setState(() {});
                    },
                    icon: Icon(CupertinoIcons.square_pencil),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.maxFinite,
                child: CupertinoSearchTextField(
                  placeholder: 'Search conversation',
                  // placeholderStyle: TextStyle(
                  //   color: context.isDark ? Colors.grey.shade200 : Colors.black,
                  // ),
                  style: TextStyle(
                    color: context.isDark ? Colors.grey.shade200 : Colors.black,
                  ),
                  onChanged: (String value) {
                    searchKeyword.add(value);
                  },
                  onSubmitted: (String value) {
                    searchKeyword.add(value);
                  },
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text(
                    "Recents :",
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  Spacer(),
                  // Change the button text based on _isEditing
                  TextButton(
                    onPressed: () async {
                      if (_isEditing) {
                        // Cancel editing
                        _isEditing = false;
                        _selectedChats.clear();
                      } else {
                        // Enter edit mode
                        _isEditing = true;
                      }
                      setState(() {});

                      await Haptics.vibrate(HapticsType.medium);
                    },
                    child: Text(_isEditing ? 'Cancel' : 'Edit'),
                  ),
                  // Show delete button if in edit mode and items are selected
                  if (_isEditing && _selectedChats.isNotEmpty)
                    TextButton(
                      onPressed: () async {
                        // Perform delete
                        _deleteSelectedChats();
                      },
                      child: Text('Delete'),
                    ),
                ],
              ),
              StreamBuilder(
                stream: searchKeyword,
                initialData: '',
                builder: (context, snapshot) {
                  return StreamBuilder(
                    stream: sl<ChatRepository>().getAllChats$(
                      snapshot.data ?? '',
                    ),
                    builder: (context, snapshot) {
                      final chats = (snapshot.data ?? []);

                      if (chats.isEmpty) {
                        return Padding(
                          padding: EdgeInsets.all(18),
                          child: const Text("No data"),
                        );
                      }

                      // Group chats by createdAt date
                      Map<String, List<BaseMessageModel>> groupedChats = {};
                      for (var chat in chats) {
                        final date =
                            chat.createdAt.toLocal().toString().split(
                              ' ',
                            )[0]; // Format date
                        if (!groupedChats.containsKey(date)) {
                          groupedChats[date] = [];
                        }
                        groupedChats[date]!.add(chat);
                      }

                      // Sort dates in descending order
                      final sortedDates =
                          groupedChats.keys.toList()..sort(
                            (a, b) =>
                                DateTime.parse(b).compareTo(DateTime.parse(a)),
                          );

                      return ListView.builder(
                        itemCount: sortedDates.length,
                        shrinkWrap: true,
                        padding: EdgeInsets.zero,
                        physics: NeverScrollableScrollPhysics(),
                        itemBuilder: (context, index) {
                          final date = sortedDates[index];
                          final chatList = groupedChats[date]!.reversed;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                child: Text(
                                  getDateLabel(DateTime.parse(date)),
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              ...chatList.map((chat) {
                                final isSelected = _selectedChats.contains(
                                  chat.id,
                                );
                                return TouchableOpacity(
                                  onTap: () async {
                                    if (_isEditing) {
                                      if (isSelected) {
                                        _selectedChats.remove(chat.id);
                                      } else {
                                        _selectedChats.add(chat.id);
                                      }

                                      setState(() {});

                                      await Haptics.vibrate(HapticsType.medium);
                                    } else {
                                      _activeChat = chat.id;
                                      setState(() {});
                                      controller?.starNewSession(chat);
                                      widget.sideMenuController.closeMenu();
                                    }
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 8,
                                    ),
                                    child: Row(
                                      children: [
                                        // Show checkmark if in edit mode
                                        if (_isEditing)
                                          Icon(
                                            isSelected
                                                ? Icons.check_box
                                                : Icons.check_box_outline_blank,
                                            size: 20,
                                          ),
                                        if (_isEditing) SizedBox(width: 8),
                                        Expanded(
                                          child: Builder(
                                            builder: (context) {
                                              final isActive =
                                                  _activeChat == chat.id;
                                              return Text(
                                                chat.title,
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  decoration:
                                                      !isActive
                                                          ? null
                                                          : TextDecoration
                                                              .underline,
                                                  fontWeight:
                                                      !isActive
                                                          ? null
                                                          : FontWeight.bold,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              );
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }),
                            ],
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),

        Positioned(
          right: 0,
          top: 0,
          bottom: 0,
          child: Stack(
            children: [
              GestureDetector(
                onHorizontalDragUpdate: (details) {
                  if (!mounted) return;
                  setState(() {
                    sidebarWidth += details.delta.dx;
                    if (sidebarWidth < 50) sidebarWidth = 50; // Minimum width
                    if (sidebarWidth > 350) sidebarWidth = 350; // Maximum width
                  });
                },
                onHorizontalDragEnd: (_) {
                  if (!mounted) return;
                  setState(() {
                    isDragged = false;
                  });
                },
                onHorizontalDragStart: (_) {
                  if (!mounted) return;
                  setState(() {
                    isDragged = true;
                  });
                },
                child: MouseRegion(
                  cursor:
                      SystemMouseCursors.resizeLeftRight, // Change cursor here
                  child: Container(
                    width: 2, // Width of the draggable area
                    color:
                        context.isDark
                            ? Colors.grey.shade800
                            : Colors.grey.shade200,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
