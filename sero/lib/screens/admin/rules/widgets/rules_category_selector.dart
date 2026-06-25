import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sero/app/theme.dart';

class GovernanceCategorySelector extends StatelessWidget {
  final String selectedCategory;
  final Function(String) onCategorySelected;
  final List<String> categories;

  const GovernanceCategorySelector({
    super.key,
    required this.selectedCategory,
    required this.onCategorySelected,
    required this.categories,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CATEGORIES',
            style: GoogleFonts.outfit(
              color: const Color(0xFF94A3B8),
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: categories.map((cat) {
                final isSelected = selectedCategory == cat;
                return GestureDetector(
                  onTap: () => onCategorySelected(cat),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? kPrimaryGreen
                          : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: isSelected 
                            ? kPrimaryGreen 
                            : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Text(
                      cat,
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: isSelected ? Colors.white : const Color(0xFF64748B),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}







