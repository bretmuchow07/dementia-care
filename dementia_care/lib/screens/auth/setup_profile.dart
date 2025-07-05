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
  final _formKey = GlobalKey<FormState>();

  String? fullName;
  int? age;
  File? profilePicture;
  String? email;
  String? avatarUrl;

  final picker = ImagePicker();

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

        // Upload to Supabase Storage
        await Supabase.instance.client.storage
            .from('profile_pictures')
            .uploadBinary(
              fileName,
              fileBytes,
              fileOptions: const FileOptions(
                upsert: true,
                contentType: 'image/jpeg',
              ),
            );

        // Get public URL
        final publicUrl = Supabase.instance.client.storage
            .from('profile_pictures')
            .getPublicUrl(fileName);

        setState(() {
          avatarUrl = publicUrl;
        });

        print('Image uploaded to Supabase! URL: $publicUrl');

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image uploaded successfully')),
        );
      } catch (e) {
        print('Image upload failed: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to upload image')),
        );
      }
    }
  }

  void _nextStep() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      if (_currentStep < 2) {
        setState(() {
          _currentStep += 1;
        });
      } else {
        _submitProfile();
      }
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep -= 1;
      });
    }
  }

  Future<void> _submitProfile() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('No logged-in user');
      }

      await Supabase.instance.client
          .from('profiles')
          .upsert({
            'id': userId,
            'full_name': fullName,
            'age': age,
            'email': email,
            'avatar_url': avatarUrl,
          });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile submitted!')),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
    } catch (e) {
      print('Failed to submit profile: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to submit profile')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Setup Profile')),
      body: Form(
        key: _formKey,
        child: Stepper(
          currentStep: _currentStep,
          onStepContinue: _nextStep,
          onStepCancel: _prevStep,
          steps: [
            Step(
              title: const Text('Basic Info'),
              isActive: _currentStep >= 0,
              content: Column(
                children: [
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Full Name'),
                    validator: (value) =>
                        value == null || value.isEmpty ? 'Enter your name' : null,
                    onSaved: (value) => fullName = value,
                  ),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Age'),
                    keyboardType: TextInputType.number,
                    validator: (value) =>
                        value == null || int.tryParse(value) == null
                            ? 'Enter a valid age'
                            : null,
                    onSaved: (value) => age = int.tryParse(value!),
                  ),
                ],
              ),
            ),
            Step(
              title: const Text('Profile Picture'),
              isActive: _currentStep >= 1,
              content: Column(
                children: [
                  profilePicture == null
                      ? const Text('No image selected.')
                      : Image.file(profilePicture!, height: 100),
                  ElevatedButton(
                    onPressed: _pickImage,
                    child: const Text('Pick Profile Picture'),
                  ),
                ],
              ),
            ),
            Step(
              title: const Text('Email'),
              isActive: _currentStep >= 2,
              content: TextFormField(
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Enter your email';
                  }
                  final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                  if (!emailRegex.hasMatch(value)) {
                    return 'Enter a valid email';
                  }
                  return null;
                },
                onSaved: (value) => email = value,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
