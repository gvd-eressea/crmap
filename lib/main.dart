import 'dart:io';

import 'package:crmap_app/parser.dart';
import 'package:crmap_app/region.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:hexagon/hexagon.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter CR Map',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(key: UniqueKey(), title: 'Eressea'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with TickerProviderStateMixin {
  int depth = 1;
  List<int> depths = [0, 1, 2, 3, 4];
  HexagonType type = HexagonType.FLAT;
  bool hasControls = true;
  double hexSize = 80;

  TabController tabController;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  String searchRegion = "";

  Future<List<Region>> _regionsList;
  List<Region> _regionsListFromFile;
  Region _markedRegion;
  int _horizontalDrag = 0;
  int _verticalDrag = 0;
  int _lastDragTime = 0;

  @override
  void initState() {
    super.initState();
    tabController = TabController(initialIndex: 0, length: 4, vsync: this);
    tabController.addListener(_onTabChange);
    _regionsList = getRegionsLocally();
    _regionsListFromFile = [];
    _markedRegion = Region("", 0, 0, "", "", "", 0, 0, 0, 0, 0, 0, 0, 0);
    _horizontalDrag = 0;
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

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;

    return DefaultTabController(
      length: 4,
      initialIndex: 0,
      child: Scaffold(
        appBar: AppBar(
          bottom: TabBar(
            controller: tabController,
            tabs: [
              Tab(text: 'CR öffnen'),
              // Tab(text: 'Grid'),
              Tab(text: 'Karte'),
              Tab(text: 'Region'),
              Tab(text: 'Beispiel'),
            ],
          ),
          title: Text(widget.title),
          actions: hasControls
              ? [
                  Row(children: [
                    Form(
                      key: _formKey,
                      child: Row(
                        children: <Widget>[
                          ConstrainedBox(
                            constraints:
                                BoxConstraints.tight(const Size(200, 50)),
                            child: TextFormField(
                              decoration: const InputDecoration(
                                hintText: 'Regionssuche',
                              ),
                              validator: (String value) {
                                if (value == null || value.isEmpty) {
                                  return 'Bitte Regionsnamen eingeben';
                                }
                                return null;
                              },
                              onSaved: (String value) {
                                setState(() {
                                  searchRegion = value;
                                });
                              },
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            child: ElevatedButton(
                              onPressed: () {
                                if (_formKey.currentState.validate()) {
                                  _formKey.currentState.save();
                                  print('searchRegion: $searchRegion');
                                  if (searchRegion != null && searchRegion.isNotEmpty && _regionsListFromFile.isNotEmpty) {
                                    var foundRegion = _regionsListFromFile.firstWhere((region) => region.name == searchRegion);
                                    print('found region: $foundRegion');
                                    _markedRegion = foundRegion;
                                  } else {
                                    print(_regionsListFromFile);
                                  }
                                }
                              },
                              child: const Text('Suche'),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
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
          physics: NeverScrollableScrollPhysics(),
          children: [
            _openFile(),
            // _buildStack(context),
            _buildHorizontalGrid(context, size, tabController),
            _buildRegion(),
            _buildMore(size),
          ],
        ),
      ),
    );
  }

  Stack _buildStack(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(child: _buildGrid(context, type)),
        Align(
          alignment: Alignment.topRight,
          child: Visibility(
            visible: true,
            child: Theme(
              data: ThemeData(colorScheme: ColorScheme.dark()),
              child: Card(
                margin: EdgeInsets.all(8.0),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 2.0, horizontal: 16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DropdownButton<HexagonType>(
                        onChanged: (value) => this.setState(() {
                          type = value;
                        }),
                        value: type,
                        items: [
                          DropdownMenuItem<HexagonType>(
                            value: HexagonType.FLAT,
                            child: Text('Flat'),
                          ),
                          DropdownMenuItem<HexagonType>(
                            value: HexagonType.POINTY,
                            child: Text('Pointy'),
                          )
                        ],
                        selectedItemBuilder: (context) => [
                          Center(child: Text('Flat')),
                          Center(child: Text('Pointy')),
                        ],
                      ),
                      DropdownButton<int>(
                        onChanged: (value) => this.setState(() {
                          depth = value;
                        }),
                        value: depth,
                        items: depths
                            .map((e) => DropdownMenuItem<int>(
                                  value: e,
                                  child: Text('Depth: $e'),
                                ))
                            .toList(),
                        selectedItemBuilder: (context) {
                          return depths
                              .map((e) => Center(child: Text('Depth: $e')))
                              .toList();
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGrid(BuildContext context, HexagonType type) {
    return InteractiveViewer(
      minScale: 0.2,
      maxScale: 4.0,
      child: HexagonGrid(
        hexType: type,
        color: Colors.pink,
        depth: depth,
        buildTile: (coordinates) => HexagonWidgetBuilder(
          padding: 2.0,
          cornerRadius: 8.0,
          child: Stack(children: [
            Align(
              child: Image.asset(
                'images/wald.gif',
                fit: BoxFit.cover,
              ),
              alignment: Alignment.center,
            ),
            Align(
              child: Text(
                  '${coordinates.q + coordinates.r},${-1 * coordinates.r}',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              alignment: Alignment.center,
            ),
          ]),
        ),
      ),
    );
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
            Object data = snapshot.data;
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
    var indexZero =
        rl.regions.indexWhere((region) => region.x == _markedRegion.x && region.y == _markedRegion.y);
    int centerX = indexZero > 0 ? _markedRegion.x : rl.maxX - (rl.maxX - rl.minX) ~/ 2;
    int centerY = indexZero > 0 ? _markedRegion.y : rl.maxY - (rl.maxY - rl.minY) ~/ 2;
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
                      Region("", x, y, "", "", "", 0, 0, 0, 0, 0, 0, 0, 0));
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
              return HexagonWidgetBuilder(
                elevation: col.toDouble(),
                padding: 1.0,
                color: color,
                child: GestureDetector(
                    child: Text(
                        '${found.name == "" ? found.terrain : found.name} / ${x},${y}'),
                    onTap: () {
                      print(
                          '${found.name == "" ? found.terrain : found.name} / ${x},${y} / ($col,$row)');
                      tabController.animateTo(tabController.index + 1);
                      _markedRegion = found;
                    },
                    onHorizontalDragUpdate:
                        (DragUpdateDetails dragUpdateDetails) {
                      var currTime = DateTime.now().millisecondsSinceEpoch;
                      var diffTime = currTime - _lastDragTime;
                      if (diffTime > 100) {
                        _lastDragTime = currTime;
                        print(
                            'delta ${dragUpdateDetails.delta} / primaryDelta ${dragUpdateDetails.primaryDelta} / globalPosition ${dragUpdateDetails.globalPosition} / localPosition ${dragUpdateDetails.localPosition} / diffTime $diffTime');
                        setState(() {
                          if (dragUpdateDetails.primaryDelta != 0) {
                            dragUpdateDetails.primaryDelta > 0
                                ? _horizontalDrag--
                                : _horizontalDrag++;
                          }
                        });
                      }
                    },
                    onVerticalDragUpdate:
                        (DragUpdateDetails dragUpdateDetails) {
                      var currTime = DateTime.now().millisecondsSinceEpoch;
                      var diffTime = currTime - _lastDragTime;
                      if (diffTime > 100) {
                        _lastDragTime = currTime;
                        print(
                            'delta ${dragUpdateDetails.delta} / primaryDelta ${dragUpdateDetails.primaryDelta} / globalPosition ${dragUpdateDetails.globalPosition} / localPosition ${dragUpdateDetails.localPosition} / diffTime $diffTime');
                        setState(() {
                          if (dragUpdateDetails.primaryDelta != 0) {
                            dragUpdateDetails.primaryDelta > 0
                                ? _verticalDrag--
                                : _verticalDrag++;
                          }
                        });
                      }
                    }),
              );
            },
          )
        ],
      ),
    );
  }

  Widget _buildVerticalGrid() {
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Marked Region: ' + _markedRegion.terrain),
          HexagonOffsetGrid.evenPointy(
            color: Colors.yellow.shade100,
            padding: EdgeInsets.all(8.0),
            columns: 5,
            rows: 20,
            buildTile: (col, row) => HexagonWidgetBuilder(
              color: row.isEven ? Colors.yellow : Colors.orangeAccent,
              elevation: 2.0,
              padding: 1.0,
            ),
            buildChild: (col, row) => Text('$col, $row'),
          ),
        ],
      ),
    );
  }

  Widget _buildRegion() {
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
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

  Widget _buildMore(Size size) {
    var padding = 1.0;
    var w = (size.width - 4 * padding) / 4;
    var h = 150.0;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: EdgeInsets.all(padding),
                  child: RegionWidget(
                    key: UniqueKey(),
                    width: w,
                    name: 'images/berge.gif',
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(padding),
                  child: RegionWidget(
                    key: UniqueKey(),
                    width: w,
                    name: 'images/ebene.gif',
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(padding),
                  child: RegionWidget(
                    key: UniqueKey(),
                    width: w,
                    name: 'images/ozean.gif',
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(padding),
                  child: RegionWidget(
                    key: UniqueKey(),
                    width: w,
                    name: 'images/hochland.gif',
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(padding),
                  child: RegionWidget(
                    key: UniqueKey(),
                    width: w,
                    name: 'images/sumpf.gif',
                  ),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: EdgeInsets.all(padding),
                  child: RegionWidget(
                    key: UniqueKey(),
                    width: w,
                    name: 'images/feuerwand.gif',
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(padding),
                  child: RegionWidget(
                    key: UniqueKey(),
                    width: w,
                    name: 'images/vulkan.gif',
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(padding),
                  child: RegionWidget(
                    key: UniqueKey(),
                    width: w,
                    name: 'images/wald.gif',
                  ),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: EdgeInsets.all(padding),
                  child: RegionWidget(
                    key: UniqueKey(),
                    width: w,
                    name: 'images/wueste.gif',
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(padding),
                  child: RegionWidget(
                    key: UniqueKey(),
                    width: w,
                    name: 'images/unbekannt.gif',
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(padding),
                  child: RegionWidget(
                    key: UniqueKey(),
                    width: w,
                    name: 'images/ozean.gif',
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(padding),
                  child: RegionWidget(
                    key: UniqueKey(),
                    width: w,
                    name: 'images/aktiver vulkan.gif',
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(padding),
                  child: RegionWidget(
                    key: UniqueKey(),
                    width: w,
                    name: 'images/sumpf.gif',
                  ),
                ),
              ],
            ),
          ],
        ),
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
            style: style,
            onPressed: () async {
              var myRegionsList;
              FilePickerResult result =
                  await FilePicker.platform.pickFiles(type: FileType.any);
              if (result != null) {
                var fileStream = result.files.first.bytes;
                if (fileStream == null) {
                  File file = File(result.files.single.path);
                  fileStream = file.readAsBytesSync();
                }
                if (fileStream != null) {
                  print("File stream length: " +
                      fileStream.lengthInBytes.toString());
                  myRegionsList = readFileByLinesForStream(fileStream);
                } else {
                  print("file stream empty");
                }
//                print(myRegionsList);
              }
              setState(() {
                _regionsListFromFile = myRegionsList;
              });
            },
            child: const Text('CR öffnen'),
          ),
        ],
      ),
    );
  }
}

class RegionWidget extends StatelessWidget {
  const RegionWidget({
    Key key,
    this.width,
    this.name,
  }) : super(key: key);

  final double width;
  final name;

  @override
  Widget build(BuildContext context) {
    return HexagonWidget.pointy(
      width: width,
      child: AspectRatio(
        aspectRatio: HexagonType.POINTY.ratio,
        child: Image.asset(
          name,
          fit: BoxFit.fitHeight,
        ),
      ),
    );
  }
}
