import 'dart:io';
import 'dart:isolate';
import 'dart:math';
import 'package:excel/excel.dart';
import 'package:faker/faker.dart';
import 'package:flutter/material.dart';
import 'package:objectbox/objectbox.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import '../objectBox/Entity.dart';
import '../objectbox.g.dart';
import 'dart:math' show Random;
import 'package:permission_handler/permission_handler.dart';

class ObjectBox {
  late final Store store;
  late final Box<User> userBox;
  late final Box<Crud> crudBox;
  late final Box<Produit> produitBox;
  late final Box<Approvisionnement> approvisionnementBox;
  late final Box<Fournisseur> fournisseurBox;
  late final Box<Document> factureBox;
  late final Box<LigneDocument> ligneFacture;
  late final Box<Client> clientBox;
  late final Box<DeletedProduct> deletedProduct;
  late final Box<Annonces> annonces;
  Admin? admin; // Admin optionnel

  static final ObjectBox _singleton = ObjectBox._internal();

  factory ObjectBox() => _singleton;

  final random = Random();

  ObjectBox._internal();

  Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();
    if (!Store.isOpen('${dir.path}/objectbox')) {
      store = await openStore(directory: '${dir.path}/objectbox');
      userBox = Box<User>(store);
      crudBox = Box<Crud>(store);
      produitBox = Box<Produit>(store);
      approvisionnementBox = Box<Approvisionnement>(store);
      fournisseurBox = Box<Fournisseur>(store);
      factureBox = Box<Document>(store);
      ligneFacture = Box<LigneDocument>(store);
      clientBox = Box<Client>(store);
      deletedProduct = Box<DeletedProduct>(store);
      annonces = Box<Annonces>(store);

      // Démarre Admin si disponible et vérifie son statut
      if (Admin.isAvailable()) {
        admin = Admin(store);
        print(
            'Admin a démarré avec succès et est accessible à http://127.0.0.1:8090');
      } else {
        print('Admin n\'est pas disponible.');
      }
    }
  }

  bool isAdminAvailable() {
    return admin != null; // Retourne vrai si Admin est initialisé
  }

  void close() {
    admin?.close(); // Ferme Admin si initialisé
    store.close();
  }

  void fillWithFakeData(int userCount, int clientCount, int fournisseurCount,
      int produitCount, int approvisionnementCount) {
    final faker = Faker();
    final random = Random();
    List<String> roles = [
      'admin',
      'public',
      'vendeur',
      'owner',
      'manager',
      'it'
    ];
    Set<String> qrSet = {}; // Utiliser un Set pour garantir l'unicité des QR

    List<String> types = [
      'vente',
      'achat',
      'devis',
      'facture',
      'bon',
      'proforma'
    ];

    // Créer des utilisateurs
    List<User> users = List.generate(userCount, (index) {
      roles.shuffle(random); // Mélanger les rôles
      return User(
        phone: faker.phoneNumber.de(),
        username: faker.person.name(),
        password: faker.internet.password(),
        email: faker.internet.email(),
        role: roles.first,
        derniereModification: DateTime.now(),
      );
    });
    userBox.putMany(users);

    // Fonction pour générer un QR unique
    String generateUniqueQr() {
      String uniqueQr;
      do {
        uniqueQr = faker.randomGenerator.integer(999999).toString();
      } while (qrSet.contains(uniqueQr)); // Vérifier l'unicité du QR
      qrSet.add(uniqueQr);
      return uniqueQr;
    }

    // Créer des fournisseurs
    List<Fournisseur> fournisseurs = List.generate(fournisseurCount, (index) {
      String uniqueQr = generateUniqueQr();

      return Fournisseur(
        nom: faker.company.name(),
        phone: faker.phoneNumber.us(),
        adresse: faker.address.streetAddress(),
        qr: uniqueQr,
        derniereModification:
            faker.date.dateTime(minYear: 2000, maxYear: DateTime.now().year),
      )..crud.target = Crud(
          createdBy: 1,
          updatedBy: 1,
          deletedBy: 1,
          dateCreation: faker.date.dateTime(minYear: 2010, maxYear: 2024),
          derniereModification:
              faker.date.dateTime(minYear: 2000, maxYear: DateTime.now().year),
        );
    });
    fournisseurBox.putMany(fournisseurs);

    // Créer des produits
    List<Produit> produits = List.generate(produitCount, (index) {
      String uniqueQr;
      do {
        uniqueQr = generateUniqueQr();
      } while (produitBox
          .query(Produit_.qr.equals(uniqueQr))
          .build()
          .find()
          .isNotEmpty);

      return Produit(
        image: 'https://picsum.photos/200/300?random=$index',
        nom: faker.food.dish(),
        prixVente: faker.randomGenerator.decimal(min: 500, scale: 2),
        description: faker.lorem.sentence(),
        qr: uniqueQr,
        minimStock: faker.randomGenerator.decimal(min: 1, scale: 2),
        alertPeremption: random.nextInt(5),
        derniereModification:
            faker.date.dateTime(minYear: 2000, maxYear: DateTime.now().year),
      )..crud.target = Crud(
          createdBy: 1,
          updatedBy: 1,
          deletedBy: 1,
          dateCreation: faker.date.dateTime(minYear: 2010, maxYear: 2024),
          derniereModification:
              faker.date.dateTime(minYear: 2000, maxYear: DateTime.now().year),
        );
    });
    produitBox.putMany(produits);

    // Créer des approvisionnements et les lier aux produits
    List<Approvisionnement> approvisionnements = [];
    for (var produit in produits) {
      // Générer un nombre aléatoire d'approvisionnements par produit
      int numberOfApprovisionnements =
          faker.randomGenerator.integer(approvisionnementCount, min: 1);

      for (int i = 0; i < numberOfApprovisionnements; i++) {
        final fournisseur = fournisseurs[random.nextInt(fournisseurs.length)];

        Approvisionnement approvisionnement = Approvisionnement(
          quantite: faker.randomGenerator.decimal(min: 10, scale: 2),
          prixAchat: faker.randomGenerator.decimal(min: 100, scale: 2),
          datePeremption: faker.date
              .dateTimeBetween(DateTime.now(), DateTime(2025, 12, 31)),
          derniereModification:
              faker.date.dateTime(minYear: 2000, maxYear: DateTime.now().year),
        )
          ..crud.target = Crud(
            createdBy: 1,
            updatedBy: 1,
            deletedBy: 1,
            dateCreation: faker.date.dateTime(minYear: 2010, maxYear: 2024),
            derniereModification: faker.date
                .dateTime(minYear: 2000, maxYear: DateTime.now().year),
          )
          ..produit.target = produit
          ..fournisseur.target = fournisseur;

        approvisionnements.add(approvisionnement);
      }
    }
    approvisionnementBox.putMany(approvisionnements);

    // Créer des clients
    List<Client> clients = List.generate(clientCount, (index) {
      String uniqueQr = generateUniqueQr();

      return Client(
        qr: uniqueQr,
        nom: faker.person.name(),
        phone: faker.phoneNumber.us(),
        adresse: faker.address.streetAddress(),
        description: faker.lorem.sentence(),
        derniereModification:
            faker.date.dateTime(minYear: 2000, maxYear: DateTime.now().year),
      )..crud.target = Crud(
          createdBy: 1,
          updatedBy: 1,
          deletedBy: 1,
          dateCreation: faker.date.dateTime(minYear: 2010, maxYear: 2024),
          derniereModification:
              faker.date.dateTime(minYear: 2000, maxYear: DateTime.now().year),
        );
    });
    clientBox.putMany(clients);

    // Créer des factures et les associer aux clients
    for (var client in clients) {
      int numberOfFactures = faker.randomGenerator.integer(50);
      List<Document> factures = List.generate(numberOfFactures, (_) {
        String uniqueQr = generateUniqueQr();

        types.shuffle(random);

        Document facture = Document(
          type: types.first,
          qrReference: uniqueQr,
          impayer: faker.randomGenerator.decimal(min: 0, scale: 2),
          date: faker.date.dateTime(minYear: 2010, maxYear: 2024),
          derniereModification:
              faker.date.dateTime(minYear: 2000, maxYear: DateTime.now().year),
        )..crud.target = Crud(
            createdBy: 1,
            updatedBy: 1,
            deletedBy: 1,
            dateCreation: faker.date.dateTime(minYear: 2010, maxYear: 2024),
            derniereModification: faker.date
                .dateTime(minYear: 2000, maxYear: DateTime.now().year),
          );

        // Créer des lignes de facture
        int numberOfLignes = faker.randomGenerator.integer(5, min: 1);
        for (int i = 0; i < numberOfLignes; i++) {
          final produit = produits[random.nextInt(produits.length)];
          final ligneDocument = LigneDocument(
            quantite: faker.randomGenerator.decimal(min: 1, scale: 10),
            prixUnitaire: produit.prixVente,
            derniereModification: faker.date
                .dateTime(minYear: 2000, maxYear: DateTime.now().year),
          );
          ligneDocument.produit.target = produit;
          ligneDocument.facture.target = facture;
          facture.lignesDocument.add(ligneDocument);
        }

        return facture;
      });

      client.factures.addAll(factures);
    }

    clientBox.putMany(clients);
  }

  // void fillWithFakeData(int userCount, int clientCount, int fournisseurCount,
  //     int produitCount, int approvisionnementCount) {
  //   final faker = Faker();
  //   final random = Random();
  //   List<String> roles = [
  //     'admin',
  //     'public',
  //     'vendeur',
  //     'owner',
  //     'manager',
  //     'it'
  //   ];
  //   Set<String> qrSet = {}; // Utiliser un Set pour garantir l'unicité des QR
  //
  //   List<String> types = [
  //     'vente',
  //     'achat',
  //     'devis',
  //     'facture',
  //     'bon',
  //     'proforma'
  //   ];
  //
  //   // Créer des utilisateurs
  //   List<User> users = List.generate(userCount, (index) {
  //     roles.shuffle(random); // Mélanger les rôles
  //     return User(
  //       phone: faker.phoneNumber.de(),
  //       username: faker.person.name(),
  //       password: faker.internet.password(),
  //       email: faker.internet.email(),
  //       role: roles.first,
  //       derniereModification:
  //           DateTime.now(), // Assigner le premier rôle après mélange
  //     );
  //   });
  //   userBox.putMany(users);
  //
  //   // Fonction pour générer un QR unique
  //   String generateUniqueQr() {
  //     String uniqueQr;
  //     do {
  //       uniqueQr = faker.randomGenerator.integer(999999).toString();
  //     } while (qrSet.contains(uniqueQr)); // Vérifier l'unicité du QR
  //     qrSet.add(uniqueQr);
  //     return uniqueQr;
  //   }
  //
  //   // Créer des fournisseurs
  //   List<Fournisseur> fournisseurs = List.generate(fournisseurCount, (index) {
  //     String uniqueQr = generateUniqueQr();
  //
  //     return Fournisseur(
  //       nom: faker.company.name(),
  //       phone: faker.phoneNumber.us(),
  //       adresse: faker.address.streetAddress(),
  //       qr: uniqueQr,
  //       // QR unique
  //       derniereModification:
  //           faker.date.dateTime(minYear: 2000, maxYear: DateTime.now().year),
  //     )..crud.target = Crud(
  //         createdBy: 1,
  //         updatedBy: 1,
  //         deletedBy: 1,
  //         dateCreation: faker.date.dateTime(minYear: 2010, maxYear: 2024),
  //         derniereModification:
  //             faker.date.dateTime(minYear: 2000, maxYear: DateTime.now().year),
  //       );
  //   });
  //   fournisseurBox.putMany(fournisseurs);
  //
  //   // Créer des produits
  //   List<Produit> produits = List.generate(produitCount, (index) {
  //     String uniqueQr;
  //     do {
  //       uniqueQr = generateUniqueQr();
  //     } while (produitBox
  //         .query(Produit_.qr.equals(uniqueQr))
  //         .build()
  //         .find()
  //         .isNotEmpty);
  //
  //     return Produit(
  //       image: 'https://picsum.photos/200/300?random=$index',
  //       nom: faker.food.dish(),
  //       prixVente: faker.randomGenerator.decimal(min: 500, scale: 2),
  //       description: faker.lorem.sentence(),
  //       qr: uniqueQr,
  //       // QR unique
  //       minimStock: faker.randomGenerator.decimal(min: 1, scale: 2),
  //       alertPeremption: random.nextInt(5),
  //       derniereModification:
  //           faker.date.dateTime(minYear: 2000, maxYear: DateTime.now().year),
  //     )..crud.target = Crud(
  //         createdBy: 1,
  //         updatedBy: 1,
  //         deletedBy: 1,
  //         dateCreation: faker.date.dateTime(minYear: 2010, maxYear: 2024),
  //         derniereModification:
  //             faker.date.dateTime(minYear: 2000, maxYear: DateTime.now().year),
  //       );
  //   });
  //   produitBox.putMany(produits);
  //
  //   // Créer des approvisionnements
  //   List<Approvisionnement> approvisionnements =
  //       List.generate(approvisionnementCount, (_) {
  //     final produit = produits[random.nextInt(produits.length)];
  //     final fournisseur = fournisseurs[random.nextInt(fournisseurs.length)];
  //
  //     return Approvisionnement(
  //       quantite: faker.randomGenerator.decimal(min: 10, scale: 2),
  //       prixAchat: faker.randomGenerator.decimal(min: 100, scale: 2),
  //       datePeremption:
  //           faker.date.dateTimeBetween(DateTime.now(), DateTime(2025, 12, 31)),
  //       derniereModification:
  //           faker.date.dateTime(minYear: 2000, maxYear: DateTime.now().year),
  //     )
  //       ..crud.target = Crud(
  //         createdBy: 1,
  //         updatedBy: 1,
  //         deletedBy: 1,
  //         dateCreation: faker.date.dateTime(minYear: 2010, maxYear: 2024),
  //         derniereModification:
  //             faker.date.dateTime(minYear: 2000, maxYear: DateTime.now().year),
  //       )
  //       ..produit.target = produit
  //       ..fournisseur.target = fournisseur;
  //   });
  //   approvisionnementBox.putMany(approvisionnements);
  //
  //   // Créer des clients
  //   List<Client> clients = List.generate(clientCount, (index) {
  //     String uniqueQr = generateUniqueQr();
  //
  //     return Client(
  //       qr: uniqueQr,
  //       // QR unique
  //       nom: faker.person.name(),
  //       phone: faker.phoneNumber.us(),
  //       adresse: faker.address.streetAddress(),
  //       description: faker.lorem.sentence(),
  //       derniereModification:
  //           faker.date.dateTime(minYear: 2000, maxYear: DateTime.now().year),
  //     )..crud.target = Crud(
  //         createdBy: 1,
  //         updatedBy: 1,
  //         deletedBy: 1,
  //         dateCreation: faker.date.dateTime(minYear: 2010, maxYear: 2024),
  //         derniereModification:
  //             faker.date.dateTime(minYear: 2000, maxYear: DateTime.now().year),
  //       );
  //   });
  //   clientBox.putMany(clients);
  //
  //   // Créer des factures et les associer aux clients
  //   for (var client in clients) {
  //     int numberOfFactures = faker.randomGenerator.integer(50);
  //     List<Document> factures = List.generate(numberOfFactures, (_) {
  //       String uniqueQr = generateUniqueQr();
  //
  //       types.shuffle(random);
  //
  //       Document facture = Document(
  //         type: types.first,
  //         qrReference: uniqueQr,
  //         // QR unique
  //         impayer: faker.randomGenerator.decimal(min: 0, scale: 2),
  //         date: faker.date.dateTime(minYear: 2010, maxYear: 2024),
  //         derniereModification:
  //             faker.date.dateTime(minYear: 2000, maxYear: DateTime.now().year),
  //       )..crud.target = Crud(
  //           createdBy: 1,
  //           updatedBy: 1,
  //           deletedBy: 1,
  //           dateCreation: faker.date.dateTime(minYear: 2010, maxYear: 2024),
  //           derniereModification: faker.date
  //               .dateTime(minYear: 2000, maxYear: DateTime.now().year),
  //         );
  //
  //       // Créer des lignes de facture
  //       int numberOfLignes = faker.randomGenerator.integer(5, min: 1);
  //       for (int i = 0; i < numberOfLignes; i++) {
  //         final produit = produits[random.nextInt(produits.length)];
  //         final ligneDocument = LigneDocument(
  //           quantite: faker.randomGenerator.decimal(min: 1, scale: 10),
  //           prixUnitaire: produit.prixVente,
  //           derniereModification: faker.date
  //               .dateTime(minYear: 2000, maxYear: DateTime.now().year),
  //         );
  //         ligneDocument.produit.target = produit;
  //         ligneDocument.facture.target = facture;
  //         facture.lignesDocument.add(ligneDocument);
  //       }
  //
  //       return facture;
  //     });
  //
  //     client.factures.addAll(factures);
  //   }
  //
  //   clientBox.putMany(clients);
  // }

  Future<void> insertOrUpdateProduit(Produit produit) async {
    try {
      // Vérifier si un produit avec le même QR existe déjà
      final existingProduit =
          produitBox.query(Produit_.qr.equals(produit.qr!)).build().findFirst();

      if (existingProduit != null) {
        // Un produit avec ce QR existe déjà, mettons à jour ses propriétés
        existingProduit.nom = produit.nom;
        existingProduit.description = produit.description;
        existingProduit.prixVente = produit.prixVente;
        existingProduit.minimStock = produit.minimStock;
        existingProduit.alertPeremption = produit.alertPeremption;
        existingProduit.derniereModification = DateTime.now();

        // Mettre à jour le produit existant
        produitBox.put(existingProduit);
        print(
            'Produit mis à jour : ${existingProduit.id} - ${existingProduit.nom}');
      } else {
        // Aucun produit avec ce QR n'existe, insérons le nouveau produit
        final id = produitBox.put(produit);
        print('Nouveau produit inséré : $id - ${produit.nom}');
      }
    } catch (e) {
      print('Erreur lors de l\'insertion/mise à jour du produit : $e');
      // Gérer l'erreur selon vos besoins (par exemple, afficher une alerte à l'utilisateur)
    }
  }

  Future<void> importProduitsDepuisExcel(
    String filePath,
    int userCount,
    int clientCount,
    int fournisseurCount,
  ) async {
    final faker = Faker();
    final random = Random();
    final file = File(filePath);
    await checkStoragePermission();
    final bytes = await file.readAsBytes();
    final excel = Excel.decodeBytes(bytes);
    final roles = ['admin', 'public', 'vendeur', 'owner', 'manager', 'it'];

    // Création des utilisateurs
    final users = List.generate(userCount, (_) {
      roles.shuffle(random);
      return User(
        phone: faker.phoneNumber.de(),
        username: faker.person.name(),
        password: faker.internet.password(),
        email: faker.internet.email(),
        role: roles.first,
        derniereModification: DateTime.now(),
      );
    });
    await userBox.putMany(users);

    // Création des fournisseurs
    final fournisseurs = List.generate(fournisseurCount, (_) {
      final now = DateTime.now();
      return Fournisseur(
        nom: faker.company.name(),
        phone: faker.phoneNumber.us(),
        adresse: faker.address.streetAddress(),
        qr: faker.randomGenerator.integer(999999).toString(),
        derniereModification:
            faker.date.dateTime(minYear: 2000, maxYear: DateTime.now().year),
      )..crud.target = Crud(
          createdBy: 1,
          updatedBy: 1,
          deletedBy: 1,
          dateCreation: faker.date.dateTime(minYear: 2010, maxYear: now.year),
          derniereModification:
              faker.date.dateTime(minYear: 2000, maxYear: now.year),
        );
    });
    await fournisseurBox.putMany(fournisseurs);

    // Importation des produits depuis Excel
    for (var table in excel.tables.keys) {
      for (var row in excel.tables[table]!.rows.skip(1)) {
        final designation = row[1]?.value?.toString() ?? faker.food.dish();
        final prixAchat = double.tryParse(row[6]?.value?.toString() ?? '') ??
            faker.randomGenerator.decimal();
        final prixVente = double.tryParse(row[7]?.value?.toString() ?? '') ??
            faker.randomGenerator.decimal();
        final stock = double.tryParse(row[5]?.value?.toString() ?? '') ??
            faker.randomGenerator.integer(100).toDouble();
        // Nettoyage du code QR (suppression des espaces)
        final qrCode = (row[0]?.value?.toString() ?? '').replaceAll(' ', '');
        // Création d'un produit
        final produit = Produit(
          qr: qrCode,
          image:
              'https://picsum.photos/200/300?random=${faker.randomGenerator.integer(5000)}',
          nom: designation,
          description: row[1]?.value?.toString() ?? faker.lorem.sentence(),
          prixVente: prixVente,
          minimStock: faker.randomGenerator.decimal(min: 1, scale: 2),
          alertPeremption: Random().nextInt(1000),
          derniereModification:
              faker.date.dateTime(minYear: 2000, maxYear: DateTime.now().year),
        )..crud.target = Crud(
            createdBy: faker.randomGenerator.integer(1000),
            updatedBy: faker.randomGenerator.integer(1000),
            deletedBy: faker.randomGenerator.integer(1000),
            dateCreation: faker.date.dateTime(minYear: 2010, maxYear: 2024),
            derniereModification: faker.date
                .dateTime(minYear: 2000, maxYear: DateTime.now().year),
          );

        // Création des approvisionnements pour chaque produit
        final nombreApprovisionnements =
            faker.randomGenerator.integer(10, min: 1);
        for (int i = 0; i < nombreApprovisionnements; i++) {
          final fournisseur = fournisseurs[random.nextInt(fournisseurs.length)];

          final approvisionnement = Approvisionnement(
            quantite: stock,
            prixAchat: prixAchat,
            datePeremption: faker.date.dateTime(
                minYear: DateTime.now().year, maxYear: DateTime.now().year + 2),
            derniereModification: faker.date
                .dateTime(minYear: 2000, maxYear: DateTime.now().year),
          )
            ..produit.target = produit
            ..fournisseur.target = fournisseur
            ..crud.target = Crud(
              createdBy: faker.randomGenerator.integer(1000),
              updatedBy: faker.randomGenerator.integer(1000),
              deletedBy: faker.randomGenerator.integer(1000),
              dateCreation: DateTime.now(),
              derniereModification: DateTime.now(),
            );

          produit.approvisionnements.add(approvisionnement);
        }

        //await produitBox.put(produit);
        // Insérer ou mettre à jour le produit
        await insertOrUpdateProduit(produit);
        print(produit.id.toString() +
            ' ===> ' +
            produit.nom +
            ' ===> ' +
            produit.qr.toString());
      }
    }

    // Création des clients et factures
    final clients = List.generate(clientCount, (_) {
      final client = Client(
        qr: faker.randomGenerator.integer(999999).toString(),
        nom: faker.person.name(),
        phone: faker.phoneNumber.us(),
        adresse: faker.address.streetAddress(),
        description: faker.lorem.sentence(),
        derniereModification:
            faker.date.dateTime(minYear: 2000, maxYear: DateTime.now().year),
      )..crud.target = Crud(
          createdBy: 1,
          updatedBy: 1,
          deletedBy: 1,
          dateCreation: faker.date.dateTime(minYear: 2010, maxYear: 2024),
          derniereModification:
              faker.date.dateTime(minYear: 2000, maxYear: DateTime.now().year),
        );

      // Création d'un nombre aléatoire de factures pour chaque client
      final nombreFactures = faker.randomGenerator.integer(50);
      client.factures
          .addAll(List.generate(nombreFactures, (_) => _createFacture(faker)));

      return client;
    });
    await clientBox.putMany(clients);

    // Création des factures sans clients
    final facturesSansClient = List.generate(
      faker.randomGenerator.integer(10, min: 1),
      (_) => _createFacture(faker),
    );
    await factureBox.putMany(facturesSansClient);
  }

  Future<void> importProduitsRestantsDepuisExcel(String filePath) async {
    final file = File(filePath);
    final bytes = await file.readAsBytes();
    final excel = Excel.decodeBytes(bytes);
    final faker = Faker();
    final random = Random();

    for (var table in excel.tables.keys) {
      for (var row in excel.tables[table]!.rows.skip(1)) {
        final designation = row[1]?.value?.toString() ?? faker.food.dish();
        final prixAchat = double.tryParse(row[6]?.value?.toString() ?? '') ??
            faker.randomGenerator.decimal();
        final prixVente = double.tryParse(row[7]?.value?.toString() ?? '') ??
            faker.randomGenerator.decimal();
        final stock = double.tryParse(row[5]?.value?.toString() ?? '') ??
            faker.randomGenerator.integer(100).toDouble();

        // Nettoyage du code QR (suppression des espaces)
        final qrCode = (row[0]?.value?.toString() ?? '').replaceAll(' ', '');

        // Vérification de l'existence du produit dans ObjectBox
        final existingProduit = await produitBox
            .query(Produit_.qr.equals(qrCode))
            .build()
            .findFirst();

        if (existingProduit == null) {
          // Création d'un nouveau produit s'il n'existe pas
          final produit = Produit(
            qr: qrCode,
            image:
                'https://picsum.photos/200/300?random=${faker.randomGenerator.integer(5000)}',
            nom: designation,
            description: row[1]?.value?.toString() ?? faker.lorem.sentence(),
            prixVente: prixVente,
            minimStock: faker.randomGenerator.decimal(min: 1, scale: 2),
            alertPeremption: random.nextInt(1000),
            derniereModification: DateTime.now(),
          )..crud.target = Crud(
              createdBy: faker.randomGenerator.integer(1000),
              updatedBy: faker.randomGenerator.integer(1000),
              deletedBy: faker.randomGenerator.integer(1000),
              dateCreation: DateTime.now(),
              derniereModification: DateTime.now(),
            );

          // Création d'un approvisionnement initial pour le nouveau produit
          final approvisionnement = Approvisionnement(
            quantite: stock,
            prixAchat: prixAchat,
            datePeremption: faker.date.dateTime(
                minYear: DateTime.now().year, maxYear: DateTime.now().year + 2),
            derniereModification: DateTime.now(),
          )
            ..produit.target = produit
            ..fournisseur.target = await getFournisseurAleatoire()
            ..crud.target = Crud(
              createdBy: faker.randomGenerator.integer(1000),
              updatedBy: faker.randomGenerator.integer(1000),
              deletedBy: faker.randomGenerator.integer(1000),
              dateCreation: DateTime.now(),
              derniereModification: DateTime.now(),
            );

          produit.approvisionnements.add(approvisionnement);

          await produitBox.put(produit);
          print(
              'Nouveau produit importé: ${produit.id} - ${produit.nom} - QR: ${produit.qr}');
        } else {
          print(
              'Produit déjà existant: ${existingProduit.id} - ${existingProduit.nom} - QR: ${existingProduit.qr}');
        }
      }
    }
  }

  Future<Fournisseur> getFournisseurAleatoire() async {
    final count = await fournisseurBox.count();
    final randomId = Random().nextInt(count) + 1;
    return fournisseurBox.get(randomId)!;
  }

  Future<void> checkStoragePermission() async {
    var status = await Permission.storage.status;

    if (!status.isGranted) {
      // Demander la permission
      await Permission.storage.request();
    }
  }

  Document _createFacture(Faker faker) {
    List<String> types = [
      'vente',
      'achat',
      'devis',
      'facture',
      'bon',
      'proforma'
    ];
    types.shuffle(random);
    final facture = Document(
      qrReference: faker.randomGenerator.integer(999999).toString(),
      impayer: faker.randomGenerator.decimal(min: 0, scale: 2),
      date: faker.date.dateTime(minYear: 2010, maxYear: 2024),
      derniereModification:
          faker.date.dateTime(minYear: 2000, maxYear: DateTime.now().year),
      type: types.first,
    )..crud.target = Crud(
        createdBy: 1,
        updatedBy: 1,
        deletedBy: 1,
        dateCreation: faker.date.dateTime(minYear: 2010, maxYear: 2024),
        derniereModification:
            faker.date.dateTime(minYear: 2000, maxYear: DateTime.now().year),
      );

    // Create invoice lines
    final numberOfLignes = faker.randomGenerator.integer(5, min: 1);
    for (int j = 0; j < numberOfLignes; j++) {
      final randomProductId =
          faker.randomGenerator.integer(produitBox.count()) + 1;
      final produit = produitBox.get(randomProductId);
      if (produit != null) {
        final ligneFacture = LigneDocument(
          quantite: faker.randomGenerator.decimal(min: 1, scale: 10),
          prixUnitaire: produit.prixVente,
          derniereModification:
              faker.date.dateTime(minYear: 2000, maxYear: DateTime.now().year),
        );
        ligneFacture.produit.target = produit;
        ligneFacture.facture.target = facture;
        facture.lignesDocument.add(ligneFacture);
      }
    }

    return facture;
  }

  Future<void> deleteDatabase() async {
    final directory = await getApplicationDocumentsDirectory();
    print('Directory: $directory');

    final path = join(directory.path, 'objectbox');
    print('Path: $path');

    final dir = Directory(path);
    print('Directory exists: ${await dir.exists()}');
    // if (await dir.exists()) {
    //   await dir.delete(recursive: true);
    // }
    print('Suppression des approvisionnements');
    approvisionnementBox.removeAll();
    print('Approvisionnements Succefully Deleted');

    print('Suppression des ligneFacture');
    ligneFacture.removeAll();
    print('ligneFacture Succefully Deleted');

    print('Suppression des crudBox');
    crudBox.removeAll();
    print('crudBox Succefully Deleted');

    print('Suppression des produitBox');
    produitBox.removeAll();
    print('produitBox Succefully Deleted');

    print('Suppression des fournisseurBox');
    fournisseurBox.removeAll();
    print('fournisseurBox Succefully Deleted');

    print('Suppression des clientBox');
    clientBox.removeAll();
    print('clientBox Succefully Deleted');

    print('Suppression des userBox');
    userBox.removeAll();
    print('userBox Succefully Deleted');

    print('Suppression des factureBox');
    factureBox.removeAll();
    print('factureBox Succefully Deleted');

    print('Suppression des deletedProduct');
    deletedProduct.removeAll();
    print('deletedProduct Succefully Deleted');

    //await deleteDatabase();
    await init();
  }

// Méthode pour supprimer les produits avec QR codes invalides et leurs entités associées
  void supprimerProduitsAvecQrCodeInvalide() {
    Iterable<Produit> produitsInvalide = getProduitsAvecQrCodeInvalide();

    for (var produit in produitsInvalide) {
      // Récupérer et supprimer les approvisionnements associés à ce produit
      List<Approvisionnement> approvisionnements = approvisionnementBox
          .query(Approvisionnement_.produit.equals(produit.id))
          .build()
          .find();
      for (var approvisionnement in approvisionnements) {
        approvisionnementBox.remove(approvisionnement.id);
      }

      // Supprimer l'entité Crud associée à ce produit

      crudBox.remove(produit.crud.target!.id);

      // Supprimer le produit lui-même
      produitBox.remove(produit.id);

      print('Produit supprimé : ${produit.nom}');
    }
  }

  // Méthode pour récupérer les produits avec QR codes invalides
  Iterable<Produit> getProduitsAvecQrCodeInvalide() {
    return produitBox
        .query()
        .build()
        .find()
        .where((produit) => !_qrCodeEstValide(produit.qr!));
  }

  // Méthode de validation des QR codes (seuls les chiffres sont autorisés)
  bool _qrCodeEstValide(String qrCode) {
    final regex = RegExp(r'^[0-9]+$'); // Seuls les chiffres sont autorisés
    return regex.hasMatch(qrCode);
  }

  Future<void> cleanQrCodes() async {
    final produits = produitBox.getAll();

    for (var produit in produits) {
      if (produit.qr != null) {
        final trimmedQr = produit.qr!.trim();

        if (produit.qr != trimmedQr) {
          produit.qr = trimmedQr;
          produitBox.put(produit);
        }
      }
    }
  }

  /// Ajouter une annonce dans la base de données
  void addAnnonce(Annonces annonce) {
    // Utilise "Annonces"
    annonces.put(annonce);
  }

  /// Récupérer toutes les annonces
  List<Annonces> getAllAnnonces() {
    // Utilise "Annonces"
    return annonces.getAll();
  }
}
