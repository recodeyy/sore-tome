import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sero/app/theme.dart';
import 'package:sero/models/super_admin/super_admin_models.dart';
import 'package:sero/providers/super_admin/super_admin_provider.dart';
import 'package:sero/widgets/super_admin/super_admin_widgets.dart';

class SuperAdminPlansScreen extends ConsumerWidget {
  const SuperAdminPlansScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plansAsync = ref.watch(superAdminPlansProvider);

    return Scaffold(
      backgroundColor: kSlateBg,
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          SuperAdminHeader(
            title: 'Subscription Plans',
            subtitle: 'Manage pricing tiers & limits',
            leadingIcon: Icons.arrow_back_rounded,
            onMenu: () => Navigator.maybePop(context),
            onNotifications: () =>
                Navigator.pushNamed(context, '/notifications'),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
            child: SuperAdminSectionCard(
              title: 'Pricing Tiers',
              actionText: '+ Add',
              onAction: () => _openCreatePlanSheet(context, ref),
              child: SuperAdminAsyncView<List<JsonMap>>(
                loading: plansAsync.isLoading,
                error: plansAsync.hasError ? plansAsync.error : null,
                data: plansAsync.asData?.value,
                onRetry: () => ref.invalidate(superAdminPlansProvider),
                builder: (plans) {
                  if (plans.isEmpty) {
                    return const SuperAdminEmptyState(
                      icon: Icons.view_carousel_outlined,
                      title: 'No plans yet',
                      message:
                          'Create your first subscription plan to get started.',
                    );
                  }
                  return Column(
                    children: [
                      for (final plan in plans) _PlanCard(plan: plan),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openCreatePlanSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
        ),
        child: const _CreatePlanForm(),
      ),
    );
  }
}

class _CreatePlanForm extends ConsumerStatefulWidget {
  const _CreatePlanForm();

  @override
  ConsumerState<_CreatePlanForm> createState() => _CreatePlanFormState();
}

class _CreatePlanFormState extends ConsumerState<_CreatePlanForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  final _priceController = TextEditingController();
  String _interval = 'month';
  bool _submitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final rupees = double.parse(_priceController.text.trim());
    setState(() => _submitting = true);
    try {
      await ref.read(superAdminServiceProvider).createPlan({
        'name': _nameController.text.trim(),
        'code': _codeController.text.trim(),
        'price_minor': (rupees * 100).round(),
        'interval': _interval,
      });
      ref.invalidate(superAdminPlansProvider);
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: kSuperGreen,
          content: Text('Plan created'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFFEF4444),
          content: Text('Failed to create plan: $e'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: kSlateBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'New Plan',
                style: GoogleFonts.outfit(
                  color: const Color(0xFF1E293B),
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 16),
              _FormField(
                controller: _nameController,
                label: 'Name',
                hint: 'e.g. Premium',
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              _FormField(
                controller: _codeController,
                label: 'Code',
                hint: 'e.g. premium',
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              _FormField(
                controller: _priceController,
                label: 'Price (₹)',
                hint: 'e.g. 499',
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (v) {
                  final value = double.tryParse((v ?? '').trim());
                  if (value == null) return 'Enter a valid amount';
                  if (value < 0) return 'Must be 0 or more';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              Text(
                'Interval',
                style: GoogleFonts.outfit(
                  color: const Color(0xFF475569),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: _interval,
                decoration: _inputDecoration(null),
                items: const [
                  DropdownMenuItem(value: 'month', child: Text('Monthly')),
                  DropdownMenuItem(value: 'year', child: Text('Yearly')),
                ],
                onChanged: _submitting
                    ? null
                    : (value) {
                        if (value != null) {
                          setState(() => _interval = value);
                        }
                      },
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kSuperGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _submitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Create Plan',
                          style: GoogleFonts.outfit(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

InputDecoration _inputDecoration(String? hint) {
  OutlineInputBorder border(Color color) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: color),
      );
  return InputDecoration(
    hintText: hint,
    hintStyle: GoogleFonts.outfit(
      color: const Color(0xFF94A3B8),
      fontSize: 14,
    ),
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    enabledBorder: border(kSlateBorder),
    focusedBorder: border(kSuperGreen),
    border: border(kSlateBorder),
  );
}

class _FormField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const _FormField({
    required this.controller,
    required this.label,
    this.hint,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            color: const Color(0xFF475569),
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          style: GoogleFonts.outfit(
            color: const Color(0xFF1E293B),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          decoration: _inputDecoration(hint),
        ),
      ],
    );
  }
}

class _PlanCard extends StatelessWidget {
  final JsonMap plan;

  const _PlanCard({required this.plan});

  @override
  Widget build(BuildContext context) {
    final name = (plan['name'] ?? 'Untitled plan').toString();
    final code = (plan['code'] ?? '').toString();
    final priceMinor = plan['price_minor'];
    final num priceMinorNum =
        priceMinor is num ? priceMinor : num.tryParse('$priceMinor') ?? 0;
    final rupees = priceMinorNum / 100;
    final interval = (plan['interval'] ?? 'month').toString();
    final isActive = plan['active'] is bool ? plan['active'] as bool : true;
    final features = plan['features'];
    final featureList = features is List
        ? features.map((e) => e.toString()).toList()
        : <String>[];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kSlateBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF1E293B),
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _StatusPill(active: isActive),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '₹ ${rupees.toStringAsFixed(rupees == rupees.roundToDouble() ? 0 : 2)} / $interval',
            style: GoogleFonts.outfit(
              color: kSuperGreen,
              fontSize: 20,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          if (code.isNotEmpty) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: kSuperGreenSoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  code.toUpperCase(),
                  style: GoogleFonts.outfit(
                    color: kSuperGreenDark,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ],
          if (featureList.isNotEmpty) ...[
            const SizedBox(height: 14),
            for (final feature in featureList.take(4))
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.check_circle_rounded,
                        color: kAccentGreen, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        feature,
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF475569),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final bool active;

  const _StatusPill({required this.active});

  @override
  Widget build(BuildContext context) {
    final color = active ? kAccentGreen : const Color(0xFF94A3B8);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            active ? 'Active' : 'Inactive',
            style: GoogleFonts.outfit(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
