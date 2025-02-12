import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:math';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:faker/faker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kenzy/objectBox/itemDetail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'AddCarouselButton.dart';

// Widget principal pour afficher le carousel
class CarouselBanner extends StatefulWidget {
  const CarouselBanner({super.key});

  @override
  State createState() => _CarouselBannerState();
}

class _CarouselBannerState extends State<CarouselBanner> {
  final CarouselController _scrollController =
      CarouselController(initialItem: 1);
  bool _isDragging = false;
  Offset? _lastPosition;
  Timer? _autoScrollTimer;

  @override
  void initState() {
    super.initState();
    _initializeCarouselData();
    _startAutoScroll();
  }

  static const double _scrollSpeed = 41;
  static const Duration _scrollDuration = Duration(milliseconds: 800);
  static const Duration _autoScrollInterval = Duration(seconds: 5);

  late Stream<List<Map<String, dynamic>>> _carouselDataStream;

  void _initializeCarouselData() {
    // Récupérer les données de la table 'annonces' depuis Supabase
    _carouselDataStream = Supabase.instance.client
        .from('annonces')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((event) => event.map((row) => row).toList());
  }

  void _startAutoScroll() {
    _autoScrollTimer?.cancel(); // Annule le timer précédent s'il existe
    _autoScrollTimer = Timer.periodic(_autoScrollInterval, (_) {
      if (!_isDragging && mounted && _scrollController.hasClients) {
        final double nextOffset = _scrollController.offset + _scrollSpeed;

        // Vérifie si l'offset suivant dépasse ou égale la position maximale
        if (nextOffset >= _scrollController.position.maxScrollExtent) {
          // Si c'est le cas, vérifie si nous sommes exactement à la fin
          if (_scrollController.offset ==
              _scrollController.position.maxScrollExtent) {
            // Si oui, on revient au début après avoir affiché la dernière photo
            _scrollController.animateTo(
              0.0,
              duration: _scrollDuration,
              curve: Curves.easeInOut,
            );
          } else {
            // Sinon, on avance jusqu'à la fin pour afficher la dernière photo
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: _scrollDuration,
              curve: Curves.easeInOut,
            );
          }
        } else {
          // Sinon, continuez le défilement normal
          _scrollController.animateTo(
            nextOffset,
            duration: _scrollDuration,
            curve: Curves.easeInOut,
          );
        }
      }
    });
  }

  void _handleDragStart(Offset position) {
    setState(() {
      _isDragging = true;
      _lastPosition = position;
    });
    _autoScrollTimer?.cancel();
  }

  void _handleDragEnd(Offset position) {
    setState(() {
      _isDragging = false;
      _lastPosition = null;
    });
    _startAutoScroll();
  }

  void _handleDragUpdate(Offset position) {
    if (!_isDragging || _lastPosition == null) return;
    final double dx = position.dx - _lastPosition!.dx;
    if (_scrollController.hasClients) {
      final double newOffset = (_scrollController.offset - dx)
          .clamp(0.0, _scrollController.position.maxScrollExtent);
      _scrollController.jumpTo(newOffset);
    }
    _lastPosition = position;
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _carouselDataStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Une erreur est survenue'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        final carouselItems =
            snapshot.data!.map((item) => CarouselData.fromMap(item)).toList();
        final double height = MediaQuery.of(context).size.height;
        return LayoutBuilder(
          builder: (context, constraints) {
            return MouseRegion(
              cursor: _isDragging
                  ? SystemMouseCursors.grabbing
                  : SystemMouseCursors.grab,
              child: Listener(
                onPointerDown: (event) => _handleDragStart(event.position),
                onPointerUp: (event) => _handleDragEnd(event.position),
                onPointerMove: (event) => _handleDragUpdate(event.position),
                child: CarouselView.weighted(
                  controller: _scrollController,
                  // Utilisez le ScrollController ici
                  // itemSnapping: true,
                  onTap: (int index) {
                    _launchUrl(carouselItems[index].webUrl);
                  },
                  flexWeights: const <int>[1, 7, 1],
                  // Poids flex pour les éléments
                  children: carouselItems.map((item) {
                    return HeroLayoutCard(carouselData: item);
                  }).toList(),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _launchUrl(String url) async {
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      throw 'Impossible d\'ouvrir $url';
    }
  }
}

// Widget pour chaque élément du carousel
class HeroLayoutCard extends StatelessWidget {
  const HeroLayoutCard({
    super.key,
    required this.carouselData,
  });

  final CarouselData carouselData;

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.sizeOf(context).width;

    return Stack(
      alignment: Alignment.bottomCenter,
      fit: StackFit.loose,
      children: [
        ClipRect(
          child: OverflowBox(
            maxWidth: width * 7 / 8,
            minWidth: width * 7 / 8,
            child: CachedNetworkImage(
              imageUrl: carouselData.imageUrl,
              fit: BoxFit.cover,
              errorWidget: (context, error, stackTrace) {
                return const Center(child: Icon(Icons.error_outline, size: 40));
              },
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.black.withOpacity(0.8),
              ],
              stops: [0.3, 1.0], // position du dégradé
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
                carouselData.title,
                overflow: TextOverflow.fade,
                maxLines: 3,
                softWrap: false,
                style: Theme.of(context)
                    .textTheme
                    .headlineLarge
                    ?.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 10),
              Text(
                carouselData.prix.toStringAsFixed(2),
                overflow: TextOverflow.clip,
                softWrap: false,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: Colors.white),
              ),
              Text(
                DateFormat('EEE dd MMM yyyy', 'fr')
                    .format(DateTime.parse(carouselData.created_at.toString())),
                overflow: TextOverflow.clip,
                softWrap: false,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Colors.white),
              )
            ],
          ),
        ),
      ],
    );
  }
}

class YouTubeVideoApp extends StatefulWidget {
  @override
  _YouTubeVideoAppState createState() => _YouTubeVideoAppState();
}

class _YouTubeVideoAppState extends State<YouTubeVideoApp> {
  late YoutubePlayerController _controller;
  String? _videoId;

  final TextEditingController _urlController = TextEditingController();

  // Fonction pour extraire l'ID de la vidéo YouTube à partir de l'URL
  String? extractVideoId(String url) {
    final regExp = RegExp(
        r'(?:youtube\.com\/(?:[^\/]+\/.+\/|(?:v|e)\/|.*[?&]v=)|youtu\.be\/)([^"&?\/ ]{11})');
    final match = regExp.firstMatch(url);
    return match?.group(1);
  }

  void _loadYouTubeVideo(String youtubeUrl) {
    final videoId = extractVideoId(youtubeUrl);

    if (videoId != null) {
      setState(() {
        _videoId = videoId;
        _controller = YoutubePlayerController(
          initialVideoId: videoId,
          flags: const YoutubePlayerFlags(
            autoPlay: true, // Lecture automatique
            mute: false, // Son activé
          ),
        );
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lien YouTube invalide')),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose(); // Libérer les ressources du contrôleur
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lecteur YouTube'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _urlController,
              decoration: const InputDecoration(
                labelText: 'Coller le lien YouTube',
                suffixIcon: Icon(Icons.paste),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final youtubeUrl = _urlController.text.trim();
              if (youtubeUrl.isNotEmpty) {
                _loadYouTubeVideo(youtubeUrl);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Veuillez entrer un lien YouTube valide')),
                );
              }
            },
            child: const Text('Charger la vidéo'),
          ),
          if (_videoId != null)
            Expanded(
              child: YoutubePlayerBuilder(
                player: YoutubePlayer(
                  controller: _controller,
                  showVideoProgressIndicator: true,
                  // Afficher l'indicateur de progression
                  progressColors: const ProgressBarColors(
                    playedColor: Colors.red,
                    handleColor: Colors.redAccent,
                  ),
                  onReady: () {
                    print('Lecteur YouTube prêt');
                  },
                ),
                builder: (context, player) {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      player, // Le lecteur YouTube
                      const SizedBox(height: 20),
                      const Text(
                          'Contrôles personnalisés peuvent être ajoutés ici'),
                    ],
                  );
                },
              ),
            )
          else
            const Center(child: Text('Coller un lien YouTube pour commencer')),
        ],
      ),
    );
  }
}
