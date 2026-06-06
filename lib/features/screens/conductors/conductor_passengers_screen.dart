import 'package:flutter/material.dart';
import '../../../supabase_config.dart';
import 'conductor_scanner_screen.dart';

class ConductorPassengersScreen extends StatefulWidget {
  final Map<String, dynamic> trip;
  const ConductorPassengersScreen({super.key, required this.trip});

  @override
  State<ConductorPassengersScreen> createState() =>
      _ConductorPassengersScreenState();
}

class _ConductorPassengersScreenState extends State<ConductorPassengersScreen> {
  List<Map<String, dynamic>> _passengers = [];
  bool _isLoading = true;
  bool _isAllowingStart = false;
  String _filterStatus = 'all';

  @override
  void initState() {
    super.initState();
    _loadPassengers();
  }

  Future<void> _loadPassengers() async {
    setState(() => _isLoading = true);
    try {
      final data = await SupabaseConfig.client
          .from('bookings')
          .select('''
            id, seat_number, status, total_price, booking_channel,
            users!bookings_passenger_id_fkey ( name, phone ),
            tickets ( id, qr_code, status, scanned_at )
          ''')
          .eq('trip_id', widget.trip['id'])
          .inFilter('status', ['confirmed', 'boarded', 'pending'])
          .order('seat_number');

      if (mounted) {
        setState(() {
          _passengers = List<Map<String, dynamic>>.from(data);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredPassengers {
    if (_filterStatus == 'all') return _passengers;
    return _passengers.where((p) => p['status'] == _filterStatus).toList();
  }

  int get _boardedCount =>
      _passengers.where((p) => p['status'] == 'boarded').length;
  int get _confirmedCount =>
      _passengers.where((p) => p['status'] == 'confirmed').length;

  // Manually mark as boarded (for cash walk-in or conductor override)
  Future<void> _markBoarded(String bookingId, String ticketId) async {
    try {
      await SupabaseConfig.client
          .from('bookings')
          .update({'status': 'boarded'})
          .eq('id', bookingId);

      await SupabaseConfig.client
          .from('tickets')
          .update({
            'status': 'used',
            'scanned_at': DateTime.now().toIso8601String(),
            'scanned_by': SupabaseConfig.client.auth.currentUser?.id,
          })
          .eq('id', ticketId);

      await _loadPassengers();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Passenger marked as boarded ✅'),
            backgroundColor: Color(0xFF10B981),
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
    }
  }

  Future<void> _allowTripStart() async {
    setState(() => _isAllowingStart = true);
    try {
      final response = await SupabaseConfig.client
          .from('trips')
          .update({'conductor_allowed_start': true})
          .eq('id', widget.trip['id'])
          .select();

      if (response == null || response.isEmpty) {
        throw Exception(
          'Update blocked by Supabase RLS policy. Conductor role cannot update trips.',
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Trip start allowed by conductor ✅'),
            backgroundColor: Color(0xFF10B981),
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
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isAllowingStart = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final schedule = widget.trip['schedules'] as Map<String, dynamic>?;
    final route = schedule?['routes'] as Map<String, dynamic>?;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1D4ED8),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Passenger List',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            Text(
              '${route?['origin'] ?? ''} → ${route?['destination'] ?? ''}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withOpacity(0.85),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner_rounded),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    ConductorScannerScreen(tripId: widget.trip['id']),
              ),
            ).then((_) => _loadPassengers()),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadPassengers,
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress bar
          Container(
            color: const Color(0xFF1D4ED8),
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$_boardedCount / ${_passengers.length} boarded',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${_passengers.isEmpty ? 0 : (_boardedCount / _passengers.length * 100).toStringAsFixed(0)}%',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: _passengers.isEmpty
                        ? 0
                        : _boardedCount / _passengers.length,
                    backgroundColor: Colors.white.withOpacity(0.3),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.white,
                    ),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),

          // Filter chips
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                _FilterChip(
                  label: 'All (${_passengers.length})',
                  isSelected: _filterStatus == 'all',
                  color: const Color(0xFF1D4ED8),
                  onTap: () => setState(() => _filterStatus = 'all'),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Waiting ($_confirmedCount)',
                  isSelected: _filterStatus == 'confirmed',
                  color: const Color(0xFF1A73E8),
                  onTap: () => setState(() => _filterStatus = 'confirmed'),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Boarded ($_boardedCount)',
                  isSelected: _filterStatus == 'boarded',
                  color: const Color(0xFF10B981),
                  onTap: () => setState(() => _filterStatus = 'boarded'),
                ),
              ],
            ),
          ),

          // Passenger list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredPassengers.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.people_outline_rounded,
                          size: 48,
                          color: Color(0xFF9CA3AF),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _filterStatus == 'all'
                              ? 'No passengers booked'
                              : 'No $_filterStatus passengers',
                          style: const TextStyle(color: Color(0xFF6B7280)),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredPassengers.length,
                    itemBuilder: (context, index) {
                      final p = _filteredPassengers[index];
                      return _PassengerCard(
                        passenger: p,
                        onMarkBoarded: () {
                          final tickets = p['tickets'] as List?;
                          final ticketId = tickets != null && tickets.isNotEmpty
                              ? tickets.first['id'] as String
                              : '';
                          _markBoarded(p['id'] as String, ticketId);
                        },
                      );
                    },
                  ),
          ),

          // Allow Trip Start Button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  // ignore: deprecated_member_use
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isAllowingStart ? null : _allowTripStart,
                icon: _isAllowingStart
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check_circle_outline_rounded),
                label: const Text(
                  'Allow Trip Start',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Passenger Card ───────────────────────────────────────────────────────────

class _PassengerCard extends StatelessWidget {
  final Map<String, dynamic> passenger;
  final VoidCallback onMarkBoarded;
  const _PassengerCard({required this.passenger, required this.onMarkBoarded});

  @override
  Widget build(BuildContext context) {
    final user = passenger['users'] as Map<String, dynamic>?;
    final status = passenger['status'] as String;
    final tickets = passenger['tickets'] as List?;
    final isBoarded = status == 'boarded';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: isBoarded
            // ignore: deprecated_member_use
            ? Border.all(color: const Color(0xFF10B981).withOpacity(0.3))
            : null,
        boxShadow: [
          BoxShadow(
            // ignore: deprecated_member_use
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: isBoarded
              ? const Color(0xFF10B981).withOpacity(0.1)
              : const Color(0xFF1D4ED8).withOpacity(0.1),
          child: Text(
            (user?['name'] as String? ?? 'P')[0].toUpperCase(),
            style: TextStyle(
              color: isBoarded
                  ? const Color(0xFF10B981)
                  : const Color(0xFF1D4ED8),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        title: Text(
          user?['name'] ?? 'Unknown',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF111827),
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Seat ${passenger['seat_number']} • ${user?['phone'] ?? '—'}',
              style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
            ),
            if (passenger['booking_channel'] == 'conductor')
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Walk-in',
                  style: TextStyle(
                    fontSize: 10,
                    color: Color(0xFF92400E),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        trailing: isBoarded
            ? const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    color: Color(0xFF10B981),
                    size: 24,
                  ),
                  Text(
                    'Boarded',
                    style: TextStyle(
                      fontSize: 10,
                      color: Color(0xFF10B981),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              )
            : GestureDetector(
                onTap: onMarkBoarded,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1D4ED8),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Board',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}

// ─── Filter Chip ──────────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;
  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color : const Color(0xFFF3F4F6),
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
