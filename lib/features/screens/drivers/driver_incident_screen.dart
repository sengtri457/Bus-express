import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../supabase_config.dart';

class DriverIncidentScreen extends StatefulWidget {
  final String tripId;
  const DriverIncidentScreen({super.key, required this.tripId});

  @override
  State<DriverIncidentScreen> createState() => _DriverIncidentScreenState();
}

class _DriverIncidentScreenState extends State<DriverIncidentScreen> {
  final _descriptionController = TextEditingController();
  String _selectedType = 'delay';
  bool _isLoading = false;
  List<Map<String, dynamic>> _pastIncidents = [];

  final _types = [
    {
      'value': 'delay',
      'label': 'Delay',
      'icon': Icons.timer_off_rounded,
      'color': const Color(0xFFF59E0B),
    },
    {
      'value': 'breakdown',
      'label': 'Breakdown',
      'icon': Icons.build_rounded,
      'color': const Color(0xFFEF4444),
    },
    {
      'value': 'accident',
      'label': 'Accident',
      'icon': Icons.car_crash_rounded,
      'color': const Color(0xFFDC2626),
    },
    {
      'value': 'other',
      'label': 'Other',
      'icon': Icons.report_rounded,
      'color': const Color(0xFF6B7280),
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadPastIncidents();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadPastIncidents() async {
    try {
      final data = await SupabaseConfig.client
          .from('incidents')
          .select('id, type, description, created_at')
          .eq('trip_id', widget.tripId)
          .order('created_at', ascending: false);
      if (mounted) {
        setState(() => _pastIncidents = List<Map<String, dynamic>>.from(data));
      }
    } catch (_) {}
  }

  Future<void> _submitIncident() async {
    if (_descriptionController.text.trim().isEmpty) {
      _showError('Please describe the incident');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final user = SupabaseConfig.client.auth.currentUser;
      if (user == null) throw Exception('Not logged in');

      await SupabaseConfig.client.from('incidents').insert({
        'trip_id': widget.tripId,
        'reported_by': user.id,
        'type': _selectedType,
        'description': _descriptionController.text.trim(),
        'created_at': DateTime.now().toIso8601String(),
      });

      if (!mounted) return;

      _descriptionController.clear();
      await _loadPastIncidents();

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFFD1FAE5),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF10B981),
                  size: 36,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Incident Reported',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              const Text(
                'Your incident report has been submitted successfully.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF6B7280), fontSize: 13),
              ),
            ],
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A73E8),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('OK'),
              ),
            ),
          ],
        ),
      );
    } on PostgrestException catch (e) {
      _showError('Failed: ${e.message}');
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D47A1),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Report Incident',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header warning
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Color(0xFFF59E0B),
                    size: 22,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Report any incidents that affect this trip immediately. Your report will be sent to the operator.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF92400E),
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Incident Type
            const Text(
              'Incident Type',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 2.8,
              children: _types.map((type) {
                final isSelected = _selectedType == type['value'];
                return GestureDetector(
                  onTap: () =>
                      setState(() => _selectedType = type['value'] as String),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? (type['color'] as Color).withOpacity(0.1)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? type['color'] as Color
                            : const Color(0xFFE5E7EB),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          type['icon'] as IconData,
                          color: isSelected
                              ? type['color'] as Color
                              : const Color(0xFF9CA3AF),
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          type['label'] as String,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? type['color'] as Color
                                : const Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Description
            const Text(
              'Description',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: TextField(
                controller: _descriptionController,
                maxLines: 5,
                style: const TextStyle(fontSize: 14),
                decoration: const InputDecoration(
                  hintText:
                      'Describe what happened in detail...\n\ne.g. "Bus broke down near Kampong Thom, waiting for repair. Estimated delay: 30 minutes."',
                  hintStyle: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(16),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _submitIncident,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send_rounded, size: 20),
                label: const Text(
                  'Submit Report',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF4444),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),

            // Past incidents
            if (_pastIncidents.isNotEmpty) ...[
              const SizedBox(height: 32),
              const Text(
                'Previous Reports This Trip',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 12),
              ..._pastIncidents.map(
                (i) => _IncidentTile(incident: i, types: _types),
              ),
            ],
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

// ─── Incident Tile ────────────────────────────────────────────────────────────

class _IncidentTile extends StatelessWidget {
  final Map<String, dynamic> incident;
  final List<Map<String, dynamic>> types;
  const _IncidentTile({required this.incident, required this.types});

  @override
  Widget build(BuildContext context) {
    final type = incident['type'] as String;
    final typeConfig = types.firstWhere(
      (t) => t['value'] == type,
      orElse: () => types.last,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (typeConfig['color'] as Color).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              typeConfig['icon'] as IconData,
              color: typeConfig['color'] as Color,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      typeConfig['label'] as String,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: typeConfig['color'] as Color,
                      ),
                    ),
                    Text(
                      _formatTimestamp(incident['created_at'] as String),
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF9CA3AF),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  incident['description'] as String,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF374151),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(String ts) {
    final dt = DateTime.parse(ts).toLocal();
    final h = dt.hour;
    final period = h >= 12 ? 'PM' : 'AM';
    final dh = h > 12 ? h - 12 : (h == 0 ? 12 : h);
    return '$dh:${dt.minute.toString().padLeft(2, '0')} $period';
  }
}
