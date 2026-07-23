import 'package:flutter/material.dart';
import '../../../l10n/tr_extension.dart';
import '../../../supabase_config.dart';
import 'operator_routes_screen.dart';

class OperatorSchedulesScreen extends StatefulWidget {
  final String operatorId;
  const OperatorSchedulesScreen({super.key, required this.operatorId});

  @override
  State<OperatorSchedulesScreen> createState() =>
      _OperatorSchedulesScreenState();
}

class _OperatorSchedulesScreenState extends State<OperatorSchedulesScreen> {
  List<Map<String, dynamic>> _schedules = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSchedules();
  }

  Future<void> _loadSchedules() async {
    setState(() => _isLoading = true);
    try {
      final data = await SupabaseConfig.client
          .from('schedules')
          .select('''
            id, departure_time, arrival_time, days_of_week, price, status,
            routes!inner ( id, origin, destination, operator_id ),
            buses ( model, plate_number ),
            users!schedules_driver_id_fkey ( name )
          ''')
          .eq('routes.operator_id', widget.operatorId)
          .order('departure_time');

      if (mounted) {
        setState(() {
          _schedules = List<Map<String, dynamic>>.from(data);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showScheduleForm({Map<String, dynamic>? existing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ScheduleFormSheet(
        operatorId: widget.operatorId,
        existing: existing,
        onSaved: _loadSchedules,
      ),
    );
  }

  Future<void> _toggleStatus(String id, String current) async {
    final newStatus = current == 'active' ? 'cancelled' : 'active';
    try {
      await SupabaseConfig.client
          .from('schedules')
          .update({'status': newStatus})
          .eq('id', id);
      _loadSchedules();
    } catch (e) {
      _showSnack(context.tr.failedToUpdate('$e'), isError: true);
    }
  }

  Future<void> _delete(String id) async {
    final confirm = await _confirmDialog(
      context.tr.deleteSchedule,
      context.tr.deleteScheduleConfirm,
    );
    if (!confirm) return;
    try {
      await SupabaseConfig.client.from('schedules').delete().eq('id', id);
      _loadSchedules();
    } catch (e) {
      _showSnack(context.tr.failedToUpdate('$e'), isError: true);
    }
  }

  Future<bool> _confirmDialog(String title, String message) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        content: Text(
          message,
          style: const TextStyle(color: Color(0xFF6B7280)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              context.tr.cancel,
              style: const TextStyle(color: Color(0xFF6B7280)),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(context.tr.confirm),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError
            ? const Color(0xFFEF4444)
            : const Color(0xFF059669),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _formatDays(String days, BuildContext context) {
    const map = {
      '1': 'Mon',
      '2': 'Tue',
      '3': 'Wed',
      '4': 'Thu',
      '5': 'Fri',
      '6': 'Sat',
      '7': 'Sun',
    };
    final parts = days.split(',');
    if (parts.length == 7) return context.tr.everyDay;
    if (parts.length == 5 && !parts.contains('6') && !parts.contains('7')) {
      return context.tr.weekdays;
    }
    return parts.map((d) => map[d.trim()] ?? d).join(', ');
  }

  String _formatTime(String t, BuildContext context) {
    final p = t.split(':');
    final h = int.parse(p[0]);
    final period = h >= 12 ? context.tr.pm : context.tr.am;
    final dh = h > 12 ? h - 12 : (h == 0 ? 12 : h);
    return '$dh:${p[1]} $period';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadSchedules,
              child: _schedules.isEmpty
                  ? _EmptyState(
                      icon: Icons.schedule_rounded,
                      message: context.tr.noSchedulesYet,
                      subtitle: context.tr.createScheduleSubtitle,
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _schedules.length,
                      itemBuilder: (context, i) {
                        final s = _schedules[i];
                        final route = s['routes'] as Map<String, dynamic>?;
                        final bus = s['buses'] as Map<String, dynamic>?;
                        final driver = s['users'] as Map<String, dynamic>?;
                        final isActive = s['status'] == 'active';

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
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
                                        Expanded(
                                          child: Text(
                                            '${route?['origin'] ?? '?'} → ${route?['destination'] ?? '?'}',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                              color: Color(0xFF111827),
                                            ),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isActive
                                                ? const Color(0xFFD1FAE5)
                                                : const Color(0xFFFEE2E2),
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                          ),
                                          child: Text(
                                            isActive ? context.tr.scheduleActive : context.tr.cancelled,
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: isActive
                                                  ? const Color(0xFF059669)
                                                  : const Color(0xFFEF4444),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        // Time
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              _formatTime(s['departure_time'], context),
                                              style: const TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.w700,
                                                color: Color(0xFF111827),
                                              ),
                                            ),
                                            Text(
                                              context.tr.departureLabel,
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Color(0xFF6B7280),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const Padding(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 16,
                                          ),
                                          child: Icon(
                                            Icons.arrow_forward_rounded,
                                            color: Color(0xFF6B7280),
                                            size: 16,
                                          ),
                                        ),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              _formatTime(s['arrival_time'], context),
                                              style: const TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.w700,
                                                color: Color(0xFF111827),
                                              ),
                                            ),
                                            Text(
                                              context.tr.arrivalLabel,
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Color(0xFF6B7280),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const Spacer(),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              '\$${s['price']}',
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.w700,
                                                color: Color(0xFF059669),
                                              ),
                                            ),
                                            Text(
                                              context.tr.perSeat,
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Color(0xFF6B7280),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.calendar_today_rounded,
                                          size: 13,
                                          color: Color(0xFF6B7280),
                                        ),
                                        const SizedBox(width: 5),
                                        Text(
                                          _formatDays(s['days_of_week'], context),
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF6B7280),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        if (bus != null) ...[
                                          const Icon(
                                            Icons.directions_bus_outlined,
                                            size: 13,
                                            color: Color(0xFF6B7280),
                                          ),
                                          const SizedBox(width: 5),
                                          Text(
                                            bus['model'] ?? '',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFF6B7280),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    if (driver != null)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 6),
                                        child: Row(
                                          children: [
                                            const Icon(
                                              Icons.person_outline_rounded,
                                              size: 13,
                                              color: Color(0xFF6B7280),
                                            ),
                                            const SizedBox(width: 5),
                                            Text(
                                              driver['name'] ?? '',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Color(0xFF6B7280),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              const Divider(
                                height: 1,
                                color: Color(0xFFF3F4F6),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                child: Row(
                                  children: [
                                    TextButton.icon(
                                      onPressed: () =>
                                          _showScheduleForm(existing: s),
                                      icon: const Icon(
                                        Icons.edit_rounded,
                                        size: 16,
                                      ),
                                      label: Text(context.tr.edit),
                                      style: TextButton.styleFrom(
                                        foregroundColor: const Color(
                                          0xFF1A73E8,
                                        ),
                                      ),
                                    ),
                                    TextButton.icon(
                                      onPressed: () =>
                                          _toggleStatus(s['id'], s['status']),
                                      icon: Icon(
                                        isActive
                                            ? Icons.pause_circle_outline_rounded
                                            : Icons.play_circle_outline_rounded,
                                        size: 16,
                                      ),
                                      label: Text(
                                        isActive ? context.tr.deactivate : context.tr.activate,
                                      ),
                                      style: TextButton.styleFrom(
                                        foregroundColor: isActive
                                            ? const Color(0xFFF59E0B)
                                            : const Color(0xFF059669),
                                      ),
                                    ),
                                    const Spacer(),
                                    IconButton(
                                      onPressed: () => _delete(s['id']),
                                      icon: const Icon(
                                        Icons.delete_outline_rounded,
                                        color: Color(0xFFEF4444),
                                        size: 20,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_schedules',
        onPressed: () => _showScheduleForm(),
        backgroundColor: const Color(0xFF54282E),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: Text(
          context.tr.addSchedule,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

// ─── Schedule Form Sheet ──────────────────────────────────────────────────────

class _ScheduleFormSheet extends StatefulWidget {
  final String operatorId;
  final Map<String, dynamic>? existing;
  final VoidCallback onSaved;

  const _ScheduleFormSheet({
    required this.operatorId,
    required this.onSaved,
    this.existing,
  });

  @override
  State<_ScheduleFormSheet> createState() => _ScheduleFormSheetState();
}

class _ScheduleFormSheetState extends State<_ScheduleFormSheet> {
  final _priceCtrl = TextEditingController();
  TimeOfDay _departureTime = const TimeOfDay(hour: 7, minute: 0);
  TimeOfDay _arrivalTime = const TimeOfDay(hour: 13, minute: 0);

  List<Map<String, dynamic>> _routes = [];
  List<Map<String, dynamic>> _buses = [];
  List<Map<String, dynamic>> _drivers = [];
  List<Map<String, dynamic>> _conductors = [];

  String? _selectedRouteId;
  String? _selectedBusId;
  String? _selectedDriverId;
  String? _selectedConductorId;

  final Map<String, bool> _days = {
    '1': true,
    '2': true,
    '3': true,
    '4': true,
    '5': true,
    '6': true,
    '7': true,
  };
  final Map<String, String> _dayLabels = {
    '1': 'Mon',
    '2': 'Tue',
    '3': 'Wed',
    '4': 'Thu',
    '5': 'Fri',
    '6': 'Sat',
    '7': 'Sun',
  };

  bool _isLoading = false;
  bool _isFetching = true;

  @override
  void initState() {
    super.initState();
    _loadDropdownData();
    if (widget.existing != null) {
      final e = widget.existing!;
      _priceCtrl.text = e['price']?.toString() ?? '';
      _selectedRouteId = (e['routes'] as Map?)?.containsKey('id') == true
          ? e['routes']['id'] as String?
          : null;
      _selectedBusId = (e['buses'] as Map?)?.containsKey('id') == true
          ? e['buses']['id'] as String?
          : null;
      // Parse times
      final dep = (e['departure_time'] as String).split(':');
      final arr = (e['arrival_time'] as String).split(':');
      _departureTime = TimeOfDay(
        hour: int.parse(dep[0]),
        minute: int.parse(dep[1]),
      );
      _arrivalTime = TimeOfDay(
        hour: int.parse(arr[0]),
        minute: int.parse(arr[1]),
      );
      // Parse days
      final savedDays = (e['days_of_week'] as String).split(',');
      for (final k in _days.keys) {
        _days[k] = savedDays.contains(k);
      }
    }
  }

  @override
  void dispose() {
    _priceCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadDropdownData() async {
    try {
      final results = await Future.wait([
        SupabaseConfig.client
            .from('routes')
            .select('id, origin, destination')
            .eq('operator_id', widget.operatorId)
            .eq('status', 'active'),
        SupabaseConfig.client
            .from('buses')
            .select('id, model, plate_number')
            .eq('operator_id', widget.operatorId)
            .eq('status', 'active'),
        SupabaseConfig.client
            .from('users')
            .select('id, name')
            .eq('operator_id', widget.operatorId)
            .eq('role', 'driver'),
        SupabaseConfig.client
            .from('users')
            .select('id, name')
            .eq('operator_id', widget.operatorId)
            .eq('role', 'conductor'),
      ]);

      if (mounted) {
        setState(() {
          _routes = List<Map<String, dynamic>>.from(results[0]);
          _buses = List<Map<String, dynamic>>.from(results[1]);
          _drivers = List<Map<String, dynamic>>.from(results[2]);
          _conductors = List<Map<String, dynamic>>.from(results[3]);

          // Pre-select first item when value is null (new schedule)
          if (_selectedRouteId == null && _routes.isNotEmpty) {
            _selectedRouteId = _routes.first['id'] as String?;
          }
          if (_selectedBusId == null && _buses.isNotEmpty) {
            _selectedBusId = _buses.first['id'] as String?;
          }
          if (_selectedDriverId == null && _drivers.isNotEmpty) {
            _selectedDriverId = _drivers.first['id'] as String?;
          }

          _isFetching = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isFetching = false);
    }
  }

  Future<void> _pickTime(bool isDeparture) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isDeparture ? _departureTime : _arrivalTime,
    );
    if (picked != null) {
      setState(() {
        if (isDeparture) {
          _departureTime = picked;
        } else {
          _arrivalTime = picked;
        }
      });
    }
  }

  String _timeString(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:00';

  String _formatTime(TimeOfDay t) {
    final h = t.hour;
    final period = h >= 12 ? context.tr.pm : context.tr.am;
    final dh = h > 12 ? h - 12 : (h == 0 ? 12 : h);
    return '$dh:${t.minute.toString().padLeft(2, '0')} $period';
  }

  Future<void> _save() async {
    if (_selectedRouteId == null) {
      _showSnack(context.tr.pleaseSelectRoute, isError: true);
      return;
    }
    if (_selectedBusId == null) {
      _showSnack(context.tr.pleaseSelectBus, isError: true);
      return;
    }
    if (_selectedDriverId == null) {
      _showSnack(context.tr.pleaseSelectDriver, isError: true);
      return;
    }
    if (_priceCtrl.text.trim().isEmpty) {
      _showSnack(context.tr.pleaseEnterPrice, isError: true);
      return;
    }

    final selectedDays = _days.entries
        .where((e) => e.value)
        .map((e) => e.key)
        .join(',');

    if (selectedDays.isEmpty) {
      _showSnack(context.tr.pleaseSelectAtLeastOneDay, isError: true);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final data = {
        'route_id': _selectedRouteId,
        'bus_id': _selectedBusId,
        'driver_id': _selectedDriverId,
        'conductor_id': _selectedConductorId,
        'departure_time': _timeString(_departureTime),
        'arrival_time': _timeString(_arrivalTime),
        'days_of_week': selectedDays,
        'price': double.parse(_priceCtrl.text.trim()),
        'status': 'active',
      };

      if (widget.existing != null) {
        await SupabaseConfig.client
            .from('schedules')
            .update(data)
            .eq('id', widget.existing!['id']);
      } else {
        await SupabaseConfig.client.from('schedules').insert(data);
      }

      if (mounted) {
        Navigator.pop(context);
        widget.onSaved();
        _showSnack(
          widget.existing != null ? context.tr.scheduleUpdated : context.tr.scheduleCreated,
        );
      }
    } catch (e) {
      _showSnack(context.tr.failedToUpdate('$e'), isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError
            ? const Color(0xFFEF4444)
            : const Color(0xFF059669),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: _isFetching
            ? const SizedBox(
                height: 200,
                child: Center(child: CircularProgressIndicator()),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE5E7EB),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Text(
                      isEdit ? context.tr.editSchedule : context.tr.newSchedule,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Route
                    _DropdownField(
                      label: context.tr.routeDropdown,
                      value: _selectedRouteId,
                      items: _routes
                          .map(
                            (r) => DropdownMenuItem(
                              value: r['id'] as String,
                              child: Text(
                                '${r['origin']} → ${r['destination']}',
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _selectedRouteId = v),
                    ),
                    const SizedBox(height: 14),

                    // Bus
                    _DropdownField(
                      label: context.tr.busDropdown,
                      value: _selectedBusId,
                      items: _buses
                          .map(
                            (b) => DropdownMenuItem(
                              value: b['id'] as String,
                              child: Text(
                                '${b['model']} • ${b['plate_number']}',
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _selectedBusId = v),
                    ),
                    const SizedBox(height: 14),

                    // Driver
                    _DropdownField(
                      label: context.tr.driverDropdown,
                      value: _selectedDriverId,
                      items: _drivers
                          .map(
                            (d) => DropdownMenuItem(
                              value: d['id'] as String,
                              child: Text(d['name'] as String),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _selectedDriverId = v),
                    ),
                    const SizedBox(height: 14),

                    // Conductor (optional)
                    _DropdownField(
                      label: context.tr.conductorOptional,
                      value: _selectedConductorId,
                      items: [
                        DropdownMenuItem(
                          value: null,
                          child: Text(context.tr.noConductor),
                        ),
                        ..._conductors.map(
                          (c) => DropdownMenuItem(
                            value: c['id'] as String,
                            child: Text(c['name'] as String),
                          ),
                        ),
                      ],
                      onChanged: (v) =>
                          setState(() => _selectedConductorId = v),
                    ),
                    const SizedBox(height: 20),

                    // Times
                    Row(
                      children: [
                        Expanded(
                          child: _TimePicker(
                            label: context.tr.departureLabel,
                            time: _formatTime(_departureTime),
                            onTap: () => _pickTime(true),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _TimePicker(
                            label: context.tr.arrivalLabel,
                            time: _formatTime(_arrivalTime),
                            onTap: () => _pickTime(false),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Price
                    _FormField(
                      controller: _priceCtrl,
                      label: context.tr.pricePerSeat,
                      hint: context.tr.priceHint,
                      icon: Icons.attach_money_rounded,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 20),

                    // Days of week
                    Text(
                      context.tr.operatingDays,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF374151),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      children: _days.entries.map((entry) {
                        final isSelected = entry.value;
                        return GestureDetector(
                          onTap: () =>
                              setState(() => _days[entry.key] = !entry.value),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFF059669)
                                  : const Color(0xFFF3F4F6),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _dayLabels[entry.key]!,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? Colors.white
                                    : const Color(0xFF6B7280),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 28),

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF059669),
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
                            : Text(
                                isEdit ? context.tr.saveChanges : context.tr.createSchedule,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
      ),
    );
  }
}

// ─── Reusable form widgets ────────────────────────────────────────────────────

class _DropdownField extends StatelessWidget {
  final String label;
  final String? value;
  final List<DropdownMenuItem<String?>> items;
  final ValueChanged<String?> onChanged;

  const _DropdownField({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
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
        DropdownButtonFormField<String?>(
          value: value,
          onChanged: onChanged,
          items: items,
          decoration: InputDecoration(
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
              borderSide: const BorderSide(color: Color(0xFF059669), width: 2),
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

class _TimePicker extends StatelessWidget {
  final String label;
  final String time;
  final VoidCallback onTap;

  const _TimePicker({
    required this.label,
    required this.time,
    required this.onTap,
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
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.access_time_rounded,
                  size: 18,
                  color: Color(0xFF6B7280),
                ),
                const SizedBox(width: 8),
                Text(
                  time,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF111827),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _FormField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final Color? iconColor;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;

  const _FormField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.iconColor,
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
            hintStyle: const TextStyle(color: Color(0xFF6B7280), fontSize: 14),
            prefixIcon: Icon(
              icon,
              color: iconColor ?? const Color(0xFF6B7280),
              size: 18,
            ),
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
              borderSide: const BorderSide(color: Color(0xFF059669), width: 2),
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

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String subtitle;
  const _EmptyState({
    required this.icon,
    required this.message,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(50),
            ),
            child: Icon(icon, size: 40, color: const Color(0xFF6B7280)),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
          ),
        ],
      ),
    );
  }
}
