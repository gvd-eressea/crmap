import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:crmap_app/parser.dart';
import 'package:crmap_app/region.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:hexagon/hexagon.dart';
import 'package:path/path.dart' as p;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter CR Map',
      theme: ThemeData(
        primarySwatch: myBlue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(key: UniqueKey(), title: 'Eressea'),
    );
  }
}

const MaterialColor myBlue = MaterialColor(
  _myBluePrimaryValue,
  <int, Color>{
    50: Color(0xFFE3F2FD),
    100: Color(0xFFDA8888),
    200: Color(0xFFAF7486),
    300: Color(0xFF835F83),
    400: Color(0xFF614F82),
    500: Color(_myBluePrimaryValue),
    600: Color(0xFF1E88E5),
    700: Color(0xFF1976D2),
    800: Color(0xFF1565C0),
    900: Color(0xFF0D47A1),
  },
);
const int _myBluePrimaryValue = 0xFF404080;

class MyHomePage extends StatefulWidget {
  MyHomePage({required Key key, required this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with TickerProviderStateMixin {
  int depth = 1;
  List<int> depths = [0, 1, 2, 3, 4];
  HexagonType type = HexagonType.FLAT;
  bool hasControls = false;
  double hexSize = 80;

  late TabController tabController;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  String searchRegion = "";
  String battleRegion = "Finde Kämpfe";

  late Future<List<Region>> _regionsList;
  late List<Region> _regionsListFromFile;
  late List<Region> _battleRegionsList;
  late Region _markedRegion;
  int _horizontalDrag = 0;
  int _verticalDrag = 0;
  int _lastDragTime = 0;

  @override
  void initState() {
    super.initState();
    tabController = TabController(initialIndex: 0, length: 3, vsync: this);
    tabController.addListener(_onTabChange);
    _regionsList = getRegionsLocally();
    _regionsListFromFile = [];
    _markedRegion = Region("", 0, 0, "", "", "", "", 0, 0, 0, 0, 0, 0, 0, 0);
    _horizontalDrag = 0;
  }

  @override
  void deactivate() {
    tabController.dispose();
    super.deactivate();
  }

  void _onTabChange() {
    if (tabController.index == 1) {
      setState(() {
        hasControls = true;
      });
    } else {
      setState(() {
        hasControls = false;
      });
    }
  }

  void Function() handlePressed(BuildContext context, String buttonName) {
    return () {
      if (_battleRegionsList.isNotEmpty) {
        var region = _battleRegionsList.removeLast();
        if (region.name.length > 0) {
          battleRegion = region.name;
          searchRegion = region.name;
        } else {
          battleRegion = region.terrain;
        }
      } else {
        battleRegion = "Keine Kämpfe";
      }
      final snackBar = SnackBar(
        content: Text(
          '$battleRegion gefunden!',
          style: TextStyle(color: Theme.of(context).colorScheme.surface),
        ),
        action: SnackBarAction(
          textColor: Theme.of(context).colorScheme.surface,
          label: 'Close',
          onPressed: () {},
        ),
      );

      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    };
  }

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;

    return DefaultTabController(
      length: 3,
      initialIndex: 0,
      child: Scaffold(
        appBar: AppBar(
          bottom: TabBar(
            controller: tabController,
            tabs: [
              Tab(text: 'Datei'),
              Tab(key: Key('map'), text: 'Karte'),
              Tab(text: 'Region'),
            ],
          ),
          title: Text(widget.title),
          actions: hasControls
              ? [
                  Row(children: [
                    GestureDetector(
                      child: Form(
                        key: _formKey,
                        child: Row(
                          children: <Widget>[
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8.0),
                              child: ElevatedButton(
                                onPressed: handlePressed(context, battleRegion),
                                child: Text(battleRegion),
                              ),
                            ),
                            ConstrainedBox(
                              constraints: BoxConstraints.tight(
                                  Size(size.width / 4, 50)),
                              child: TextFormField(
                                decoration: const InputDecoration(
                                  hintText: 'Regionssuche',
                                ),
                                validator: (String? value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Bitte Regionsnamen eingeben';
                                  }
                                  return null;
                                },
                                onSaved: (String? value) {
                                  setState(() {
                                    searchRegion = value!;
                                  });
                                },
                              ),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8.0),
                              child: ElevatedButton(
                                onPressed: () {
                                  findRegionByPartOfName();
                                  FocusScopeNode currentFocus =
                                      FocusScope.of(context);
                                  if (!currentFocus.hasPrimaryFocus) {
                                    currentFocus.unfocus();
                                  }
                                },
                                child: Icon(Icons.search),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text('Zoom'),
                    ),
                    Slider.adaptive(
                      value: hexSize,
                      min: 60,
                      max: 100,
                      activeColor: Colors.lightBlueAccent,
                      onChanged: (value) => setState(() {
                        hexSize = value;
                      }),
                    ),
                  ])
                ]
              : null,
        ),
        body: TabBarView(
          controller: tabController,
          physics: ClampingScrollPhysics(),
          children: [
            _openFile(),
            _buildHorizontalGrid(context, size, tabController),
            _buildRegion(),
          ],
        ),
      ),
    );
  }

  /// Find region where the region name contains the entered search string.
  void findRegionByPartOfName() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      print('searchRegion: $searchRegion');
      if (searchRegion.isNotEmpty && _regionsListFromFile.isNotEmpty) {
        var foundRegion = _regionsListFromFile.firstWhere(
            (region) => region.name.contains(searchRegion),
            orElse: nothingFound);
        print('found region: $foundRegion');
        _markedRegion = foundRegion;
      } else {
        print(_regionsListFromFile);
      }
    }
  }

  /// If entered search string is not found in any region name the old marked region will be returned.
  Region nothingFound() {
    print('No region found! Return old marked region: ' + _markedRegion.name);
    return _markedRegion;
  }

  Widget _buildHorizontalGrid(
      BuildContext context, Size size, TabController tabController) {
    if (_regionsListFromFile.length > 0) {
      RegionList rl = RegionList(_regionsListFromFile);
      return showMap(rl, size, tabController);
    } else {
      return FutureBuilder(
        future: _regionsList,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return CircularProgressIndicator();
          } else if (snapshot.connectionState == ConnectionState.done) {
            Object? data = snapshot.data;
            if (data is List<Region>) {
              RegionList rl = RegionList(data);
              return showMap(rl, size, tabController);
            } else {
              return Text('State: ${snapshot.connectionState}');
            }
          } else {
            return Text('State: ${snapshot.connectionState}');
          }
        },
      );
    }
  }

  SingleChildScrollView showMap(
      RegionList rl, Size size, TabController tabController) {
    var indexZero = rl.regions.indexWhere(
        (region) => region.x == _markedRegion.x && region.y == _markedRegion.y);
    int centerX =
        indexZero > 0 ? _markedRegion.x : rl.maxX - (rl.maxX - rl.minX) ~/ 2;
    int centerY =
        indexZero > 0 ? _markedRegion.y : rl.maxY - (rl.maxY - rl.minY) ~/ 2;
    int maxColumns = rl.maxX - rl.minX + 1;
    int maxRows = rl.maxY - rl.minY + 1;
    int columns = maxColumns > (size.width.toInt() ~/ hexSize)
        ? (size.width.toInt() ~/ hexSize)
        : maxColumns;
    int rows = maxRows > (size.height.toInt() ~/ hexSize) * 2
        ? (size.height.toInt() ~/ hexSize) * 2
        : maxRows;
    int yOffset = rl.maxY - (centerY + rows ~/ 2) + _verticalDrag;
    yOffset = yOffset > 0 ? yOffset : 0;
    int xOffset = centerX -
        (columns ~/ 2) -
        (rl.maxY - yOffset - centerY) ~/ 2 +
        _horizontalDrag;

    print(
        'min (${rl.minX}, ${rl.minY}), max (${rl.maxX}, ${rl.maxY}), center ($centerX, $centerY), col $columns, rows $rows, xOffset $xOffset, yOffset $yOffset / Size ${size.width} / horizontalDrag $_horizontalDrag / verticalDrag $_verticalDrag / hexSize $hexSize');
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          HexagonOffsetGrid.oddPointy(
            color: Colors.black54,
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 32.0),
            columns: columns,
            rows: rows,
            buildTile: (col, row) {
              int y = rl.maxY - row - yOffset;
              int x = col +
                  xOffset +
                  (row ~/ 2) -
                  ((rl.maxY + yOffset).isOdd
                      ? (y.isOdd ? 1 : 0)
                      : (y.isOdd ? 0 : 1));
              Region found = rl.regions.firstWhere(
                  (region) => region.x == x && region.y == y,
                  orElse: () =>
                      Region("", x, y, "", "", "", "", 0, 0, 0, 0, 0, 0, 0, 0));
              var color = findColorByTerrain(found);
              var imageName = found.terrain == ""
                  ? "images/unbekannt.gif"
                  : "images/" +
                      (found.terrain == "Wüste"
                          ? "wueste"
                          : (found.terrain == "Aktiver Vulkan"
                              ? "aktivervulkan"
                              : found.terrain.toLowerCase())) +
                      ".gif";
              return HexagonWidgetBuilder(
                key: Key('$x,$y'),
                elevation: col.toDouble(),
                padding: 1.0,
                color: color,
                child: GestureDetector(
                    child: Stack(
                      children: [
                        AspectRatio(
                            aspectRatio: HexagonType.POINTY.ratio,
                            child: Image.asset(
                              imageName,
                              fit: BoxFit.fitHeight,
                            )),
                        Center(
                            child: Text(
                                '${found.name == "" ? found.terrain : found.name} / $x,$y'))
                      ],
                    ),
                    onTap: () {
                      print(
                          '${found.name == "" ? found.terrain : found.name} / $x,$y / ($col,$row)');
                      tabController.animateTo(tabController.index + 1);
                      _markedRegion = found;
                    },
                    onHorizontalDragUpdate: calculateHorizontalDrag,
                    onVerticalDragUpdate: calculateVerticalDrag),
              );
            },
          )
        ],
      ),
    );
  }

  findColorByTerrain(Region found) {
    var color;
    switch (found.terrain) {
      case "Ozean":
        {
          color = Colors.lightBlue.shade200;
        }
        break;
      case "Ebene":
        {
          color = Colors.lightGreen.shade200;
        }
        break;
      case "Wald":
        {
          color = Colors.lightGreen.shade500;
        }
        break;
      case "Hochland":
        {
          color = Colors.brown.shade400;
        }
        break;
      case "Wüste":
        {
          color = Colors.yellow.shade200;
        }
        break;
      case "Gletscher":
        {
          color = Colors.white;
        }
        break;
      case "Berge":
        {
          color = Colors.black26;
        }
        break;
      case "Sumpf":
        {
          color = Colors.green.shade900;
        }
        break;
      case "Feuerwand":
        {
          color = Colors.red;
        }
        break;
      case "Vulkan":
        {
          color = Colors.black54;
        }
        break;
      default:
        {
          color = Colors.black;
        }
        break;
    }
    return color;
  }

  void calculateHorizontalDrag(DragUpdateDetails dragUpdateDetails) {
    var currTime = DateTime.now().millisecondsSinceEpoch;
    var diffTime = currTime - _lastDragTime;
    if (diffTime > 100) {
      _lastDragTime = currTime;
      print(
          'delta ${dragUpdateDetails.delta} / primaryDelta ${dragUpdateDetails.primaryDelta} / globalPosition ${dragUpdateDetails.globalPosition} / localPosition ${dragUpdateDetails.localPosition} / diffTime $diffTime');
      setState(() {
        if (dragUpdateDetails.primaryDelta != 0) {
          dragUpdateDetails.primaryDelta! > 0
              ? _horizontalDrag--
              : _horizontalDrag++;
        }
      });
    }
  }

  void calculateVerticalDrag(DragUpdateDetails dragUpdateDetails) {
    var currTime = DateTime.now().millisecondsSinceEpoch;
    var diffTime = currTime - _lastDragTime;
    if (diffTime > 100) {
      _lastDragTime = currTime;
      print(
          'delta ${dragUpdateDetails.delta} / primaryDelta ${dragUpdateDetails.primaryDelta} / globalPosition ${dragUpdateDetails.globalPosition} / localPosition ${dragUpdateDetails.localPosition} / diffTime $diffTime');
      setState(() {
        if (dragUpdateDetails.primaryDelta != 0) {
          dragUpdateDetails.primaryDelta! > 0
              ? _verticalDrag--
              : _verticalDrag++;
        }
      });
    }
  }

  Widget _buildRegion() {
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            key: Key('regionCard'),
            elevation: 1,
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                richText('Name:', _markedRegion.name),
                richText('Terrain: ', _markedRegion.terrain),
                richText(
                    'Koordinaten: ',
                    _markedRegion.x.toString() +
                        ',' +
                        _markedRegion.y.toString()),
              ],
            ),
          ),
          Card(
              elevation: 1,
              color: Colors.white,
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    richText('Beschreibung: ', _markedRegion.description),
                  ])),
          Card(
              elevation: 1,
              color: Colors.white,
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    richText('Bäume: ', _markedRegion.trees.toString()),
                    richText('Schößlinge: ', _markedRegion.saplings.toString()),
                    richText('Bauern: ', _markedRegion.peasants.toString()),
                    richText('Pferde: ', _markedRegion.horses.toString()),
                    richText('Silber: ', _markedRegion.silver.toString()),
                    richText('Unterhaltung: ',
                        _markedRegion.entertainment.toString()),
                    richText('Rekruten: ', _markedRegion.recruits.toString()),
                    richText('Lohn: ', _markedRegion.wage.toString()),
                  ])),
          Card(
              elevation: 1,
              color: Colors.white,
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    richText('Kämpfe: ', _markedRegion.battleSection),
                  ])),
        ],
      ),
    );
  }

  RichText richText(String header, String value) {
    return RichText(
      text: TextSpan(
        text: header,
        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        children: [
          TextSpan(
            text: value,
            style:
                TextStyle(fontWeight: FontWeight.normal, color: Colors.black),
          ),
        ],
      ),
    );
  }

  Widget _openFile() {
    final ButtonStyle style =
        ElevatedButton.styleFrom(textStyle: const TextStyle(fontSize: 20));

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const SizedBox(height: 30),
          ElevatedButton(
            key: Key('openCR'),
            style: style,
            onPressed: () async {
              var myRegionsList = await openFile();
              setState(() {
                _regionsListFromFile = myRegionsList;
                _battleRegionsList = fillBattleList(_regionsListFromFile);
              });
              tabController.animateTo(tabController.index + 1);
            },
            child: const Text('CR öffnen'),
          ),
        ],
      ),
    );
  }

  Future<dynamic> openFile() async {
    var myRegionsList = [];
    FilePickerResult? result =
        await FilePicker.platform.pickFiles(type: FileType.any);
    if (result != null) {
      var fileName = result.files.first.name;
      print("File " +
          fileName +
          " has extension " +
          p.context.extension(fileName));
      var isZipFile = p.context.extension(fileName) == '.zip';
      var fileStream = result.files.first.bytes;
      if (fileStream == null) {
        var s = result.files.single.path;
        File file = File(s!);
        fileStream = file.readAsBytesSync();
      }
      if (isZipFile) {
        var content = "";
        print("Decompress zip file and find cr file.");
        final archive = new ZipDecoder().decodeBytes(fileStream);
        for (var file in archive) {
          if (file.isFile) {
            if (p.context.extension(file.name) == '.cr') {
              print("Found cr file " + file.name);
              content = utf8.decode(file.content);
              break;
            }
          }
        }
        print("File content length: " + content.length.toString());
        myRegionsList = readFileByLinesForString(content);
      } else {
        print("File stream length: " + fileStream.lengthInBytes.toString());
        myRegionsList = readFileByLinesForStream(fileStream);
      }
      //                print(myRegionsList);
    }
    return myRegionsList;
  }
}

class RegionWidget extends StatelessWidget {
  const RegionWidget({
    required Key key,
    required this.width,
    this.name,
  }) : super(key: key);

  final double width;
  final name;

  @override
  Widget build(BuildContext context) {
    return HexagonWidget.pointy(
      width: width,
      child: Stack(
        children: [
          AspectRatio(
              aspectRatio: HexagonType.POINTY.ratio,
              child: Image.asset(
                name,
                fit: BoxFit.fitHeight,
              )),
          Center(child: Text(name))
        ],
      ),
    );
  }
}
