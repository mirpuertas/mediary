import 'package:flutter/material.dart';

import '../../../../models/medication_group.dart';
import '../../../../l10n/l10n.dart';
import '../../data/medication_groups_repository.dart';
import '../../../../ui/app_theme_tokens.dart';
import 'medication_group_detail_screen.dart';

class MedicationGroupsScreen extends StatefulWidget {
  const MedicationGroupsScreen({super.key});

  @override
  State<MedicationGroupsScreen> createState() => _MedicationGroupsScreenState();
}

class _MedicationGroupsScreenState extends State<MedicationGroupsScreen> {
  final MedicationGroupsRepository _repo = MedicationGroupsRepository();

  Future<List<MedicationGroup>> _loadGroups() async {
    return _repo.listGroups(includeArchived: true);
  }

  Future<void> _createGroup() async {
    final l10n = context.l10n;
    final controller = TextEditingController();

    final name = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.medicationGroupsNewGroupTitle),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(
              labelText: l10n.medicationGroupsNameLabel,
              hintText: l10n.medicationGroupsNameHint,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.commonCancel),
            ),
            ElevatedButton(
              onPressed: () {
                final v = controller.text.trim();
                Navigator.pop(context, v.isEmpty ? null : v);
              },
              child: Text(l10n.commonCreate),
            ),
          ],
        );
      },
    );

    if (name == null || name.isEmpty) return;

    await _repo.createGroup(MedicationGroup(name: name));
    if (!mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.medicationGroupsTitle),
        backgroundColor: context.surfaces.accentSurface,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createGroup,
        icon: const Icon(Icons.add),
        label: Text(l10n.commonAdd),
      ),
      body: FutureBuilder<List<MedicationGroup>>(
        future: _loadGroups(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final groups = snapshot.data!;
          if (groups.isEmpty) {
            return Center(child: Text(l10n.medicationGroupsEmpty));
          }

          final active = groups.where((g) => !g.isArchived).toList();
          final archived = groups.where((g) => g.isArchived).toList();

          return ListView(
            children: [
              if (active.isNotEmpty) ...[
                Padding(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    l10n.commonActive,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                ...active.map(
                  (g) => ListTile(
                    leading: const Icon(Icons.group),
                    title: Text(g.name),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              MedicationGroupDetailScreen(groupId: g.id!),
                        ),
                      );
                      if (!mounted) return;
                      setState(() {});
                    },
                  ),
                ),
              ],
              if (archived.isNotEmpty) ...[
                Padding(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    l10n.commonArchived,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                ...archived.map(
                  (g) => ListTile(
                    leading: const Icon(Icons.inventory_2_outlined),
                    title: Text(g.name),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              MedicationGroupDetailScreen(groupId: g.id!),
                        ),
                      );
                      if (!mounted) return;
                      setState(() {});
                    },
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
