import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:kenzy/objectBox/pages/ClientListScreen.dart';
import 'package:kenzy/objectBox/pages/FournisseurListScreen.dart';
import 'package:kenzy/objectBox/tests/cruds.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../Entity.dart';

import '../MyProviders.dart';
import '../tests/hotel2.dart';
import '../tests/hotelScreen.dart';
import '../tests/hotelScreenFiable.dart';
import 'ProduitListScreen.dart';
import 'facturation/FacturePage.dart';
import 'facturation/textfacture.dart';

//////////////////////////////////////////////////test//////////////////////////////
class CarouselExample extends StatefulWidget {
  const CarouselExample({
    super.key,
    required this.provider,
  });

  final CommerceProvider provider;

  @override
  State<CarouselExample> createState() => _CarouselExampleState();
}

class _CarouselExampleState extends State<CarouselExample> {
  final CarouselController controller = CarouselController(initialItem: 1);

  final ScrollController _headerHorizontalController = ScrollController();

  double prixMin = 0;
  double prixMax = 0;
  List<String> imageUrls = []; // Liste pour stocker les URLs des images
  bool _isDragging = false;
  Offset? _lastPosition;

  @override
  void initState() {
    super.initState();
    _loadPrix();
    _loadImages();
    // _showInterstitialAd();
    controller.addListener(_syncScrollControllers);
  }

  @override
  void dispose() {
    _headerHorizontalController.removeListener(_syncScrollControllers);

    _headerHorizontalController.dispose();

    controller.dispose();
    super.dispose();
  }

  void _syncScrollControllers() {
    if (_headerHorizontalController.hasClients) {
      controller.jumpTo(_headerHorizontalController.offset);
    }
  }

  Future<void> _savePrix() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('prixMin', prixMin);
    await prefs.setDouble('prixMax', prixMax);
  }

  Future<void> _loadPrix() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      prixMin = prefs.getDouble('prixMin') ?? 0.0;
      prixMax = prefs.getDouble('prixMax') ?? 0.0;
    });
  }

  void _ouvrirDialogAjustementPrix(BuildContext context) {
    double nouveauPrixMin = prixMin;
    double nouveauPrixMax = prixMax;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Ajuster les prix'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: InputDecoration(labelText: 'Prix minimum'),
                keyboardType: TextInputType.number,
                onChanged: (value) =>
                    nouveauPrixMin = double.tryParse(value) ?? nouveauPrixMin,
              ),
              TextField(
                decoration: InputDecoration(labelText: 'Prix maximum'),
                keyboardType: TextInputType.number,
                onChanged: (value) =>
                    nouveauPrixMax = double.tryParse(value) ?? nouveauPrixMax,
              ),
            ],
          ),
          actions: [
            TextButton(
              child: Text('Annuler'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text('Valider'),
              onPressed: () {
                setState(() {
                  prixMin = nouveauPrixMin;
                  prixMax = nouveauPrixMax;
                });
                _savePrix(); // Sauvegarder les nouvelles valeurs
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // Fonction pour charger les images depuis Supabase Storage
  Future<void> _loadImages() async {
    final supabase = Supabase.instance.client;

    try {
      // Accéder au bucket où les images sont stockées
      final storage = supabase.storage
          .from('images'); // Remplacez 'images' par le nom de votre bucket

      // Récupérer la liste des fichiers dans le bucket
      final List<String> urls = [];
      final files = await storage.list();

      for (var file in files) {
        // Récupérer l'URL du fichier
        final fileUrl = await storage.getPublicUrl(file.name);
        urls.add(fileUrl);
      }
// Mélanger la liste des URLs
      urls.shuffle(Random());
      setState(() {
        imageUrls = urls; // Mettre à jour l'état avec les URLs récupérées
      });
    } catch (e) {
      print('Erreur lors du chargement des images : $e');
    }
  }

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

    if (controller.hasClients) {
      controller.jumpTo(
        (controller.offset - dx).clamp(
          0.0,
          controller.position.maxScrollExtent,
        ),
      );
    }

    _lastPosition = position;
  }

  @override
  Widget build(BuildContext context) {
    final double height = MediaQuery.sizeOf(context).height;
    int totalProduits = widget.provider.getTotalProduits();
    List<String> roomNumbers =
        generateRoomNumbers(1, 20, ["111", "102", "313"]);
    List<Produit> produitsFiltres =
        widget.provider.getProduitsBetweenPrices(prixMin, prixMax);
    // var produitsLowStock = produitProvider.getProduitsLowStock(5.0);
    // var produitsLowStock0 = produitProvider.getProduitsLowStock(0.0);
    return Center(
      child: ListView(
        children: <Widget>[
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: height / 2),
            child: MouseRegion(
              cursor: _isDragging
                  ? SystemMouseCursors.grabbing
                  : SystemMouseCursors.grab,
              child: Listener(
                onPointerDown: (event) => _handleDragStart(event.position),
                onPointerUp: (event) => _handleDragEnd(event.position),
                onPointerMove: (event) => _handleDragUpdate(event.position),
                child: CarouselView(
                    onTap: (index) {
                      // Action à réaliser lorsque l'élément est cliqué
                      if (index == 0) {
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (context) => FacturePageTest(),
                          //   ProduitListScreen(),
                        ));
                      } else if (index == 1) {
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (context) => ClientListScreen(),
                        ));
                      } else if (index == 2) {
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (context) => FournisseurListScreen(),
                        ));
                      } else if (index == 3) {
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (context) => UserListScreen(),
                        ));
                      }
                    },
                    controller: controller,
                    itemExtent: 330,
                    // Largeur de chaque item
                    shrinkExtent: 100,
                    // Largeur réduite lors du défilement
                    children: [
                      HeroLayoutCard(
                          title: widget.provider.users.length.toString(),
                          subTitle: 'Total Des Users',
                          image: imageUrls.elementAtOrNull(0) ??
                              'https://loremflickr.com/1920/1080'),
                      HeroLayoutCard(
                          title: widget.provider.users.length.toString(),
                          subTitle: 'Total Des Users',
                          image: imageUrls.elementAtOrNull(1) ??
                              'https://loremflickr.com/1920/1080'),
                      HeroLayoutCard(
                          title: widget.provider.users.length.toString(),
                          subTitle: 'Total Des Users',
                          image: imageUrls.elementAtOrNull(2) ??
                              'https://loremflickr.com/1920/1080'),
                      HeroLayoutCard(
                          title: widget.provider.users.length.toString(),
                          subTitle: 'Total Des Users',
                          image: imageUrls.elementAtOrNull(3) ??
                              'https://loremflickr.com/1920/1080'),
                    ]
                    // ImageInfo.values.map((ImageInfo image) {
                    //   return HeroLayoutCard(imageInfo: image);
                    // }).toList(),
                    ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              ElevatedButton(
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (ctx) =>
                            //     CalendarTableWithDragging(
                            //   fromDate: DateTime.now(),
                            //   toDate: DateTime.now().add(Duration(days: 30)),
                            // ),
                            HotelReservationChart(
                          fromDate: DateTime(2024, 1, 1),
                          toDate: DateTime(2024, 12, 31),
                          roomNames: roomNumbers,
                          reservations: [
                            Reservation(
                              clientName: "John Doe",
                              roomName: "101",
                              startDate: DateTime(2024, 1, 5),
                              endDate: DateTime(2024, 1, 9),
                              pricePerNight: 100.0,
                              status: "Confirmed",
                            ),
                            Reservation(
                              clientName: "Jane Smith",
                              roomName: "102",
                              startDate: DateTime(2024, 2, 4),
                              endDate: DateTime(2024, 2, 5),
                              pricePerNight: 150.0,
                              status: "Checked In",
                            ),
                            Reservation(
                              clientName: "John Doe",
                              roomName: "103",
                              startDate: DateTime(2024, 2, 1),
                              endDate: DateTime(2024, 2, 5),
                              pricePerNight: 100.0,
                              status: "Confirmed",
                            ),
                            Reservation(
                              clientName: "Jane Smith",
                              roomName: "104",
                              startDate: DateTime(2024, 2, 4),
                              endDate: DateTime(2024, 2, 5),
                              pricePerNight: 150.0,
                              status: "Checked In",
                            ),
                            Reservation(
                              clientName: "John Doe",
                              roomName: "105",
                              startDate: DateTime(2024, 1, 2),
                              endDate: DateTime(2024, 1, 5),
                              pricePerNight: 100.0,
                              status: "Confirmed",
                            ),
                            Reservation(
                              clientName: "Jane Smith",
                              roomName: "108",
                              startDate: DateTime(2024, 2, 4),
                              endDate: DateTime(2024, 2, 5),
                              pricePerNight: 150.0,
                              status: "Checked In",
                            ),
                          ],
                        ),
                      )),
                  child: Text('Hotel')),
              SizedBox(
                width: 20,
              ),
              ElevatedButton(
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (ctx) => CalendarTableWithDragging(
                          fromDate: DateTime.now(),
                          toDate: DateTime.now().add(Duration(days: 30)),
                          roomNames: roomNumbers,
                          reservations: [
                            Reservation(
                              clientName: "John Doe",
                              roomName: "101",
                              startDate: DateTime(2024, 1, 5),
                              endDate: DateTime(2024, 1, 9),
                              pricePerNight: 100.0,
                              status: "Confirmed",
                            ),
                            Reservation(
                              clientName: "Jane Smith",
                              roomName: "102",
                              startDate: DateTime(2024, 2, 4),
                              endDate: DateTime(2024, 2, 5),
                              pricePerNight: 150.0,
                              status: "Checked In",
                            ),
                            Reservation(
                              clientName: "John Doe",
                              roomName: "103",
                              startDate: DateTime(2024, 2, 1),
                              endDate: DateTime(2024, 2, 5),
                              pricePerNight: 100.0,
                              status: "Confirmed",
                            ),
                            Reservation(
                              clientName: "Jane Smith",
                              roomName: "104",
                              startDate: DateTime(2024, 2, 4),
                              endDate: DateTime(2024, 2, 5),
                              pricePerNight: 150.0,
                              status: "Checked In",
                            ),
                            Reservation(
                              clientName: "John Doe",
                              roomName: "105",
                              startDate: DateTime(2024, 1, 2),
                              endDate: DateTime(2024, 1, 5),
                              pricePerNight: 100.0,
                              status: "Confirmed",
                            ),
                            Reservation(
                              clientName: "Jane Smith",
                              roomName: "108",
                              startDate: DateTime(2024, 2, 4),
                              endDate: DateTime(2024, 2, 5),
                              pricePerNight: 150.0,
                              status: "Checked In",
                            ),
                          ],
                        ),
                      )),
                  child: Text('Hotel Fiable')),
            ],
          ),
          const Padding(
            padding: EdgeInsetsDirectional.only(top: 8.0, start: 8.0),
            child: Text('Multi-browse layout'),
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 50),
            child: CarouselView(
              itemExtent: 100, // Largeur de base pour chaque item
              shrinkExtent: 80, // Largeur réduite
              children: List<Widget>.generate(20, (int index) {
                return ColoredBox(
                  color: Colors.primaries[index % Colors.primaries.length]
                      .withOpacity(0.8),
                  child: const SizedBox.expand(),
                );
              }),
            ),
          ),
          const SizedBox(height: 20),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 200),
            child: CarouselView(
                itemExtent: 150, // Largeur de base pour chaque item
                shrinkExtent: 120, // Largeur réduite
                children: CardInfo.values.map((CardInfo info) {
                  return ColoredBox(
                    color: info.backgroundColor,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Icon(info.icon, color: info.color, size: 32.0),
                          Text(info.label,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                              overflow: TextOverflow.clip,
                              softWrap: false),
                        ],
                      ),
                    ),
                  );
                }).toList()),
          ),
          const SizedBox(height: 20),
          const Padding(
            padding: EdgeInsetsDirectional.only(top: 8.0, start: 8.0),
            child: Text('Uncontained layout'),
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 200),
            child: CarouselView(
              itemExtent: 330,
              shrinkExtent: 200,
              children: List<Widget>.generate(20, (int index) {
                return UncontainedLayoutCard(
                    index: index, label: 'Show $index');
              }),
            ),
          )
        ],
      ),
    );
  }
}

class HeroLayoutCard extends StatelessWidget {
  const HeroLayoutCard({
    super.key,
    required this.title,
    required this.subTitle,
    required this.image,
  });

  final String title;
  final String subTitle;
  final String image;

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.sizeOf(context).width;
    return Stack(
      alignment: AlignmentDirectional.bottomStart,
      children: <Widget>[
        Positioned.fill(
          child: ClipRect(
            child: OverflowBox(
              alignment: Alignment.center,
              maxWidth: double.infinity,
              maxHeight: double.infinity,
              child: ShaderMask(
                shaderCallback: (rect) {
                  return LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black87,
                    ],
                  ).createShader(Rect.fromLTRB(0, 0, rect.width, rect.height));
                },
                blendMode: BlendMode.srcATop,
                child: CachedNetworkImage(
                  imageUrl: image,
                  fit: BoxFit.cover, // L'image couvre la zone
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(18.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                title,
                overflow: TextOverflow.ellipsis,
                softWrap: false,
                style: Theme.of(context)
                    .textTheme
                    .headlineLarge
                    ?.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 10),
              Text(
                subTitle,
                overflow: TextOverflow.clip,
                softWrap: false,
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(color: Colors.white),
              )
            ],
          ),
        ),
      ],
    );
  }
}

class UncontainedLayoutCard extends StatelessWidget {
  const UncontainedLayoutCard({
    super.key,
    required this.index,
    required this.label,
  });

  final int index;
  final String label;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.primaries[index % Colors.primaries.length].withOpacity(0.5),
      child: Center(
        child: Text(
          label,
          style: const TextStyle(color: Colors.white, fontSize: 20),
          overflow: TextOverflow.clip,
          softWrap: false,
        ),
      ),
    );
  }
}

// class CarouselExample extends StatefulWidget {
//   const CarouselExample({super.key});
//
//   @override
//   State<CarouselExample1> createState() => _CarouselExample1State();
// }
//
// class _CarouselExample1State extends State<CarouselExample1> {
//   final CarouselController controller = CarouselController(initialItem: 1);
//
//   @override
//   void dispose() {
//     controller.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final double height = MediaQuery.sizeOf(context).height;
//
//     return ListView(
//       children: <Widget>[
//         ConstrainedBox(
//           constraints: BoxConstraints(maxHeight: height / 2),
//           child: CarouselView.weighted(
//             controller: controller,
//             itemSnapping: true,
//             flexWeights: const <int>[1, 7, 1],
//             children: ImageInfo.values.map((ImageInfo image) {
//               return HeroLayoutCard1(imageInfo: image);
//             }).toList(),
//           ),
//         ),
//         const SizedBox(height: 20),
//         const Padding(
//           padding: EdgeInsetsDirectional.only(top: 8.0, start: 8.0),
//           child: Text('Multi-browse layout'),
//         ),
//         ConstrainedBox(
//           constraints: const BoxConstraints(maxHeight: 50),
//           child: CarouselView.weighted(
//             flexWeights: const <int>[1, 2, 3, 2, 1],
//             consumeMaxWeight: false,
//             children: List<Widget>.generate(20, (int index) {
//               return ColoredBox(
//                 color: Colors.primaries[index % Colors.primaries.length]
//                     .withOpacity(0.8),
//                 child: const SizedBox.expand(),
//               );
//             }),
//           ),
//         ),
//         const SizedBox(height: 20),
//         ConstrainedBox(
//           constraints: const BoxConstraints(maxHeight: 200),
//           child: CarouselView.weighted(
//               flexWeights: const <int>[3, 3, 3, 2, 1],
//               consumeMaxWeight: false,
//               children: CardInfo.values.map((CardInfo info) {
//                 return ColoredBox(
//                   color: info.backgroundColor,
//                   child: Center(
//                     child: Column(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: <Widget>[
//                         Icon(info.icon, color: info.color, size: 32.0),
//                         Text(info.label,
//                             style: const TextStyle(fontWeight: FontWeight.bold),
//                             overflow: TextOverflow.clip,
//                             softWrap: false),
//                       ],
//                     ),
//                   ),
//                 );
//               }).toList()),
//         ),
//         const SizedBox(height: 20),
//         const Padding(
//           padding: EdgeInsetsDirectional.only(top: 8.0, start: 8.0),
//           child: Text('Uncontained layout'),
//         ),
//         ConstrainedBox(
//           constraints: const BoxConstraints(maxHeight: 200),
//           child: CarouselView(
//             itemExtent: 330,
//             shrinkExtent: 200,
//             children: List<Widget>.generate(20, (int index) {
//               return UncontainedLayoutCard(index: index, label: 'Show $index');
//             }),
//           ),
//         )
//       ],
//     );
//   }
// }

class HeroLayoutCard1 extends StatelessWidget {
  const HeroLayoutCard1({
    super.key,
    required this.imageInfo,
  });

  final ImageInfo imageInfo;

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.sizeOf(context).width;
    return Stack(
        alignment: AlignmentDirectional.bottomStart,
        children: <Widget>[
          ClipRect(
            child: OverflowBox(
              maxWidth: width * 7 / 8,
              minWidth: width * 7 / 8,
              child: Image(
                fit: BoxFit.cover,
                image: NetworkImage(
                    'https://flutter.github.io/assets-for-api-docs/assets/material/${imageInfo.url}'),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  imageInfo.title,
                  overflow: TextOverflow.clip,
                  softWrap: false,
                  style: Theme.of(context)
                      .textTheme
                      .headlineLarge
                      ?.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 10),
                Text(
                  imageInfo.subtitle,
                  overflow: TextOverflow.clip,
                  softWrap: false,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: Colors.white),
                )
              ],
            ),
          ),
        ]);
  }
}

class UncontainedLayoutCard1 extends StatelessWidget {
  const UncontainedLayoutCard1({
    super.key,
    required this.index,
    required this.label,
  });

  final int index;
  final String label;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.primaries[index % Colors.primaries.length].withOpacity(0.5),
      child: Center(
        child: Text(
          label,
          style: const TextStyle(color: Colors.white, fontSize: 20),
          overflow: TextOverflow.clip,
          softWrap: false,
        ),
      ),
    );
  }
}

enum CardInfo {
  camera('Cameras', Icons.video_call, Color(0xff2354C7), Color(0xffECEFFD)),
  lighting('Lighting', Icons.lightbulb, Color(0xff806C2A), Color(0xffFAEEDF)),
  climate('Climate', Icons.thermostat, Color(0xffA44D2A), Color(0xffFAEDE7)),
  wifi('Wifi', Icons.wifi, Color(0xff417345), Color(0xffE5F4E0)),
  media('Media', Icons.library_music, Color(0xff2556C8), Color(0xffECEFFD)),
  security(
      'Security', Icons.crisis_alert, Color(0xff794C01), Color(0xffFAEEDF)),
  safety(
      'Safety', Icons.medical_services, Color(0xff2251C5), Color(0xffECEFFD)),
  more('', Icons.add, Color(0xff201D1C), Color(0xffE3DFD8));

  const CardInfo(this.label, this.icon, this.color, this.backgroundColor);

  final String label;
  final IconData icon;
  final Color color;
  final Color backgroundColor;
}

enum ImageInfo {
  image0('The Flow', 'Sponsored | Season 1 Now Streaming',
      'content_based_color_scheme_1.png'),
  image1('Through the Pane', 'Sponsored | Season 1 Now Streaming',
      'content_based_color_scheme_2.png'),
  image2('Iridescence', 'Sponsored | Season 1 Now Streaming',
      'content_based_color_scheme_3.png'),
  image3('Sea Change', 'Sponsored | Season 1 Now Streaming',
      'content_based_color_scheme_4.png'),
  image4('Blue Symphony', 'Sponsored | Season 1 Now Streaming',
      'content_based_color_scheme_5.png'),
  image5('When It Rains', 'Sponsored | Season 1 Now Streaming',
      'content_based_color_scheme_6.png');

  const ImageInfo(this.title, this.subtitle, this.url);

  final String title;
  final String subtitle;
  final String url;
}

List<String> generateRoomNumbers(
    int totalFloors, int roomsPerFloor, List<String> excludedRooms) {
  List<String> roomNumbers = [];

  for (int floor = 1; floor <= totalFloors; floor++) {
    int currentRoom = 1;
    int generatedRooms = 0;

    while (generatedRooms < roomsPerFloor) {
      String roomNumber = "$floor${currentRoom.toString().padLeft(2, '0')}";
      if (!excludedRooms.contains(roomNumber)) {
        roomNumbers.add(roomNumber);
        generatedRooms++;
      }
      currentRoom++;
    }
  }

  return roomNumbers;
}
