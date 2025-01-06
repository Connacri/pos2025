import 'package:objectbox/objectbox.dart';

@Entity()
class User {
  @Id()
  int id;
  String? photo;
  String username;
  String password;
  String email;
  String? phone;
  String role;
  DateTime derniereModification;
  bool isSynced;
  DateTime syncedAt;

  final crud = ToOne<Crud>();

  User({
    this.id = 0,
    this.photo,
    required this.username,
    required this.password,
    this.phone,
    required this.email,
    required this.role,
    required this.derniereModification,
    this.isSynced = false,
    DateTime? syncedAt,
  }) : syncedAt = syncedAt ?? DateTime.now();

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? 0,
      photo: json['photo'],
      username: json['username'] ?? '',
      password: json['password'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'],
      role: json['role'] ?? '',
      derniereModification: json['derniereModification'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['derniereModification'])
          : DateTime.now(),
    );
  }
}

@Entity()
class Produit {
  int id;
  @Unique()
  @Index() // Indexation du QR pour une recherche rapide
  String? qr; // Stocker les QR codes comme une chaîne avec des séparateurs
  String? image;
  String nom;
  String? description;
  double prixVente;
  double? tax;
  double? qtyPartiel;
  double? pricePartielVente;
  double? minimStock;
  int? alertPeremption;
  bool isSynced;
  DateTime syncedAt;

  @Property(type: PropertyType.date)
  DateTime derniereModification;

  @Backlink()
  final approvisionnements = ToMany<Approvisionnement>();

  // Correction : renommage de la relation ToMany<QrCode>

  // final qrcodes = ToMany<QrCode>();
  final crud = ToOne<Crud>();

  Produit({
    this.id = 0,
    this.qr,
    this.image,
    required this.nom,
    this.description,
    required this.prixVente,
    this.tax,
    this.qtyPartiel,
    this.pricePartielVente,
    this.minimStock,
    this.alertPeremption,
    required this.derniereModification,
    this.isSynced = false,
    DateTime? syncedAt,
  }) : syncedAt = syncedAt ??
            DateTime.now(); // // Getters pour calculer les valeurs dynamiques
  // double get prixAchat => approvisionnements.isNotEmpty
  //     ? approvisionnements.map((a) => a.prixAchat).reduce((a, b) => a + b) /
  //         approvisionnements.length
  //     : 0;
// Getter pour récupérer les QR codes sous forme de liste
  List<String> get qrCodeList {
    return qr != null && qr!.isNotEmpty ? qr!.split(',') : [];
  }

  // Setter pour mettre à jour les QR codes
  set qrCodeList(List<String> codes) {
    qr = codes.join(',');
  }

  // // Getter pour récupérer la liste des QR codes sous forme de liste
  // List<String> get qrCodeList {
  //   return qr != null && qr!.isNotEmpty ? List<String>.from(json.decode(qr!)) : [];
  // }
  //
  // // Setter pour mettre à jour les QR codes dans le format JSON
  // set qrCodeList(List<String> codes) {
  //   qr = json.encode(codes);
  // }
  // Méthode pour ajouter un QR code à la liste existante
  void addQrCode(String code) {
    List<String> codes = qrCodeList;
    codes.add(code);
    qrCodeList = codes; // Met à jour la chaîne JSON avec la nouvelle liste
  }

  double get stock => approvisionnements.fold(0, (sum, a) => sum + a.quantite);

// Méthode pour calculer le stock total à partir des approvisionnements
  double calculerStockTotal() {
    // Si la liste des approvisionnements est vide, retourne 0
    if (approvisionnements.isEmpty) {
      return 0.0;
    }

    // Utilise fold() pour calculer la somme des quantités d'approvisionnement
    double stockTotal = approvisionnements.fold(0.0, (total, appro) {
      return total + appro.quantite;
    });

    return stockTotal;
  }

  factory Produit.fromJson(Map<String, dynamic> json) {
    return Produit(
      id: json['id'] ?? 0,
      qr: json['qr'],
      image: json['image'],
      nom: json['nom'] ?? '',
      description: json['description'] ?? '',
      prixVente: (json['prixVente'] ?? 0).toDouble(),
      tax: (json['tax'] ?? 0).toDouble(),
      qtyPartiel: (json['qtyPartiel'] ?? 0).toDouble(),
      pricePartielVente: (json['pricePartielVente'] ?? 0.0).toDouble(),
      minimStock: (json['minimStock'] ?? 0).toDouble(),
      alertPeremption: (json['alertPeremption'] ?? 0).toInt(),
      derniereModification: json['derniereModification'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['derniereModification'])
          : DateTime.now(),
    );
  }
}

@Entity()
class Approvisionnement {
  int id;
  double quantite;
  bool isSynced;
  double? prixAchat;
  DateTime? derniereModification;
  DateTime syncedAt;

  @Property(type: PropertyType.date)
  DateTime? datePeremption;

  final produit = ToOne<Produit>();

  // Relation vers l'entité Fournisseur
  final fournisseur = ToOne<Fournisseur>();
  final crud = ToOne<Crud>();

  Approvisionnement({
    this.id = 0,
    required this.quantite,
    this.prixAchat,
    this.datePeremption,
    this.derniereModification,
    this.isSynced = false,
    DateTime? syncedAt,
  }) : syncedAt = syncedAt ?? DateTime.now();

  factory Approvisionnement.fromJson(Map<String, dynamic> json) {
    return Approvisionnement(
      id: json['id'] ?? 0,
      quantite: (json['quantite'] ?? 0).toDouble(),
      prixAchat: (json['prixAchat'] ?? 0).toDouble(),
      datePeremption: json['datePeremption'] != null
          ? DateTime.parse(json['datePeremption'])
          : null,
      derniereModification: json['derniereModification'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['derniereModification'])
          : DateTime.now(),
    );
  }
}

@Entity()
class Crud {
  int id;
  int? createdBy;
  int updatedBy;
  int? deletedBy;
  bool isSynced;
  @Property(type: PropertyType.date)
  DateTime? dateCreation;
  DateTime syncedAt;

  @Property(type: PropertyType.date)
  DateTime derniereModification;

  @Property(type: PropertyType.date)
  DateTime? dateDeleting;

  Crud({
    this.id = 0,
    this.createdBy,
    required this.updatedBy,
    this.deletedBy,
    this.dateCreation,
    required this.derniereModification,
    this.dateDeleting,
    this.isSynced = false,
    DateTime? syncedAt,
  }) : syncedAt = syncedAt ?? DateTime.now();

  factory Crud.fromJson(Map<String, dynamic> json) {
    return Crud(
      id: json['id'] ?? 0,
      createdBy: (json['createdBy']).toInt(),
      updatedBy: (json['updatedBy']).toInt(),
      deletedBy: (json['deletedBy']).toInt(),
      dateCreation: json['dateCreation'] != null
          ? DateTime.parse(json['dateCreation'])
          : null,
      dateDeleting: json['dateDeleting'] != null
          ? DateTime.parse(json['dateDeleting'])
          : null,
      derniereModification: DateTime.parse(
          json['derniereModification'] //?? DateTime.now().toIso8601String()
          ),
    );
  }
}

@Entity()
class Fournisseur {
  int id;
  @Unique()
  String? qr;
  String nom;
  String? phone;
  String? adresse;
  DateTime derniereModification;
  bool isSynced;
  DateTime syncedAt;

  final crud = ToOne<Crud>();

  @Backlink()
  final approvisionnements = ToMany<Approvisionnement>();

  Fournisseur({
    this.id = 0,
    this.qr,
    required this.nom,
    this.phone,
    this.adresse,
    required this.derniereModification,
    this.isSynced = false,
    DateTime? syncedAt,
  }) : syncedAt = syncedAt ?? DateTime.now();

  factory Fournisseur.fromJson(Map<String, dynamic> json) {
    return Fournisseur(
      id: json['id'] ?? 0,
      qr: json['qr'],
      nom: json['nom'] ?? '',
      phone: json['phone'],
      adresse: json['adresse'],
      derniereModification: json['derniereModification'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['derniereModification'])
          : DateTime.now(),
    );
  }
}

@Entity()
class Client {
  int id;
  String qr;
  String nom;
  String phone;
  String adresse;
  String? description;
  DateTime derniereModification;
  bool isSynced;
  DateTime syncedAt;

  @Backlink()
  final factures = ToMany<Document>();

  final crud = ToOne<Crud>();

  Client({
    this.id = 0,
    required this.qr,
    required this.nom,
    required this.phone,
    required this.adresse,
    this.description,
    required this.derniereModification,
    this.isSynced = false,
    DateTime? syncedAt,
  }) : syncedAt = syncedAt ?? DateTime.now();

  factory Client.fromJson(Map<String, dynamic> json) {
    return Client(
      id: json['id'] ?? 0,
      qr: json['qr'] ?? '',
      nom: json['nom'] ?? '',
      phone: json['phone'] ?? '',
      adresse: json['adresse'] ?? '',
      description: json['description'] ?? '',
      derniereModification: json['derniereModification'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['derniereModification'])
          : DateTime.now(),
    );
  }
}

@Entity()
class Document {
  //int id;
  @Id()
  int id = 0;
  String type; // 'vente', 'achat', etc.
  String qrReference;
  double? impayer;
  DateTime derniereModification;
  bool isSynced;
  DateTime syncedAt;

  @Property(type: PropertyType.date)
  DateTime date;

  // Relations spécifiques
  final client = ToOne<Client>();
  final fournisseur = ToOne<Fournisseur>();
  final crud = ToOne<Crud>();

  double montantVerse = 0.0; // Montant payé

  @Backlink()
  final lignesDocument = ToMany<LigneDocument>();

  Document({
    this.id = 0,
    required this.date,
    required this.qrReference,
    required this.type,
    this.montantVerse = 0.0,
    required this.impayer,
    required this.derniereModification,
    this.isSynced = false,
    DateTime? syncedAt,
  }) : syncedAt = syncedAt ?? DateTime.now();

  // Montant total calculé
  double get montantTotal =>
      lignesDocument.fold(0.0, (sum, ligne) => sum + ligne.sousTotal);

  // État calculé en fonction du montant payé et du total
  DocumentEtat get etat {
    if (montantVerse >= montantTotal) {
      return DocumentEtat.paye;
    } else if (montantVerse > 0) {
      return DocumentEtat.partiellementPaye;
    } else {
      return DocumentEtat.nonPaye;
    }
  }

  // Validation basée sur le type
  bool get estValide {
    if (type == 'vente' && client.target == null) {
      return false;
    }
    if (type == 'achat' && fournisseur.target == null) {
      return false;
    }
    return true;
  }

  factory Document.fromJson(Map<String, dynamic> json) {
    return Document(
      id: json['id'] ?? 0,
      type: json['type'] ?? '',
      qrReference: json['qrReference'] ?? '',
      impayer: (json['impayer'] ?? 0).toDouble(),
      date: DateTime.parse(json['date']),
      derniereModification: json['derniereModification'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['derniereModification'])
          : DateTime.now(),
    );
  }
}

@Entity()
class LigneDocument {
  // int id;
  @Id()
  int id = 0;
  double quantite;
  double prixUnitaire;
  DateTime derniereModification;
  bool isSynced;
  DateTime syncedAt;

  final produit = ToOne<Produit>();
  final facture = ToOne<Document>();

  LigneDocument({
    this.id = 0,
    required this.quantite,
    required this.prixUnitaire,
    required this.derniereModification,
    this.isSynced = false,
    DateTime? syncedAt,
  }) : syncedAt = syncedAt ?? DateTime.now();

  // Sous-total calculé automatiquement
  double get sousTotal => quantite * prixUnitaire;

  factory LigneDocument.fromJson(Map<String, dynamic> json) {
    return LigneDocument(
      id: json['id'] ?? 0,
      quantite: (json['quantite'] ?? 0).toDouble(),
      prixUnitaire: (json['prixUnitaire'] ?? 0).toDouble(),
      derniereModification: json['derniereModification'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['derniereModification'])
          : DateTime.now(),
    );
  }
}

// État des documents
enum DocumentEtat {
  paye,
  partiellementPaye,
  nonPaye,
}

@Entity()
class DeletedProduct {
  @Id()
  int id = 0;
  String name;
  String description;
  double price;
  int quantity;
  int delaisPeremption;
  DateTime derniereModification;
  bool isSynced;
  DateTime syncedAt;

  final crud = ToOne<Crud>();

  DeletedProduct({
    required this.name,
    required this.description,
    required this.price,
    required this.quantity,
    required this.delaisPeremption,
    required this.derniereModification,
    this.isSynced = false,
    DateTime? syncedAt,
  }) : syncedAt = syncedAt ?? DateTime.now();

  factory DeletedProduct.fromJson(Map<String, dynamic> json) {
    return DeletedProduct(
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      quantity: (json['quantity'] ?? 0).toInt(),
      delaisPeremption: (json['delaisPeremption']).toInt(),
      derniereModification: json['derniereModification'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['derniereModification'])
          : DateTime.now(),
    );
  }
}
