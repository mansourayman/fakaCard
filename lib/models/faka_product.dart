enum ProductGroup { fakka, mared }

class FakaProduct {
  const FakaProduct({
    required this.id,
    required this.group,
  });

  final String id;
  final ProductGroup group;

  String get title => id.replaceAll('_', ' ');
}
