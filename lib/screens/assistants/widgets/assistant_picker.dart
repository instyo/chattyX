import 'package:chatty/screens/assistants/assistants_setting.dart';
import 'package:chatty/utils/context_extension.dart';
import 'package:chatty/utils/models/ai_assistant.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rxdart/rxdart.dart';

class AIAssistantPicker extends StatelessWidget {
  const AIAssistantPicker({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.read<AssistantsController>();

    return StreamBuilder<(AiAssistant?, List<AiAssistant>)>(
      initialData: (null, []),
      stream: Rx.combineLatest2(
        controller.selected$,
        controller.list$,
        (selectedAssistant, listAssistant) => (
          selectedAssistant,
          listAssistant,
        ),
      ),
      builder: (context, snapshot) {
        final (selectedModel, listAssistants) = snapshot.data!;
        print(">> Selected model : ${selectedModel}");

        if (selectedModel == null && listAssistants.isEmpty) {
          return const Text("Please add assistant to continue");
        }

        return Container(
          constraints: BoxConstraints(maxWidth: 180, minWidth: 100),
          width: context.isMobile ? MediaQuery.of(context).size.width / 3 : 180,
          height: 40,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8), // Added circular border
            border: Border.all(
              color: Colors.grey,
            ), // Optional: add border color
          ),
          child: DropdownButton<String>(
            value: selectedModel?.id,
            padding: EdgeInsets.symmetric(horizontal: 8),
            elevation: 0,
            hint: Text(
              'Choose Assistant',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            isExpanded: true,
            underline: Container(height: 2, color: Colors.transparent),
            items:
                listAssistants.map((assistant) {
                  return DropdownMenuItem<String>(
                    value: assistant.id,
                    child: Text(
                      assistant.name,
                      maxLines: 1,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  );
                }).toList(),
            onChanged: (String? newValue) {
              final selectedAssistant = listAssistants.firstWhere(
                (assistant) => assistant.id == newValue,
              );
              controller.edit(selectedAssistant);
            },
          ),
        );
      },
    );
  }
}
