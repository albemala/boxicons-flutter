import 'dart:io';

import 'package:http/http.dart';

/*
* Script used to download the latest icons from https://github.com/atisawd/boxicons
*
* Usage:
*   cd scripts
*   dart ./update-icons.dart
*/
Future<void> main() async {
  // Download latest boxicons.ttf file into assets folder
  await _downloadBoxiconsFontFile();
  // Download boxicons.css and generate icons file
  await _generateIconsFile();
}

Future<void> _downloadBoxiconsFontFile() async {
  const uri = "https://github.com/atisawd/boxicons/blob/master/fonts/boxicons.ttf?raw=true";
  final response = await get(Uri.parse(uri));
  if (response.statusCode != 200) return;

  final file = File("../assets/boxicons.ttf");
  await file.writeAsBytes(response.bodyBytes);
}

Future<void> _generateIconsFile() async {
  const uri = "https://github.com/atisawd/boxicons/blob/master/css/boxicons.css?raw=true";
  final response = await get(Uri.parse(uri));
  if (response.statusCode != 200) return;

  final css = response.body;
  /*
    Extract all icon data from css

    Examples of icon data:
  .bx-flickr-square:before {
    content: "\e936";
  }
  .bx-flutter:before {
    content: "\e937";
  }
  .bx-foursquare:before {
    content: "\e938";
  }

    Examples of extracted data:

    "flickr-square" : "e936"
    "flutter" : "e937"
    "foursquare" : "e938"
  */
  final regularIcons = RegExp(r'\.bx-([a-z0-9-]+):before\s*{\s*content:\s*"\\([a-z0-9]+)";\s*}').allMatches(css);
  final solidIcons = RegExp(r'\.bxs-([a-z0-9-]+):before\s*{\s*content:\s*"\\([a-z0-9]+)";\s*}').allMatches(css);
  final logoIcons = RegExp(r'\.bxl-([a-z0-9-]+):before\s*{\s*content:\s*"\\([a-z0-9]+)";\s*}').allMatches(css);

  final regularIconsCode = regularIcons.map((match) {
    final iconName = match.group(1)?.replaceAll("-", "_") ?? "";
    final iconData = match.group(2) ?? "";
    return "  static const IconData bx_${iconName}_regular = IconData(0x$iconData, fontFamily: iconFont, fontPackage: iconFontPackage, matchTextDirection: true);";
  }).join("\n");
  final solidIconsCode = solidIcons.map((match) {
    final iconName = match.group(1)?.replaceAll("-", "_") ?? "";
    final iconData = match.group(2) ?? "";
    return "  static const IconData bx_${iconName}_solid = IconData(0x$iconData, fontFamily: iconFont, fontPackage: iconFontPackage, matchTextDirection: true);";
  }).join("\n");
  final logoIconsCode = logoIcons.map((match) {
    final iconName = match.group(1)?.replaceAll("-", "_") ?? "";
    final iconData = match.group(2) ?? "";
    return "  static const IconData bx_${iconName}_logo = IconData(0x$iconData, fontFamily: iconFont, fontPackage: iconFontPackage, matchTextDirection: true);";
  }).join("\n");

  // Write icons to file
  final file = File("../lib/boxicons.dart");
  await file.writeAsString("""
library boxicons;

import 'package:flutter/widgets.dart';

class BoxIcons {
  BoxIcons._();
  
  static const String iconFont = 'boxicons';
  static const String iconFontPackage = 'boxicons';
  
$regularIconsCode
$solidIconsCode
$logoIconsCode
}
      """);
}
