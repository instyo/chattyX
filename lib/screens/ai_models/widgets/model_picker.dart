import 'package:chatty/screens/ai_models/models_screen.dart';
import 'package:chatty/utils/context_extension.dart';
import 'package:chatty/utils/models/ai_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rxdart/rxdart.dart';

class ModelPicker extends StatelessWidget {
  const ModelPicker({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.read<ModelsController>();

    // I didn't know why using CombineLatest2 not working.

    return StreamBuilder<(AIModel?, List<AIModel>)>(
      initialData: (null, []),
      stream: Rx.combineLatest2(
        controller.selected$,
        controller.list$,
        (selectedModel, listModel) => (selectedModel, listModel),
      ), // Ensure distinct values to avoid null prints
      builder: (context, snapshot) {
        final (selectedModel, listModel) = snapshot.data!;

        if (selectedModel == null && listModel.isEmpty) {
          return const Text("Please add model to continue");
        }

        if (listModel.isEmpty) {
          return const SizedBox();
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
            value: selectedModel?.id, // Use the id of the selected model
            padding: EdgeInsets.symmetric(horizontal: 8),
            elevation: 0,
            hint: Text(
              'Choose Model',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            isExpanded: true,
            underline: Container(height: 2, color: Colors.transparent),
            items:
                listModel.map((model) {
                  return DropdownMenuItem<String>(
                    value: model.id, // Use the id of the model
                    child: Text(
                      model.name,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ), // Assuming AIModel has a 'name' property
                  );
                }).toList(),
            onChanged: (String? newValue) {
              final selectedModel = listModel.firstWhere(
                (model) => model.id == newValue,
              );
              controller.edit(selectedModel);
            },
          ),
        );
      },
    );
  }
}
