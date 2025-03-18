import 'package:flutter/material.dart';

class LocationSelector extends StatefulWidget {
  final Function(Map<String, dynamic>) onLocationSelected;
  final Map<String, dynamic>? initialLocation;

  const LocationSelector({
    super.key,
    required this.onLocationSelected,
    this.initialLocation,
  });

  @override
  State<LocationSelector> createState() => _LocationSelectorState();
}

class _LocationSelectorState extends State<LocationSelector>
    with SingleTickerProviderStateMixin {
  final _storeNameController = TextEditingController();
  final _addressController = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    if (widget.initialLocation != null) {
      _storeNameController.text = widget.initialLocation!['name'] ?? '';
      _addressController.text = widget.initialLocation!['address'] ?? '';
    }
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          AppBar(
            title: const Text(
              'Store Location',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            centerTitle: true,
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
          ),
          Expanded(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildInfoCard(isDark),
                    const SizedBox(height: 24),
                    _buildInputFields(isDark),
                    const Spacer(),
                    _buildSaveButton(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(bool isDark) {
    return Card(
      elevation: 0,
      color: isDark ? Colors.green[900] : Colors.green[50],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? Colors.green[800] : Colors.green[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.store_mall_directory,
                  color: isDark ? Colors.green[200] : Colors.green[800]),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                'Add your store details below',
                style: TextStyle(
                  color: isDark ? Colors.green[200] : Colors.green[800],
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputFields(bool isDark) {
    return Column(
      children: [
        TextField(
          controller: _storeNameController,
          decoration: _buildInputDecoration(
            'Store Name',
            'Enter store name',
            Icons.store,
            isDark,
          ),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _addressController,
          maxLines: 3,
          decoration: _buildInputDecoration(
            'Store Address',
            'Enter store address',
            Icons.location_on,
            isDark,
          ),
        ),
      ],
    );
  }

  InputDecoration _buildInputDecoration(
    String label,
    String hint,
    IconData icon,
    bool isDark,
  ) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: Colors.green[800]),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      filled: true,
      fillColor: isDark ? Colors.grey[800] : Colors.grey[100],
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 16,
      ),
      labelStyle:
          TextStyle(color: isDark ? Colors.green[300] : Colors.green[800]),
    );
  }

  Widget _buildSaveButton() {
    return ElevatedButton(
      onPressed: () {
        if (_storeNameController.text.isEmpty &&
            _addressController.text.isEmpty) {
          widget.onLocationSelected({});
        } else {
          widget.onLocationSelected({
            'name': _storeNameController.text,
            'address': _addressController.text,
          });
        }
        Navigator.pop(context);
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green[800],
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 4,
      ),
      child: const Text(
        'Save Location',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _storeNameController.dispose();
    _addressController.dispose();
    _animationController.dispose();
    super.dispose();
  }
}