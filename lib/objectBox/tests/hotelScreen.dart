import 'dart:math';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class Reservation {
  final String clientName;
  final String roomName;
  final DateTime startDate;
  final DateTime endDate;
  final double pricePerNight;
  final String status;

  Reservation({
    required this.clientName,
    required this.roomName,
    required this.startDate,
    required this.endDate,
    this.pricePerNight = 0.0,
    this.status = "Confirmed",
  });
}

class HotelReservationChart extends StatefulWidget {
  final DateTime fromDate;
  final DateTime toDate;
  final List<Reservation> reservations;
  final List<String> roomNames;

  HotelReservationChart({
    required this.fromDate,
    required this.toDate,
    required this.reservations,
    required this.roomNames,
  });

  @override
  _HotelReservationChartState createState() => _HotelReservationChartState();
}

class _HotelReservationChartState extends State<HotelReservationChart> {
  final ScrollController _horizontalController = ScrollController();
  final ScrollController _verticalController = ScrollController();
  final ScrollController _headerHorizontalController = ScrollController();
  final ScrollController _roomNamesVerticalController = ScrollController();
  final double dayWidth = 40.0;
  final double roomHeight = 30.0;
  final double roomNameWidth = 80.0;
  bool _isDragging = false;
  Offset? _lastPosition;

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

  int get viewRange =>
      calculateNumberOfDaysBetween(widget.fromDate, widget.toDate);

  void _handleDragStart(Offset position) {
    _isDragging = true;
    _lastPosition = position;
  }

  void _handleDragEnd(Offset position) {
    _isDragging = false;
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
    }

    if (_verticalController.hasClients) {
      _verticalController.jumpTo(
        (_verticalController.offset - dy).clamp(
          0.0,
          _verticalController.position.maxScrollExtent,
        ),
      );
    }

    _lastPosition = position;
  }

  @override
  Widget build(BuildContext context) {
    final double totalWidth = dayWidth * viewRange + roomNameWidth;

    return Scaffold(
      appBar: AppBar(title: Text('Réservations')),
      body: MouseRegion(
        cursor:
            _isDragging ? SystemMouseCursors.grabbing : SystemMouseCursors.grab,
        child: Listener(
          onPointerDown: (event) => _handleDragStart(event.position),
          onPointerUp: (event) => _handleDragEnd(event.position),
          onPointerMove: (event) => _handleDragUpdate(event.position),
          child: Column(
            children: [
              // En-tête avec scroll horizontal synchronisé
              SingleChildScrollView(
                controller: _headerHorizontalController,
                scrollDirection: Axis.horizontal,
                child: Container(
                  height: 80,
                  width: totalWidth,
                  child: Row(
                    children: [
                      Container(
                        width: roomNameWidth,
                        color: Colors.grey.shade200,
                        child: Center(
                          child: Text(
                            "Chambres",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      Container(
                        width: totalWidth - roomNameWidth,
                        color: Colors.grey.shade200,
                        child: Column(
                          children: [
                            buildMonthRow(),
                            buildDayRow(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Zone principale
              Expanded(
                child: Row(
                  children: [
                    // Colonne des noms de chambres avec scroll vertical synchronisé
                    SingleChildScrollView(
                      controller: _roomNamesVerticalController,
                      child: Container(
                        width: roomNameWidth,
                        child: Column(
                          children: widget.roomNames
                              .map((roomName) => Container(
                                    height: roomHeight,
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      border: Border.all(
                                          color: Colors.grey.shade300),
                                    ),
                                    child: Center(
                                      child: Text(
                                        roomName,
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ))
                              .toList(),
                        ),
                      ),
                    ),
                    // Zone des réservations avec scroll horizontal et vertical synchronisé
                    Expanded(
                      child: SingleChildScrollView(
                        controller: _roomNamesVerticalController,
                        // Synchronisation verticale
                        scrollDirection: Axis.horizontal,
                        child: SingleChildScrollView(
                          controller: _headerHorizontalController,
                          // Synchronisation horizontale
                          scrollDirection: Axis.horizontal,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: widget.roomNames.map((roomName) {
                              List<Reservation> roomReservations = widget
                                  .reservations
                                  .where((r) => r.roomName == roomName)
                                  .toList();
                              return buildRoomRow(roomReservations);
                            }).toList(),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  int calculateNumberOfDaysBetween(DateTime from, DateTime to) {
    return to.difference(from).inDays + 1;
  }

  double calculateDistanceToLeftBorder(DateTime startDate) {
    if (startDate.isBefore(widget.fromDate)) {
      return 0;
    } else {
      return startDate.difference(widget.fromDate).inDays * dayWidth;
    }
  }

  double calculateBarWidth(DateTime startDate, DateTime endDate) {
    if (startDate.isBefore(widget.fromDate) &&
        endDate.isBefore(widget.fromDate)) {
      return 0;
    } else if (startDate.isBefore(widget.fromDate)) {
      return (endDate.difference(widget.fromDate).inDays + 1) * dayWidth;
    } else if (endDate.isAfter(widget.toDate)) {
      return (widget.toDate.difference(startDate).inDays + 1) * dayWidth;
    } else {
      return (endDate.difference(startDate).inDays + 1) * dayWidth;
    }
  }

  Color randomColorGenerator() {
    var random = Random();
    return Color.fromRGBO(
      random.nextInt(256),
      random.nextInt(256),
      random.nextInt(256),
      0.75,
    );
  }

  Widget buildMonthRow() {
    // Définir la plage des mois et leur largeur
    List<Widget> months = [];
    List<int> daysInMonth = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
    int startMonth = 1; // Exemple : Janvier
    int startYear = 2024; // Exemple : Année de départ
    int displayedDays = 90; // Par exemple : 90 jours visibles
    int currentDay = 1;

    for (int i = 0; i < daysInMonth.length; i++) {
      int monthDays = daysInMonth[i];
      String monthName = "${_getMonthName(startMonth + i)} $startYear";

      // Vérifier combien de jours du mois sont visibles dans la plage
      int remainingDays = displayedDays - currentDay + 1;
      int visibleDaysInMonth =
          remainingDays < monthDays ? remainingDays : monthDays;

      // Si aucun jour visible dans ce mois, arrêter
      if (visibleDaysInMonth <= 0) break;

      // Ajouter le conteneur pour le mois
      months.add(Container(
        width: visibleDaysInMonth * dayWidth,
        height: 40,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Center(
          child: Text(
            monthName,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ));

      // Mettre à jour le compteur de jours affichés
      currentDay += visibleDaysInMonth;
    }

    return Row(children: months);
  }

  Widget buildDayRow() {
    List<Widget> days = [];
    DateTime currentDate = widget.fromDate;

    while (!currentDate.isAfter(widget.toDate)) {
      days.add(Container(
        width: dayWidth,
        height: 40,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "${currentDate.day}",
                style: TextStyle(fontSize: 12),
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

  Widget buildRoomRow(List<Reservation> roomReservations) {
    return Container(
      height: roomHeight,
      child: Stack(
        children: [
          Row(
            children: List.generate(
              viewRange,
              (index) => Container(
                width: dayWidth,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                ),
              ),
            ),
          ),
          ...roomReservations.map((reservation) {
            double leftOffset =
                calculateDistanceToLeftBorder(reservation.startDate);
            double width =
                calculateBarWidth(reservation.startDate, reservation.endDate);

            return Positioned(
              left: leftOffset,
              top: 5,
              child: Container(
                width: width,
                height: roomHeight - 10,
                decoration: BoxDecoration(
                  color: randomColorGenerator(),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Tooltip(
                  message: "${reservation.clientName} (${reservation.status})\n"
                      "Du: ${reservation.startDate.day}/${reservation.startDate.month}/${reservation.startDate.year}\n"
                      "Au: ${reservation.endDate.day}/${reservation.endDate.month}/${reservation.endDate.year}\n"
                      "\$${reservation.pricePerNight.toStringAsFixed(2)}/nuit",
                  child: Center(
                    child: Text(
                      reservation.clientName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 10, color: Colors.white),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  String _getMonthName(int month) {
    const monthNames = [
      "Janvier",
      "Février",
      "Mars",
      "Avril",
      "Mai",
      "Juin",
      "Juillet",
      "Août",
      "Septembre",
      "Octobre",
      "Novembre",
      "Décembre"
    ];
    return monthNames[month - 1];
  }

  String _getDayName(int weekday) {
    const dayNames = ["Lun", "Mar", "Mer", "Jeu", "Ven", "Sam", "Dim"];
    return dayNames[weekday - 1];
  }
}
