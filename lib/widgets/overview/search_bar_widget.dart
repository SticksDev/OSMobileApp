import 'package:flutter/material.dart';

class SearchBarWidget extends StatelessWidget {
  final TextEditingController controller;
  final String searchQuery;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const SearchBarWidget({
    super.key,
    required this.controller,
    required this.searchQuery,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
      ),
      child: TextField(
        controller: controller,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Search shockers...',
          hintStyle: const TextStyle(color: Colors.white30),
          prefixIcon: const Icon(Icons.search, color: Colors.white70),
          suffixIcon: searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.white70),
                  onPressed: onClear,
                )
              : null,
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.05),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.white, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
        onChanged: onChanged,
      ),
    );
  }
}
