import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:country_picker/country_picker.dart';

class AboutMePage extends StatefulWidget {
  const AboutMePage({super.key});

  @override
  _AboutMePageState createState() => _AboutMePageState();
}

class _AboutMePageState extends State<AboutMePage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  String _selectedCountry = 'Nigeria';
  bool _isLoading = true;
  String? _avatarUrl;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not logged in')),
      );
      return;
    }

    try {
      final response = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();

      setState(() {
        _nameController.text = response['full_name'] ?? '';
        _emailController.text = response['email'] ?? '';
        _dobController.text = response['dob'] != null
            ? _formatDate(response['dob'])
            : '';
        _selectedCountry = response['country'] ?? 'Nigeria';
        _avatarUrl = response['avatar_url'];
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading profile: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load profile')),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _formatDate(String isoDate) {
    final date = DateTime.parse(isoDate);
    return "${date.day}/${date.month}/${date.year}";
  }

  String _toIsoDate(String formattedDate) {
    final parts = formattedDate.split('/');
    return DateTime(
      int.parse(parts[2]),
      int.parse(parts[1]),
      int.parse(parts[0]),
    ).toIso8601String();
  }

  Future<void> _saveProfile() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not logged in')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await Supabase.instance.client.from('profiles').upsert({
        'id': userId,
        'full_name': _nameController.text,
        'email': _emailController.text,
        'dob': _dobController.text.isNotEmpty ? _toIsoDate(_dobController.text) : null,
        'country': _selectedCountry,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
    } catch (e) {
      print('Error updating profile: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update profile')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("About Me"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        titleTextStyle: const TextStyle(color: Colors.black, fontSize: 20),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundImage: _avatarUrl != null
                                ? NetworkImage(_avatarUrl!)
                                : const AssetImage("assets/profile_picture.png")
                                    as ImageProvider,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: CircleAvatar(
                              backgroundColor: Colors.white,
                              child: IconButton(
                                icon: const Icon(Icons.camera_alt, color: Colors.black),
                                onPressed: () {
                                  // TODO: Implement image picker and Supabase upload
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text('Profile picture update not implemented')),
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: "Name",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12.0)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: "Email",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12.0)),
                        ),
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _dobController,
                      decoration: const InputDecoration(
                        labelText: "Date of Birth",
                        suffixIcon: Icon(Icons.calendar_today),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12.0)),
                        ),
                      ),
                      readOnly: true,
                      onTap: () async {
                        DateTime initialDate = DateTime.now();
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
                            _dobController.text =
                                "${pickedDate.day}/${pickedDate.month}/${pickedDate.year}";
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      readOnly: true,
                      controller: TextEditingController(text: _selectedCountry),
                      decoration: const InputDecoration(
                        labelText: "Country/Region",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12.0)),
                        ),
                        suffixIcon: Icon(Icons.arrow_drop_down),
                      ),
                      onTap: () {
                        showCountryPicker(
                          context: context,
                          showPhoneCode: false,
                          onSelect: (Country country) {
                            setState(() {
                              _selectedCountry = country.name;
                            });
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton(
                      onPressed: _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF265F7E),
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: const Text(
                        "Save",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
