import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sakkeny_app/models/cards.dart';
import 'package:sakkeny_app/pages/AddApartmentPage.dart';
import 'package:sakkeny_app/pages/property.dart';
import 'package:sakkeny_app/services/property_service.dart';

class MyListingsPage extends StatefulWidget {
  const MyListingsPage({super.key});

  @override
  State<MyListingsPage> createState() => _MyListingsPageState();
}

class _MyListingsPageState extends State<MyListingsPage> {
  final PropertyService _propertyService = PropertyService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String _fullName = "User";
  String? _imageUrl;
  bool _loadingUser = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  /* ================= LOAD USER DATA ================= */

  Future<void> _loadUserData() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        final data = doc.data();
        setState(() {
          _fullName = data?['first name'] ?? "User";
          _imageUrl = data?['profile_image'] ?? user.photoURL;
          _loadingUser = false;
        });
      } else {
        _loadingUser = false;
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
      _loadingUser = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FE),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: const Text(
          "My Listings",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: StreamBuilder<List<PropertyModel>>(
        stream: _propertyService.getUserProperties(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF276152)),
            );
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final properties = snapshot.data ?? [];

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _profileHeader(),
              const SizedBox(height: 8),
              Expanded(
                child: properties.isEmpty
                    ? _emptyState()
                    : _gridListings(properties),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF276152),
        foregroundColor: Colors.white,
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AddApartmentPage(),
            ),
          );

          if (result == true && mounted) {
            setState(() {});
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  /* ================= PROFILE HEADER ================= */

  Widget _profileHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundImage: _imageUrl != null
                ? NetworkImage(_imageUrl!)
                : const NetworkImage(
                    "https://upload.wikimedia.org/wikipedia/commons/7/7c/Profile_avatar_placeholder_large.png",
                  ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _loadingUser
                  ? const SizedBox(
                      width: 80,
                      height: 14,
                      child: LinearProgressIndicator(),
                    )
                  : Text(
                      _fullName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
              const SizedBox(height: 4),
              const Text(
                "My Apartments",
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /* ================= GRID ================= */

  Widget _gridListings(List<PropertyModel> properties) {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: properties.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 0.72,
      ),
      itemBuilder: (context, index) {
        final property = properties[index];
        return _apartmentCard(property);
      },
    );
  }

  /* ================= CARD ================= */

  Widget _apartmentCard(PropertyModel property) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PropertyDetailsPage(property: property),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 11,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    child: Image.network(
                      property.mainImage,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Center(
                        child: Icon(Icons.home, size: 35, color: Colors.grey),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () => _toggleStatus(property),
                      child: _statusChip(property.status == 'available'),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 9,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      property.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(Icons.location_on,
                            size: 11, color: Colors.grey[600]),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            property.location.city,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${property.price.toStringAsFixed(0)} EGP",
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        color: Color(0xFF276152),
                      ),
                    ),
                    const Spacer(),

                    // ===== EDIT & DELETE (ADDED) =====
                    Container(
                      height: 28,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () => _editApartment(property),
                              child: const Icon(
                                Icons.edit_outlined,
                                size: 15,
                                color: Color(0xFF276152),
                              ),
                            ),
                          ),
                          Container(width: 1, color: Colors.grey[300]),
                          Expanded(
                            child: InkWell(
                              onTap: () => _deleteApartment(property),
                              child: const Icon(
                                Icons.delete_outline,
                                size: 15,
                                color: Colors.red,
                              ),
                            ),
                          ),
                        ],
                      ),
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

  Widget _statusChip(bool available) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: available ? Colors.green : Colors.red,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        available ? "Available" : "Rented",
        style: const TextStyle(
          fontSize: 9,
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  /* ================= EDIT ================= */

  void _editApartment(PropertyModel property) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddApartmentPage(property: property),
      ),
    );

    if (result == true && mounted) {
      setState(() {});
    }
  }

  /* ================= DELETE ================= */

  void _deleteApartment(PropertyModel property) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Property"),
        content: Text(
          "Are you sure you want to delete '${property.title}'?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);

              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) => const Center(
                  child: CircularProgressIndicator(),
                ),
              );

              bool success = await _propertyService.deleteProperty(
                property.propertyId,
              );

              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? '✅ Property deleted successfully'
                          : '❌ Failed to delete property',
                    ),
                    backgroundColor:
                        success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  /* ================= TOGGLE STATUS ================= */

  void _toggleStatus(PropertyModel property) async {
    final newStatus = property.status == 'available' ? 'rented' : 'available';

    final updatedProperty = PropertyModel(
      propertyId: property.propertyId,
      userId: property.userId,
      userName: property.userName,
      userImage: property.userImage,
      title: property.title,
      description: property.description,
      price: property.price,
      priceDisplay: property.priceDisplay,
      location: property.location,
      bedrooms: property.bedrooms,
      bathrooms: property.bathrooms,
      kitchens: property.kitchens,
      balconies: property.balconies,
      amenities: property.amenities,
      isWifi: property.isWifi,
      images: property.images,
      mainImage: property.mainImage,
      rating: property.rating,
      status: newStatus,
      isPublished: property.isPublished,
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    bool success = await _propertyService.updateProperty(updatedProperty);

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? '✅ Status updated to $newStatus'
                : '❌ Failed to update status',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.home_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text(
            "No apartments added yet",
            style: TextStyle(
              color: Colors.grey,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Tap the + button to add your first property",
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}
