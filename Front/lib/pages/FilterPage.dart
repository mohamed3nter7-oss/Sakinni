import 'package:flutter/material.dart';
import 'package:sakkeny_app/pages/HomePage.dart';

class FilterPage extends StatefulWidget {
  const FilterPage({Key? key}) : super(key: key);

  @override
  State<FilterPage> createState() => _FilterPageState();
}

class _FilterPageState extends State<FilterPage> {
  RangeValues? _priceRange;

  int? selectedBedroom;
  int? selectedBathroom;
  int? selectedKitchen;   // ✅ NEW
  int? selectedBalcony;   // ✅ NEW

  Map<String, bool> amenities = {
    'Air Conditioner': false,
    'Wifi': false,
    'Closet': false,
    'Iron': false,
    'Tv': false,
    'Dedicted work-Space': false,
  };

  static const Color primaryColor = Color(0xFF276152);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade200.withOpacity(0.4),
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          margin: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(color: Colors.black12, blurRadius: 10),
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                const SizedBox(height: 20),

                // PRICE RANGE
                const Text(
                  'Price Range',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                RangeSlider(
                  min: 100,
                  max: 50000,
                  values: _priceRange ?? const RangeValues(100, 50000),
                  activeColor: primaryColor,
                  onChanged: (value) {
                    setState(() => _priceRange = value);
                  },
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('#${(_priceRange?.start ?? 100).toInt()}'),
                    Text('#${(_priceRange?.end ?? 50000).toInt()}'),
                  ],
                ),

                const SizedBox(height: 20),

                // BEDROOMS
                const Text(
                  'Bedrooms',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  children: List.generate(
                    5,
                    (i) => _numberChip(
                      i + 1,
                      selectedBedroom,
                      (v) => setState(() => selectedBedroom = v),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // BATHROOMS
                const Text(
                  'Bathrooms',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  children: List.generate(
                    3,
                    (i) => _numberChip(
                      i + 1,
                      selectedBathroom,
                      (v) => setState(() => selectedBathroom = v),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // KITCHENS ✅
                const Text(
                  'Kitchens',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  children: List.generate(
                    3,
                    (i) => _numberChip(
                      i + 1,
                      selectedKitchen,
                      (v) => setState(() => selectedKitchen = v),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // BALCONIES ✅
                const Text(
                  'Balconies',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  children: List.generate(
                    4,
                    (i) => _numberChip(
                      i,
                      selectedBalcony,
                      (v) => setState(() => selectedBalcony = v),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // AMENITIES
                const Text(
                  'Amenities',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Column(
                  children: amenities.keys.map((key) {
                    return CheckboxListTile(
                      activeColor: primaryColor,
                      value: amenities[key],
                      onChanged: (v) =>
                          setState(() => amenities[key] = v!),
                      title: Text(key),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 20),

                // BUTTONS
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () {
                        setState(() {
                          _priceRange = null;
                          selectedBedroom = null;
                          selectedBathroom = null;
                          selectedKitchen = null;
                          selectedBalcony = null;
                          amenities.updateAll((key, value) => false);
                        });
                      },
                      child: const Text('Clear Filters'),
                    ),

                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                      ),
                      onPressed: () {
                        List<String> selectedAmenities = amenities.entries
                            .where((e) => e.value)
                            .map((e) => e.key)
                            .toList();

                        double? minPrice;
                        double? maxPrice;

                        if (_priceRange != null) {
                          if (_priceRange!.start > 100) {
                            minPrice = _priceRange!.start;
                          }
                          if (_priceRange!.end < 50000) {
                            maxPrice = _priceRange!.end;
                          }
                        }

                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => HomePage(
                              minPrice: minPrice,
                              maxPrice: maxPrice,
                              bedrooms: selectedBedroom,
                              bathrooms: selectedBathroom,
                              kitchens: selectedKitchen,   // ✅
                              balconies: selectedBalcony,  // ✅
                              amenities: selectedAmenities.isNotEmpty
                                  ? selectedAmenities
                                  : null,
                            ),
                          ),
                        );
                      },
                      child: const Text(
                        'Show Results',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _numberChip(int number, int? selected, Function(int?) onSelect) {
    final bool isSelected = selected == number;
    return ChoiceChip(
      showCheckmark: true,
      checkmarkColor: Colors.white,
      label: Text(
        number.toString(),
        style: TextStyle(color: isSelected ? Colors.white : Colors.black),
      ),
      selected: isSelected,
      selectedColor: primaryColor,
      backgroundColor: Colors.grey.shade200,
      onSelected: (_) => onSelect(isSelected ? null : number),
    );
  }
}