// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:dementia_care/home.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SetupProfilePage extends StatefulWidget {
  const SetupProfilePage({super.key});

  @override
  _SetupProfilePageState createState() => _SetupProfilePageState();
}

class _SetupProfilePageState extends State<SetupProfilePage> {
  int _currentStep = 0;
  final PageController _pageController = PageController();

  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();

  File? profilePicture;
  String? avatarUrl;
  bool _isSubmitting = false;

  final picker = ImagePicker();

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _dobController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _showResultDialog({
    required bool success,
    required String title,
    required String message,
    VoidCallback? onOkPressed,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: success 
                        ? Colors.green.withOpacity(0.1) 
                        : Colors.red.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    success ? Icons.check_circle : Icons.error,
                    color: success ? Colors.green : Colors.red,
                    size: 50,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      if (onOkPressed != null) {
                        onOkPressed();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: success ? Colors.green : const Color(0xFF2196F3),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'OK',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final file = File(pickedFile.path);
      setState(() {
        profilePicture = file;
      });

      try {
        final fileBytes = await file.readAsBytes();
        final fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}_${pickedFile.name}';

        await Supabase.instance.client.storage
            .from('avatars')
            .uploadBinary(
              fileName,
              fileBytes,
              fileOptions: const FileOptions(
                upsert: true,
                contentType: 'image/jpeg',
              ),
            );

        final publicUrl = Supabase.instance.client.storage
            .from('avatars')
            .getPublicUrl(fileName);

        setState(() {
          avatarUrl = publicUrl;
        });

        _showResultDialog(
          success: true,
          title: 'Image Uploaded!',
          message: 'Your profile picture has been uploaded successfully.',
        );
      } catch (e) {
        print('Image upload failed: $e');
        _showResultDialog(
          success: false,
          title: 'Upload Failed',
          message: 'Failed to upload image. Please try again.',
        );
      }
    }
  }

  void _nextStep() {
    if (_currentStep < 2) {
      if (_validateCurrentStep()) {
        setState(() {
          _currentStep += 1;
        });
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    } else {
      _submitProfile();
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep -= 1;
      });
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0:
        if (_fullNameController.text.isEmpty) {
          _showResultDialog(
            success: false,
            title: 'Missing Information',
            message: 'Please enter your full name to continue.',
          );
          return false;
        }
        break;
      case 1:
        if (_dobController.text.isEmpty) {
          _showResultDialog(
            success: false,
            title: 'Missing Information',
            message: 'Please select your date of birth to continue.',
          );
          return false;
        }
        break;
      case 2:
        if (_emailController.text.isEmpty) {
          _showResultDialog(
            success: false,
            title: 'Missing Information',
            message: 'Please enter your email address to continue.',
          );
          return false;
        }
        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(_emailController.text)) {
          _showResultDialog(
            success: false,
            title: 'Invalid Email',
            message: 'Please enter a valid email address.',
          );
          return false;
        }
        break;
    }
    return true;
  }

  String _toIsoDate(String formattedDate) {
    final parts = formattedDate.split('/');
    return DateTime(
      int.parse(parts[2]),
      int.parse(parts[1]),
      int.parse(parts[0]),
    ).toIso8601String();
  }

  Future<void> _submitProfile() async {
    if (!_validateCurrentStep()) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('No logged-in user');
      }

      await Supabase.instance.client
          .from('profile')
          .upsert({
            'id': userId,
            'full_name': _fullNameController.text.trim(),
            'date_of_birth': _toIsoDate(_dobController.text),
            'email': _emailController.text.trim(),
            'profile_picture': avatarUrl,
            'created_at': DateTime.now().toIso8601String(),
          });

      _showResultDialog(
        success: true,
        title: 'Profile Complete!',
        message: 'Your profile has been set up successfully. Welcome to DementiaCare!',
        onOkPressed: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomePage()),
          );
        },
      );
    } catch (e) {
      print('Failed to submit profile: $e');
      _showResultDialog(
        success: false,
        title: 'Setup Failed',
        message: 'Failed to complete profile setup. Please try again.',
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(),
            
            // Progress Indicator
            _buildProgressIndicator(),
            
            // Content
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildBasicInfoStep(),
                  _buildDateOfBirthStep(),
                  _buildProfilePictureStep(),
                  _buildEmailStep(),
                ],
              ),
            ),
            
            // Navigation Buttons
            _buildNavigationButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text(
            'Setup Your Profile',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Let\'s get to know you better',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: List.generate(4, (index) {
          return Expanded(
            child: Container(
              height: 4,
              margin: EdgeInsets.only(right: index < 3 ? 8 : 0),
              decoration: BoxDecoration(
                color: index <= _currentStep 
                    ? const Color(0xFF2196F3) 
                    : Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildBasicInfoStep() {
    return _buildStepContainer(
      title: 'What\'s your name?',
      subtitle: 'Please enter your full name',
      child: Column(
        children: [
          const SizedBox(height: 40),
          _buildTextField(
            controller: _fullNameController,
            label: 'Full Name',
            icon: Icons.person_outline,
            hint: 'Enter your full name',
          ),
        ],
      ),
    );
  }

  Widget _buildDateOfBirthStep() {
    return _buildStepContainer(
      title: 'When were you born?',
      subtitle: 'Please select your date of birth',
      child: Column(
        children: [
          const SizedBox(height: 40),
          _buildDateField(),
        ],
      ),
    );
  }

  Widget _buildProfilePictureStep() {
    return _buildStepContainer(
      title: 'Add a profile picture',
      subtitle: 'This helps personalize your experience (optional)',
      child: Column(
        children: [
          const SizedBox(height: 40),
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                color: profilePicture == null ? Colors.grey[100] : null,
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF2196F3).withOpacity(0.3),
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: profilePicture == null
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_a_photo,
                          size: 50,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap to add photo',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    )
                  : ClipOval(
                      child: Image.file(
                        profilePicture!,
                        fit: BoxFit.cover,
                        width: 150,
                        height: 150,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 24),
          if (profilePicture != null)
            ElevatedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.edit),
              label: const Text('Change Photo'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[100],
                foregroundColor: Colors.grey[700],
                elevation: 0,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmailStep() {
    return _buildStepContainer(
      title: 'What\'s your email?',
      subtitle: 'We\'ll use this for important updates',
      child: Column(
        children: [
          const SizedBox(height: 40),
          _buildTextField(
            controller: _emailController,
            label: 'Email Address',
            icon: Icons.email_outlined,
            hint: 'Enter your email address',
            keyboardType: TextInputType.emailAddress,
          ),
        ],
      ),
    );
  }

  Widget _buildStepContainer({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Text(
            title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2196F3),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String hint,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey[400]),
              prefixIcon: Icon(icon, color: const Color(0xFF2196F3)),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 18,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Date of Birth',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextField(
            controller: _dobController,
            readOnly: true,
            onTap: () async {
              DateTime initialDate = DateTime.now().subtract(const Duration(days: 365 * 30));
              if (_dobController.text.isNotEmpty) {
                final parts = _dobController.text.split('/');
                initialDate = DateTime(
                  int.parse(parts[2]),
                  int.parse(parts[1]),
                  int.parse(parts[0]),
                );
              }
              DateTime? pickedDate = await showDatePicker(
                context: context,
                initialDate: initialDate,
                firstDate: DateTime(1900),
                lastDate: DateTime.now(),
              );
              if (pickedDate != null) {
                setState(() {
                  _dobController.text = "${pickedDate.day}/${pickedDate.month}/${pickedDate.year}";
                });
              }
            },
            decoration: InputDecoration(
              hintText: 'Select your date of birth',
              hintStyle: TextStyle(color: Colors.grey[400]),
              prefixIcon: const Icon(Icons.cake_outlined, color: Color(0xFF2196F3)),
              suffixIcon: const Icon(Icons.calendar_today, color: Color(0xFF2196F3)),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 18,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _prevStep,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(color: Colors.grey[300]!),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Back',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 16),
          Expanded(
            flex: _currentStep == 0 ? 1 : 1,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _nextStep,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: const Color(0xFF2196F3),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      _currentStep < 3 ? 'Continue' : 'Complete Setup',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}