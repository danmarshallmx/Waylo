import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:waylo/features/groups/bloc/groups_bloc.dart';
import 'package:waylo/features/groups/bloc/groups_event.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _destController = TextEditingController(text: 'Liverpool');
  DateTime _startDate = DateTime.now().add(const Duration(days: 14));
  DateTime _endDate = DateTime.now().add(const Duration(days: 20));

  @override
  void dispose() {
    _nameController.dispose();
    _destController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      context.read<GroupsBloc>().add(
            CreateGroupEvent(
              name: _nameController.text.trim(),
              destination: _destController.text.trim(),
              startDate: _startDate,
              endDate: _endDate,
            ),
          );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formatter = DateFormat('dd/MM/yyyy');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear Grupo de Viaje Pro'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Planifica con hasta 5 amigos en tiempo real.',
                style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre del Viaje',
                  hintText: 'Ej. Liverpool Beatles & Football Tour',
                  prefixIcon: Icon(Icons.group_work_rounded),
                  border: OutlineInputBorder(),
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Ingresa un nombre' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _destController,
                decoration: const InputDecoration(
                  labelText: 'Destino',
                  prefixIcon: Icon(Icons.location_city_rounded),
                  border: OutlineInputBorder(),
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Ingresa el destino' : null,
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.date_range_rounded),
                title: const Text('Fechas del Viaje'),
                subtitle: Text('${formatter.format(_startDate)} - ${formatter.format(_endDate)}'),
                trailing: const Icon(Icons.edit_calendar_rounded),
                onTap: () async {
                  final picked = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                    initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
                  );
                  if (picked != null) {
                    setState(() {
                      _startDate = picked.start;
                      _endDate = picked.end;
                    });
                  }
                },
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.check_circle_rounded),
                label: const Text('Generar Grupo y Código de Invitación',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
