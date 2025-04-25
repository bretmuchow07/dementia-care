import 'package:flutter/material.dart';

class AboutMePage extends StatefulWidget {
  const AboutMePage({super.key});

  @override
  _AboutMePageState createState() => _AboutMePageState();
}

class _AboutMePageState extends State<AboutMePage> {
  final TextEditingController _nameController = TextEditingController(text: "Jack Webster");
  final TextEditingController _emailController = TextEditingController(text: "melpeters@gmail.com");
  final TextEditingController _passwordController = TextEditingController(text: "************");
  final TextEditingController _dobController = TextEditingController(text: "23/05/1995");
  String _selectedCountry = "Nigeria";

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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundImage: AssetImage("assets/profile_picture.png"),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: CircleAvatar(
                        backgroundColor: Colors.white,
                        child: Icon(Icons.camera_alt, color: Colors.black),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30), // Spacing below the profile picture
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: "Name",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12.0)), // Curved edges
                  ),
                ),
              ),
              const SizedBox(height: 20), // Spacing between fields
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: "Email",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12.0)), // Curved edges
                  ),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 20), // Spacing between fields
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: "Password",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12.0)), // Curved edges
                  ),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 20), // Spacing between fields
              TextFormField(
                controller: _dobController,
                decoration: const InputDecoration(
                  labelText: "Date of Birth",
                  suffixIcon: Icon(Icons.calendar_today),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12.0)), // Curved edges
                  ),
                ),
                readOnly: true,
                onTap: () async {
                  DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime(1995, 5, 23),
                    firstDate: DateTime(1900),
                    lastDate: DateTime.now(),
                  );
                  if (pickedDate != null) {
                    setState(() {
                      _dobController.text = "${pickedDate.day}/${pickedDate.month}/${pickedDate.year}";
                    });
                  }
                },
              ),
              const SizedBox(height: 20), // Spacing between fields
              DropdownButtonFormField<String>(
                value: _selectedCountry,
                items: ["Nigeria", "USA", "Canada", "UK"].map((String country) {
                  return DropdownMenuItem<String>(
                    value: country,
                    child: Text(country),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _selectedCountry = newValue!;
                  });
                },
                decoration: const InputDecoration(
                  labelText: "Country/Region",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12.0)), // Curved edges
                  ),
                ),
              ),
              const SizedBox(height: 30), // Spacing before the button
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                     backgroundColor: Color(0xFF265F7E),
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text("Save",  
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 22,),
              ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
