import 'package:flutter/material.dart';
import 'package:objectbox/objectbox.dart';
import 'package:provider/provider.dart';

import '../../../objectbox.g.dart';
import '../../Entity.dart';
import '../../classeObjectBox.dart';

class CommerceProvider1 extends ChangeNotifier {
  final ObjectBox _objectBox;

  CommerceProvider1(this._objectBox);

  Future<Produit?> getProduitByQr(String qrCode) async {
    final query = _objectBox.produitBox.query(Produit_.qr.equals(qrCode));
    final produits = await query.build().find();
    return produits.isNotEmpty ? produits.first : null;
  }

  Future<void> updateProduitStock(Produit produit, double quantity) async {
    // Find the corresponding approvisionnement
    final approvisionnement = produit.approvisionnements.firstWhere(
      (a) => a.quantite >= quantity,
      orElse: () =>
          throw Exception('Not enough stock for product: ${produit.nom}'),
    );

    if (approvisionnement != null) {
      // Update the quantity of the approvisionnement
      approvisionnement.quantite -= quantity;
      _objectBox.approvisionnementBox.put(approvisionnement);
    } else {
      throw Exception('Not enough stock for product: ${produit.nom}');
    }
  }
}

class CartProvider1 extends ChangeNotifier {
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

  CartProvider1(this._objectBox) {
    fetchFactures();
  }

  void selectFacture(Document facture) {
    _facture = facture;
    notifyListeners();
  }

  void fetchFactures() {
    _factures = _objectBox.factureBox.getAll();
    notifyListeners();
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
    _facture.client.target = client;
    notifyListeners();
  }

  void resetClient() {
    _selectedClient = null;
    notifyListeners();
  }

  Future<void> createAndSelectClient(
      String nom,
      String phone,
      String adresse,
      String description,
      DateTime dateCreation,
      DateTime derniereModification) async {
    final newClient = Client(
      qr: await generateQRCode('${_selectedClient!.id}'),
      nom: nom,
      phone: phone,
      adresse: adresse,
      description: description,
      derniereModification: DateTime.now(),
    );
    _objectBox.clientBox.put(newClient);
    selectClient(newClient);
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
    notifyListeners();
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
    notifyListeners();
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

    List<Document> facturesDansIntervalle =
        _objectBox.factureBox.getAll().where((facture) {
      return (facture.date.isAfter(startDate) &&
              facture.date.isBefore(endDate)) ||
          facture.date.isAtSameMomentAs(startDate) ||
          facture.date.isAtSameMomentAs(endDate);
    }).toList();

    for (var facture in facturesDansIntervalle) {
      double montantHT = facture.lignesDocument.fold(0.0, (sum, ligne) {
        return sum + (ligne.prixUnitaire * ligne.quantite);
      });

      double tva = montantHT * tvaRate;
      double montantTTC = montantHT + tva;

      totalTTC += montantTTC;
      totalTVA += tva;

      totalImpayes += facture.impayer ?? 0.0;
    }

    return {
      'totalTTC': totalTTC,
      'totalImpayes': totalImpayes,
      'totalTVA': totalTVA,
    };
  }

  Future<void> saveFacture(CommerceProvider1 commerceProvider1) async {
    if (_selectedClient != null) {
      _objectBox.clientBox.put(_selectedClient!);
      _facture.client.target = _selectedClient;
    }

    _facture.qrReference =
        await generateQRCode('${_facture.id} ${_facture.date}');

    _objectBox.factureBox.put(_facture);

    for (var ligne in _facture.lignesDocument) {
      final produit = ligne.produit.target;
      if (produit != null) {
        await commerceProvider1.updateProduitStock(produit, ligne.quantite);
      }
      _objectBox.ligneFacture.put(ligne);
    }

    _facture = Document(
      date: DateTime.now(),
      qrReference: '',
      impayer: 0.0,
      derniereModification: DateTime.now(),
      type: '',
    );
    _selectedClient = null;

    notifyListeners();

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
    return "QR_${gRGenerated}";
  }

  Future<void> deleteFacture(Document facture) async {
    _objectBox.factureBox.remove(facture.id);
    notifyListeners();
    fetchFactures();
  }

  void loadFactureForEditing(Document facture) {
    _facture = facture;
    notifyListeners();
  }

  Future<void> updateFacture(int factureId) async {
    final existingFacture = _factures.firstWhere((f) => f.id == factureId);
    existingFacture.lignesDocument.clear();
    for (var ligne in _facture.lignesDocument) {
      existingFacture.lignesDocument.add(ligne);
    }
    existingFacture.impayer = _facture.impayer;
    existingFacture.date = DateTime.now();
    await _objectBox.factureBox.put(existingFacture);
    notifyListeners();
  }

  Future<void> deleteAllFactures() async {
    final box = _objectBox.factureBox;
    box.removeAll();
    fetchFactures();
  }
}
