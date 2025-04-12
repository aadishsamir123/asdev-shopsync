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
            color: Colors.black.withValues(alpha: 0.2),
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
      elevation: 2,
      color: isDark ? const Color(0xFF1B5E20) : const Color(0xFFE8F5E9),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color:
                    isDark ? const Color(0xFF2E7D32) : const Color(0xFFC8E6C9),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? Colors.black.withValues(alpha: 0.2)
                        : Colors.green.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.store_mall_directory,
                color: isDark ? Colors.white : const Color(0xFF2E7D32),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                'Add your store details below',
                style: TextStyle(
                  color: isDark ? Colors.white : const Color(0xFF1B5E20),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
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
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
          ),
          decoration: InputDecoration(
            labelText: 'Store name',
            labelStyle: TextStyle(
              color: isDark ? Colors.grey[400] : Colors.grey[700],
            ),
            filled: true,
            fillColor:
                isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF5F5F5),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: isDark ? Colors.grey[600]! : Colors.grey[400]!,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: Colors.green.shade400,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _addressController,
          maxLines: 3,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
          ),
          decoration: InputDecoration(
            labelText: 'Store Address',
            labelStyle: TextStyle(
              color: isDark ? Colors.grey[400] : Colors.grey[700],
            ),
            filled: true,
            fillColor:
                isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF5F5F5),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: isDark ? Colors.grey[600]! : Colors.grey[400]!,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: Colors.green.shade400,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
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
