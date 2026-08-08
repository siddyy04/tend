import 'package:flutter/material.dart';

/// Natural-language-shaped search field with clear action.
class SearchQueryField extends StatelessWidget {
  const SearchQueryField({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.onClear,
    this.hintText = 'Ask about a memory…',
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final String hintText;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Search memories',
      textField: true,
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        autocorrect: true,
        decoration: InputDecoration(
          hintText: hintText,
          prefixIcon: const Icon(Icons.search),
          suffixIcon: ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (context, value, _) {
              if (value.text.isEmpty) return const SizedBox.shrink();
              return IconButton(
                tooltip: 'Clear search',
                icon: const Icon(Icons.clear),
                onPressed: onClear,
              );
            },
          ),
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}
