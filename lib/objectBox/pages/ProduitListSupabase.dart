// import 'dart:io';
// import 'dart:isolate';
// import 'package:supabase_flutter/supabase_flutter.dart' as Supa;
// import 'package:objectbox/objectbox.dart';
// import 'package:cached_network_image/cached_network_image.dart';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:percent_indicator/linear_percent_indicator.dart';
// import '../Entity.dart';
// import '../classeObjectBox.dart';
// import 'FournisseurListScreen.dart';
// import 'ProduitListScreen.dart';
// import 'dart:io' show Platform;
// import 'package:flutter/foundation.dart' show kIsWeb;
// import 'package:timeago/timeago.dart' as timeago;
// import 'dart:developer' as developer;
//
// class SyncException implements Exception {
//   final String message;
//   SyncException(this.message);
//   @override
//   String toString() => 'SyncException: $message';
// }
//
// class SupabaseSync {
//   final Supa.SupabaseClient supabase;
//   final Store objectboxStore;
//
//   SupabaseSync(this.supabase, this.objectboxStore);
//
//   Future<void> syncToSupabase() async {
//     developer.log('Début de syncToSupabase');
//
//     try {
//       await _syncUsers();
//       await _syncFournisseurs();
//       await _syncProduits();
//       await _syncClients();
//       await _syncFactures();
//       await _syncLignesFacture();
//       await _syncDeletedProducts();
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
//   Future<void> _syncUsers() async {
//     developer.log('Début de la synchronisation des utilisateurs');
//     final userBox = objectboxStore.box<User>();
//     final usersData = userBox
//         .getAll()
//         .map((user) => {
//               'id': user.id,
//               'photo': user.photo,
//               'username': user.username,
//               'password': user.password,
//               'email': user.email,
//               'phone': user.phone,
//               'role': user.role,
//             })
//         .toList();
//
//     final result =
//         await supabase.from('User').upsert(usersData, onConflict: 'id');
//     developer.log('Résultat de la synchronisation des utilisateurs: $result');
//   }
//
//   Future<void> _syncFournisseurs() async {
//     developer.log('Début de la synchronisation des fournisseurs');
//     final fournisseurBox = objectboxStore.box<Fournisseur>();
//     final fournisseursData = fournisseurBox
//         .getAll()
//         .map((fournisseur) => {
//               'id': fournisseur.id,
//               'qr': fournisseur.qr,
//               'nom': fournisseur.nom,
//               'phone': fournisseur.phone,
//               'adresse': fournisseur.adresse,
//               'createdBy': fournisseur.createdBy,
//               'updatedBy': fournisseur.updatedBy,
//               'deletedBy': fournisseur.deletedBy,
//               'dateCreation': fournisseur.dateCreation.toIso8601String(),
//               'derniereModification':
//                   fournisseur.derniereModification?.toIso8601String(),
//             })
//         .toList();
//
//     final result = await supabase
//         .from('Fournisseur')
//         .upsert(fournisseursData, onConflict: 'id');
//     developer.log('Résultat de la synchronisation des fournisseurs: $result');
//   }
//
//   Future<void> _syncProduits() async {
//     developer.log('Début de la synchronisation des produits');
//     final produitBox = objectboxStore.box<Produit>();
//     final produitsData = produitBox
//         .getAll()
//         .map((produit) => {
//               'id': produit.id,
//               'qr': produit.qr,
//               'image': produit.image,
//               'nom': produit.nom,
//               'description': produit.description,
//               'origine': produit.origine,
//               'prixAchat': produit.prixAchat,
//               'prixVente': produit.prixVente,
//               'stock': produit.stock,
//               'minimStock': produit.minimStock,
//               'stockInit': produit.stockinit,
//               'createdBy': produit.createdBy,
//               'updatedBy': produit.updatedBy,
//               'deletedBy': produit.deletedBy,
//               'dateCreation': produit.dateCreation?.toIso8601String(),
//               'datePeremption': produit.datePeremption?.toIso8601String(),
//               'stockUpdate': produit.stockUpdate?.toIso8601String(),
//               'derniereModification':
//                   produit.derniereModification.toIso8601String(),
//             })
//         .toList();
//
//     final result =
//         await supabase.from('Produit').upsert(produitsData, onConflict: 'id');
//     developer.log('Résultat de la synchronisation des produits: $result');
//   }
//
//   Future<void> _syncClients() async {
//     developer.log('Début de la synchronisation des clients');
//     final clientBox = objectboxStore.box<Client>();
//     final clientsData = clientBox
//         .getAll()
//         .map((client) => {
//               'id': client.id,
//               'qr': client.qr,
//               'nom': client.nom,
//               'phone': client.phone,
//               'adresse': client.adresse,
//               'description': client.description,
//               'createdBy': client.createdBy,
//               'updatedBy': client.updatedBy,
//               'deletedBy': client.deletedBy,
//               'dateCreation': client.dateCreation?.toIso8601String(),
//               'derniereModification':
//                   client.derniereModification?.toIso8601String(),
//             })
//         .toList();
//
//     final result =
//         await supabase.from('Client').upsert(clientsData, onConflict: 'id');
//     developer.log('Résultat de la synchronisation des clients: $result');
//   }
//
//   Future<void> _syncFactures() async {
//     developer.log('Début de la synchronisation des factures');
//     final factureBox = objectboxStore.box<Facture>();
//     final facturesData = factureBox
//         .getAll()
//         .map((facture) => {
//               'id': facture.id,
//               'qr': facture.qr,
//               'impayer': facture.impayer,
//               'createdBy': facture.createdBy,
//               'updatedBy': facture.updatedBy,
//               'deletedBy': facture.deletedBy,
//               'date': facture.date.toIso8601String(),
//               'client_id': facture.client.target?.id,
//             })
//         .toList();
//
//     final result =
//         await supabase.from('Facture').upsert(facturesData, onConflict: 'id');
//     developer.log('Résultat de la synchronisation des factures: $result');
//   }
//
//   Future<void> _syncLignesFacture() async {
//     developer.log('Début de la synchronisation des lignes de facture');
//     final ligneFactureBox = objectboxStore.box<LigneFacture>();
//     final lignesFactureData = ligneFactureBox
//         .getAll()
//         .map((ligne) => {
//               'id': ligne.id,
//               'produit_id': ligne.produit.target?.id,
//               'facture_id': ligne.facture.target?.id,
//               'quantite': ligne.quantite,
//               'prixUnitaire': ligne.prixUnitaire,
//             })
//         .toList();
//
//     final result = await supabase
//         .from('LigneFacture')
//         .upsert(lignesFactureData, onConflict: 'id');
//     developer
//         .log('Résultat de la synchronisation des lignes de facture: $result');
//   }
//
//   Future<void> _syncDeletedProducts() async {
//     developer.log('Début de la synchronisation des produits supprimés');
//     final deletedProductBox = objectboxStore.box<DeletedProduct>();
//     final deletedProductsData = deletedProductBox
//         .getAll()
//         .map((product) => {
//               'id': product.id,
//               'name': product.name,
//               'description': product.description,
//               'price': product.price,
//               'quantity': product.quantity,
//               'createdBy': product.createdBy,
//               'updatedBy': product.updatedBy,
//               'deletedBy': product.deletedBy,
//               'deletedAt': product.deletedAt.toIso8601String(),
//             })
//         .toList();
//
//     final result = await supabase
//         .from('DeletedProduct')
//         .upsert(deletedProductsData, onConflict: 'id');
//     developer
//         .log('Résultat de la synchronisation des produits supprimés: $result');
//   }
//
//   Future<void> syncFromSupabase() async {
//     final fournisseurBox = objectboxStore.box<Fournisseur>();
//     final produitBox = objectboxStore.box<Produit>();
//
//     try {
//       // Préparer les données à synchroniser
//       final fournisseursResponse = await supabase.from('Fournisseur').select();
//       final fournisseursData = fournisseursResponse as List<dynamic>;
//
//       final produitsResponse = await supabase.from('Produit').select();
//       final produitsData = produitsResponse as List<dynamic>;
//
//       final relationsResponse =
//           await supabase.from('Produit_Fournisseur').select();
//       final relationsData = relationsResponse as List<dynamic>;
//
//       // Effectuer les opérations dans une transaction ObjectBox
//       objectboxStore.runInTransaction(TxMode.write, () {
//         // Synchroniser les fournisseurs
//         for (var data in fournisseursData) {
//           final fournisseur = Fournisseur.fromJson(data);
//           if (fournisseur.id == 0) {
//             fournisseurBox.put(fournisseur); // ID 0 -> nouvel objet
//           } else {
//             // Mettre à jour si existant
//             final existingFournisseur = fournisseurBox.get(fournisseur.id);
//             if (existingFournisseur != null) {
//               fournisseurBox.put(fournisseur);
//             } else {
//               // Si l'objet avec cet ID n'existe pas, vous pouvez choisir de le réinitialiser
//               fournisseur.id = 0;
//               fournisseurBox.put(fournisseur);
//             }
//           }
//         }
//
//         // Synchroniser les produits
//         for (var data in produitsData) {
//           final produit = Produit.fromJson(data);
//           produitBox.put(produit);
//         }
//
//         // Synchroniser les relations plusieurs-à-plusieurs
//         for (var data in relationsData) {
//           final fournisseur = fournisseurBox.get(data['fournisseur_id']);
//           final produit = produitBox.get(data['produit_id']);
//           if (fournisseur != null && produit != null) {
//             fournisseur.produits.add(produit);
//             produit.fournisseurs.add(fournisseur);
//           }
//         }
//
//         // Sauvegarder les modifications des relations
//         fournisseurBox.putMany(fournisseurBox.getAll());
//         produitBox.putMany(produitBox.getAll());
//       });
//     } catch (e) {
//       print(e);
//       throw SyncException(
//           'Erreur lors de la synchronisation depuis Supabase: $e');
//     }
//   }
// }
//
// class ProduitListPage extends StatefulWidget {
//   final Supa.SupabaseClient supabase;
//   final Store objectboxStore;
//
//   ProduitListPage({required this.supabase, required this.objectboxStore});
//
//   @override
//   _ProduitListPageState createState() => _ProduitListPageState();
// }
//
// class _ProduitListPageState extends State<ProduitListPage>
//     with TickerProviderStateMixin {
//   List<Produit> _produits = [];
//   List<Fournisseur> _fournisseurs = [];
//   List<User> _users = [];
//   List<Client> _clients = [];
//   List<Facture> _factures = [];
//   List<LigneFacture> _ligneFactures = [];
//   List<DeletedProduct> _deletedProducts = [];
//
//   bool _isLoading = false;
//   bool _hasMore = true;
//   final int _pageSize = 20;
//   int _currentPage = 0;
//
//   bool _isLoadingf = false;
//   bool _hasMoref = true;
//   final int _pageSizef = 20;
//   int _currentPagef = 0;
//
//   bool _isLoadingUser = false;
//   bool _hasMoreUser = true;
//   final int _pageSizeUser = 20;
//   int _currentPageUser = 0;
//
//   bool _isLoadingClient = false;
//   bool _hasMoreClient = true;
//   final int _pageSizeClient = 20;
//   int _currentPageClient = 0;
//
//   bool _isLoadingFacture = false;
//   bool _hasMoreFacture = true;
//   final int _pageSizeFacture = 20;
//   int _currentPageFacture = 0;
//
//   bool _isLoadingLF = false;
//   bool _hasMoreLF = true;
//   final int _pageSizeLF = 20;
//   int _currentPageLF = 0;
//
//   bool _isLoadingDP = false;
//   bool _hasMoreDP = true;
//   final int _pageSizeDP = 20;
//   int _currentPageDP = 0;
//
//   //final ScrollController _scrollController = ScrollController();
//   final ScrollController _scrollControllerProduits = ScrollController();
//   final ScrollController _scrollControllerFournisseurs = ScrollController();
//   final ScrollController _scrollControllerUsers = ScrollController();
//   final ScrollController _scrollControllerClients = ScrollController();
//   final ScrollController _scrollControllerFactures = ScrollController();
//   final ScrollController _scrollControllerLigneFactures = ScrollController();
//   final ScrollController _scrollControllerDeletedProducts = ScrollController();
//
//   late TabController _tabController;
//
//   @override
//   void initState() {
//     super.initState();
//     _loadMoreProduits();
//     _loadMoreFournisseurs();
//     _loadMoreUsers();
//     _loadMoreClients();
//     _loadMoreFactures();
//     _loadMoreLigneFactures();
//     _loadMoreDeletedProducts();
//     _scrollControllerProduits.addListener(_onScrollProduits);
//     _scrollControllerFournisseurs.addListener(_onScrollFournisseurs);
//     _scrollControllerUsers.addListener(_onScrollUsers);
//     _scrollControllerClients.addListener(_onScrollClients);
//     _scrollControllerFactures.addListener(_onScrollFactures);
//     _scrollControllerLigneFactures.addListener(_onScrollLigneFactures);
//     _scrollControllerDeletedProducts.addListener(_onScrollDeletedProducts);
//
//     _tabController = TabController(length: 6, vsync: this);
//   }
//
//   @override
//   void dispose() {
//     _scrollControllerProduits.removeListener(_onScrollProduits);
//     _scrollControllerFournisseurs.removeListener(_onScrollFournisseurs);
//     _scrollControllerUsers.removeListener(_onScrollUsers);
//     _scrollControllerClients.removeListener(_onScrollClients);
//     _scrollControllerFactures.removeListener(_onScrollFactures);
//     _scrollControllerLigneFactures.removeListener(_onScrollLigneFactures);
//     _scrollControllerDeletedProducts.removeListener(_onScrollDeletedProducts);
//
//     _scrollControllerProduits.dispose();
//     _scrollControllerFournisseurs.dispose();
//     _scrollControllerUsers.dispose();
//     _scrollControllerClients.dispose();
//     _scrollControllerFactures.dispose();
//     _scrollControllerLigneFactures.dispose();
//     _scrollControllerDeletedProducts.dispose();
//
//     _tabController.dispose();
//     super.dispose();
//   }
//
//   void _onScrollProduits() {
//     if (_scrollControllerProduits.position.pixels ==
//         _scrollControllerProduits.position.maxScrollExtent) {
//       _loadMoreProduits();
//     }
//   }
//
//   void _onScrollFournisseurs() {
//     if (_scrollControllerFournisseurs.position.pixels ==
//         _scrollControllerFournisseurs.position.maxScrollExtent) {
//       _loadMoreFournisseurs();
//     }
//   }
//
//   void _onScrollUsers() {
//     if (_scrollControllerUsers.position.pixels ==
//         _scrollControllerUsers.position.maxScrollExtent) {
//       _loadMoreUsers();
//     }
//   }
//
//   void _onScrollClients() {
//     if (_scrollControllerClients.position.pixels ==
//         _scrollControllerClients.position.maxScrollExtent) {
//       _loadMoreClients();
//     }
//   }
//
//   void _onScrollFactures() {
//     if (_scrollControllerFactures.position.pixels ==
//         _scrollControllerFactures.position.maxScrollExtent) {
//       _loadMoreFactures();
//     }
//   }
//
//   void _onScrollLigneFactures() {
//     if (_scrollControllerLigneFactures.position.pixels ==
//         _scrollControllerLigneFactures.position.maxScrollExtent) {
//       _loadMoreLigneFactures();
//     }
//   }
//
//   void _onScrollDeletedProducts() {
//     if (_scrollControllerDeletedProducts.position.pixels ==
//         _scrollControllerDeletedProducts.position.maxScrollExtent) {
//       _loadMoreDeletedProducts();
//     }
//   }
//
//   Future<void> _loadMoreProduits() async {
//     if (_isLoading || !_hasMore) return;
//
//     setState(() {
//       _isLoading = true;
//     });
//
//     try {
//       final supabase = Supa.Supabase.instance.client;
//       final List<Map<String, dynamic>> data = await supabase
//           .from('Produit')
//           .select()
//           .order('id', ascending: false)
//           .range(_currentPage * _pageSize, (_currentPage + 1) * _pageSize - 1);
//
//       if (data.isEmpty) {
//         setState(() {
//           _hasMore = false;
//         });
//       } else {
//         setState(() {
//           _produits.addAll(data.map((item) => Produit.fromJson(item)).toList());
//           _currentPage++;
//         });
//       }
//     } catch (e) {
//       print('Erreur lors de la récupération des produits: $e');
//     } finally {
//       setState(() {
//         _isLoading = false;
//       });
//     }
//   }
//
//   Future<void> _loadMoreFournisseurs() async {
//     if (_isLoadingf || !_hasMoref) return;
//
//     setState(() {
//       _isLoadingf = true;
//     });
//
//     try {
//       final supabase = Supa.Supabase.instance.client;
//       final List<Map<String, dynamic>> data = await supabase
//           .from('Fournisseur')
//           .select()
//           .order('id', ascending: false)
//           .range(
//               _currentPagef * _pageSizef, (_currentPagef + 1) * _pageSizef - 1);
//
//       if (data.isEmpty) {
//         setState(() {
//           _hasMoref = false;
//         });
//       } else {
//         setState(() {
//           _fournisseurs
//               .addAll(data.map((item) => Fournisseur.fromJson(item)).toList());
//           _currentPagef++;
//         });
//       }
//     } catch (e) {
//       print('Erreur lors de la récupération des Fournisseurs: $e');
//     } finally {
//       setState(() {
//         _isLoadingf = false;
//       });
//     }
//   }
//
//   Future<void> _loadMoreUsers() async {
//     if (_isLoadingUser || !_hasMoreUser) return;
//
//     setState(() {
//       _isLoadingUser = true;
//     });
//
//     try {
//       final supabase = Supa.Supabase.instance.client;
//       final List<Map<String, dynamic>> data = await supabase
//           .from('User')
//           .select()
//           .order('id', ascending: false)
//           .range(_currentPageUser * _pageSizeUser,
//               (_currentPageUser + 1) * _pageSizeUser - 1);
//
//       if (data.isEmpty) {
//         setState(() {
//           _hasMoreUser = false;
//         });
//       } else {
//         setState(() {
//           _users.addAll(data.map((item) => User.fromJson(item)).toList());
//           _currentPageUser++;
//         });
//       }
//     } catch (e) {
//       print('Erreur lors de la récupération des Users: $e');
//     } finally {
//       setState(() {
//         _isLoadingUser = false;
//       });
//     }
//   }
//
//   Future<void> _loadMoreClients() async {
//     if (_isLoadingClient || !_hasMoreClient) return;
//
//     setState(() {
//       _isLoadingClient = true;
//     });
//
//     try {
//       final supabase = Supa.Supabase.instance.client;
//       final List<Map<String, dynamic>> data = await supabase
//           .from('Client')
//           .select()
//           .order('id', ascending: false)
//           .range(_currentPageClient * _pageSizeClient,
//               (_currentPageClient + 1) * _pageSizeClient - 1);
//
//       if (data.isEmpty) {
//         setState(() {
//           _hasMoreClient = false;
//         });
//       } else {
//         setState(() {
//           _clients.addAll(data.map((item) => Client.fromJson(item)).toList());
//           _currentPageClient++;
//         });
//       }
//     } catch (e) {
//       print('Erreur lors de la récupération des clients: $e');
//     } finally {
//       setState(() {
//         _isLoadingClient = false;
//       });
//     }
//   }
//
//   Future<void> _loadMoreFactures() async {
//     if (_isLoadingFacture || !_hasMoreFacture) return;
//
//     setState(() {
//       _isLoadingFacture = true;
//     });
//
//     try {
//       final supabase = Supa.Supabase.instance.client;
//       final List<Map<String, dynamic>> data = await supabase
//           .from('Facture')
//           .select()
//           .order('id', ascending: false)
//           .range(_currentPageFacture * _pageSizeFacture,
//               (_currentPageFacture + 1) * _pageSizeFacture - 1);
//
//       if (data.isEmpty) {
//         setState(() {
//           _hasMoreFacture = false;
//         });
//       } else {
//         setState(() {
//           _factures.addAll(data.map((item) => Facture.fromJson(item)).toList());
//           _currentPageFacture++;
//         });
//       }
//     } catch (e) {
//       print('Erreur lors de la récupération des Factures: $e');
//     } finally {
//       setState(() {
//         _isLoadingFacture = false;
//       });
//     }
//   }
//
//   Future<void> _loadMoreLigneFactures() async {
//     if (_isLoadingLF || !_hasMoreLF) return;
//
//     setState(() {
//       _isLoadingLF = true;
//     });
//
//     try {
//       final supabase = Supa.Supabase.instance.client;
//       final List<Map<String, dynamic>> data = await supabase
//           .from('LigneFacture')
//           .select()
//           .order('id', ascending: false)
//           .range(_currentPageLF * _pageSizeLF,
//               (_currentPageLF + 1) * _pageSizeLF - 1);
//
//       if (data.isEmpty) {
//         setState(() {
//           _hasMoreLF = false;
//         });
//       } else {
//         setState(() {
//           _ligneFactures
//               .addAll(data.map((item) => LigneFacture.fromJson(item)).toList());
//           _currentPageLF++;
//         });
//       }
//     } catch (e) {
//       print('Erreur lors de la récupération des LigneFactures: $e');
//     } finally {
//       setState(() {
//         _isLoadingLF = false;
//       });
//     }
//   }
//
//   Future<void> _loadMoreDeletedProducts() async {
//     if (_isLoadingDP || !_hasMoreDP) return;
//
//     setState(() {
//       _isLoadingDP = true;
//     });
//
//     try {
//       final supabase = Supa.Supabase.instance.client;
//       final List<Map<String, dynamic>> data = await supabase
//           .from('DeletedProduct')
//           .select()
//           .order('id', ascending: false)
//           .range(_currentPageDP * _pageSizeDP,
//               (_currentPageDP + 1) * _pageSizeDP - 1);
//
//       if (data.isEmpty) {
//         setState(() {
//           _hasMoreDP = false;
//         });
//       } else {
//         setState(() {
//           _deletedProducts.addAll(
//               data.map((item) => DeletedProduct.fromJson(item)).toList());
//           _currentPageDP++;
//         });
//       }
//     } catch (e) {
//       print('Erreur lors de la récupération des DeletedProducts: $e');
//     } finally {
//       setState(() {
//         _isLoadingDP = false;
//       });
//     }
//   }
//
//   bool _isSyncing = false;
//   String? _errorMessage;
//   String? _successMessage;
//   bool _isSyncingF = false;
//   String? _errorMessageF;
//   String? _successMessageF;
//
//   Future<void> _syncData() async {
//     setState(() {
//       _isSyncing = true;
//       _errorMessage = null;
//       _successMessage = null;
//     });
//
//     final sync = SupabaseSync(widget.supabase, widget.objectboxStore);
//
//     try {
//       await sync.syncToSupabase();
//       // await sync.syncFromSupabase();
//       setState(() {
//         _successMessage = 'Synchronisation réussie';
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text(
//               _successMessage!,
//               style: TextStyle(color: Colors.white),
//             ),
//             backgroundColor: Colors.green,
//           ),
//         );
//       });
//     } on SyncException catch (e) {
//       setState(() {
//         _errorMessage = e.message;
//       });
//     } finally {
//       setState(() {
//         _isSyncing = false;
//       });
//     }
//   }
//
//   Future<void> _syncDataFrom() async {
//     setState(() {
//       _isSyncingF = true;
//       _errorMessageF = null;
//       _successMessageF = null;
//     });
//
//     final sync = SupabaseSync(widget.supabase, widget.objectboxStore);
//
//     try {
//       await sync.syncFromSupabase();
//       setState(() {
//         _successMessageF = 'Synchronisation Depuis Serveur réussie';
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text(
//               _successMessageF!,
//               style: TextStyle(color: Colors.white),
//             ),
//             backgroundColor: Colors.green,
//           ),
//         );
//       });
//     } on SyncException catch (e) {
//       setState(() {
//         _errorMessageF = e.message;
//       });
//     } finally {
//       setState(() {
//         _isSyncingF = false;
//       });
//     }
//   }
//
//   Future<List<User>> fetchUsersFromSupabase() async {
//     final supabase = Supa.Supabase.instance.client;
//     try {
//       final List<Map<String, dynamic>> data =
//           await supabase.from('User').select().order('id', ascending: true);
//
//       List<User> users = data.map((item) => User.fromJson(item)).toList();
//       return users;
//     } catch (e) {
//       print('Erreur lors de la récupération des Users: $e');
//       return [];
//     }
//   }
//
//   Future<void> clearAllTables() async {
//     final supabase = Supa.Supabase.instance.client;
//
//     try {
//       // Supprimer les lignes de la table de relation en premier
//       print('Suppression des lignes de la table produitfournisseur...');
//       await supabase
//           .from('Produit_Fournisseur')
//           .delete()
//           .neq('produit_id', 0)
//           .neq('fournisseur_id', 0);
//       setState(() {
//         _produits.clear();
//         _successMessage = "Toutes les tables ont été vidées";
//       });
//       print('Lignes de la table produitfournisseur supprimées avec succès.');
//       await supabase
//           .from('LigneFacture')
//           .delete()
//           .neq('id', 0)
//           .timeout(Duration(minutes: 2));
//       print('Toutes les tables LigneFacture ont été vidées avec succès.');
//       // Supprimer les lignes de la table produits
//       print('Suppression des lignes de la table produits...');
//
//       supabase
//           .from('Produit')
//           .delete()
//           .neq('id', 0)
//           .timeout(Duration(minutes: 2));
//       print('Lignes de la table produits supprimées avec succès.');
//
//       // Supprimer les lignes de la table fournisseurs
//       print('Suppression des lignes de la table fournisseurs...');
//       await supabase.from('Fournisseur').delete().neq('id', 0);
//       print('Lignes de la table fournisseurs supprimées avec succès.');
//
//       print('Toutes les tables ont été vidées avec succès.');
//       await supabase.from('Facture').delete().neq('id', 0);
//       print('Toutes les tables Facture ont été vidées avec succès.');
//       await supabase.from('User').delete().neq('id', 0);
//       print('Toutes les tables Facture ont été vidées avec succès.');
//       await supabase.from('Client').delete().neq('id', 0);
//       print('Toutes les tables Client ont été vidées avec succès.');
//       await supabase.from('DeletedProduct').delete().neq('id', 0);
//       print(
//           'Toutes les tables DeletedProductClient ont été vidées avec succès.');
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text(
//             'Toutes les tables ont été vidées avec succès.',
//             style: TextStyle(color: Colors.white),
//           ),
//           backgroundColor: Colors.blue,
//         ),
//       );
//     } catch (e) {
//       print('Erreur lors de la suppression des tables: $e');
//     }
//   }
//
//   Color getColorBasedOnPeremption(int peremption, double alert) {
//     if (peremption <= 0) {
//       return Colors.red;
//     } else if (peremption > 0 && peremption <= alert) {
//       return Colors.orange;
//     } else {
//       return Colors.green;
//     }
//   }
//
//   Color getColorBasedOnStock(double stock, double stockInit, double alert) {
//     if (stock <= 0) {
//       return Colors.grey;
//     } else if (stock > 0 && stock <= alert) {
//       return Colors.red;
//     } else if (stock <= alert && stock > stockInit * 0.30) {
//       return Colors.orange;
//     } else {
//       return Colors.green;
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final double largeur;
//     if (kIsWeb || Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
//       // Pour le web
//       largeur = 1 / 10;
//     } else if (Platform.isAndroid || Platform.isIOS) {
//       // Pour Android et iOS
//       largeur = 0.5;
//     } else {
//       // Pour les autres plateformes (Desktop)
//       largeur = 1 / 10;
//     }
//
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Liste des Produits'),
//         actions: [
//           Center(
//             child: Padding(
//               padding: const EdgeInsets.all(2.0),
//               child: Row(
//                 children: [
//                   if (_errorMessage != null)
//                     Padding(
//                         padding: const EdgeInsets.symmetric(horizontal: 16),
//                         child: Center(
//                           child: Text(
//                             'Erreur', // : $_errorMessage',
//                             style: TextStyle(color: Colors.red),
//                           ),
//                         )),
//                   if (_successMessage != null)
//                     Padding(
//                       padding: const EdgeInsets.symmetric(horizontal: 16),
//                       child: Center(
//                         child: Text(
//                           '$_successMessage',
//                           style: TextStyle(color: Colors.green),
//                         ),
//                       ),
//                     ),
//                   if (_isSyncing)
//                     Padding(
//                       padding: const EdgeInsets.all(8.0),
//                       child: CircularProgressIndicator(
//                         strokeWidth: 3.0,
//                       ),
//                     )
//                   else
//                     IconButton(
//                       icon: Icon(Icons.sync),
//                       onPressed: _syncData,
//                     ),
//                 ],
//               ),
//             ),
//           ),
//           Center(
//             child: Padding(
//               padding: const EdgeInsets.all(2.0),
//               child: Row(
//                 children: [
//                   if (_errorMessageF != null)
//                     Padding(
//                         padding: const EdgeInsets.symmetric(horizontal: 16),
//                         child: Center(
//                           child: Text(
//                             'Erreur', // : $_errorMessage',
//                             style: TextStyle(color: Colors.red),
//                           ),
//                         )),
//                   if (_successMessageF != null)
//                     Padding(
//                       padding: const EdgeInsets.symmetric(horizontal: 16),
//                       child: Center(
//                         child: Text(
//                           '$_successMessageF',
//                           style: TextStyle(color: Colors.green),
//                         ),
//                       ),
//                     ),
//                   if (_isSyncingF)
//                     Padding(
//                       padding: const EdgeInsets.all(8.0),
//                       child: CircularProgressIndicator(
//                         strokeWidth: 3.0,
//                       ),
//                     )
//                   else
//                     IconButton(
//                       icon: Icon(Icons.sync, color: Colors.red),
//                       onPressed: _syncDataFrom,
//                     ),
//                 ],
//               ),
//             ),
//           ),
//           IconButton(
//             icon: Icon(Icons.delete_forever, color: Colors.red),
//             onPressed: clearAllTables,
//           ),
//           kIsWeb ||
//                   Platform.isWindows ||
//                   Platform.isLinux ||
//                   Platform.isMacOS //|| Platform.isFushia
//               ? SizedBox(
//                   width: 50,
//                 )
//               : Container()
//         ],
//         bottom: TabBar(
//           controller: _tabController,
//           tabs: [
//             Tab(text: 'Produits'),
//             Tab(text: 'Fournisseurs'),
//             Tab(text: 'Users'),
//             Tab(text: 'Clients'),
//             Tab(text: 'Factures'),
//             Tab(text: 'DeletedProducts'),
//           ],
//         ),
//       ),
//       body: TabBarView(
//         controller: _tabController,
//         children: [
//           ListView.builder(
//             controller: _scrollControllerProduits,
//             itemCount: _produits.length + 1,
//             itemBuilder: (context, index) {
//               if (index < _produits.length) {
//                 final produit = _produits[index];
//
//                 final peremption =
//                     produit.datePeremption!.difference(DateTime.now()).inDays;
//                 Color colorPeremption =
//                     getColorBasedOnPeremption(peremption, 5.0);
//                 final double percentProgress = produit.stock != 0 &&
//                         produit.stockinit != 0 &&
//                         produit.stockinit >= produit.stock
//                     ? produit.stock / produit.stockinit
//                     : 0;
//                 Color colorStock = getColorBasedOnStock(
//                     produit.stock, produit.stockinit, produit.minimStock);
//                 return Card(
//                   child: Platform.isIOS || Platform.isAndroid
//                       ? Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                               ListTile(
//                                 leading: Tooltip(
//                                   message: 'ID : ${produit.id}',
//                                   child: GestureDetector(
//                                     child: produit.image == null ||
//                                             produit.image!.isEmpty
//                                         ? CircleAvatar(
//                                             child:
//                                                 Icon(Icons.image_not_supported),
//                                           )
//                                         : Column(
//                                             children: [
//                                               Expanded(
//                                                 child: CircleAvatar(
//                                                   backgroundImage:
//                                                       CachedNetworkImageProvider(
//                                                     produit.image!,
//                                                     errorListener: (error) =>
//                                                         Icon(Icons.error),
//                                                   ),
//                                                 ),
//                                               ),
//                                               Text('Id:' +
//                                                   produit.id.toString()),
//                                             ],
//                                           ),
//                                   ),
//                                 ),
//                                 title: Padding(
//                                   padding:
//                                       const EdgeInsets.symmetric(horizontal: 8),
//                                   child: Text(produit.nom),
//                                 ),
//                                 subtitle: Column(
//                                   crossAxisAlignment: CrossAxisAlignment.start,
//                                   children: [
//                                     Column(
//                                       children: [
//                                         Row(
//                                           children: [
//                                             Center(
//                                               child: Text(
//                                                 'A : ${produit.prixAchat.toStringAsFixed(2)} ',
//                                               ),
//                                             ),
//                                             SizedBox(
//                                               width: 10,
//                                             ),
//                                             Container(
//                                               padding: EdgeInsets.symmetric(
//                                                   horizontal: 5, vertical: 2),
//                                               decoration: BoxDecoration(
//                                                 gradient: LinearGradient(
//                                                   colors: [
//                                                     Colors.lightGreen,
//                                                     Colors.black45
//                                                   ], // Couleurs du dégradé
//                                                   begin: Alignment
//                                                       .topLeft, // Début du dégradé
//                                                   end: Alignment
//                                                       .bottomRight, // Fin du dégradé
//                                                 ), // Couleur de fond
//                                                 borderRadius:
//                                                     BorderRadius.circular(
//                                                         10), // Coins arrondis
//                                               ),
//                                               child: Center(
//                                                 child: Text(
//                                                   '${(produit.prixVente - produit.prixAchat).toStringAsFixed(2)}',
//                                                   style: TextStyle(
//                                                       color: Colors.white),
//                                                 ),
//                                               ),
//                                             ),
//                                           ],
//                                         ),
//                                         SizedBox(height: 5),
//                                         Container(
//                                           padding: EdgeInsets.symmetric(
//                                               horizontal: 5, vertical: 2),
//                                           decoration: BoxDecoration(
//                                             gradient: LinearGradient(
//                                               colors: [
//                                                 Colors.red,
//                                                 Colors.black45
//                                               ], // Couleurs du dégradé
//                                               begin: Alignment
//                                                   .topLeft, // Début du dégradé
//                                               end: Alignment
//                                                   .bottomRight, // Fin du dégradé
//                                             ), // Couleur de fond
//                                             borderRadius: BorderRadius.circular(
//                                                 10), // Coins arrondis
//                                           ),
//                                           child: Center(
//                                             child: Text(
//                                               'Reste : ${produit.datePeremption!.difference(DateTime.now()).inDays} Jours ',
//                                               style: TextStyle(
//                                                   color: Colors.white),
//                                             ),
//                                           ),
//                                         ),
//                                       ],
//                                     ),
//                                     SizedBox(
//                                       height: 5,
//                                     ),
//                                   ],
//                                 ),
//                                 trailing: Padding(
//                                   padding: const EdgeInsets.only(left: 15),
//                                   child: Text(
//                                     '${produit.prixVente.toStringAsFixed(2)}',
//                                     style: TextStyle(fontSize: 20),
//                                   ),
//                                 ),
//                               ),
//                               Row(
//                                 children: [
//                                   Padding(
//                                     padding: const EdgeInsets.symmetric(
//                                         horizontal: 8),
//                                     child:
//                                         Text('QR : ' + produit.qr.toString()),
//                                   ),
//                                   SizedBox(width: 2),
//                                   Container(
//                                     padding: EdgeInsets.symmetric(
//                                         horizontal: 5, vertical: 2),
//                                     decoration: BoxDecoration(
//                                       gradient: LinearGradient(
//                                         colors: [
//                                           Colors.blue,
//                                           Colors.black45
//                                         ], // Couleurs du dégradé
//                                         begin: Alignment
//                                             .topLeft, // Début du dégradé
//                                         end: Alignment
//                                             .bottomRight, // Fin du dégradé
//                                       ), // Couleur de fond
//                                       borderRadius: BorderRadius.circular(
//                                           10), // Coins arrondis
//                                     ),
//                                     child: Center(
//                                       child: Text(
//                                         '${produit.minimStock.toStringAsFixed(produit.minimStock.truncateToDouble() == produit.minimStock ? 0 : 2)}',
//                                         // '${(produit.minimStock).toStringAsFixed(2)}',
//                                         style: TextStyle(color: Colors.white),
//                                       ),
//                                     ),
//                                   ),
//                                   SizedBox(width: 2),
//                                   Expanded(
//                                     child: Padding(
//                                       padding:
//                                           EdgeInsets.symmetric(horizontal: 15),
//                                       child: new LinearPercentIndicator(
//                                         animation: true,
//                                         animationDuration: 1000,
//                                         lineHeight: 20.0,
//                                         leading: new Text(produit.stockinit
//                                             .toStringAsFixed(1)),
//                                         trailing: new Text(
//                                             produit.stock.toStringAsFixed(1)),
//                                         percent: percentProgress,
//                                         center: new Text(
//                                             '${(percentProgress * 100).toStringAsFixed(1)}%'),
//                                         linearStrokeCap:
//                                             LinearStrokeCap.roundAll,
//                                         backgroundColor: Colors.grey.shade300,
//                                         progressColor: colorStock,
//                                       ),
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                               SizedBox(height: 15),
//                             ])
//                       : GestureDetector(
//                           onTap: () {
//                             Navigator.of(context).push(MaterialPageRoute(
//                               builder: (ctx) =>
//                                   ProduitDetailPage(produit: produit),
//                             ));
//                           },
//                           child: Container(
//                             width: MediaQuery.of(context).size.width,
//                             child: Row(
//                               mainAxisAlignment: MainAxisAlignment.start,
//                               children: [
//                                 Padding(
//                                   padding: const EdgeInsets.symmetric(
//                                       horizontal: 15, vertical: 8),
//                                   child: Tooltip(
//                                     message: 'ID : ${produit.id}',
//                                     child: produit.image == null ||
//                                             produit.image!.isEmpty
//                                         ? CircleAvatar(
//                                             child:
//                                                 Icon(Icons.image_not_supported),
//                                           )
//                                         : Column(
//                                             mainAxisAlignment:
//                                                 MainAxisAlignment.center,
//                                             crossAxisAlignment:
//                                                 CrossAxisAlignment.center,
//                                             children: [
//                                               CircleAvatar(
//                                                 backgroundImage:
//                                                     CachedNetworkImageProvider(
//                                                   produit.image!,
//                                                   errorListener: (error) =>
//                                                       Icon(Icons.error),
//                                                 ),
//                                               ),
//                                               Padding(
//                                                 padding: const EdgeInsets.only(
//                                                     top: 8),
//                                                 child: Text('Id:' +
//                                                     produit.id.toString()),
//                                               ),
//                                             ],
//                                           ),
//                                   ),
//                                 ),
//                                 Expanded(
//                                   child: Column(
//                                     crossAxisAlignment:
//                                         CrossAxisAlignment.start,
//                                     children: [
//                                       Text(produit.nom),
//                                       Row(
//                                         mainAxisAlignment:
//                                             MainAxisAlignment.spaceBetween,
//                                         children: [
//                                           Row(
//                                             children: [
//                                               Center(
//                                                 child: Text(
//                                                   'A: ${produit.prixAchat.toStringAsFixed(2)} ',
//                                                 ),
//                                               ),
//                                               SizedBox(
//                                                 width: 10,
//                                               ),
//                                               Container(
//                                                 padding: EdgeInsets.symmetric(
//                                                     horizontal: 5, vertical: 2),
//                                                 decoration: BoxDecoration(
//                                                   gradient: LinearGradient(
//                                                     colors: [
//                                                       Colors.lightGreen,
//                                                       Colors.black45
//                                                     ], // Couleurs du dégradé
//                                                     begin: Alignment
//                                                         .topLeft, // Début du dégradé
//                                                     end: Alignment
//                                                         .bottomRight, // Fin du dégradé
//                                                   ), // Couleur de fond
//                                                   borderRadius:
//                                                       BorderRadius.circular(
//                                                           10), // Coins arrondis
//                                                 ),
//                                                 child: Center(
//                                                   child: Text(
//                                                     '${(produit.prixVente - produit.prixAchat).toStringAsFixed(2)}',
//                                                     style: TextStyle(
//                                                         color: Colors.white),
//                                                   ),
//                                                 ),
//                                               ),
//                                               SizedBox(
//                                                 width: 10,
//                                               ),
//                                               Container(
//                                                 padding: EdgeInsets.symmetric(
//                                                     horizontal: 5, vertical: 2),
//                                                 decoration: BoxDecoration(
//                                                   gradient: LinearGradient(
//                                                     colors: [
//                                                       Colors.black45,
//                                                       colorPeremption,
//                                                     ], // Couleurs du dégradé
//                                                     begin: Alignment
//                                                         .topLeft, // Début du dégradé
//                                                     end: Alignment
//                                                         .bottomRight, // Fin du dégradé
//                                                   ), // Couleur de fond
//                                                   borderRadius:
//                                                       BorderRadius.circular(
//                                                           10), // Coins arrondis
//                                                 ),
//                                                 child: Center(
//                                                   child: Text(
//                                                     'Péremption : ${produit.datePeremption!.day}/${produit.datePeremption!.month}/${produit.datePeremption!.year}  Reste : ${peremption} Jours ',
//                                                     style: TextStyle(
//                                                         color: Colors.white),
//                                                   ),
//                                                 ),
//                                               ),
//                                             ],
//                                           ),
//                                           SizedBox(height: 5),
//                                           Center(
//                                             child: Padding(
//                                               padding:
//                                                   const EdgeInsets.symmetric(
//                                                       horizontal: 15),
//                                               child: Text('QR : ' +
//                                                   produit.qr.toString()),
//                                             ),
//                                           )
//                                         ],
//                                       ),
//                                       SizedBox(height: 5),
//                                       Row(
//                                         children: [
//                                           Container(
//                                             padding: EdgeInsets.symmetric(
//                                                 horizontal: 5, vertical: 2),
//                                             decoration: BoxDecoration(
//                                               gradient: LinearGradient(
//                                                 colors: [
//                                                   Colors.blue,
//                                                   Colors.black45
//                                                 ], // Couleurs du dégradé
//                                                 begin: Alignment
//                                                     .topLeft, // Début du dégradé
//                                                 end: Alignment
//                                                     .bottomRight, // Fin du dégradé
//                                               ), // Couleur de fond
//                                               borderRadius:
//                                                   BorderRadius.circular(
//                                                       10), // Coins arrondis
//                                             ),
//                                             child: Center(
//                                               child: Text(
//                                                 '${produit.minimStock.toStringAsFixed(produit.minimStock.truncateToDouble() == produit.minimStock ? 0 : 2)}',
//                                                 style: TextStyle(
//                                                     color: Colors.white),
//                                               ),
//                                             ),
//                                           ),
//                                           SizedBox(width: 5),
//                                           Expanded(
//                                             child: new LinearPercentIndicator(
//                                               animation: true,
//                                               animationDuration: 1000,
//                                               lineHeight: 20.0,
//                                               leading: new Text(produit
//                                                   .stockinit
//                                                   .toStringAsFixed(2)),
//                                               trailing: new Text(produit.stock
//                                                   .toStringAsFixed(2)),
//                                               percent: percentProgress < 0
//                                                   ? 0
//                                                   : percentProgress,
//                                               center: new Text(
//                                                   '${(percentProgress * 100).toStringAsFixed(1)}%'),
//                                               linearStrokeCap:
//                                                   LinearStrokeCap.roundAll,
//                                               backgroundColor:
//                                                   Colors.grey.shade300,
//                                               progressColor: colorStock,
//                                             ),
//                                           ),
//                                         ],
//                                       ),
//                                       SizedBox(height: 5),
//                                     ],
//                                   ),
//                                 ),
//                                 Padding(
//                                   padding: const EdgeInsets.symmetric(
//                                       vertical: 8, horizontal: 25),
//                                   child: Text(
//                                     '${produit.prixVente.toStringAsFixed(2)}',
//                                     style: TextStyle(fontSize: 20),
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ),
//                 );
//               } else if (_hasMore) {
//                 return Center(
//                   child: LinearProgressIndicator(),
//                 );
//               } else {
//                 return Container(
//                   padding: EdgeInsets.all(16),
//                   alignment: Alignment.center,
//                   child: Text('Fin de la liste'),
//                 );
//               }
//             },
//           ),
//           ListView.builder(
//             controller: _scrollControllerFournisseurs,
//             itemCount: _fournisseurs.length + 1,
//             itemBuilder: (context, index) {
//               if (index < _fournisseurs.length) {
//                 final fournisseur = _fournisseurs[index];
//                 return Card(
//                   child: ListTile(
//                     onTap: () {
//                       Navigator.of(context).push(
//                         MaterialPageRoute(
//                           builder: (context) => ProduitsFournisseurPage(
//                             fournisseur: fournisseur,
//                           ),
//                         ),
//                       );
//                     },
//                     leading: CircleAvatar(
//                       child: FittedBox(
//                           child: Padding(
//                         padding: const EdgeInsets.all(8.0),
//                         child: Text(fournisseur.id.toString()),
//                       )),
//                     ),
//                     title: Text(fournisseur.nom),
//                     subtitle: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text('Phone : ${fournisseur.phone}'),
//                         Text(
//                           'Créer le ${fournisseur.dateCreation.day}-${fournisseur.dateCreation.month}-${fournisseur.dateCreation.year}  Modifié ${timeago.format(fournisseur.derniereModification!, locale: 'fr')}',
//                           style: TextStyle(
//                               fontSize: 13, fontWeight: FontWeight.w300),
//                         ),
//                       ],
//                     ),
//                     trailing: Container(
//                       width: 50,
//                       child: Row(
//                         mainAxisAlignment: MainAxisAlignment.start,
//                         children: [
//                           Expanded(
//                             child: Text(
//                               fournisseur.produits.length.toString(),
//                               style: TextStyle(fontSize: 20),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                 );
//               } else if (_hasMore) {
//                 return Center(
//                   child: LinearProgressIndicator(),
//                 );
//               } else {
//                 return Container(
//                   padding: EdgeInsets.all(16),
//                   alignment: Alignment.center,
//                   child: Text('Fin de la liste'),
//                 );
//               }
//             },
//           ),
//           ListView.builder(
//             itemCount: _users.length,
//             itemBuilder: (context, index) {
//               if (index < _users.length) {
//                 final user = _users[index];
//                 return ListTile(
//                   title: Text(user.username),
//                   subtitle: Text(user.email),
//                   // Add more widgets here to display other user data
//                 );
//               } else if (_hasMore) {
//                 return Center(
//                   child: LinearProgressIndicator(),
//                 );
//               } else {
//                 return Container(
//                   padding: EdgeInsets.all(16),
//                   alignment: Alignment.center,
//                   child: Text('Fin de la liste'),
//                 );
//               }
//             },
//           ),
//           ListView.builder(
//             controller: _scrollControllerClients,
//             itemCount: _clients.length + 1,
//             itemBuilder: (context, index) {
//               if (index < _clients.length) {
//                 final client = _clients[index];
//                 return Card(
//                   child: ListTile(
//                     onTap: () {
//                       // Navigator.of(context).push(
//                       //   MaterialPageRoute(
//                       //     builder: (context) => ProduitsFournisseurPage(
//                       //       fournisseur: fournisseur,
//                       //     ),
//                       //   ),
//                       // );
//                     },
//                     leading: CircleAvatar(
//                       child: FittedBox(
//                           child: Padding(
//                         padding: const EdgeInsets.all(8.0),
//                         child: Text(client.id.toString()),
//                       )),
//                     ),
//                     title: Text(client.nom),
//                     subtitle: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text('Phone : ${client.phone}'),
//                         Text(
//                           'Créer le ${client.dateCreation!.day}-${client.dateCreation!.month}-${client.dateCreation!.year}  Modifié ${timeago.format(client.derniereModification!, locale: 'fr')}',
//                           style: TextStyle(
//                               fontSize: 13, fontWeight: FontWeight.w300),
//                         ),
//                       ],
//                     ),
//                     trailing: Container(
//                       width: 50,
//                       child: Row(
//                         mainAxisAlignment: MainAxisAlignment.start,
//                         children: [
//                           Expanded(
//                             child: Text(
//                               client.factures.length.toString(),
//                               style: TextStyle(fontSize: 20),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                 );
//               } else if (_hasMore) {
//                 return Center(
//                   child: LinearProgressIndicator(),
//                 );
//               } else {
//                 return Container(
//                   padding: EdgeInsets.all(16),
//                   alignment: Alignment.center,
//                   child: Text('Fin de la liste'),
//                 );
//               }
//             },
//           ),
//           ListView.builder(
//             controller: _scrollControllerFactures,
//             itemCount: _factures.length + 1,
//             itemBuilder: (context, index) {
//               if (index < _factures.length) {
//                 final facture = _factures[index];
//                 return Card(
//                   child: ListTile(
//                     onTap: () {
//                       // Navigator.of(context).push(
//                       //   MaterialPageRoute(
//                       //     builder: (context) => ProduitsFournisseurPage(
//                       //       fournisseur: fournisseur,
//                       //     ),
//                       //   ),
//                       // );
//                     },
//                     leading: CircleAvatar(
//                       child: FittedBox(
//                           child: Padding(
//                         padding: const EdgeInsets.all(8.0),
//                         child: Text(facture.id.toString()),
//                       )),
//                     ),
//                     title: Text('${facture.client.target?.nom ?? 'Unknown'}'),
//                     subtitle: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text('Phone : ${facture.lignesFacture.length}'),
//                         Text(
//                           'Créer le ${facture.date.day}-${facture.date.month}-${facture.date.year}  Modifié ${timeago.format(facture.date, locale: 'fr')}',
//                           style: TextStyle(
//                               fontSize: 13, fontWeight: FontWeight.w300),
//                         ),
//                       ],
//                     ),
//                   ),
//                 );
//               } else if (_hasMore) {
//                 return Center(
//                   child: LinearProgressIndicator(),
//                 );
//               } else {
//                 return Container(
//                   padding: EdgeInsets.all(16),
//                   alignment: Alignment.center,
//                   child: Text('Fin de la liste'),
//                 );
//               }
//             },
//           ),
//           ListView.builder(
//             controller: _scrollControllerDeletedProducts,
//             itemCount: _deletedProducts.length + 1,
//             itemBuilder: (context, index) {
//               if (index < _deletedProducts.length) {
//                 final deletedProduct = _deletedProducts[index];
//                 return Card(
//                   child: ListTile(
//                     onTap: () {
//                       // Navigator.of(context).push(
//                       //   MaterialPageRoute(
//                       //     builder: (context) => ProduitsFournisseurPage(
//                       //       fournisseur: fournisseur,
//                       //     ),
//                       //   ),
//                       // );
//                     },
//                     leading: CircleAvatar(
//                       child: FittedBox(
//                           child: Padding(
//                         padding: const EdgeInsets.all(8.0),
//                         child: Text(deletedProduct.id.toString()),
//                       )),
//                     ),
//                     title: Text(deletedProduct.name),
//                     subtitle: Text('Prix : ${deletedProduct.price}'),
//                   ),
//                 );
//               } else if (_hasMore) {
//                 return Center(
//                   child: LinearProgressIndicator(),
//                 );
//               } else {
//                 return Container(
//                   padding: EdgeInsets.all(16),
//                   alignment: Alignment.center,
//                   child: Text('Fin de la liste'),
//                 );
//               }
//             },
//           ),
//         ],
//       ),
//     );
//   }
// }
