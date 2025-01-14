import 'package:flutter/cupertino.dart';

import '../../../objectbox.g.dart';
import '../../Entity.dart';
import '../../classeObjectBox.dart';

class FacturationProvider with ChangeNotifier {
  List<Document> _factures = [];
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

  List<Document> get factures => _factures;

  Document? get factureEnCours => _factureEnCours;

  List<LigneDocument> get lignesFacture => _lignesFacture;

  List<Produit> get produitsTrouves => _produitsTrouves;

  Client? _clientTemporaire; // Client temporaire

  final ObjectBox _objectBox = ObjectBox();

  FacturationProvider() {
    _objectBox.init().then((_) {
      _chargerFactures();
    });
  }

  Client? _selectedClient;

  Client? get selectedClient => _selectedClient;

// Ajoutez un champ pour gérer l'impayé
  double _impayer = 0.0;

  double get impayer => _impayer;

  void setImpayer(double value) {
    _impayer = value;
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

  void _chargerFactures() {
    _factures = _objectBox.factureBox.getAll();
    notifyListeners();
  }

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
        _factures.add(nouvelleFacture);
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
      _chargerFactures();

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
    _factures.remove(facture);

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
//
// void modifierImpayer(double impayer) {
//   if (_impayer != impayer) {
//     _impayer = impayer;
//     _hasChanges = true;
//     notifyListeners();
//   }
// }
}
