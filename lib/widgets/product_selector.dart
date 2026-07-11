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

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8EAF1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'اختيار الكارت',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 19),
                ),
              ),
              _GroupSwitch(
                selected: _group,
                onChanged: _changeGroup,
              ),
            ],
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth > 640 ? 4 : 3;
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  mainAxisSpacing: 9,
                  crossAxisSpacing: 9,
                  childAspectRatio: constraints.maxWidth > 380 ? 1.75 : 1.45,
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
    );
  }

  void _changeGroup(ProductGroup group) {
    setState(() => _group = group);
    final firstProduct = VodafoneApiService.products.firstWhere(
      (product) => product.group == group,
    );
    widget.onChanged(firstProduct);
  }
}

class _GroupSwitch extends StatelessWidget {
  const _GroupSwitch({
    required this.selected,
    required this.onChanged,
  });

  final ProductGroup selected;
  final ValueChanged<ProductGroup> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F8),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE1E5EE)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _GroupButton(
            label: 'فكة',
            selected: selected == ProductGroup.fakka,
            onTap: () => onChanged(ProductGroup.fakka),
          ),
          _GroupButton(
            label: 'مارد',
            selected: selected == ProductGroup.mared,
            onTap: () => onChanged(ProductGroup.mared),
          ),
        ],
      ),
    );
  }
}

class _GroupButton extends StatelessWidget {
  const _GroupButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: 66,
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: selected ? primary : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : const Color(0xFF475467),
            fontWeight: FontWeight.w800,
          ),
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
    final primary = Theme.of(context).colorScheme.primary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: selected ? primary.withOpacity(.08) : const Color(0xFFFBFCFE),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? primary : const Color(0xFFE3E7EF),
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: AlignmentDirectional.topEnd,
              child: Icon(
                selected ? Icons.check_circle_rounded : Icons.circle_outlined,
                size: 20,
                color: selected ? primary : const Color(0xFF98A2B3),
              ),
            ),
            const Spacer(),
            Text(
              _labelFor(product),
              maxLines: 2,
              overflow: TextOverflow.fade,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: const Color(0xFF1D2939),
                fontSize: 14,
                height: 1.15,
                fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _labelFor(FakaProduct product) {
    final id = product.id;
    if (id.startsWith('Mared_10_Minuts')) return 'مارد 10 دقائق';
    if (id.startsWith('Mared_10_Flexs')) return 'مارد 10 فليكس';
    if (id.startsWith('Mared_10_Social')) return 'مارد 10 سوشيال';

    final value = RegExp(r'Fakka_([^_]+)').firstMatch(id)?.group(1) ?? id;
    final isNew = id.contains('New');
    return isNew ? 'فكة $value جديد' : 'فكة $value';
  }
}
