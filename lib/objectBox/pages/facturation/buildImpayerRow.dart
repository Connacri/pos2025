import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../MyProviders.dart';

class buildImpayerRow extends StatefulWidget {
  buildImpayerRow({
    Key? key,
    required isEditingImpayer,
    required localImpayer,
    required TextEditingController impayerController,
  })  : _impayerController = impayerController,
        _isEditingImpayer = isEditingImpayer,
        _localImpayer = localImpayer,
        super(key: key);

  final TextEditingController _impayerController;

  bool _isEditingImpayer;

  double _localImpayer;

  @override
  State<buildImpayerRow> createState() => _buildImpayerRowState();
}

class _buildImpayerRowState extends State<buildImpayerRow> {
  @override
  Widget build(BuildContext context) {
    return Consumer<CartProvider>(builder: (context, cartProvider, child) {
      double impayer = 0;
      // widget.factureToEdit != null
      //    ?
      impayer = cartProvider.facture.impayer ?? 0.0;
      widget._localImpayer = impayer;

      // Synchronisation du TextEditingController avec le Provider
      // if (_impayerController.text != impayer.toStringAsFixed(2)) {
      widget._impayerController.text = impayer.toStringAsFixed(2);
      //}

      return LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final isCompact = constraints.maxWidth < 700;

          return Container(
            width: isCompact
                ? MediaQuery.of(context).size.width * 0.8
                : MediaQuery.of(context).size.width * 1 / 6,
            child: Row(
              children: [
                widget._isEditingImpayer
                    ? Flexible(
                        child: TextFormField(
                          controller: widget._impayerController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Impayés',
                            border: OutlineInputBorder(),
                            suffixText: 'DZD',
                          ),

                          // onChanged: (value) {
                          //   setState(() {
                          //     _localImpayer = double.tryParse(value) ?? 0.00;
                          //   });
                          // },
                          onTap: () {
                            // Effacer le champ si la valeur initiale est 0
                            if (widget._impayerController.text == '0' ||
                                widget._impayerController.text == '0.0' ||
                                widget._impayerController.text == '0.00') {
                              widget._impayerController.clear();
                            }
                          },
                          autofocus: true,
                        ),
                      )
                    : Text(
                        'Impayés: ${impayer.toStringAsFixed(2)} DZD',
                        style:
                            TextStyle(fontSize: 16, color: Colors.deepOrange),
                      ),
                IconButton(
                  icon: Icon(
                    widget._isEditingImpayer ? Icons.check : Icons.edit,
                    color:
                        widget._isEditingImpayer ? Colors.green : Colors.blue,
                    size: widget._isEditingImpayer ? 22 : 17,
                  ),
                  onPressed: () {
                    setState(() {
                      if (widget._isEditingImpayer) {
                        // Récupérer la valeur saisie et mettre à jour le Provider
                        final newImpayer =
                            double.tryParse(widget._impayerController.text) ??
                                widget._localImpayer;
                        cartProvider.updateImpayer(newImpayer);
                        widget._localImpayer =
                            newImpayer; // Met à jour la valeur locale
                      } else {
                        // Pré-remplir le TextFormField avec la valeur locale
                        widget._impayerController.text =
                            widget._localImpayer.toStringAsFixed(2);
                      }
                      widget._isEditingImpayer = !widget
                          ._isEditingImpayer; // Alterner entre édition et lecture
                    });
                  },
                ),
              ],
            ),
          );
        },
      );
    });
  }
}
