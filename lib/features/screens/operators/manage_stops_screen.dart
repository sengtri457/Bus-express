import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../l10n/tr_extension.dart';
import '../../../models/stop_model.dart';
import '../../../repositories/stop_repository.dart';

class ManageStopsScreen extends StatefulWidget {
  const ManageStopsScreen({super.key});

  @override
  State<ManageStopsScreen> createState() => _ManageStopsScreenState();
}

class _ManageStopsScreenState extends State<ManageStopsScreen> {
  final _repo = StopRepository();
  final _searchCtrl = TextEditingController();

  List<StopModel> _allStops = [];
  List<StopModel> _filteredStops = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStops();
    _searchCtrl.addListener(_filter);
  }

  @override
  void dispose() {
    _searchCtrl.removeListener(_filter);
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadStops() async {
    setState(() => _isLoading = true);
    final result = await _repo.getAllStops();
    if (mounted) {
      setState(() {
        if (result is Success<List<StopModel>>) {
          _allStops = result.data;
        } else {
          _allStops = [];
        }
        _filter();
        _isLoading = false;
      });
    }
  }

  void _filter() {
    final query = _searchCtrl.text.trim().toLowerCase();
    setState(() {
      _filteredStops = query.isEmpty
          ? _allStops
          : _allStops.where((s) =>
              s.name.toLowerCase().contains(query)).toList();
    });
  }

  void _showStopForm({StopModel? existing}) {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final latCtrl = TextEditingController(
      text: existing?.lat?.toString() ?? '',
    );
    final lngCtrl = TextEditingController(
      text: existing?.lng?.toString() ?? '',
    );
    final formKey = GlobalKey<FormState>();
    final isEdit = existing != null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40, height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Text(
                  isEdit ? 'Edit Stop' : 'Add Stop',
                  style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Stop Name',
                    hintText: 'e.g. Phnom Penh Central',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.stops_rounded, size: 18),
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: latCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Latitude',
                          hintText: 'e.g. 11.568',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.explore_rounded, size: 18),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: lngCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Longitude',
                          hintText: 'e.g. 104.921',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.explore_rounded, size: 18),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) return;
                      final name = nameCtrl.text.trim();
                      final lat = double.tryParse(latCtrl.text.trim());
                      final lng = double.tryParse(lngCtrl.text.trim());
                      if (isEdit) {
                        await _repo.updateStop(
                          id: existing!.id,
                          name: name,
                          lat: lat,
                          lng: lng,
                        );
                      } else {
                        await _repo.createStop(name: name, lat: lat, lng: lng);
                      }
                      if (ctx.mounted) {
                        Navigator.pop(ctx);
                        _loadStops();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              isEdit ? 'Stop updated' : 'Stop created',
                            ),
                            backgroundColor: const Color(0xFF059669),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF059669),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(isEdit ? 'Save Changes' : 'Create Stop'),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _deleteStop(StopModel stop) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.lgR),
        title: const Text('Delete stop?'),
        content: Text('Delete "${stop.name}" permanently?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final result = await _repo.deleteStop(stop.id);
    if (result is Success) {
      _loadStops();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Stop deleted'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text((result as Failure).message),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Manage Stops'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search stops...',
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 12,
                ),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredStops.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                color: AppColors.primaryLight,
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: const Icon(
                                Icons.stops_rounded,
                                size: 36,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'No stops yet',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textDark,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Create your first stop to get started.',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.textSoft,
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadStops,
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4,
                          ),
                          itemCount: _filteredStops.length,
                          separatorBuilder: (_, _) => const Divider(
                            height: 1,
                            indent: 72,
                            endIndent: 16,
                            color: AppColors.border,
                          ),
                          itemBuilder: (context, index) {
                            final stop = _filteredStops[index];
                            return _StopTile(
                              stop: stop,
                              onEdit: () => _showStopForm(existing: stop),
                              onDelete: () => _deleteStop(stop),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_stops',
        onPressed: () => _showStopForm(),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Stop'),
      ),
    );
  }
}

class _StopTile extends StatelessWidget {
  final StopModel stop;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _StopTile({
    required this.stop,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.primaryLight,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.stops_rounded, color: AppColors.primary, size: 22),
      ),
      title: Text(
        stop.name,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 15,
          color: AppColors.textDark,
        ),
      ),
      subtitle: stop.lat != null && stop.lng != null
          ? Text(
              '${stop.lat!.toStringAsFixed(3)}°N, ${stop.lng!.toStringAsFixed(3)}°E',
              style: const TextStyle(fontSize: 12, color: AppColors.textHint),
            )
          : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit_rounded, size: 18),
            color: AppColors.textSecondary,
            onPressed: onEdit,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, size: 18),
            color: AppColors.error,
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}
