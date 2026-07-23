import 'package:flutter/material.dart';
import '../../../l10n/tr_extension.dart';
import '../../../supabase_config.dart';

class SuperAdminUsersScreen extends StatefulWidget {
  const SuperAdminUsersScreen({super.key});

  @override
  State<SuperAdminUsersScreen> createState() => _SuperAdminUsersScreenState();
}

class _SuperAdminUsersScreenState extends State<SuperAdminUsersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchCtrl = TextEditingController();

  List<Map<String, dynamic>> _allUsers = [];
  List<Map<String, dynamic>> _filteredUsers = [];
  bool _isLoading = true;
  String _selectedRole = 'all';

  final _roles = ['all', 'passenger', 'driver', 'conductor', 'operator_admin'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadUsers();
    _searchCtrl.addListener(_filterUsers);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      final data = await SupabaseConfig.client
          .from('users')
          .select(
            'id, name, email, phone, role, status, created_at, operator_id',
          )
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _allUsers = List<Map<String, dynamic>>.from(data);
          _filterUsers();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _filterUsers() {
    final query = _searchCtrl.text.toLowerCase();
    setState(() {
      _filteredUsers = _allUsers.where((u) {
        final matchesRole =
            _selectedRole == 'all' || u['role'] == _selectedRole;
        final matchesSearch =
            query.isEmpty ||
            (u['name'] as String? ?? '').toLowerCase().contains(query) ||
            (u['email'] as String? ?? '').toLowerCase().contains(query);
        return matchesRole && matchesSearch;
      }).toList();
    });
  }

  Future<void> _toggleUserStatus(String id, String current) async {
    final newStatus = current == 'active' ? 'suspended' : 'active';
    try {
      await SupabaseConfig.client
          .from('users')
          .update({'status': newStatus})
          .eq('id', id);
      _loadUsers();
      _showSnack(
        newStatus == 'active' ? context.tr.userActivated : context.tr.userSuspended,
      );
    } catch (e) {
      _showSnack(context.tr.failedToUpdate(e.toString()), isError: true);
    }
  }

  Future<void> _changeRole(String id, String currentRole) async {
    final roles = [
      'passenger',
      'driver',
      'conductor',
      'operator_admin',
      'super_admin',
    ];
    String? selected = currentRole;

    final result = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          context.tr.changeRole,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        content: StatefulBuilder(
          builder: (context, setDialogState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: roles
                .map(
                  (role) => RadioListTile<String>(
                    title: Text(
                      role
                          .replaceAll('_', ' ')
                          .split(' ')
                          .map((w) => w[0].toUpperCase() + w.substring(1))
                          .join(' '),
                      style: const TextStyle(fontSize: 14),
                    ),
                    value: role,
                    groupValue: selected,
                    activeColor: const Color(0xFF111827),
                    onChanged: (v) => setDialogState(() => selected = v),
                  ),
                )
                .toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              context.tr.cancel,
              style: const TextStyle(color: Color(0xFF6B7280)),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, selected),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF111827),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(context.tr.save),
          ),
        ],
      ),
    );

    if (result == null || result == currentRole) return;

    try {
      await SupabaseConfig.client
          .from('users')
          .update({'role': result})
          .eq('id', id);
      _loadUsers();
      _showSnack(context.tr.roleUpdated(result));
    } catch (e) {
      _showSnack(context.tr.failedToUpdate(e.toString()), isError: true);
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeUsers = _filteredUsers
        .where((u) => u['status'] == 'active')
        .toList();
    final suspendedUsers = _filteredUsers
        .where((u) => u['status'] != 'active')
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          // Search + filter
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Column(
              children: [
                // Search bar
                TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: context.tr.searchByNameOrEmail,
                    hintStyle: const TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 14,
                    ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: Color(0xFF6B7280),
                      size: 20,
                    ),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(
                              Icons.clear_rounded,
                              size: 18,
                              color: Color(0xFF6B7280),
                            ),
                            onPressed: () {
                              _searchCtrl.clear();
                              _filterUsers();
                            },
                          )
                        : null,
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
                      borderSide: const BorderSide(
                        color: Color(0xFF111827),
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
                const SizedBox(height: 10),

                // Role filter chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _roles.map((role) {
                      final isSelected = _selectedRole == role;
                      final label = role == 'all'
                          ? context.tr.allRole
                          : role
                                .replaceAll('_', ' ')
                                .split(' ')
                                .map((w) => w[0].toUpperCase() + w.substring(1))
                                .join(' ');
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () {
                            setState(() => _selectedRole = role);
                            _filterUsers();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFF111827)
                                  : const Color(0xFFF3F4F6),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              label,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? Colors.white
                                    : const Color(0xFF6B7280),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 4),

                // Tabs
                TabBar(
                  controller: _tabController,
                  indicatorColor: const Color(0xFF111827),
                  labelColor: const Color(0xFF111827),
                  unselectedLabelColor: const Color(0xFF6B7280),
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  tabs: [
                    Tab(text: context.tr.activeUsersTab(activeUsers.length)),
                    Tab(text: context.tr.suspendedUsersTab(suspendedUsers.length)),
                  ],
                ),
              ],
            ),
          ),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _UserList(
                        users: activeUsers,
                        onToggle: (id, status) => _toggleUserStatus(id, status),
                        onChangeRole: (id, role) => _changeRole(id, role),
                      ),
                      _UserList(
                        users: suspendedUsers,
                        onToggle: (id, status) => _toggleUserStatus(id, status),
                        onChangeRole: (id, role) => _changeRole(id, role),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

// ─── User List ────────────────────────────────────────────────────────────────

class _UserList extends StatelessWidget {
  final List<Map<String, dynamic>> users;
  final Function(String, String) onToggle;
  final Function(String, String) onChangeRole;

  const _UserList({
    required this.users,
    required this.onToggle,
    required this.onChangeRole,
  });

  @override
  Widget build(BuildContext context) {
    if (users.isEmpty) {
      return Center(
        child: Text(
          context.tr.noUsersFound,
          style: const TextStyle(color: Color(0xFF6B7280)),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: users.length,
      itemBuilder: (context, i) => _UserCard(
        user: users[i],
        onToggle: () => onToggle(users[i]['id'], users[i]['status']),
        onChangeRole: () => onChangeRole(users[i]['id'], users[i]['role']),
      ),
    );
  }
}

// ─── User Card ────────────────────────────────────────────────────────────────

class _UserCard extends StatelessWidget {
  final Map<String, dynamic> user;
  final VoidCallback onToggle;
  final VoidCallback onChangeRole;

  const _UserCard({
    required this.user,
    required this.onToggle,
    required this.onChangeRole,
  });

  Color _roleColor(String role) {
    switch (role) {
      case 'super_admin':
        return const Color(0xFF111827);
      case 'operator_admin':
        return const Color(0xFF059669);
      case 'driver':
        return const Color(0xFF1A73E8);
      case 'conductor':
        return const Color(0xFF7C3AED);
      default:
        return const Color(0xFF6B7280);
    }
  }

  @override
  Widget build(BuildContext context) {
    final role = user['role'] as String;
    final status = user['status'] as String;
    final isActive = status == 'active';
    final roleColor = _roleColor(role);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: roleColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                (user['name'] as String? ?? '?')[0].toUpperCase(),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: roleColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        user['name'] as String? ?? '—',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF111827),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // Role badge
                    GestureDetector(
                      onTap: onChangeRole,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: roleColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: roleColor.withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              role.replaceAll('_', ' '),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: roleColor,
                              ),
                            ),
                            const SizedBox(width: 3),
                            Icon(Icons.edit_rounded, size: 9, color: roleColor),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  user['email'] as String? ?? '—',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF6B7280),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: isActive
                            ? const Color(0xFFD1FAE5)
                            : const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isActive ? context.tr.active : context.tr.inactive,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: isActive
                              ? const Color(0xFF059669)
                              : const Color(0xFFEF4444),
                        ),
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: onToggle,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isActive
                              ? const Color(0xFFFEE2E2)
                              : const Color(0xFFD1FAE5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isActive ? context.tr.suspend : context.tr.activate,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isActive
                                ? const Color(0xFFEF4444)
                                : const Color(0xFF059669),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
