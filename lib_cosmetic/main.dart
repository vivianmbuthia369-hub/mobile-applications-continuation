import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // Handles the kIsWeb environment check
import 'package:sqflite/sqflite.dart';
import 'cosmetic_model.dart';
import 'database_helper.dart';

// Safe web import for the factory configuration
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    // Safely assign web factory when running inside a web browser engine
    databaseFactory = databaseFactoryFfiWeb;
  }

  runApp(const CosmeticInventoryApp());
}

class CosmeticInventoryApp extends StatelessWidget {
  const CosmeticInventoryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Cosmetics Smart Inventory',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFE91E63), // Deep Premium Pink
          primary: const Color(0xFFD81B60),
          secondary: const Color(0xFF8E24AA), // Elegant Purple Accent
        ),
        scaffoldBackgroundColor: const Color(
          0xFFFFF8F9,
        ), // Resolves background deprecation error
      ),
      home: const InventoryDashboard(),
    );
  }
}

class InventoryDashboard extends StatefulWidget {
  const InventoryDashboard({super.key});

  @override
  State<InventoryDashboard> createState() => _InventoryDashboardState();
}

class _InventoryDashboardState extends State<InventoryDashboard> {
  List<CosmeticProduct> _products = [];
  final TextEditingController _searchController = TextEditingController();

  // Primary entry form controllers (Top Card)
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _brandController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();

  // Modifying/Editing form controllers
  final TextEditingController _editNameController = TextEditingController();
  final TextEditingController _editBrandController = TextEditingController();
  final TextEditingController _editPriceController = TextEditingController();
  final TextEditingController _editQuantityController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _refreshInventory();
  }

  Future<void> _refreshInventory() async {
    final data = await DatabaseHelper.instance.readAllProducts();
    setState(() {
      _products = data;
    });
  }

  Future<void> _filterInventory(String query) async {
    if (query.isEmpty) {
      _refreshInventory();
      return;
    }
    final data = await DatabaseHelper.instance.searchProducts(query);
    setState(() {
      _products = data;
    });
  }

  // --- RUNTIME METRIC CALCULATIONS ---
  int get totalProducts => _products.length;
  int get totalItems => _products.fold(0, (sum, item) => sum + item.quantity);
  double get totalValue =>
      _products.fold(0.0, (sum, item) => sum + (item.price * item.quantity));
  int get lowStockCount => _products.where((item) => item.quantity <= 5).length;

  void _addStock() async {
    final name = _nameController.text;
    final brand = _brandController.text;
    final price = double.tryParse(_priceController.text) ?? 0.0;
    final qty = int.tryParse(_quantityController.text) ?? 0;

    if (name.isEmpty || brand.isEmpty || price <= 0 || qty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Verification Error: All cosmetic details must be populated before registering.',
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final newProduct = CosmeticProduct(
      name: name,
      brand: brand,
      price: price,
      quantity: qty,
    );

    await DatabaseHelper.instance.createProduct(newProduct);

    _nameController.clear();
    _brandController.clear();
    _priceController.clear();
    _quantityController.clear();

    _refreshInventory();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text('New product added to inventory registry.'),
      ),
    );
  }

  void _showFormDialog(CosmeticProduct product) {
    _editNameController.text = product.name;
    _editBrandController.text = product.brand;
    _editPriceController.text = product.price.toString();
    _editQuantityController.text = product.quantity.toString();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Icon(Icons.edit_note, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 10),
            const Text('Modify Product Details'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              _buildModernTextField(
                _editNameController,
                'Product Name',
                Icons.shopping_bag_outlined,
              ),
              const SizedBox(height: 16),
              _buildModernTextField(
                _editBrandController,
                'Brand / Vendor',
                Icons.branding_watermark_outlined,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildModernTextField(
                      _editPriceController,
                      'Price (KES)',
                      Icons.payments_outlined,
                      isNumber: true,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildModernTextField(
                      _editQuantityController,
                      'Stock Quantity',
                      Icons.inventory_2_outlined,
                      isNumber: true,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Dismiss',
              style: TextStyle(color: Colors.grey),
            ), // Clear from redundant evaluation bugs
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () async {
              final name = _editNameController.text;
              final brand = _editBrandController.text;
              final price = double.tryParse(_editPriceController.text) ?? 0.0;
              final qty = int.tryParse(_editQuantityController.text) ?? 0;

              if (name.isEmpty || brand.isEmpty) return;

              final updatedProduct = CosmeticProduct(
                id: product.id,
                name: name,
                brand: brand,
                price: price,
                quantity: qty,
              );

              await DatabaseHelper.instance.updateProduct(updatedProduct);
              if (!mounted) return;
              Navigator.pop(context);
              _refreshInventory();
            },
            child: const Text('Save Changes'),
          ),
        ],
      ),
    );
  }

  void _deleteProduct(int id) async {
    await DatabaseHelper.instance.deleteProduct(id);
    _refreshInventory();
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isDesktop = screenWidth > 800;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Cosmetics Smart Inventory',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 1,
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        centerTitle: true,
        elevation: 2,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- TOP METRICS ROW ---
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildMetricCard(
                  'Total Products',
                  totalProducts.toString(),
                  Icons.category,
                  Colors.pink.shade400,
                  screenWidth,
                  isDesktop,
                ),
                _buildMetricCard(
                  'Stocked Units',
                  totalItems.toString(),
                  Icons.layers,
                  Colors.purple.shade400,
                  screenWidth,
                  isDesktop,
                ),
                _buildMetricCard(
                  'Valuation (KES)',
                  'KES ${totalValue.toStringAsFixed(0)}',
                  Icons.monetization_on,
                  Colors.blue.shade600,
                  screenWidth,
                  isDesktop,
                ),
                _buildMetricCard(
                  'Reorder Alerts',
                  lowStockCount.toString(),
                  Icons.warning,
                  lowStockCount > 0 ? Colors.amber.shade800 : Colors.green,
                  screenWidth,
                  isDesktop,
                ),
              ],
            ),
            const SizedBox(height: 20),

            // --- DATA ENTRY FORM ---
            Card(
              color: Colors.white,
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Glamour Track Stock Registry',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (isDesktop)
                      Row(
                        children: [
                          Expanded(
                            child: _buildModernTextField(
                              _nameController,
                              'Product Name',
                              Icons.shopping_bag_outlined,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildModernTextField(
                              _brandController,
                              'Brand Title',
                              Icons.branding_watermark_outlined,
                            ),
                          ),
                        ],
                      )
                    else ...[
                      _buildModernTextField(
                        _nameController,
                        'Product Name',
                        Icons.shopping_bag_outlined,
                      ),
                      const SizedBox(height: 12),
                      _buildModernTextField(
                        _brandController,
                        'Brand Title',
                        Icons.branding_watermark_outlined,
                      ),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildModernTextField(
                            _priceController,
                            'Price (KES)',
                            Icons.payments_outlined,
                            isNumber: true,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildModernTextField(
                            _quantityController,
                            'Quantity',
                            Icons.inventory_2_outlined,
                            isNumber: true,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _addStock,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(Icons.playlist_add),
                          label: const Text(
                            'Register Item',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            _nameController.clear();
                            _brandController.clear();
                            _priceController.clear();
                            _quantityController.clear();
                          },
                          child: const Text('Clear Form'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // --- SEARCH REGISTRY ---
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search profiles by product name or brand...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: _filterInventory,
            ),
            const SizedBox(height: 20),

            // --- ACTIVE REGISTRY LIST ---
            const Text(
              'Active Database Records',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.black54,
              ), // Fixed black70 runtime crash
            ),
            const SizedBox(height: 10),
            _products.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Text('No database profiles matching parameters.'),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _products.length,
                    itemBuilder: (context, index) {
                      final product = _products[index];
                      final isLow = product.quantity <= 5;
                      return Card(
                        color: Colors.white,
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        elevation: 1,
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          title: Text(
                            product.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              'Brand: ${product.brand}\nPrice: KES ${product.price.toStringAsFixed(0)} | Status: ${product.quantity} Units',
                              style: const TextStyle(height: 1.4),
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isLow)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  margin: const EdgeInsets.only(right: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.shade100,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'LOW STOCK',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.amber.shade900,
                                    ),
                                  ),
                                ),
                              IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  color: Colors.blue,
                                ),
                                onPressed: () => _showFormDialog(product),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () => _deleteProduct(product.id!),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }

  // --- REUSABLE UI BUILDERS ---
  Widget _buildModernTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool isNumber = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }

  Widget _buildMetricCard(
    String title,
    String value,
    IconData icon,
    Color color,
    double screenWidth,
    bool isDesktop,
  ) {
    final double width = isDesktop
        ? (screenWidth - 64) / 4
        : (screenWidth - 44) / 2;
    return Container(
      width: width,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.pink.shade50),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.black38,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ), // Fixed black38 error
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ), // Fixed black87 error
              ],
            ),
          ),
        ],
      ),
    );
  }
}
