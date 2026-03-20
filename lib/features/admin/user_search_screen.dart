import 'package:flutter/material.dart';
import '../../main.dart'; // To access apiService

class UserSearchScreen extends StatefulWidget {
  const UserSearchScreen({super.key});

  @override
  State<UserSearchScreen> createState() => _UserSearchScreenState();
}

class _UserSearchScreenState extends State<UserSearchScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  bool _isLoading = false;
  List<dynamic> _users = [];

  static const _roles = ['USER', 'ADMIN', 'SUPER_ADMIN'];

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    setState(() => _isLoading = true);
    try {
      final data = await apiService.searchUsers(_query);
      setState(() => _users = data);
    } catch (e) {
      debugPrint('Error fetching users: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onQueryChanged(String query) {
    setState(() => _query = query);
    _fetchUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Color _roleColor(String role, ThemeData theme) => switch (role) {
    'SUPER_ADMIN' => Colors.deepPurple,
    'ADMIN' => theme.colorScheme.tertiary,
    _ => theme.colorScheme.primary,
  };

  String _roleLabel(String role) => switch (role) {
    'SUPER_ADMIN' => 'Super Admin',
    'ADMIN' => 'Admin',
    _ => 'User',
  };

  void _showRoleDialog(Map<String, dynamic> user) {
    final role = user['role'] as String? ?? 'USER';
    if (role == 'SUPER_ADMIN') return; // Can't change super admin
    final assignableRoles = _roles.where((r) => r != 'SUPER_ADMIN').toList();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Change Role'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Set role for ${user['fullName']}:'),
              const SizedBox(height: 16),
              ...assignableRoles.map(
                (r) => RadioListTile<String>(
                  title: Text(_roleLabel(r)),
                  value: r,
                  groupValue: role,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  onChanged: (value) async {
                    Navigator.of(ctx).pop();
                    try {
                      await apiService.setRole(user['id'].toString(), value!);
                      _fetchUsers();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '${user['fullName']} is now ${_roleLabel(value)}',
                            ),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to update role: $e')),
                        );
                      }
                    }
                  },
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteDialog(Map<String, dynamic> user) {
    if (user['role'] == 'SUPER_ADMIN') return;

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Delete User'),
          content: Text(
            'Are you sure you want to permanently delete ${user['fullName']}? '
            'This action cannot be undone and will erase all of their historical library visit logs.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton.icon(
              onPressed: () async {
                Navigator.of(ctx).pop();
                setState(() => _isLoading = true);
                try {
                  await apiService.deleteUser(user['id'].toString());
                  _fetchUsers();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${user['fullName']} was deleted.')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    setState(() => _isLoading = false);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to delete user: $e')),
                    );
                  }
                }
              },
              icon: const Icon(Icons.delete_forever),
              label: const Text('Delete'),
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Theme.of(context).colorScheme.onError,
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isWide = MediaQuery.sizeOf(context).width >= 700;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          'User Management',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search by name or institutional email…',
            prefixIcon: const Icon(Icons.search),
            border: const OutlineInputBorder(),
            suffixIcon: _query.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      _onQueryChanged('');
                    },
                  )
                : null,
          ),
          onChanged: _onQueryChanged,
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 0,
          color: theme.colorScheme.surfaceContainerLow,
          clipBehavior: Clip.antiAlias,
          child: isWide ? _buildDataTable(theme) : _buildCardList(theme),
        ),
      ],
    );
  }

  Widget _buildDataTable(ThemeData theme) {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Name')),
          DataColumn(label: Text('Email')),
          DataColumn(label: Text('College / Office')),
          DataColumn(label: Text('Role')),
          DataColumn(label: Text('Status')),
          DataColumn(label: Text('Actions')),
        ],
        rows: _users
            .map(
              (u) {
                final role = u['role'] as String? ?? 'USER';
                final isBlocked = u['blocked'] as bool? ?? false;
                return DataRow(
                  cells: [
                    DataCell(Text(u['fullName'] ?? '')),
                    DataCell(Text(u['email'] ?? '')),
                    DataCell(Text(u['collegeOffice'] ?? 'N/A')),
                    DataCell(
                      InkWell(
                        onTap: role != 'SUPER_ADMIN'
                            ? () => _showRoleDialog(u)
                            : null,
                        borderRadius: BorderRadius.circular(8),
                        child: Chip(
                          avatar: Icon(
                            role == 'SUPER_ADMIN'
                                ? Icons.shield_rounded
                                : role == 'ADMIN'
                                ? Icons.admin_panel_settings
                                : Icons.person,
                            size: 16,
                            color: _roleColor(role, theme),
                          ),
                          label: Text(_roleLabel(role)),
                          backgroundColor: _roleColor(
                            role,
                            theme,
                          ).withAlpha(25),
                          labelStyle: TextStyle(
                            color: _roleColor(role, theme),
                            fontWeight: FontWeight.w600,
                          ),
                          side: BorderSide.none,
                        ),
                      ),
                    ),
                    DataCell(
                      Chip(
                        label: Text(isBlocked ? 'Blocked' : 'Active'),
                        backgroundColor: isBlocked
                            ? theme.colorScheme.errorContainer
                            : theme.colorScheme.primaryContainer,
                        labelStyle: TextStyle(
                          color: isBlocked
                              ? theme.colorScheme.error
                              : theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                        side: BorderSide.none,
                      ),
                    ),
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Switch(
                            value: !isBlocked,
                            onChanged: role == 'SUPER_ADMIN'
                                ? null
                                : (active) async {
                                    try {
                                      await apiService.setBlocked(u['id'].toString(), !active);
                                      _fetchUsers();
                                    } catch (e) {
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Failed to update block status: $e')),
                                        );
                                      }
                                    }
                                  },
                          ),
                          if (role != 'SUPER_ADMIN')
                            IconButton(
                              icon: const Icon(Icons.swap_vert_rounded),
                              tooltip: 'Change role',
                              onPressed: () => _showRoleDialog(u),
                            ),
                          if (role != 'SUPER_ADMIN')
                            IconButton(
                              icon: Icon(Icons.delete_outline, color: theme.colorScheme.error),
                              tooltip: 'Delete user',
                              onPressed: () => _showDeleteDialog(u),
                            ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            )
            .toList(),
      ),
    );
  }

  Widget _buildCardList(ThemeData theme) {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_users.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: Text('No users found.')),
      );
    }
    return Column(
      children: _users.map((u) {
        final role = u['role'] as String? ?? 'USER';
        final isBlocked = u['blocked'] as bool? ?? false;
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: isBlocked
                ? theme.colorScheme.errorContainer
                : _roleColor(role, theme).withAlpha(40),
            child: Icon(
              role == 'SUPER_ADMIN'
                  ? Icons.shield_rounded
                  : role == 'ADMIN'
                  ? Icons.admin_panel_settings
                  : isBlocked
                  ? Icons.block
                  : Icons.person,
              color: isBlocked
                  ? theme.colorScheme.error
                  : _roleColor(role, theme),
            ),
          ),
          title: Row(
            children: [
              Flexible(child: Text(u['fullName'] ?? '')),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _roleColor(role, theme).withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _roleLabel(role),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _roleColor(role, theme),
                  ),
                ),
              ),
            ],
          ),
          subtitle: Text('${u['email'] ?? ''}\n${u['collegeOffice'] ?? 'N/A'}'),
          isThreeLine: true,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (role != 'SUPER_ADMIN')
                IconButton(
                  icon: const Icon(Icons.swap_vert_rounded, size: 20),
                  tooltip: 'Change role',
                  onPressed: () => _showRoleDialog(u),
                ),
              Switch(
                value: !isBlocked,
                onChanged: role == 'SUPER_ADMIN'
                    ? null
                    : (active) async {
                        try {
                          await apiService.setBlocked(u['id'].toString(), !active);
                          _fetchUsers();
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Failed to update block status: $e')),
                            );
                          }
                        }
                      },
              ),
              if (role != 'SUPER_ADMIN')
                IconButton(
                  icon: Icon(Icons.delete_outline, color: theme.colorScheme.error, size: 20),
                  tooltip: 'Delete user',
                  onPressed: () => _showDeleteDialog(u),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
