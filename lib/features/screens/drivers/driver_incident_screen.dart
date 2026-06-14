import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../services/notification_service.dart';
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
  
  Position? _currentPosition;
  String _detectedLocationName = 'Detecting location...';
  bool _isGeolocating = false;

  final List<Map<String, dynamic>> _types = [
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _detectLocation();
    });
  }

  Future<void> _detectLocation() async {
    if (_isGeolocating) return;
    setState(() {
      _isGeolocating = true;
      _detectedLocationName = 'Accessing GPS...';
    });
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() {
          _detectedLocationName = 'GPS Permission Denied';
          _isGeolocating = false;
        });
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 5),
      );

      if (!mounted) return;
      setState(() {
        _currentPosition = pos;
        _detectedLocationName = 'Resolving address...';
      });

      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=${pos.latitude}&lon=${pos.longitude}&zoom=14',
      );
      final response = await http.get(
        url,
        headers: {'User-Agent': 'BusExpressDriverApp/1.0.0'},
      ).timeout(const Duration(seconds: 4));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final address = data['address'] as Map<String, dynamic>?;
        
        String name = '';
        if (address != null) {
          final parts = <String>[];
          final village = address['village'] as String?;
          final town = address['town'] as String?;
          final city = address['city'] as String?;
          final county = address['county'] as String?;
          final state = address['state'] as String?;
          
          final primary = village ?? town ?? city ?? county;
          if (primary != null) parts.add(primary);
          if (state != null) parts.add(state);
          
          name = parts.isNotEmpty ? parts.join(', ') : (data['display_name'] as String? ?? '');
        } else {
          name = data['display_name'] as String? ?? 'Unknown Location';
        }
        
        setState(() {
          _detectedLocationName = name.trim();
          _isGeolocating = false;
        });
      } else {
        setState(() {
          _detectedLocationName = 'Location: ${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)}';
          _isGeolocating = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      if (_currentPosition != null) {
        setState(() {
          _detectedLocationName = '${_currentPosition!.latitude.toStringAsFixed(4)}, ${_currentPosition!.longitude.toStringAsFixed(4)}';
          _isGeolocating = false;
        });
      } else {
        setState(() {
          _detectedLocationName = 'Failed to detect location';
          _isGeolocating = false;
        });
      }
    }
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

      String finalDesc = _descriptionController.text.trim();
      if (_currentPosition != null &&
          _detectedLocationName.isNotEmpty &&
          _detectedLocationName != 'GPS Permission Denied' &&
          _detectedLocationName != 'Failed to detect location' &&
          _detectedLocationName != 'Detecting location...' &&
          _detectedLocationName != 'Accessing GPS...' &&
          _detectedLocationName != 'Resolving address...') {
        finalDesc = '[Location: $_detectedLocationName] $finalDesc';
      }

      await SupabaseConfig.client.from('incidents').insert({
        'trip_id': widget.tripId,
        'reported_by': user.id,
        'type': _selectedType,
        'description': finalDesc,
        'created_at': DateTime.now().toIso8601String(),
      });

      unawaited(_notifyPassengersOfIncident());

      if (!mounted) return;

      _descriptionController.clear();
      await _loadPastIncidents();
      if (!mounted) return;

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

  Future<void> _notifyPassengersOfIncident() async {
    try {
      final bookings = await SupabaseConfig.client
          .from('bookings')
          .select('passenger_id')
          .eq('trip_id', widget.tripId)
          .inFilter('status', ['confirmed', 'boarded']);

      final passengerIds = <String>{};
      for (final b in bookings) {
        final pid = b['passenger_id'] as String?;
        if (pid != null) passengerIds.add(pid);
      }

      if (passengerIds.isEmpty) return;

      final typeLabel = _types
          .firstWhere(
            (t) => t['value'] == _selectedType,
            orElse: () => {'label': 'Issue'},
          )['label'] as String;

      final delayMap = {'delay': '20', 'breakdown': '30', 'accident': '45', 'other': '15'};
      final estDelay = delayMap[_selectedType] ?? '15';

      final title = 'Trip Alert: $typeLabel';
      final body =
          'Your bus reported a $typeLabel. Estimated delay: $estDelay min. We apologize for the inconvenience.';

      for (final uid in passengerIds) {
        await NotificationService.instance.insertNotification(
          userId: uid,
          title: title,
          body: body,
          type: 'incident',
          referenceType: 'trip',
          referenceId: widget.tripId,
        );
      }
    } catch (e) {
      debugPrint('[IncidentNotify] Failed to notify passengers: $e');
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

            // Incident Location Card
            const Text(
              'Incident Location',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE5E7EB)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _isGeolocating 
                          ? const Color(0xFFEFF6FF) 
                          : (_currentPosition != null ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2)),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _isGeolocating 
                          ? Icons.location_searching_rounded 
                          : (_currentPosition != null ? Icons.my_location_rounded : Icons.location_off_rounded),
                      color: _isGeolocating 
                          ? const Color(0xFF3B82F6) 
                          : (_currentPosition != null ? const Color(0xFF10B981) : const Color(0xFFEF4444)),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isGeolocating 
                              ? 'Auto-detecting Location...' 
                              : (_currentPosition != null ? 'Auto-detected Location' : 'Location Service'),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: _isGeolocating 
                                ? const Color(0xFF3B82F6) 
                                : (_currentPosition != null ? const Color(0xFF10B981) : const Color(0xFFEF4444)),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _detectedLocationName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF111827),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (!_isGeolocating)
                    IconButton(
                      icon: const Icon(Icons.refresh_rounded, color: Color(0xFF4B5563)),
                      onPressed: _detectLocation,
                      tooltip: 'Refresh Location',
                    ),
                ],
              ),
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
