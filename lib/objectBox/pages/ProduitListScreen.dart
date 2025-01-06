import 'dart:isolate';
import 'package:syncfusion_flutter_barcodes/barcodes.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dart_date/dart_date.dart';
import 'package:faker/faker.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';
import 'package:provider/provider.dart';
import 'package:string_extensions/string_extensions.dart';

import '../../objectbox.g.dart';
import '../Entity.dart';
import '../MyProviders.dart';
import '../Utils/country_flags.dart';
import '../Utils/winMobile.dart';
import '../classeObjectBox.dart';
import '../tests/doublons.dart';
import 'Edit_Produit.dart';
import 'FournisseurListScreen.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:percent_indicator/percent_indicator.dart';
import 'addProduct.dart';

import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'editProduct.dart';

class ProduitListScreen extends StatefulWidget {
  @override
  _ProduitListScreenState createState() => _ProduitListScreenState();
}

class _ProduitListScreenState extends State<ProduitListScreen> {
  final ScrollController _scrollController = ScrollController();
  NativeAd? _nativeAd;
  bool _nativeAdIsLoaded = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Create the ad objects and load ads.
    _nativeAd = NativeAd(
      adUnitId: 'ca-app-pub-2282149611905342/2166057043',
      request: AdRequest(),
      listener: NativeAdListener(
        onAdLoaded: (Ad ad) {
          print('$NativeAd loaded.');
          setState(() {
            _nativeAdIsLoaded = true;
          });
        },
        onAdFailedToLoad: (Ad ad, LoadAdError error) {
          print('$NativeAd failedToLoad: $error');
          ad.dispose();
        },
        onAdOpened: (Ad ad) => print('$NativeAd onAdOpened.'),
        onAdClosed: (Ad ad) => print('$NativeAd onAdClosed.'),
      ),
      nativeTemplateStyle: NativeTemplateStyle(
        templateType: TemplateType.medium,
        mainBackgroundColor: Colors.white12,
        callToActionTextStyle: NativeTemplateTextStyle(
          size: 16.0,
        ),
        primaryTextStyle: NativeTemplateTextStyle(
          textColor: Colors.black38,
          backgroundColor: Colors.white70,
        ),
      ),
    )..load();
  }

  @override
  void dispose() {
    super.dispose();
    _nativeAd?.dispose();
    _scrollController.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      // Charger plus de produits lorsque l'utilisateur atteint la fin de la liste
      Provider.of<CommerceProvider>(context, listen: false).chargerProduits();
    }
  }

  Future<void> createUsersAndUpdateRelationsIsolate(ObjectBox objectbox) async {
    final result = await Isolate.run(() {
      return _createUsersAndUpdateRelations(objectbox);
    });

    print(result);
  }

  String _createUsersAndUpdateRelations(ObjectBox objectbox) {
    final faker = Faker();
    StringBuffer log = StringBuffer();
    log.writeln(
        'Début de la création des utilisateurs et de la mise à jour des relations...');

    // Création des utilisateurs
    List<User> newUsers = [];
    for (int i = 0; i < 5; i++) {
      User newUser = User(
        id: 0,
        username: faker.person.firstName() +
            faker.randomGenerator.numberOfLength(3).toString(),
        password: faker.internet.password(),
        email: faker.internet.email(),
        role: 'default_role',
        phone: faker.phoneNumber.toString(),
        photo: faker.image.image(),
        derniereModification: DateTime.now(),
      );
      int userId = objectbox.userBox.put(newUser);
      newUser.id = userId;
      newUsers.add(newUser);
      log.writeln(
          'Utilisateur créé : ID=${newUser.id}, Username=${newUser.username}, Email=${newUser.email}');
    }
    log.writeln('5 utilisateurs ont été créés avec succès.');

    // Récupération des produits existants
    final produits = objectbox.produitBox.getAll();
    log.writeln('Nombre de produits existants : ${produits.length}');

    // Mise à jour des produits et approvisionnements avec leurs relations
    log.writeln(
        'Début de la mise à jour des produits et approvisionnements...');
    for (int i = 0; i < produits.length; i++) {
      Produit produit = produits[i];
      log.writeln(
          '\nTraitement du produit : ID=${produit.id}, Nom=${produit.nom}');

      // Choisir aléatoirement un utilisateur pour chaque rôle dans Crud
      User createdByUser =
          newUsers[faker.randomGenerator.integer(newUsers.length)];
      User updatedByUser =
          newUsers[faker.randomGenerator.integer(newUsers.length)];
      User? deletedByUser = faker.randomGenerator.boolean()
          ? newUsers[faker.randomGenerator.integer(newUsers.length)]
          : null;

      // Créer ou mettre à jour l'objet Crud
      Crud crud;
      if (produit.crud.target != null) {
        crud = produit.crud.target!;
        log.writeln('Mise à jour du Crud existant : ID=${crud.id}');
      } else {
        crud = Crud(
          createdBy: createdByUser.id,
          updatedBy: updatedByUser.id,
          deletedBy: deletedByUser?.id,
          dateCreation: DateTime.now(),
          derniereModification: DateTime.now(),
          dateDeleting: deletedByUser != null ? DateTime.now() : null,
        );
        log.writeln('Création d\'un nouveau Crud pour le produit');
      }

      // Mise à jour des valeurs du CRUD
      crud.createdBy = createdByUser.id;
      crud.updatedBy = updatedByUser.id;
      crud.deletedBy = deletedByUser?.id;
      crud.derniereModification = DateTime.now();

      log.writeln(
          'Crud mis à jour : createdBy=${crud.createdBy}, updatedBy=${crud.updatedBy}, deletedBy=${crud.deletedBy}');

      // Associer le CRUD au produit
      produit.crud.target = crud;
      objectbox.produitBox.put(produit);
      log.writeln('Produit mis à jour avec le nouveau Crud');

      // Créer ou mettre à jour l'approvisionnement
      Approvisionnement approvisionnement = Approvisionnement(
        quantite: faker.randomGenerator.integer(100).toDouble(),
        prixAchat: faker.randomGenerator.decimal(min: 5),
        datePeremption: DateTime.now()
            .add(Duration(days: faker.randomGenerator.integer(365))),
        derniereModification: DateTime.now(),
      );
      approvisionnement.produit.target = produit;
      approvisionnement.crud.target = crud;
      int approvId = objectbox.approvisionnementBox.put(approvisionnement);
      log.writeln(
          'Approvisionnement créé/mis à jour : ID=${approvId}, Quantité=${approvisionnement.quantite}, Prix d\'achat=${approvisionnement.prixAchat}');
    }

    log.writeln(
        '\nLa mise à jour des produits et approvisionnements est terminée.');
    log.writeln('Nombre total de produits traités : ${produits.length}');
    log.writeln(
        'Fin de l\'opération de création des utilisateurs et de mise à jour des relations.');

    return log.toString();
  }

  void deleteAllUsers(ObjectBox objectbox) {
    // Supprimer tous les utilisateurs de la boîte User
    objectbox.userBox.removeAll();

    print('Tous les utilisateurs ont été supprimés.');
  }

  @override
  Widget build(BuildContext context) {
    final objectBox = Provider.of<ObjectBox>(context, listen: false);
    void supprimerProduitsInvalides() {
      objectBox.supprimerProduitsAvecQrCodeInvalide();
      print(
          'Tous les produits invalides et leurs entités associées ont été supprimés.');
    }

    return Scaffold(
      appBar: AppBar(
        title: Consumer<CommerceProvider>(
            builder: (context, produitProvider, child) {
          int totalProduits = produitProvider.getTotalProduits();

          return Text(
            '${totalProduits} Produits',
          );
        }),
        actions: [
          // IconButton(
          //   icon: Icon(Icons.dashboard),
          //   onPressed: () async {
          //     supprimerProduitsInvalides();
          //     // deleteAllUsers(objectBox);
          //   },
          // ),
          // IconButton(
          //   icon: Icon(Icons.sync),
          //   onPressed: () async {
          //     _createUsersAndUpdateRelations(objectBox);
          //     // deleteAllUsers(objectBox);
          //   },
          // ),
          // IconButton(
          //   icon: Icon(Icons.delete, color: Colors.red),
          //   onPressed: () async {
          //     deleteAllUsers(objectBox);
          //   },
          // ),

          WinMobile(),
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () async {
              final produitProvider =
                  Provider.of<CommerceProvider>(context, listen: false);

              showSearch(
                context: context,
                delegate: ProduitSearchDelegateMain(produitProvider),
              );
            },
          ),

          // IconButton(
          //   icon: Icon(Icons.close_fullscreen_rounded, color: Colors.blueGrey),
          //   onPressed: () async {
          //     objectBox.cleanQrCodes();
          //   },
          // ),
          // TextButton(
          //   onPressed: () {
          //     Navigator.of(context).push(MaterialPageRoute(
          //         builder: (ctx) => DuplicateProductsListView()));
          //   },
          //   child: Text('Boublons Liste'),
          // ),
          SizedBox(
            width: 50,
          ),
        ],
      ),
      // body: Consumer<CommerceProvider>(
      //   builder: (context, produitProvider, child) {
      //     return ListView.builder(
      //       controller: _scrollController,
      //       itemCount: produitProvider.produits.length + 1,
      //       itemBuilder: (context, index) {
      //         if (index < produitProvider.produits.length) {
      //           final produit = produitProvider.produits[index];
      //           // final peremption =
      //           //     produit.datePeremption!.difference(DateTime.now()).inDays;
      //           // Color colorPeremption =
      //           //     getColorBasedOnPeremption(peremption, 5.0);
      //           // final double percentProgress = produit.stock != 0 &&
      //           //         produit.stockinit != 0 &&
      //           //         produit.stockinit >= produit.stock
      //           //     ? produit.stock / produit.stockinit
      //           //     : 0;
      //           // Color colorStock = getColorBasedOnStock(
      //           //     produit.stock, produit.stockinit, produit.minimStock);
      //           return
      //               // Slidable(
      //               // key: ValueKey(produit.id),
      //               // startActionPane: ActionPane(
      //               //   extentRatio: largeur,
      //               //   motion: ScrollMotion(),
      //               //   children: [
      //               //     SlidableAction(
      //               //       onPressed: (BuildContext context) {
      //               //         Navigator.of(context).push(MaterialPageRoute(
      //               //           builder: (ctx) => Edit_Produit(produit: produit),
      //               //         ));
      //               //       },
      //               //       backgroundColor: Colors.blue,
      //               //       icon: Icons.edit,
      //               //       label: 'Editer',
      //               //     ),
      //               //   ],
      //               // ),
      //               // child:
      //               InkWell(
      //                   onTap: () {
      //                     // Navigator.of(context).push(MaterialPageRoute(
      //                     //   builder: (ctx) => Edit_Produit(produit: produit),
      //                     // ));
      //                   },
      //                   child: Card(
      //                       child: Column(
      //                           crossAxisAlignment: CrossAxisAlignment.start,
      //                           children: [
      //                         ListTile(
      //                           onTap: () {
      //                             Navigator.of(context).push(MaterialPageRoute(
      //                               builder: (ctx) =>
      //                                   ProduitDetailPage(produit: produit),
      //                             ));
      //                           },
      //                           onLongPress: () {
      //                             _deleteProduit(context, produit);
      //                           },
      //                           leading: Tooltip(
      //                             message: 'ID : ${produit.id}',
      //                             child: GestureDetector(
      //                               onDoubleTap: () {
      //                                 _showAllFournisseursDialog(
      //                                   context,
      //                                   produit, /*fournisseurs*/
      //                                 );
      //                               },
      //                               child: produit.image == null ||
      //                                       produit.image!.isEmpty
      //                                   ? CircleAvatar(
      //                                       child:
      //                                           Icon(Icons.image_not_supported),
      //                                     )
      //                                   : Column(
      //                                       children: [
      //                                         Expanded(
      //                                           child: CircleAvatar(
      //                                             backgroundImage:
      //                                                 CachedNetworkImageProvider(
      //                                               produit.image!,
      //                                               errorListener: (error) =>
      //                                                   Icon(Icons.error),
      //                                             ),
      //                                           ),
      //                                         ),
      //                                         Text('Id:' +
      //                                             produit.id.toString()),
      //                                       ],
      //                                     ),
      //                             ),
      //                           ),
      //                           title: Padding(
      //                             padding:
      //                                 const EdgeInsets.symmetric(horizontal: 8),
      //                             child: Text(produit.nom),
      //                           ),
      //                           subtitle: Column(
      //                             crossAxisAlignment: CrossAxisAlignment.start,
      //                             children: [
      //                               Column(
      //                                 children: [
      //                                   Row(
      //                                     children: [
      //                                       // Center(
      //                                       //   child: Text(
      //                                       //     'A : ${produit.prixAchat.toStringAsFixed(produit.prixAchat.truncateToDouble() == produit.prixAchat ? 0 : 2)}',
      //                                       //   ),
      //                                       // ),
      //                                       SizedBox(
      //                                         width: 10,
      //                                       ),
      //                                       // Container(
      //                                       //   padding:
      //                                       //       EdgeInsets.symmetric(
      //                                       //           horizontal: 5,
      //                                       //           vertical: 2),
      //                                       //   decoration: BoxDecoration(
      //                                       //     gradient:
      //                                       //         LinearGradient(
      //                                       //       colors: [
      //                                       //         Colors.lightGreen,
      //                                       //         Colors.black45
      //                                       //       ], // Couleurs du dégradé
      //                                       //       begin: Alignment
      //                                       //           .topLeft, // Début du dégradé
      //                                       //       end: Alignment
      //                                       //           .bottomRight, // Fin du dégradé
      //                                       //     ), // Couleur de fond
      //                                       //     borderRadius:
      //                                       //         BorderRadius.circular(
      //                                       //             10), // Coins arrondis
      //                                       //   ),
      //                                       //   child: Center(
      //                                       //     child: Text(
      //                                       //       '${(produit.prixVente - produit.prixAchat).toStringAsFixed((produit.prixVente - produit.prixAchat).truncateToDouble() == (produit.prixVente - produit.prixAchat) ? 0 : 2)}',
      //                                       //       style: TextStyle(
      //                                       //           color:
      //                                       //               Colors.white),
      //                                       //     ),
      //                                       //   ),
      //                                       // ),
      //                                     ],
      //                                   ),
      //                                   SizedBox(height: 5),
      //                                   // Container(
      //                                   //   padding: EdgeInsets.symmetric(
      //                                   //       horizontal: 5,
      //                                   //       vertical: 2),
      //                                   //   decoration: BoxDecoration(
      //                                   //     gradient: LinearGradient(
      //                                   //       colors: [
      //                                   //         Colors.red,
      //                                   //         Colors.black45
      //                                   //       ], // Couleurs du dégradé
      //                                   //       begin: Alignment
      //                                   //           .topLeft, // Début du dégradé
      //                                   //       end: Alignment
      //                                   //           .bottomRight, // Fin du dégradé
      //                                   //     ), // Couleur de fond
      //                                   //     borderRadius:
      //                                   //         BorderRadius.circular(
      //                                   //             10), // Coins arrondis
      //                                   //   ),
      //                                   //   child: Center(
      //                                   //     child: Text(
      //                                   //       'Reste : ${produit.approvisionnements.map(f).datePeremption!.difference(DateTime.now()).inDays} Jours ',
      //                                   //       style: TextStyle(
      //                                   //           color: Colors.white),
      //                                   //     ),
      //                                   //   ),
      //                                   // ),
      //                                   SizedBox(height: 10),
      //                                   Text('Approvisionnements:',
      //                                       style: TextStyle(
      //                                           fontWeight: FontWeight.bold)),
      //                                   ...produit.approvisionnements
      //                                       .map((appro) {
      //                                     return Padding(
      //                                       padding: EdgeInsets.symmetric(
      //                                           vertical: 4.0),
      //                                       child: Text(
      //                                           '  - Date: ${appro.crud.target!.dateCreation}\n      Quantité: ${appro.quantite}\n      Prix d\'achat: ${appro.prixAchat}\n      Date de péremption: ${appro.datePeremption}'),
      //                                     );
      //                                   }).toList(),
      //                                 ],
      //                               ),
      //                               SizedBox(
      //                                 height: 5,
      //                               ),
      //                             ],
      //                           ),
      //                           trailing: Padding(
      //                             padding: const EdgeInsets.only(left: 15),
      //                             child: Text(
      //                               '${produit.prixVente.toStringAsFixed(2)}',
      //                               style: TextStyle(fontSize: 20),
      //                             ),
      //                           ),
      //                         ),
      //                         Row(
      //                           children: [
      //                             Padding(
      //                               padding: const EdgeInsets.symmetric(
      //                                   horizontal: 8),
      //                               child:
      //                                   Text('QR : ' + produit.qr.toString()),
      //                             ),
      //                             SizedBox(width: 2),
      //                             Container(
      //                               padding: EdgeInsets.symmetric(
      //                                   horizontal: 5, vertical: 2),
      //                               decoration: BoxDecoration(
      //                                 gradient: LinearGradient(
      //                                   colors: [
      //                                     Colors.blue,
      //                                     Colors.black45
      //                                   ], // Couleurs du dégradé
      //                                   begin: Alignment
      //                                       .topLeft, // Début du dégradé
      //                                   end: Alignment
      //                                       .bottomRight, // Fin du dégradé
      //                                 ), // Couleur de fond
      //                                 borderRadius: BorderRadius.circular(
      //                                     10), // Coins arrondis
      //                               ),
      //                               child: Center(
      //                                 child: Text(
      //                                   '${produit.minimStock.toStringAsFixed(produit.minimStock.truncateToDouble() == produit.minimStock ? 0 : 2)}',
      //                                   // '${(produit.minimStock).toStringAsFixed(2)}',
      //                                   style: TextStyle(color: Colors.white),
      //                                 ),
      //                               ),
      //                             ),
      //                             SizedBox(width: 2),
      //                             Expanded(
      //                               child: Padding(
      //                                 padding:
      //                                     EdgeInsets.symmetric(horizontal: 15),
      //                                 child: new LinearPercentIndicator(
      //                                   animation: true,
      //                                   animationDuration: 1000,
      //                                   lineHeight: 20.0,
      //                                   // leading: new Text(
      //                                   //   '${produit.stockinit.toStringAsFixed(produit.stockinit.truncateToDouble() == produit.stockinit ? 0 : 2)}',
      //                                   // ),
      //                                   trailing: new Text(
      //                                     '${produit.stock.toStringAsFixed(produit.stock.truncateToDouble() == produit.stock ? 0 : 2)}',
      //                                   ),
      //                                   // percent: percentProgress,
      //                                   // center: new Text(
      //                                   //     '${(percentProgress * 100).toStringAsFixed(1)}%'),
      //                                   linearStrokeCap:
      //                                       LinearStrokeCap.roundAll,
      //                                   backgroundColor: Colors.grey.shade300,
      //                                   // progressColor: colorStock,
      //                                 ),
      //                               ),
      //                             ),
      //                           ],
      //                         ),
      //                         SizedBox(height: 15),
      //                         if (produit.approvisionnements.isNotEmpty)
      //                           Column(
      //                             children:
      //                                 produit.approvisionnements.map((appro) {
      //                               return ListTile(
      //                                 title: Text(
      //                                     'Fournisseur : ${appro.fournisseur.target?.nom ?? "Inconnu"}'),
      //                                 subtitle: Column(
      //                                   crossAxisAlignment:
      //                                       CrossAxisAlignment.start,
      //                                   children: [
      //                                     Text('Quantité : ${appro.quantite}'),
      //                                     Text(
      //                                         'Prix unitaire : ${appro.prixAchat} DA'),
      //                                     Text(
      //                                         'Date de péremption : ${appro.datePeremption != null ? appro.datePeremption!.toLocal().toString() : "N/A"}'),
      //                                   ],
      //                                 ),
      //                               );
      //                             }).toList(),
      //                           )
      //                         else
      //                           Text('Aucun approvisionnement disponible'),
      //                       ])));
      //         } else if (produitProvider.hasMoreProduits) {
      //           return Center(child: CircularProgressIndicator());
      //         } else {
      //           return SizedBox.shrink();
      //         }
      //       },
      //     );
      //   },
      // ),
      body: Consumer<CommerceProvider>(
        builder: (context, produitProvider, child) {
          return ListView.builder(
            controller: _scrollController,
            itemCount: produitProvider.produits.length + 1,
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
                    ));
              }
              if (index < produitProvider.produits.length) {
                final produit = produitProvider.produits[index];

                // Calculer le total des quantités des approvisionnements
                final totalQuantite = produit.approvisionnements
                    .fold<double>(
                        0,
                        (previousValue, appro) =>
                            previousValue + appro.quantite)
                    .toStringAsFixed(2);
                // Exemple d'attribut produit.qr
                String? qrCodesString = produit.qr; // Exemple : "QR1,QR2,QR3"

                // Vérifiez que produit.qr n'est pas vide ou null
                List<String> qrCodes =
                    qrCodesString != null && qrCodesString.isNotEmpty
                        ? qrCodesString
                            .split(',') // Sépare les QR codes par la virgule
                        : []; // Si null ou vide, on crée une liste vide

                return Card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListTile(
                        onTap: () async {
                          await Navigator.of(context).push(MaterialPageRoute(
                              builder: (ctx) => ProduitDetailPage(
                                    produit: produit,
                                  )));
                        },
                        onLongPress: () {
                          _deleteProduit(context, produit);
                        },
                        leading: Tooltip(
                          message: 'ID : ${produit.id}',
                          child: GestureDetector(
                            onDoubleTap: () {
                              _showAllFournisseursDialog(
                                context,
                                produit, /*fournisseurs*/
                              );
                            },
                            child:
                                produit.image == null || produit.image!.isEmpty
                                    ? CircleAvatar(
                                        child: Icon(Icons.image_not_supported),
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
                                          Text('Id:' + produit.id.toString()),
                                        ],
                                      ),
                          ),
                        ),
                        title: Container(
                          width: 50,
                          child: Row(
                            children: [
                              Text(
                                produit.nom ?? '',
                                overflow: TextOverflow.ellipsis,
                              ),
                              Spacer(),
                              IconButton(
                                icon: Icon(Icons.edit, size: 15),
                                onPressed: () async {
                                  await Navigator.of(context)
                                      .push(MaterialPageRoute(
                                          builder: (ctx) => editProduct(
                                                produit: produit,
                                              )));
                                },
                              )
                            ],
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${produit.description ?? 'N/A'}',
                              overflow: TextOverflow.ellipsis,
                            ),

                            // Text(
                            //     'Users createdBy : ${produit.crud.target!.createdBy}'),
                            Text(
                              'Modifier par : ${produit.crud.target?.updatedBy ?? ''}',
                            )

                            // Text(
                            //     'Users deletedBy : ${produit.crud.target!.deletedBy}'),
                            // Text(
                            //     produit.approvisionnements.isNotEmpty
                            //         ? 'Approvisionnements:'
                            //         : '',
                            //     style:
                            //         TextStyle(fontWeight: FontWeight.bold)),

                            // DataTable(
                            //   columns: const <DataColumn>[
                            //     DataColumn(
                            //       label: Text(
                            //         'Quantité',
                            //         style: TextStyle(
                            //             fontStyle: FontStyle.italic),
                            //       ),
                            //     ),
                            //     DataColumn(
                            //       label: Text(
                            //         'Fournisseur',
                            //         style: TextStyle(
                            //             fontStyle: FontStyle.italic),
                            //       ),
                            //     ),
                            //     DataColumn(
                            //       label: Text(
                            //         'Date de péremption',
                            //         style: TextStyle(
                            //             fontStyle: FontStyle.italic),
                            //       ),
                            //     ),
                            //     DataColumn(
                            //       label: Text(
                            //         'Créé le',
                            //         style: TextStyle(
                            //             fontStyle: FontStyle.italic),
                            //       ),
                            //     ),
                            //     DataColumn(
                            //       label: Text(
                            //         'Prix d\'achat',
                            //         style: TextStyle(
                            //             fontStyle: FontStyle.italic),
                            //       ),
                            //     ),
                            //   ],
                            //   rows: produit.approvisionnements.map((appro) {
                            //     final fournisseur = appro.fournisseur.target;
                            //     return DataRow(
                            //       cells: <DataCell>[
                            //         DataCell(Text(
                            //             appro.quantite.toStringAsFixed(2))),
                            //         DataCell(
                            //             Text(fournisseur?.nom ?? 'Inconnu')),
                            //         DataCell(Text(appro.datePeremption != null
                            //             ? DateFormat('dd/MM/yyyy').format(
                            //                 appro.datePeremption!.toLocal())
                            //             : "N/A")),
                            //         DataCell(Text(DateFormat('dd/MM/yyyy')
                            //             .format(appro
                            //                 .crud.target!.dateCreation!
                            //                 .toLocal()))),
                            //         DataCell(Text(
                            //             appro.prixAchat.toStringAsFixed(2))),
                            //       ],
                            //     );
                            //   }).toList(),
                            // ),

                            // ...produit.approvisionnements.map((appro) {
                            //   final fournisseur = appro.fournisseur.target;
                            //   return Padding(
                            //       padding:
                            //           EdgeInsets.symmetric(vertical: 4.0),
                            //       child: ListTile(
                            //         leading: CircleAvatar(
                            //           child: Text(
                            //             'Quantité: ${appro.quantite.toStringAsFixed(2)}',
                            //           ),
                            //         ),
                            //         title: Text(
                            //           'Fournisseur: ${fournisseur?.nom ?? 'Inconnu'}',
                            //         ),
                            //         subtitle: Column(
                            //           children: [
                            //             Text(
                            //               'Date de péremption: ${appro.datePeremption != null ? DateFormat('dd/MM/yyyy').format(appro.datePeremption!.toLocal()) : "N/A"}',
                            //             ),
                            //             Text(
                            //               'Créer le : ${DateFormat('dd/MM/yyyy').format(appro.crud.target!.dateCreation!.toLocal())}',
                            //             ),
                            //           ],
                            //         ),
                            //         trailing: Text(
                            //           'Prix d\'achat: ${appro.prixAchat.toStringAsFixed(2)}',
                            //         ),
                            //       ));
                            // }).toList(),
                          ],
                        ),
                        trailing: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Text(
                                '${produit.prixVente.toStringAsFixed(2)} DZD',
                                style: TextStyle(fontSize: 16),
                              ),
                            ),
                            SizedBox(
                              height: 5,
                            ),
                            RichText(
                              text: TextSpan(
                                text: 'Qty : $totalQuantite',
                                style: Theme.of(context).textTheme.titleSmall,
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () {
                                    showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        double totalQuantite = 0;
                                        double totalAmount = 0;

                                        produit.approvisionnements
                                            .forEach((appro) {
                                          totalQuantite += appro.quantite;
                                          totalAmount +=
                                              appro.quantite * appro.prixAchat!;
                                        });

                                        return AlertDialog(
                                          title: Text('Approvisionnements'),
                                          content: SingleChildScrollView(
                                            scrollDirection: Axis.vertical,
                                            child: SingleChildScrollView(
                                              scrollDirection: Axis.horizontal,
                                              child: DataTable(
                                                columns: const <DataColumn>[
                                                  DataColumn(
                                                    label: Text(
                                                      'Quantité',
                                                      style: TextStyle(
                                                          fontStyle:
                                                              FontStyle.italic),
                                                    ),
                                                  ),
                                                  DataColumn(
                                                    label: Text(
                                                      'Fournisseur',
                                                      style: TextStyle(
                                                          fontStyle:
                                                              FontStyle.italic),
                                                    ),
                                                  ),
                                                  DataColumn(
                                                    label: Text(
                                                      'Date de péremption',
                                                      style: TextStyle(
                                                          fontStyle:
                                                              FontStyle.italic),
                                                    ),
                                                  ),
                                                  DataColumn(
                                                    label: Text(
                                                      'Créé le',
                                                      style: TextStyle(
                                                          fontStyle:
                                                              FontStyle.italic),
                                                    ),
                                                  ),
                                                  DataColumn(
                                                    label: Text(
                                                      'Prix d\'achat',
                                                      style: TextStyle(
                                                          fontStyle:
                                                              FontStyle.italic),
                                                    ),
                                                  ),
                                                  DataColumn(
                                                    label: Text(
                                                      'Montant',
                                                      style: TextStyle(
                                                          fontStyle:
                                                              FontStyle.italic),
                                                    ),
                                                  ),
                                                ],
                                                rows: [
                                                  ...produit.approvisionnements
                                                      .map((appro) {
                                                    final fournisseur = appro
                                                        .fournisseur.target;
                                                    return DataRow(
                                                      cells: <DataCell>[
                                                        DataCell(Text(appro
                                                            .quantite
                                                            .toStringAsFixed(
                                                                2))),
                                                        DataCell(Text(
                                                            fournisseur?.nom ??
                                                                'Inconnu')),
                                                        DataCell(Text(appro
                                                                    .datePeremption !=
                                                                null
                                                            ? DateFormat(
                                                                    'dd/MM/yyyy')
                                                                .format(appro
                                                                    .datePeremption!
                                                                    .toLocal())
                                                            : "N/A")),
                                                        DataCell(Text(DateFormat(
                                                                'dd/MM/yyyy')
                                                            .format(appro
                                                                .crud
                                                                .target!
                                                                .dateCreation!
                                                                .toLocal()))),
                                                        DataCell(Text(appro
                                                            .prixAchat!
                                                            .toStringAsFixed(
                                                                2))),
                                                        DataCell(Text((appro
                                                                    .quantite *
                                                                appro
                                                                    .prixAchat!)
                                                            .toStringAsFixed(
                                                                2))),
                                                      ],
                                                    );
                                                  }).toList(),
                                                  DataRow(
                                                    cells: <DataCell>[
                                                      DataCell(Text(
                                                          totalQuantite
                                                              .toStringAsFixed(
                                                                  2))),
                                                      DataCell(Text('')),
                                                      DataCell(Text('')),
                                                      DataCell(Text('')),
                                                      DataCell(Text('')),
                                                      DataCell(Text(totalAmount
                                                          .toStringAsFixed(2))),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          actions: <Widget>[
                                            TextButton(
                                              onPressed: () {
                                                Navigator.of(context).pop();
                                              },
                                              child: Text('Fermer'),
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  },
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 15.0, vertical: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8.0),
                              child: Text(
                                produit.approvisionnements.isNotEmpty
                                    ? 'Dernier Approvisionnement le : ${DateFormat('dd/MM/yyyy').format(
                                        produit.approvisionnements.last.crud
                                                .target?.derniereModification ??
                                            DateTime.now(),
                                      )}'
                                    : 'No approvisionnements available',
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Wrap(
                                spacing:
                                    8.0, // Espacement horizontal entre les Chips
                                runSpacing:
                                    7.0, // Espacement vertical entre les Chips
                                children: qrCodes
                                    .map((code) => Chip(
                                          padding: EdgeInsets.zero,

                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                                20.0), // Coins arrondis
                                          ),
                                          avatar: CircularFlagDetector(
                                            barcode: code,
                                            size:
                                                22, // Adjust the size as needed
                                          ),
                                          backgroundColor: Theme.of(context)
                                                      .brightness ==
                                                  Brightness.dark
                                              ? Colors.blueAccent.withOpacity(
                                                  0.2) // Couleur pour le thème sombre
                                              : Colors.blueAccent
                                                  .withOpacity(0.6),
                                          // Couleur pour le thème clair
                                          visualDensity:
                                              VisualDensity(vertical: -1),
                                          label: Text(
                                            code,
                                            style: TextStyle(
                                              color: Theme.of(context)
                                                          .brightness ==
                                                      Brightness.dark
                                                  ? Colors
                                                      .white // Couleur du texte pour le thème sombre
                                                  : Colors
                                                      .black, // Couleur du texte pour le thème clair
                                            ),
                                          ), // Affiche le QR code dans le Chip
                                        ))
                                    .toList(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              } else if (produitProvider.hasMoreProduits) {
                return Center(child: CircularProgressIndicator());
              } else {
                return SizedBox.shrink();
              }
            },
          );
        },
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context)
              .push(MaterialPageRoute(builder: (_) => addProduct()));
        },
        child: Icon(Icons.add),
      ),
    );
  }
}

// Widget _buildChipRow(
//     BuildContext context, produit /*List<Fournisseur> fournisseurs*/) {
//   final List<Fournisseur> fournisseurs = produit.fournisseurs;
//   if (fournisseurs.length <= 2) {
//     return Wrap(
//       spacing: 4.0,
//       runSpacing: 0.0,
//       children: fournisseurs.map((fournisseur) {
//         return InkWell(
//           onTap: () {
//             Navigator.of(context).push(
//               MaterialPageRoute(
//                 builder: (ctx) =>
//                     ProduitsFournisseurPage(fournisseur: fournisseur),
//               ),
//             );
//           },
//           child: Chip(
//             shadowColor: Colors.black,
//             backgroundColor: Theme.of(context).chipTheme.backgroundColor,
//             labelStyle: TextStyle(
//               color: Theme.of(context).chipTheme.labelStyle?.color,
//             ),
//             side: BorderSide.none,
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.all(Radius.circular(10)),
//             ),
//             padding: EdgeInsets.zero,
//             label: Text(
//               fournisseur.nom,
//               style: TextStyle(fontSize: 10),
//             ),
//           ),
//         );
//       }).toList(),
//     );
//   } else {
//     return Wrap(
//       spacing: 4.0,
//       runSpacing: 0.0,
//       children: [
//         for (var i = 0; i < 2; i++)
//           InkWell(
//             onTap: () {
//               Navigator.of(context).push(
//                 MaterialPageRoute(
//                   builder: (ctx) =>
//                       ProduitsFournisseurPage(fournisseur: fournisseurs[i]),
//                 ),
//               );
//             },
//             child: Chip(
//               shadowColor: Colors.black,
//               backgroundColor: Theme.of(context).chipTheme.backgroundColor,
//               labelStyle: TextStyle(
//                 color: Theme.of(context).chipTheme.labelStyle?.color,
//               ),
//               side: BorderSide.none,
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.all(Radius.circular(10)),
//               ),
//               padding: EdgeInsets.zero,
//               label: Text(
//                 fournisseurs[i].nom,
//                 style: TextStyle(fontSize: 10),
//               ),
//             ),
//           ),
//         IconButton(
//           onPressed: () {
//             _showAllFournisseursDialog(
//               context,
//               produit, /*fournisseurs*/
//             );
//           },
//           icon: Icon(
//             Icons.add,
//           ),
//         ),
//       ],
//     );
//   }
// }

void _showAllFournisseursDialog(
  BuildContext context,
  produit,
) {
  final List<Fournisseur> fournisseurs = produit.fournisseurs;
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Les Fournisseurs du ${produit.nom}'),
        content: SingleChildScrollView(
          child: Wrap(
            spacing: 4.0,
            runSpacing: 0.0,
            children: fournisseurs.map((fournisseur) {
              return InkWell(
                // onTap: () {
                //   Navigator.of(context).push(
                //     MaterialPageRoute(
                //       builder: (ctx) =>
                //           ProduitsFournisseurPage(fournisseur: fournisseur),
                //     ),
                //   );
                // },
                child: Chip(
                  shadowColor: Colors.black,
                  backgroundColor: Theme.of(context).chipTheme.backgroundColor,
                  labelStyle: TextStyle(
                    color: Theme.of(context).chipTheme.labelStyle?.color,
                  ),
                  side: BorderSide.none,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                  ),
                  padding: EdgeInsets.zero,
                  label: Text(
                    fournisseur.nom,
                    style: TextStyle(fontSize: 10),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        actions: <Widget>[
          TextButton(
            child: Text('Fermer'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}

void _deleteProduit(BuildContext context, Produit produit) {
  showModalBottomSheet(
    context: context,
    builder: (BuildContext context) {
      return Container(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Confirmer la suppression', style: TextStyle(fontSize: 20.0)),
            SizedBox(height: 20.0),
            Text('Êtes-vous sûr de vouloir supprimer ce produit ?'),
            SizedBox(height: 20.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    // Utilise les couleurs du thème
                    backgroundColor: Theme.of(context).colorScheme.secondary,
                    foregroundColor: Theme.of(context).colorScheme.onSecondary,
                    elevation: 2,
                  ),
                  label: Text('Annuler'),
                  icon: Icon(Icons.cancel),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    context.read<CommerceProvider>().supprimerProduit(produit);
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    // Utilise les couleurs du thème pour le bouton de suppression
                    backgroundColor: Theme.of(context).colorScheme.error,
                    foregroundColor: Theme.of(context).colorScheme.onError,
                    elevation: 2,
                  ),
                  label: Text('Supprimer'),
                  icon: Icon(Icons.delete),
                )
              ],
            ),
            SizedBox(
              height: 60,
            )
          ],
        ),
      );
    },
  );
}

class ProduitDetailPage extends StatelessWidget {
  final Produit produit;

  ProduitDetailPage({required this.produit});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: CustomScrollView(
      slivers: [
        SliverAppBar(
            expandedHeight: 400.0,
            pinned: true,
            flexibleSpace: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                // Calculer le pourcentage de collapse
                double percent = (constraints.maxHeight - kToolbarHeight) /
                    (400.0 - kToolbarHeight);
                // Limiter entre 0 et 1
                percent = percent.clamp(0.0, 1.0);

                return FlexibleSpaceBar(
                  title: Text(produit.nom.capitalize,
                      style: TextStyle(color: Colors.white70)),
                  titlePadding:
                      EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  background: Stack(
                    alignment: Alignment.bottomCenter,
                    fit: StackFit.expand,
                    children: [
                      produit.image!.isEmpty
                          ? Center(
                              child: Icon(Icons.image_not_supported, size: 50))
                          : CachedNetworkImage(
                              imageUrl: produit.image!,
                              fit: BoxFit.cover,
                              errorWidget: (context, url, error) =>
                                  Center(child: Icon(Icons.error, size: 50)),
                            ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.8),
                            ],
                            stops: [0.3, 1.0], // position du dégradé
                          ),
                        ),
                      ),
                      Positioned(
                        right: 20,
                        bottom: 20,
                        child: Column(
                          children: [
                            SizedBox(
                              width: 100,
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  'ID : ${produit.id} \nQR : ${produit.qr}',
                                  style: TextStyle(
                                    color: Colors.white70,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(
                              height: 100, width: 100,
                              child: SfBarcodeGenerator(
                                value: produit.qr.toString(),
                                symbology: QRCode(),
                                barColor: Colors.white70,
                              ),

                              // PrettyQr(
                              //     data: produit.qr.toString(),
                              //     elementColor: Theme.of(context).hintColor,
                              //   ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(1 - (1 * percent)),
                        ),
                      ),
                    ],
                  ),
                  collapseMode: CollapseMode.parallax,
                );
              },
            )),
        SliverList(
          delegate: SliverChildListDelegate(
            [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dernière Modification : ' +
                          timeago.format(
                              produit.crud.target!.derniereModification,
                              locale: 'fr'),
                      style: TextStyle(fontSize: 12),
                    ),
                    SizedBox(height: 28),
                    // Center(
                    //     child: Padding(
                    //   padding: const EdgeInsets.all(8.0),
                    //   child: Text('QR : ${produit.qr}'),
                    // )),
                    // Center(
                    //   child: PrettyQr(
                    //     data: produit.qr.toString(),
                    //     elementColor: Theme.of(context).hintColor,
                    //   ),
                    // ),
                    // SizedBox(height: 8),
                    // Center(child: Text('Id : ${produit.id}')),
                    // Center(
                    //   child: Text(
                    //     produit.nom,
                    //     style: TextStyle(
                    //         fontSize: 24, fontWeight: FontWeight.bold),
                    //   ),
                    // ),
                    // SizedBox(height: 28),
                    // Text(
                    //   'Prix d\'achat: ${produit.prixAchat.toStringAsFixed(2)} DZD',
                    //   style: TextStyle(fontSize: 16),
                    // ),
                    Text(
                      'Prix de vente: ${produit.prixVente.toStringAsFixed(2)} DZD',
                      style: TextStyle(fontSize: 16),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Stock : ' + produit.stock.truncate().toString(),
                      style: TextStyle(fontSize: 16),
                    ),
                    produit.description != null &&
                            produit.description!.isNotEmpty
                        ? Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child:
                                Text('Description :\n${produit.description}'),
                          )
                        : SizedBox.shrink(),
                    // Vérifiez si les données doivent être affichées
                    if ((produit.qtyPartiel != null &&
                            produit.qtyPartiel! > 1) &&
                        (produit.pricePartielVente != null &&
                            produit.pricePartielVente! > 0)) ...[
                      SizedBox(height: 16),
                      Text(
                        'Nombre de pièces dans ce pack: ${produit.qtyPartiel!.truncate()}',
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Prix de la pièce du détail: ${produit.pricePartielVente!.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 16),
                      ),
                      SizedBox(height: 16),
                    ],
                    SizedBox(height: 10),
                    // Text('Stock Minimal pour l\'Alert : ' +
                    //     produit.stockinit.toString()),
                    // SizedBox(height: 10),
                    // Text('Stock Update : ' + produit.stockUpdate.toString()),
                    SizedBox(height: 10),
                    produit.approvisionnements.isEmpty ||
                            produit.approvisionnements == ''
                        ? Container()
                        : SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              columns: [
                                DataColumn(label: Text('Fournisseurs')),
                                DataColumn(label: Text('Date de Création')),
                                DataColumn(label: Text('Quantité')),
                                DataColumn(label: Text('Prix d\'Achat')),
                                DataColumn(label: Text('Date de Péremption')),
                              ],
                              rows: produit.approvisionnements.map((appro) {
                                return DataRow(
                                  cells: [
                                    DataCell(
                                      Text(
                                        appro.fournisseur != null &&
                                                appro.fournisseur.target != null
                                            ? '${appro.fournisseur.target!.nom}'
                                            : '-', // Valeur par défaut si fournisseur ou target est null
                                      ),
                                    ),
                                    DataCell(
                                      Text(
                                        appro.crud != null &&
                                                appro.crud.target != null
                                            ? DateFormat(
                                                    'EEE dd MMM yyyy', 'fr')
                                                .format(DateTime.parse(appro
                                                    .crud.target!.dateCreation
                                                    .toString()))
                                            : '-', // Valeur par défaut si crud ou target est null
                                      ),
                                    ),
                                    DataCell(Text(
                                        '${appro.quantite.truncate().toStringAsFixed(2)}')),
                                    DataCell(Text(
                                        '${appro.prixAchat?.toStringAsFixed(2) ?? '-'}')),
                                    DataCell(
                                      Text(
                                        appro.datePeremption != null
                                            ? DateFormat(
                                                    'EEE dd MMM yyyy', 'fr')
                                                .format(DateTime.parse(appro
                                                    .datePeremption
                                                    .toString()))
                                            : '-', // Valeur par défaut si datePeremption est null
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                    // SizedBox(height: 10),
                    // ...produit.approvisionnements.map((appro) {
                    //   return Padding(
                    //     padding: EdgeInsets.symmetric(vertical: 4.0),
                    //     child: Text(
                    //         '  Date Peremption :  ${appro.datePeremption}'),
                    //   );
                    // }).toList(),
                    //
                    // SizedBox(height: 10),
                    SizedBox(height: 10),
                    SizedBox(
                      height: 16,
                    ),
                    produit.approvisionnements.length == 0
                        ? SizedBox.shrink()
                        : Divider(),
                    produit.approvisionnements.isEmpty ||
                            !produit.approvisionnements.any((appro) =>
                                appro.fournisseur != null &&
                                appro.fournisseur.target != null)
                        ? SizedBox.shrink()
                        : Text(
                            'Fournisseurs',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                    SizedBox(height: 8),
                    // SizedBox(height: 10),
                    // ...produit.approvisionnements.map((appro) {
                    //   return Padding(
                    //     padding: EdgeInsets.symmetric(vertical: 4.0),
                    //     child: Text(
                    //         '  Date Peremption :  ${appro.datePeremption}'),
                    //   );
                    // }).toList(),
                    // Consumer<CommerceProvider>(
                    //   builder: (context, produitProvider, child) {
                    //return
                    Wrap(
                      spacing: 6.0, // Espace horizontal entre les éléments
                      runSpacing: 4.0, // Espace vertical entre les lignes
                      children: produit.approvisionnements
                          .where((appro) => appro.fournisseur.target != null)
                          .map((appro) {
                        return InkWell(
                          onTap: () {
                            Navigator.of(context).push(MaterialPageRoute(
                                builder: (ctx) => ProduitsFournisseurPage(
                                      fournisseur: appro.fournisseur.target!,
                                    )));
                          },
                          child: Chip(
                            backgroundColor:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Theme.of(context).colorScheme.surface
                                    : Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .withOpacity(0.1),
                            labelStyle: TextStyle(
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Theme.of(context).colorScheme.onSurface
                                  : Theme.of(context).colorScheme.primary,
                              fontSize:
                                  12, // Ajout pour une taille de texte cohérente
                            ),
                            side: BorderSide(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withOpacity(0.5),
                              width: 1, // Définir une bordure subtile
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(10)),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            label: Text(
                              appro.fournisseur.target?.nom ??
                                  'Fournisseur inconnu',
                              overflow: TextOverflow
                                  .ellipsis, // Gérer les textes trop longs
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    //     ;
                    //   },
                    // ),
                    SizedBox(
                      height: 20,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: ElevatedButton.icon(
                            onPressed: () {
                              context
                                  .read<CommerceProvider>()
                                  .supprimerProduit(produit);
                              Navigator.of(context).pop();
                            },
                            style: ElevatedButton.styleFrom(
                              // Utilise les couleurs du thème pour le bouton de suppression
                              backgroundColor:
                                  Theme.of(context).colorScheme.error,
                              foregroundColor:
                                  Theme.of(context).colorScheme.onError,
                              elevation: 2,
                            ),
                            label: Text('Supprimer'),
                            icon: Icon(Icons.delete),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              final updatedProduit =
                                  await Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (ctx) => editProduct(
                                    produit: produit,
                                  ),
                                ),
                              );
                            },
                            label: Text('Modifier'),
                            icon: Icon(Icons.edit),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(
                      height: 50,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    ));
  }
}

class ProduitSearchDelegateMain extends SearchDelegate {
  final CommerceProvider commerceProvider;

  ProduitSearchDelegateMain(this.commerceProvider);

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(Icons.clear),
        onPressed: () {
          query = '';
          showSuggestions(context);
        },
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults(context);
  }

  Widget _buildSearchResults(BuildContext context) {
    return FutureBuilder<List<Produit>>(
      future: commerceProvider.rechercherProduits(query),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Erreur: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text('Aucun résultat trouvé'));
        } else {
          final results = snapshot.data!;
          return ListView.builder(
            itemCount: results.length,
            itemBuilder: (context, index) {
              final produit = results[index];
              return ListTile(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => ProduitDetailPage(produit: produit),
                    ),
                  );
                },
                title: Text('${produit.qr} ${produit.nom}'),
                subtitle:
                    Text('Prix: ${produit.prixVente.toStringAsFixed(2)} DZD'),
                trailing: IconButton(
                  icon: Icon(Icons.add_shopping_cart),
                  onPressed: () {
                    Provider.of<CartProvider>(context, listen: false)
                        .addToCart(produit);
                    Navigator.of(context).pop();
                  },
                ),
              );
            },
          );
        }
      },
    );
  }
}
