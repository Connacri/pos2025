import 'dart:io';
import 'dart:isolate';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:path/path.dart' as path;
import 'package:supabase_flutter/supabase_flutter.dart' as Supa;
import 'package:objectbox/objectbox.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import '../../objectbox.g.dart';
import '../Entity.dart';
import '../classeObjectBox.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:timeago/timeago.dart' as timeago;
import 'dart:developer' as developer;
import 'dart:io';

import '../pages/ProduitListScreen.dart';
import 'package:supabase/supabase.dart' as Supa;
import 'package:objectbox/objectbox.dart';
import 'dart:developer' as developer;

class SyncException implements Exception {
  final String message;
  SyncException(this.message);
  @override
  String toString() => 'SyncException: $message';
}

// class SupabaseSync {
//   final Supa.SupabaseClient supabase;
//   final Store objectboxStore;
//   DateTime? lastSyncDate;
//
//   SupabaseSync(this.supabase, this.objectboxStore);
//
//   Future<void> resolveQRCodeConflicts() async {
//     final produitBox = objectboxStore.box<Produit>();
//     final produits = produitBox.getAll();
//     Map<String, List<Produit>> qrCodeMap = {};
//     Set<String> usedQRCodes = Set<String>();
//
//     // Première passe : grouper les produits par QR code
//     for (final produit in produits) {
//       if (!qrCodeMap.containsKey(produit.qr)) {
//         qrCodeMap[produit.qr!] = [];
//       }
//       qrCodeMap[produit.qr]!.add(produit);
//     }
//
//     // Deuxième passe : résoudre les conflits et assurer l'unicité
//     for (var entry in qrCodeMap.entries) {
//       String baseQR = entry.key;
//       List<Produit> conflictingProducts = entry.value;
//
//       for (int i = 0; i < conflictingProducts.length; i++) {
//         Produit produit = conflictingProducts[i];
//         String newQR = baseQR;
//
//         // Si ce n'est pas le premier produit ou si le QR est déjà utilisé, générer un nouveau QR
//         if (i > 0 || usedQRCodes.contains(newQR)) {
//           int suffix = 1;
//           do {
//             newQR = '${baseQR}_$suffix';
//             suffix++;
//           } while (usedQRCodes.contains(newQR));
//         }
//
//         if (newQR != produit.qr) {
//           developer.log(
//               'Modification du QR code pour le produit ${produit.nom} (ID: ${produit.id}): ${produit.qr} -> $newQR');
//           produit.qr = newQR;
//           produitBox.put(produit);
//         }
//
//         usedQRCodes.add(newQR);
//       }
//     }
//
//     developer.log(
//         'Résolution des conflits de QR codes terminée. ${usedQRCodes.length} QR codes uniques assurés.');
//   }
//
//   Future<void> syncToSupabase() async {
//     developer.log('Début de syncToSupabase');
//
//     try {
//       // await cleanProductQRCodes(); // Nettoyage des QR codes
//       // await resolveQRCodeConflicts(); // Résolution des conflits de QR codes
//       await _syncProduits();
//
//       developer.log('Fin de syncToSupabase');
//     } catch (e) {
//       developer.log('Erreur dans syncToSupabase: $e',
//           error: e, stackTrace: StackTrace.current);
//       throw SyncException(
//           'Erreur lors de la synchronisation vers Supabase: $e');
//     }
//   }
//
//   Future<void> _syncProduits() async {
//     developer.log('Début de la synchronisation des produits');
//     final produitBox = objectboxStore.box<Produit>();
//     final produits = produitBox.getAll();
//
//     for (final produit in produits) {
//       // Gestion de l'image pour chaque produit
//       final imageUrl = await _uploadProductImage(produit);
//
//       // Préparation des données à synchroniser avec Supabase
//       final produitData = {
//         'id': produit.id,
//         'qr': produit.qr,
//         'image': imageUrl, // Utilisation de l'URL de l'image
//         'nom': produit.nom,
//         'description': produit.description,
//         'prixVente': produit.prixVente,
//         'minimStock': produit.minimStock,
//         'alertPeremption': produit.alertPeremption,
//       };
//
//       // Synchronisation des données avec Supabase
//       final result = await supabase
//           .from('produits')
//           .upsert([produitData], onConflict: 'id');
//
//       developer.log(
//           'Résultat de la synchronisation du produit ${produit.nom}: $result');
//     }
//   }
//
//   Future<String> _uploadProductImage(Produit produit) async {
//     final String localFolderPath =
//         r'C:\Users\INDRA\OneDrive\Documents\ImagesProduits';
//     final String placeholderImageUrl =
//         'https://picsum.photos/200/300?random=${produit.id}';
//     final String supabaseBucketPath = 'products';
//
//     // Utiliser le QR code comme nom de fichier, en ajoutant l'extension .jpg
//     final String imageName = '${produit.qr}.jpg';
//     final File imageFile = File(path.join(localFolderPath, imageName));
//
//     developer.log(
//         'Recherche de l\'image pour le produit ${produit.nom} avec QR: ${produit.qr}');
//     developer.log('Chemin du fichier image: ${imageFile.path}');
//
//     if (await imageFile.exists()) {
//       try {
//         final fileBytes = await imageFile.readAsBytes();
//         final imageToUploadPath = '$supabaseBucketPath/$imageName';
//
//         // Vérifier si l'image existe déjà dans Supabase Storage
//         final existsResponse = await Supa.Supabase.instance.client.storage
//             .from(supabaseBucketPath)
//             .list(path: imageToUploadPath);
//
//         if (existsResponse.isEmpty) {
//           // Uploader l'image si elle n'existe pas déjà
//           await Supa.Supabase.instance.client.storage
//               .from(supabaseBucketPath)
//               .uploadBinary(imageToUploadPath, fileBytes);
//           developer.log(
//               'Image uploadée avec succès pour ${produit.nom}: $imageToUploadPath');
//         } else {
//           developer.log(
//               'Image déjà présente pour ${produit.nom} dans Supabase Storage: $imageToUploadPath');
//         }
//
//         // Générer l'URL publique de l'image dans Supabase
//         final String imageUrl = Supa.Supabase.instance.client.storage
//             .from(supabaseBucketPath)
//             .getPublicUrl(imageToUploadPath);
//
//         developer.log('URL de l\'image générée: $imageUrl');
//         return imageUrl;
//       } catch (e) {
//         developer.log('Erreur lors de l\'upload de l\'image $imageName: $e');
//         throw Exception('Erreur lors de l\'upload de l\'image $imageName: $e');
//       }
//     } else {
//       developer.log(
//           'Image absente pour ${produit.nom} (QR: ${produit.qr}), utilisation de l\'image factice.');
//       return placeholderImageUrl;
//     }
//   }
//
//   Future<void> cleanProductQRCodes() async {
//     final produitBox = objectboxStore.box<Produit>();
//     final produits = produitBox.getAll();
//     int updatedCount = 0;
//
//     for (final produit in produits) {
//       String originalQR = produit.qr!;
//       // Utilisation de trim() pour supprimer les espaces au début et à la fin,
//       // puis suppression des espaces au milieu
//       String cleanedQR = originalQR.trim().replaceAll(RegExp(r'\s+'), '');
//
//       if (cleanedQR != originalQR) {
//         produit.qr = cleanedQR;
//         produitBox.put(produit);
//         updatedCount++;
//         developer.log(
//             'QR code nettoyé pour ${produit.nom}: "$originalQR" -> "$cleanedQR"');
//       }
//     }
//
//     developer.log(
//         'Nettoyage des QR codes terminé. $updatedCount produits mis à jour.');
//   }
//
//   Future<void> handleDuplicateQRCodes() async {
//     final produitBox = objectboxStore.box<Produit>();
//     final produits = produitBox.getAll();
//     Map<String, List<Produit>> qrCodeMap = {};
//
//     // Grouper les produits par QR code
//     for (final produit in produits) {
//       if (!qrCodeMap.containsKey(produit.qr)) {
//         qrCodeMap[produit.qr!] = [];
//       }
//       qrCodeMap[produit.qr]!.add(produit);
//     }
//
//     // Traiter les doublons
//     for (var entry in qrCodeMap.entries) {
//       if (entry.value.length > 1) {
//         developer.log('QR code en double détecté: ${entry.key}');
//         // Conserver le premier produit, modifier les autres
//         for (int i = 1; i < entry.value.length; i++) {
//           Produit produit = entry.value[i];
//           String newQR = '${produit.qr}_${produit.id}';
//           developer.log(
//               'Modification du QR code pour le produit ${produit.nom}: ${produit.qr} -> $newQR');
//           produit.qr = newQR;
//           produitBox.put(produit);
//         }
//       }
//     }
//   }
// }
// class SupabaseSync {
//   final Supa.SupabaseClient supabase;
//
//   final Store objectboxStore;
//   DateTime? lastSyncDate;
//
//   SupabaseSync(this.supabase, this.objectboxStore);
//
//   Future<void> resolveQRCodeConflicts() async {
//     final produitBox = objectboxStore.box<Produit>();
//     final produits = produitBox.getAll();
//     Map<String, List<Produit>> qrCodeMap = {};
//     Set<String> usedQRCodes = Set<String>();
//
//     // Première passe : grouper les produits par QR code
//     for (final produit in produits) {
//       if (!qrCodeMap.containsKey(produit.qr)) {
//         qrCodeMap[produit.qr!] = [];
//       }
//       qrCodeMap[produit.qr]!.add(produit);
//     }
//
//     // Deuxième passe : résoudre les conflits et assurer l'unicité
//     for (var entry in qrCodeMap.entries) {
//       String baseQR = entry.key;
//       List<Produit> conflictingProducts = entry.value;
//
//       for (int i = 0; i < conflictingProducts.length; i++) {
//         Produit produit = conflictingProducts[i];
//         String newQR = baseQR;
//
//         // Si ce n'est pas le premier produit ou si le QR est déjà utilisé, générer un nouveau QR
//         if (i > 0 || usedQRCodes.contains(newQR)) {
//           int suffix = 1;
//           do {
//             newQR = '${baseQR}_$suffix';
//             suffix++;
//           } while (usedQRCodes.contains(newQR));
//         }
//
//         if (newQR != produit.qr) {
//           developer.log(
//               'Modification du QR code pour le produit ${produit.nom} (ID: ${produit.id}): ${produit.qr} -> $newQR');
//           produit.qr = newQR;
//           produitBox.put(produit);
//         }
//
//         usedQRCodes.add(newQR);
//       }
//     }
//
//     developer.log(
//         'Résolution des conflits de QR codes terminée. ${usedQRCodes.length} QR codes uniques assurés.');
//   }
//
//   // Future<void> syncToSupabase2() async {
//   //   developer.log('Début de syncToSupabase');
//   //
//   //   try {
//   //     // await _syncProduits();
//   //     _syncAllEntities();
//   //     developer.log('Fin de syncToSupabase');
//   //   } catch (e) {
//   //     developer.log('Erreur dans syncToSupabase: $e',
//   //         error: e, stackTrace: StackTrace.current);
//   //     throw SyncException(
//   //         'Erreur lors de la synchronisation vers Supabase: $e');
//   //   }
//   // }
//   //
//   // Future<void> _syncUsers() async {
//   //   // Synchronisation des utilisateurs ici
//   //   // Supposons que vous ayez une box pour les utilisateurs dans ObjectBox
//   //   final userBox = objectboxStore.box<User>();
//   //   final users = userBox.getAll();
//   //
//   //   for (final user in users) {
//   //     final userData = {
//   //       'id': user.id,
//   //       'username': user.username,
//   //       // Autres champs pertinents
//   //     };
//   //
//   //     final result =
//   //         await supabase.from('users').upsert([userData], onConflict: 'id');
//   //     developer.log(
//   //         'Résultat de la synchronisation de l\'utilisateur ${user.username}: $result');
//   //   }
//   // }
//
//   Future<void> _syncProduitsWithoutRelations() async {
//     final produitBox = objectboxStore.box<Produit>();
//     final produits =
//         _filterProduitsByDerniereModification(lastSyncDate ?? DateTime(1990));
//
//     for (final produit in produits) {
//       final produitData = {
//         'id': produit.id,
//         'qr': produit.qr,
//         'nom': produit.nom,
//         'description': produit.description,
//         'prixVente': produit.prixVente,
//         'minimStock': produit.minimStock,
//         'alertPeremption': produit.alertPeremption,
//       };
//
//       final result = await supabase
//           .from('produits')
//           .upsert([produitData], onConflict: 'id');
//       developer.log(
//           'Résultat de la synchronisation du produit ${produit.nom}: $result');
//     }
//   }
//
//   Future<void> _syncFournisseurs() async {
//     final fournisseurBox = objectboxStore.box<Fournisseur>();
//     final fournisseurs = fournisseurBox.getAll();
//
//     for (final fournisseur in fournisseurs) {
//       final fournisseurData = {
//         'id': fournisseur.id,
//         'nom': fournisseur.nom,
//         // Autres champs pertinents
//       };
//
//       final result = await supabase
//           .from('fournisseurs')
//           .upsert([fournisseurData], onConflict: 'id');
//       developer.log(
//           'Résultat de la synchronisation du fournisseur ${fournisseur.nom}: $result');
//     }
//   }
//
//   Future<void> _syncApprovisionnementsWithRelations() async {
//     final approvisionnementBox = objectboxStore.box<Approvisionnement>();
//     final approvisionnements = approvisionnementBox.getAll();
//
//     for (final approvisionnement in approvisionnements) {
//       final approvisionnementData = {
//         'id': approvisionnement.id,
//         'quantite': approvisionnement.quantite,
//         'prixAchat': approvisionnement.prixAchat,
//         'datePeremption': approvisionnement.datePeremption?.toIso8601String(),
//         'produitId':
//             approvisionnement.produit.target?.id, // Référence au produit
//         'fournisseurId': approvisionnement
//             .fournisseur.target?.id, // Référence au fournisseur
//       };
//
//       final result = await supabase
//           .from('approvisionnements')
//           .upsert([approvisionnementData], onConflict: 'id');
//       developer.log(
//           'Résultat de la synchronisation de l\'approvisionnement ${approvisionnement.id}: $result');
//     }
//   }
//
//   Future<void> _syncCrud(Crud? crud) async {
//     if (crud == null) return;
//
//     final crudData = {
//       'id': crud.id,
//       'createdBy': crud.createdBy ?? 1,
//       'updatedBy': crud.updatedBy ?? 1,
//       'deletedBy': crud.deletedBy ?? 1,
//       'dateCreation': crud.dateCreation?.toIso8601String(),
//       'derniereModification': crud.derniereModification.toIso8601String(),
//       'dateDeleting': crud.dateDeleting?.toIso8601String(),
//     };
//
//     final result =
//         await supabase.from('cruds').upsert([crudData], onConflict: 'id');
//     developer.log(
//         'Résultat de la synchronisation du Crud avec ID ${crud.id}: $result');
//   }
//
//   Future<void> _syncAllCruds() async {
//     developer.log('Début de la synchronisation des Crud');
//
//     final produitBox = objectboxStore.box<Produit>();
//     final approvisionnementBox = objectboxStore.box<Approvisionnement>();
//
//     // Synchroniser les Crud des produits
//     final produits = produitBox.getAll();
//     for (final produit in produits) {
//       await _syncCrud(produit.crud.target);
//     }
//
//     // Synchroniser les Crud des approvisionnements
//     final approvisionnements = approvisionnementBox.getAll();
//     for (final approvisionnement in approvisionnements) {
//       await _syncCrud(approvisionnement.crud.target);
//     }
//
//     developer.log('Fin de la synchronisation des Crud');
//   }
//
//   ///*****************************
//
//   Future<void> _syncAllEntities() async {
//     developer.log('Début de la synchronisation des entités modifiées');
//
//     final userBox = objectboxStore.box<User>();
//     final produitBox = objectboxStore.box<Produit>();
//     final approvisionnementBox = objectboxStore.box<Approvisionnement>();
//
//     final lastSync = lastSyncDate ?? DateTime(1990);
//
//     // Synchroniser les utilisateurs modifiés
//     await _syncModifiedUsers(userBox, lastSync);
//
//     // Synchroniser les produits modifiés
//     await _syncModifiedProduits(produitBox, lastSync);
//
//     // Synchroniser les approvisionnements modifiés
//     await _syncModifiedApprovisionnements(approvisionnementBox, lastSync);
//
//     // Gérer les suppressions
//     await _handleDeletions(lastSync);
//
//     lastSyncDate = DateTime.now();
//     developer.log('Fin de la synchronisation des entités modifiées');
//   }
//
//   Future<void> _syncModifiedUsers(Box<User> box, DateTime lastSync) async {
//     final query = box
//         .query(User_.derniereModification
//             .greaterThan(lastSync.millisecondsSinceEpoch))
//         .build();
//     final modifiedUsers = query.find();
//
//     for (final user in modifiedUsers) {
//       final userData = _prepareUserData(user);
//       final result =
//           await supabase.from('users').upsert([userData], onConflict: 'id');
//       developer.log(
//           'Résultat de la synchronisation de l\'utilisateur ${user.id}: $result');
//     }
//   }
//
//   Future<void> _syncModifiedProduits(
//       Box<Produit> box, DateTime lastSync) async {
//     try {
//       // Récupérer tous les produits de la base de données
//       final allProduits = box.getAll();
//
//       // Filtrer les produits modifiés
//       final modifiedProduits = allProduits.where((produit) {
//         // Assurez-vous que produit.crud.target n'est pas nul avant d'accéder à derniereModification
//         return produit.crud.target != null &&
//             produit.crud.target!.derniereModification.isAfter(lastSync);
//       }).toList();
//
//       for (final produit in modifiedProduits) {
//         final produitData = _prepareProduitData(produit);
//         final result = await supabase
//             .from('produits')
//             .upsert([produitData], onConflict: 'id');
//
//         developer.log(
//             'Résultat de la synchronisation du produit ${produit.id}: $result',
//             name: 'Sync Produits');
//       }
//     } catch (e) {
//       developer.log(
//         'Erreur lors de la synchronisation des produits: $e',
//         name: 'Sync Produits',
//       );
//     }
//   }
//
//   Future<void> _syncModifiedApprovisionnements(
//       Box<Approvisionnement> box, DateTime lastSync) async {
//     try {
//       // Récupérer tous les approvisionnements de la base de données
//       final allApprovisionnements = box.getAll();
//
//       // Filtrer les approvisionnements modifiés
//       final modifiedApprovisionnements =
//           allApprovisionnements.where((approvisionnement) {
//         // Assurez-vous que approvisionnement.crud.target n'est pas nul avant d'accéder à derniereModification
//         return approvisionnement.crud.target != null &&
//             approvisionnement.crud.target!.derniereModification
//                 .isAfter(lastSync);
//       }).toList();
//
//       for (final approvisionnement in modifiedApprovisionnements) {
//         final approData = _prepareApprovisionnementData(approvisionnement);
//         final result = await supabase
//             .from('approvisionnements')
//             .upsert([approData], onConflict: 'id');
//
//         developer.log(
//             'Résultat de la synchronisation de l\'approvisionnement ${approvisionnement.id}: $result',
//             name: 'Sync Approvisionnements');
//       }
//     } catch (e) {
//       developer.log(
//         'Erreur lors de la synchronisation des approvisionnements: $e',
//         name: 'Sync Approvisionnements',
//       );
//     }
//   }
//
//   Map<String, dynamic> _prepareUserData(User user) {
//     return {
//       'id': user.id,
//       'photo': user.photo,
//       'username': user.username,
//       'email': user.email,
//       'phone': user.phone,
//       'role': user.role,
//       'dateCreation': user.dateCreation?.toIso8601String(),
//       'derniereModification': DateTime.now(),
//       'dateDeleting': user.dateDeleting?.toIso8601String(),
//     };
//   }
//
//   Map<String, dynamic> _prepareProduitData(Produit produit) {
//     return {
//       'id': produit.id,
//       'qr': produit.qr,
//       'image': produit.image,
//       'nom': produit.nom,
//       'description': produit.description,
//       'prixVente': produit.prixVente,
//       'minimStock': produit.minimStock,
//       'alertPeremption': produit.alertPeremption,
//       'derniereModification': DateTime.now(),
//     };
//   }
//
//   Map<String, dynamic> _prepareApprovisionnementData(
//       Approvisionnement approvisionnement) {
//     return {
//       'id': approvisionnement.id,
//       'quantite': approvisionnement.quantite,
//       'prixAchat': approvisionnement.prixAchat,
//       'datePeremption': approvisionnement.datePeremption?.toIso8601String(),
//       'produitId': approvisionnement.produit.target?.id,
//       'fournisseurId': approvisionnement.fournisseur.target?.id,
//       'derniereModification': DateTime.now(),
//     };
//   }
//
//   Future<void> _handleDeletions(DateTime lastSync) async {
//     await _handleEntityDeletions<User>(
//         objectboxStore.box<User>(), 'users', lastSync, (user) => user.id);
//     await _handleEntityDeletions<Produit>(objectboxStore.box<Produit>(),
//         'produits', lastSync, (produit) => produit.id);
//     await _handleEntityDeletions<Approvisionnement>(
//         objectboxStore.box<Approvisionnement>(),
//         'approvisionnements',
//         lastSync,
//         (approvisionnement) => approvisionnement.id);
//   }
//
//   Future<void> _handleEntityDeletions<T>(Box<T> box, String tableName,
//       DateTime lastSync, int Function(T) getId) async {
//     final deletedEntities = await supabase
//         .from(tableName)
//         .select()
//         .gte('dateDeleting', lastSync.toIso8601String());
//
//     for (final deletedEntity in deletedEntities) {
//       final localEntity = box.get(deletedEntity['id']);
//       if (localEntity != null) {
//         box.remove(getId(localEntity));
//       }
//     }
//   }
//
//   ///*****************************
//
//   Future<void> syncToSupabase() async {
//     developer.log('Début de syncToSupabase');
//
//     try {
//       // 1. Synchroniser les utilisateurs
//       await _syncAllEntities();
//
//       // 2. Synchroniser les produits sans leurs relations
//       await _syncProduitsWithoutRelations();
//
//       // 3. Synchroniser les fournisseurs
//       await _syncFournisseurs();
//
//       // 4. Synchroniser les approvisionnements avec leurs relations
//       await _syncApprovisionnementsWithRelations();
//
//       // 5. Synchroniser les Crud pour toutes les entités principales
//       await _syncAllCruds();
//
//       // Fin de la synchronisation
//       developer.log('Fin de syncToSupabase');
//     } catch (e) {
//       developer.log('Erreur dans syncToSupabase: $e',
//           error: e, stackTrace: StackTrace.current);
//       throw SyncException(
//           'Erreur lors de la synchronisation vers Supabase: $e');
//     }
//   }
//
//   Future<void> _syncAllEntities0() async {
//     developer.log('Début de la synchronisation des entités');
//
//     final produitBox = objectboxStore.box<Produit>();
//     final crudBox = objectboxStore.box<Crud>();
//     final approvisionnementBox = objectboxStore.box<Approvisionnement>();
//
//     // Filtrer les produits modifiés après la dernière synchronisation
//     final produits =
//         _filterProduitsByDerniereModification(lastSyncDate ?? DateTime(1990));
//
//     // Synchroniser les produits et leurs Crud associés
//     for (final produit in produits) {
//       // Synchroniser le Crud du produit
//       await _syncCrud(produit.crud.target);
//
//       // Gestion de l'image pour chaque produit
//       final imageUrl = await _uploadProductImage(produit);
//
//       // Préparation des données à synchroniser avec Supabase
//       final produitData = {
//         'id': produit.id,
//         'qr': produit.qr,
//         'image': imageUrl,
//         'nom': produit.nom,
//         'description': produit.description,
//         'prixVente': produit.prixVente,
//         'minimStock': produit.minimStock,
//         'alertPeremption': produit.alertPeremption,
//         // 'derniereModification':
//         //     produit.crud.target?.derniereModification?.toIso8601String(),
//       };
//
//       // Synchronisation des données avec Supabase
//       final result = await supabase.from('produits').upsert([produitData],
//           onConflict:
//               'id').select(); // Utilisez .select() pour récupérer les données synchronisées
//
//       if (result == null || result.isEmpty) {
//         developer.log(
//             'Aucune donnée retournée pour la synchronisation du produit ${produit.nom}');
//       } else {
//         developer.log(
//             'Résultat de la synchronisation du produit ${produit.nom}: $result');
//       }
//
//       developer.log(
//           'Résultat de la synchronisation du produit ${produit.nom}: $result');
//
//       // Synchroniser les approvisionnements associés au produit
//       await _syncApprovisionnements(produit.approvisionnements);
//     }
//
//     // Mettre à jour la date de dernière synchronisation après succès
//     lastSyncDate = DateTime.now();
//   }
//
// // Méthode de synchronisation des Crud
//   Future<void> _syncCrud1(Crud? crud) async {
//     if (crud == null) return;
//
//     final crudData = {
//       'id': crud.id,
//       'createdBy': crud.createdBy ?? 1,
//       'updatedBy': crud.updatedBy ?? 1,
//       'deletedBy': crud.deletedBy ?? 1,
//       'dateCreation': crud.dateCreation?.toIso8601String(),
//       'derniereModification': crud.derniereModification.toIso8601String(),
//       'dateDeleting': crud.dateDeleting?.toIso8601String(),
//     };
//
//     // Synchronisation avec Supabase
//     final result =
//         await supabase.from('cruds').upsert([crudData], onConflict: 'id');
//
//     developer.log(
//         'Résultat de la synchronisation du Crud avec ID ${crud.id}: $result');
//   }
//
// // Méthode de synchronisation des approvisionnements
//   Future<void> _syncApprovisionnements(
//       ToMany<Approvisionnement> approvisionnements) async {
//     for (final approvisionnement in approvisionnements) {
//       // Synchroniser le Crud de l'approvisionnement
//       await _syncCrud(approvisionnement.crud.target);
//
//       // Préparation des données à synchroniser avec Supabase
//       final approvisionnementData = {
//         'id': approvisionnement.id,
//         'quantite': approvisionnement.quantite,
//         'prixAchat': approvisionnement.prixAchat,
//         'datePeremption': approvisionnement.datePeremption?.toIso8601String(),
//         'produitId': approvisionnement.produit.target
//             ?.id, // Assurez-vous d'ajouter une référence à produit
//         'fournisseurId': approvisionnement.fournisseur.target
//             ?.id, // Assurez-vous d'ajouter une référence à fournisseur
//         // 'derniereModification': approvisionnement
//         //     .crud.target?.derniereModification
//         //     .toIso8601String(),
//       };
//
//       // Synchronisation des données avec Supabase
//       final result = await supabase
//           .from('approvisionnements')
//           .upsert([approvisionnementData], onConflict: 'id');
//
//       developer.log(
//           'Résultat de la synchronisation de l\'approvisionnement avec ID ${approvisionnement.id}: $result');
//     }
//   }
//
// // Méthode de filtrage pour récupérer les produits modifiés après une date donnée
//   List<Produit> _filterProduitsByDerniereModification(DateTime date) {
//     final produitBox = objectboxStore.box<Produit>();
//     final allProduits = produitBox.getAll();
//
//     return allProduits.where((produit) {
//       final derniereModification = produit.crud.target?.derniereModification;
//       return derniereModification != null && derniereModification.isAfter(date);
//     }).toList();
//   }
//
//   // Future<void> _syncProduits() async {
//   //   developer.log('Début de la synchronisation des produits');
//   //   final produitBox = objectboxStore.box<Produit>();
//   //
//   //   // Filtrer les produits modifiés après la dernière synchronisation
//   //   final produits =
//   //       _filterProduitsByDerniereModification(lastSyncDate ?? DateTime(2024));
//   //
//   //   for (final produit in produits) {
//   //     // Gestion de l'image pour chaque produit
//   //     final imageUrl = await _uploadProductImage(produit);
//   //
//   //     // Préparation des données à synchroniser avec Supabase
//   //     final produitData = {
//   //       'id': produit.id,
//   //       'qr': produit.qr,
//   //       'image': imageUrl, // Utilisation de l'URL de l'image
//   //       'nom': produit.nom,
//   //       'description': produit.description,
//   //       'prixVente': produit.prixVente,
//   //       'minimStock': produit.minimStock,
//   //       'alertPeremption': produit.alertPeremption,
//   //       // Inclure la dernière modification depuis Crud
//   //       'derniereModification':
//   //           produit.crud.target?.derniereModification.toIso8601String(),
//   //     };
//   //
//   //     // Synchronisation des données avec Supabase
//   //     final result = await supabase
//   //         .from('produits')
//   //         .upsert([produitData], onConflict: 'id');
//   //
//   //     developer.log(
//   //         'Résultat de la synchronisation du produit ${produit.nom}: $result');
//   //   }
//   //
//   //   // Mettre à jour la date de dernière synchronisation après succès
//   //   lastSyncDate = DateTime.now();
//   // }
//
// // Méthode de filtrage pour récupérer les produits modifiés après une date donnée
// //   List<Produit> _filterProduitsByDerniereModification(DateTime date) {
// //     final produitBox = objectboxStore.box<Produit>();
// //     final allProduits = produitBox.getAll();
// //
// //     return allProduits.where((produit) {
// //       // Récupérer la dernière modification du produit
// //       final derniereModification = produit.crud.target?.derniereModification;
// //
// //       // Comparer avec la date fournie
// //       return derniereModification != null && derniereModification.isAfter(date);
// //     }).toList();
// //   }
//
//   Future<String> _uploadProductImage(Produit produit) async {
//     final String localFolderPath =
//         r'C:\Users\INDRA\OneDrive\Documents\ImagesProduits';
//     final String placeholderImageUrl =
//         'https://picsum.photos/200/300?random=${produit.id}';
//     final String supabaseBucketPath = 'products';
//
//     final String imageName = '${produit.qr}.jpg';
//     final File imageFile = File(path.join(localFolderPath, imageName));
//
//     developer.log(
//         'Recherche de l\'image pour le produit ${produit.nom} avec QR: ${produit.qr}');
//     developer.log('Chemin du fichier image: ${imageFile.path}');
//
//     if (await imageFile.exists()) {
//       try {
//         final fileBytes = await imageFile.readAsBytes();
//         final imageToUploadPath = '$supabaseBucketPath/$imageName';
//
//         // Vérifier si l'image existe déjà dans Supabase Storage
//         final existsResponse = await Supa.Supabase.instance.client.storage
//             .from(supabaseBucketPath)
//             .list(path: imageToUploadPath);
//
//         if (existsResponse.isEmpty) {
//           // Uploader l'image si elle n'existe pas déjà
//           await Supa.Supabase.instance.client.storage
//               .from(supabaseBucketPath)
//               .uploadBinary(imageToUploadPath, fileBytes);
//           developer.log(
//               'Image uploadée avec succès pour ${produit.nom}: $imageToUploadPath');
//         } else {
//           developer.log(
//               'Image déjà présente pour ${produit.nom} dans Supabase Storage: $imageToUploadPath');
//         }
//
//         final String imageUrl = Supa.Supabase.instance.client.storage
//             .from(supabaseBucketPath)
//             .getPublicUrl(imageToUploadPath);
//
//         developer.log('URL de l\'image générée: $imageUrl');
//         return imageUrl;
//       } catch (e) {
//         developer.log('Erreur lors de l\'upload de l\'image $imageName: $e');
//         throw Exception('Erreur lors de l\'upload de l\'image $imageName: $e');
//       }
//     } else {
//       developer.log(
//           'Image absente pour ${produit.nom} (QR: ${produit.qr}), utilisation de l\'image factice.');
//       return placeholderImageUrl;
//     }
//   }
//
//   Future<void> cleanProductQRCodes() async {
//     final produitBox = objectboxStore.box<Produit>();
//     final produits = produitBox.getAll();
//     int updatedCount = 0;
//
//     for (final produit in produits) {
//       String originalQR = produit.qr!;
//       String cleanedQR = originalQR.trim().replaceAll(RegExp(r'\s+'), '');
//
//       if (cleanedQR != originalQR) {
//         produit.qr = cleanedQR;
//         produitBox.put(produit);
//         updatedCount++;
//         developer.log(
//             'QR code nettoyé pour ${produit.nom}: "$originalQR" -> "$cleanedQR"');
//       }
//     }
//
//     developer.log(
//         'Nettoyage des QR codes terminé. $updatedCount produits mis à jour.');
//   }
//
//   Future<void> handleDuplicateQRCodes() async {
//     final produitBox = objectboxStore.box<Produit>();
//     final produits = produitBox.getAll();
//     Map<String, List<Produit>> qrCodeMap = {};
//
//     // Grouper les produits par QR code
//     for (final produit in produits) {
//       if (!qrCodeMap.containsKey(produit.qr)) {
//         qrCodeMap[produit.qr!] = [];
//       }
//       qrCodeMap[produit.qr]!.add(produit);
//     }
//
//     // Traiter les doublons
//     for (var entry in qrCodeMap.entries) {
//       if (entry.value.length > 1) {
//         developer.log('QR code en double détecté: ${entry.key}');
//         for (int i = 1; i < entry.value.length; i++) {
//           Produit produit = entry.value[i];
//           String newQR = '${produit.qr}_${produit.id}';
//           developer.log(
//               'Modification du QR code pour le produit ${produit.nom}: ${produit.qr} -> $newQR');
//           produit.qr = newQR;
//           produitBox.put(produit);
//         }
//       }
//     }
//   }
// }

class SupabaseSync {
  final Supa.SupabaseClient supabase;
  final Store objectboxStore;
  DateTime? lastSyncDate;

  SupabaseSync(this.supabase, this.objectboxStore);

  Future<void> syncToSupabase() async {
    developer.log('Début de syncToSupabase');
    try {
      await _syncRecentlyModifiedEntities();
      lastSyncDate = DateTime.now();
      developer.log('Fin de syncToSupabase');
    } catch (e) {
      developer.log('Erreur dans syncToSupabase: $e',
          error: e, stackTrace: StackTrace.current);
      throw SyncException(
          'Erreur lors de la synchronisation vers Supabase: $e');
    }
  }

  Future<void> _syncRecentlyModifiedEntities() async {
    final lastSync = lastSyncDate ?? DateTime(1990);
    await _syncModifiedUsers(lastSync);
    await _syncModifiedProduits(lastSync);

    await _syncModifiedFournisseurs(lastSync);
    await _syncModifiedApprovisionnements(lastSync);
  }

  Future<void> _syncModifiedUsers(DateTime lastSync) async {
    final userBox = objectboxStore.box<User>();
    final modifiedUsers = userBox
        .query(User_.derniereModification
            .greaterThan(lastSync.millisecondsSinceEpoch))
        .build()
        .find();

    for (final user in modifiedUsers) {
      final userData = _prepareUserData(user);
      await supabase.from('users').upsert([userData], onConflict: 'id');
      developer.log('User synchronisé: ${user.id}');
    }
  }

  Future<void> _syncModifiedProduits(DateTime lastSync) async {
    final produitBox = objectboxStore.box<Produit>();
    final modifiedProduits = produitBox
        .query(Produit_.derniereModification
            .greaterThan(lastSync.millisecondsSinceEpoch))
        .build()
        .find();

    for (final produit in modifiedProduits) {
      final produitData = await _prepareProduitData(produit);
      await supabase.from('produits').upsert([produitData], onConflict: 'id');
      developer.log('Produit synchronisé: ${produit.id}');
    }
  }

  Future<void> _syncModifiedApprovisionnements(DateTime lastSync) async {
    final approBox = objectboxStore.box<Approvisionnement>();
    final modifiedAppros = approBox
        .query(Approvisionnement_.derniereModification
            .greaterThan(lastSync.millisecondsSinceEpoch))
        .build()
        .find();

    for (final appro in modifiedAppros) {
      final approData = _prepareApprovisionnementData(appro);
      await supabase
          .from('approvisionnements')
          .upsert([approData], onConflict: 'id');
      developer.log('Approvisionnement synchronisé: ${appro.id}');
    }
  }

  Future<void> _syncModifiedFournisseurs(DateTime lastSync) async {
    final fournisseurBox = objectboxStore.box<Fournisseur>();
    final modifiedFournisseurs = fournisseurBox
        .query(Fournisseur_.derniereModification
            .greaterThan(lastSync.millisecondsSinceEpoch))
        .build()
        .find();

    for (final fournisseur in modifiedFournisseurs) {
      final fournisseurData = _prepareFournisseurData(fournisseur);
      await supabase
          .from('fournisseurs')
          .upsert([fournisseurData], onConflict: 'id');
      developer.log('Fournisseur synchronisé: ${fournisseur.id}');
    }
  }

  Map<String, dynamic> _prepareUserData(User user) {
    return {
      'id': user.id,
      'username': user.username,
      'email': user.email,
      'role': user.role,
      'derniereModification': DateTime.now().toIso8601String(),
      // Ajoutez d'autres champs pertinents ici
    };
  }

  Future<Map<String, dynamic>> _prepareProduitData(Produit produit) async {
    final imageUrl = await _uploadProductImage(produit);
    return {
      'id': produit.id,
      'qr': produit.qr,
      'image': imageUrl,
      'nom': produit.nom,
      'description': produit.description,
      'prixVente': produit.prixVente,
      'minimStock': produit.minimStock,
      'alertPeremption': produit.alertPeremption,
      'derniereModification': DateTime.now().toIso8601String(),
    };
  }

  Map<String, dynamic> _prepareApprovisionnementData(Approvisionnement appro) {
    return {
      'id': appro.id,
      'quantite': appro.quantite,
      'prixAchat': appro.prixAchat,
      'datePeremption': appro.datePeremption?.toIso8601String(),
      'produitId': appro.produit.target?.id,
      'fournisseurId': appro.fournisseur.target?.id,
      'derniereModification': DateTime.now().toIso8601String(),
    };
  }

  Map<String, dynamic> _prepareFournisseurData(Fournisseur fournisseur) {
    return {
      'id': fournisseur.id,
      'nom': fournisseur.nom,
      'derniereModification': DateTime.now().toIso8601String(),
      // Ajoutez d'autres champs pertinents ici
    };
  }

  Future<String> _uploadProductImage(Produit produit) async {
    final String localFolderPath =
        r'C:\Users\INDRA\OneDrive\Documents\ImagesProduits';
    final String placeholderImageUrl =
        'https://picsum.photos/200/300?random=${produit.id.toString().trim()}';

    final String supabaseBucketPath = 'products';

    final String imageName = '${produit.qr.toString().trim()}.jpg';
    final File imageFile = File(path.join(localFolderPath, imageName));

    developer.log(
        'Recherche de l\'image pour le produit ${produit.nom} avec QR: ${produit.qr.toString().trim()}');
    developer.log('Chemin du fichier image: ${imageFile.path}');

    if (await imageFile.exists()) {
      try {
        final fileBytes = await imageFile.readAsBytes();
        final imageToUploadPath = '$supabaseBucketPath/$imageName';

        // Vérifier si l'image existe déjà dans Supabase Storage
        final existsResponse = await Supa.Supabase.instance.client.storage
            .from(supabaseBucketPath)
            .list(path: imageToUploadPath);

        if (existsResponse.isEmpty) {
          // Uploader l'image si elle n'existe pas déjà
          await Supa.Supabase.instance.client.storage
              .from(supabaseBucketPath)
              .uploadBinary(imageToUploadPath, fileBytes);
          developer.log(
              'Image uploadée avec succès pour ${produit.nom}: $imageToUploadPath');
        } else {
          developer.log(
              'Image déjà présente pour ${produit.nom} dans Supabase Storage: $imageToUploadPath');
        }

        final String imageUrl = Supa.Supabase.instance.client.storage
            .from(supabaseBucketPath)
            .getPublicUrl(imageToUploadPath);

        developer.log('URL de l\'image générée: $imageUrl');
        return imageUrl;
      } catch (e) {
        developer.log('Erreur lors de l\'upload de l\'image $imageName: $e');
        throw Exception('Erreur lors de l\'upload de l\'image $imageName: $e');
      }
    } else {
      developer.log(
          'Image absente pour ${produit.nom} (QR: ${produit.qr}), utilisation de l\'image factice.');
      return placeholderImageUrl;
    }
  }
}

class ProduitListPage extends StatefulWidget {
  final Supa.SupabaseClient supabase;
  final Store objectboxStore;

  ProduitListPage({required this.supabase, required this.objectboxStore});

  @override
  _ProduitListPageState createState() => _ProduitListPageState();
}

class _ProduitListPageState extends State<ProduitListPage>
    with TickerProviderStateMixin {
  List<Produit> _produits = [];

  bool _isLoading = false;
  bool _hasMore = true;
  final int _pageSize = 20;
  int _currentPage = 0;

  final ScrollController _scrollControllerProduits = ScrollController();
  NativeAd? _nativeAd;
  bool _nativeAdIsLoaded = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _loadMoreProduits();
    _scrollControllerProduits.addListener(_onScrollProduits);

    _tabController = TabController(length: 1, vsync: this);
  }

  @override
  void dispose() {
    _scrollControllerProduits.removeListener(_onScrollProduits);

    _scrollControllerProduits.dispose();
    _nativeAd?.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _onScrollProduits() {
    if (_scrollControllerProduits.position.pixels ==
        _scrollControllerProduits.position.maxScrollExtent) {
      _loadMoreProduits();
    }
  }

  Future<void> _loadMoreProduits() async {
    if (_isLoading || !_hasMore) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final supabase = Supa.Supabase.instance.client;
      final List<Map<String, dynamic>> data = await supabase
          .from('produits')
          .select()
          .order('id', ascending: false)
          .range(_currentPage * _pageSize, (_currentPage + 1) * _pageSize - 1);

      if (data.isEmpty) {
        setState(() {
          _hasMore = false;
        });
      } else {
        setState(() {
          _produits.addAll(data.map((item) => Produit.fromJson(item)).toList());
          _currentPage++;
        });
      }
    } catch (e) {
      print('Erreur lors de la récupération des produits: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  bool _isSyncing = false;
  String? _errorMessage;
  String? _successMessage;
  bool _isSyncingF = false;
  String? _errorMessageF;
  String? _successMessageF;

  Future<void> _syncData() async {
    setState(() {
      _isSyncing = true;
      _errorMessage = null;
      _successMessage = null;
    });

    final sync = SupabaseSync(widget.supabase, widget.objectboxStore);

    try {
      //  , await sync.resolveQRCodeConflicts();
      await sync.syncToSupabase();
      // await sync.syncFromSupabase();
      setState(() {
        _successMessage = 'Synchronisation réussie';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _successMessage!,
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.green,
          ),
        );
      });
    } on SyncException catch (e) {
      setState(() {
        _errorMessage = e.message;
      });
    } finally {
      setState(() {
        _isSyncing = false;
      });
    }
  }

  Future<List<User>> fetchUsersFromSupabase() async {
    final supabase = Supa.Supabase.instance.client;
    try {
      final List<Map<String, dynamic>> data =
          await supabase.from('User').select().order('id', ascending: true);

      List<User> users = data.map((item) => User.fromJson(item)).toList();
      return users;
    } catch (e) {
      print('Erreur lors de la récupération des Users: $e');
      return [];
    }
  }

  Future<void> clearAllTables() async {
    final supabase = Supa.Supabase.instance.client;

    try {
      // Supprimer les lignes de la table de relation en premier

      await supabase
          .from('lignes_facture')
          .delete()
          .neq('id', 0)
          .timeout(Duration(minutes: 2));
      print('Toutes les tables lignes_facture ont été vidées avec succès.');
      // Supprimer les lignes de la table produits
      // print('Suppression des lignes de la table produits...');
      //
      // supabase
      //     .from('produits')
      //     .delete()
      //     .neq('id', 0)
      //     .timeout(Duration(minutes: 2));
      // print('Lignes de la table produits supprimées avec succès.');
      print('Suppression des lignes de la table cruds...');
      await supabase.from('cruds').delete().neq('id', 0);
      print('Suppression des lignes de la table produits...');
      await supabase.from('produits').delete().neq('id', 0);
      print('Lignes de la table produits supprimées avec succès.');

      print('Lignes de la table cruds supprimées avec succès.');
      print('Suppression des lignes de la table approvisionnements...');
      await supabase.from('approvisionnements').delete().neq('id', 0);
      print('Lignes de la table approvisionnements supprimées avec succès.');
      // Supprimer les lignes de la table fournisseurs
      print('Suppression des lignes de la table fournisseurs...');
      await supabase.from('fournisseurs').delete().neq('id', 0);
      print('Lignes de la table fournisseurs supprimées avec succès.');

      print('Toutes les tables ont été vidées avec succès.');
      await supabase.from('factures').delete().neq('id', 0);
      print('Toutes les tables Facture ont été vidées avec succès.');
      await supabase.from('users').delete().neq('id', 0);
      print('Toutes les tables Facture ont été vidées avec succès.');
      await supabase.from('clients').delete().neq('id', 0);
      print('Toutes les tables Client ont été vidées avec succès.');
      await supabase.from('deleted_products').delete().neq('id', 0);
      print(
          'Toutes les tables DeletedProductClient ont été vidées avec succès.');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Toutes les tables ont été vidées avec succès.',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.blue,
        ),
      );
    } catch (e) {
      print('Erreur lors de la suppression des tables: $e');
    }
  }

  Color getColorBasedOnPeremption(int peremption, double alert) {
    if (peremption <= 0) {
      return Colors.red;
    } else if (peremption > 0 && peremption <= alert) {
      return Colors.orange;
    } else {
      return Colors.green;
    }
  }

  Color getColorBasedOnStock(double stock, double stockInit, double alert) {
    if (stock <= 0) {
      return Colors.grey;
    } else if (stock > 0 && stock <= alert) {
      return Colors.red;
    } else if (stock <= alert && stock > stockInit * 0.30) {
      return Colors.orange;
    } else {
      return Colors.green;
    }
  }

  Future<void> updateObjectBoxRelationships() async {
    developer.log('Début de la mise à jour des relations ObjectBox');

    // Get all Approvisionnement entities
    final approvisionnementBox = widget.objectboxStore.box<Approvisionnement>();
    final approvisionnements = approvisionnementBox.getAll();

    // Get all Fournisseur entities
    final fournisseurBox = widget.objectboxStore.box<Fournisseur>();
    final fournisseurs = fournisseurBox.getAll();

    // Create a map of Fournisseur entities for quick lookup
    final fournisseurMap = Map.fromIterable(
      fournisseurs,
      key: (fournisseur) => fournisseur.id,
      value: (fournisseur) => fournisseur,
    );

    // Update Approvisionnement entities with valid Fournisseur references
    for (final approvisionnement in approvisionnements) {
      final fournisseurId = approvisionnement.fournisseur.targetId;
      if (fournisseurId != null && !fournisseurMap.containsKey(fournisseurId)) {
        // Remove the invalid reference
        approvisionnement.fournisseur.target = null;
        approvisionnementBox.put(approvisionnement);
        developer.log(
            'Relation invalide supprimée pour l\'approvisionnement avec ID: ${approvisionnement.id}');
      }
    }

    developer.log('Fin de la mise à jour des relations ObjectBox');
  }

  @override
  Widget build(BuildContext context) {
    // final double largeur;
    // if (kIsWeb || Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    //   // Pour le web
    //   largeur = 1 / 10;
    // } else if (Platform.isAndroid || Platform.isIOS) {
    //   // Pour Android et iOS
    //   largeur = 0.5;
    // } else {
    //   // Pour les autres plateformes (Desktop)
    //   largeur = 1 / 10;
    // }

    return Scaffold(
      appBar: AppBar(
        title: Text('Liste des Produits'),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.all(2.0),
              child: Row(
                children: [
                  if (_errorMessage != null)
                    Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Center(
                          child: Text(
                            'Erreur', // : $_errorMessage',
                            style: TextStyle(color: Colors.red),
                          ),
                        )),
                  if (_successMessage != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Center(
                        child: Text(
                          '$_successMessage',
                          style: TextStyle(color: Colors.green),
                        ),
                      ),
                    ),
                  if (_isSyncing)
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: CircularProgressIndicator(
                        strokeWidth: 3.0,
                      ),
                    )
                  else
                    IconButton(
                      icon: Icon(Icons.sync),
                      onPressed: _syncData,
                    ),
                ],
              ),
            ),
          ),
          // Center(
          //   child: Padding(
          //     padding: const EdgeInsets.all(2.0),
          //     child: Row(
          //       children: [
          //         if (_errorMessageF != null)
          //           Padding(
          //               padding: const EdgeInsets.symmetric(horizontal: 16),
          //               child: Center(
          //                 child: Text(
          //                   'Erreur', // : $_errorMessage',
          //                   style: TextStyle(color: Colors.red),
          //                 ),
          //               )),
          //         if (_successMessageF != null)
          //           Padding(
          //             padding: const EdgeInsets.symmetric(horizontal: 16),
          //             child: Center(
          //               child: Text(
          //                 '$_successMessageF',
          //                 style: TextStyle(color: Colors.green),
          //               ),
          //             ),
          //           ),
          //         if (_isSyncingF)
          //           Padding(
          //             padding: const EdgeInsets.all(8.0),
          //             child: CircularProgressIndicator(
          //               strokeWidth: 3.0,
          //             ),
          //           )
          //         else
          //           IconButton(
          //             icon: Icon(Icons.sync, color: Colors.red),
          //             onPressed: _syncDataFrom,
          //           ),
          //       ],
          //     ),
          //   ),
          // ),
          IconButton(
            icon: Icon(Icons.delete_forever, color: Colors.red),
            onPressed: clearAllTables,
          ),
          ElevatedButton(
            onPressed: () async {
              await updateObjectBoxRelationships();
              // Perform synchronization or any other action after updating relationships
            },
            child: Text('Update Relationships'),
          ),
          kIsWeb ||
                  Platform.isWindows ||
                  Platform.isLinux ||
                  Platform.isMacOS //|| Platform.isFushia
              ? SizedBox(
                  width: 50,
                )
              : Container(),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Produits'),
            // Tab(text: 'Fournisseurs'),
            // Tab(text: 'Users'),
            // Tab(text: 'Clients'),
            // Tab(text: 'Factures'),
            // Tab(text: 'DeletedProducts'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          ListView.builder(
            controller: _scrollControllerProduits,
            itemCount: _produits.length + 1,
            itemBuilder: (context, index) {
              if (index != 0 &&
                  index % 5 == 0 &&
                  _nativeAd != null &&
                  _nativeAdIsLoaded) {
                return Align(
                  alignment: Alignment.center,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      minWidth: 300,
                      minHeight: 350,
                      maxHeight: 400,
                      maxWidth: 450,
                    ),
                    child: AdWidget(ad: _nativeAd!),
                  ),
                );
              }

              if (index < _produits.length) {
                final produit = _produits[index];

                return Card(
                  child: Platform.isIOS || Platform.isAndroid
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                              ListTile(
                                leading: Tooltip(
                                  message: 'ID : ${produit.id}',
                                  child: GestureDetector(
                                    child: produit.image == null ||
                                            produit.image!.isEmpty
                                        ? CircleAvatar(
                                            child:
                                                Icon(Icons.image_not_supported),
                                          )
                                        : Column(
                                            children: [
                                              Expanded(
                                                child: CircleAvatar(
                                                  backgroundImage:
                                                      CachedNetworkImageProvider(
                                                    produit.image!,
                                                    errorListener: (error) =>
                                                        Icon(Icons.error),
                                                  ),
                                                ),
                                              ),
                                              Text('Id:' +
                                                  produit.id.toString()),
                                            ],
                                          ),
                                  ),
                                ),
                                title: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 8),
                                  child: Text(produit.nom),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Column(
                                      children: [
                                        // Row(
                                        //   children: [
                                        //     SizedBox(
                                        //       width: 10,
                                        //     ),
                                        //     Container(
                                        //       padding: EdgeInsets.symmetric(
                                        //           horizontal: 5, vertical: 2),
                                        //       decoration: BoxDecoration(
                                        //         gradient: LinearGradient(
                                        //           colors: [
                                        //             Colors.lightGreen,
                                        //             Colors.black45
                                        //           ], // Couleurs du dégradé
                                        //           begin: Alignment
                                        //               .topLeft, // Début du dégradé
                                        //           end: Alignment
                                        //               .bottomRight, // Fin du dégradé
                                        //         ), // Couleur de fond
                                        //         borderRadius:
                                        //             BorderRadius.circular(
                                        //                 10), // Coins arrondis
                                        //       ),
                                        //       child: Center(
                                        //         child: Text(
                                        //           '${(produit.prixVente - produit.prixAchat).toStringAsFixed(2)}',
                                        //           style: TextStyle(
                                        //               color: Colors.white),
                                        //         ),
                                        //       ),
                                        //     ),
                                        //   ],
                                        // ),
                                        SizedBox(height: 5),
                                        // Container(
                                        //   padding: EdgeInsets.symmetric(
                                        //       horizontal: 5, vertical: 2),
                                        //   decoration: BoxDecoration(
                                        //     gradient: LinearGradient(
                                        //       colors: [
                                        //         Colors.red,
                                        //         Colors.black45
                                        //       ], // Couleurs du dégradé
                                        //       begin: Alignment
                                        //           .topLeft, // Début du dégradé
                                        //       end: Alignment
                                        //           .bottomRight, // Fin du dégradé
                                        //     ), // Couleur de fond
                                        //     borderRadius: BorderRadius.circular(
                                        //         10), // Coins arrondis
                                        //   ),
                                        //   child: Center(
                                        //     child: Text(
                                        //       'Reste : ${produit.datePeremption!.difference(DateTime.now()).inDays} Jours ',
                                        //       style: TextStyle(
                                        //           color: Colors.white),
                                        //     ),
                                        //   ),
                                        // ),
                                      ],
                                    ),
                                    SizedBox(
                                      height: 5,
                                    ),
                                  ],
                                ),
                                trailing: Padding(
                                  padding: const EdgeInsets.only(left: 15),
                                  child: Text(
                                    '${produit.prixVente.toStringAsFixed(2)}',
                                    style: TextStyle(fontSize: 20),
                                  ),
                                ),
                              ),
                              Row(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8),
                                    child:
                                        Text('QR : ' + produit.qr.toString()),
                                  ),
                                  SizedBox(width: 2),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 5, vertical: 2),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.blue,
                                          Colors.black45
                                        ], // Couleurs du dégradé
                                        begin: Alignment
                                            .topLeft, // Début du dégradé
                                        end: Alignment
                                            .bottomRight, // Fin du dégradé
                                      ), // Couleur de fond
                                      borderRadius: BorderRadius.circular(
                                          10), // Coins arrondis
                                    ),
                                    child: Center(
                                      child: Text(
                                        '${produit.minimStock!.toStringAsFixed(produit.minimStock!.truncateToDouble() == produit.minimStock ? 0 : 2)}',
                                        // '${(produit.minimStock).toStringAsFixed(2)}',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 2),
                                  // Expanded(
                                  //   child: Padding(
                                  //     padding:
                                  //         EdgeInsets.symmetric(horizontal: 15),
                                  //     child: new LinearPercentIndicator(
                                  //       animation: true,
                                  //       animationDuration: 1000,
                                  //       lineHeight: 20.0,
                                  //       leading: new Text(produit.stockinit
                                  //           .toStringAsFixed(1)),
                                  //       trailing: new Text(
                                  //           produit.stock.toStringAsFixed(1)),
                                  //       percent: percentProgress,
                                  //       center: new Text(
                                  //           '${(percentProgress * 100).toStringAsFixed(1)}%'),
                                  //       linearStrokeCap:
                                  //           LinearStrokeCap.roundAll,
                                  //       backgroundColor: Colors.grey.shade300,
                                  //       progressColor: colorStock,
                                  //     ),
                                  //   ),
                                  // ),
                                ],
                              ),
                              SizedBox(height: 15),
                            ])
                      : GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(MaterialPageRoute(
                              builder: (ctx) =>
                                  ProduitDetailPage(produit: produit),
                            ));
                          },
                          child: Container(
                            width: MediaQuery.of(context).size.width,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 15, vertical: 8),
                                  child: Tooltip(
                                    message: 'ID : ${produit.id}',
                                    child: produit.image == null ||
                                            produit.image!.isEmpty
                                        ? CircleAvatar(
                                            child:
                                                Icon(Icons.image_not_supported),
                                          )
                                        : Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              ClipRRect(
                                                child: CachedNetworkImage(
                                                  imageUrl: produit.image!,
                                                ),
                                              ),
                                              // CircleAvatar(
                                              //   backgroundImage:
                                              //       CachedNetworkImageProvider(
                                              //     produit.image!,
                                              //     errorListener: (error) =>
                                              //         Icon(Icons.error),
                                              //   ),
                                              // ),
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                    top: 8),
                                                child: Text('Id:' +
                                                    produit.id.toString()),
                                              ),
                                            ],
                                          ),
                                  ),
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(produit.nom),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              // Center(
                                              //   child: Text(
                                              //     'A: ${produit.prixAchat.toStringAsFixed(2)} ',
                                              //   ),
                                              // ),
                                              SizedBox(
                                                width: 10,
                                              ),
                                              // Container(
                                              //   padding: EdgeInsets.symmetric(
                                              //       horizontal: 5, vertical: 2),
                                              //   decoration: BoxDecoration(
                                              //     gradient: LinearGradient(
                                              //       colors: [
                                              //         Colors.lightGreen,
                                              //         Colors.black45
                                              //       ], // Couleurs du dégradé
                                              //       begin: Alignment
                                              //           .topLeft, // Début du dégradé
                                              //       end: Alignment
                                              //           .bottomRight, // Fin du dégradé
                                              //     ), // Couleur de fond
                                              //     borderRadius:
                                              //         BorderRadius.circular(
                                              //             10), // Coins arrondis
                                              //   ),
                                              //   child: Center(
                                              //     child: Text(
                                              //       '${(produit.prixVente - produit.prixAchat).toStringAsFixed(2)}',
                                              //       style: TextStyle(
                                              //           color: Colors.white),
                                              //     ),
                                              //   ),
                                              // ),
                                              SizedBox(
                                                width: 10,
                                              ),
                                              // Container(
                                              //   padding: EdgeInsets.symmetric(
                                              //       horizontal: 5, vertical: 2),
                                              //   decoration: BoxDecoration(
                                              //     gradient: LinearGradient(
                                              //       colors: [
                                              //         Colors.black45,
                                              //         colorPeremption,
                                              //       ], // Couleurs du dégradé
                                              //       begin: Alignment
                                              //           .topLeft, // Début du dégradé
                                              //       end: Alignment
                                              //           .bottomRight, // Fin du dégradé
                                              //     ), // Couleur de fond
                                              //     borderRadius:
                                              //         BorderRadius.circular(
                                              //             10), // Coins arrondis
                                              //   ),
                                              //   child: Center(
                                              //     child: Text(
                                              //       'Péremption : ${produit.datePeremption!.day}/${produit.datePeremption!.month}/${produit.datePeremption!.year}  Reste : ${peremption} Jours ',
                                              //       style: TextStyle(
                                              //           color: Colors.white),
                                              //     ),
                                              //   ),
                                              // ),
                                            ],
                                          ),
                                          SizedBox(height: 5),
                                          Center(
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 15),
                                              child: Text('QR : ' +
                                                  produit.qr.toString()),
                                            ),
                                          )
                                        ],
                                      ),
                                      SizedBox(height: 5),
                                      Row(
                                        children: [
                                          Container(
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 5, vertical: 2),
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [
                                                  Colors.blue,
                                                  Colors.black45
                                                ], // Couleurs du dégradé
                                                begin: Alignment
                                                    .topLeft, // Début du dégradé
                                                end: Alignment
                                                    .bottomRight, // Fin du dégradé
                                              ), // Couleur de fond
                                              borderRadius:
                                                  BorderRadius.circular(
                                                      10), // Coins arrondis
                                            ),
                                            child: Center(
                                              child: Text(
                                                '${produit.minimStock!.toStringAsFixed(produit.minimStock!.truncateToDouble() == produit.minimStock ? 0 : 2)}',
                                                style: TextStyle(
                                                    color: Colors.white),
                                              ),
                                            ),
                                          ),
                                          SizedBox(width: 5),
                                          // Expanded(
                                          //   child: new LinearPercentIndicator(
                                          //     animation: true,
                                          //     animationDuration: 1000,
                                          //     lineHeight: 20.0,
                                          //     leading: new Text(produit
                                          //         .stockinit
                                          //         .toStringAsFixed(2)),
                                          //     trailing: new Text(produit.stock
                                          //         .toStringAsFixed(2)),
                                          //     percent: percentProgress < 0
                                          //         ? 0
                                          //         : percentProgress,
                                          //     center: new Text(
                                          //         '${(percentProgress * 100).toStringAsFixed(1)}%'),
                                          //     linearStrokeCap:
                                          //         LinearStrokeCap.roundAll,
                                          //     backgroundColor:
                                          //         Colors.grey.shade300,
                                          //     progressColor: colorStock,
                                          //   ),
                                          // ),
                                        ],
                                      ),
                                      SizedBox(height: 5),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 8, horizontal: 25),
                                  child: Text(
                                    '${produit.prixVente.toStringAsFixed(2)}',
                                    style: TextStyle(fontSize: 20),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                );
              } else if (_hasMore) {
                return Center(
                  child: LinearProgressIndicator(),
                );
              } else {
                return Container(
                  padding: EdgeInsets.all(16),
                  alignment: Alignment.center,
                  child: Text('Fin de la liste'),
                );
              }
            },
          ),
          // ListView.builder(
          //   controller: _scrollControllerFournisseurs,
          //   itemCount: _fournisseurs.length + 1,
          //   itemBuilder: (context, index) {
          //     if (index < _fournisseurs.length) {
          //       final fournisseur = _fournisseurs[index];
          //       return Card(
          //         child: ListTile(
          //           onTap: () {
          //             Navigator.of(context).push(
          //               MaterialPageRoute(
          //                 builder: (context) => ProduitsFournisseurPage(
          //                   fournisseur: fournisseur,
          //                 ),
          //               ),
          //             );
          //           },
          //           leading: CircleAvatar(
          //             child: FittedBox(
          //                 child: Padding(
          //               padding: const EdgeInsets.all(8.0),
          //               child: Text(fournisseur.id.toString()),
          //             )),
          //           ),
          //           title: Text(fournisseur.nom),
          //           subtitle: Column(
          //             crossAxisAlignment: CrossAxisAlignment.start,
          //             children: [
          //               Text('Phone : ${fournisseur.phone}'),
          //               Text(
          //                 'Créer le ${fournisseur.dateCreation.day}-${fournisseur.dateCreation.month}-${fournisseur.dateCreation.year}  Modifié ${timeago.format(fournisseur.derniereModification!, locale: 'fr')}',
          //                 style: TextStyle(
          //                     fontSize: 13, fontWeight: FontWeight.w300),
          //               ),
          //             ],
          //           ),
          //           trailing: Container(
          //             width: 50,
          //             child: Row(
          //               mainAxisAlignment: MainAxisAlignment.start,
          //               children: [
          //                 Expanded(
          //                   child: Text(
          //                     fournisseur.produits.length.toString(),
          //                     style: TextStyle(fontSize: 20),
          //                   ),
          //                 ),
          //               ],
          //             ),
          //           ),
          //         ),
          //       );
          //     } else if (_hasMore) {
          //       return Center(
          //         child: LinearProgressIndicator(),
          //       );
          //     } else {
          //       return Container(
          //         padding: EdgeInsets.all(16),
          //         alignment: Alignment.center,
          //         child: Text('Fin de la liste'),
          //       );
          //     }
          //   },
          // ),
          // ListView.builder(
          //   itemCount: _users.length,
          //   itemBuilder: (context, index) {
          //     if (index < _users.length) {
          //       final user = _users[index];
          //       return ListTile(
          //         title: Text(user.username),
          //         subtitle: Text(user.email),
          //         // Add more widgets here to display other user data
          //       );
          //     } else if (_hasMore) {
          //       return Center(
          //         child: LinearProgressIndicator(),
          //       );
          //     } else {
          //       return Container(
          //         padding: EdgeInsets.all(16),
          //         alignment: Alignment.center,
          //         child: Text('Fin de la liste'),
          //       );
          //     }
          //   },
          // ),
          // ListView.builder(
          //   controller: _scrollControllerClients,
          //   itemCount: _clients.length + 1,
          //   itemBuilder: (context, index) {
          //     if (index < _clients.length) {
          //       final client = _clients[index];
          //       return Card(
          //         child: ListTile(
          //           onTap: () {
          //             // Navigator.of(context).push(
          //             //   MaterialPageRoute(
          //             //     builder: (context) => ProduitsFournisseurPage(
          //             //       fournisseur: fournisseur,
          //             //     ),
          //             //   ),
          //             // );
          //           },
          //           leading: CircleAvatar(
          //             child: FittedBox(
          //                 child: Padding(
          //               padding: const EdgeInsets.all(8.0),
          //               child: Text(client.id.toString()),
          //             )),
          //           ),
          //           title: Text(client.nom),
          //           subtitle: Column(
          //             crossAxisAlignment: CrossAxisAlignment.start,
          //             children: [
          //               Text('Phone : ${client.phone}'),
          //               Text(
          //                 'Créer le ${client.dateCreation!.day}-${client.dateCreation!.month}-${client.dateCreation!.year}  Modifié ${timeago.format(client.derniereModification!, locale: 'fr')}',
          //                 style: TextStyle(
          //                     fontSize: 13, fontWeight: FontWeight.w300),
          //               ),
          //             ],
          //           ),
          //           trailing: Container(
          //             width: 50,
          //             child: Row(
          //               mainAxisAlignment: MainAxisAlignment.start,
          //               children: [
          //                 Expanded(
          //                   child: Text(
          //                     client.factures.length.toString(),
          //                     style: TextStyle(fontSize: 20),
          //                   ),
          //                 ),
          //               ],
          //             ),
          //           ),
          //         ),
          //       );
          //     } else if (_hasMore) {
          //       return Center(
          //         child: LinearProgressIndicator(),
          //       );
          //     } else {
          //       return Container(
          //         padding: EdgeInsets.all(16),
          //         alignment: Alignment.center,
          //         child: Text('Fin de la liste'),
          //       );
          //     }
          //   },
          // ),
          // ListView.builder(
          //   controller: _scrollControllerFactures,
          //   itemCount: _factures.length + 1,
          //   itemBuilder: (context, index) {
          //     if (index < _factures.length) {
          //       final facture = _factures[index];
          //       return Card(
          //         child: ListTile(
          //           onTap: () {
          //             // Navigator.of(context).push(
          //             //   MaterialPageRoute(
          //             //     builder: (context) => ProduitsFournisseurPage(
          //             //       fournisseur: fournisseur,
          //             //     ),
          //             //   ),
          //             // );
          //           },
          //           leading: CircleAvatar(
          //             child: FittedBox(
          //                 child: Padding(
          //               padding: const EdgeInsets.all(8.0),
          //               child: Text(facture.id.toString()),
          //             )),
          //           ),
          //           title: Text('${facture.client.target?.nom ?? 'Unknown'}'),
          //           subtitle: Column(
          //             crossAxisAlignment: CrossAxisAlignment.start,
          //             children: [
          //               Text('Phone : ${facture.lignesFacture.length}'),
          //               Text(
          //                 'Créer le ${facture.date.day}-${facture.date.month}-${facture.date.year}  Modifié ${timeago.format(facture.date, locale: 'fr')}',
          //                 style: TextStyle(
          //                     fontSize: 13, fontWeight: FontWeight.w300),
          //               ),
          //             ],
          //           ),
          //         ),
          //       );
          //     } else if (_hasMore) {
          //       return Center(
          //         child: LinearProgressIndicator(),
          //       );
          //     } else {
          //       return Container(
          //         padding: EdgeInsets.all(16),
          //         alignment: Alignment.center,
          //         child: Text('Fin de la liste'),
          //       );
          //     }
          //   },
          // ),
          // ListView.builder(
          //   controller: _scrollControllerDeletedProducts,
          //   itemCount: _deletedProducts.length + 1,
          //   itemBuilder: (context, index) {
          //     if (index < _deletedProducts.length) {
          //       final deletedProduct = _deletedProducts[index];
          //       return Card(
          //         child: ListTile(
          //           onTap: () {
          //             // Navigator.of(context).push(
          //             //   MaterialPageRoute(
          //             //     builder: (context) => ProduitsFournisseurPage(
          //             //       fournisseur: fournisseur,
          //             //     ),
          //             //   ),
          //             // );
          //           },
          //           leading: CircleAvatar(
          //             child: FittedBox(
          //                 child: Padding(
          //               padding: const EdgeInsets.all(8.0),
          //               child: Text(deletedProduct.id.toString()),
          //             )),
          //           ),
          //           title: Text(deletedProduct.name),
          //           subtitle: Text('Prix : ${deletedProduct.price}'),
          //         ),
          //       );
          //     } else if (_hasMore) {
          //       return Center(
          //         child: LinearProgressIndicator(),
          //       );
          //     } else {
          //       return Container(
          //         padding: EdgeInsets.all(16),
          //         alignment: Alignment.center,
          //         child: Text('Fin de la liste'),
          //       );
          //     }
          //   },
          // ),
        ],
      ),
    );
  }
}
