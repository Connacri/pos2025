import 'package:calendar_timeline/calendar_timeline.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:intl/intl.dart';
import 'package:kenzy/objectBox/classeObjectBox.dart';
import 'package:kenzy/objectBox/pages/addProduct.dart';
import 'package:provider/provider.dart';
import '../../Entity.dart';
import '../../MyProviders.dart';
import 'package:flutter/services.dart';

import '../FactureListScreen.dart';
import 'FacturePage.dart';

class FacturesListPage extends StatefulWidget {
  // final Function(Document) onFactureSelected;
  //
  // FacturesListPage({required this.onFactureSelected});

  @override
  State<FacturesListPage> createState() => _FacturesListPageState();
}

class _FacturesListPageState extends State<FacturesListPage> {
  DateTime? _startDate;
  NativeAd? _nativeAd;
  bool _nativeAdIsLoaded = false;
  DateTime? _endDate;

  @override
  void dispose() {
    super.dispose();
    _nativeAd?.dispose();
  }

  Map<String, dynamic> _totals = {
    'totalTTC': 0.0,
    'totalImpayes': 0.0,
    'totalTVA': 0.0
  };

  FacturePage? currentFacturePage;

  // Fonction pour sélectionner la date de début
  Future<void> _selectStartDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _startDate) {
      setState(() {
        _startDate = picked;
      });
    }
  }

  // Fonction pour sélectionner la date de fin
  Future<void> _selectEndDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _endDate) {
      setState(() {
        _endDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final commerceProvider = Provider.of<CommerceProvider>(context);
    return Consumer<CartProvider>(builder: (context, cartProvider, child) {
      final factures = cartProvider.factures.reversed.toList();

      // Fonction pour calculer les totaux
      void _calculateTotals() {
        if (_startDate != null && _endDate != null) {
          setState(() {
            _totals =
                cartProvider.calculateTotalsForInterval(_startDate!, _endDate!);
          });
        }
      }

      return Scaffold(
        appBar: AppBar(
          title: Consumer<CartProvider>(
            builder: (context, cartProvider, child) {
              return Text('${cartProvider.factureCount} Factures');
            },
          ),
          actions: [
            IconButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.grey[300],
                disabledBackgroundColor: Colors.grey[300],
                disabledForegroundColor: Colors.grey[600],
              ),
              icon: Icon(Icons.clear_all_outlined),
              onPressed: () async {
                await cartProvider.deleteAllFactures();

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Liste de Factures Vider avec succès!'),
                    backgroundColor: Colors.red,
                  ),
                );
              },
            ),
            SizedBox(
              width: 50,
            ),
          ],
        ),
        body: factures.isEmpty
            ? Center(child: Text('Aucune facture trouvée'))
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            TextButton(
                              onPressed: () => _selectStartDate(context),
                              child: Text(
                                _startDate == null
                                    ? 'Sélectionner la date de début'
                                    : 'Date de début : ${DateFormat.yMd().format(_startDate!)}',
                              ),
                            ),
                            TextButton(
                              onPressed: () => _selectEndDate(context),
                              child: Text(
                                _endDate == null
                                    ? 'Sélectionner la date de fin'
                                    : 'Date de fin : ${DateFormat.yMd().format(_endDate!)}',
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: _calculateTotals,
                          child: Text('Calculer les totaux'),
                        ),
                        SizedBox(height: 010),
                        if (_startDate != null && _endDate != null)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                  'Total TTC: ${_totals['totalTTC'].toStringAsFixed(2)} DZD',
                                  style: TextStyle(color: Colors.green)),
                              Text(
                                  'Total Impayés: ${_totals['totalImpayes'].toStringAsFixed(2)} DZD',
                                  style: TextStyle(color: Colors.red)),
                              Text(
                                  'Total TVA: ${_totals['totalTVA'].toStringAsFixed(2)} DZD',
                                  style: TextStyle(color: Colors.blue)),
                            ],
                          ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        // Réinitialiser la facture via le provider
                        //  cartProvider.clearCart();
                      },
                      child: ListView.builder(
                        itemCount: factures.length,
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

                          final facture = factures[index];
                          final client = facture.client.target;
                          return Column(
                            children: [
                              Card(
                                child: ListTile(
                                  isThreeLine: false,
                                  dense: true,
                                  leading: GestureDetector(
                                    onTap: () =>
                                        Navigator.of(context).push<void>(
                                      MaterialPageRoute<void>(
                                        builder: (BuildContext context) =>
                                            new FactureDetailPage(
                                                facture: facture,
                                                cartProvider: cartProvider,
                                                commerceProvider:
                                                    commerceProvider),
                                      ),
                                    ),
                                    child: CircleAvatar(
                                      child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: FittedBox(
                                            child: Text('${facture.id}')),
                                      ),
                                    ),
                                  ),
                                  title: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Client ${client?.nom ?? 'Unknown'}',
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text('Impayer : ${facture.impayer}',
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                              color: Colors.redAccent,
                                              fontSize: 12)),
                                    ],
                                  ),
                                  // subtitle:
                                  onLongPress: () {
                                    Provider.of<CartProvider>(context,
                                            listen: false)
                                        .deleteFacture(facture);
                                  },
                                  // onTap: () {
                                  //   Navigator.of(context).push(
                                  //     MaterialPageRoute(
                                  //       builder: (context) => new FacturePage(
                                  //           factureToEdit: facture),
                                  //       // FactureDetailPage(
                                  //       //   facture: facture,
                                  //       //   cartProvider: cartProvider,
                                  //       //   commerceProvider: commerceProvider,
                                  //       // ),
                                  //     ),
                                  //   );
                                  // },
                                  onTap: () {
                                    // Sélectionner la facture dans le provider
                                    cartProvider.selectFacture(facture);
                                  },

                                  trailing: Text(
                                    '${(_calculateTotal(facture) * 1.19).toStringAsFixed(2)} DZD',
                                    style: TextStyle(fontSize: 20),
                                  ),
                                ),
                              ),
                              Text(
                                DateFormat('EEE dd MMM yyyy HH:mm', 'fr')
                                    .format(
                                        DateTime.parse(facture.date.toString()))
                                    .capitalize(),
                                //'${facture.date}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight
                                      .w300, /*fontStyle: FontStyle.italic*/
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
      );
    });
  }

  double _calculateTotal(Document facture) {
    return facture.lignesDocument
        .fold(0, (sum, item) => sum + item.prixUnitaire * item.quantite);
  }
}
