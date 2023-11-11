import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crmap_app/region.dart';
import 'package:crmap_app/battle.dart';
import 'package:flutter/services.dart' show Uint8List, rootBundle;

void main() async {
  List<Region> list = [];
  RegionList rl = RegionList(list);
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
  List<Battle> battleList = [];
  // Future<List<Region>> returnList = regionList as Future<List<Region>>;
  Region region;
  int x = -9999;
  int y = -9999;
  String id = "";
  String name = "";
  String terrain = "";
  String description = "";
  String regionBattleSection = "";
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

  Battle battle;
  String battleId = "";
  int xb = -9999;
  int yb = -9999;
  String battleSection = "";
  var battleActive = false;
  int countBattle = 0;

  List<String> lines = Utf8Decoder().convert(inputStream).split('\n');
  for (var line in lines) {
    if (line.startsWith("REGION")) {
      regionActive = true;
      battleActive = false;
      if (regionList.length < count) {
        region = Region(
            id,
            x,
            y,
            name,
            terrain,
            description,
            regionBattleSection,
            trees,
            saplings,
            peasants,
            horses,
            silver,
            entertainment,
            recruits,
            wage);
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
    } else if (line.startsWith("BATTLE")) {
      regionActive = false;
      battleActive = true;
      if (battleList.length < countBattle) {
        battleId = 'b$countBattle';
        battle = Battle(battleId, xb, yb, battleSection);
        battleList.add(battle);
        // reset to initial values
        print("Add: " + battle.toString());
        battleSection = "";
      }
      List<String> split = line.split(" ");
      xb = int.parse(split.elementAt(1));
      yb = int.parse(split.elementAt(2));
      countBattle++;
    } else if (line.startsWith("PARTEI")) {
      regionActive = false;
      battleActive = false;
      if (battleList.length < countBattle) {
        battleId = 'b$countBattle';
        battle = Battle(battleId, xb, yb, battleSection);
        battleList.add(battle);
        // reset to initial values
        print("Add: " + battle.toString());
        battleSection = "";
      }
    } else if (line.startsWith("EINHEIT")) {
      regionActive = false;
      battleActive = false;
    } else if (line.startsWith("SCHIFF")) {
      regionActive = false;
      battleActive = false;
    } else if (line.startsWith("BURG")) {
      regionActive = false;
      battleActive = false;
    } else if (line.startsWith("TRANSLATION")) {
      regionActive = false;
      battleActive = false;
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
      } else if (battleActive) {
        if (line.startsWith("MESSAGE")) {
          // skip
        } else {
          List<String> split = line.split(";");
          if (split.length > 1) {
            var section = "";
            section = getStringElement(split, section, "rendered");
            if (section != "") {
              battleSection = battleSection + '\n' + section;
            }
          }
        }
      }
    }
  }
  print('File is now closed.');
  if (regionList.length < count) {
    region = Region(
        id,
        x,
        y,
        name,
        terrain,
        description,
        regionBattleSection,
        trees,
        saplings,
        peasants,
        horses,
        silver,
        entertainment,
        recruits,
        wage);
    regionList.add(region);
    print("readFileByLinesForStream - Last: $count " + region.toString());
  }
  if (regionList.length > 0 && battleList.length > 0) {
    regionList.forEach((region) {
      var foundBattle = battleList.firstWhere(
          (battle) => battle.x == region.x && battle.y == region.y,
          orElse: () => Battle("none", -1, -1, ""));
      if (foundBattle.id != "none") {
        region.battleSection = foundBattle.battleSection;
        print("Battle found in  " + region.toString());
      }
    });
  }

  return regionList;
}

String getStringElement(
    List<String> split, String element, String elementName) {
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

List<Region> fillBattleList(List<Region> regionList) {
  List<Region> battleRegionList = [];
  regionList.forEach((region) {
    if (region.battleSection.length>0) {
      battleRegionList.add(region);
    }
  });
  if (battleRegionList.length>0) {
    var cnt = battleRegionList.length;
    print("Found $cnt battles.");
  }
  return battleRegionList;
}

Future<List<Region>> getRegionsLocally() async {
  List<Region> regionList = [];
  List<Battle> battleList = [];
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

  Battle battle;
  String battleId = "";
  int xb = -9999;
  int yb = -9999;
  String battleSection = "";
  var battleActive = false;
  int countBattle = 0;

  final data = await rootBundle.loadString('./assets/Andune.txt');

  LineSplitter ls = new LineSplitter();
  List<String> lines = ls.convert(data);
  for (var line in lines) {
    if (line.startsWith("REGION")) {
      regionActive = true;
      battleActive = false;
      if (regionList.length < count) {
        region = Region(
            id,
            x,
            y,
            name,
            terrain,
            description,
            battleSection,
            trees,
            saplings,
            peasants,
            horses,
            silver,
            entertainment,
            recruits,
            wage);
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
    } else if (line.startsWith("BATTLE")) {
      regionActive = false;
      battleActive = true;
      if (battleList.length < countBattle) {
        battleId = 'b$countBattle';
        battle = Battle(battleId, xb, yb, battleSection);
        battleList.add(battle);
        // reset to initial values
        print("Add: " + battle.toString());
        battleSection = "";
      }
      List<String> split = line.split(" ");
      xb = int.parse(split.elementAt(1));
      yb = int.parse(split.elementAt(2));
      countBattle++;
    } else if (line.startsWith("PARTEI")) {
      regionActive = false;
      battleActive = false;
      if (battleList.length < countBattle) {
        battleId = 'b$countBattle';
        battle = Battle(battleId, xb, yb, battleSection);
        battleList.add(battle);
        // reset to initial values
        print("Add: " + battle.toString());
        battleSection = "";
      }
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
      } else if (battleActive) {
        if (line.startsWith("MESSAGE")) {
          // skip
        } else {
          List<String> split = line.split(";");
          if (split.length > 1) {
            var section = "";
            section = getStringElement(split, section, "rendered");
            if (section != "") {
              battleSection = battleSection + '\n' + section;
            }
          }
        }
      }
    }
  }
  if (regionList.length < count) {
    region = Region(id, x, y, name, terrain, description, battleSection, trees,
        saplings, peasants, horses, silver, entertainment, recruits, wage);
    regionList.add(region);
    print("getRegionsLocally - Last: $count " + region.toString());
  }
  if (regionList.length > 0 && battleList.length > 0) {
    regionList.forEach((region) {
      var foundBattle = battleList.firstWhere(
          (battle) => battle.x == region.x && battle.y == region.y,
          orElse: () => Battle("none", -1, -1, ""));
      if (foundBattle.id != "none") {
        region.battleSection = foundBattle.battleSection;
        print("Battle found in  " + region.toString());
      }
    });
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
  String battleSection = "";
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

  List<String> lines = content.split('\n');
  for (var line in lines) {
    if (line.startsWith("REGION")) {
      regionActive = true;
      if (regionList.length < count) {
        region = Region(
            id,
            x,
            y,
            name,
            terrain,
            description,
            battleSection,
            trees,
            saplings,
            peasants,
            horses,
            silver,
            entertainment,
            recruits,
            wage);
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
    region = Region(id, x, y, name, terrain, description, battleSection, trees,
        saplings, peasants, horses, silver, entertainment, recruits, wage);
    regionList.add(region);
    print("Last: $count " + region.toString());
  }

  return regionList;
}
