import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sero/app/theme.dart';

class SuperAdminBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const SuperAdminBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  static const _items = [
    _Item(Icons.dashboard_outlined, Icons.dashboard_rounded, 'Platform'),
    _Item(Icons.business_outlined, Icons.business_rounded, 'Societies'),
    _Item(null, null, 'Revenue'),
    _Item(Icons.support_agent_outlined, Icons.support_agent_rounded, 'Support'),
    _Item(Icons.more_horiz, Icons.more_horiz, 'More'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: Color(0xFFF1F5F9))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SizedBox(
        height: 56,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(_items.length, (index) {
            final item = _items[index];
            final selected = currentIndex == index;
            if (index == 2) {
              return GestureDetector(
                onTap: () => onTap(index),
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: selected ? kSuperGreenDark : kSuperGreen,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: (selected ? kSuperGreenDark : kSuperGreen)
                            .withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'G',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              );
            }
            return GestureDetector(
              onTap: () => onTap(index),
              behavior: HitTestBehavior.opaque,
              child: SizedBox(
                width: 68,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      selected ? item.activeIcon : item.icon,
                      color: selected ? kSuperGreen : const Color(0xFF94A3B8),
                      size: 22,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        color:
                            selected ? kSuperGreen : const Color(0xFF94A3B8),
                        fontSize: 10,
                        fontWeight:
                            selected ? FontWeight.w700 : FontWeight.w500,
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

class _Item {
  final IconData? icon;
  final IconData? activeIcon;
  final String label;

  const _Item(this.icon, this.activeIcon, this.label);
}
