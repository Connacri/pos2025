import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:country_flags/country_flags.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class FlagDetector extends StatefulWidget {
  final String barcode;
  final double height;
  final double width;

  const FlagDetector(
      {Key? key,
      required this.barcode,
      required this.height,
      required this.width})
      : super(key: key);

  @override
  _FlagDetectorState createState() => _FlagDetectorState();
}

class _FlagDetectorState extends State<FlagDetector> {
  late Future<List<dynamic>> countries;
  String _detectedCountry = "Inconnu";
  String _detectedIsoCode = "";

  @override
  void initState() {
    super.initState();
    countries = loadCountries();
    detectCountry(widget.barcode);
  }

  @override
  void didUpdateWidget(FlagDetector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.barcode != oldWidget.barcode) {
      detectCountry(widget.barcode);
    }
  }

  Future<List<dynamic>> loadCountries() async {
    String jsonString = await rootBundle.loadString('assets/countries.json');
    Map<String, dynamic> jsonResponse = jsonDecode(jsonString);
    if (jsonResponse['pays'] != null) {
      return jsonResponse['pays'];
    }
    return [];
  }

  // void detectCountry(String barcode) {
  //   countries.then((data) {
  //     setState(() {
  //       String prefix =  barcode.length >= 3 ? barcode.substring(0, 3) : barcode;
  //       Map<String, String> result = findCountry(prefix, data);
  //       _detectedCountry = result['name'] ?? "Inconnu";
  //       _detectedIsoCode = result['iso'] ?? "";
  //     });
  //   });
  // }
  void detectCountry(String barcode) {
    countries.then((data) {
      setState(() {
        String prefix;
        if (barcode.startsWith('1613')) {
          prefix = '613';
        } else {
          prefix = barcode.length >= 3 ? barcode.substring(0, 3) : barcode;
        }

        Map<String, String> result = findCountry(prefix, data);
        _detectedCountry = result['name'] ?? "Inconnu";
        _detectedIsoCode = result['iso'] ?? "";
      });
    });
  }

  Map<String, String> findCountry(String prefix, List<dynamic> countries) {
    if (prefix.isEmpty) {
      return {'name': "Inconnu", 'iso': ""};
    }
    int code = int.tryParse(prefix) ?? -1;
    if (code == -1) {
      return {'name': "Inconnu", 'iso': ""};
    }
    for (var country in countries) {
      for (String range in country['prefixes']) {
        if (range.contains('-')) {
          List<String> parts = range.split('-');
          int start = int.parse(parts[0]);
          int end = int.parse(parts[1]);
          if (code >= start && code <= end) {
            return {'name': country['nom'], 'iso': country['iso']};
          }
        } else {
          if (code == int.parse(range)) {
            return {'name': country['nom'], 'iso': country['iso']};
          }
        }
      }
    }
    return {'name': "Inconnu", 'iso': ""};
  }

  @override
  Widget build(BuildContext context) {
    return CountryDisplay(
      country: _detectedCountry,
      isoCode: _detectedIsoCode,
      height: widget.height,
      width: widget.width,
    );
  }
}

class CountryDisplay extends StatelessWidget {
  final String country;
  final String isoCode;
  final double height;
  final double width;
  const CountryDisplay({
    Key? key,
    required this.country,
    required this.isoCode,
    required this.height,
    required this.width,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        isoCode.isNotEmpty
            ? FittedBox(
                child: CountryFlag.fromCountryCode(
                  isoCode,
                  height: height,
                  width: width,
                  shape: const RoundedRectangle(6),
                ),
              )
            : FittedBox(
                child: Container(
                    height: height,
                    width: width,
                    child: Icon(
                      FontAwesomeIcons.globe,
                      size: 20,
                    )),
              ),
        const SizedBox(width: 10),
        FittedBox(
          child: Text(
              isoCode.isNotEmpty ? 'Made in ' + country : 'Pays Inconnu',
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyLarge),
        ),
      ],
    );
  }
}

class CircularFlagDetector extends StatelessWidget {
  final String barcode;
  final double size;

  const CircularFlagDetector({
    Key? key,
    required this.barcode,
    this.size = 40,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: Container(
        width: size,
        height: size,
        child: FlagDetectorOnlyFlag(
          barcode: barcode,
          height: size,
          width: size,
        ),
      ),
    );
  }
}

class FlagDetectorOnlyFlag extends StatefulWidget {
  final String barcode;
  final double height;
  final double width;

  const FlagDetectorOnlyFlag({
    Key? key,
    required this.barcode,
    required this.height,
    required this.width,
  }) : super(key: key);

  @override
  _FlagDetectorOnlyFlagState createState() => _FlagDetectorOnlyFlagState();
}

class _FlagDetectorOnlyFlagState extends State<FlagDetectorOnlyFlag> {
  late Future<List<dynamic>> countries;
  String _detectedIsoCode = "";

  @override
  void initState() {
    super.initState();
    countries = loadCountries();
    detectCountry(widget.barcode);
  }

  @override
  void didUpdateWidget(FlagDetectorOnlyFlag oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.barcode != oldWidget.barcode) {
      detectCountry(widget.barcode);
    }
  }

  Future<List<dynamic>> loadCountries() async {
    String jsonString = await DefaultAssetBundle.of(context)
        .loadString('assets/countries.json');
    Map<String, dynamic> jsonResponse = jsonDecode(jsonString);
    return jsonResponse['pays'] ?? [];
  }

  void detectCountry(String barcode) {
    countries.then((data) {
      setState(() {
        String prefix = barcode.startsWith('1613')
            ? '613'
            : (barcode.length >= 3 ? barcode.substring(0, 3) : barcode);

        Map<String, String> result = findCountry(prefix, data);
        _detectedIsoCode = result['iso'] ?? "";
      });
    });
  }

  Map<String, String> findCountry(String prefix, List<dynamic> countries) {
    if (prefix.isEmpty) {
      return {'name': "Inconnu", 'iso': ""};
    }
    int code = int.tryParse(prefix) ?? -1;
    if (code == -1) {
      return {'name': "Inconnu", 'iso': ""};
    }
    for (var country in countries) {
      for (String range in country['prefixes']) {
        if (range.contains('-')) {
          List<String> parts = range.split('-');
          int start = int.parse(parts[0]);
          int end = int.parse(parts[1]);
          if (code >= start && code <= end) {
            return {'name': country['nom'], 'iso': country['iso']};
          }
        } else {
          if (code == int.parse(range)) {
            return {'name': country['nom'], 'iso': country['iso']};
          }
        }
      }
    }
    return {'name': "Inconnu", 'iso': ""};
  }

  @override
  Widget build(BuildContext context) {
    return CountryDisplayOnlyFlag(
      isoCode: _detectedIsoCode,
      height: widget.height,
      width: widget.width,
    );
  }
}

class CountryDisplayOnlyFlag extends StatelessWidget {
  final String isoCode;
  final double height;
  final double width;

  const CountryDisplayOnlyFlag({
    Key? key,
    required this.isoCode,
    required this.height,
    required this.width,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      child: isoCode.isNotEmpty
          ? FittedBox(
              child: CountryFlag.fromCountryCode(
                isoCode,
                height: height,
                width: width,
              ),
            )
          : FittedBox(
              child: Container(
                height: height,
                width: width,
                child: Icon(
                  FontAwesomeIcons.globe,
                  size: 20,
                ),
              ),
            ),
    );
  }
}
