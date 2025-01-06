import 'dart:isolate';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';

import '../Entity.dart';
import '../MyProviders.dart';
import '../classeObjectBox.dart'; // Import du package Provider

// Import de la page de détails d'un Crud

class CrudListScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<CrudProvider>(
      builder: (context, crudProvider, child) {
        final cruds = crudProvider.cruds; // Liste des cruds à afficher
        final totalCruds = crudProvider.totalCrudCount; // Nombre total de Cruds
        return Scaffold(
          appBar: AppBar(
            title: Text(
                'Cruds List (Total: $totalCruds)'), // Affiche le nombre total de Cruds
          ),
          body: ListView.builder(
            itemCount: cruds.length,
            itemBuilder: (context, index) {
              final crud =
                  cruds[cruds.length - 1 - index]; // Pour inverser la liste
              print(cruds.length.toString());
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(crud.id.toString()),
                    ),
                  ),
                  title: Text(
                      'ID: ${crud.id} - Created By: ${crud.createdBy ?? "N/A"}'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Updated By: ${crud.updatedBy}'),
                      Text('Deleted By: ${crud.deletedBy ?? "N/A"}'),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class UserListScreen extends StatefulWidget {
  final Produit? produit;

  UserListScreen({Key? key, this.produit}) : super(key: key);

  @override
  State<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  NativeAd? _nativeAd;

  bool _nativeAdIsLoaded = false;

  void checkCrudsWithInvalidUserIds(objectBox) {
    // Étape 1 : Récupérer tous les IDs des utilisateurs existants
    final userBox = objectBox.store.box<User>();
    final crudBox = objectBox.store.box<Crud>();

    final existingUserIds = userBox.getAll().map((user) => user.id).toList();

    // Étape 2 : Vérifier les champs createdBy, updatedBy, et deletedBy dans la Box<Crud>
    final invalidCruds = crudBox.getAll().where((crud) {
      return (crud.createdBy != null &&
              !existingUserIds.contains(crud.createdBy)) ||
          !existingUserIds.contains(crud.updatedBy) ||
          (crud.deletedBy != null && !existingUserIds.contains(crud.deletedBy));
    }).toList();

    // Afficher les Cruds avec des IDs de User invalides
    if (invalidCruds.isEmpty) {
      print("Tous les Cruds ont des IDs de User valides.");
    } else {
      print("Les Cruds suivants ont des IDs de User inexistants :");
      for (var crud in invalidCruds) {
        print(
            "Crud ID: ${crud.id}, createdBy: ${crud.createdBy}, updatedBy: ${crud.updatedBy}, deletedBy: ${crud.deletedBy}");
      }
    }
  }

  // Future<void> updateCrudsWithValidUserIdsAsync(objectBox) async {
  //   await Isolate.run(() {
  //     final userBox = objectBox.store.box<User>();
  //     final crudBox = objectBox.store.box<Crud>();
  //
  //     // Étape 1 : Récupérer les utilisateurs existants dans la Box<User>
  //     final users = userBox.getAll();
  //     final userIdMap = Map<int, User>.fromIterable(users,
  //         key: (user) => user.id, value: (user) => user);
  //
  //     // Étape 2 : Parcourir les entités Crud et mettre à jour les champs createdBy, updatedBy, et deletedBy
  //     final allCruds = crudBox.getAll();
  //     for (var crud in allCruds) {
  //       // Si createdBy est null ou invalide, on lui affecte un ID valide aléatoire
  //       if (crud.createdBy == null || !userIdMap.containsKey(crud.createdBy)) {
  //         crud.createdBy = userIdMap
  //             .keys.first; // Par défaut, on met l'ID du premier utilisateur
  //       }
  //
  //       // Si updatedBy est invalide, on lui affecte un ID valide aléatoire
  //       if (!userIdMap.containsKey(crud.updatedBy)) {
  //         crud.updatedBy = userIdMap
  //             .keys.first; // Par défaut, on met l'ID du premier utilisateur
  //       }
  //
  //       // Si deletedBy est null ou invalide, on lui affecte un ID valide aléatoire si nécessaire
  //       if (crud.deletedBy != null && !userIdMap.containsKey(crud.deletedBy)) {
  //         crud.deletedBy = userIdMap
  //             .keys.first; // Par défaut, on met l'ID du premier utilisateur
  //       }
  //
  //       // Mettre à jour l'entité Crud dans la base
  //       crudBox.put(crud);
  //     }
  //
  //     print("Tous les Cruds ont été mis à jour avec des IDs valides.");
  //   });
  // }

  @override
  Widget build(BuildContext context) {
    final objectBox = Provider.of<ObjectBox>(context, listen: false);
    return Scaffold(
      appBar: AppBar(
        title: Text('Users'),
        actions: [
          Consumer<CrudProvider>(
            builder: (context, crudProvider, child) {
              final totalCruds =
                  crudProvider.totalCrudCount; // Nombre total de Cruds
              return Text('Cruds List (Total: $totalCruds)');
            },
          ),
          SizedBox(
            width: 100,
          ),
          IconButton(
            icon: Icon(
              Icons.vertical_align_bottom,
              color: Colors.green,
            ),
            onPressed: () async {
              // checkCrudsWithInvalidUserIds(objectBox);
              updateCrudsWithValidUserIdsAsync(objectBox);
            },
          ),
          IconButton(
            icon: Icon(
              Icons.dashboard,
              color: Colors.blue,
            ),
            onPressed: () async {
              updateCrudsWithValidUserIdsAsync2(objectBox);
              // updateCrudsWithValidUserIdsAsync(objectBox);
            },
          ),
          SizedBox(
            width: 60,
          ),
        ],
      ),
      body: Consumer<CommerceProvider>(
        builder: (context, userProvider, child) {
          return ListView.builder(
            itemCount: userProvider.users.length,
            itemBuilder: (context, index) {
              if (index == 5 && _nativeAd != null && _nativeAdIsLoaded) {
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
              final user = userProvider.users[index];
              return Card(
                child: ListTile(
                  // onLongPress: () {
                  //   _deleteUser(context, user);
                  // },
                  // onTap: () {
                  //   Navigator.of(context).push(
                  //     MaterialPageRoute(
                  //       builder: (context) => ProduitsUserPage(
                  //         user: user,
                  //         //   produits: fournisseur.produits,
                  //       ),
                  //     ),
                  //   );
                  // },
                  leading: CircleAvatar(
                    child: FittedBox(
                        child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(user.id.toString()),
                    )),
                  ),
                  title: Text(user.username),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Phone : ${user.phone}'),
                      // Text(
                      //   'Créer le ${user.crud.target!.dateCreation!.day}-${user.crud.target!.dateCreation!.month}-${user.crud.target!.dateCreation!.year}  Modifié ${timeago.format(user.crud.target!.derniereModification, locale: 'fr')}',
                      //   style: TextStyle(
                      //     fontSize: 13,
                      //     fontWeight:
                      //         FontWeight.w300, /* fontStyle: FontStyle.italic*/
                      //   ),
                      // ),
                    ],
                  ),
                  trailing: Container(
                    width: 70,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        // Expanded(
                        //   child: Text(
                        //     fournisseur.produits.length.toString(),
                        //     style: TextStyle(fontSize: 20),
                        //   ),
                        // ),
                        Expanded(
                          child: IconButton(
                            icon: Icon(
                              Icons.edit,
                            ),
                            onPressed: () {
                              //  _editUser(context, user);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      // floatingActionButton: FloatingActionButton(
      //   onPressed: () {
      //     showModalBottomSheet(
      //       context: context,
      //       isScrollControlled:
      //       true, // Permet de redimensionner en fonction de la hauteur du contenu
      //       builder: (context) => AddUserForm(),
      //     );
      //   },
      //   child: Icon(Icons.add),
      // ),
    );
  }

  Future<void> updateCrudsWithValidUserIdsAsync(objectBox) async {
    final userBox = objectBox.store.box<User>();
    final crudBox = objectBox.store.box<Crud>();

    // Récupérer les utilisateurs dans le thread principal
    final users = userBox.getAll();
    final userIds = users.map((user) => user.id).toList();

    // Récupérer les Crud dans le thread principal
    final allCruds = crudBox.getAll();

    // Transformer les Crud en une structure de données transférable
    final crudDataList = allCruds
        .map((crud) => {
              'id': crud.id,
              'createdBy': crud.createdBy,
              'updatedBy': crud.updatedBy,
              'deletedBy': crud.deletedBy
            })
        .toList();

    // Exécuter le traitement dans un Isolate
    final updatedCrudDataList = await Isolate.run(() {
      return crudDataList.map((crudData) {
        // Mise à jour des champs selon les userIds valides
        if (!userIds.contains(crudData['createdBy'])) {
          crudData['createdBy'] = userIds.first; // Met à jour avec un ID valide
        }
        if (!userIds.contains(crudData['updatedBy'])) {
          crudData['updatedBy'] = userIds.first;
        }
        if (crudData['deletedBy'] != null &&
            !userIds.contains(crudData['deletedBy'])) {
          crudData['deletedBy'] = userIds.first;
        }
        return crudData;
      }).toList();
    });

    // Mettre à jour les Crud dans la base de données dans le thread principal
    for (var crudData in updatedCrudDataList) {
      final crud = crudBox.get(crudData['id']);
      if (crud != null) {
        crud.createdBy = crudData['createdBy'];
        crud.updatedBy = crudData['updatedBy'];
        crud.deletedBy = crudData['deletedBy'];
        crudBox.put(crud); // Mettre à jour l'entité dans ObjectBox
      }
    }

    print("Tous les Cruds ont été mis à jour avec des IDs valides.");
  }

  Future<void> updateCrudsWithValidUserIdsAsync2(ObjectBox objectBox) async {
    final userBox = objectBox.store.box<User>();
    final crudBox = objectBox.store.box<Crud>();

    print("Début de la récupération des utilisateurs...");

    // Récupérer les utilisateurs dans le thread principal
    final users = userBox.getAll();
    print("Utilisateurs récupérés : ${users.length} utilisateurs.");

    final userIds = users.map((user) => user.id).toList();
    print("IDs des utilisateurs : $userIds");

    print("Début de la récupération des Cruds...");

    // Récupérer les Crud dans le thread principal
    final allCruds = crudBox.getAll();
    print("Cruds récupérés : ${allCruds.length} cruds.");

    // Transformer les Crud en une structure de données transférable
    final crudDataList = allCruds
        .map((crud) => {
              'id': crud.id,
              'createdBy': crud.createdBy,
              'updatedBy': crud.updatedBy,
              'deletedBy': crud.deletedBy
            })
        .toList();

    print("Données des Cruds transformées en liste pour Isolate.");

    // Exécuter le traitement dans un Isolate
    print("Début de l'exécution dans un Isolate...");

    final updatedCrudDataList = await Isolate.run(() {
      return crudDataList.map((crudData) {
        print("Traitement du Crud ID: ${crudData['id']}");

        // Mise à jour des champs selon les userIds valides
        if (!userIds.contains(crudData['createdBy'])) {
          print(
              "ID de createdBy non valide : ${crudData['createdBy']}. Mise à jour avec ${userIds.first}");
          crudData['createdBy'] = userIds.first; // Met à jour avec un ID valide
        }
        if (!userIds.contains(crudData['updatedBy'])) {
          print(
              "ID de updatedBy non valide : ${crudData['updatedBy']}. Mise à jour avec ${userIds.first}");
          crudData['updatedBy'] = userIds.first;
        }
        if (crudData['deletedBy'] != null &&
            !userIds.contains(crudData['deletedBy'])) {
          print(
              "ID de deletedBy non valide : ${crudData['deletedBy']}. Mise à jour avec ${userIds.first}");
          crudData['deletedBy'] = userIds.first;
        }

        return crudData;
      }).toList();
    });

    print("Traitement terminé dans l'Isolate.");

    // Mettre à jour les Crud dans la base de données dans le thread principal
    print("Début de la mise à jour des Cruds dans la base de données...");

    for (var crudData in updatedCrudDataList) {
      final crud = crudBox.get(crudData['id']!);
      if (crud != null) {
        print("Mise à jour du Crud ID: ${crud.id} dans la base de données.");
        crud.createdBy = crudData['createdBy'];
        crud.updatedBy = crudData['updatedBy']!;
        crud.deletedBy = crudData['deletedBy'];
        crudBox.put(crud); // Mettre à jour l'entité dans ObjectBox
      } else {
        print("Crud ID: ${crudData['id']} introuvable.");
      }
    }

    print("Tous les Cruds ont été mis à jour avec des IDs valides.");
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Create the ad objects and load ads.
    _nativeAd = NativeAd(
      adUnitId: 'ca-app-pub-2282149611905342/3007902409',
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
  }
}
