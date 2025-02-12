import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:faker/faker.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CarouselData {
  final String title;
  final String subtitle;
  final double prix; // Utilisez double au lieu de float8
  final String imageUrl;
  final String webUrl;
  final DateTime created_at;

  CarouselData({
    required this.title,
    required this.subtitle,
    required this.prix,
    required this.imageUrl,
    required this.webUrl,
    required this.created_at,
  });

  // Conversion du modèle en Map pour insertion dans Supabase
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'subtitle': subtitle,
      'prix': prix, // Converti en nombre
      'imageUrl': imageUrl,
      'webUrl': webUrl, // Assurez-vous que cette colonne existe dans Supabase
      'created_at': created_at.toIso8601String(), // Format ISO pour DateTime
    };
  }

  // Conversion d'une Map Supabase en objet CarouselData
  factory CarouselData.fromMap(Map<String, dynamic> map) {
    return CarouselData(
      title: map['title'] ?? '',
      subtitle: map['subtitle'] ?? '',
      prix: (map['prix'] as num?)?.toDouble() ?? 0.0,
      // Conversion en double
      imageUrl: map['imageUrl'] ?? '',
      webUrl: map['webUrl'] ?? '',
      // Assurez-vous que cette colonne existe
      created_at: DateTime.tryParse(map['created_at'] ?? '') ?? DateTime.now(),
      // Convertir le String en DateTime
    );
  }
}

// Bouton pour ajouter des données à Supabase
class AddCarouselButton extends StatelessWidget {
  final TextEditingController titleController;
  final TextEditingController subtitleController;
  final TextEditingController imageUrlController;
  final TextEditingController webUrlController;
  final TextEditingController prixController; // Nouveau contrôle pour le prix

  const AddCarouselButton({
    Key? key,
    required this.titleController,
    required this.subtitleController,
    required this.imageUrlController,
    required this.webUrlController,
    required this.prixController, // Ajout du contrôle pour le prix
  }) : super(key: key);

  // Méthode pour ajouter les données à Supabase
  Future<void> _addToSupabase(BuildContext context) async {
    try {
      // Créer un objet CarouselData avec les valeurs actuelles des contrôleurs
      final carouselItem = CarouselData(
        title: titleController.text.trim(),
        subtitle: subtitleController.text.trim(),
        prix: double.tryParse(prixController.text.trim()) ?? 0.0,
        // Conversion en double
        imageUrl: imageUrlController.text.trim(),
        webUrl: webUrlController.text.trim(),
        created_at: DateTime.now(), // Horodatage automatique
      );

      // Ajouter les données à Supabase
      await Supabase.instance.client
          .from('annonces')
          .insert(carouselItem.toMap());

      // Afficher un message de succès
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Données ajoutées avec succès !')),
      );

      // Réinitialiser les champs du formulaire
      titleController.clear();
      subtitleController.clear();
      imageUrlController.clear();
      webUrlController.clear();
      prixController.clear(); // Réinitialisation du champ prix
    } catch (e) {
      // Afficher un message d'erreur en cas de problème
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur : $e')),
      );
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        ElevatedButton(
          onPressed: () => _addToSupabase(context),
          child: const Text('Ajouter à BD'),
        ),
        ElevatedButton(
          onPressed: () => insertMockData(),
          child: const Text('Fake Mock'),
        ),
      ],
    );
  }

  Future<void> insertMockData() async {
    // Initialisation du faker
    final faker = Faker();
    final random = Random();

    try {
      print('Début de la génération des données...');

      // Génération de 20 annonces sans inclure l'ID
      List<Map<String, dynamic>> annonces = [];
      for (int i = 1; i <= 20; i++) {
        final title = faker.lorem.sentence(); // Titre aléatoire
        final subtitle = faker.lorem.words(3).join(' '); // Sous-titre aléatoire
        final prix =
            random.nextInt(1000) + 100; // Prix aléatoire entre 100 et 1099 €
        final imageUrl =
            'https://picsum.photos/500/400?random=$i.webp'; // URL d'image aléatoire
        final webUrl =
            getPopularWebsiteUrl(random); // URL du site web aléatoire
        final createdAt = DateTime.now().toIso8601String(); // Horodatage actuel

        annonces.add({
          'title': title,
          'imageUrl': imageUrl,
          'webUrl': webUrl,
          'created_at': createdAt,
          'subtitle': subtitle,
          'prix': prix,
        });

        print('Annonce générée : $i');
      }

      print(
          'Toutes les annonces ont été générées. Début de l\'insertion dans Supabase...');

      // Insertion des données dans Supabase
      final response = await Supabase.instance.client
          .from('annonces')
          .insert(annonces); // Ne pas inclure l'ID ici

      if (response != null) {
        print('Données insérées avec succès dans Supabase.');
        print('Réponse de Supabase : ${jsonEncode(response)}');
      } else {
        print(
            'Aucune donnée insérée. Vérifiez les permissions ou les erreurs.');
      }
    } catch (error) {
      print(
          'Une erreur est survenue lors de l\'insertion des données : $error');
    }
  }

// Fonction pour générer une URL de site web populaire aléatoire
  String getPopularWebsiteUrl(Random random) {
    final popularWebsites = [
      'https://www.google.com',
      'https://www.facebook.com',
      'https://www.amazon.com',
      'https://www.youtube.com',
      'https://www.twitter.com',
      'https://www.instagram.com',
      'https://www.wikipedia.org',
      'https://www.reddit.com',
      'https://www.stackoverflow.com',
      'https://www.github.com',
    ];
    return popularWebsites[random.nextInt(popularWebsites.length)];
  }
}

// Formulaire pour ajouter des éléments au carousel
class CarouselForm extends StatefulWidget {
  const CarouselForm({super.key});

  @override
  _CarouselFormState createState() => _CarouselFormState();
}

class _CarouselFormState extends State<CarouselForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _subtitleController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _webUrlController = TextEditingController();
  final _prixController =
      TextEditingController(); // Nouveau contrôle pour le prix

  @override
  void dispose() {
    // Nettoyer les contrôleurs lorsque le widget est supprimé
    _titleController.dispose();
    _subtitleController.dispose();
    _imageUrlController.dispose();
    _webUrlController.dispose();
    _prixController.dispose(); // Dispose du nouveau contrôle
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajouter un élément au carousel'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: 'Titre'),
                  validator: (value) => value!.isEmpty ? 'Champs requis' : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _subtitleController,
                  decoration: const InputDecoration(labelText: 'Sous-titre'),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _imageUrlController,
                  decoration:
                      const InputDecoration(labelText: 'URL de l\'image'),
                  validator: (value) => value!.isEmpty ? 'Champs requis' : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _prixController, // Champ pour le prix
                  decoration: const InputDecoration(labelText: 'Prix'),
                  keyboardType: TextInputType.number, // Clavier numérique
                  validator: (value) =>
                      value!.isEmpty || double.tryParse(value) == null
                          ? 'Veuillez entrer un prix valide'
                          : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _webUrlController,
                  decoration:
                      const InputDecoration(labelText: 'URL de destination'),
                  validator: (value) => value!.isEmpty ? 'Champs requis' : null,
                ),
                const SizedBox(height: 20),
                AddCarouselButton(
                  titleController: _titleController,
                  subtitleController: _subtitleController,
                  imageUrlController: _imageUrlController,
                  webUrlController: _webUrlController,
                  prixController:
                      _prixController, // Passage du contrôle pour le prix
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
