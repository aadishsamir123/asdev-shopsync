import 'package:flutter/material.dart';
import '../libraries/icons/lucide_food_map.dart';

class ChooseTaskIconScreen extends StatefulWidget {
  final FoodIconMapping? selectedIcon;

  const ChooseTaskIconScreen({
    super.key,
    this.selectedIcon,
  });

  @override
  State<ChooseTaskIconScreen> createState() => _ChooseTaskIconScreenState();
}

class _ChooseTaskIconScreenState extends State<ChooseTaskIconScreen> {
  final TextEditingController _searchController = TextEditingController();
  FoodIconMapping? _selectedIcon;
  String _selectedCategory = 'all';
  List<FoodIconMapping> _filteredIcons = [];

  final List<String> _categories = [
    'all',
    'fruits',
    'vegetables',
    'proteins',
    'desserts',
    'beverages',
    'cooking',
    'dietary',
  ];

  @override
  void initState() {
    super.initState();
    _selectedIcon = widget.selectedIcon;
    _updateFilteredIcons();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _updateFilteredIcons() {
    List<FoodIconMapping> icons;

    if (_selectedCategory == 'all') {
      icons = LucideFoodIconMap.getAllIcons();
    } else {
      icons = LucideFoodIconMap.getFoodIconsByCategory(_selectedCategory);
    }

    if (_searchController.text.isNotEmpty) {
      icons = icons
          .where((icon) =>
              icon.displayName
                  .toLowerCase()
                  .contains(_searchController.text.toLowerCase()) ||
              icon.identifier
                  .toLowerCase()
                  .contains(_searchController.text.toLowerCase()))
          .toList();
    }

    setState(() {
      _filteredIcons = icons;
    });
  }

  void _onSearchChanged(String query) {
    _updateFilteredIcons();
  }

  void _onCategoryChanged(String category) {
    setState(() {
      _selectedCategory = category;
    });
    _updateFilteredIcons();
  }

  void _onIconSelected(FoodIconMapping icon) {
    setState(() {
      _selectedIcon = icon;
    });
  }

  void _onConfirm() {
    Navigator.of(context).pop(_selectedIcon);
  }

  void _onCancel() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Choose Icon',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: isDark ? Colors.grey[900] : Colors.green[800],
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.grey[800]!.withValues(alpha: 0.5)
                  : Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark
                    ? Colors.grey[700]!
                    : Colors.white.withValues(alpha: 0.3),
              ),
            ),
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: _onCancel,
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              decoration: BoxDecoration(
                color: _selectedIcon != null
                    ? Colors.white.withValues(alpha: 0.2)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _selectedIcon != null
                      ? Colors.white.withValues(alpha: 0.3)
                      : Colors.transparent,
                ),
              ),
              child: TextButton(
                onPressed: _selectedIcon != null ? _onConfirm : null,
                child: Text(
                  'Done',
                  style: TextStyle(
                    color:
                        _selectedIcon != null ? Colors.white : Colors.white60,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      backgroundColor: isDark ? Colors.grey[900] : Colors.grey[50],
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
              ),
              decoration: InputDecoration(
                hintText: 'Search icons...',
                hintStyle: TextStyle(
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.clear,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: isDark ? Colors.grey[700]! : Colors.green[200]!,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: isDark ? Colors.grey[700]! : Colors.green[200]!,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Colors.green[800]!,
                    width: 2,
                  ),
                ),
                filled: true,
                fillColor: isDark ? Colors.grey[800] : Colors.white,
              ),
            ),
          ),

          // Category Chips
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = _selectedCategory == category;

                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: FilterChip(
                    label: Text(
                      category == 'all'
                          ? 'All'
                          : category.substring(0, 1).toUpperCase() +
                              category.substring(1),
                      style: TextStyle(
                        color: isSelected
                            ? (isDark ? Colors.white : Colors.green[800])
                            : (isDark ? Colors.grey[300] : Colors.grey[700]),
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        _onCategoryChanged(category);
                      }
                    },
                    backgroundColor:
                        isDark ? Colors.grey[800] : Colors.grey[100],
                    selectedColor:
                        isDark ? Colors.green[800] : Colors.green[100],
                    checkmarkColor: isDark ? Colors.white : Colors.green[800],
                    side: BorderSide(
                      color: isSelected
                          ? Colors.green[800]!
                          : (isDark ? Colors.grey[600]! : Colors.grey[300]!),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 16),

          // Selected Icon Preview
          if (_selectedIcon != null)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16.0),
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: isDark ? Colors.green[800] : Colors.green[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.green[800]!,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.green[700] : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _selectedIcon!.icon,
                      size: 24,
                      color: isDark ? Colors.white : Colors.green[800],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Selected: ${_selectedIcon!.displayName}',
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.green[800],
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.check_circle,
                    color: isDark ? Colors.white : Colors.green[800],
                    size: 24,
                  ),
                ],
              ),
            ),

          if (_selectedIcon != null) const SizedBox(height: 16),

          // Icons Grid
          Expanded(
            child: _filteredIcons.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 64,
                          color: isDark ? Colors.grey[600] : Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No icons found',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Try adjusting your search or category filter',
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? Colors.grey[500] : Colors.grey[500],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(16.0),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1,
                    ),
                    itemCount: _filteredIcons.length,
                    itemBuilder: (context, index) {
                      final icon = _filteredIcons[index];
                      final isSelected =
                          _selectedIcon?.identifier == icon.identifier;

                      return GestureDetector(
                        onTap: () => _onIconSelected(icon),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? (isDark
                                    ? Colors.green[800]
                                    : Colors.green[100])
                                : (isDark ? Colors.grey[800] : Colors.white),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? Colors.green[800]!
                                  : (isDark
                                      ? Colors.grey[600]!
                                      : Colors.grey[300]!),
                              width: isSelected ? 2 : 1,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: Colors.green[800]!
                                          .withValues(alpha: 0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                          alpha: isDark ? 0.3 : 0.1),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                icon.icon,
                                size: 28,
                                color: isSelected
                                    ? (isDark
                                        ? Colors.white
                                        : Colors.green[800])
                                    : (isDark
                                        ? Colors.grey[300]
                                        : Colors.grey[700]),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                icon.displayName,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: isSelected
                                      ? (isDark
                                          ? Colors.white
                                          : Colors.green[800])
                                      : (isDark
                                          ? Colors.grey[400]
                                          : Colors.grey[600]),
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
