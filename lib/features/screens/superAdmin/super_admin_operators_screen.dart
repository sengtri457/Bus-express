import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../supabase_config.dart';

class SuperAdminOperatorsScreen extends StatefulWidget {
  const SuperAdminOperatorsScreen({super.key});

  @override
  State<SuperAdminOperatorsScreen> createState() =>
      _SuperAdminOperatorsScreenState();
}

class _SuperAdminOperatorsScreenState extends State<SuperAdminOperatorsScreen> {
  List<Map<String, dynamic>> _operators = [];
  bool _isLoading = true;
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    _loadOperators();
  }

  Future<void> _loadOperators() async {
    setState(() => _isLoading = true);
    try {
      var query = SupabaseConfig.client
          .from('operators')
          .select('id, name, contact, status, created_at, logo_url');

      if (_filter != 'all') {
        query = query.eq('status', _filter);
      }

      final data = await query.order('created_at', ascending: false);

      // Load bus/route counts per operator
      final ops = List<Map<String, dynamic>>.from(data);
      final enriched = <Map<String, dynamic>>[];

      for (final op in ops) {
        final results = await Future.wait([
          SupabaseConfig.client
              .from('buses')
              .select('id')
              .eq('operator_id', op['id'])
              .eq('status', 'active'),
          SupabaseConfig.client
              .from('routes')
              .select('id')
              .eq('operator_id', op['id'])
              .eq('status', 'active'),
          SupabaseConfig.client
              .from('users')
              .select('id')
              .eq('operator_id', op['id'])
              .inFilter('role', ['driver', 'conductor']),
        ]);
        enriched.add({
          ...op,
          'buses_count': (results[0] as List).length,
          'routes_count': (results[1] as List).length,
          'staff_count': (results[2] as List).length,
        });
      }

      if (mounted) {
        setState(() {
          _operators = enriched;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleStatus(String id, String current) async {
    final newStatus = current == 'active' ? 'inactive' : 'active';
    final action = newStatus == 'active' ? 'Activate' : 'Suspend';
    final color = newStatus == 'active'
        ? const Color(0xFF059669)
        : const Color(0xFFEF4444);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          '$action Operator',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        content: Text(
          newStatus == 'inactive'
              ? 'Suspending this operator will prevent their buses from appearing in searches. Continue?'
              : 'This will reactivate the operator and their services. Continue?',
          style: const TextStyle(color: Color(0xFF6B7280)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFF6B7280)),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(action),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await SupabaseConfig.client
          .from('operators')
          .update({'status': newStatus})
          .eq('id', id);
      _loadOperators();
      _showSnack(
        newStatus == 'active' ? 'Operator activated ✅' : 'Operator suspended ⛔',
        isError: newStatus == 'inactive',
      );
    } catch (e) {
      _showSnack('Error: $e', isError: true);
    }
  }

  void _showAddOperatorForm() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _OperatorFormSheet(onSaved: _loadOperators),
    );
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError
            ? const Color(0xFFEF4444)
            : const Color(0xFF059669),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          // Filter bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                _FilterChip(
                  label: 'All',
                  isSelected: _filter == 'all',
                  onTap: () {
                    setState(() => _filter = 'all');
                    _loadOperators();
                  },
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Active',
                  isSelected: _filter == 'active',
                  color: const Color(0xFF059669),
                  onTap: () {
                    setState(() => _filter = 'active');
                    _loadOperators();
                  },
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Inactive',
                  isSelected: _filter == 'inactive',
                  color: const Color(0xFF9CA3AF),
                  onTap: () {
                    setState(() => _filter = 'inactive');
                    _loadOperators();
                  },
                ),
              ],
            ),
          ),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _loadOperators,
                    child: _operators.isEmpty
                        ? const Center(
                            child: Text(
                              'No operators found',
                              style: TextStyle(color: Color(0xFF9CA3AF)),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _operators.length,
                            itemBuilder: (context, i) {
                              final op = _operators[i];
                              return _OperatorCard(
                                operator: op,
                                onToggle: () =>
                                    _toggleStatus(op['id'], op['status']),
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_operators',
        onPressed: _showAddOperatorForm,
        backgroundColor: const Color(0xFF111827),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_business_rounded),
        label: const Text(
          'Add Operator',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

// ─── Operator Card ────────────────────────────────────────────────────────────

class _OperatorCard extends StatelessWidget {
  final Map<String, dynamic> operator;
  final VoidCallback onToggle;

  const _OperatorCard({required this.operator, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final isActive = operator['status'] == 'active';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isActive ? null : Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    _OperatorAvatar(
                      name: operator['name'] as String,
                      logoUrl: operator['logo_url'] as String?,
                      size: 48,
                      isActive: isActive,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            operator['name'] as String,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF111827),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.phone_outlined,
                                size: 12,
                                color: Color(0xFF9CA3AF),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                operator['contact'] as String? ?? '—',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF6B7280),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Status badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isActive
                            ? const Color(0xFFD1FAE5)
                            : const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: isActive
                                  ? const Color(0xFF059669)
                                  : const Color(0xFF9CA3AF),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            isActive ? 'Active' : 'Inactive',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isActive
                                  ? const Color(0xFF059669)
                                  : const Color(0xFF9CA3AF),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Stats row
                Row(
                  children: [
                    _MiniStat(
                      label: 'Buses',
                      value: '${operator['buses_count'] ?? 0}',
                      icon: Icons.directions_bus_rounded,
                    ),
                    const SizedBox(width: 16),
                    _MiniStat(
                      label: 'Routes',
                      value: '${operator['routes_count'] ?? 0}',
                      icon: Icons.route_rounded,
                    ),
                    const SizedBox(width: 16),
                    _MiniStat(
                      label: 'Staff',
                      value: '${operator['staff_count'] ?? 0}',
                      icon: Icons.people_rounded,
                    ),
                    const Spacer(),
                    Text(
                      _formatDate(operator['created_at'] as String? ?? ''),
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF9CA3AF),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF3F4F6)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                const Spacer(),
                TextButton.icon(
                  onPressed: onToggle,
                  icon: Icon(
                    isActive
                        ? Icons.pause_circle_outline_rounded
                        : Icons.play_circle_outline_rounded,
                    size: 16,
                  ),
                  label: Text(isActive ? 'Suspend' : 'Activate'),
                  style: TextButton.styleFrom(
                    foregroundColor: isActive
                        ? const Color(0xFFEF4444)
                        : const Color(0xFF059669),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String d) {
    if (d.isEmpty) return '';
    try {
      final dt = DateTime.parse(d);
      const m = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      return '${m[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return '';
    }
  }
}

// ─── Operator Avatar ──────────────────────────────────────────────────────────

class _OperatorAvatar extends StatelessWidget {
  final String name;
  final String? logoUrl;
  final double size;
  final bool isActive;

  const _OperatorAvatar({
    required this.name,
    required this.logoUrl,
    required this.size,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    final hasValidUrl =
        logoUrl != null && logoUrl!.startsWith('http');

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: hasValidUrl
            ? const Color(0xFFF0F7FF)
            : isActive
                ? const Color(0xFF111827)
                : const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(size * 0.3),
        image: hasValidUrl
            ? DecorationImage(
                image: NetworkImage(logoUrl!),
                fit: BoxFit.contain,
              )
            : null,
      ),
      child: hasValidUrl
          ? null
          : Center(
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : 'O',
                style: TextStyle(
                  fontSize: size * 0.42,
                  fontWeight: FontWeight.w700,
                  color: isActive
                      ? Colors.white
                      : const Color(0xFF9CA3AF),
                ),
              ),
            ),
    );
  }
}

// ─── Mini Stat ────────────────────────────────────────────────────────────────

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _MiniStat({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: const Color(0xFF9CA3AF)),
        const SizedBox(width: 4),
        Text(
          '$value $label',
          style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
        ),
      ],
    );
  }
}

// ─── Filter Chip ──────────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color? color;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? const Color(0xFF111827);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? c : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF6B7280),
          ),
        ),
      ),
    );
  }
}

// ─── Operator Form Sheet ──────────────────────────────────────────────────────

class _OperatorFormSheet extends StatefulWidget {
  final VoidCallback onSaved;
  const _OperatorFormSheet({required this.onSaved});

  @override
  State<_OperatorFormSheet> createState() => _OperatorFormSheetState();
}

class _OperatorFormSheetState extends State<_OperatorFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _contactCtrl = TextEditingController();
  bool _isLoading = false;
  Uint8List? _logoBytes;
  String? _logoFileName;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _contactCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickLogo() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    setState(() {
      _logoBytes = bytes;
      _logoFileName = file.name;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final inserted = await SupabaseConfig.client
          .from('operators')
          .insert({
            'name': _nameCtrl.text.trim(),
            'contact': _contactCtrl.text.trim(),
            'status': 'active',
          })
          .select('id')
          .single();

      final operatorId = inserted['id'] as String;

      if (_logoBytes != null && _logoFileName != null) {
        final ext = _logoFileName!.contains('.')
            ? _logoFileName!.split('.').last
            : 'png';
        final path = '$operatorId/logo.$ext';
        await SupabaseConfig.client.storage
            .from('operator-logos')
            .uploadBinary(path, _logoBytes!);

        final logoUrl =
            '${SupabaseConfig.storageUrl}/operator-logos/$operatorId/logo.$ext';
        await SupabaseConfig.client
            .from('operators')
            .update({'logo_url': logoUrl})
            .eq('id', operatorId);
      }

      if (mounted) {
        Navigator.pop(context);
        widget.onSaved();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Operator created ✅'),
            backgroundColor: Color(0xFF059669),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Text(
                'Add New Operator',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: _pickLogo,
                child: Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFFE5E7EB),
                      width: 2,
                    ),
                  ),
                  child: _logoBytes != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: Image.memory(
                            _logoBytes!,
                            fit: BoxFit.contain,
                          ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_photo_alternate_outlined,
                              color: const Color(0xFF9CA3AF),
                              size: 28,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Logo',
                              style: TextStyle(
                                fontSize: 11,
                                color: const Color(0xFF9CA3AF),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 20),
              _Field(
                controller: _nameCtrl,
                label: 'Company Name',
                hint: 'e.g. Capitol Express',
                icon: Icons.business_rounded,
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 14),
              _Field(
                controller: _contactCtrl,
                label: 'Contact Number',
                hint: '+855 23 123 456',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF111827),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Create Operator',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;

  const _Field({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.keyboardType = TextInputType.text,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
            prefixIcon: Icon(icon, color: const Color(0xFF6B7280), size: 18),
            filled: true,
            fillColor: const Color(0xFFF9FAFB),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF111827), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFEF4444)),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }
}
