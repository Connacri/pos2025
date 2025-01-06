import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../Entity.dart';
import '../MyProviders.dart';
import '../classeObjectBox.dart';
import 'ProduitListScreen.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:timeago/timeago.dart' as timeago;
import 'addProduct.dart';

import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'dart:isolate';

class FournisseurListScreen extends StatefulWidget {
  final Produit? produit;

  FournisseurListScreen({Key? key, this.produit}) : super(key: key);

  @override
  State<FournisseurListScreen> createState() => _FournisseurListScreenState();
}

class _FournisseurListScreenState extends State<FournisseurListScreen> {
  NativeAd? _nativeAd;

  bool _nativeAdIsLoaded = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Fournisseurs'),
        actions: [
          IconButton(
            icon: Icon(Icons.update, color: Colors.lightGreen),
            onPressed: () async {
              final commerceProvider =
                  Provider.of<CommerceProvider>(context, listen: false);
              await commerceProvider.miseAJourDesApprovisionnements();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text('Approvisionnements mis à jour avec succès')),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () async {
              final fournisseurProvider =
                  Provider.of<CommerceProvider>(context, listen: false);
              showSearch(
                context: context,
                delegate: FournisseurSearchDelegateMain(
                    fournisseurProvider.fournisseurs),
              );
            },
          ),
          SizedBox(width: 120),
        ],
      ),
      body: Consumer<CommerceProvider>(
        builder: (context, fournisseurProvider, child) {
          return ListView.builder(
            itemCount: fournisseurProvider.fournisseurs.length,
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
              final fournisseur = fournisseurProvider.fournisseurs[index];
              return Card(
                child: ListTile(
                  onLongPress: () {
                    _deleteFournisseur(context, fournisseur);
                  },
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => ProduitsFournisseurPage(
                          fournisseur: fournisseur,
                          //   produits: fournisseur.produits,
                        ),
                      ),
                    );
                  },
                  leading: CircleAvatar(
                    child: FittedBox(
                        child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(fournisseur.id.toString()),
                    )),
                  ),
                  title: Text(fournisseur.nom),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Phone : ${fournisseur.phone}'),
                      Text(
                        'Créer le ${(fournisseur.crud.target?.dateCreation != null) ? '${fournisseur.crud.target!.dateCreation!.day}-${fournisseur.crud.target!.dateCreation!.month}-${fournisseur.crud.target!.dateCreation!.year}' : 'Date inconnue'} '
                        'Modifié ${(fournisseur.crud.target?.derniereModification != null) ? timeago.format(fournisseur.crud.target!.derniereModification, locale: 'fr') : 'Modification inconnue'}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight:
                              FontWeight.w300, /* fontStyle: FontStyle.italic*/
                        ),
                      ),
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
                              _editFournisseur(context, fournisseur);
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled:
                true, // Permet de redimensionner en fonction de la hauteur du contenu
            builder: (context) => AddFournisseurForm(),
          );
        },
        child: Icon(Icons.add),
      ),
    );
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

class ProduitsFournisseurPage extends StatelessWidget {
  final Fournisseur fournisseur;
  //final List<Produit>? produits;

  ProduitsFournisseurPage({
    required this.fournisseur, //this.produits
  });

  @override
  Widget build(BuildContext context) {
    // final produits = Provider.of<CommerceProvider>(context)
    //     .getProduitsForFournisseur(fournisseur);
    //.getFournisseurById(fournisseur.id);
    // final produitProvider = Provider.of<CommerceProvider>(context);
    final commerceProvider =
        Provider.of<CommerceProvider>(context, listen: false);
    final double largeur;
    if (kIsWeb || Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      // Pour le web
      largeur = 1 / 10;
    } else if (Platform.isAndroid || Platform.isIOS) {
      // Pour Android et iOS
      largeur = 0.5;
    } else {
      // Pour les autres plateformes (Desktop)
      largeur = 1 / 10;
    }
    return Scaffold(
      body: CustomScrollView(
        slivers: <Widget>[
          MySliverAppBar(fournisseur: fournisseur),
          MySliverToBoxAdapter(fournisseur: fournisseur),
          Consumer<CommerceProvider>(
            builder: (context, commerceProvider, child) {
              final produits =
                  commerceProvider.getProduitsForFournisseur(fournisseur);
              print(produits
                  .length); // Vérifiez ce qui est retourné ici pour déboguer

              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (BuildContext context, int index) {
                    final produit = produits[index];
                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      // child: Slidable(
                      //     key: ValueKey(produit.id),
                      //     startActionPane: ActionPane(
                      //       extentRatio: largeur,
                      //       motion: ScrollMotion(),
                      //       children: [
                      //         SlidableAction(
                      //           onPressed: (BuildContext context) {
                      //             // Navigator.of(context).push(MaterialPageRoute(
                      //             //   builder: (ctx) => Edit_Product(
                      //             //     produit: produit,
                      //             //     specifiquefournisseur: fournisseur,
                      //             //   ),
                      //             // ));
                      //           },
                      //           backgroundColor: Colors.blue,
                      //           icon: Icons.edit,
                      //           label: 'Editer',
                      //         ),
                      //       ],
                      //     ),
                      child: Card(
                        child: ListTile(
                            onTap: () {
                              Navigator.of(context).push(MaterialPageRoute(
                                builder: (ctx) =>
                                    ProduitDetailPage(produit: produit!),
                              ));
                            },
                            onLongPress: () {
                              _deleteProduit(context, produit!);
                            },
                            leading: produit!.image == null ||
                                    produit!.image!.isEmpty
                                ? CircleAvatar(
                                    child: Icon(
                                    Icons.image_not_supported,
                                  ))
                                : CircleAvatar(
                                    backgroundImage: CachedNetworkImageProvider(
                                      produit.image!,
                                      errorListener: (error) =>
                                          Icon(Icons.error),
                                    ),
                                  ),
                            title: Text(produit.nom),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Text(
                                //   'A: ${produit.prixAchat.toStringAsFixed(2)}\nB: ${(produit.prixVente - produit.prixAchat).toStringAsFixed(2)} ',
                                // ),
                                Text('ID : ${produit.id} QR : ${produit.qr}'),
                                produit.crud.target?.dateCreation != null && produit.crud.target?.derniereModification != null
                                    ? Text(
                                  'Créer le ${produit.crud.target!.dateCreation!.day}-${produit.crud.target!.dateCreation!.month}-${produit.crud.target!.dateCreation!.year}  Modifié ${timeago.format(produit.crud.target!.derniereModification, locale: 'fr')}',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w300),
                                )
                                    : SizedBox.shrink(),

                                // produit.fournisseurs.isEmpty
                                //     ? Container()
                                //     : Wrap(
                                //         spacing:
                                //             6.0, // Espace horizontal entre les éléments
                                //         runSpacing:
                                //             4.0, // Espace vertical entre les lignes
                                //         children: produit.fournisseurs
                                //             .map((fournisseurL) {
                                //           // print(fournisseurL.id);
                                //           // print(fournisseur.id);
                                //
                                //           return InkWell(
                                //             onTap: () {
                                //               Navigator.of(context).push(
                                //                   MaterialPageRoute(
                                //                       builder: (ctx) =>
                                //                           ProduitsFournisseurPage(
                                //                             fournisseur:
                                //                                 fournisseur,
                                //                           )));
                                //             },
                                //             child: fournisseur.id ==
                                //                     fournisseurL.id
                                //                 ? Container()
                                //                 : Chip(
                                //                     shadowColor: Colors.black,
                                //                     backgroundColor:
                                //                         Theme.of(context)
                                //                             .chipTheme
                                //                             .backgroundColor,
                                //                     labelStyle: TextStyle(
                                //                       color: Theme.of(context)
                                //                           .chipTheme
                                //                           .labelStyle
                                //                           ?.color,
                                //                     ),
                                //                     side: BorderSide.none,
                                //                     shape: RoundedRectangleBorder(
                                //                         borderRadius:
                                //                             BorderRadius.all(
                                //                                 Radius.circular(
                                //                                     10))),
                                //                     padding: EdgeInsets.zero,
                                //                     label: Text(
                                //                       fournisseurL.nom,
                                //                       style: TextStyle(
                                //                           fontSize: 10),
                                //                     ),
                                //                   ),
                                //           );
                                //         }).toList(),
                                //       ),
                              ],
                            ),
                            trailing: Text(
                              '${produit.prixVente.toStringAsFixed(2)}',
                              style: TextStyle(fontSize: 20),
                            )),
                      ),
                      //  ),
                    );

                    //   ListTile(
                    //   onLongPress: () {
                    //     _deleteProduit(context, produit);
                    //   },
                    //   onTap: () {
                    //     Navigator.of(context).push(
                    //       MaterialPageRoute(
                    //         builder: (context) => ProduitsFournisseurPage(
                    //           fournisseur: fournisseur,
                    //         ),
                    //       ),
                    //     );
                    //   },
                    //   title: Text(produit.nom),
                    //   subtitle: Text(
                    //     'Prix: ${produit.prixVente.toStringAsFixed(2)} €',
                    //   ),
                    // );
                  },
                  childCount: produits.length,
                ),
              );
            },
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 50,
            ),
          ),
        ],
      ),
      // floatingActionButton: FloatingActionButton(
      //   onPressed: () {
      //     Navigator.of(context).push(MaterialPageRoute(
      //         builder: (_) =>
      //             EditProduitScreen(specifiquefournisseur: fournisseur)));
      //   },
      //   child: Icon(Icons.add),
      // ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: () {
              //_selectExistingProducts(context, commerceProvider);
            },
            child: Icon(Icons.add_shopping_cart),
            heroTag: 'selectExisting',
          ),
          SizedBox(width: 16),
          FloatingActionButton(
            onPressed: () {
              Navigator.of(context)
                  .push(MaterialPageRoute(builder: (_) => addProduct()));
            },
            child: Icon(Icons.add),
            heroTag: 'addNew',
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  // void _selectExistingProducts(
  //     BuildContext context, CommerceProvider provider) async {
  //   final List<Produit> allProduits = await provider.rechercherProduits('');
  //   final List<Produit>? selectedProduits = await Navigator.of(context).push(
  //     MaterialPageRoute(
  //       builder: (context) => SelectProductsPage(
  //         allProduits: allProduits,
  //         initiallySelectedProduits: fournisseur.produits.toList(),
  //         fournisseur: fournisseur,
  //       ),
  //     ),
  //   );

  // if (selectedProduits != null) {
  //   provider.ajouterProduitsExistantsAuFournisseur(
  //       fournisseur, selectedProduits);
  // }
  //}

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
              Text('Confirmer la suppression',
                  style: TextStyle(fontSize: 20.0)),
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
                    label: Text('Annuler'),
                    icon: Icon(Icons.cancel),
                  ),
                  ElevatedButton.icon(
                      onPressed: () {
                        context
                            .read<CommerceProvider>()
                            .supprimerProduit(produit);

                        final produitProvider = Provider.of<CommerceProvider>(
                            context,
                            listen: false);
                        // produitProvider.supprimerProduit(produit);
                        // produitProvider.supprimerProduitDuFournisseur(
                        //     fournisseur, produit);
                        // print(fournisseur.id);
                        print(produit.id);
                        print('deleted');
                        Navigator.of(context).pop();
                      },
                      label: Text(
                        'Supprimer',
                        style: TextStyle(color: Colors.white),
                      ),
                      icon: Icon(Icons.delete),
                      style: ButtonStyle(
                        iconColor: WidgetStateProperty.all<Color>(Colors.white),
                        backgroundColor:
                            WidgetStateProperty.all<Color>(Colors.red),
                      ))
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
}

class SelectProductsPage extends StatefulWidget {
  final List<Produit> allProduits;
  final List<Produit> initiallySelectedProduits;
  final Fournisseur fournisseur;

  SelectProductsPage({
    required this.allProduits,
    required this.initiallySelectedProduits,
    required this.fournisseur,
  });

  @override
  _SelectProductsPageState createState() => _SelectProductsPageState();
}

class _SelectProductsPageState extends State<SelectProductsPage> {
  late Set<int> selectedProductIds;
  String searchQuery = '';
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    selectedProductIds =
        Set.from(widget.initiallySelectedProduits.map((p) => p.id));
  }

  void updateSelection(Produit produit, bool? isSelected) {
    setState(() {
      if (isSelected == true) {
        selectedProductIds.add(produit.id);
      } else {
        selectedProductIds.remove(produit.id);
        supprimerProduit(produit);
      }
    });
  }

  void supprimerProduit(Produit produit) {
    final provider = Provider.of<CommerceProvider>(context, listen: false);
    provider.supprimerProduitDuFournisseur(widget.fournisseur, produit);
    print(
        'Produit supprimé - Fournisseur ID: ${widget.fournisseur.id}, Produit ID: ${produit.id}');
  }

  List<Produit> get filteredProduits {
    return widget.allProduits
        .where((produit) {
          final lowercaseQuery = searchQuery.toLowerCase();
          return produit.nom.toLowerCase().contains(lowercaseQuery) ||
              produit.id.toString().contains(lowercaseQuery);
        })
        .toList()
        .reversed
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sélectionner des produits'),
        actions: [
          IconButton(
            icon: Icon(Icons.check),
            onPressed: () {
              Navigator.of(context).pop(widget.allProduits
                  .where((p) => selectedProductIds.contains(p.id))
                  .toList());
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                labelText: 'Rechercher par Nom de Produit ou ID',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filteredProduits.length,
              itemBuilder: (context, index) {
                final produit = filteredProduits[index];
                final isSelected = selectedProductIds.contains(produit.id);
                return ListTile(
                  title: Text(produit.nom),
                  subtitle: Text(
                      'ID: ${produit.id} - Prix: ${produit.prixVente.toStringAsFixed(2)} DZD'),
                  trailing: Checkbox(
                    value: isSelected,
                    onChanged: (bool? value) => updateSelection(produit, value),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class MySliverToBoxAdapter extends StatelessWidget {
  const MySliverToBoxAdapter({
    super.key,
    required this.fournisseur,
  });

  final Fournisseur fournisseur;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            SizedBox(height: 8),
            Text(fournisseur.phone == null && fournisseur.phone == 0
                ? ''
                : 'Téléphone: ${fournisseur.phone ?? "N/A"}'),
            Text(fournisseur.adresse == null && fournisseur.adresse == ''
                ? ''
                : 'Adresse: ${fournisseur.adresse ?? "N/A"}'),
            SizedBox(
              height: 10,
            ),
            Divider(),
            SizedBox(
              height: 20,
            ),
            Text(
              'Liste Des Produits:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            ElevatedButton(
              onPressed: () {
                final fournisseurProvider =
                    Provider.of<CommerceProvider>(context, listen: false);
                fournisseurProvider.ajouterProduitsAleatoiresPourFournisseur(
                    fournisseur, 5); // Ajouter 5 produits aléatoires
              },
              child: Icon(Icons.add),
            )
          ],
        ),
      ),
    );
  }
}

class MySliverAppBar extends StatelessWidget {
  const MySliverAppBar({
    super.key,
    required this.fournisseur,
  });

  final Fournisseur fournisseur;

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 200.0,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.parallax,
        background: Stack(
          alignment: Alignment.bottomCenter,
          fit: StackFit.expand,
          children: [
            // Container(
            //   decoration: BoxDecoration(
            //     image: DecorationImage(
            //       image: fournisseur.produits.isNotEmpty &&
            //               fournisseur.produits.first.image != null
            //           ? CachedNetworkImageProvider(
            //               fournisseur.produits.first.image!)
            //           : CachedNetworkImageProvider(
            //               'https://picsum.photos/200/300?random=${(fournisseur.id) + 5}',
            //             ),
            //       fit: BoxFit.cover,
            //       filterQuality: FilterQuality.low,
            //     ),
            //   ),
            // ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
                  stops: [0.0, 1.0],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Container(),
                  ),
                  Chip(
                    label: Text('Fournisseur'),
                  ),
                  Text(
                    //  'Produits du Fournisseur '
                    'ID : ${fournisseur.id}\n' + fournisseur.nom,
                    //overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24, // Taille du texte ajustée
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            // Positioned(
            //     top: 20,
            //     left: 10,
            //     child: Chip(
            //       label: Text('Fournisseur'),
            //     )),
            // Positioned(
            //   bottom: 10,
            //   left: 16,
            //   right: 16,
            //   child: Text(
            //     //  'Produits du Fournisseur '
            //     'ID : ${fournisseur.id}\n' + fournisseur.nom,
            //     //overflow: TextOverflow.ellipsis,
            //     style: TextStyle(
            //       color: Colors.white,
            //       fontSize: 24, // Taille du texte ajustée
            //       fontWeight: FontWeight.bold,
            //     ),
            //   ),
            // ),
          ],
        ),
      ),
    );
  }
}

class AddFournisseurForm extends StatefulWidget {
  @override
  _AddFournisseurFormState createState() => _AddFournisseurFormState();
}

class _AddFournisseurFormState extends State<AddFournisseurForm> {
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  final _phoneController = TextEditingController();
  final _adresseController = TextEditingController();
  final _creationController = TextEditingController();
  final _modificationController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context)
            .viewInsets
            .bottom, // Permet de remonter le BottomSheet lorsque le clavier apparaît
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Ajouter un Fournisseur',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _nomController,
                  decoration: InputDecoration(labelText: 'Nom'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer un nom';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(labelText: 'Phone'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer un Tel';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _adresseController,
                  decoration: InputDecoration(labelText: 'Adresse'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer une adresse';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('Annuler'),
              ),
              TextButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    final fournisseur = Fournisseur(
                      qr: '',
                      nom: _nomController.text,
                      phone: _phoneController.text,
                      adresse: _adresseController.text,
                      derniereModification: DateTime.now(),
                    );
                    context
                        .read<CommerceProvider>()
                        .addFournisseur(fournisseur);
                    Navigator.of(context).pop();
                  }
                },
                child: Text('Ajouter'),
              ),
            ],
          ),
          SizedBox(height: 60),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nomController.dispose();
    _phoneController.dispose();
    _adresseController.dispose();
    _creationController.dispose();
    _modificationController.dispose();
    super.dispose();
  }
}

void _editFournisseur(BuildContext context, Fournisseur fournisseur) {
  final _nomController = TextEditingController(text: fournisseur.nom);
  final _phoneController = TextEditingController(text: fournisseur.phone);
  final _adresseController = TextEditingController(text: fournisseur.adresse);
  final _creationController = TextEditingController(
      text: fournisseur.crud.target!.dateCreation.toString());

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (context) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Modifier un Fournisseur',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          Form(
            child: Column(
              children: [
                TextFormField(
                  controller: _nomController,
                  decoration: InputDecoration(labelText: 'Nom'),
                ),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(labelText: 'Phone'),
                ),
                TextFormField(
                  controller: _adresseController,
                  decoration: InputDecoration(labelText: 'Adresse'),
                ),
              ],
            ),
          ),
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('Annuler'),
              ),
              TextButton(
                onPressed: () {
                  if (_nomController.text.isNotEmpty &&
                      _phoneController.text.isNotEmpty &&
                      _adresseController.text.isNotEmpty) {
                    final updatedFournisseur = Fournisseur(
                      qr: '',
                      nom: _nomController.text,
                      phone: _phoneController.text,
                      adresse: _adresseController.text,
                      derniereModification: DateTime.now(),
                    )..crud.target = Crud(
                        createdBy: 1,
                        updatedBy: 1,
                        deletedBy: 1,
                        dateCreation: DateTime.parse(_creationController.text),
                        derniereModification: DateTime.now(),
                        dateDeleting: null,
                      );
                    context
                        .read<CommerceProvider>()
                        .updateFournisseur(fournisseur.id, updatedFournisseur);
                    Navigator.of(context).pop();
                  }
                },
                child: Text('Modifier'),
              ),
            ],
          ),
          SizedBox(height: 50),
        ],
      ),
    ),
  );
}

void _deleteFournisseur(BuildContext context, Fournisseur fournisseur) {
  showModalBottomSheet(
    context: context,
    builder: (BuildContext context) {
      return Container(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(15.0),
              child: Text(
                'Confirmer la suppression',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            FittedBox(
                child: Text(
                    'Êtes-vous sûr de vouloir supprimer ce fournisseur ?')),
            SizedBox(
              height: 15,
            ),
            Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  label: Text('Annuler'),
                  icon: Icon(Icons.cancel),
                ),
                ElevatedButton.icon(
                    onPressed: () {
                      context
                          .read<CommerceProvider>()
                          .supprimerFournisseur(fournisseur);
                      Navigator.of(context).pop();
                    },
                    label: Text(
                      'Supprimer',
                      style: TextStyle(color: Colors.white),
                    ),
                    icon: Icon(Icons.delete),
                    style: ButtonStyle(
                      iconColor: WidgetStateProperty.all<Color>(Colors.white),
                      backgroundColor:
                          WidgetStateProperty.all<Color>(Colors.red),
                    ))
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

class FournisseurSearchDelegateMain extends SearchDelegate {
  final List<Fournisseur> fournisseurs;

  FournisseurSearchDelegateMain(this.fournisseurs);

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(Icons.clear),
        onPressed: () {
          query = '';
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
    final results = fournisseurs.where((fournisseur) {
      final queryLower = query.toLowerCase();
      final nomLower = fournisseur.nom.toLowerCase();
      return nomLower.contains(queryLower) ||
          fournisseur.id.toString().contains(query);
    }).toList();

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final fournisseur = results[index];
        return ListTile(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) =>
                    ProduitsFournisseurPage(fournisseur: fournisseur),
              ),
            );
          },
          title: Text(fournisseur.nom),
          // subtitle: Text('${fournisseur.produits.length} produits'),
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final suggestions = fournisseurs.where((fournisseur) {
      final queryLower = query.toLowerCase();
      final nomLower = fournisseur.nom.toLowerCase();
      return nomLower.contains(queryLower) ||
          fournisseur.id.toString().contains(query);
    }).toList();

    return ListView.builder(
      itemCount: suggestions.length,
      itemBuilder: (context, index) {
        final fournisseur = suggestions[index];
        return ListTile(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) =>
                    ProduitsFournisseurPage(fournisseur: fournisseur),
              ),
            );
          },
          title: Text('${fournisseur.id} ${fournisseur.nom}'),
          // trailing: Text('${fournisseur.produits.length} Produits'),
        );
      },
    );
  }
}
