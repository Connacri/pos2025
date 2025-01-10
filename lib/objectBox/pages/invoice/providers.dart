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

  Document? get factureEnEdition => _factureEnEdition;

  List<Document> get factures => _factures;

  Document? get factureEnCours => _factureEnCours;

  List<LigneDocument> get lignesFacture => _lignesFacture;

  List<Produit> get produitsTrouves => _produitsTrouves;
  Client? _clientSelectionne;

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
    // notifyListeners();
  }

  void selectClient(Client client) {
    _selectedClient = client;
    if (_factureEnEdition != null) {
      _factureEnEdition!.client.target = client;
    }
    notifyListeners();
  }

  // Méthode pour réinitialiser le client sélectionné
  void resetClient() {
    _selectedClient = null;
    if (_factureEnCours != null) {
      _factureEnCours!.client.target = null;
    }
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

  // Méthode pour commencer l'édition d'une facture
  void commencerEdition(Document facture) {
    _factureEnEdition = facture;

    notifyListeners();
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

  void modifierLigne(int index, double quantite, double prixUnitaire) {
    if (index >= 0 && index < _lignesFacture.length) {
      _lignesFacture[index].quantite = quantite;
      _lignesFacture[index].prixUnitaire = prixUnitaire;
      notifyListeners();
    }
  }

  void supprimerLigne(int index) {
    if (index >= 0 && index < _lignesFacture.length) {
      print('Suppression de la ligne à l\'index $index'); // Ajoutez ce log
      _lignesFacture.removeAt(index);
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

    // Réinitialiser les lignes de la facture
    _lignesFacture.clear();

    // Notifier les listeners pour mettre à jour l'interface utilisateur
    notifyListeners();
  }

  // void selectionnerFacture(Document facture) {
  //   _factureEnCours = facture;
  //   _lignesFacture = facture.lignesDocument.toList();
  //   notifyListeners();
  // }

  // void selectionnerFacture(Document facture) {
  //   // Créer une copie manuelle de la facture
  //   _factureEnEdition = Document(
  //     id: facture.id,
  //     type: facture.type,
  //     qrReference: facture.qrReference,
  //     impayer: facture.impayer,
  //     derniereModification: facture.derniereModification,
  //     isSynced: facture.isSynced,
  //     syncedAt: facture.syncedAt,
  //     date: facture.date,
  //   );
  //
  //   // Copier les lignes de document
  //   _factureEnEdition!.lignesDocument
  //       .addAll(facture.lignesDocument.map((ligne) {
  //     return LigneDocument(
  //       id: ligne.id,
  //       quantite: ligne.quantite,
  //       prixUnitaire: ligne.prixUnitaire,
  //       derniereModification: ligne.derniereModification,
  //       isSynced: ligne.isSynced,
  //       syncedAt: ligne.syncedAt,
  //     )..produit.target = ligne.produit.target;
  //   }));
  //
  //   _factureEnCours = facture;
  //   _lignesFacture = _factureEnEdition!.lignesDocument.toList();
  //   notifyListeners();
  // }
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

  // Future<void> sauvegarderFacture() async {
  //   print('Sauvegarde de la facture en cours...');
  //
  //   if (_factureEnCours == null) {
  //     print('Création d\'une nouvelle facture');
  //     final nouvelleFacture = Document(
  //       type: 'vente',
  //       qrReference: 'REF${DateTime.now().millisecondsSinceEpoch}',
  //       impayer: 0.0,
  //       derniereModification: DateTime.now(),
  //       isSynced: false,
  //       date: DateTime.now(),
  //     );
  //
  //     nouvelleFacture.lignesDocument.addAll(_lignesFacture);
  //     _objectBox.factureBox.put(nouvelleFacture);
  //
  //     for (final ligne in _lignesFacture) {
  //       ligne.facture.target = nouvelleFacture;
  //       _objectBox.ligneFacture.put(ligne);
  //     }
  //
  //     _factures.add(nouvelleFacture);
  //   } else {
  //     _factureEnCours!.lignesDocument.clear();
  //     _factureEnCours!.lignesDocument.addAll(_lignesFacture);
  //     _objectBox.factureBox.put(_factureEnCours!);
  //
  //     for (final ligne in _lignesFacture) {
  //       ligne.facture.target = _factureEnCours;
  //       _objectBox.ligneFacture.put(ligne);
  //     }
  //   }
  //
  //   _factureEnCours = null;
  //   _lignesFacture.clear();
  //   _chargerFactures();
  //
  //   print('Facture sauvegardée avec succès');
  // }
  Future<void> sauvegarderFacture() async {
    print('Sauvegarde de la facture en cours...');

    if (_factureEnCours == null) {
      print('Création d\'une nouvelle facture');
      final nouvelleFacture = Document(
        type: 'vente',
        qrReference: 'REF${DateTime.now().millisecondsSinceEpoch}',
        impayer: _impayer,
        // Ajoutez l'impayé
        derniereModification: DateTime.now(),
        isSynced: false,
        date: DateTime.now(),
      );

      nouvelleFacture.lignesDocument.addAll(_lignesFacture);
      _objectBox.factureBox.put(nouvelleFacture);

      for (final ligne in _lignesFacture) {
        ligne.facture.target = nouvelleFacture;
        _objectBox.ligneFacture.put(ligne);
      }

      _factures.add(nouvelleFacture);
    } else {
      _factureEnCours!.lignesDocument.clear();
      _factureEnCours!.lignesDocument.addAll(_lignesFacture);
      _factureEnCours!.impayer = _impayer; // Mettez à jour l'impayé
      _objectBox.factureBox.put(_factureEnCours!);

      for (final ligne in _lignesFacture) {
        ligne.facture.target = _factureEnCours;
        _objectBox.ligneFacture.put(ligne);
      }
    }

    _factureEnCours = null;
    _lignesFacture.clear();
    _impayer = 0.0; // Réinitialisez l'impayé
    _chargerFactures();

    print('Facture sauvegardée avec succès');
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
  bool isEditedPu = false;
}
