import 'package:flutter/material.dart';

import '../../../core/error/result.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/route_stop_model.dart';
import '../../../models/stop_model.dart';
import '../../../repositories/stop_repository.dart';

class RouteStopsEditor extends StatefulWidget {
  final String routeId;
  final String origin;
  final String destination;

  const RouteStopsEditor({
    super.key,
    required this.routeId,
    required this.origin,
    required this.destination,
  });

  @override
  State<RouteStopsEditor> createState() => _RouteStopsEditorState();
}

class _EditableStop {
  String? id; // null if new
  String stopId;
  String stopName;
  int stopOrder;
  int arrivalOffset;
  int departureOffset;
  double? lat;
  double? lng;

  _EditableStop({
    this.id,
    required this.stopId,
    required this.stopName,
    required this.stopOrder,
    required this.arrivalOffset,
    required this.departureOffset,
    this.lat,
    this.lng,
  });

  Map<String, dynamic> toInsert() => {
    'stop_id': stopId,
    'stop_order': stopOrder,
    'arrival_offset': arrivalOffset,
    'departure_offset': departureOffset,
  };
}

class _RouteStopsEditorState extends State<RouteStopsEditor> {
  final _repo = StopRepository();
  List<_EditableStop> _stops = [];
  List<StopModel> _availableStops = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final stopsResult = await _repo.getAllStops();

    if (stopsResult is Success<List<StopModel>>) {
      _availableStops = stopsResult.data;
    }

    final routeStopsResult = await _repo.getStopsByRoute(widget.routeId);

    if (routeStopsResult is Success<List<RouteStopModel>>) {
      _stops = routeStopsResult.data.map((rs) => _EditableStop(
        id: rs.id,
        stopId: rs.stopId,
        stopName: rs.stopName,
        stopOrder: rs.stopOrder,
        arrivalOffset: rs.arrivalOffset,
        departureOffset: rs.departureOffset,
        lat: rs.stop?.lat,
        lng: rs.stop?.lng,
      )).toList();
    } else {
      _stops = [];
    }

    if (mounted) setState(() => _isLoading = false);
  }

  void _addStop() {
    final available = _availableStops
        .where((s) => !_stops.any((es) => es.stopId == s.id))
        .toList();

    if (available.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No more stops available to add'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _StopPickerSheet(
        stops: available,
        onSelected: (stop) {
          Navigator.pop(ctx);
          setState(() {
            _stops.add(_EditableStop(
              stopId: stop.id,
              stopName: stop.name,
              stopOrder: _stops.length,
              arrivalOffset: _stops.isNotEmpty
                  ? _stops.last.departureOffset + 5
                  : 0,
              departureOffset: _stops.isNotEmpty
                  ? _stops.last.departureOffset + 10
                  : 0,
              lat: stop.lat,
              lng: stop.lng,
            ));
          });
        },
      ),
    );
  }

  void _removeStop(int index) {
    setState(() => _stops.removeAt(index));
    for (var i = 0; i < _stops.length; i++) {
      _stops[i].stopOrder = i;
    }
  }

  Future<void> _save() async {
    if (_stops.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('A route needs at least 2 stops (origin and destination)'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final data = _stops.map((s) => s.toInsert()).toList();
    final result = await _repo.saveRouteStops(
      routeId: widget.routeId,
      stops: data,
    );

    if (result is Success && mounted) {
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Route stops saved'),
          backgroundColor: Color(0xFF059669),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else if (result is Failure && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Stops: ${widget.origin} → ${widget.destination}'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _save,
            child: const Text('Done', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _addStop,
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Add Stop'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline_rounded, size: 14, color: AppColors.textHint),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Drag ⠿ to reorder. Tap fields to edit offsets.',
                          style: TextStyle(fontSize: 12, color: AppColors.textHint),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _stops.isEmpty
                      ? const Center(
                          child: Text(
                            'No stops yet. Tap "Add Stop" to begin.',
                            style: TextStyle(color: AppColors.textSoft),
                          ),
                        )
                      : ReorderableListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          itemCount: _stops.length,
                          onReorder: (oldIndex, newIndex) {
                            setState(() {
                              if (newIndex > oldIndex) newIndex--;
                              final item = _stops.removeAt(oldIndex);
                              _stops.insert(newIndex, item);
                              for (var i = 0; i < _stops.length; i++) {
                                _stops[i].stopOrder = i;
                              }
                            });
                          },
                          itemBuilder: (context, index) {
                            final s = _stops[index];
                            return _StopEditorTile(
                              key: ValueKey('${s.stopId}_$index'),
                              editable: s,
                              index: index,
                              isFirst: index == 0,
                              isLast: index == _stops.length - 1,
                              onRemove: () => _removeStop(index),
                              onChanged: () => setState(() {}),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}

class _StopEditorTile extends StatelessWidget {
  final _EditableStop editable;
  final int index;
  final bool isFirst;
  final bool isLast;
  final VoidCallback onRemove;
  final VoidCallback onChanged;

  const _StopEditorTile({
    super.key,
    required this.editable,
    required this.index,
    required this.isFirst,
    required this.isLast,
    required this.onRemove,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ReorderableDragStartListener(
                  index: index,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.drag_indicator_rounded,
                      size: 20,
                      color: AppColors.textHint,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isFirst
                        ? const Color(0xFF059669).withValues(alpha: 0.1)
                        : isLast
                            ? const Color(0xFFEF4444).withValues(alpha: 0.1)
                            : AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$index',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: isFirst
                          ? const Color(0xFF059669)
                          : isLast
                              ? const Color(0xFFEF4444)
                              : AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    editable.stopName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: AppColors.textDark,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18),
                  color: AppColors.error,
                  visualDensity: VisualDensity.compact,
                  onPressed: onRemove,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const SizedBox(width: 38),
                Expanded(
                  child: _OffsetField(
                    label: 'Arrival +',
                    value: editable.arrivalOffset,
                    onChanged: (v) {
                      editable.arrivalOffset = v;
                      onChanged();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _OffsetField(
                    label: 'Depart +',
                    value: editable.departureOffset,
                    onChanged: (v) {
                      editable.departureOffset = v;
                      onChanged();
                    },
                  ),
                ),
              ],
            ),
            if (isFirst || isLast) ...[
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.only(left: 38),
                child: Text(
                  isFirst ? '⛁ Origin stop' : '⛁ Destination stop',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textHint,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _OffsetField extends StatelessWidget {
  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  const _OffsetField({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: TextField(
              controller: TextEditingController(text: '$value'),
              keyboardType: TextInputType.number,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.zero,
                border: InputBorder.none,
              ),
              onChanged: (v) {
                final parsed = int.tryParse(v);
                if (parsed != null) onChanged(parsed);
              },
            ),
          ),
          const Text(
            'min',
            style: TextStyle(fontSize: 11, color: AppColors.textHint),
          ),
        ],
      ),
    );
  }
}

class _StopPickerSheet extends StatelessWidget {
  final List<StopModel> stops;
  final ValueChanged<StopModel> onSelected;

  const _StopPickerSheet({
    required this.stops,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.85,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFD1D5DB),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  children: [
                    const Text(
                      'Select a Stop',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.close_rounded, size: 20, color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppColors.border),
              Expanded(
                child: stops.isEmpty
                    ? const Center(child: Text('No stops available'))
                    : ListView.separated(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        itemCount: stops.length,
                        separatorBuilder: (_, _) => const Divider(
                          height: 1,
                          indent: 16,
                          endIndent: 16,
                          color: AppColors.border,
                        ),
                        itemBuilder: (context, index) {
                          final stop = stops[index];
                          return ListTile(
                            leading: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: AppColors.primaryLight,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.flag_rounded,
                                color: AppColors.primary,
                                size: 20,
                              ),
                            ),
                            title: Text(stop.name),
                            trailing: const Icon(
                              Icons.add_circle_outline_rounded,
                              color: AppColors.primary,
                            ),
                            onTap: () => onSelected(stop),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
