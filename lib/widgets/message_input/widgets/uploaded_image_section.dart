part of '../message_input.dart';

class _UploadedImageSection extends StatelessWidget {
  const _UploadedImageSection();

  @override
  Widget build(BuildContext context) {
    final controller = context.read<MessageInputController>();
    return StreamBuilder(
      stream: controller.images$,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox();
        }

        final images = snapshot.data ?? [];

        if (images.isEmpty) {
          return const SizedBox();
        }

        double imageSize;
        if (context.isMobile) {
          imageSize = context.screenWidth / 6; // Mobile size
        } else if (context.isTablet) {
          imageSize = context.screenWidth / 8; // Tablet size
        } else {
          imageSize = context.screenWidth / 12; // Desktop size
        }

        return SizedBox(
          height: imageSize + 10,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            shrinkWrap: true,
            itemCount: images.length,
            itemBuilder: (context, index) {
              final String image = images[index];
              return Container(
                margin: EdgeInsets.only(right: 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    margin: EdgeInsets.only(bottom: 8),
                    width: imageSize,
                    height: imageSize,
                    child: Stack(
                      children: [
                        CachedBase64Image(base64: image, maxSize: imageSize),
                        Align(
                          alignment: Alignment.topRight,
                          child: TouchableOpacity(
                            onTap: () {
                              controller.clearImage(at: index);
                              if (controller.textController.text.isEmpty) {
                                controller.toggleFocus();
                              }
                            },
                            child: Padding(
                              padding: EdgeInsets.all(4),
                              child: Icon(
                                CupertinoIcons.minus_circle_fill,
                                color: Colors.red,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
