import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:table_calendar/table_calendar.dart';

class ColaboradorCalendario extends StatefulWidget {
  final String userEmail;
  const ColaboradorCalendario({super.key, required this.userEmail});

  @override
  State<ColaboradorCalendario> createState() => _ColaboradorCalendarioState();
}

class _ColaboradorCalendarioState extends State<ColaboradorCalendario> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  Widget build(BuildContext context) {
    final primerDia = DateTime(_focusedDay.year, _focusedDay.month, 1);
    final ultimoDia = DateTime(_focusedDay.year, _focusedDay.month + 1, 0, 23, 59, 59);

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('actividades')
          .where('colaborador', isEqualTo: widget.userEmail)
          .where('fecha', isGreaterThanOrEqualTo: primerDia)
          .where('fecha', isLessThanOrEqualTo: ultimoDia)
          .orderBy('fecha') // IMPORTANTE: Firestore requiere orderBy para rangos
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        // Construye el mapa de eventos
        final eventos = <DateTime, List<Map<String, dynamic>>>{};
        for (var doc in snapshot.data!.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final fecha = (data['fecha'] as Timestamp).toDate();
          final dia = DateTime(fecha.year, fecha.month, fecha.day);
          eventos.putIfAbsent(dia, () => []).add(data);
        }

        List<Map<String, dynamic>> getEventosDelDia(DateTime day) {
          final dia = DateTime(day.year, day.month, day.day);
          return eventos[dia] ?? [];
        }

        return Column(
          children: [
            TableCalendar(
              locale: 'es_ES',
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2100, 12, 31),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) =>
                  _selectedDay != null &&
                  day.year == _selectedDay!.year &&
                  day.month == _selectedDay!.month &&
                  day.day == _selectedDay!.day,
              eventLoader: getEventosDelDia,
              calendarStyle: const CalendarStyle(
                markerDecoration: BoxDecoration(
                  color: Colors.indigo,
                  shape: BoxShape.circle,
                ),
              ),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              },
              onPageChanged: (focusedDay) {
                setState(() {
                  _focusedDay = focusedDay;
                  _selectedDay = null;
                });
              },
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _selectedDay == null
                  ? const Center(child: Text('Selecciona un día para ver actividades.'))
                  : getEventosDelDia(_selectedDay!).isEmpty
                      ? const Center(child: Text('No hay actividades para este día.'))
                      : ListView(
                          children: getEventosDelDia(_selectedDay!).map((actividad) {
                            final fecha = (actividad['fecha'] as Timestamp).toDate();
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                              child: ListTile(
                                title: Text(actividad['descripcion'] ?? 'Sin descripción'),
                                subtitle: Text(
                                  'Estado: ${actividad['estado'] ?? ''}\n'
                                  'Hora: ${fecha.hour.toString().padLeft(2, '0')}:${fecha.minute.toString().padLeft(2, '0')}',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
            ),
          ],
        );
      },
    );
  }
}