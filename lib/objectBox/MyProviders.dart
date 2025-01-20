import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:faker/faker.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../objectbox.g.dart';
import 'Entity.dart';
import 'classeObjectBox.dart';
import 'package:objectbox/objectbox.dart';
import 'dart:isolate';

class ThemeProvider with ChangeNotifier {
  // Par défaut, le thème est clair
  bool _isDarkTheme = false;

  bool get isDarkTheme => _isDarkTheme;

  // Fonction pour changer le thème
  void toggleTheme() {
    _isDarkTheme = !_isDarkTheme;
    notifyListeners(); // Notifie les auditeurs que l'état a changé
  }
}

class CommerceProvider extends ChangeNotifier {
  final ObjectBox _objectBox;

  List<Produit> _produits = [];
  List<Fournisseur> _fournisseurs = [];
  List<User> _users = [];
  List<Approvisionnement> _approvisionnements = [];
  List<Approvisionnement> _approvisionnementTemporaire = [];
  List<Client> _clients = [];
  int _currentPage = 0;
  final int _pageSize = 100;
  bool _hasMoreProduits = true;
  bool _isLoading = false;

  List<Produit> get produits => _produits;

  List<Approvisionnement> get approvisionnements => _approvisionnements;

  List<Approvisionnement> get approvisionnementTemporaire =>
      _approvisionnementTemporaire;

  bool get hasMoreProduits => _hasMoreProduits;

  List<Fournisseur> get fournisseurs => _fournisseurs;

  List<User> get users => _users;

  bool get isLoading => _isLoading;

  List<Client> get clients => _clients;

  CommerceProvider(this._objectBox) {
    chargerProduits();
    _chargerFournisseurs();
    chargerUsers();
    getClientsFromBox();
  }

  Future<void> chargerProduits({bool reset = false}) async {
    // Empêche les appels multiples simultanés
    if (_isLoading) return;
    _isLoading = true;
    notifyListeners();

    // Réinitialiser la pagination si nécessaire
    if (reset) {
      _currentPage = 0;
      produits.clear();
    }

    // // Créer la requête pour récupérer les produits triés par ID descendant
    // final query = _objectBox.produitBox.query()
    //   ..order(Produit_.id, flags: Order.descending);
    //
    // // Récupérer tous les produits
    // final allProduits = await query.build().find();
    final query = _objectBox.produitBox
        .query()
        .order(Produit_.id, flags: Order.descending)
        .build()
      ..offset =
          _currentPage * _pageSize // Ignorer les produits des pages précédentes
      ..limit = _pageSize; // Limiter le nombre de produits récupérés

    final allProduits = await query.find();
    produits.addAll(allProduits);
    // Gérer la pagination
    final startIndex = _currentPage * _pageSize;
    final endIndex = startIndex + _pageSize;

    if (startIndex >= allProduits.length) {
      _hasMoreProduits = false;
    } else {
      // Sous-liste des nouveaux produits à ajouter
      final newProduits = allProduits.sublist(
        startIndex,
        endIndex > allProduits.length ? allProduits.length : endIndex,
      );

      // Ajouter les nouveaux produits sans restructurer
      produits.addAll(newProduits);
      _currentPage++;
      _hasMoreProduits = endIndex < allProduits.length;
    }

    _isLoading = false;
    notifyListeners();
  }

  void getClientsFromBox() {
    final box = ObjectBox().clientBox; // Utilisez le singleton ObjectBox
    _clients = box.getAll();
    notifyListeners();
  }

  Future<List<Produit>> rechercherProduits(String query,
      {int limit = 20}) async {
    final queryLower = query.toLowerCase();
    final idQuery = int.tryParse(query);
    final qrQuery = query;

    final qBuilder = _objectBox.produitBox.query(qrQuery !=
            null // la recherche se fait par id et moi je le veux pas qrcode
        ? Produit_.qr.equals(qrQuery) |
            Produit_.nom.contains(queryLower, caseSensitive: false) |
            Produit_.qr.contains(queryLower, caseSensitive: false)
        : Produit_.nom.contains(queryLower, caseSensitive: false));
    // Inverser l'ordre des résultats
    final results = qBuilder.build().find();
    return results.reversed.toList();
  }

  void resetProduits() {
    _produits.clear();
    _currentPage = 0;
    _hasMoreProduits = true;

    chargerProduits(reset: true);
  }

  void _chargerFournisseurs() {
    _fournisseurs = _objectBox.fournisseurBox.getAll().reversed.toList();
    notifyListeners();
  }

  void chargerUsers() {
    _users = _objectBox.userBox.getAll().reversed.toList();
    notifyListeners();
  }

  Produit? getProduitById(int id) {
    return _objectBox.produitBox.get(id);
  }

  // Future<Produit?> getProduitByQr(String qrCode) async {
  //   final query = _objectBox.produitBox.query(Produit_.qr.equals(qrCode));
  //   final produits = await query.build().find();
  //
  //   if (produits.isNotEmpty) {
  //     return produits.first;
  //   } else {
  //     return null;
  //   }
  // }
  Future<Produit?> getProduitByQr(String qrCode) async {
    // Vérifier si le QR code commence par '613' ou '1613' et le transformer si nécessaire
    if (qrCode.startsWith('1613')) {
      qrCode = '613' + qrCode.substring(4); // Remplace 1613 par 613
    }

    // Requête pour récupérer tous les produits
    final query = _objectBox.produitBox.query();

    // Récupérer tous les produits
    final produits = await query.build().find();

    // Chercher le produit avec le QR code spécifié
    for (var produit in produits) {
      // Convertir la chaîne QR en liste
      List<String> qrCodes = produit.qr!.split(','); // Séparer les QR codes

      // Vérifier si le QR code existe dans la liste
      if (qrCodes.contains(qrCode)) {
        return produit; // Retourner le produit si le QR code est trouvé
      }
    }

    return null; // Aucun produit trouvé avec le QR code donné
  }

  // Future<void> removeQRCodeFromProduit(int produitId, String qrCode) async {
  //   // Récupérer le produit par ID
  //   final produit = await getProduitById(produitId);
  //   if (produit != null) {
  //     // Convertir la chaîne QR en liste
  //     List<String> qrCodes = produit.qr!.split(',');
  //
  //     // Vérifier si le QR code existe et le supprimer
  //     if (qrCodes.contains(qrCode)) {
  //       qrCodes.remove(qrCode); // Supprimer le QR code
  //
  //       // Mettre à jour la chaîne QR du produit
  //       produit.qr = qrCodes.isNotEmpty
  //           ? qrCodes.join(',')
  //           : ''; // Rejoindre en une seule chaîne ou le définir à une chaîne vide
  //
  //       // Mettre à jour le produit dans ObjectBox ou votre base de données
  //       await _objectBox.produitBox.put(produit);
  //       chargerProduits(reset: true);
  //     } else {
  //       print('Le QR code $qrCode n\'existe pas dans la liste.');
  //     }
  //   } else {
  //     print('Produit non trouvé.');
  //   }
  // }
  Future<void> removeQRCodeFromProduit(int produitId, String qrCode) async {
    // Récupérer le produit par ID
    final produit = await getProduitById(produitId);

    if (produit != null) {
      // Convertir la chaîne QR en liste
      List<String> qrCodes = produit.qr?.split(',') ?? [];
      print(qrCodes);

      // Vérifier si le QR code existe et le supprimer
      if (qrCodes.contains(qrCode)) {
        qrCodes.remove(qrCode);

        // Mettre à jour la chaîne QR du produit
        String newQrValue = qrCodes.join(',');

        // Vérifier si la nouvelle valeur est vide, null ou ne contient que des espaces
        if (newQrValue.trim().isEmpty) {
          // Si vide, utiliser le nom du produit
          produit.qr = produit.nom + produit.id.toString();
        } else {
          produit.qr = newQrValue;
        }

        // Mettre à jour le produit dans ObjectBox
        await _objectBox.produitBox.put(produit);
        chargerProduits(reset: true);
      } else {
        print('Le QR code $qrCode n\'existe pas dans la liste.');
      }
    } else {
      print('Produit non trouvé.');
    }
  }

  List<Produit?> getProduitsForFournisseur(Fournisseur fournisseur) {
    // Récupérer le fournisseur à partir de l'ID
    final fournisseurBox = _objectBox.fournisseurBox.get(fournisseur.id);

    if (fournisseurBox == null) {
      return [];
    }

    // Récupérer tous les approvisionnements du fournisseur
    final approvisionnements = fournisseurBox.approvisionnements;

    // Extraire les produits uniques associés aux approvisionnements
    final produits = approvisionnements
        .map((approvisionnement) => approvisionnement.produit.target)
        .where((produit) => produit != null) // Filtrer les produits non-nuls
        .toSet() // Supprimer les doublons
        .toList();

    return produits.reversed.toList();
  }

  void ajouterProduit(
    Produit produit,
    List<Fournisseur> fournisseurs,
    List<Approvisionnement> approvisionnements,
  ) {
    // Mettre à jour ou ajouter les fournisseurs
    _ajouterOuMettreAJourFournisseurs(fournisseurs);

    // Lier Crud au produit
    // produit.crud.target = crudProduit;

    // Ajouter ou mettre à jour les approvisionnements
    //_objectBox.crud.put(crudProduit);
    final produitId = _objectBox.produitBox.put(produit);

    // Enregistrer chaque approvisionnement temporaire
    final boxApprovisionnement = _objectBox.approvisionnementBox;
    final boxFournisseur = _objectBox.fournisseurBox;
    final boxCrudApprovisionnement = _objectBox.crudBox;

    for (var approvisionnementTemp in _approvisionnementTemporaire) {
      // a. Vérifier ou créer le fournisseur
      Fournisseur fournisseur = _fournisseurs.firstWhere(
        (f) =>
            f.nom.toLowerCase() ==
            approvisionnementTemp.fournisseur.target!.nom.toLowerCase(),
        orElse: () => Fournisseur(
          nom: approvisionnementTemp.fournisseur.target!.nom,
          derniereModification: DateTime.now(),
        ),
      );

      if (fournisseur.id == 0) {
        // Nouveau fournisseur, l'enregistrer
        boxFournisseur.put(fournisseur);
        _fournisseurs.add(fournisseur);
      } else {
        // Si le fournisseur existe déjà, le récupérer de la boîte
        fournisseur = _objectBox.fournisseurBox.get(fournisseur.id)!;
      }

      // b. Enregistrer le Crud pour l'approvisionnement
      // boxCrudApprovisionnement.put(crudProduit);

      // c. Créer l'instance de l'approvisionnement
      Approvisionnement approvisionnement = Approvisionnement(
        quantite: approvisionnementTemp.quantite,
        prixAchat: approvisionnementTemp.prixAchat,
        datePeremption: approvisionnementTemp.datePeremption,
        derniereModification: DateTime.now(),
      );

      // Lier les relations
      // approvisionnement.crud.target = crudProduit;
      approvisionnement.fournisseur.target = fournisseur;
      approvisionnement.produit.targetId = produitId;

      // d. Enregistrer l'approvisionnement
      boxApprovisionnement.put(approvisionnement);
    }

    // Enregistrer les approvisionnements fournis
    for (var approvisionnement in approvisionnements) {
      if (!_approvisionnements.contains(approvisionnement)) {
        // Vérifier les doublons
        approvisionnement.produit.target = produit;
        _objectBox.approvisionnementBox.put(approvisionnement);
      }
    }

    // Sauvegarder le produit avec les relations
    _objectBox.produitBox.put(produit);

    // Recharger les produits et les fournisseurs après mise à jour
    chargerProduits(reset: true);
    _chargerFournisseurs();
  }

  //
  // void updateProduit(Produit produit) {
  //   _objectBox.produitBox.put(produit);
  //   chargerProduits(reset: true);
  // }

  void updateProduit(Produit updatedProduit) {
    // Vérifiez si le produit existe déjà
    final existingProduct = _objectBox.produitBox.get(updatedProduit.id);

    if (existingProduct == null) {
      throw Exception("Produit avec l'ID ${updatedProduit.id} n'existe pas.");
    }

    // Remplacer complètement les données du produit
    existingProduct
      ..nom = updatedProduit.nom
      ..description = updatedProduit.description
      ..qr = updatedProduit.qr?.trim() ?? ""
      ..prixVente = updatedProduit.prixVente
      ..image = updatedProduit.image
      ..prixVente = updatedProduit.prixVente
      ..pricePartielVente = updatedProduit.pricePartielVente
      ..qtyPartiel = updatedProduit.qtyPartiel
      ..derniereModification = DateTime.now();

    // Supprimer les anciens approvisionnements liés
    for (var appro in existingProduct.approvisionnements) {
      _objectBox.approvisionnementBox.remove(appro.id);
    }
    existingProduct.approvisionnements.clear();

    // Ajouter les nouveaux approvisionnements
    for (var approvisionnement in updatedProduit.approvisionnements) {
      // Sauvegarder chaque approvisionnement
      approvisionnement.produit.target = existingProduct;
      final approId = _objectBox.approvisionnementBox.put(approvisionnement);
      approvisionnement.id = approId;
      existingProduct.approvisionnements.add(approvisionnement);
    }

    // Sauvegarder le produit mis à jour
    _objectBox.produitBox.put(existingProduct);

    // Recharger les produits si nécessaire
    chargerProduits(reset: true);
  }

  void supprimerProduit(Produit produit) {
    _objectBox.produitBox.remove(produit.id);
    chargerProduits(reset: true);
    _chargerFournisseurs();
  }

  int getTotalProduits() {
    return _objectBox.produitBox.count();
  }

  int getTotalClientsCount() {
    return _objectBox.clientBox.count();
  }

  List<Produit> getProduitsBetweenPrices(double minPrice, double maxPrice) {
    final query = _objectBox.produitBox
        .query(Produit_.prixVente.between(minPrice, maxPrice));
    return query.build().find();
  }

  void addFournisseur(Fournisseur fournisseur) {
    _objectBox.fournisseurBox.put(fournisseur);
    chargerProduits(reset: true);
    _chargerFournisseurs();
    notifyListeners();
  }

  void updateFournisseur(int id, Fournisseur updatedFournisseur) {
    var fournisseurIndex = _fournisseurs.indexWhere((f) => f.id == id);
    if (fournisseurIndex != -1) {
      updatedFournisseur.id = id;
      _objectBox.fournisseurBox.put(updatedFournisseur);
      _fournisseurs[fournisseurIndex] = updatedFournisseur;
      chargerProduits(reset: true);
      _chargerFournisseurs();
      notifyListeners();
    }
  }

  void supprimerFournisseur(Fournisseur fournisseur) {
    _objectBox.fournisseurBox.remove(fournisseur.id);
    chargerProduits(reset: true);
    _chargerFournisseurs();
    notifyListeners();
  }

  void ajouterFournisseurAvecProduits(Fournisseur fournisseur,
      List<Produit> produits, List<double> quantites, List<double> prixAchats) {
    // Assurer que les quantités et les prix d'achat sont fournis pour chaque produit
    if (produits.length != quantites.length ||
        produits.length != prixAchats.length) {
      throw ArgumentError(
          "Les listes de produits, quantités et prix d'achat doivent avoir la même longueur.");
    }

    // Ajouter ou mettre à jour les produits
    _ajouterOuMettreAJourProduits(produits);

    // Associer chaque produit avec le fournisseur via un approvisionnement
    for (int i = 0; i < produits.length; i++) {
      Approvisionnement approvisionnement = Approvisionnement(
        quantite: quantites[i],
        prixAchat: prixAchats[i],
        datePeremption:
            null, // Ajouter si tu as besoin de gérer la date de péremption
        derniereModification: DateTime.now(),
      );

      // Définir les relations produit et fournisseur
      approvisionnement.produit.target = produits[i];
      approvisionnement.fournisseur.target = fournisseur;

      // Ajouter l'approvisionnement dans la base de données
      _objectBox.approvisionnementBox.put(approvisionnement);
    }

    // Sauvegarder le fournisseur dans la base de données
    _objectBox.fournisseurBox.put(fournisseur);

    // Rafraîchir les listes de produits et fournisseurs
    chargerProduits(reset: true);
    _chargerFournisseurs();

    // Notifier les auditeurs
    notifyListeners();
  }

  void ajouterProduitsAleatoiresPourFournisseur(
      Fournisseur fournisseur, int nombreProduits) {
    final faker = Faker();

    List<Produit> produits = List.generate(nombreProduits, (index) {
      return Produit(
        id: 0,
        image: 'https://picsum.photos/200/300?random=${Random().nextInt(1000)}',
        nom: faker.food.dish(),
        description: faker.lorem.sentence(),
        qr: faker.randomGenerator.integer(999999).toString(),
        prixVente: faker.randomGenerator.decimal(min: 50),
        minimStock: faker.randomGenerator.decimal(min: 1, scale: 2),
        alertPeremption: Random().nextInt(10),
        derniereModification: DateTime.now(),
      );
    });

    // Ajouter les produits et créer des approvisionnements pour chaque produit
    for (Produit produit in produits) {
      Approvisionnement approvisionnement = Approvisionnement(
        quantite: faker.randomGenerator.decimal(min: 100, scale: 15),
        prixAchat: faker.randomGenerator.decimal(min: 10),
        datePeremption: faker.date.dateTime(minYear: 2025),
        derniereModification: DateTime.now(),
      );

      // Définir les relations entre l'approvisionnement, le produit et le fournisseur
      approvisionnement.produit.target = produit;
      approvisionnement.fournisseur.target = fournisseur;

      // Ajouter l'approvisionnement à la base de données
      _objectBox.approvisionnementBox.put(approvisionnement);
    }

    // Sauvegarder le fournisseur et les produits associés
    _objectBox.fournisseurBox.put(fournisseur);

    // Notifier les auditeurs que les données ont été mises à jour
    notifyListeners();
  }

  // Méthodes utilitaires privées
  void _ajouterOuMettreAJourFournisseurs(List<Fournisseur> fournisseurs) {
    for (var fournisseur in fournisseurs) {
      _objectBox.fournisseurBox.put(fournisseur);
    }
  }

  void _ajouterOuMettreAJourProduits(List<Produit> produits) {
    for (var produit in produits) {
      _objectBox.produitBox.put(produit);
    }
  }

  void ajouterProduitsExistantsAuFournisseur(
      Fournisseur fournisseur, List<Produit> produits) {
    for (var produit in produits) {
      // Vérifier si l'approvisionnement existe déjà pour ce produit
      bool existe = fournisseur.approvisionnements
          .any((a) => a.produit.target == produit);

      if (!existe) {
        // Créer un nouvel approvisionnement pour ce produit
        Approvisionnement approvisionnement = Approvisionnement(
          quantite: 0, // Définir la quantité initiale
          prixAchat: 0, // Ajuster le prix d'achat si nécessaire
          datePeremption: null, // Définir la date de péremption si nécessaire
          derniereModification: DateTime.now(),
        );

        // Établir les relations
        approvisionnement.produit.target = produit;
        approvisionnement.fournisseur.target = fournisseur;

        // Ajouter l'approvisionnement au fournisseur
        fournisseur.approvisionnements.add(approvisionnement);
      }
    }

    // Sauvegarder le fournisseur et les produits associés
    _objectBox.fournisseurBox.put(fournisseur);
    _objectBox.produitBox.putMany(produits);

    // Charger les produits et les fournisseurs
    chargerProduits(reset: true);
    _chargerFournisseurs();
    notifyListeners();
  }

  void supprimerProduitDuFournisseur(Fournisseur fournisseur, Produit produit) {
    try {
      // Charger les instances actuelles de la base de données
      Fournisseur? fournisseurActuel =
          _objectBox.fournisseurBox.get(fournisseur.id);
      Produit? produitActuel = _objectBox.produitBox.get(produit.id);

      if (fournisseurActuel == null) {
        print('Fournisseur non trouvé dans la base de données.');
        return;
      }
      if (produitActuel == null) {
        print('Produit non trouvé dans la base de données.');
        return;
      }

      _objectBox.store.runInTransaction(TxMode.write, () {
        // Vérifier si l'approvisionnement existe pour ce produit et ce fournisseur
        bool approvisionnementExiste = fournisseurActuel.approvisionnements
            .any((a) => a.produit.target == produitActuel);

        if (approvisionnementExiste) {
          // Supprimer l'approvisionnement du fournisseur
          fournisseurActuel.approvisionnements
              .removeWhere((a) => a.produit.target == produitActuel);

          // Mise à jour dans la base de données
          _objectBox.fournisseurBox.put(fournisseurActuel);
          _objectBox.produitBox
              .put(produitActuel); // Mettre à jour le produit si nécessaire
        } else {
          print(
              'L\'approvisionnement n\'existe pas pour ce produit et ce fournisseur.');
        }
      });

      // Rechargement des données en dehors de la transaction
      chargerProduits(reset: true);
      _chargerFournisseurs();
      notifyListeners();
    } catch (e) {
      print('Erreur lors de la suppression du produit du fournisseur : $e');
    }
  }

  void supprimerFournisseurDuProduit(Produit produit, Fournisseur fournisseur) {
    try {
      // Charger les instances actuelles de la base de données
      Produit? produitActuel = _objectBox.produitBox.get(produit.id);
      Fournisseur? fournisseurActuel =
          _objectBox.fournisseurBox.get(fournisseur.id);

      if (produitActuel == null) {
        print('Produit non trouvé dans la base de données.');
        return;
      }
      if (fournisseurActuel == null) {
        print('Fournisseur non trouvé dans la base de données.');
        return;
      }

      _objectBox.store.runInTransaction(TxMode.write, () {
        // Vérifier si l'approvisionnement existe pour ce produit et ce fournisseur
        bool approvisionnementExiste = fournisseurActuel.approvisionnements
            .any((a) => a.produit.target == produitActuel);

        if (approvisionnementExiste) {
          // Supprimer l'approvisionnement du fournisseur
          fournisseurActuel.approvisionnements
              .removeWhere((a) => a.produit.target == produitActuel);

          // Mise à jour dans la base de données
          _objectBox.fournisseurBox.put(fournisseurActuel);
        } else {
          print(
              'L\'approvisionnement n\'existe pas pour ce produit et ce fournisseur.');
        }
      });

      // Rechargement des données en dehors de la transaction
      chargerProduits(reset: true);
      _chargerFournisseurs();
      notifyListeners();
    } catch (e) {
      print('Erreur lors de la suppression du fournisseur du produit : $e');
    }
  }

  // Méthode pour mettre à jour les fournisseurId de tous les approvisionnements
  Future<void> updateFournisseurIdsInApprovisionnements() async {
    // Récupérer tous les fournisseurs existants
    final List<Fournisseur> fournisseurs = _objectBox.fournisseurBox.getAll();

    if (fournisseurs.isEmpty) {
      return; // Assurez-vous qu'il y a des fournisseurs disponibles
    }

    // Récupérer tous les approvisionnements
    final List<Approvisionnement> approvisionnements =
        _objectBox.approvisionnementBox.getAll();

    for (var approvisionnement in approvisionnements) {
      // Vérifier si le fournisseur est assigné et existe dans la base de données
      if (!fournisseurs
          .any((f) => f.id == approvisionnement.fournisseur.targetId)) {
        // Si non valide, assigner un fournisseur valide (par exemple, le premier)
        approvisionnement.fournisseur.target = fournisseurs.first;

        // Mettre à jour l'approvisionnement dans la base de données
        _objectBox.approvisionnementBox.put(approvisionnement);
      }
    }

    // Recharger les approvisionnements et notifier les listeners
    _approvisionnements = _objectBox.approvisionnementBox.getAll();
    notifyListeners();
  }

  // Exemple de méthode d'appel de cette mise à jour
  Future<void> miseAJourDesApprovisionnements() async {
    await updateFournisseurIdsInApprovisionnements();
  }
}

class CartProvider with ChangeNotifier {
  final ObjectBox _objectBox;
  Document _facture = Document(
    date: DateTime.now(),
    qrReference: '',
    impayer: 0.0,
    derniereModification: DateTime.now(),
    type: '',
  );

  Client? _selectedClient;
  List<Document> _factures = [];

  Produit? produit;

  Document get facture => _facture;

  Client? get selectedClient => _selectedClient;

  List<Document> get factures => _factures;

  int get factureCount => _factures.length;

  CartProvider(this._objectBox) {
    fetchFactures();
  }

  void fetchFactures() {
    _factures = _objectBox.factureBox.getAll();
    notifyListeners();
  }

  // Méthode pour la sélection d'une facture
  void selectFacture(Document facture) {
    _facture = facture; // Clonage ou copie indépendante
    notifyListeners();
  }

  // Méthode pour filtrer ou rechercher une facture
  List<Document> searchFactures(String keyword) {
    return _factures
        .where(
            (f) => f.qrReference.contains(keyword) || f.type.contains(keyword))
        .toList();
  }

  void updateImpayer(double newImpayer) {
    _facture.impayer = newImpayer;
    notifyListeners();
  }

  void setSelectedClient(Client client) {
    _selectedClient = client;
    notifyListeners();
  }

  void selectClient(Client client) {
    _selectedClient = client;
    //_facture.client.target = client;
    notifyListeners();
  }

  void resetClient() {
    _selectedClient = null;
    _facture.client.target = null;
    // notifyListeners();
  }

  Future<void> createAndSelectClient(
      String nom,
      String phone,
      String adresse,
      String description,
      DateTime dateCreation,
      DateTime derniereModification) async {
    final newClient = Client(
      qr: await generateQRCode('${_selectedClient?.id ?? ''}'),
      nom: nom,
      phone: phone,
      adresse: adresse,
      description: description,
      derniereModification: DateTime.now(),
    );
    //_objectBox.clientBox.put(newClient);
    selectClient(newClient);
  }

  void createAnonymousClientIfNeeded() {
    if (_selectedClient == null) {
      // Création de l'entité Crud pour le client anonyme
      final crud = Crud(
        createdBy: 1,
        updatedBy: 1,
        deletedBy: 1,
        dateCreation: DateTime.now(),
        derniereModification: DateTime.now(),
        dateDeleting: null,
      );

      // Création du client anonyme
      final anonymousClient = Client(
        qr: 'ANONYMOUS_${DateTime.now().millisecondsSinceEpoch}',
        nom:
            'ANONYMOUS_Client du ${_facture.date.day}/${_facture.date.month}/${_facture.date.year}',
        phone: '',
        adresse: '',
        description: 'Client créé automatiquement',
        derniereModification: DateTime.now(),
      );

      // Associer l'entité Crud au client
      anonymousClient.crud.target = crud;

      // Sauvegarder le client avec l'entité Crud
      // _objectBox.clientBox.put(anonymousClient);

      // Sélectionner le client anonyme comme client courant
      selectClient(anonymousClient);
    }
  }

  void addToCart(Produit produit) {
    final index = _facture.lignesDocument
        .indexWhere((item) => item.produit.target!.id == produit.id);
    if (index != -1) {
      _facture.lignesDocument[index].quantite += 1;
    } else {
      final ligneFacture = LigneDocument(
        quantite: 1,
        prixUnitaire: produit.prixVente,
        derniereModification: DateTime.now(),
      );
      ligneFacture.produit.target = produit;
      ligneFacture.facture.target = _facture;
      _facture.lignesDocument.add(ligneFacture);
    }
  }

  void removeFromCart(Produit produit) {
    final index = _facture.lignesDocument
        .indexWhere((item) => item.produit.target!.id == produit.id);
    if (index != -1) {
      if (_facture.lignesDocument[index].quantite > 1) {
        _facture.lignesDocument[index].quantite -= 1;
      } else {
        _facture.lignesDocument.removeAt(index);
      }
    }
  }

  double get totalAmount {
    return _facture.lignesDocument
        .fold(0, (sum, item) => sum + item.prixUnitaire * item.quantite);
  }

  Map<String, dynamic> calculateTotalsForInterval(
      DateTime startDate, DateTime endDate) {
    double totalTTC = 0.0;
    double totalImpayes = 0.0;
    double totalTVA = 0.0;
    const double tvaRate = 0.19; // Taux de TVA (20% par exemple)

    // Récupérer les factures depuis ObjectBox au moment de l'appel de la méthode

    List<Document> facturesDansIntervalle =
        _objectBox.factureBox.getAll().where((facture) {
      return (facture.date.isAfter(startDate) &&
              facture.date.isBefore(endDate)) ||
          facture.date.isAtSameMomentAs(startDate) ||
          facture.date.isAtSameMomentAs(endDate);
    }).toList();

    // Calculer les totaux pour chaque facture dans l'intervalle
    for (var facture in facturesDansIntervalle) {
      double montantHT = facture.lignesDocument.fold(0.0, (sum, ligne) {
        return sum + (ligne.prixUnitaire * ligne.quantite);
      });

      double tva = montantHT * tvaRate;
      double montantTTC = montantHT + tva;

      totalTTC += montantTTC;
      totalTVA += tva;

      // Ajouter le montant impayé
      totalImpayes += facture.impayer ?? 0.0;
    }

    // Retourner les résultats sous forme de map
    return {
      'totalTTC': totalTTC,
      'totalImpayes': totalImpayes,
      'totalTVA': totalTVA,
    };
  }

  Future<void> saveFacture(CommerceProvider commerceProvider) async {
    // Vérifier si un client est sélectionné
    if (_selectedClient != null) {
      // Sauvegarder le client mis à jour
      _objectBox.clientBox.put(_selectedClient!);
      // Associer le client à la facture
      _facture.client.target = _selectedClient;
    }

    // Génération du QR code et sauvegarde de la facture
    _facture.qrReference =
        await generateQRCode('${_facture.id} ${_facture.date}');

    // Sauvegarder la facture
    _objectBox.factureBox.put(_facture);

    // Sauvegarde des lignes de facture et mise à jour des produits associés
    for (var ligne in _facture.lignesDocument) {
      final produit = ligne.produit.target;

      if (produit != null) {
        // Mettre à jour le stock du produit en fonction de la quantité vendue
        double newStock =
            produit.stock - ligne.quantite; // Utilisez le getter ici

        // Sauvegarder le produit mis à jour
        _objectBox.produitBox.put(produit);
        commerceProvider.updateProduit(produit);
      }

      // Sauvegarder la ligne de facture
      _objectBox.ligneFacture.put(ligne);
    }

    // Réinitialisation de la facture et du client sélectionné
    _facture = Document(
      date: DateTime.now(),
      qrReference: '',
      impayer: 0.0,
      derniereModification: DateTime.now(),
      type: '',
    );
    _selectedClient = null;

    notifyListeners();

    // Rafraîchir la liste des factures
    fetchFactures();
  }

  void clearCart() {
    _facture = Document(
      date: DateTime.now(),
      qrReference: '',
      impayer: 0.0,
      derniereModification: DateTime.now(),
      type: '',
    );
    _selectedClient = null;
    notifyListeners();
  }

  Future<String> generateQRCode(gRGenerated) async {
    // Implémentez la logique de génération du QR code ici
    // Par exemple, vous pourriez utiliser un package comme 'qr' pour générer le code
    // et le convertir en chaîne de caractères
    // await Future.delayed(
    //     Duration(milliseconds: 100)); // Simuler une opération asynchrone
    return //"QR_${_objectBox.random.nextInt(1000000)}";
        "QR_${gRGenerated}";
  }

  Future<void> deleteFacture(Document facture) async {
    _objectBox.factureBox.remove(facture.id);
    notifyListeners();
    fetchFactures();
  }

  // Future<void> updateFacture(Document updatedFacture) async {
  //   _objectBox.factureBox.put(updatedFacture);
  //   notifyListeners();
  //   fetchFactures();
  // }
  // void loadFactureForEditing(Document facture) {
  //   // Copier les lignes de la facture dans le panier actuel
  //   _facture.lignesDocument.clear();
  //   for (var ligne in facture.lignesDocument) {
  //     _facture.lignesDocument.add(ligne);
  //   }
  //
  //   // Copier les autres propriétés de la facture
  //   // _facture.impayer =  facture.impayer;
  //   // _facture.date=facture.date;
  //
  //   notifyListeners();
  // }
  void loadFactureForEditing(Document facture) {
    // Réinitialiser complètement l'instance actuelle de Document
    _facture = Document(
      id: 0,
      // Réinitialiser l'ID pour éviter d'écraser une facture existante
      date: facture.date,
      qrReference: facture.qrReference,
      type: facture.type,
      montantVerse: facture.montantVerse,
      impayer: facture.impayer,
      derniereModification: facture.derniereModification,
      isSynced: facture.isSynced,
      syncedAt: facture.syncedAt,
    );

    // Copier les relations spécifiques
    _facture.client.target = facture.client.target;
    _facture.fournisseur.target = facture.fournisseur.target;
    _facture.crud.target = facture.crud.target;

    // Réinitialiser les lignes de document
    _facture.lignesDocument.clear();
    for (var ligne in facture.lignesDocument) {
      _facture.lignesDocument.add(LigneDocument(
        id: 0,
        // Réinitialisation pour garantir une modification locale
        quantite: ligne.quantite,
        prixUnitaire: ligne.prixUnitaire,
        derniereModification: ligne.derniereModification,
        isSynced: ligne.isSynced,
        syncedAt: ligne.syncedAt,
      )..produit.target = ligne.produit.target); // Copie de la relation produit
    }

    // Notifier les auditeurs pour mettre à jour l'interface
    notifyListeners();
  }

  Future<void> updateFacture(int factureId) async {
    // Trouver la facture existante
    final existingFacture = _factures.firstWhere((f) => f.id == factureId);

    // Mettre à jour les données
    existingFacture.lignesDocument.clear();
    for (var ligne in _facture.lignesDocument) {
      existingFacture.lignesDocument.add(ligne);
    }

    existingFacture.impayer = _facture.impayer;
    existingFacture.date = DateTime.now();

    // Sauvegarder dans la base de données
    await _objectBox.factureBox.put(existingFacture);
    // Réinitialiser le panier
    // resetCart();
    notifyListeners();
  }

  Future<void> deleteAllFactures() async {
    final box = _objectBox.factureBox;
    box.removeAll();
    fetchFactures();
  }
}

class ClientProvider with ChangeNotifier {
  final ObjectBox _objectBox;
  List<Client> _clients = [];

  List<Client> get clients => _clients;

  int get clientCount => _clients.length;

  ClientProvider(this._objectBox) {
    getClientsFromBox();
  }

  void getClientsFromBox() {
    final box = _objectBox.clientBox;
    _clients = box.getAll();
    notifyListeners();
  }

  Future<void> addClient(Client client) async {
    _objectBox.clientBox.put(client);
    getClientsFromBox();
    notifyListeners();
  }

  Future<void> updateClient(Client client) async {
    _objectBox.clientBox.put(client);
    getClientsFromBox();
    notifyListeners();
  }

  Future<void> deleteClient(Client client) async {
    _objectBox.clientBox.remove(client.id);
    getClientsFromBox();
    notifyListeners();
  }

  List<Document> getFacturesForClient(Client client) {
    // Utiliser ObjectBox pour récupérer les factures associées au client
    final facturesQuery =
        _objectBox.factureBox.query(Document_.client.equals(client.id)).build();
    final factures = facturesQuery.find();
    facturesQuery.close();
    return factures;
  }

  Future<void> deleteAllClients() async {
    final box = _objectBox.clientBox;
    box.removeAll();
    getClientsFromBox();
    notifyListeners();
  }
}

class FakeDataGenerator1 extends ChangeNotifier {
  bool _isGenerating = false;

  bool get isGenerating => _isGenerating;
  String? _message;

  String? get message => _message;

  Future<void> generateFakeData(ObjectBox objectBox, int users, int clients,
      int suppliers, int products, int approvisionnements) async {
    print("Début de generateFakeData");
    if (_isGenerating) {
      print("Génération déjà en cours");
      return;
    }

    _isGenerating = true;
    _message = null;
    notifyListeners();
    print("Notification envoyée, début de la génération");

    try {
      print("Début de Isolate.run");
      await Isolate.run(() {
        print("Dans Isolate.run");
        return objectBox.fillWithFakeData(
            users, clients, suppliers, products, approvisionnements);
      });
      print("Fin de Isolate.run");

      _message = 'Données factices ajoutées avec succès !';
    } catch (e) {
      print("Erreur capturée : $e");
      _message = 'Erreur lors de la génération des données : $e';
    } finally {
      _isGenerating = false;
      notifyListeners();
      print("Fin de generateFakeData");
    }
  }

  void clearMessage() {
    _message = null;
    notifyListeners();
  }
}

class AdProvider extends ChangeNotifier {
  static const int maxFailedLoadAttempts = 3;

  InterstitialAd? _interstitialAd;
  int _numInterstitialLoadAttempts = 0;

  RewardedInterstitialAd? _rewardedInterstitialAd;
  int _numRewardedInterstitialLoadAttempts = 0;

  RewardedAd? _rewardedAd;
  int _numRewardedLoadAttempts = 0;

  bool _isInterstitialAdReady = false;
  bool _isRewardedAdReady = false;
  bool _isRewardedInterstitialAdReady = true;

  bool get isInterstitialAdReady => _isInterstitialAdReady;

  bool get isRewardedAdReady => _isRewardedAdReady;

  bool get isRewardedInterstitialAdReady => _isRewardedInterstitialAdReady;

  AdProvider() {
    _createInterstitialAd();
    _createRewardedAd();
  }

  // Utilisez cette méthode pour créer une AdRequest sans paramètres spécifiques
  static AdRequest get request => AdRequest();

  void _createInterstitialAd() {
    InterstitialAd.load(
      adUnitId: Platform.isAndroid
          ? 'ca-app-pub-2282149611905342/9541682865'
          : 'ca-app-pub-2282149611905342/9541682865',
      request: request,
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          _interstitialAd = ad;
          _numInterstitialLoadAttempts = 0;
          _isInterstitialAdReady = true;
          ad.setImmersiveMode(true);
          notifyListeners();
        },
        onAdFailedToLoad: (LoadAdError error) {
          _numInterstitialLoadAttempts += 1;
          _interstitialAd = null;
          _isInterstitialAdReady = false;
          if (_numInterstitialLoadAttempts < maxFailedLoadAttempts) {
            _createInterstitialAd();
          }
          notifyListeners();
        },
      ),
    );
  }

  void showInterstitialAd() {
    if (_interstitialAd == null) {
      return;
    }
    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (InterstitialAd ad) {
        ad.dispose();
        _createInterstitialAd();
      },
      onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
        ad.dispose();
        _createInterstitialAd();
      },
    );
    _interstitialAd!.show();
    _interstitialAd = null;
    _isInterstitialAdReady = false;
    notifyListeners();
  }

  void _createRewardedAd() {
    RewardedAd.load(
      adUnitId: Platform.isAndroid
          ? 'ca-app-pub-2282149611905342/1761000427'
          : 'ca-app-pub-2282149611905342/1761000427',
      request: request,
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) {
          _rewardedAd = ad;
          _numRewardedLoadAttempts = 0;
          _isRewardedAdReady = true;
          notifyListeners();
        },
        onAdFailedToLoad: (LoadAdError error) {
          _rewardedAd = null;
          _numRewardedLoadAttempts += 1;
          _isRewardedAdReady = false;
          if (_numRewardedLoadAttempts < maxFailedLoadAttempts) {
            _createRewardedAd();
          }
          notifyListeners();
        },
      ),
    );
  }

  Future<bool> showRewardedAd() async {
    if (_rewardedAd == null) {
      return false;
    }

    final completer = Completer<bool>();

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (RewardedAd ad) {
        ad.dispose();
        _createRewardedAd();
        completer.complete(false);
      },
      onAdFailedToShowFullScreenContent: (RewardedAd ad, AdError error) {
        ad.dispose();
        _createRewardedAd();
        completer.complete(false);
      },
    );

    _rewardedAd!.setImmersiveMode(true);
    await _rewardedAd!.show(
      onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
        completer.complete(true);
      },
    );
    _rewardedAd = null;
    _isRewardedAdReady = false;
    notifyListeners();

    return completer.future;
  }
}

class CrudProvider with ChangeNotifier {
  final ObjectBox _objectBox;

  CrudProvider(this._objectBox) {
    loadCruds();
  }

  List<Crud> _cruds = [];

  List<Crud> get cruds => _cruds;

  // Retourne le nombre de Cruds actuellement chargés en mémoire
  int get crudCount => _cruds.length;

  // Retourne le nombre total de Cruds dans la base de données
  int get totalCrudCount {
    final crudBox = _objectBox.crudBox;
    return crudBox.count(); // Méthode ObjectBox pour obtenir le nombre total
  }

  // Charger les Cruds depuis ObjectBox
  void loadCruds() {
    final crudBox = _objectBox.crudBox;
    _cruds = crudBox.getAll();
    notifyListeners(); // Notifier l'UI que les données ont changé
  }

  // Mettre à jour un Crud et recharger la liste
  Future<void> updateCrud(Crud crud) async {
    final crudBox = _objectBox.crudBox;
    crudBox.put(crud);
    loadCruds(); // Recharger les données après mise à jour
  }

  // Supprimer tous les Cruds et recharger la liste
  Future<void> deleteAllCruds() async {
    final crudBox = _objectBox.crudBox;
    crudBox.removeAll();
    loadCruds();
  }
}
