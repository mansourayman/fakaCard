import 'package:flutter/material.dart';

import '../models/faka_product.dart';
import '../services/vodafone_api_service.dart';

class ProductSelector extends StatefulWidget {
  const ProductSelector({
    required this.selected,
    required this.onChanged,
    super.key,
  });

  final FakaProduct selected;
  final ValueChanged<FakaProduct> onChanged;

  @override
  State<ProductSelector> createState() => _ProductSelectorState();
}

class _ProductSelectorState extends State<ProductSelector> {
  ProductGroup _group = ProductGroup.fakka;

  @override
  Widget build(BuildContext context) {
    final products = VodafoneApiService.products
        .where((product) => product.group == _group)
        .toList(growable: false);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'اختيار الكارت',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                  ),
                ),
                SegmentedButton<ProductGroup>(
                  segments: const [
                    ButtonSegment(
                      value: ProductGroup.fakka,
                      label: Text('فكة'),
                    ),
                    ButtonSegment(
                      value: ProductGroup.mared,
                      label: Text('مارد'),
                    ),
                  ],
                  selected: {_group},
                  onSelectionChanged: (values) {
                    final group = values.first;
                    setState(() => _group = group);
                    final firstProduct = VodafoneApiService.products.firstWhere(
                      (product) => product.group == group,
                    );
                    widget.onChanged(firstProduct);
                  },
                  showSelectedIcon: false,
                ),
              ],
            ),
            const SizedBox(height: 14),
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth > 620 ? 3 : 2;
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 2.5,
                  ),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];
                    return _ProductTile(
                      product: product,
                      selected: widget.selected.id == product.id,
                      onTap: () => widget.onChanged(product),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductTile extends StatelessWidget {
  const _ProductTile({
    required this.product,
    required this.selected,
    required this.onTap,
  });

  final FakaProduct product;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? colors.primary.withOpacity(.09) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? colors.primary : const Color(0xFFE5E7EF),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_unchecked_rounded,
              size: 19,
              color: selected ? colors.primary : const Color(0xFF8B92A1),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                product.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  color: const Color(0xFF202432),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
