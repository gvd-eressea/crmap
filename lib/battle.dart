class Battle {
  String id;
  int x;
  int y;
  String battleSection;

  Battle(this.id, this.x, this.y, this.battleSection);

  factory Battle.fromJson(dynamic json) {
    return Battle(json['id'] as String, json['x'] as int, json['y'] as int,
        json['battleSection'] as String);
  }

  @override
  String toString() {
    return '{ ${this.id}, ${this.x}, ${this.y}, ${this.battleSection} }';
  }
}

class BattleList {
  List<Battle> battles;
  int minX = 9999;
  int minY = 9999;
  int maxX = -9999;
  int maxY = -9999;

  BattleList(this.battles) {
    battles.forEach((region) {
      minX = region.x < minX ? region.x : minX;
      minY = region.y < minY ? region.y : minY;
      maxX = region.x > maxX ? region.x : maxX;
      maxY = region.y > maxY ? region.y : maxY;
    });
  }
}
