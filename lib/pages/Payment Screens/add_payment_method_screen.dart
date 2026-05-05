import 'package:flutter/material.dart';
import 'package:sakkeny_app/models/cards.dart';
import 'add_card_details_screen.dart';

class AddPaymentMethodScreen extends StatefulWidget {
  final PropertyModel property;
  final DateTime moveInDate;
  final int rentalMonths;
  final int adults;
  final int children;
  final double totalPrice;

  const AddPaymentMethodScreen({
    Key? key,
    required this.property,
    required this.moveInDate,
    required this.rentalMonths,
    required this.adults,
    required this.children,
    required this.totalPrice,
  }) : super(key: key);

  @override
  State<AddPaymentMethodScreen> createState() => _AddPaymentMethodScreenState();
}

class _AddPaymentMethodScreenState extends State<AddPaymentMethodScreen> {
  String selectedPaymentMethod = 'card'; // 'card', 'paypal', 'googlepay'

  // ✅ Format date
  String get moveInDateText {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${widget.moveInDate.day} ${months[widget.moveInDate.month - 1]} ${widget.moveInDate.year}';
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
          'Add a payment method',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.black),
            onPressed: () {
              Navigator.popUntil(context, (route) => route.isFirst);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // ✅ Booking Summary Header
          _buildBookingSummary(),
          
          const Divider(height: 1),
          
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Choose how to pay',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  
                  // ✅ Payment Options
                  _buildPaymentOption(
                    'card',
                    'Credit or debit card',
                    Icons.credit_card,
                    'Pay with your card',
                  ),
                  const SizedBox(height: 12),
                  
                  _buildPaymentOption(
                    'paypal',
                    'PayPal',
                    Icons.account_balance_wallet,
                    'Pay with PayPal account',
                  ),
                  const SizedBox(height: 12),
                  
                  _buildPaymentOption(
                    'googlepay',
                    'Google Pay',
                    Icons.payment,
                    'Pay with Google Pay',
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // ✅ Security Notice
                  _buildSecurityNotice(),
                ],
              ),
            ),
          ),
          
          // ✅ Bottom Bar with Total & Next Button
          _buildBottomBar(),
        ],
      ),
    );
  }

  // ✅ Booking Summary Header
  Widget _buildBookingSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[50],
      child: Row(
        children: [
          // Property Image
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              widget.property.mainImage,
              width: 60,
              height: 60,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 60,
                  height: 60,
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
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  moveInDateText,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(height: 2),
                Text(
                  '${widget.rentalMonths} month${widget.rentalMonths > 1 ? 's' : ''} · ${widget.adults} guest${widget.adults > 1 ? 's' : ''}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'Total',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              Text(
                'EGP ${widget.totalPrice.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ✅ Payment Option Card
  Widget _buildPaymentOption(
    String value,
    String title,
    IconData icon,
    String subtitle,
  ) {
    final isSelected = selectedPaymentMethod == value;
    
    return InkWell(
      onTap: () {
        setState(() {
          selectedPaymentMethod = value;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? const Color(0xFF276152) : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected ? const Color(0xFF276152).withOpacity(0.05) : Colors.white,
        ),
        child: Row(
          children: [
            // Icon Container
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected 
                    ? const Color(0xFF276152).withOpacity(0.1)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                size: 24,
                color: isSelected ? const Color(0xFF276152) : Colors.grey[700],
              ),
            ),
            const SizedBox(width: 16),
            
            // Title & Subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? const Color(0xFF276152) : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            
            // Radio Button
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? const Color(0xFF276152) : Colors.grey.shade400,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF276152),
                        ),
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  // ✅ Security Notice
  Widget _buildSecurityNotice() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.shield_outlined, color: Colors.blue[700], size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your payment is secure',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue[900],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'All transactions are encrypted and secure',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ✅ Bottom Bar
  Widget _buildBottomBar() {
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
            // Total Price
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Total',
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                  Text(
                    'EGP ${widget.totalPrice.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            
            // Next Button
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: () {
                  _proceedToPayment();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF276152),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  _getButtonText(),
                  style: const TextStyle(
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

  // ✅ Get Button Text Based on Payment Method
  String _getButtonText() {
    switch (selectedPaymentMethod) {
      case 'paypal':
        return 'Continue with PayPal';
      case 'googlepay':
        return 'Continue with Google Pay';
      default:
        return 'Add Card';
    }
  }

  // ✅ Proceed to Payment
  void _proceedToPayment() {
    if (selectedPaymentMethod == 'card') {
      // Navigate to card details screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AddCardDetailsScreen(
            property: widget.property,
            moveInDate: widget.moveInDate,
            rentalMonths: widget.rentalMonths,
            adults: widget.adults,
            children: widget.children,
            totalPrice: widget.totalPrice,
          ),
        ),
      );
    } else if (selectedPaymentMethod == 'paypal') {
      // Show PayPal integration (placeholder)
      _showComingSoonDialog('PayPal');
    } else if (selectedPaymentMethod == 'googlepay') {
      // Show Google Pay integration (placeholder)
      _showComingSoonDialog('Google Pay');
    }
  }

  // ✅ Coming Soon Dialog
  void _showComingSoonDialog(String method) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$method Integration'),
        content: Text('$method payment is coming soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}