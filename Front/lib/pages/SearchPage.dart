import 'package:flutter/material.dart';
import 'package:sakkeny_app/models/cards.dart';
import 'package:sakkeny_app/pages/property.dart';
import 'package:sakkeny_app/pages/property_card.dart';
import 'package:sakkeny_app/services/property_service.dart';

class PropertySearchPage extends StatefulWidget {
  final List<PropertyModel> properties;

  const PropertySearchPage({super.key, required this.properties});

  @override
  State<PropertySearchPage> createState() => _PropertySearchPageState();
}

class _PropertySearchPageState extends State<PropertySearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final PropertyService _propertyService = PropertyService();
  
  List<PropertyModel> _searchResults = [];

  @override
  void initState() {
    super.initState();
    print('🔍 Search page opened');
    print('📊 Total properties available: ${widget.properties.length}');
  }

  void _onSearchChanged(String query) {
    print('🔎 Search query: "$query"');
    
    if (query.trim().isEmpty) {
      setState(() => _searchResults = []);
      return;
    }

    setState(() {
      _searchResults = widget.properties.where((property) {
        final q = query.toLowerCase();
        final matchesTitle = property.title.toLowerCase().contains(q);
        final matchesFullAddress = property.location.fullAddress.toLowerCase().contains(q);
        final matchesCity = property.location.city.toLowerCase().contains(q);
        final matchesArea = property.location.area.toLowerCase().contains(q);
        
        // Debug print for first property
        if (widget.properties.indexOf(property) == 0) {
          print('🏠 Sample property:');
          print('   Title: ${property.title}');
          print('   City: ${property.location.city}');
          print('   Area: ${property.location.area}');
          print('   Full Address: ${property.location.fullAddress}');
        }
        
        return matchesTitle || matchesFullAddress || matchesCity || matchesArea;
      }).toList();
      
      print('✅ Found ${_searchResults.length} results');
    });
  }

  // ✅ Save to Firestore when user taps a property
  Future<void> _addToRecent(PropertyModel property) async {
    print('💾 Saving to recent searches...');
    print('   Property ID: ${property.propertyId}');
    print('   Property Title: ${property.title}');
    
    bool success = await _propertyService.saveRecentSearch(property);
    
    if (success) {
      print('✅ Successfully saved to Firestore');
    } else {
      print('❌ Failed to save to Firestore');
    }
  }

  // ✅ Clear all recent searches
  Future<void> _clearRecentSearches() async {
    print('🗑️ Clearing recent searches...');
    bool success = await _propertyService.clearRecentSearches();
    
    if (success && mounted) {
      print('✅ Recent searches cleared');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Recent searches cleared'),
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      print('❌ Failed to clear searches');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSearching = _searchController.text.isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Search Properties'),
        actions: [
          if (!isSearching)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _clearRecentSearches,
              tooltip: 'Clear recent searches',
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search by city, area, title',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ),
          Expanded(
            child: isSearching ? _buildResults() : _buildRecent(),
          ),
        ],
      ),
    );
  }

  // ✅ Search Results Grid
  Widget _buildResults() {
    if (_searchResults.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No properties found',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.75,
      ),
      itemCount: _searchResults.length,
      itemBuilder: (_, index) {
        final property = _searchResults[index];
        return GestureDetector(
          onTap: () async {
            print('👆 User tapped on: ${property.title}');
            
            // ✅ Save to Firestore BEFORE navigation
            await _addToRecent(property);
            
            if (mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PropertyDetailsPage(property: property),
                ),
              );
            }
          },
          child: PropertyCard(
            price: property.priceDisplay,
            title: property.title,
            location: property.location.fullAddress,
            imagePath: property.mainImage,
            propertyId: property.propertyId,
          ),
        );
      },
    );
  }

  // ✅ Recent Searches from Firestore (StreamBuilder)
  Widget _buildRecent() {
    print('📡 Building recent searches widget...');
    
    return StreamBuilder<List<PropertyModel>>(
      stream: _propertyService.getRecentSearches(limit: 5),
      builder: (context, snapshot) {
        print('📊 StreamBuilder state: ${snapshot.connectionState}');
        print('📊 Has data: ${snapshot.hasData}');
        print('📊 Has error: ${snapshot.hasError}');
        
        if (snapshot.hasError) {
          print('❌ Stream error: ${snapshot.error}');
        }
        
        if (snapshot.hasData) {
          print('📊 Recent searches count: ${snapshot.data!.length}');
          for (var prop in snapshot.data!) {
            print('   - ${prop.title}');
          }
        }
        
        // Loading state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  color: Color(0xFF276152),
                ),
                SizedBox(height: 16),
                Text('Loading recent searches...'),
              ],
            ),
          );
        }

        // Error state
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Error: ${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    setState(() {}); // Retry
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        // Empty state
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No recent searches',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                SizedBox(height: 8),
                Text(
                  'Search for properties to see them here',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        // Display recent searches
        final recentSearches = snapshot.data!;
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: recentSearches.length,
          itemBuilder: (_, index) {
            final property = recentSearches[index];
            return Dismissible(
              key: Key(property.propertyId),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.delete,
                  color: Colors.white,
                  size: 30,
                ),
              ),
              confirmDismiss: (direction) async {
                // Show confirmation dialog
                return await showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text('Delete Search'),
                      content: Text('Remove "${property.title}" from recent searches?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red,
                          ),
                          child: const Text('Delete'),
                        ),
                      ],
                    );
                  },
                );
              },
              onDismissed: (direction) async {
                print('🗑️ Deleting recent search: ${property.title}');
                bool success = await _propertyService.deleteRecentSearch(property.propertyId);
                
                if (success && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('✅ Removed from recent searches'),
                      duration: const Duration(seconds: 2),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  );
                } else {
                  print('❌ Failed to delete search');
                }
              },
              child: Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 2,
                child: ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      property.mainImage,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 60,
                        height: 60,
                        color: Colors.grey[300],
                        child: const Icon(Icons.image_not_supported),
                      ),
                    ),
                  ),
                  title: Text(
                    property.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    property.location.fullAddress,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    print('👆 Navigating to: ${property.title}');
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PropertyDetailsPage(property: property),
                      ),
                    );
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}