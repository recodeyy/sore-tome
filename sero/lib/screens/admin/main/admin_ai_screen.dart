import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sero/app/theme.dart';
import 'package:sero/services/api_service.dart';
import '../../shared/ai_chat/ai_chat_screen.dart';
import 'package:sero/services/auth_service.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'widgets/ai_job_card.dart';
import 'widgets/knowledge_base_policy_banner.dart';

class AdminAIScreen extends StatefulWidget {
  const AdminAIScreen({super.key});

  @override
  State<AdminAIScreen> createState() => _AdminAIScreenState();
}

class _AdminAIScreenState extends State<AdminAIScreen> {
  bool _isUploading = false;
  String? _societyId;

  @override
  void initState() {
    super.initState();
    _loadSocietyId();
  }

  Future<void> _loadSocietyId() async {
    final user = await AuthService.getSavedUser();
    if (mounted) {
      setState(() {
        _societyId = user?['society_id'] ?? 'default_society';
      });
    }
  }

  Future<void> _pickAndUpload() async {
    if (_societyId == null) return;
    FilePickerResult? result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'png'],
    );

    if (result != null) {
      if (!mounted) return;
      final docType = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(
            'Document Type',
            style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _docTypeTile(context, 'rules', 'Society Rules & Bylaws', Icons.gavel),
              _docTypeTile(context, 'notice', 'Official Notice', Icons.campaign),
              _docTypeTile(context, 'policy', 'Operational Policy', Icons.policy),
              _docTypeTile(context, 'general', 'General Document', Icons.description),
            ],
          ),
        ),
      );

      if (docType == null) return;

      setState(() => _isUploading = true);

      final fileName = result.files.single.name;

      try {
        final response = await ApiService.post('/ai/upload-document', {
          'fileUrl': 'https://firebasestorage.googleapis.com/v0/b/sero/o/$fileName',
          'fileName': fileName,
          'fileType': result.files.single.extension,
          'documentType': docType,
          'society_id': _societyId,
        });

        if (!mounted) return;

        setState(() => _isUploading = false);

        if (response.statusCode == 202) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Upload successful. Tracking ingestion in real-time.')),
          );
        }
      } catch (e) {
        if (!mounted) return;
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
      }
    }
  }

  Widget _docTypeTile(BuildContext context, String type, String label, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: kPrimaryGreen),
      title: Text(label, style: GoogleFonts.outfit(fontSize: 14)),
      onTap: () => Navigator.pop(context, type),
    );
  }

  void _exportAuditLogs() async {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Preparing Audit Log CSV stream...')),
    );

    try {
      final url = '${ApiService.baseUrl}/ai/audit/export';
      final headers = await AuthService.authHeaders();

      final response = await http.get(Uri.parse(url), headers: headers);

      if (response.statusCode == 200) {
        final directory = await getApplicationDocumentsDirectory();
        final file = File('${directory.path}/ai_audit_${DateTime.now().millisecondsSinceEpoch}.csv');
        await file.writeAsBytes(response.bodyBytes);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Audit Logs Downloaded: ${file.path.split('/').last}')),
        );
      } else {
        throw 'Server error: ${response.statusCode}';
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'AI Intelligence Admin',
          style: GoogleFonts.outfit(color: Colors.black, fontWeight: FontWeight.w700),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            onPressed: _exportAuditLogs,
            icon: const Icon(Icons.file_download_outlined, color: kPrimaryGreen),
            tooltip: 'Export Audit Logs (CSV)',
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(child: KnowledgeBasePolicyBanner()),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: InkWell(
                onTap: _isUploading ? null : _pickAndUpload,
                child: Container(
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.grey.shade300, width: 2),
                  ),
                  child: Center(
                    child: RepaintBoundary(
                      child: _isUploading
                          ? const CircularProgressIndicator(color: kPrimaryGreen)
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.cloud_upload_outlined, color: kPrimaryGreen, size: 32),
                                const SizedBox(height: 8),
                                Text(
                                  'Upload Society Bylaws, Rules, or Notices',
                                  style: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: const Color(0xFF334155)),
                                ),
                                Text(
                                  'PDF, JPG, PNG up to 10MB',
                                  style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
              child: Row(
                children: [
                  Text(
                    'INGESTION QUEUE',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF64748B),
                      letterSpacing: 1.2,
                    ),
                  ),
                  const Spacer(),
                  const Icon(Icons.sync, color: Colors.grey, size: 16),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: _societyId == null
                ? const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator()))
                : RepaintBoundary(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('ai_jobs')
                          .where('society_id', isEqualTo: _societyId)
                          .orderBy('updated_at', descending: true)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) return SliverToBoxAdapter(child: Text('Error: ${snapshot.error}'));
                        if (!snapshot.hasData) return const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator()));
  
                        final jobs = snapshot.data!.docs;
                        if (jobs.isEmpty) {
                          return SliverToBoxAdapter(
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.all(40),
                                child: Text('No ingestion tasks yet.', style: GoogleFonts.outfit(color: Colors.grey)),
                              ),
                            ),
                          );
                        }
  
                        return SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) => AiJobCard(job: jobs[index].data() as Map<String, dynamic>),
                            childCount: jobs.length,
                          ),
                        );
                      },
                    ),
                  ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      floatingActionButtonLocation: kPillNavbarFabLocation,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AiChatScreen(
                initialMessage: 'Check doc indexing progress and suggest notices',
                initialContext: {'screen': 'admin_ai'},
                userRole: 'admin',
              ),
            ),
          );
        },
        backgroundColor: kPrimaryGreen,
        child: const Icon(Icons.auto_awesome, color: Colors.white),
      ),
    );
  }
}









