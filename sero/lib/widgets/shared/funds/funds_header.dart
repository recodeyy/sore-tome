import 'package:flutter/material.dart';
import '../branding_header.dart';
import '../hero_header.dart';

class FundsHeader extends StatelessWidget {
  final String title;
  final VoidCallback onRefresh;
  
  const FundsHeader({
    super.key, 
    this.title = 'Society Funds',
    required this.onRefresh
  });

  @override
  Widget build(BuildContext context) {
    return SliverList(
      delegate: SliverChildListDelegate([
        const BrandingHeader(),
        HeroHeader(
          title: title,
          label: 'FINANCIAL OPS',
          description: 'Sero AI tracks every transaction in real-time. Maintenance dues and disbursements are verified by smart-contracts.',
          onRefresh: onRefresh,
        ),
        const SizedBox(height: 24),
      ]),
    );
  }
}




