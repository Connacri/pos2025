import 'dart:math';

import 'package:calendar_timeline/calendar_timeline.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'hotelScreen.dart';

class CalendarTableWithDragging extends StatefulWidget {
  final DateTime fromDate;
  final DateTime toDate;
  final List<Reservation> reservations;
  final List<String> roomNames;

  CalendarTableWithDragging({
    required this.fromDate,
    required this.toDate,
    required this.reservations,
    required this.roomNames,
  });

  @override
  _CalendarTableWithDraggingState createState() =>
      _CalendarTableWithDraggingState();
}

class _CalendarTableWithDraggingState extends State<CalendarTableWithDragging> {
  final ScrollController _horizontalController = ScrollController();
  final ScrollController _verticalController = ScrollController();
  final ScrollController _headerHorizontalController = ScrollController();
  final ScrollController _roomNamesVerticalController = ScrollController();

  final double dayWidth = 40.0;
  final double roomHeight = 30.0;
  final double roomNameWidth = 80.0;
  bool _isDragging = false;
  Offset? _lastPosition;
  double heightLigne = 60;
  double widthLigne = 100;

  @override
  void initState() {
    super.initState();
    _headerHorizontalController.addListener(_syncScrollControllers);
    _roomNamesVerticalController.addListener(_syncScrollControllers);
  }

  @override
  void dispose() {
    _headerHorizontalController.removeListener(_syncScrollControllers);
    _roomNamesVerticalController.removeListener(_syncScrollControllers);
    _horizontalController.dispose();
    _verticalController.dispose();
    _headerHorizontalController.dispose();
    _roomNamesVerticalController.dispose();
    super.dispose();
  }

  void _syncScrollControllers() {
    if (_headerHorizontalController.hasClients) {
      _horizontalController.jumpTo(_headerHorizontalController.offset);
    }
    if (_roomNamesVerticalController.hasClients) {
      _verticalController.jumpTo(_roomNamesVerticalController.offset);
    }
  }

  void _handleDragStart(Offset position) {
    setState(() {
      _isDragging = true;
    });
    _lastPosition = position;
  }

  void _handleDragEnd(Offset position) {
    setState(() {
      _isDragging = false;
    });
    _lastPosition = null;
  }

  void _handleDragUpdate(Offset position) {
    if (!_isDragging || _lastPosition == null) return;

    final double dx = position.dx - _lastPosition!.dx;
    final double dy = position.dy - _lastPosition!.dy;

    if (_horizontalController.hasClients) {
      _horizontalController.jumpTo(
        (_horizontalController.offset - dx).clamp(
          0.0,
          _horizontalController.position.maxScrollExtent,
        ),
      );
      _headerHorizontalController.jumpTo(_horizontalController.offset);
    }

    if (_verticalController.hasClients) {
      _verticalController.jumpTo(
        (_verticalController.offset - dy).clamp(
          0.0,
          _verticalController.position.maxScrollExtent,
        ),
      );
      _roomNamesVerticalController.jumpTo(_verticalController.offset);
    }

    _lastPosition = position;
  }

  List<String> generateDates() {
    final List<String> dates = [];
    for (int i = 0;
        i <= widget.toDate.difference(widget.fromDate).inDays;
        i++) {
      final date = widget.fromDate.add(Duration(days: i));
      dates.add("${date.day}/${date.month}");
    }
    return dates;
  }

  @override
  Widget build(BuildContext context) {
    final dates = generateDates();
    final rooms = widget.roomNames;

    return Scaffold(
      appBar: AppBar(title: Text("Tableau Dragging")),
      body: MouseRegion(
        cursor:
            _isDragging ? SystemMouseCursors.grabbing : SystemMouseCursors.grab,
        child: Listener(
          onPointerDown: (event) => _handleDragStart(event.position),
          onPointerUp: (event) => _handleDragEnd(event.position),
          onPointerMove: (event) => _handleDragUpdate(event.position),
          child: Stack(
            children: [
              // Main Table Reservation
              MainTableReservation(
                  verticalController: _verticalController,
                  horizontalController: _horizontalController,
                  widget: widget,
                  dates: dates,
                  widthLigne: widthLigne,
                  heightLigne: heightLigne),
              // Fixed Horizontal Header Calendar
              FixedHeaderHorizontalCalendar(
                  widthLigne: widthLigne,
                  heightLigne: heightLigne,
                  fromDate: widget.fromDate,
                  toDate: widget.toDate,
                  dates: dates,
                  headerHorizontalController: _headerHorizontalController),
              FixedChambresDates(
                  widthLigne: widthLigne, heightLigne: heightLigne),
              // Fixed Vertical Rooms Column
              VerticalRoomsColumn(
                  heightLigne: heightLigne,
                  roomNamesVerticalController: _roomNamesVerticalController,
                  rooms: rooms,
                  widthLigne: widthLigne),
            ],
          ),
        ),
      ),
    );
  }
}

class FixedHeaderHorizontalCalendar3 extends StatelessWidget {
  const FixedHeaderHorizontalCalendar3({
    super.key,
    required this.widthLigne,
    required this.heightLigne,
    required this.fromDate,
    required this.toDate,
    required this.dates,
    required ScrollController headerHorizontalController,
  }) : _headerHorizontalController = headerHorizontalController;

  final ScrollController _headerHorizontalController;

  final double widthLigne;
  final double heightLigne;
  final DateTime fromDate;
  final DateTime toDate;
  final dates;

  List<String> generateDates() {
    final List<String> dates = [];
    for (int i = 0; i <= toDate.difference(fromDate).inDays; i++) {
      final date = fromDate.add(Duration(days: i));
      dates.add("${date.day}/${date.month}");
    }
    return dates;
  }

  @override
  Widget build(BuildContext context) {
    final dates = generateDates();
    return SingleChildScrollView(
      controller: _headerHorizontalController,
      scrollDirection: Axis.horizontal,
      child: Column(
        children: [
          buildMonthRow(),
          Row(
            children: dates.map((date) {
              return buildDayRow(date);
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget buildDayRow(String date) {
    List<Widget> days = [];
    DateTime currentDate = fromDate;

    while (!currentDate.isAfter(toDate)) {
      days.add(Container(
        width: widthLigne,
        height: heightLigne,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          color: Colors.grey.shade200,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                date,
                style: TextStyle(fontSize: 14),
              ),
              Text(
                "${currentDate.day}",
                style: TextStyle(fontSize: 14),
              ),
              Text(
                _getDayName(currentDate.weekday),
                style: TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ],
          ),
        ),
      ));
      currentDate = currentDate.add(Duration(days: 1));
    }

    return Row(children: days);
  }

  String _getDayName(int weekday) {
    const dayNames = ["Lun", "Mar", "Mer", "Jeu", "Ven", "Sam", "Dim"];
    return dayNames[weekday - 1];
  }

  Widget buildMonthRow() {
    List<Widget> months = [];

    DateTime currentDate = DateTime.now();
    int currentDay = currentDate.day;
    int currentMonth = currentDate.month;
    int currentYear = currentDate.year;

    int displayedDays = 90;
    int remainingDays = displayedDays;

    int getDaysInMonth(int year, int month) {
      return DateTime(year, month + 1, 0).day;
    }

    while (remainingDays > 0) {
      int daysInCurrentMonth = getDaysInMonth(currentYear, currentMonth);
      int visibleDaysInMonth = daysInCurrentMonth - currentDay + 1;

      if (visibleDaysInMonth > remainingDays) {
        visibleDaysInMonth = remainingDays;
      }

      String monthName = DateFormat('MMMM yyyy', 'fr_FR')
          .format(DateTime(currentYear, currentMonth));

      months.add(Container(
        width: visibleDaysInMonth * widthLigne,
        height: heightLigne / 2,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          color: Colors.amberAccent,
        ),
        child: Center(
          child: Text(
            monthName,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ));

      remainingDays -= visibleDaysInMonth;
      currentDay = 1;

      currentMonth++;
      if (currentMonth > 12) {
        currentMonth = 1;
        currentYear++;
      }
    }

    return Row(children: months);
  }
}

// class _CalendarTableWithDraggingState extends State<CalendarTableWithDragging> {
//   final ScrollController _horizontalController = ScrollController();
//   final ScrollController _verticalController = ScrollController();
//   final ScrollController _headerHorizontalController = ScrollController();
//   final ScrollController _roomNamesVerticalController = ScrollController();
//
//   final double dayWidth = 40.0;
//   final double roomHeight = 30.0;
//   final double roomNameWidth = 80.0;
//   bool _isDragging = false;
//   Offset? _lastPosition;
//   double heightLigne = 60;
//   double widthLigne = 100;
//
//   @override
//   void initState() {
//     super.initState();
//     _headerHorizontalController.addListener(_syncScrollControllers);
//     _roomNamesVerticalController.addListener(_syncScrollControllers);
//   }
//
//   @override
//   void dispose() {
//     _headerHorizontalController.removeListener(_syncScrollControllers);
//     _roomNamesVerticalController.removeListener(_syncScrollControllers);
//     _horizontalController.dispose();
//     _verticalController.dispose();
//     _headerHorizontalController.dispose();
//     _roomNamesVerticalController.dispose();
//     super.dispose();
//   }
//
//   void _syncScrollControllers() {
//     if (_headerHorizontalController.hasClients) {
//       _horizontalController.jumpTo(_headerHorizontalController.offset);
//     }
//     if (_roomNamesVerticalController.hasClients) {
//       _verticalController.jumpTo(_roomNamesVerticalController.offset);
//     }
//   }
//
//   void _handleDragStart(Offset position) {
//     setState(() {
//       _isDragging = true;
//     });
//     _lastPosition = position;
//   }
//
//   void _handleDragEnd(Offset position) {
//     setState(() {
//       _isDragging = false;
//     });
//     _lastPosition = null;
//   }
//
//   void _handleDragUpdate(Offset position) {
//     if (!_isDragging || _lastPosition == null) return;
//
//     final double dx = position.dx - _lastPosition!.dx;
//     final double dy = position.dy - _lastPosition!.dy;
//
//     if (_horizontalController.hasClients) {
//       _horizontalController.jumpTo(
//         (_horizontalController.offset - dx).clamp(
//           0.0,
//           _horizontalController.position.maxScrollExtent,
//         ),
//       );
//       _headerHorizontalController.jumpTo(_horizontalController.offset);
//     }
//
//     if (_verticalController.hasClients) {
//       _verticalController.jumpTo(
//         (_verticalController.offset - dy).clamp(
//           0.0,
//           _verticalController.position.maxScrollExtent,
//         ),
//       );
//       _roomNamesVerticalController.jumpTo(_verticalController.offset);
//     }
//
//     _lastPosition = position;
//   }
//
//   List<String> generateDates() {
//     final List<String> dates = [];
//     for (int i = 0;
//         i <= widget.toDate.difference(widget.fromDate).inDays;
//         i++) {
//       final date = widget.fromDate.add(Duration(days: i));
//       dates.add("${date.day}/${date.month}");
//     }
//     return dates;
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final dates = generateDates();
//     final rooms = widget.roomNames;
//
//     return Scaffold(
//       appBar: AppBar(title: Text("Tableau Dragging")),
//       body: MouseRegion(
//         cursor:
//             _isDragging ? SystemMouseCursors.grabbing : SystemMouseCursors.grab,
//         child: Listener(
//           onPointerDown: (event) => _handleDragStart(event.position),
//           onPointerUp: (event) => _handleDragEnd(event.position),
//           onPointerMove: (event) => _handleDragUpdate(event.position),
//           child: Stack(
//             children: [
//               // Main Table Reservation
//               MainTableReservation(
//                   verticalController: _verticalController,
//                   horizontalController: _horizontalController,
//                   widget: widget,
//                   dates: dates,
//                   widthLigne: widthLigne,
//                   heightLigne: heightLigne),
//               // Fixed Horizontal Header Calendar
//               FixedHeaderHorizontalCalendar(
//                   widthLigne: widthLigne,
//                   heightLigne: heightLigne,
//                   fromDate: widget.fromDate,
//                   toDate: widget.toDate,
//                   dates: dates,
//                   headerHorizontalController: _headerHorizontalController),
//               FixedChambresDates(
//                   widthLigne: widthLigne, heightLigne: heightLigne),
//               // Fixed Vertical Rooms Column
//               VerticalRoomsColumn(
//                   heightLigne: heightLigne,
//                   roomNamesVerticalController: _roomNamesVerticalController,
//                   rooms: rooms,
//                   widthLigne: widthLigne),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

class VerticalRoomsColumn extends StatelessWidget {
  const VerticalRoomsColumn({
    super.key,
    required this.heightLigne,
    required ScrollController roomNamesVerticalController,
    required this.rooms,
    required this.widthLigne,
  }) : _roomNamesVerticalController = roomNamesVerticalController;

  final double heightLigne;
  final ScrollController _roomNamesVerticalController;
  final List<String> rooms;
  final double widthLigne;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: heightLigne,
      left: 0,
      bottom: 0,
      child: SingleChildScrollView(
        controller: _roomNamesVerticalController,
        scrollDirection: Axis.vertical,
        child: Column(
          children: rooms.map((room) {
            return Container(
              width: widthLigne,
              height: heightLigne,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                color: Colors.grey.shade200,
              ),
              child: Text(
                'Room $room',
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class FixedChambresDates extends StatelessWidget {
  const FixedChambresDates({
    super.key,
    required this.widthLigne,
    required this.heightLigne,
  });

  final double widthLigne;
  final double heightLigne;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widthLigne,
      height: heightLigne,
      child: Center(
        child: Text(
          "Chambres/Date",
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.black54,
          ),
        ),
      ),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        color: Colors.grey.shade200,
      ),
    );
  }
}

class MainTableReservation extends StatelessWidget {
  const MainTableReservation({
    super.key,
    required ScrollController verticalController,
    required ScrollController horizontalController,
    required this.widget,
    required this.dates,
    required this.widthLigne,
    required this.heightLigne,
  })  : _verticalController = verticalController,
        _horizontalController = horizontalController;

  final ScrollController _verticalController;
  final ScrollController _horizontalController;
  final CalendarTableWithDragging widget;
  final List<String> dates;
  final double widthLigne;
  final double heightLigne;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: heightLigne, left: 100),
      child: SingleChildScrollView(
        controller: _verticalController,
        scrollDirection: Axis.vertical,
        child: SingleChildScrollView(
          controller: _horizontalController,
          scrollDirection: Axis.horizontal,
          child: Column(
            children: widget.roomNames.map((roomName) {
              return Row(
                children: dates.map((date) {
                  return Container(
                    width: widthLigne,
                    height: heightLigne,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Text("-"),
                  );
                }).toList(),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class FixedHeaderHorizontalCalendar extends StatelessWidget {
  const FixedHeaderHorizontalCalendar({
    super.key,
    required this.widthLigne,
    required this.heightLigne,
    required this.fromDate,
    required this.toDate,
    required this.dates,
    required ScrollController headerHorizontalController,
  }) : _headerHorizontalController = headerHorizontalController;

  final ScrollController _headerHorizontalController;

  final double widthLigne;
  final double heightLigne;
  final DateTime fromDate;
  final DateTime toDate;
  final dates;

  List<String> generateDates() {
    final List<String> dates = [];
    for (int i = 0; i <= toDate.difference(fromDate).inDays; i++) {
      final date = fromDate.add(Duration(days: i));
      dates.add("${date.day}/${date.month}");
    }
    return dates;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: _headerHorizontalController,
      scrollDirection: Axis.horizontal,
      child: Column(
        children: [
          buildMonthRow(),
          Container(
            color: Colors.red,
            child: Row(
              children: [
                ...dates.map((date) {
                  return buildDayRow(date);
                }).toList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildDayRow(date) {
    List<Widget> days = [];
    DateTime currentDate = fromDate;

    while (!currentDate.isAfter(toDate)) {
      days.add(Container(
        width: widthLigne,
        height: heightLigne,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          color: Colors.grey.shade200,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "${date}",
                style: TextStyle(fontSize: 14),
              ),
              Text(
                "${currentDate.day}",
                style: TextStyle(fontSize: 14),
              ),
              Text(
                _getDayName(currentDate.weekday),
                style: TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ],
          ),
        ),
      ));
      currentDate = currentDate.add(Duration(days: 1));
    }

    return Row(children: days);
  }

  String _getDayName(int weekday) {
    const dayNames = ["Lun", "Mar", "Mer", "Jeu", "Ven", "Sam", "Dim"];
    return dayNames[weekday - 1];
  }

  Widget buildMonthRow() {
    // Définir la plage des mois et leur largeur
    List<Widget> months = [];

    // Récupérer la date actuelle
    DateTime currentDate = DateTime.now();
    int currentDay = currentDate.day;
    int currentMonth = currentDate.month;
    int currentYear = currentDate.year;

    int displayedDays = 90; // Par exemple : 90 jours visibles
    int remainingDays = displayedDays;

    // Fonction pour obtenir le nombre de jours dans un mois, dynamique selon l'année
    int getDaysInMonth(int year, int month) {
      return DateTime(year, month + 1, 0).day;
    }

    // Parcourir les mois pour générer les conteneurs
    while (remainingDays > 0) {
      // Calculer les jours restants dans le mois actuel
      int daysInCurrentMonth = getDaysInMonth(currentYear, currentMonth);
      int visibleDaysInMonth = daysInCurrentMonth - currentDay + 1;

      // Si les jours visibles restants sont inférieurs aux jours restants dans le mois
      if (visibleDaysInMonth > remainingDays) {
        visibleDaysInMonth = remainingDays;
      }

      // Utiliser DateFormat pour obtenir le nom du mois en français
      String monthName = DateFormat('MMMM yyyy', 'fr_FR')
          .format(DateTime(currentYear, currentMonth));

      months.add(Container(
        width: visibleDaysInMonth * widthLigne,
        height: heightLigne / 2,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          color: Colors.amberAccent,
        ),
        child: Center(
          child: Text(
            monthName,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ));

      // Mettre à jour le compteur de jours restants
      remainingDays -= visibleDaysInMonth;
      currentDay = 1; // Réinitialiser au premier jour du mois suivant

      // Passer au mois suivant
      currentMonth++;
      if (currentMonth > 12) {
        currentMonth = 1;
        currentYear++;
      }
    }

    return Row(children: months);
  }
}

class FixedHeaderHorizontalCalendar2 extends StatelessWidget {
  const FixedHeaderHorizontalCalendar2({
    super.key,
    required this.widthLigne,
    required this.heightLigne,
    required this.fromDate,
    required this.toDate,
    required this.dates,
    required ScrollController headerHorizontalController,
  }) : _headerHorizontalController = headerHorizontalController;

  final ScrollController _headerHorizontalController;

  final double widthLigne;
  final double heightLigne;
  final DateTime fromDate;
  final DateTime toDate;
  final dates;

  List<String> generateDates() {
    final List<String> dates = [];
    for (int i = 0; i <= toDate.difference(fromDate).inDays; i++) {
      final date = fromDate.add(Duration(days: i));
      dates.add("${date.day}/${date.month}");
    }
    return dates;
  }

  @override
  Widget build(BuildContext context) {
    final dates = generateDates();
    return SingleChildScrollView(
      controller: _headerHorizontalController,
      scrollDirection: Axis.horizontal,
      child: Column(
        children: [
          buildMonthRow(),
          Row(
            children: dates.map((date) {
              return buildDayRow(date);
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget buildDayRow(String date) {
    List<Widget> days = [];
    DateTime currentDate = fromDate;

    while (!currentDate.isAfter(toDate)) {
      days.add(Container(
        width: widthLigne,
        height: heightLigne,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          color: Colors.grey.shade200,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                date,
                style: TextStyle(fontSize: 14),
              ),
              Text(
                "${currentDate.day}",
                style: TextStyle(fontSize: 14),
              ),
              Text(
                _getDayName(currentDate.weekday),
                style: TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ],
          ),
        ),
      ));
      currentDate = currentDate.add(Duration(days: 1));
    }

    return Row(children: days);
  }

  String _getDayName(int weekday) {
    const dayNames = ["Lun", "Mar", "Mer", "Jeu", "Ven", "Sam", "Dim"];
    return dayNames[weekday - 1];
  }

  Widget buildMonthRow() {
    List<Widget> months = [];

    DateTime currentDate = DateTime.now();
    int currentDay = currentDate.day;
    int currentMonth = currentDate.month;
    int currentYear = currentDate.year;

    int displayedDays = 90;
    int remainingDays = displayedDays;

    int getDaysInMonth(int year, int month) {
      return DateTime(year, month + 1, 0).day;
    }

    while (remainingDays > 0) {
      int daysInCurrentMonth = getDaysInMonth(currentYear, currentMonth);
      int visibleDaysInMonth = daysInCurrentMonth - currentDay + 1;

      if (visibleDaysInMonth > remainingDays) {
        visibleDaysInMonth = remainingDays;
      }

      String monthName = DateFormat('MMMM yyyy', 'fr_FR')
          .format(DateTime(currentYear, currentMonth));

      months.add(Container(
        width: visibleDaysInMonth * widthLigne,
        height: heightLigne / 2,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          color: Colors.amberAccent,
        ),
        child: Center(
          child: Text(
            monthName,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ));

      remainingDays -= visibleDaysInMonth;
      currentDay = 1;

      currentMonth++;
      if (currentMonth > 12) {
        currentMonth = 1;
        currentYear++;
      }
    }

    return Row(children: months);
  }
}
