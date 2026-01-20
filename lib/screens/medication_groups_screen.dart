import 'package:flutter/material.dart';

import '../models/medication_group.dart';
import '../services/database_helper.dart';
import 'medication_group_detail_screen.dart';

class MedicationGroupsScreen extends StatefulWidget {
  const MedicationGroupsScreen({super.key});

  @override
  State<MedicationGroupsScreen> createState() => _MedicationGroupsScreenState();
}

class _MedicationGroupsScreenState extends State<MedicationGroupsScreen> {
  Future<List<MedicationGroup>> _loadGroups() async {
    return DatabaseHelper.instance.getAllMedicationGroups(
      includeArchived: true,
    );
  }

  Future<void> _createGroup() async {
    final controller = TextEditingController();

    final name = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Nuevo grupo'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Nombre',
              hintText: 'Ej: Noche',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                final v = controller.text.trim();
                Navigator.pop(context, v.isEmpty ? null : v);
              },
              child: const Text('Crear'),
            ),
          ],
        );
      },
    );

    if (name == null || name.isEmpty) return;

    await DatabaseHelper.instance.createMedicationGroup(
      MedicationGroup(name: name),
    );
    if (!mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Grupos de medicación'),
        backgroundColor: colorScheme.inversePrimary,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createGroup,
        icon: const Icon(Icons.add),
        label: const Text('Agregar'),
      ),
      body: FutureBuilder<List<MedicationGroup>>(
        future: _loadGroups(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final groups = snapshot.data!;
          if (groups.isEmpty) {
            return const Center(child: Text('Todavía no tenés grupos'));
          }

          final active = groups.where((g) => !g.isArchived).toList();
          final archived = groups.where((g) => g.isArchived).toList();

          return ListView(
            children: [
              if (active.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    'Activos',
                    style: TextStyle(fontWeight: FontWeight.bold),
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
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    'Archivados',
                    style: TextStyle(fontWeight: FontWeight.bold),
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
