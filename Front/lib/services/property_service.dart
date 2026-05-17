import 'package:shared_preferences/shared_preferences.dart';
import '../models/cards.dart';
import 'api_service.dart';

class PropertyService {
  // ===== 1. FETCH ALL PROPERTIES (for HomePage) =====
  Stream<List<PropertyModel>> getAllProperties() async* {
    try {
      final response = await ApiService().dio.get('/properties');
      if (response.data['success'] == true) {
        List<dynamic> data = response.data['data']['properties'] ?? response.data['data'] ?? [];
        yield data.map((e) => PropertyModel.fromJson(e)).toList();
      } else {
        yield [];
      }
    } catch (e) {
      print('Error getting all properties: $e');
      yield [];
    }
  }

  // ===== 2. FETCH SINGLE PROPERTY (for Property Details Page) =====
  Future<PropertyModel?> getPropertyById(String propertyId) async {
    try {
      final response = await ApiService().dio.get('/properties/$propertyId');
      if (response.data['success'] == true) {
        return PropertyModel.fromJson(response.data['data']['property'] ?? response.data['data']);
      }
      return null;
    } catch (e) {
      print('Error fetching property: $e');
      return null;
    }
  }

  // ===== 3. ADD NEW PROPERTY (for AddApartmentPage) =====
  Future<bool> addProperty({
    required String title,
    required String description,
    required double price,
    required PropertyLocation location,
    required int bedrooms,
    required int bathrooms,
    required int kitchens,
    required int balconies,
    required List<String> amenities,
    required List<String> imageUrls,
  }) async {
    try {
      print('📤 Starting property upload...');
      final response = await ApiService().dio.post('/properties', data: {
        'title': title,
        'description': description,
        'price': price,
        'location': location.toMap(),
        'bedrooms': bedrooms,
        'bathrooms': bathrooms,
        'kitchens': kitchens,
        'balconies': balconies,
        'amenities': amenities,
        'images': imageUrls,
        'mainImage': imageUrls.isNotEmpty ? imageUrls.first : '',
        'status': 'available',
        'isPublished': true,
      });
      return response.data['success'] == true;
    } catch (e) {
      print('❌ Error adding property: $e');
      return false;
    }
  }

  // ===== 4. UPDATE PROPERTY =====
  Future<bool> updateProperty(PropertyModel property) async {
    try {
      final response = await ApiService().dio.put('/properties/${property.propertyId}', data: property.toJson());
      return response.data['success'] == true;
    } catch (e) {
      print('Error updating property: $e');
      return false;
    }
  }

  // ===== 5. DELETE PROPERTY =====
  Future<bool> deleteProperty(String propertyId) async {
    try {
      final response = await ApiService().dio.delete('/properties/$propertyId');
      return response.data['success'] == true;
    } catch (e) {
      print('Error deleting property: $e');
      return false;
    }
  }

  // ===== 6. SEARCH PROPERTIES =====
  Future<List<PropertyModel>> searchProperties(String query) async {
    try {
      final response = await ApiService().dio.get('/properties');
      if (response.data['success'] == true) {
        List<dynamic> data = response.data['data']['properties'] ?? response.data['data'] ?? [];
        List<PropertyModel> all = data.map((e) => PropertyModel.fromJson(e)).toList();
        return all.where((p) => p.title.toLowerCase().contains(query.toLowerCase()) || p.location.fullAddress.toLowerCase().contains(query.toLowerCase())).toList();
      }
      return [];
    } catch (e) {
      print('Error searching properties: $e');
      return [];
    }
  }

  // ===== 7. FILTER PROPERTIES (IN-MEMORY SOLUTION) =====
  Future<List<PropertyModel>> filterProperties({
    double? minPrice,
    double? maxPrice,
    String? propertyType,
    int? bedrooms,
    int? bathrooms,
    int? kitchens,
    int? balconies,
    List<String>? amenities,
  }) async {
    try {
      final response = await ApiService().dio.get('/properties');
      if (response.data['success'] == true) {
        List<dynamic> data = response.data['data']['properties'] ?? response.data['data'] ?? [];
        List<PropertyModel> allProperties = data.map((e) => PropertyModel.fromJson(e)).toList();
        
        return allProperties.where((property) {
          if (minPrice != null && property.price < minPrice) return false;
          if (maxPrice != null && property.price > maxPrice) return false;
          if (bedrooms != null && property.bedrooms != bedrooms) return false;
          if (bathrooms != null && property.bathrooms != bathrooms) return false;
          if (kitchens != null && property.kitchens != kitchens) return false;
          if (balconies != null && property.balconies != balconies) return false;
          
          if (amenities != null && amenities.isNotEmpty) {
            if (property.amenities == null || property.amenities.isEmpty) return false;
            List<String> normalizedPropertyAmenities = property.amenities.map((a) => a.toLowerCase().trim()).toList();
            bool hasAllAmenities = amenities.every((amenity) {
              String normalizedAmenity = amenity.toLowerCase().trim();
              return normalizedPropertyAmenities.any((propAmenity) {
                if (normalizedAmenity.contains('air condition') && propAmenity.contains('air condition')) return true;
                if (normalizedAmenity == 'tv' && propAmenity == 'tv') return true;
                return propAmenity == normalizedAmenity;
              });
            });
            if (!hasAllAmenities) return false;
          }
          return true;
        }).toList();
      }
      return [];
    } catch (e) {
      print('❌ Error filtering properties: $e');
      return [];
    }
  }

  // ===== 8. SAVE/UNSAVE PROPERTY (Toggle Favorite) =====
  Future<bool> toggleSavedProperty(String propertyId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> saved = prefs.getStringList('saved_properties') ?? [];
      if (saved.contains(propertyId)) {
        saved.remove(propertyId);
      } else {
        saved.add(propertyId);
      }
      await prefs.setStringList('saved_properties', saved);
      return true;
    } catch (e) {
      print('❌ Error toggling saved property: $e');
      return false;
    }
  }

  // ===== 9. CHECK IF PROPERTY IS SAVED =====
  Future<bool> isPropertySaved(String propertyId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> saved = prefs.getStringList('saved_properties') ?? [];
      return saved.contains(propertyId);
    } catch (e) {
      return false;
    }
  }

  // ===== 10. GET ALL SAVED PROPERTIES =====
  Stream<List<PropertyModel>> getAllSavedProperties() async* {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> savedIds = prefs.getStringList('saved_properties') ?? [];
      List<PropertyModel> properties = [];
      for (String id in savedIds) {
        PropertyModel? prop = await getPropertyById(id);
        if (prop != null) properties.add(prop);
      }
      yield properties;
    } catch (e) {
      yield [];
    }
  }

  // ===== 11. GET USER'S OWN PROPERTIES =====
  Stream<List<PropertyModel>> getUserProperties() async* {
    try {
      final me = await ApiService().dio.get('/auth/me');
      String myId = me.data['data']['user']['_id'];
      
      final propsRes = await ApiService().dio.get('/properties');
      if (propsRes.data['success'] == true) {
        List<dynamic> data = propsRes.data['data']['properties'] ?? propsRes.data['data'] ?? [];
        List<PropertyModel> all = data.map((e) => PropertyModel.fromJson(e)).toList();
        yield all.where((p) => p.userId == myId).toList();
      } else {
        yield [];
      }
    } catch (e) {
      yield [];
    }
  }

  // ===== 12. SAVE RECENT SEARCH =====
  Future<bool> saveRecentSearch(PropertyModel property) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> recent = prefs.getStringList('recent_searches') ?? [];
      recent.remove(property.propertyId);
      recent.insert(0, property.propertyId);
      if (recent.length > 5) recent = recent.sublist(0, 5);
      await prefs.setStringList('recent_searches', recent);
      return true;
    } catch (e) {
      return false;
    }
  }

  // ===== 13. GET RECENT SEARCHES (Stream) =====
  Stream<List<PropertyModel>> getRecentSearches({int limit = 5}) async* {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> recent = prefs.getStringList('recent_searches') ?? [];
      List<PropertyModel> properties = [];
      for (String id in recent.take(limit)) {
        PropertyModel? prop = await getPropertyById(id);
        if (prop != null) properties.add(prop);
      }
      yield properties;
    } catch (e) {
      yield [];
    }
  }

  // ===== 14. CLEAR ALL RECENT SEARCHES =====
  Future<bool> clearRecentSearches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('recent_searches');
      return true;
    } catch (e) {
      return false;
    }
  }

  // ===== 15. DELETE SINGLE RECENT SEARCH =====
  Future<bool> deleteRecentSearch(String propertyId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> recent = prefs.getStringList('recent_searches') ?? [];
      recent.remove(propertyId);
      await prefs.setStringList('recent_searches', recent);
      return true;
    } catch (e) {
      return false;
    }
  }

  // ===== 16. BOOK PROPERTY =====
  Future<bool> bookProperty(String propertyId, {DateTime? startDate, DateTime? endDate}) async {
    try {
      final response = await ApiService().dio.post('/bookings', data: {
        'propertyId': propertyId,
        'checkIn': startDate?.toIso8601String(),
        'checkOut': endDate?.toIso8601String(),
        'guests': 1,
        'totalPrice': 0, // Should be calculated or pass property price
      });
      return response.data['success'] == true;
    } catch (e) {
      print('❌ Error booking property: $e');
      return false;
    }
  }

  // ===== 17. GET BOOKED PROPERTIES =====
  Stream<List<PropertyModel>> getBookedProperties() async* {
    try {
      final response = await ApiService().dio.get('/bookings/my-bookings');
      if (response.data['success'] == true) {
        List<dynamic> data = response.data['data']['bookings'] ?? response.data['data'] ?? [];
        List<PropertyModel> properties = [];
        for (var b in data) {
          if (b['propertyId'] != null) {
            String pId = b['propertyId'] is Map ? b['propertyId']['_id'] : b['propertyId'];
            PropertyModel? prop = await getPropertyById(pId);
            if (prop != null) properties.add(prop);
          }
        }
        yield properties;
      } else {
        yield [];
      }
    } catch (e) {
      yield [];
    }
  }

  // ===== 18. CHECK IF PROPERTY IS BOOKED BY CURRENT USER =====
  Future<bool> isPropertyBookedByUser(String propertyId) async {
    try {
      final response = await ApiService().dio.get('/bookings/my-bookings');
      if (response.data['success'] == true) {
        List<dynamic> data = response.data['data']['bookings'] ?? response.data['data'] ?? [];
        for (var b in data) {
          String pId = b['propertyId'] is Map ? b['propertyId']['_id'] : b['propertyId'];
          if (pId == propertyId) return true;
        }
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // ===== 19. CHECK IF PROPERTY IS BOOKED BY ANYONE =====
  Future<bool> isPropertyBookedByAnyone(String propertyId) async {
    try {
      PropertyModel? property = await getPropertyById(propertyId);
      if (property == null) return false;
      return property.status != 'available';
    } catch (e) {
      return false;
    }
  }
}