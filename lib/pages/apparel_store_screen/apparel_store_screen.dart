import 'package:flutter/material.dart';

class ApparelScreen extends StatefulWidget {
  const ApparelScreen({super.key});

  @override
  State<ApparelScreen> createState() => _ApparelScreenState();
}

class _ApparelScreenState extends State<ApparelScreen> {
  String selectedCategory = 'All';
  Set<String> likedProducts = {};

  final List<String> categories = [
    'All',
    'T-Shirts',
    'Hoodies',
    'Jerseys',
    'Shorts',
    'Accessories',
    'Equipment',
  ];

  // Mock product data with dummy images
  final List<Map<String, dynamic>> products = [
    {
      'id': '1',
      'name': 'Factory Elite T-Shirt',
      'price': 29.99,
      'originalPrice': null,
      'category': 'T-Shirts',
      'sizes': ['S', 'M', 'L', 'XL', 'XXL'],
      'colors': [Colors.black, Colors.white, const Color(0xFFB8FF00)],
      'rating': 4.8,
      'reviews': 124,
      'isNew': true,
      'isSale': false,
      'imageUrl':
          'https://images.unsplash.com/photo-1521572163474-6864f9cf17ab?w=300&h=300&fit=crop',
    },
    {
      'id': '2',
      'name': 'Performance Hoodie',
      'price': 59.99,
      'originalPrice': 79.99,
      'category': 'Hoodies',
      'sizes': ['S', 'M', 'L', 'XL'],
      'colors': [Colors.black, Colors.grey, const Color(0xFFB8FF00)],
      'rating': 4.9,
      'reviews': 87,
      'isNew': false,
      'isSale': true,
      'imageUrl':
          'https://images.unsplash.com/photo-1556821840-3a63f95609a7?w=300&h=300&fit=crop',
    },
    {
      'id': '3',
      'name': 'Training Jersey',
      'price': 49.99,
      'originalPrice': null,
      'category': 'Jerseys',
      'sizes': ['S', 'M', 'L', 'XL', 'XXL'],
      'colors': [Colors.white, const Color(0xFFB8FF00), Colors.blue],
      'rating': 4.7,
      'reviews': 203,
      'isNew': false,
      'isSale': false,
      'imageUrl':
          'https://images.unsplash.com/photo-1551698618-1dfe5d97d256?w=300&h=300&fit=crop',
    },
    {
      'id': '4',
      'name': 'Athletic Shorts',
      'price': 34.99,
      'originalPrice': null,
      'category': 'Shorts',
      'sizes': ['S', 'M', 'L', 'XL'],
      'colors': [Colors.black, Colors.grey, Colors.blue],
      'rating': 4.6,
      'reviews': 95,
      'isNew': true,
      'isSale': false,
      'imageUrl':
          'https://images.unsplash.com/photo-1591195853828-11db59a44f6b?w=300&h=300&fit=crop',
    },
    {
      'id': '5',
      'name': 'Factory Cap',
      'price': 24.99,
      'originalPrice': 29.99,
      'category': 'Accessories',
      'sizes': ['One Size'],
      'colors': [Colors.black, const Color(0xFFB8FF00), Colors.white],
      'rating': 4.5,
      'reviews': 67,
      'isNew': false,
      'isSale': true,
      'imageUrl':
          'https://images.unsplash.com/photo-1588850561407-ed78c282e89b?w=300&h=300&fit=crop',
    },
    {
      'id': '6',
      'name': 'Training Stick',
      'price': 129.99,
      'originalPrice': null,
      'category': 'Equipment',
      'sizes': ['Youth', 'Adult'],
      'colors': [const Color(0xFFB8FF00), Colors.black],
      'rating': 4.9,
      'reviews': 156,
      'isNew': true,
      'isSale': false,
      'imageUrl':
          'https://images.unsplash.com/photo-1578662996442-48f60103fc96?w=300&h=300&fit=crop',
    },
  ];

  List<Map<String, dynamic>> get filteredProducts {
    if (selectedCategory == 'All') {
      return products;
    }
    return products
        .where((product) => product['category'] == selectedCategory)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Factory Store',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined, color: Colors.white),
            onPressed: () {
              // Navigate to cart
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Category Filter
          Container(
            height: 50,
            margin: const EdgeInsets.symmetric(vertical: 16),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                final isSelected = category == selectedCategory;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedCategory = category;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color:
                          isSelected
                              ? const Color(0xFFB8FF00)
                              : const Color(0xFF2A2A2A),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color:
                            isSelected
                                ? const Color(0xFFB8FF00)
                                : const Color(0xFF404040),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        category,
                        style: TextStyle(
                          color: isSelected ? Colors.black : Colors.white,
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Products Grid
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75, // Adjusted for better proportions
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: filteredProducts.length,
              itemBuilder: (context, index) {
                return _buildProductCard(filteredProducts[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    return GestureDetector(
      onTap: () => _showProductDetails(product),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF404040)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                ),
                child: Stack(
                  children: [
                    // Product Image
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                      child: Container(
                        width: double.infinity,
                        height: double.infinity,
                        color: Colors.grey[800],
                        child: Image.network(
                          product['imageUrl'],
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[800],
                              child: Icon(
                                _getCategoryIcon(product['category']),
                                color: Colors.white.withOpacity(0.8),
                                size: 40,
                              ),
                            );
                          },
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              color: Colors.grey[800],
                              child: Center(
                                child: CircularProgressIndicator(
                                  value:
                                      loadingProgress.expectedTotalBytes != null
                                          ? loadingProgress
                                                  .cumulativeBytesLoaded /
                                              loadingProgress
                                                  .expectedTotalBytes!
                                          : null,
                                  color: const Color(0xFFB8FF00),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    // Badges
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (product['isNew'])
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFB8FF00),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'NEW',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          if (product['isSale'])
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'SALE',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    // Favorite Button
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            if (likedProducts.contains(product['id'])) {
                              likedProducts.remove(product['id']);
                            } else {
                              likedProducts.add(product['id']);
                            }
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            likedProducts.contains(product['id'])
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color:
                                likedProducts.contains(product['id'])
                                    ? const Color(0xFFB8FF00)
                                    : Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Product Info
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(10), // Reduced padding
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Product Name
                    Text(
                      product['name'],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13, // Slightly smaller
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),

                    // Rating
                    Row(
                      children: [
                        Row(
                          children: List.generate(5, (index) {
                            return Icon(
                              index < product['rating'].floor()
                                  ? Icons.star
                                  : Icons.star_border,
                              color: const Color(0xFFB8FF00),
                              size: 11, // Smaller stars
                            );
                          }),
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            '(${product['reviews']})',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 9,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),

                    const Spacer(),

                    // Price
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '\$${product['price'].toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Color(0xFFB8FF00),
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (product['originalPrice'] != null)
                          Text(
                            '\$${product['originalPrice'].toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 11,
                              decoration: TextDecoration.lineThrough,
                              height: 1.0,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'T-Shirts':
        return Icons.checkroom;
      case 'Hoodies':
        return Icons.checkroom;
      case 'Jerseys':
        return Icons.sports;
      case 'Shorts':
        return Icons.checkroom;
      case 'Accessories':
        return Icons.shopping_bag;
      case 'Equipment':
        return Icons.sports_hockey;
      default:
        return Icons.shopping_bag;
    }
  }

  void _showProductDetails(Map<String, dynamic> product) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF2A2A2A),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Product Image
                  Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.grey[800],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        product['imageUrl'],
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[800],
                            child: Icon(
                              _getCategoryIcon(product['category']),
                              color: Colors.white.withOpacity(0.8),
                              size: 60,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Product name and price
                  Text(
                    product['name'],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        '\$${product['price'].toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Color(0xFFB8FF00),
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (product['originalPrice'] != null) ...[
                        const SizedBox(width: 12),
                        Text(
                          '\$${product['originalPrice'].toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Sizes
                  const Text(
                    'Size',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children:
                        product['sizes'].map<Widget>((size) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: const Color(0xFF404040),
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              size,
                              style: const TextStyle(color: Colors.white),
                            ),
                          );
                        }).toList(),
                  ),
                  const Spacer(),

                  // Add to cart button
                  Container(
                    width: double.infinity,
                    height: 50,
                    margin: const EdgeInsets.only(bottom: 20),
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${product['name']} added to cart!'),
                            backgroundColor: const Color(0xFFB8FF00),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFB8FF00),
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Add to Cart',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
