enum TagFilterState {
  neutral,  // No effect
  included, // Must have (+)
  excluded, // Must NOT have (-) [Blacklist]
}

class TagModel {
  final String name;
  final String slug;
  final int count;
  final String? category; // "Genre", "Character", "Studio", "Fetish"

  TagModel({
    required this.name,
    required this.slug,
    this.count = 0,
    this.category,
  });

  factory TagModel.fromJson(Map<String, dynamic> json) {
    return TagModel(
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      count: json['count'] ?? 0,
      category: json['category'],
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'slug': slug,
        'count': count,
        'category': category,
      };
}
