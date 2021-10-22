import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crmap_app/region.dart';
import 'package:flutter/services.dart' show rootBundle;

void main() async {
  RegionList rl;
  Future<List<Region>> regions = readFileByLines();
  regions.then((value) => rl = RegionList(value));

  await Future.delayed(Duration(milliseconds: 1));
  print("Found " +
      rl.regions.length.toString() +
      " regions. MinX " +
      rl.minX.toString() +
      " MaxX " +
      rl.maxX.toString() +
      "");
}

Future<List<Region>> readFileByLines() async {
  File file = new File('./assets/Andune.cr');
  Uint8List inputStream = file.readAsBytesSync();

  return readFileByLinesForStream(inputStream) as Future<List<Region>>;
}

List<Region> readFileByLinesForStream(Uint8List inputStream) {
  List<Region> regionList = [];
  // Future<List<Region>> returnList = regionList as Future<List<Region>>;
  Region region;
  int x = -9999;
  int y = -9999;
  String id = "";
  String name = "";
  String terrain = "";
  String description = "";
  int trees = 0;
  int saplings = 0;
  int peasants = 0;
  int horses = 0;
  int silver = 0;
  int entertainment = 0;
  int recruits = 0;
  int wage = 0;
  int count = 0;

  if (inputStream == null) {
    return regionList;
  }

  List<String> lines = Utf8Decoder().convert(inputStream).split('\n');
  for (var line in lines) {
//      .transform(utf8.decoder) // Decode bytes to UTF-8.
//      .transform(new LineSplitter()) // Convert stream to individual lines.
//      .listen((String line) {
    // Process results.
    if (line.startsWith("REGION")) {
      if (regionList.length < count) {
        region = Region(id, x, y, name, terrain, description, trees, saplings,
            peasants, horses, silver, entertainment, recruits, wage);
        regionList.add(region);
        print("$count " + region.toString());
        id = "";
        name = "";
        terrain = "";
        description = "";
      }
      List<String> split = line.split(" ");
      x = int.parse(split.elementAt(1));
      y = int.parse(split.elementAt(2));
      count++;
    } else {
      List<String> split = line.split(";");
      if (split.length > 1) {
        if (split.elementAt(1).replaceAll("\r", "") == "id") {
          id = split.elementAt(0);
        }
        if (split.elementAt(1).replaceAll("\r", "") == "Terrain") {
          terrain = split.elementAt(0).replaceAll("\"", "");
        }
        if (split.elementAt(1).replaceAll("\r", "") == "Name") {
          name = split.elementAt(0).replaceAll("\"", "");
        }
        if (split.elementAt(1).replaceAll("\r", "") == "Beschr") {
          description = split.elementAt(0).replaceAll("\"", "");
        }
        if (split.elementAt(1).replaceAll("\r", "") == "Baeume") {
          trees = int.parse(split.elementAt(0).replaceAll("\"", ""));
        }
        if (split.elementAt(1).replaceAll("\r", "") == "Schoesslinge") {
          saplings = int.parse(split.elementAt(0).replaceAll("\"", ""));
        }
        if (split.elementAt(1).replaceAll("\r", "") == "Bauern") {
          peasants = int.parse(split.elementAt(0).replaceAll("\"", ""));
        }
        if (split.elementAt(1).replaceAll("\r", "") == "Pferde") {
          horses = int.parse(split.elementAt(0).replaceAll("\"", ""));
        }
        if (split.elementAt(1).replaceAll("\r", "") == "Silber") {
          silver = int.parse(split.elementAt(0).replaceAll("\"", ""));
        }
        if (split.elementAt(1).replaceAll("\r", "") == "Unterh") {
          entertainment = int.parse(split.elementAt(0).replaceAll("\"", ""));
        }
        if (split.elementAt(1).replaceAll("\r", "") == "Rekruten") {
          recruits = int.parse(split.elementAt(0).replaceAll("\"", ""));
        }
        if (split.elementAt(1).replaceAll("\r", "") == "Lohn") {
          wage = int.parse(split.elementAt(0).replaceAll("\"", ""));
        }
      }
    }
  }
  //, onDone: () {
  print('File is now closed.');
  if (regionList.length < count) {
    region = Region(id, x, y, name, terrain, description, trees, saplings,
        peasants, horses, silver, entertainment, recruits, wage);
    regionList.add(region);
    print("Last: $count " + region.toString());
  }
  // returnList =  regionList as Future<List<Region>>;
//  }, onError: (e) {
//    print(e.toString());
  // returnList = regionList as Future<List<Region>>;
//  });

  return regionList;
}

Future<List<Region>> getRegionsLocally() async {
  List<Region> regionList = [];
  Region region;
  int x = -9999;
  int y = -9999;
  String id = "";
  String name = "";
  String terrain = "";
  String description = "";
  int trees = 0;
  int saplings = 0;
  int peasants = 0;
  int horses = 0;
  int silver = 0;
  int entertainment = 0;
  int recruits = 0;
  int wage = 0;
  int count = 0;

  final data = await rootBundle.loadString('./assets/Andune.cr');

  LineSplitter ls = new LineSplitter();
  List<String> lines = ls.convert(data);
  for (var line in lines) {
    if (line.startsWith("REGION")) {
      if (regionList.length < count) {
        region = Region(id, x, y, name, terrain, description, trees, saplings,
            peasants, horses, silver, entertainment, recruits, wage);
        regionList.add(region);
        print("$count " + region.toString());
        id = "";
        name = "";
        terrain = "";
      }
      List<String> split = line.split(" ");
      x = int.parse(split.elementAt(1));
      y = int.parse(split.elementAt(2));
      count++;
    } else {
      List<String> split = line.split(";");
      if (split.length > 1) {
        if (split.elementAt(1) == "id") {
          id = split.elementAt(0);
        }
        if (split.elementAt(1) == "Terrain") {
          terrain = split.elementAt(0).replaceAll("\"", "");
        }
        if (split.elementAt(1) == "Name") {
          name = split.elementAt(0).replaceAll("\"", "");
        }
        if (split.elementAt(1) == "Beschr") {
          description = split.elementAt(0).replaceAll("\"", "");
        }
        if (split.elementAt(1) == "Baeume") {
          trees = int.parse(split.elementAt(0).replaceAll("\"", ""));
        }
        if (split.elementAt(1) == "Schoesslinge") {
          saplings = int.parse(split.elementAt(0).replaceAll("\"", ""));
        }
        if (split.elementAt(1) == "Bauern") {
          peasants = int.parse(split.elementAt(0).replaceAll("\"", ""));
        }
        if (split.elementAt(1) == "Pferde") {
          horses = int.parse(split.elementAt(0).replaceAll("\"", ""));
        }
        if (split.elementAt(1) == "Silber") {
          silver = int.parse(split.elementAt(0).replaceAll("\"", ""));
        }
        if (split.elementAt(1) == "Unterh") {
          entertainment = int.parse(split.elementAt(0).replaceAll("\"", ""));
        }
        if (split.elementAt(1) == "Rekruten") {
          recruits = int.parse(split.elementAt(0).replaceAll("\"", ""));
        }
        if (split.elementAt(1) == "Lohn") {
          wage = int.parse(split.elementAt(0).replaceAll("\"", ""));
        }
      }
    }
  }
  if (regionList.length < count) {
    region = Region(id, x, y, name, terrain, description, trees, saplings,
        peasants, horses, silver, entertainment, recruits, wage);
    regionList.add(region);
    print("Last: $count " + region.toString());
  }
  print("Found " + regionList.length.toString() + " Regions.");
  return regionList;
}
