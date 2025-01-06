import 'package:cached_network_image/cached_network_image.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:objectbox/objectbox.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:permission_handler/permission_handler.dart';
import '../Entity.dart';
import '../classeObjectBox.dart';
import 'package:flutter/widgets.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:objectbox/objectbox.dart';

class SyncProductsPage extends StatelessWidget {
  SyncProductsPage({Key? key}) : super(key: key);
  final ObjectBox objectBox = ObjectBox(); // Create an instance of ObjectBox

  Future<void> onSyncProductsPressed(BuildContext context) async {
    try {
      await syncProductsWithOpenFoodFacts(objectBox.store);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Synchronisation réussie!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Synchroniser Produits'),
      ),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      NonFrenchProductsScreen(store: objectBox.store),
                )),
            child: const Text('FR Liste'),
          ),
          SizedBox(
            height: 20,
          ),
          ElevatedButton(
            onPressed: () => onSyncProductsPressed(context),
            child: const Text('Synchroniser avec Open Food Facts'),
          ),
          Expanded(
            child: ProductList(),
          ),
        ],
      ),
    );
  }
}

class ProductList extends StatelessWidget {
  final ObjectBox objectBox = ObjectBox(); // Create an instance of ObjectBox

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Produit>>(
      stream: _watchProducts(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final products = snapshot.data!;
        return ListView.builder(
          itemCount: products.length,
          itemBuilder: (context, index) {
            final product = products[index];
            return ListTile(
              leading: CircleAvatar(
                backgroundImage: CachedNetworkImageProvider(product.image!),
              ),
              title: Text(product.nom),
              subtitle: Text(
                product.description ?? '',
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
              trailing: Text(product.prixVente.toStringAsFixed(2),
                  style: TextStyle(fontSize: 20)),
            );
          },
        );
      },
    );
  }

  Stream<List<Produit>> _watchProducts() {
    return objectBox.store
        .box<Produit>()
        .query()
        .watch(triggerImmediately: true)
        .map((query) => query.find());
  }
}

Future<void> syncProductsWithOpenFoodFacts(Store store) async {
  final produitBox = store.box<Produit>();
  List<Produit> produits = produitBox.getAll();

  for (var produit in produits) {
    if (produit.qr != null && produit.qr!.isNotEmpty) {
      try {
        final productData = await fetchProductFromOpenFoodFacts(produit.qr!);
        if (productData != null) {
          bool isUpdated =
              await updateProductInObjectBox(store, produit, productData);
          if (isUpdated) {
            print('Produit ${produit.nom} mis à jour avec succès');
          } else {
            print('Aucune mise à jour nécessaire pour ${produit.nom}');
          }
        } else {
          print('Produit avec code-barre ${produit.qr} non trouvé');
        }
      } catch (e) {
        print('Erreur lors de la mise à jour du produit ${produit.qr}: $e');
      }
    }
  }
}

Future<Map<String, dynamic>?> fetchProductFromOpenFoodFacts(String qr) async {
  final url = 'https://world.openfoodfacts.org/api/v0/product/$qr.json';
  final response = await http.get(Uri.parse(url));

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    if (data['status'] == 1) {
      return data['product'];
    }
  }
  return null;
}

Future<String?> downloadImage(String imageUrl, String productName) async {
  try {
    final response = await http.get(Uri.parse(imageUrl));
    if (response.statusCode == 200) {
      Directory directory = await getApplicationDocumentsDirectory();
      String imagesPath = path.join(directory.path, 'ImagesProduits');
      final dir = Directory(imagesPath);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      String filePath = path.join(imagesPath, '$productName.jpg');
      File file = File(filePath);
      await file.writeAsBytes(response.bodyBytes);
      return filePath;
    }
  } catch (e) {
    print('Erreur lors du téléchargement de l\'image: $e');
  }
  return null;
}

Future<bool> updateProductInObjectBox(
    Store store, Produit produit, Map<String, dynamic> productData) async {
  final produitBox = store.box<Produit>();

  bool isUpdated = false;

  if (produit.nom != productData['product_name']) {
    produit.nom = productData['product_name'] ?? produit.nom;
    isUpdated = true;
  }

  if (produit.description != productData['ingredients_text']) {
    produit.description =
        productData['ingredients_text'] ?? produit.description;
    isUpdated = true;
  }

  if (productData['image_url'] != null) {
    String? imagePath = await downloadImage(
        productData['image_url'], produit.qr!.trim().replaceAll(' ', ''));
    if (imagePath != null && produit.image != imagePath) {
      produit.image = imagePath;
      isUpdated = true;
    }
  }

  if (isUpdated) {
    produitBox.put(
        produit); // Cette ligne met à jour le produit dans la base de données
  }

  return isUpdated;
}

// Future<void> replaceObjectBoxDatabase(BuildContext context) async {
//   try {
//     File? sourceFile;
//
//     // Vérifier la version d'Android
//     final deviceInfo = DeviceInfoPlugin();
//     final androidInfo = await deviceInfo.androidInfo;
//     final int sdkInt = androidInfo.version.sdkInt;
//
//     if (sdkInt >= 30) {
//       // Android 11 (API 30) et supérieur
//       // Utiliser FilePicker sans demander de permissions spécifiques
//       FilePickerResult? result = await FilePicker.platform.pickFiles();
//       if (result != null) {
//         sourceFile = File(result.files.single.path!);
//       }
//     } else {
//       // Versions antérieures : vérifier les permissions de stockage
//       if (!await _checkStoragePermissions()) {
//         _showPermissionDeniedDialog(context);
//         return;
//       }
//       // Utiliser le chemin spécifique pour OPPO Reno3 ou permettre à l'utilisateur de sélectionner
//       FilePickerResult? result = await FilePicker.platform.pickFiles();
//       if (result != null) {
//         sourceFile = File(result.files.single.path!);
//       }
//     }
//
//     if (sourceFile == null || !await sourceFile.exists()) {
//       throw Exception("Fichier de base de données introuvable");
//     }
//
//     // Chemin du fichier de base de données dans le répertoire de l'application
//     final appDir = await getApplicationDocumentsDirectory();
//     final dbPath = '${appDir.path}/objectbox/data.mdb';
//
//     // Vérifier l'intégrité du fichier (à implémenter)
//     if (!await _isValidDatabaseFile(sourceFile)) {
//       throw Exception(
//           "Le fichier sélectionné n'est pas une base de données valide");
//     }
//
//     // Fermer la connexion à la base de données existante
//     // objectbox.close();
//
//     // Copier le fichier
//     await sourceFile.copy(dbPath);
//
//     print("Base de données remplacée avec succès");
//
//     // Rouvrir la connexion à la base de données
//     // Réinitialiser l'instance ObjectBox
//   } catch (e) {
//     print("Erreur lors du remplacement de la base de données : $e");
//     _showErrorDialog(context, e.toString());
//   }
// }
//
// Future<bool> _checkStoragePermissions() async {
//   var status = await Permission.storage.request();
//   return status.isGranted;
// }
//
// void _showPermissionDeniedDialog(BuildContext context) {
//   showDialog(
//     context: context,
//     builder: (BuildContext context) => AlertDialog(
//       title: Text("Permission refusée"),
//       content: Text(
//           "L'accès au stockage est nécessaire pour cette opération. Veuillez accorder la permission dans les paramètres de l'application."),
//       actions: [
//         TextButton(
//           child: Text("Paramètres"),
//           onPressed: () => openAppSettings(),
//         ),
//         TextButton(
//           child: Text("Annuler"),
//           onPressed: () => Navigator.of(context).pop(),
//         ),
//       ],
//     ),
//   );
// }
//
// void _showErrorDialog(BuildContext context, String message) {
//   showDialog(
//     context: context,
//     builder: (BuildContext context) => AlertDialog(
//       title: Text("Erreur"),
//       content: Text(message),
//       actions: [
//         TextButton(
//           child: Text("OK"),
//           onPressed: () => Navigator.of(context).pop(),
//         ),
//       ],
//     ),
//   );
// }
//
// Future<bool> _isValidDatabaseFile(File file) async {
//   // Implémentez ici la logique de vérification de l'intégrité du fichier
//   // Par exemple, vérifiez la taille du fichier, la structure, etc.
//   return true; // Pour l'instant, on suppose que le fichier est toujours valide
// }
//
// Future<bool> _checkPermissions() async {
//   var status = await Permission.storage.status;
//   if (!status.isGranted) {
//     status = await Permission.storage.request();
//   }
//   return status.isGranted;
// }

// class DatabaseUpdater {
//   static Future<void> pickAndReplaceDatabase(BuildContext context) async {
//     try {
//       FilePickerResult? result = await FilePicker.platform.pickFiles(
//         type: FileType.custom,
//         allowedExtensions: [
//           'mdb'
//         ], // Assurez-vous que cette extension correspond à votre fichier de base de données
//         allowMultiple: false,
//       );
//
//       if (result != null) {
//         File sourceFile = File(result.files.single.path!);
//         await _replaceDatabase(sourceFile);
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Base de données mise à jour avec succès')),
//         );
//       }
//     } catch (e) {
//       print('Erreur lors de la mise à jour de la base de données: $e');
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//             content:
//                 Text('Erreur lors de la mise à jour de la base de données')),
//       );
//     }
//   }
//
//   static Future<void> _replaceDatabase(File sourceFile) async {
//     final appDir = await getApplicationDocumentsDirectory();
//     final dbPath = '${appDir.path}/objectbox/data.mdb';
//
//     // Vérifiez si le fichier source est valide
//     if (!await _isValidDatabaseFile(sourceFile)) {
//       throw Exception(
//           'Le fichier sélectionné n\'est pas une base de données valide');
//     }
//
//     // Fermer la connexion à la base de données existante
//     // Assurez-vous d'avoir une référence à votre instance ObjectBox
//     // objectbox.close();
//
//     // Copier le fichier
//     await sourceFile.copy(dbPath);
//
//     // Rouvrir la connexion à la base de données
//     // Réinitialisez votre instance ObjectBox ici
//   }
//
//   static Future<bool> _isValidDatabaseFile(File file) async {
//     // Implémentez ici la logique de vérification de l'intégrité du fichier
//     // Par exemple, vérifiez la taille du fichier, la structure, etc.
//     return true; // Pour l'instant, on suppose que le fichier est toujours valide
//   }
// }

class DatabaseUpdater {
  // Méthode principale pour choisir et remplacer la base de données
  static Future<void> pickAndReplaceDatabase(BuildContext context) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['mdb'],
        allowMultiple: false,
      );

      if (result != null) {
        File sourceFile = File(result.files.single.path!);

        // Vérification avancée de l'intégrité de la base de données
        if (!await _isValidDatabaseFile(sourceFile)) {
          throw Exception(
              'Le fichier sélectionné n\'est pas une base de données valide');
        }

        await _replaceDatabase(sourceFile, context);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Base de données mise à jour avec succès')),
        );
      }
    } catch (e) {
      print('Erreur lors de la mise à jour de la base de données: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('Erreur lors de la mise à jour de la base de données')),
      );
    }
  }

  // Méthode pour remplacer la base de données
  static Future<void> _replaceDatabase(
      File sourceFile, BuildContext context) async {
    try {
      // Vérifier et obtenir le chemin de la base de données de l'application
      final appDir = await getApplicationDocumentsDirectory();
      final dbPath = '${appDir.path}/objectbox/data.mdb';

      // Fermeture sécurisée de l'instance ObjectBox existante
      await _closeObjectBox();

      // Remplacer le fichier de la base de données
      await sourceFile.copy(dbPath);

      // Rouvrir et réinitialiser l'instance ObjectBox
      await _reopenObjectBox();

      print('Base de données remplacée avec succès');
    } catch (e) {
      print('Erreur lors du remplacement de la base de données : $e');
      _showErrorDialog(context, e.toString());
    }
  }

  // Méthode pour vérifier l'intégrité du fichier de base de données
  static Future<bool> _isValidDatabaseFile(File file) async {
    try {
      // Exemple d'une vérification simple sur la taille minimale
      if (await file.length() < 1024) {
        return false; // Le fichier est trop petit pour être une base de données valide
      }
      // D'autres vérifications avancées peuvent être ajoutées ici (structure, etc.)
      return true;
    } catch (e) {
      print('Erreur lors de la validation du fichier: $e');
      return false;
    }
  }

  // Méthode pour fermer ObjectBox
  static Future<void> _closeObjectBox() async {
    // Assurez-vous de bien fermer toutes les instances Box et ObjectBox
    // objectbox.close();
    print('Connexion ObjectBox fermée');
  }

  // Méthode pour rouvrir ObjectBox
  static Future<void> _reopenObjectBox() async {
    // Réinitialiser et rouvrir ObjectBox
    // objectbox = await ObjectBox.open();
    print('Connexion ObjectBox réinitialisée et rouverte');
  }

  // Boîte de dialogue d'erreur
  static void _showErrorDialog(BuildContext context, String errorMessage) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Erreur'),
          content: Text(errorMessage),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  // Vérification des permissions de stockage pour les versions d'Android antérieures
  static Future<bool> _checkStoragePermissions() async {
    if (await Permission.storage.request().isGranted) {
      return true;
    }
    return false;
  }
}

class NonFrenchProductsScreen extends StatefulWidget {
  final Store store;

  NonFrenchProductsScreen({required this.store});

  @override
  _NonFrenchProductsScreenState createState() =>
      _NonFrenchProductsScreenState();
}

class _NonFrenchProductsScreenState extends State<NonFrenchProductsScreen> {
  List<Produit> arabicProducts = [];

  @override
  void initState() {
    super.initState();
    _loadArabicProducts();
  }

  void _loadArabicProducts() {
    final produitBox = widget.store.box<Produit>();
    List<Produit> allProducts = produitBox.getAll();

    setState(() {
      arabicProducts = allProducts.where((product) {
        // Utiliser la fonction isLikelyArabic pour détecter les produits en arabe
        return isLikelyArabic(product.nom);
      }).toList();
    });
  }

  bool isLikelyArabic(String text) {
    // Regex pour les lettres arabes de base (sans les diacritiques)
    final arabicLetters = RegExp(r'[ءآأؤإئابةتثجحخدذرزسشصضطظعغفقكلمنهوىيـ]');

    // Compter le nombre de lettres arabes dans le texte
    int arabicLetterCount = arabicLetters.allMatches(text).length;

    // Compter le nombre total de caractères (en excluant les espaces)
    int totalCharCount = text.replaceAll(RegExp(r'\s'), '').length;

    // Calculer le ratio de lettres arabes
    double arabicRatio = arabicLetterCount / totalCharCount;

    // Considérer le texte comme probablement arabe si au moins 30% des lettres sont arabes
    return arabicRatio >= 0.3;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Produits non français'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Nombre total de produits non français : ${arabicProducts.length}',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: arabicProducts.length,
              itemBuilder: (context, index) {
                final product = arabicProducts[index];
                return ListTile(
                  title: Text(product.nom),
                  subtitle: Text(product.qr ?? 'Pas de code-barres'),
                  onTap: () {
                    // Ici, vous pouvez ajouter une action lors du tap sur un produit
                    // Par exemple, ouvrir un écran de détails du produit
                  },
                  trailing: Text(product.prixVente.toStringAsFixed(2)),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
