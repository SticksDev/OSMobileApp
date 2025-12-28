import 'package:flutter/material.dart';

enum ShockerFilter { all, own, shared, active, paused }

class FilterBarWidget extends StatelessWidget {
  final Set<ShockerFilter> activeFilters;
  final ValueChanged<ShockerFilter> onToggleFilter;

  const FilterBarWidget({
    super.key,
    required this.activeFilters,
    required this.onToggleFilter,
  });

  String _getFilterLabel(ShockerFilter filter) {
    switch (filter) {
      case ShockerFilter.all:
        return 'All';
      case ShockerFilter.own:
        return 'Own';
      case ShockerFilter.shared:
        return 'Shared';
      case ShockerFilter.active:
        return 'Active';
      case ShockerFilter.paused:
        return 'Paused';
    }
  }

  IconData _getFilterIcon(ShockerFilter filter) {
    switch (filter) {
      case ShockerFilter.all:
        return Icons.apps;
      case ShockerFilter.own:
        return Icons.bolt;
      case ShockerFilter.shared:
        return Icons.share;
      case ShockerFilter.active:
        return Icons.check_circle;
      case ShockerFilter.paused:
        return Icons.pause_circle;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: ShockerFilter.values.map((filter) {
            final isActive = activeFilters.contains(filter);
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                selected: isActive,
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getFilterIcon(filter),
                      size: 16,
                      color: isActive ? Colors.black : Colors.white70,
                    ),
                    const SizedBox(width: 6),
                    Text(_getFilterLabel(filter)),
                  ],
                ),
                onSelected: (_) => onToggleFilter(filter),
                selectedColor: Colors.white,
                backgroundColor: Colors.white.withValues(alpha: 0.05),
                checkmarkColor: Colors.black,
                labelStyle: TextStyle(
                  color: isActive ? Colors.black : Colors.white70,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                ),
                side: BorderSide(
                  color: isActive
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.2),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
