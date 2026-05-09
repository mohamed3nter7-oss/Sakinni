import 'package:flutter/material.dart';
import 'package:sakkeny_app/models/cards.dart';
import 'add_payment_method_screen.dart';

class ReviewAndContinueScreen extends StatefulWidget {
  final PropertyModel property;

  const ReviewAndContinueScreen({
    Key? key,
    required this.property,
  }) : super(key: key);

  @override
  State<ReviewAndContinueScreen> createState() => _ReviewAndContinueScreenState();
}

class _ReviewAndContinueScreenState extends State<ReviewAndContinueScreen> {
  // ✅ Rental details (for monthly home rental)
  DateTime moveInDate = DateTime.now().add(const Duration(days: 7));
  int rentalMonths = 1;
  int adults = 1;
  int children = 0;

  // ✅ Calculate base monthly rent
  double get baseMonthlyRent => widget.property.price;

  // ✅ Calculate fees (percentage-based)
  double get cleaningFeePercent => 5.0;
  double get serviceFeePercent => 3.0;
  
  double get cleaningFee => (baseMonthlyRent * cleaningFeePercent) / 100;
  double get serviceFee => (baseMonthlyRent * serviceFeePercent) / 100;

  // ✅ Calculate total price
  double get totalPrice => (baseMonthlyRent * rentalMonths) + cleaningFee + serviceFee;

  // ✅ Format move-in date
  String get moveInDateText {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${moveInDate.day} ${months[moveInDate.month - 1]} ${moveInDate.year}';
  }

  // ✅ Format guests
  String get guestsText {
    if (children == 0) return '$adults adult${adults > 1 ? 's' : ''}';
    return '$adults adult${adults > 1 ? 's' : ''}, $children child${children > 1 ? 'ren' : ''}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Review',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ✅ Property Card
                  _buildPropertyCard(),
                  
                  const SizedBox(height: 24),
                  
                  const Text(
                    'Rental Details',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // ✅ Move-in Date
                  _buildInfoRow(
                    'Move-in date',
                    moveInDateText,
                    icon: Icons.calendar_today,
                    onTap: _showDatePicker,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // ✅ Rental Duration
                  _buildInfoRow(
                    'Rental period',
                    '$rentalMonths month${rentalMonths > 1 ? 's' : ''}',
                    icon: Icons.access_time,
                    onTap: _showMonthsPicker,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // ✅ Guests
                  _buildInfoRow(
                    'Guests',
                    guestsText,
                    icon: Icons.person_outline,
                    onTap: _showGuestPicker,
                  ),
                  
                  const SizedBox(height: 24),
                  
                  const Divider(),
                  
                  const SizedBox(height: 16),
                  
                  // ✅ Price Breakdown
                  _buildPriceBreakdown(),
                ],
              ),
            ),
          ),
          
          // ✅ Bottom Bar
          _buildBottomBar(context),
        ],
      ),
    );
  }

  // ✅ Property Card
  Widget _buildPropertyCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              widget.property.mainImage,
              width: 90,
              height: 90,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 90,
                  height: 90,
                  color: Colors.grey[300],
                  child: const Icon(Icons.image, color: Colors.grey),
                );
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.property.title,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),

              ],
            ),
          ),
        ],
      ),
    );
  }

  // ✅ Info Row
  Widget _buildInfoRow(
    String label,
    String value, {
    IconData? icon,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 20, color: Colors.grey[700]),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              Icon(Icons.edit, size: 18, color: Colors.grey[600]),
          ],
        ),
      ),
    );
  }

  // ✅ Price Breakdown
  Widget _buildPriceBreakdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Price details',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        _buildPriceRow(
          'EGP ${baseMonthlyRent.toStringAsFixed(0)} x $rentalMonths month${rentalMonths > 1 ? 's' : ''}',
          'EGP ${(baseMonthlyRent * rentalMonths).toStringAsFixed(0)}',
        ),
        const SizedBox(height: 12),
        _buildPriceRow(
          'Cleaning fee (${cleaningFeePercent.toStringAsFixed(0)}%)',
          'EGP ${cleaningFee.toStringAsFixed(0)}',
        ),
        const SizedBox(height: 12),
        _buildPriceRow(
          'Service fee (${serviceFeePercent.toStringAsFixed(0)}%)',
          'EGP ${serviceFee.toStringAsFixed(0)}',
        ),
        const Divider(height: 32),
        _buildPriceRow(
          'Total (EGP)',
          'EGP ${totalPrice.toStringAsFixed(0)}',
          isTotal: true,
        ),
      ],
    );
  }

  Widget _buildPriceRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: isTotal ? 16 : 14,
                fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                color: isTotal ? Colors.black : Colors.grey[700],
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ✅ Bottom Bar
  Widget _buildBottomBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'EGP ${totalPrice.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '$rentalMonths month${rentalMonths > 1 ? 's' : ''} rental',
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddPaymentMethodScreen(
                        property: widget.property,
                        moveInDate: moveInDate,
                        rentalMonths: rentalMonths,
                        adults: adults,
                        children: children,
                        totalPrice: totalPrice,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF276152),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Continue',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ Date Picker
  Future<void> _showDatePicker() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: moveInDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF276152),
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null && picked != moveInDate) {
      setState(() {
        moveInDate = picked;
      });
    }
  }

  // ✅ Months Picker
  Future<void> _showMonthsPicker() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Rental Period'),
        content: StatefulBuilder(
          builder: (context, setDialogState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('How many months?', style: TextStyle(fontSize: 14)),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed: rentalMonths > 1
                          ? () => setDialogState(() => rentalMonths--)
                          : null,
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$rentalMonths',
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      onPressed: rentalMonths < 12
                          ? () => setDialogState(() => rentalMonths++)
                          : null,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '$rentalMonths month${rentalMonths > 1 ? 's' : ''}',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {}); // Update main screen
              Navigator.pop(context);
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  // ✅ Guest Picker
  Future<void> _showGuestPicker() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Guests'),
        content: StatefulBuilder(
          builder: (context, setDialogState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildGuestCounter('Adults', adults, (value) {
                  setDialogState(() => adults = value);
                }),
                const SizedBox(height: 16),
                _buildGuestCounter('Children', children, (value) {
                  setDialogState(() => children = value);
                }),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {}); // Update main screen
              Navigator.pop(context);
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  Widget _buildGuestCounter(String label, int count, Function(int) onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 16)),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              onPressed: count > (label == 'Adults' ? 1 : 0)
                  ? () => onChanged(count - 1)
                  : null,
            ),
            Text('$count', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: count < 10 ? () => onChanged(count + 1) : null,
            ),
          ],
        ),
      ],
    );
  }
}