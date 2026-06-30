// Project Model - No Hive generation needed
class ProjectModel {
  final String id;
  final String type;
  final String name;
  final int createdAt;
  final int updatedAt;
  final double duration;

  ProjectModel({
    required this.id,
    required this.type,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    required this.duration,
  });

  Map<String, dynamic> toJson() => {
    'id': id, 'type': type, 'name': name,
    'createdAt': createdAt, 'updatedAt': updatedAt, 'duration': duration,
  };

  static ProjectModel fromJson(Map<String, dynamic> json) => ProjectModel(
    id: json['id'] ?? '',
    type: json['type'] ?? 'video',
    name: json['name'] ?? '',
    createdAt: (json['createdAt'] ?? 0) as int,
    updatedAt: (json['updatedAt'] ?? 0) as int,
    duration: (json['duration'] ?? 0.0) as double,
  );
}
