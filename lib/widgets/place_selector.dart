import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class LocationSelector extends StatefulWidget {
  final Function(Map<String, dynamic>) onLocationSelected;
  final Map<String, dynamic>? initialLocation;

  const LocationSelector({
    super.key,
    required this.onLocationSelected,
    this.initialLocation,
  });

  static void show(
      BuildContext context, Function(Map<String, dynamic>) onLocationSelected,
      {Map<String, dynamic>? initialLocation}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => LocationSelector(
        onLocationSelected: onLocationSelected,
        initialLocation: initialLocation,
      ),
    );
  }

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

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              'Enter Store Location',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _buildStoreNameCard(isDark),
            const SizedBox(height: 16),
            _buildAddressCard(isDark),
            const SizedBox(height: 24),
            _buildSaveButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildStoreNameCard(bool isDark) {
    return Card(
      elevation: 8,
      shadowColor: isDark ? Colors.black87 : Colors.grey[300],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.green[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: FaIcon(FontAwesomeIcons.shop, color: Colors.green[800]),
        ),
        title: TextField(
          controller: _storeNameController,
          style: TextStyle(color: isDark ? Colors.white : Colors.black),
          decoration: InputDecoration(
            border: InputBorder.none,
            labelStyle: TextStyle(
                color: isDark ? Colors.green[400] : Colors.green[800]),
            labelText: 'Store name',
          ),
        ),
      ),
    );
  }

  Widget _buildAddressCard(bool isDark) {
    return Card(
      elevation: 8,
      shadowColor: isDark ? Colors.black87 : Colors.grey[300],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.green[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: FaIcon(FontAwesomeIcons.locationDot, color: Colors.green[800]),
        ),
        title: TextField(
          controller: _addressController,
          maxLines: 3,
          style: TextStyle(color: isDark ? Colors.white : Colors.black),
          decoration: InputDecoration(
            border: InputBorder.none,
            labelStyle: TextStyle(
                color: isDark ? Colors.green[400] : Colors.green[800]),
            labelText: 'Store address',
          ),
        ),
      ),
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          FaIcon(FontAwesomeIcons.floppyDisk, size: 18),
          SizedBox(width: 8),
          Text('Save Changes'),
        ],
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
