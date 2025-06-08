part of '../message_input.dart';

enum UploadImageType {
  gallery('Select image', CupertinoIcons.photo),
  camera('Take a picture', CupertinoIcons.camera);

  final String title;
  final IconData icon;

  const UploadImageType(this.title, this.icon);
}

class _InputActions extends StatelessWidget {
  const _InputActions();

  @override
  Widget build(BuildContext context) {
    final controller = context.read<MessageInputController>();

    return StreamBuilder<(bool, bool)>(
      stream: controller.textFieldState$,
      initialData: (false, false),
      builder: (context, snapshot) {
        return Row(
          children: [
            // Image picker button
            _buildUploadImage(controller),
            // Hint text button, show only if unFocused
            if (snapshot.data?.$2 == false) _buildHintText(controller),
          ],
        );
      },
    );
  }

  CustomPopupMenu _buildUploadImage(MessageInputController controller) {
    return CustomPopupMenu(
      controller: controller.popupMenuController,
      menuBuilder: () {
        return ClipRRect(
          borderRadius: BorderRadius.circular(5),
          child: Container(
            color: const Color(0xFF4C4C4C),
            child: IntrinsicWidth(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children:
                    UploadImageType.values
                        .map(
                          (item) => TouchableOpacity(
                            onTap: () {
                              controller.popupMenuController.hideMenu();

                              if (item == UploadImageType.camera) {
                                controller.pickImages(ImageSource.camera);
                              }

                              if (item == UploadImageType.gallery) {
                                controller.pickImages(ImageSource.gallery);
                              }
                            },
                            child: Container(
                              height: 40,
                              padding: EdgeInsets.symmetric(horizontal: 20),
                              child: Row(
                                children: <Widget>[
                                  Icon(
                                    item.icon,
                                    size: 15,
                                    color: Colors.white,
                                  ),
                                  Expanded(
                                    child: Container(
                                      margin: EdgeInsets.only(left: 10),
                                      child: Text(
                                        item.title,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                        .toList(),
              ),
            ),
          ),
        );
      },
      barrierColor: Colors.transparent,
      pressType: PressType.singleClick,
      child: Container(
        margin: EdgeInsets.only(right: 8),
        child: Icon(CupertinoIcons.add_circled),
      ),
    );
  }

  TouchableOpacity _buildIconButton(
    BuildContext context, {
    required IconData icon,
    required Function() onTap,
    bool isSelected = false,
  }) {
    return TouchableOpacity(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(right: 8),
        child: Icon(
          icon,
          color: !isSelected ? null : Theme.of(context).primaryColor,
        ),
      ),
    );
  }

  MouseRegion _buildHintText(MessageInputController controller) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () async {
          controller.toggleFocus();
          await Future.delayed(Duration(milliseconds: 250));
          controller.focusNode.requestFocus();
        },
        child: Container(
          padding: EdgeInsets.all(8),
          child: Text("What's on your mind?"),
        ),
      ),
    );
  }
}
