class Region {
  String id;
  int x;
  int y;
  String name;
  String terrain;
  String description;
  String battleSection;
  int trees;
  int saplings;
  int peasants;
  int horses;
  int silver;
  int entertainment;
  int recruits;
  int wage;

  Region(
      this.id,
      this.x,
      this.y,
      this.name,
      this.terrain,
      this.description,
      this.battleSection,
      this.trees,
      this.saplings,
      this.peasants,
      this.horses,
      this.silver,
      this.entertainment,
      this.recruits,
      this.wage);

  factory Region.fromJson(dynamic json) {
    return Region(
        json['id'] as String,
        json['x'] as int,
        json['y'] as int,
        json['name'] as String,
        json['terrain'] as String,
        json['description'] as String,
        json['battleSection'] as String,
        json['trees'] as int,
        json['saplings'] as int,
        json['peasants'] as int,
        json['horses'] as int,
        json['silver'] as int,
        json['entertainment'] as int,
        json['recruits'] as int,
        json['wage'] as int);
  }

  @override
  String toString() {
    return '{ ${this.id}, ${this.x}, ${this.y}, ${this.name}, ${this.terrain} }';
  }
}

class RegionList {
  List<Region> regions;
  int minX = 9999;
  int minY = 9999;
  int maxX = -9999;
  int maxY = -9999;

  RegionList(this.regions) {
    regions.forEach((region) {
      minX = region.x < minX ? region.x : minX;
      minY = region.y < minY ? region.y : minY;
      maxX = region.x > maxX ? region.x : maxX;
      maxY = region.y > maxY ? region.y : maxY;
    });
  }
}
