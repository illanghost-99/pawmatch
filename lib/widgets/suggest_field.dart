import 'package:flutter/material.dart';
import '../data/suggestions.dart';

class SuggestField extends StatelessWidget {
  const SuggestField({
    super.key,
    required this.controller,
    required this.label,
    required this.options,
    this.hint,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final List<String> options;

  @override
  Widget build(BuildContext context) {
    return Autocomplete<String>(
      initialValue: TextEditingValue(text: controller.text),
      optionsBuilder: (v) => suggest(v.text, options),
      onSelected: (v) => controller.text = v,
      optionsMaxHeight: 220,
      fieldViewBuilder: (context, textController, focus, onSubmit) {
        return TextField(
          controller: textController,
          focusNode: focus,
          keyboardType: TextInputType.text,
          textCapitalization: TextCapitalization.words,
          onChanged: (v) => controller.text = v,
          decoration: InputDecoration(
            labelText: label,
            hintText: hint,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          ),
        );
      },
    );
  }
}
