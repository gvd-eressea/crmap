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
  bool showControls = true;

  TabController tabController;

  Future<List<Region>> _regionsList;
  List<Region> _regionsListFromFile;
  Region _markedRegion;
  int _horizontalDrag = 0;
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
    if (tabController.index == 0) {
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
              Tab(text: 'Grid'),
              Tab(text: 'Karte'),
              Tab(text: 'Region'),
              // Tab(text: 'Beispiel'),
              Tab(text: 'CR öffnen'),
            ],
          ),
          title: Text(widget.title),
          actions: hasControls
              ? [
                  Row(children: [
                    Text('Controls'),
                    Switch(
                      value: showControls,
                      activeColor: Colors.lightBlueAccent,
                      onChanged: (value) => setState(() {
                        showControls = value;
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
            Stack(
              children: [
                Positioned.fill(child: _buildGrid(context, type)),
                Align(
                  alignment: Alignment.topRight,
                  child: Visibility(
                    visible: showControls,
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
                                      .map((e) =>
                                          Center(child: Text('Depth: $e')))
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
            ),
            _buildHorizontalGrid(context, size, tabController),
            _buildRegion(),
            // _buildMore(size),
            _openFile(),
          ],
        ),
      ),
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
    int maxColumns = rl.maxX - rl.minX + 1;
    int maxRows = rl.maxY - rl.minY + 1;
    int columns = maxColumns > (size.width.toInt() ~/ 80)
        ? (size.width.toInt() ~/ 80)
        : maxColumns;
    int rows = maxRows; // > 50 ? 50 : maxRows;
    int xOffset = rl.minX > 0
        ? ((rl.maxX - rl.minX) ~/ 2) - (columns ~/ 2) + _horizontalDrag
        : rl.minX + 2 + _horizontalDrag;
    int yOffset =
        rl.maxY < 0 ? -1 * rl.maxY + maxRows ~/ 2 : 0; //-14 - rl.minY;

    print(
        'min (${rl.minX}, ${rl.minY}), max (${rl.maxX}, ${rl.maxY}), col $columns, rows $rows, xOffset $xOffset, yOffset $yOffset / Size ${size.width} / horizontalDrag $_horizontalDrag');
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
              int y = (rl.maxY - rl.minY) ~/ 2 - row - yOffset;
              int x = col +
                  xOffset -
                  (rl.maxX - rl.minX) ~/ 2 +
                  (row ~/ 2) -
                  (y.isOdd ? 1 : 0);
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
                          '${found.name == "" ? found.terrain : found.name} / ${x},${y}');
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
    var w = (size.width - 4 * padding) / 2;
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
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: EdgeInsets.all(8.0),
                  child: HexagonWidget.flat(
                    height: h,
                    color: Colors.orangeAccent,
                    child: Text('flat\nheight: ${h.toStringAsFixed(2)}'),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(8.0),
                  child: HexagonWidget.pointy(
                    height: h,
                    color: Colors.red,
                    child: Text('pointy\nheight: ${h.toStringAsFixed(2)}'),
                  ),
                ),
              ],
            ),
            Padding(
              padding: EdgeInsets.all(padding),
              child: HexagonWidget.flat(
                width: w,
                color: Colors.limeAccent,
                elevation: 0,
                child:
                    Text('flat\nwidth: ${w.toStringAsFixed(2)}\nelevation: 0'),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(padding),
              child: HexagonWidget.pointy(
                width: w,
                color: Colors.lightBlue,
                child: Text('pointy\nwidth: ${w.toStringAsFixed(2)}'),
              ),
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
              FilePickerResult result =
                  await FilePicker.platform.pickFiles(type: FileType.any);
              setState(() {
                if (result != null) {
                  print(result.files.first.name);
                  var fileStream = result.files.first.bytes;
                  // print(result.files.first.bytes);
                  var myRegionsList = readFileByLinesForStream(fileStream);
                  print(myRegionsList);
                  _regionsListFromFile = myRegionsList;
                }
              });
            },
            child: const Text('CR öffnen'),
          ),
        ],
      ),
    );
  }
}

String coordinates(int x, int y) {
  // // int x = col - 111 ~/ 2;
  // // col = x + 111  ~/ 2;
  // var out = 'x-transformation\n';
  // for (var i = x; i < x + 5; i++) {
  //   var col = i + 111 ~/ 2;
  //   out = out + '$i -> $col\n';
  // }
  // // int y = 102 ~/ 2 - row;
  // // row = 102 ~/ 2 - y;
  // out = out + 'y-transformation\n';
  // for (var i = y; i < y + 5; i++) {
  //   var row = 102 ~/ 2 - i;
  //   out = out + '$i -> $row\n';
  // }
  // return out;
  return "";
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
