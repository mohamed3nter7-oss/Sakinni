import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:sakkeny_app/pages/My%20Profile/MyListingsPage%20.dart';
import 'package:sakkeny_app/services/api_service.dart';
import 'package:image_picker/image_picker.dart';

import 'package:sakkeny_app/pages/My Profile/MyAccount.dart';
import 'package:sakkeny_app/pages/My Profile/Settings.dart';
import 'package:sakkeny_app/pages/My Profile/NotificationsPage.dart';
import 'package:sakkeny_app/pages/My Profile/SupportPage.dart';
import 'package:sakkeny_app/pages/Startup pages/sign_in.dart';
import 'package:sakkeny_app/pages/Saved_List.dart';

class ProfileScreen extends StatefulWidget {
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? _imageUrl;
  String? _name = "";
  String? _lastname = "";
  String? _status = "HomeFinder";
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final response = await ApiService().dio.get('/auth/me');
      if (response.data['success'] == true) {
        final data = response.data['data']['user'];
        setState(() {
          _name = data['firstName'] ?? "User";
          _lastname = data['lastName'] ?? "";
          _imageUrl = data['profileImage'] ?? null;
        });
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
    }
  }

  Future<void> _deleteOldProfileImage() async {
    // Not applicable
  }

  Future<void> _uploadProfileImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 75,
    );

    if (image == null) return;

    setState(() {
      _isUploading = true;
    });

    try {
      final Uint8List bytes = await image.readAsBytes();
      final String mimeType = image.mimeType ?? 'image/jpeg';
      final String base64Image = 'data:$mimeType;base64,${base64Encode(bytes)}';

      final meResponse = await ApiService().dio.get('/auth/me');
      if (meResponse.data['success'] != true) throw Exception('Could not get user info');
      final String userId = meResponse.data['data']['user']['_id'];

      final updateResponse = await ApiService().dio.patch(
        '/users/$userId',
        data: {'profileImage': base64Image},
      );

      if (updateResponse.data['success'] == true) {
        setState(() {
          _imageUrl = base64Image;
          _isUploading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile photo updated!'),
              backgroundColor: Color(0xFF276152),
            ),
          );
        }
      } else {
        throw Exception('Update failed');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update photo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 18),
          child: Column(
            children: [
              GestureDetector(
                onTap: _isUploading ? null : _uploadProfileImage,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircleAvatar(
                      radius: 44,
                      backgroundImage: _imageUrl != null
                          ? NetworkImage(_imageUrl!)
                          : null,
                      child: _imageUrl == null
                          ? Icon(Icons.person, size: 50, color: Colors.grey)
                          : null,
                    ),
                    if (_isUploading)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black26,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              SizedBox(height: 14),
              Text(
                '$_name $_lastname',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),

              SizedBox(height: 6),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _status!,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.green[700],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              SizedBox(height: 30),

              // MENU SECTION
              Expanded(
                child: ListView(
                  children: [
                    buildMenuItem(
                      icon: Icons.home_work_outlined,
                      text: "My Listings",
                      iconColor: Colors.grey,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const MyListingsPage(),
                          ),
                        );
                      },
                    ),
                    buildMenuItem(
                      icon: Icons.apartment_outlined,
                      text: "Booked Apartments",
                      iconColor: Colors.grey,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const SavedPage()),
                        );
                      },
                    ),
                    buildMenuItem(
                      icon: Icons.person_outline,
                      text: "My Account",
                      iconColor: Colors.grey,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => MyAccountPage()),
                        );
                      },
                    ),
                    buildMenuItem(
                      icon: Icons.notifications_outlined,
                      text: "Notifications",
                      iconColor: Colors.grey,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => NotificationsPage(),
                          ),
                        );
                      },
                    ),
                    buildMenuItem(
                      icon: Icons.headset_mic_outlined,
                      text: "Support",
                      iconColor: Colors.grey,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => SupportPage()),
                        );
                      },
                    ),
                    buildMenuItem(
                      icon: Icons.settings_outlined,
                      text: "Settings",
                      iconColor: Colors.grey,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => SettingsPage()),
                        );
                      },
                    ),
                    buildMenuItem(
                      icon: Icons.logout,
                      text: "Logout",
                      iconColor: Colors.red,
                      textColor: Colors.red,
                      onTap: () async {
                        // Sign out from ApiService
                        await ApiService().logout();

                        // Navigate to sign in page
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (_) => SignIn()),
                          (route) => false, // Remove all previous routes
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildMenuItem({
    required IconData icon,
    required String text,
    Color? iconColor,
    Color? textColor,
    VoidCallback? onTap,
  }) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 4),
      color: Colors.white,
      elevation: 0,
      child: ListTile(
        leading: Icon(icon, color: iconColor),
        title: Text(
          text,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: textColor ?? Colors.black87,
          ),
        ),
        trailing: const Icon(
          Icons.keyboard_arrow_right,
          size: 22,
          color: Colors.grey,
        ),
        onTap: onTap,
      ),
    );
  }
}
