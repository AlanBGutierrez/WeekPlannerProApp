import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:time_picker_spinner/time_picker_spinner.dart';

void main() {
  // Inicializa el formateo de fechas para el idioma español
  initializeDateFormatting('es').then((_) => runApp(MyApp()));
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WeekPlanPro',
      theme: ThemeData(
        primaryColor: Color.fromARGB(255, 255, 219, 87),
        scaffoldBackgroundColor: Color.fromARGB(255, 163, 186, 204),
      ),
      home: PlannerScreen(),
    );
  }
}

class PlannerScreen extends StatefulWidget {
  @override
  _PlannerScreenState createState() => _PlannerScreenState();
}

class _PlannerScreenState extends State<PlannerScreen> {
  // Estado del formato del calendario y las fechas seleccionadas
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  List<Event> _selectedEvents = [];

  // Estado para el manejo de eventos
  bool _isAllDayEvent = false;
  TimeOfDay _selectedStartTime = TimeOfDay.now();
  TimeOfDay _selectedEndTime = TimeOfDay.now();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Barra de aplicación personalizada con un logo
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(100.0),
        child: AppBar(
          flexibleSpace: Container(
            color: Color.fromARGB(255, 79, 107, 146),
            child: Center(
              child: Image.asset(
                "assets/logo_wpp.png",
                width: 150.0,
                height: 150.0,
              ),
            ),
          ),
        ),
      ),
      // Cuerpo de la aplicación con un ScrollView personalizado
      body: CustomScrollView(
        slivers: [
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                if (index == 0) {
                  // Widget TableCalendar para mostrar un calendario interactivo
                  final Color pastDaysColor = Color.fromARGB(255, 255, 128, 82);
                  final Color headerButtonColor =
                      Color.fromARGB(255, 245, 245, 245);

                  return TableCalendar(
                    calendarStyle: CalendarStyle(
                      todayDecoration: BoxDecoration(
                        color: Color.fromARGB(255, 137, 207, 235),
                        shape: BoxShape.circle,
                      ),
                      weekendTextStyle:
                          TextStyle(color: Color.fromARGB(255, 255, 128, 82)),
                      outsideDaysVisible: false,
                      outsideTextStyle: TextStyle(color: pastDaysColor),
                    ),
                    headerStyle: HeaderStyle(
                      titleCentered: true,
                      formatButtonVisible: true,
                      formatButtonDecoration: BoxDecoration(
                        color: headerButtonColor,
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      formatButtonTextStyle:
                          TextStyle(color: Color.fromARGB(255, 5, 5, 5)),
                    ),
                    locale: 'es',
                    firstDay: DateTime.utc(2010, 10, 16),
                    lastDay: DateTime.utc(2030, 3, 14),
                    focusedDay: _focusedDay,
                    selectedDayPredicate: (day) {
                      return isSameDay(_selectedDay, day);
                    },
                    onDaySelected: (selectedDay, focusedDay) {
                      setState(() {
                        _selectedDay = selectedDay;
                        _focusedDay = focusedDay;
                        _selectedEvents = _getEventsForDay(selectedDay);
                      });
                    },
                    calendarFormat: _calendarFormat,
                    onFormatChanged: (format) {
                      setState(() {
                        _calendarFormat = format;
                      });
                    },
                    onPageChanged: (focusedDay) {
                      _focusedDay = focusedDay;
                    },
                    eventLoader: (day) {
                      return _getEventsForDay(day);
                    },
                    availableCalendarFormats: {
                      CalendarFormat.month: 'Mes',
                      CalendarFormat.week: 'Semana',
                    },
                  );
                } else if (index == 1) {
                  // Botón elevado para agregar un nuevo evento
                  return ElevatedButton(
                    onPressed: () => _showAddEventDialog(context),
                    style: ElevatedButton.styleFrom(
                      primary: Color.fromARGB(255, 255, 189, 66),
                      textStyle: TextStyle(color: Colors.white),
                    ),
                    child: Text('Agregar Evento'),
                  );
                } else {
                  // Lista de eventos
                  var event = _selectedEvents[index - 2];
                  return ListTile(
                    title: Text(event.title),
                    subtitle: Text(
                      'Hora: ${DateFormat.Hm().format(event.startTime)} - ${DateFormat.Hm().format(event.endTime)}',
                    ),
                    trailing: IconButton(
                      icon: Icon(Icons.delete),
                      onPressed: () => _deleteEvent(event),
                    ),
                  );
                }
              },
              // La cantidad de elementos en la lista es la cantidad de eventos más 2 (calendario y botón)
              childCount: _selectedEvents.length + 2,
            ),
          ),
        ],
      ),
    );
  }

  // Función que devuelve la lista de eventos para un día específico
  List<Event> _getEventsForDay(DateTime day) {
    return events[day] ?? [];
  }

  // Función para mostrar el diálogo de agregar evento
  Future<void> _showAddEventDialog(BuildContext context) async {
    // Controlador de texto para el nombre del evento
    TextEditingController eventController = TextEditingController();

    return showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Agregar Evento'),
              content: Column(
                children: [
                  // Campo de texto para el nombre del evento
                  TextField(
                    controller: eventController,
                    decoration: InputDecoration(labelText: 'Nombre del Evento'),
                  ),
                  SizedBox(height: 10.0),
                  // Checkbox para eventos que duran todo el día
                  Row(
                    children: [
                      Text('Todo el día: '),
                      Checkbox(
                        value: _isAllDayEvent,
                        onChanged: (value) {
                          setState(() {
                            _isAllDayEvent = value!;
                            if (_isAllDayEvent) {
                              _selectedStartTime =
                                  TimeOfDay(hour: 0, minute: 0);
                              _selectedEndTime =
                                  TimeOfDay(hour: 23, minute: 59);
                            }
                          });
                        },
                      ),
                    ],
                  ),
                  Container(
                    height: _isAllDayEvent ? 0.0 : 600.0,
                    child: !_isAllDayEvent
                        ? SingleChildScrollView(
                            physics: NeverScrollableScrollPhysics(),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(height: 10.0),
                                Text('Hora de inicio:'),
                                // Selector de hora para la hora de inicio
                                _buildTimePicker(
                                  _selectedStartTime,
                                  (time) {
                                    setState(() {
                                      _selectedStartTime = time;
                                    });
                                  },
                                ),
                                SizedBox(height: 10.0),
                                Text('Hora de fin:'),
                                // Selector de hora para la hora de fin
                                _buildTimePicker(
                                  _selectedEndTime,
                                  (time) {
                                    setState(() {
                                      _selectedEndTime = time;
                                    });
                                  },
                                ),
                              ],
                            ),
                          )
                        : null,
                  ),
                ],
              ),
              actions: [
                // Botones para cancelar y agregar el evento
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('Cancelar'),
                ),
                TextButton(
                  onPressed: () {
                    // Agregar el evento a la lista de eventos
                    _addEvent(
                      eventController.text,
                      _isAllDayEvent
                          ? TimeOfDay(hour: 0, minute: 0)
                          : _selectedStartTime,
                      _isAllDayEvent
                          ? TimeOfDay(hour: 23, minute: 59)
                          : _selectedEndTime,
                      Colors.blue,
                    );

                    // Cerrar el diálogo
                    Navigator.of(context).pop();
                  },
                  child: Text('Agregar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Función para construir el selector de hora
  Widget _buildTimePicker(
      TimeOfDay time, void Function(TimeOfDay) onTimeChange) {
    return TimePickerSpinner(
      is24HourMode: true,
      normalTextStyle: TextStyle(fontSize: 18),
      highlightedTextStyle: TextStyle(fontSize: 22),
      spacing: 50,
      itemHeight: 80,
      isForce2Digits: true,
      onTimeChange: (time) {
        onTimeChange(time as TimeOfDay);
      },
    );
  }

  // Función para agregar un evento a la lista
  void _addEvent(String eventName, TimeOfDay startTime, TimeOfDay endTime,
      Color eventColor) {
    setState(() {
      // Crear objetos DateTime para la hora de inicio y fin
      DateTime startDateTime = DateTime(
        _selectedDay.year,
        _selectedDay.month,
        _selectedDay.day,
        startTime.hour,
        startTime.minute,
      );

      DateTime endDateTime = DateTime(
        _selectedDay.year,
        _selectedDay.month,
        _selectedDay.day,
        endTime.hour,
        endTime.minute,
      );

      // Agregar el evento a la lista de eventos
      _selectedEvents.add(Event(
        title: eventName,
        startTime: startDateTime,
        endTime: endDateTime,
        color: eventColor,
      ));

      // Actualizar el mapa de eventos con la nueva lista de eventos
      events[_selectedDay] = _selectedEvents;
    });
  }

  // Función para eliminar un evento de la lista
  void _deleteEvent(Event event) {
    setState(() {
      // Eliminar el evento de la lista de eventos
      _selectedEvents.remove(event);

      // Actualizar el mapa de eventos con la nueva lista de eventos
      events[_selectedDay] = _selectedEvents;
    });
  }
}

// Clase que representa un evento
class Event {
  final String title;
  final DateTime startTime;
  final DateTime endTime;
  final Color color;

  Event({
    required this.title,
    required this.startTime,
    required this.endTime,
    required this.color,
  });
}

// Mapa que contiene eventos de ejemplo para una fecha específica
final Map<DateTime, List<Event>> events = {
  DateTime.utc(2023, 12, 15): [
    Event(
      title: 'Evento 1',
      startTime: DateTime.utc(2023, 12, 15, 10, 0),
      endTime: DateTime.utc(2023, 12, 15, 12, 0),
      color: Colors.blue,
    ),
  ],
};
