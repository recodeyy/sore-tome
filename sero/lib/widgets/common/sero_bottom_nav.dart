import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Bottom navigation bar matching the reference design with
/// Dashboard, Members, Finance, Complaints, More tabs.
/// Also supports a centered floating FAB.
class SeroBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const SeroBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  static const _items = [
    _NavItem(Icons.home_outlined, Icons.home_rounded, 'Dashboard'),
    _NavItem(Icons.people_outline, Icons.people_rounded, 'Members'),
    _NavItem(null, null, 'Finance'), // placeholder for FAB
    _NavItem(Icons.chat_bubble_outline, Icons.chat_bubble_rounded, 'Complaints'),
    _NavItem(Icons.more_horiz, Icons.more_horiz, 'More'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: Color(0xFFF1F5F9), width: 1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom,
      ),
      child: SizedBox(
        height: 56,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(_items.length, (i) {
            final isSelected = currentIndex == i;
            final item = _items[i];

            if (i == 2) {
              // Center FAB (Finance / G Logo)
              return GestureDetector(
                onTap: () => onTap(2),
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF064E3B) : const Color(0xFF10B981),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: (isSelected ? const Color(0xFF064E3B) : const Color(0xFF10B981)).withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      'G',
                      style: GoogleFonts.outfit(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              );
            }

            return GestureDetector(
              onTap: () => onTap(i),
              behavior: HitTestBehavior.opaque,
              child: SizedBox(
                width: 64,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isSelected ? item.activeIcon : item.icon,
                      color: isSelected
                          ? const Color(0xFF064E3B)
                          : const Color(0xFF94A3B8),
                      size: 22,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.label,
                      style: GoogleFonts.outfit(
                        fontSize: 10,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        color: isSelected
                            ? const Color(0xFF064E3B)
                            : const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData? icon;
  final IconData? activeIcon;
  final String label;

  const _NavItem(this.icon, this.activeIcon, this.label);
}
