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
  File file = new File('./assets/Andune.txt');
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
  var regionActive = false;

  if (inputStream == null) {
    return regionList;
  }

  List<String> lines = Utf8Decoder().convert(inputStream).split('\n');
  for (var line in lines) {
    if (line.startsWith("REGION")) {
      regionActive = true;
      if (regionList.length < count) {
        region = Region(id, x, y, name, terrain, description, trees, saplings,
            peasants, horses, silver, entertainment, recruits, wage);
        regionList.add(region);
        // reset to initial values
        id = "";
        name = "";
        terrain = "";
        description = "";
        trees = 0;
        saplings = 0;
        peasants = 0;
        horses = 0;
        silver = 0;
        entertainment = 0;
        recruits = 0;
        wage = 0;
      }
      List<String> split = line.split(" ");
      x = int.parse(split.elementAt(1));
      y = int.parse(split.elementAt(2));
      count++;
    } else if (line.startsWith("EINHEIT")) {
      regionActive = false;
    } else if (line.startsWith("SCHIFF")) {
      regionActive = false;
    } else if (line.startsWith("BURG")) {
      regionActive = false;
    } else if (line.startsWith("TRANSLATION")) {
      regionActive = false;
    } else {
      if (regionActive) {
        List<String> split = line.split(";");
        if (split.length > 1) {
          id = getStringElement(split, id, "id");
          terrain = getStringElement(split, terrain, "Terrain");
          name = getStringElement(split, name, "Name");
          description = getStringElement(split, description, "Beschr");
          trees = getIntElement(split, trees, "Baeume");
          saplings = getIntElement(split, saplings, "Schoesslinge");
          peasants = getIntElement(split, peasants, "Bauern");
          horses = getIntElement(split, horses, "Pferde");
          silver = getIntElement(split, silver, "Silber");
          entertainment = getIntElement(split, entertainment, "Unterh");
          recruits = getIntElement(split, recruits, "Rekruten");
          wage = getIntElement(split, wage, "Lohn");
        }
      }
    }
  }
  print('File is now closed.');
  if (regionList.length < count) {
    region = Region(id, x, y, name, terrain, description, trees, saplings,
        peasants, horses, silver, entertainment, recruits, wage);
    regionList.add(region);
    print("Last: $count " + region.toString());
  }

  return regionList;
}

String getStringElement(List<String> split, String element, String elementName) {
  if (split.elementAt(1).replaceAll("\r", "") == elementName) {
    element = split.elementAt(0).replaceAll("\"", "");
  }
  return element;
}

int getIntElement(List<String> split, int element, String elementName) {
  if (split.elementAt(1).replaceAll("\r", "") == elementName) {
    element = int.parse(split.elementAt(0).replaceAll("\"", ""));
  }
  return element;
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

  final data = await rootBundle.loadString('./assets/Andune.txt');

  LineSplitter ls = new LineSplitter();
  List<String> lines = ls.convert(data);
  for (var line in lines) {
    if (line.startsWith("REGION")) {
      if (regionList.length < count) {
        region = Region(id, x, y, name, terrain, description, trees, saplings,
            peasants, horses, silver, entertainment, recruits, wage);
        regionList.add(region);
        print("$count " + region.toString());
        // reset to initial values
        id = "";
        name = "";
        terrain = "";
        description = "";
        trees = 0;
        saplings = 0;
        peasants = 0;
        horses = 0;
        silver = 0;
        entertainment = 0;
        recruits = 0;
        wage = 0;
      }
      List<String> split = line.split(" ");
      x = int.parse(split.elementAt(1));
      y = int.parse(split.elementAt(2));
      count++;
    } else {
      List<String> split = line.split(";");
      if (split.length > 1) {
        id = getStringElement(split, id, "id");
        terrain = getStringElement(split, terrain, "Terrain");
        name = getStringElement(split, name, "Name");
        description = getStringElement(split, description, "Beschr");
        trees = getIntElement(split, trees, "Baeume");
        saplings = getIntElement(split, saplings, "Schoesslinge");
        peasants = getIntElement(split, peasants, "Bauern");
        horses = getIntElement(split, horses, "Pferde");
        silver = getIntElement(split, silver, "Silber");
        entertainment = getIntElement(split, entertainment, "Unterh");
        recruits = getIntElement(split, recruits, "Rekruten");
        wage = getIntElement(split, wage, "Lohn");
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

List<Region> readFileByLinesForString(String content) {
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
  var regionActive = false;

  if (content == null) {
    return regionList;
  }

  List<String> lines = content.split('\n');
  for (var line in lines) {
    if (line.startsWith("REGION")) {
      regionActive = true;
      if (regionList.length < count) {
        region = Region(id, x, y, name, terrain, description, trees, saplings,
            peasants, horses, silver, entertainment, recruits, wage);
        regionList.add(region);
        // reset to initial values
        id = "";
        name = "";
        terrain = "";
        description = "";
        trees = 0;
        saplings = 0;
        peasants = 0;
        horses = 0;
        silver = 0;
        entertainment = 0;
        recruits = 0;
        wage = 0;
      }
      List<String> split = line.split(" ");
      x = int.parse(split.elementAt(1));
      y = int.parse(split.elementAt(2));
      count++;
    } else if (line.startsWith("EINHEIT")) {
      regionActive = false;
    } else if (line.startsWith("SCHIFF")) {
      regionActive = false;
    } else if (line.startsWith("BURG")) {
      regionActive = false;
    } else if (line.startsWith("TRANSLATION")) {
      regionActive = false;
    } else {
      if (regionActive) {
        List<String> split = line.split(";");
        if (split.length > 1) {
          id = getStringElement(split, id, "id");
          terrain = getStringElement(split, terrain, "Terrain");
          name = getStringElement(split, name, "Name");
          description = getStringElement(split, description, "Beschr");
          trees = getIntElement(split, trees, "Baeume");
          saplings = getIntElement(split, saplings, "Schoesslinge");
          peasants = getIntElement(split, peasants, "Bauern");
          horses = getIntElement(split, horses, "Pferde");
          silver = getIntElement(split, silver, "Silber");
          entertainment = getIntElement(split, entertainment, "Unterh");
          recruits = getIntElement(split, recruits, "Rekruten");
          wage = getIntElement(split, wage, "Lohn");
        }
      }
    }
  }
  print('File is now closed.');
  if (regionList.length < count) {
    region = Region(id, x, y, name, terrain, description, trees, saplings,
        peasants, horses, silver, entertainment, recruits, wage);
    regionList.add(region);
    print("Last: $count " + region.toString());
  }

  return regionList;
}
