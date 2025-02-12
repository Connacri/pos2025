import 'dart:async';
import 'dart:isolate';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../objectbox.g.dart';
import '../../Entity.dart';
import '../../classeObjectBox.dart';

class FacturationProvider with ChangeNotifier {
  // List<Document> _factures = [];
  Document? _factureEnCours;
  Document? _factureEnEdition; // Copie de la facture en cours d'édition
  List<LigneDocument> _lignesFacture = [];
  List<Produit> _produitsTrouves = [];
  final Map<int, LigneEditionState> _ligneEditionStates = {};
  bool _isEditing =
      false; // Pour suivre si une facture est en cours de modification
  bool get isEditing => _isEditing;
  bool _hasChanges =
      false; // Pour suivre si des modifications ont été apportées

  bool get hasChanges => _hasChanges;

  Document? get factureEnEdition => _factureEnEdition;

  //List<Document> get factures => _factures;

  Document? get factureEnCours => _factureEnCours;

  List<LigneDocument> get lignesFacture => _lignesFacture;

  List<Produit> get produitsTrouves => _produitsTrouves;

  Client? _clientTemporaire; // Client temporaire

  final ObjectBox _objectBox = ObjectBox();

  FacturationProvider() {
    _objectBox.init().then((_) {
      //_chargerFactures();
      chargerFactures();
      //chargerFacturesPaginees();
    });
  }

  Client? _selectedClient;

  Client? get selectedClient => _selectedClient;

// Ajoutez un champ pour gérer l'impayé
  double _impayer = 0.0;

  double get impayer => _impayer;

  ////////////////////////////////Liste des facture//////////////////////////////////////

  bool _isLoadingListFacture = false;

  bool get isLoadingListFacture => _isLoadingListFacture;

  List<Document> _facturesList = [];

  List<Document> get facturesList => _facturesList.reversed.toList();

  int _currentPageFacture = 0;
  final int _pageSizeFacture = 20;
  bool _hasMoreFactures = true;

  bool get hasMoreFactures => _hasMoreFactures;

  Future<void> chargerFactures({bool reset = true}) async {
    if (_isLoadingListFacture || !_hasMoreFactures) {
      print(
          "🚫 Appel ignoré : _isLoadingListFacture = $_isLoadingListFacture, _hasMoreFactures = $_hasMoreFactures");
      return;
    }

    _isLoadingListFacture = true;
    notifyListeners();
    print("🔄 Début du chargement des factures...");

    try {
      if (reset) {
        _currentPageFacture = 0;
        _facturesList.clear(); // Utilisez _facturesList au lieu de facturesList
        print(
            "🔄 Réinitialisation de la pagination : _currentPageFacture = $_currentPageFacture");
      }

      final offset = _currentPageFacture * _pageSizeFacture;
      final limit = _pageSizeFacture;
      print("📊 Pagination : offset = $offset, limit = $limit");

      final query = _objectBox.factureBox
          .query()
          .order(Document_.id, flags: Order.descending)
          .build()
        ..offset = offset
        ..limit = limit;

      print("🔍 Exécution de la requête pour récupérer les factures...");
      final newFactures = await query.find();
      print("✅ ${newFactures.length} factures récupérées");

      // Ajouter les nouvelles factures à _facturesList
      _facturesList.addAll(
          newFactures); // Utilisez _facturesList au lieu de facturesList
      print(
          "📥 ${newFactures.length} factures ajoutées à _facturesList : ${_facturesList.length}");

      if (newFactures.length < _pageSizeFacture) {
        _hasMoreFactures = false;
        print(
            "⛔ Plus de factures à charger : _hasMoreFactures = $_hasMoreFactures");
      } else {
        _currentPageFacture++;
        _hasMoreFactures = true;
        print(
            "➡️ Page suivante : _currentPageFacture = $_currentPageFacture, _hasMoreFactures = $_hasMoreFactures");
      }
    } catch (e) {
      print("❌ Erreur lors du chargement des factures : $e");
    } finally {
      _isLoadingListFacture = false;
      notifyListeners();
      print(
          "✅ Chargement terminé : _isLoadingListFacture = $_isLoadingListFacture");
    }
  }

  ///////////////////////////////////////////////////////////////////////////////////////
  Future<void> chargerFacturesPaginees2() async {
    if (_isLoadingListFacture || !_hasMoreFactures) return;

    _isLoadingListFacture = true;
    notifyListeners();

    try {
      // Calculer l'offset et le limit pour la pagination
      final offset = _currentPageFacture * _pageSizeFacture;
      final limit = _pageSizeFacture; // Limite des résultats à récupérer
      // Construire et configurer la requête
      final query = _objectBox.factureBox
          .query()
          .order(Document_.derniereModification, flags: Order.descending)
          .build()
        ..offset = offset
        ..limit = limit;

      // Effectuer la recherche dans ObjectBox
      final nouvellesFactures = await query
          .find(); // Utilisation de `await` pour exécution asynchrone
      query.close(); // Fermer la requête après utilisation

      if (nouvellesFactures.isEmpty) {
        _hasMoreFactures =
            false; // Indiquer qu'il n'y a plus de données disponibles
      } else {
        _facturesList.addAll(
            nouvellesFactures); // Ajouter les nouvelles factures à la liste
        _currentPageFacture++; // Passer à la page suivante
      }
    } catch (e) {
      print("Erreur lors de la récupération des factures : $e");
    } finally {
      _isLoadingListFacture = false;
      notifyListeners();
    }
  }

  void setImpayer(double impayer) {
    _impayer = impayer;
    // _isEditing = true;
    _hasChanges = true;
    notifyListeners();
  }

  void commencerEdition(Document facture) {
    _factureEnEdition = facture;
    _isEditing = true; // Activer l'état d'édition
    _hasChanges = false; // Réinitialiser l'état des modifications
    notifyListeners();
  }

  void modifierLigne(int index, double quantite, double prixUnitaire) {
    if (index >= 0 && index < _lignesFacture.length) {
      _lignesFacture[index].quantite = quantite;
      _lignesFacture[index].prixUnitaire = prixUnitaire;
      _hasChanges = true; // Marquer qu'il y a des modifications
      notifyListeners();
    }
  }

  void modifierImpayer(double impayer) {
    _impayer = impayer;
    _hasChanges = true; // Marquer qu'il y a des modifications
    notifyListeners();
  }

  void selectClient(Client client) {
    _selectedClient = client;
    // if (_factureEnEdition != null) {
    //   _factureEnEdition!.client.target = client;
    // }
    _hasChanges = true;

    notifyListeners();
  }

  void resetClient() {
    // Déconnecter temporairement le client uniquement pour la facture en cours
    // if (_factureEnCours != null) {
    //   _factureEnCours!.client.target = null;
    // }

    // Ne réinitialise que le client sélectionné dans l'état local
    _selectedClient = null;
    _hasChanges = true;
    notifyListeners();
  }

  // Méthode pour créer un nouveau client
  Future<void> createClient(String nom, String phone, String adresse, String qr,
      DateTime derniereModification) async {
    final nouveauClient = Client(
      nom: nom,
      phone: phone,
      adresse: adresse,
      qr: qr,
      derniereModification: derniereModification,
    );
    _objectBox.clientBox.put(nouveauClient);
    notifyListeners();
  }

  // Méthode pour récupérer tous les clients
  List<Client> getClients() {
    return _objectBox.clientBox.getAll();
  }

  // void _chargerFactures() {
  //   _factures = _objectBox.factureBox.getAll();
  //   notifyListeners();
  // }

  void marquerCommeSauvegardee(Document facture) {
    _factureEnEdition = null; // Réinitialiser la facture en cours d'édition
    notifyListeners();
  }

  // Méthode pour vérifier si une facture est en cours d'édition
  bool estEnEdition(Document facture) {
    return _factureEnEdition?.id == facture.id;
  }

  LigneEditionState getLigneEditionState(int index) {
    _ligneEditionStates.putIfAbsent(index, () => LigneEditionState());
    return _ligneEditionStates[index]!;
  }

  void toggleEditQty(int index) {
    final state = getLigneEditionState(index);
    state.isEditedQty = !state.isEditedQty;
    notifyListeners();
  }

  void toggleEditPu(int index) {
    final state = getLigneEditionState(index);
    state.isEditedPu = !state.isEditedPu;
    notifyListeners();
  }

  void AlwaystoggleEdit(int index) {
    final state = LigneEditionState();
    state.isEditedPu = !state.isEditedPu;
    notifyListeners();
  }

  bool _isEditable = false;

  bool get isEditable => _isEditable;

  void toggleEditImpayer() {
    _isEditable = !_isEditable;
    notifyListeners();
  }

  void setEditable(bool value) {
    _isEditable = value;
    notifyListeners();
  }

  void rechercherProduits(String texte) {
    if (texte.isEmpty) {
      _produitsTrouves.clear();
    } else {
      final query = _objectBox.produitBox.query(
        Produit_.nom.contains(texte, caseSensitive: false) |
            Produit_.qr.contains(texte, caseSensitive: false) |
            Produit_.id.equals(int.tryParse(texte) ?? 0),
      );
      _produitsTrouves = query.build().find();
    }
    notifyListeners();
  }

  void ajouterProduitALaFacture(
      Produit produit, double quantite, double prixUnitaire) {
    // Vérifier si le produit existe déjà dans la facture
    final ligneExistanteIndex = _lignesFacture.indexWhere(
      (ligne) => ligne.produit.target?.id == produit.id,
    );

    if (ligneExistanteIndex != -1) {
      // Si le produit existe, incrémenter la quantité
      _lignesFacture[ligneExistanteIndex].quantite += quantite;
    } else {
      // Sinon, ajouter une nouvelle ligne
      final nouvelleLigne = LigneDocument(
        quantite: quantite,
        prixUnitaire: prixUnitaire,
        derniereModification: DateTime.now(),
      );
      nouvelleLigne.produit.target = produit;
      _lignesFacture.add(nouvelleLigne);
    }

    notifyListeners();
  }

  void supprimerLigne(int index) {
    if (index >= 0 && index < _lignesFacture.length) {
      print('Suppression de la ligne à l\'index $index'); // Ajoutez ce log
      _lignesFacture.removeAt(index);
      _hasChanges = true; // Marquer qu'il y a des modifications
      notifyListeners();
    } else {
      print('Erreur : Index invalide pour la suppression'); // Ajoutez ce log
    }
  }

  double calculerTotalHT() {
    return _lignesFacture.fold(0.0, (total, ligne) {
      return total + (ligne.quantite * ligne.prixUnitaire);
    });
  }

  double calculerTVA() {
    const tauxTVA = 0.20;
    return calculerTotalHT() * tauxTVA;
  }

  double calculerTotalTTC() {
    return calculerTotalHT() + calculerTVA();
  }

  void creerNouvelleFacture() {
    // Créer une nouvelle facture
    _factureEnCours = Document(
      type: 'vente',
      // ou 'achat'
      qrReference: 'REF${DateTime.now().millisecondsSinceEpoch}',
      // Référence unique
      impayer: 0.0,
      derniereModification: DateTime.now(),
      isSynced: false,
      date: DateTime.now(),
    );
    _selectedClient = null;
    _impayer = 0.0;
    // Réinitialiser les lignes de la facture
    _lignesFacture.clear();

    // Notifier les listeners pour mettre à jour l'interface utilisateur
    notifyListeners();
  }

  void selectionnerFacture(Document facture) {
    _factureEnEdition = Document(
      id: facture.id,
      type: facture.type,
      qrReference: facture.qrReference,
      impayer: facture.impayer ?? 0.0,
      // Copiez l'impayé
      derniereModification: facture.derniereModification,
      isSynced: facture.isSynced,
      syncedAt: facture.syncedAt,
      date: facture.date,
    );
    // Copier le client associé à la facture
    _selectedClient = facture.client.target;
    // Copiez les lignes de document
    _factureEnEdition!.lignesDocument
        .addAll(facture.lignesDocument.map((ligne) {
      return LigneDocument(
        id: ligne.id,
        quantite: ligne.quantite,
        prixUnitaire: ligne.prixUnitaire,
        derniereModification: ligne.derniereModification,
        isSynced: ligne.isSynced,
        syncedAt: ligne.syncedAt,
      )..produit.target = ligne.produit.target;
    }));

    _factureEnCours = facture;
    _lignesFacture = _factureEnEdition!.lignesDocument.toList();
    _impayer = facture.impayer ?? 0.0; // Initialisez l'impayé
    notifyListeners();
  }

  Future<void> sauvegarderFacture() async {
    print('Sauvegarde de la facture en cours...');

    try {
      if (_factureEnCours == null) {
        print('Création d\'une nouvelle facture');
        final nouvelleFacture = Document(
          type: 'vente',
          qrReference: 'REF${DateTime.now().millisecondsSinceEpoch}',
          impayer: _impayer,
          derniereModification: DateTime.now(),
          isSynced: false,
          date: DateTime.now(),
        );

        // Associer le client sélectionné à la nouvelle facture
        //  if (_selectedClient != null) {
        nouvelleFacture.client.target = _selectedClient;
        // }

        // Ajouter les lignes de document à la nouvelle facture
        nouvelleFacture.lignesDocument.addAll(_lignesFacture);

        // Sauvegarder la nouvelle facture dans la base de données
        _objectBox.factureBox.put(nouvelleFacture);

        // Sauvegarder les lignes de document
        for (final ligne in _lignesFacture) {
          ligne.facture.target = nouvelleFacture;
          _objectBox.ligneFacture.put(ligne);
        }

        // Ajouter la nouvelle facture à la liste des factures
        _facturesList.add(nouvelleFacture);
      } else {
        // Mettre à jour la facture existante
        _factureEnCours!.lignesDocument.clear();
        _factureEnCours!.lignesDocument.addAll(_lignesFacture);
        _factureEnCours!.impayer = _impayer;

        // Associer le client sélectionné à la facture existante
        // if (_selectedClient != null) {
        _factureEnCours!.client.target = _selectedClient;
        //  }

        // Sauvegarder la facture mise à jour dans la base de données
        _objectBox.factureBox.put(_factureEnCours!);

        // Sauvegarder les lignes de document
        for (final ligne in _lignesFacture) {
          ligne.facture.target = _factureEnCours;
          _objectBox.ligneFacture.put(ligne);
        }
      }

      // Réinitialiser l'état après la sauvegarde
      _factureEnCours = null;
      _lignesFacture.clear();
      _impayer = 0.0;
      _selectedClient = null; // Réinitialiser le client sélectionné
      chargerFactures();
      // chargerFacturesPaginees();

      print('Facture sauvegardée avec succès');
      _isEditing = false; // Désactiver l'état d'édition après la sauvegarde
      _hasChanges = false; // Réinitialiser l'état des modifications
      notifyListeners();
    } catch (e) {
      print('Erreur lors de la sauvegarde de la facture: $e');
    }
  }

  void annulerEdition() {
    _isEditing = false; // Désactiver l'état d'édition
    _hasChanges = false; // Réinitialiser l'état des modifications
    notifyListeners();
  }

  Future<void> supprimerFacture(Document facture) async {
    // Supprimer la facture de la base de données
    _objectBox.factureBox.remove(facture.id);

    // Supprimer les lignes de document associées
    for (final ligne in facture.lignesDocument) {
      _objectBox.ligneFacture.remove(ligne.id);
    }

    // Mettre à jour la liste des factures
    _facturesList.remove(facture);

    // Si la facture supprimée est la facture en cours, la réinitialiser
    if (_factureEnCours?.id == facture.id) {
      _factureEnCours = null;
      _lignesFacture.clear();
    }

    // Notifier les listeners pour mettre à jour l'interface utilisateur
    notifyListeners();
  }
}

class LigneEditionState {
  bool isEditedQty = false;
  bool isEditedImpayer = false;
  bool isEditedPu = false;
}

class EditableFieldProvider with ChangeNotifier {
  bool _isEditable = false;

  bool get isEditable => _isEditable;

  bool _hasChanges = false;

  bool get hasChanges => _hasChanges;

//   bool _hasChanges =
//       false; // Pour suivre si des modifications ont été apportées
//
//   bool get hasChanges => _hasChanges;
//
// // Ajoutez un champ pour gérer l'impayé
//   double _impayer = 0.0;
//
//   double get impayer => _impayer;
//
//   void setImpayer(double value) {
//     _impayer = value;
//     // _isEditing = true;
//     _hasChanges = true;
//     notifyListeners();
//   }
  void AlwaystoggleEditable() {
    _isEditable = false;
    print('isEditable: $_isEditable'); // Ajout de log
    notifyListeners();
  }

  void toggleEditable() {
    _isEditable = !_isEditable;
    print('isEditable: $_isEditable'); // Ajout de log
    notifyListeners();
  }
}

/// Extension on DateTime to standardize date handling
extension DateTimeExtension on DateTime {
  DateTime get startOfDay => DateTime(year, month, day);

  DateTime get endOfDay => DateTime(year, month, day, 23, 59, 59, 999);
}

/// Response class for paginated results
class PaginatedResponse<T> {
  final List<T> items;
  final int totalCount;
  final int currentPage;
  final int pageSize;
  final bool hasNextPage;

  PaginatedResponse({
    required this.items,
    required this.totalCount,
    required this.currentPage,
    required this.pageSize,
  }) : hasNextPage = (currentPage + 1) * pageSize < totalCount;

  int get totalPages => (totalCount / pageSize).ceil();
}

/// Filter options for document queries
class DocumentFilterOptions {
  final String? searchQuery;
  final DateTimeRange? dateRange;
  final DocumentEtat? etat;
  final String? type;
  final bool? isSynced;

  DocumentFilterOptions({
    this.searchQuery,
    this.dateRange,
    this.etat,
    this.type,
    this.isSynced,
  });
}

class ConnectionStatusProvider extends ChangeNotifier {
  bool _isOnline = true;
  bool _isBlocked = false;
  Duration _offlineDuration = Duration.zero;
  Timer? _timer;

  bool get isOnline => _isOnline;

  bool get isBlocked => _isBlocked;

  String get remainingTime => _formatRemainingTime();

  Duration get offlineDuration => _offlineDuration;

  ConnectionStatusProvider() {
    _init();
  }

  Future<void> _init() async {
    await checkInternetConnection();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) async {
      await checkInternetConnection();
      notifyListeners();
    });
  }

  Future<void> checkInternetConnection() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    final prefs = await SharedPreferences.getInstance();

    if (connectivityResult == ConnectivityResult.none) {
      final lastOnline = prefs.getString('lastOnlineCheck');
      if (lastOnline != null) {
        _offlineDuration =
            DateTime.now().difference(DateTime.parse(lastOnline));
        _isBlocked = _offlineDuration.inDays >= 2;
      }
      _isOnline = false;
    } else {
      await prefs.setString(
          'lastOnlineCheck', DateTime.now().toIso8601String());
      _isOnline = true;
      _isBlocked = false;
      _offlineDuration = Duration.zero;
    }
  }

  String _formatRemainingTime() {
    if (_isOnline) return "Connecté";
    final remaining = Duration(days: 2) - _offlineDuration;
    return remaining.isNegative
        ? "Blocage actif"
        : "${remaining.inHours}h ${remaining.inMinutes.remainder(60)}m";
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
