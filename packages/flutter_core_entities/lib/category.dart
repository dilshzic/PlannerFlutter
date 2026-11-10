import 'package:uuid/uuid.dart';

class Category {
  final String id;
  final String name;
  final String colorHex;
  final String? iconName;
  final String? userId;

  Category({
    String? id,
    required this.name,
    required this.colorHex,
    this.iconName,
    this.userId,
  }) : id = id ?? const Uuid().v4();

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'] as String,
      name: map['name'] as String,
      colorHex: map['colorHex'] as String,
      iconName: map['iconName'] as String?,
      userId: map['userId'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'colorHex': colorHex,
      'iconName': iconName,
      'userId': userId,
    };
  }
}
