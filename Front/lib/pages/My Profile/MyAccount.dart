import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MyAccountPage extends StatefulWidget {
  const MyAccountPage({Key? key}) : super(key: key);

  @override
  State<MyAccountPage> createState() => _MyAccountPageState();
}

class _MyAccountPageState extends State<MyAccountPage> {
  String firstName = '';
  String lastName = '';
  String email = '';
  String phoneNumber = '';
  bool isLoading = true;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        DocumentSnapshot userData = await _firestore
            .collection('users')
            .doc(user.uid)
            .get();

        if (userData.exists) {
          setState(() {
            firstName = userData['first name'] ?? '';
            lastName = userData['last name'] ?? '';
            email = userData['email'] ?? '';
            phoneNumber = userData['phone number'] ?? '';
            isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error loading user data: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> _updateUserData(String field, String value) async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        // Update Firestore
        await _firestore.collection('users').doc(user.uid).update({
          field: value,
          'updatedAt': Timestamp.now(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Updated successfully')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating: $e')),
      );
    }
  }

  void _editField(String fieldName, String currentValue, String firestoreField) {
    final TextEditingController controller = TextEditingController(text: currentValue);
    showDialog<void>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text('Edit $fieldName'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: fieldName,
            border: const OutlineInputBorder(),
            focusedBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF276152), width: 2),
            ),
          ),
        ),
        actions: <Widget>[
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF276152),
              foregroundColor: Colors.white,
            ),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _updateUserData(firestoreField, controller.text);
              setState(() {
                if (firestoreField == 'first name') firstName = controller.text;
                if (firestoreField == 'last name') lastName = controller.text;
                if (firestoreField == 'email') email = controller.text;
                if (firestoreField == 'phone number') phoneNumber = controller.text;
              });
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF276152),
              foregroundColor: Colors.white,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _navigateToChangePassword() {
    Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (BuildContext context) => ChangePasswordPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF276152),
        body: Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF276152),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Container(
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const Text(
                    'My Account',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: <Widget>[
                    const SizedBox(height: 20),
                    _buildAccountItem(
                      icon: Icons.person_outline,
                      title: 'First Name',
                      value: firstName,
                      onTap: () => _editField('First Name', firstName, 'first name'),
                    ),
                    const SizedBox(height: 15),
                    _buildAccountItem(
                      icon: Icons.person_outline,
                      title: 'Last Name',
                      value: lastName,
                      onTap: () => _editField('Last Name', lastName, 'last name'),
                    ),
                    const SizedBox(height: 15),
                    _buildAccountItem(
                      icon: Icons.email_outlined,
                      title: 'Email',
                      value: email,
                      onTap: () => _editField('Email', email, 'email'),
                    ),
                    const SizedBox(height: 15),
                    _buildAccountItem(
                      icon: Icons.phone_outlined,
                      title: 'Phone Number',
                      value: phoneNumber,
                      onTap: () => _editField('Phone Number', phoneNumber, 'phone number'),
                    ),
                    const SizedBox(height: 15),
                    _buildPasswordItem(),
                    const SizedBox(height: 15),
                    _buildAccountItem(
                      icon: Icons.lock_outline,
                      title: 'Change Password',
                      value: '',
                      showArrow: true,
                      onTap: _navigateToChangePassword,
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

  Widget _buildAccountItem({
    required IconData icon,
    required String title,
    required String value,
    required VoidCallback onTap,
    bool showArrow = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF276152).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: const Color(0xFF276152),
                size: 24,
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value.isEmpty ? 'Tap to add' : value,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              showArrow ? Icons.arrow_forward_ios : Icons.edit,
              color: Colors.grey[400],
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordItem() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF276152).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.lock_outline,
              color: Color(0xFF276152),
              size: 24,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Password',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  '••••••••',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmNewPasswordController = TextEditingController();

  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmNewPassword = true;

  String? _currentPasswordError;
  String? _newPasswordError;
  String? _confirmNewPasswordError;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> _validateAndChangePassword() async {
    setState(() {
      _currentPasswordError = null;
      _newPasswordError = null;
      _confirmNewPasswordError = null;
    });

    bool isValid = true;

    // Validate current password (Firebase will check this)
    if (_currentPasswordController.text.isEmpty) {
      setState(() => _currentPasswordError = 'Current password cannot be empty');
      isValid = false;
    }

    // Validate new password
    if (_newPasswordController.text.isEmpty) {
      setState(() => _newPasswordError = 'New password cannot be empty');
      isValid = false;
    } else if (_newPasswordController.text.length < 6) {
      setState(() => _newPasswordError = 'Password must be at least 6 characters');
      isValid = false;
    }

    // Validate confirm new password
    if (_confirmNewPasswordController.text.isEmpty) {
      setState(() => _confirmNewPasswordError = 'Confirm password cannot be empty');
      isValid = false;
    } else if (_newPasswordController.text != _confirmNewPasswordController.text) {
      setState(() => _confirmNewPasswordError = 'Passwords do not match');
      isValid = false;
    }

    if (isValid) {
      try {
        User? user = _auth.currentUser;
        if (user != null && user.email != null) {
          // Re-authenticate user with current password
          AuthCredential credential = EmailAuthProvider.credential(
            email: user.email!,
            password: _currentPasswordController.text,
          );

          await user.reauthenticateWithCredential(credential);

          // Update password
          await user.updatePassword(_newPasswordController.text);

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Password changed successfully')),
          );

          Navigator.pop(context);
        }
      } on FirebaseAuthException catch (e) {
        String message = 'Error changing password';
        
        if (e.code == 'wrong-password') {
          setState(() => _currentPasswordError = 'Incorrect current password');
        } else if (e.code == 'weak-password') {
          setState(() => _newPasswordError = 'Password is too weak');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message)),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmNewPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF276152),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        title: const Text('Change Password'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: ListView(
                    children: <Widget>[
                      const SizedBox(height: 20),
                      _buildPasswordField(
                        controller: _currentPasswordController,
                        labelText: 'Current Password',
                        obscureText: _obscureCurrentPassword,
                        errorText: _currentPasswordError,
                        toggleVisibility: () {
                          setState(() {
                            _obscureCurrentPassword = !_obscureCurrentPassword;
                          });
                        },
                      ),
                      const SizedBox(height: 20),
                      _buildPasswordField(
                        controller: _newPasswordController,
                        labelText: 'New Password',
                        obscureText: _obscureNewPassword,
                        errorText: _newPasswordError,
                        toggleVisibility: () {
                          setState(() {
                            _obscureNewPassword = !_obscureNewPassword;
                          });
                        },
                      ),
                      const SizedBox(height: 20),
                      _buildPasswordField(
                        controller: _confirmNewPasswordController,
                        labelText: 'Confirm New Password',
                        obscureText: _obscureConfirmNewPassword,
                        errorText: _confirmNewPasswordError,
                        toggleVisibility: () {
                          setState(() {
                            _obscureConfirmNewPassword = !_obscureConfirmNewPassword;
                          });
                        },
                      ),
                      const SizedBox(height: 30),
                      ElevatedButton(
                        onPressed: _validateAndChangePassword,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          backgroundColor: const Color(0xFF276152),
                          foregroundColor: Colors.white,
                        ),
                        child: const Text(
                          'Change Password',
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String labelText,
    required bool obscureText,
    required VoidCallback toggleVisibility,
    String? errorText,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: labelText,
        errorText: errorText,
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(10)),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(10)),
          borderSide: BorderSide(color: Color(0xFF276152), width: 2),
        ),
        suffixIcon: IconButton(
          icon: Icon(
            obscureText ? Icons.visibility_off : Icons.visibility,
            color: Colors.grey,
          ),
          onPressed: toggleVisibility,
        ),
      ),
    );
  }
}