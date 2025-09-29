import 'dart:io'; // Add this import for File class
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../../providers/profile_provider.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  late TextEditingController _fullNameController;
  late TextEditingController _clubTeamController;
  late TextEditingController _schoolController;
  late TextEditingController _graduationYearController;
  late TextEditingController _instagramController;
  late TextEditingController _streetController;
  late TextEditingController _cityController;
  late TextEditingController _stateController;
  late TextEditingController _zipController;

  DateTime? _selectedDate;
  String _selectedPosition = 'Other';

  final List<String> positions = [
    'Goalkeeper',
    'Defender',
    'Midfield',
    'Forward',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadProfile();
  }

  void _initializeControllers() {
    _fullNameController = TextEditingController();
    _clubTeamController = TextEditingController();
    _schoolController = TextEditingController();
    _graduationYearController = TextEditingController();
    _instagramController = TextEditingController();
    _streetController = TextEditingController();
    _cityController = TextEditingController();
    _stateController = TextEditingController();
    _zipController = TextEditingController();
  }

  void _loadProfile() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProfileProvider>().loadProfile();
    });
  }

  void _populateFields() {
    final profile = context.read<ProfileProvider>().profile;
    if (profile != null) {
      _fullNameController.text = profile.fullName ?? '';
      _clubTeamController.text = profile.clubTeam ?? '';
      _schoolController.text = profile.school ?? '';
      _graduationYearController.text = profile.graduationYear?.toString() ?? '';
      _instagramController.text = profile.instagramHandle ?? '';
      _streetController.text = profile.address?.street ?? '';
      _cityController.text = profile.address?.city ?? '';
      _stateController.text = profile.address?.state ?? '';
      _zipController.text = profile.address?.zip ?? '';
      _selectedDate = profile.dob;
      _selectedPosition = profile.position ?? 'Other';
    }
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );

    if (image != null) {
      try {
        await context.read<ProfileProvider>().uploadAvatar(File(image.path));
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Avatar updated successfully!')));
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to update avatar')));
      }
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime(2000),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      try {
        await context.read<ProfileProvider>().updateProfile(
          fullName: _fullNameController.text,
          dob: _selectedDate,
          street: _streetController.text,
          city: _cityController.text,
          state: _stateController.text,
          zip: _zipController.text,
          clubTeam: _clubTeamController.text,
          school: _schoolController.text,
          graduationYear: int.tryParse(_graduationYearController.text),
          position: _selectedPosition,
          instagramHandle: _instagramController.text,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Profile updated successfully!')),
        );
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to update profile')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
        actions: [IconButton(icon: Icon(Icons.save), onPressed: _saveProfile)],
      ),
      body: Consumer<ProfileProvider>(
        builder: (context, profileProvider, child) {
          if (profileProvider.isLoading && !profileProvider.hasProfile) {
            return Center(child: CircularProgressIndicator());
          }

          // Populate fields when profile loads
          if (profileProvider.hasProfile) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _populateFields();
            });
          }

          return SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  // Avatar Section
                  Center(
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundImage:
                              profileProvider.profile?.avatar?.url != null
                                  ? CachedNetworkImageProvider(
                                    profileProvider.profile!.avatar!.url!,
                                  )
                                  : null,
                          child:
                              profileProvider.profile?.avatar?.url == null
                                  ? Icon(Icons.person, size: 60)
                                  : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: _pickImage,
                            child: Container(
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 24),

                  // Form Fields
                  TextFormField(
                    controller: _fullNameController,
                    decoration: InputDecoration(
                      labelText: 'Full Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 16),

                  // Date of Birth
                  InkWell(
                    onTap: _selectDate,
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Date of Birth',
                        border: OutlineInputBorder(),
                      ),
                      child: Text(
                        _selectedDate != null
                            ? DateFormat('yyyy-MM-dd').format(_selectedDate!)
                            : 'Select Date',
                      ),
                    ),
                  ),
                  SizedBox(height: 16),

                  // Position Dropdown
                  DropdownButtonFormField<String>(
                    value: _selectedPosition,
                    decoration: InputDecoration(
                      labelText: 'Position',
                      border: OutlineInputBorder(),
                    ),
                    items:
                        positions.map((String position) {
                          return DropdownMenuItem<String>(
                            value: position,
                            child: Text(position),
                          );
                        }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedPosition = newValue!;
                      });
                    },
                  ),
                  SizedBox(height: 16),

                  // Address Section
                  Text(
                    'Address',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  SizedBox(height: 8),

                  TextFormField(
                    controller: _streetController,
                    decoration: InputDecoration(
                      labelText: 'Street',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          controller: _cityController,
                          decoration: InputDecoration(
                            labelText: 'City',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _stateController,
                          decoration: InputDecoration(
                            labelText: 'State',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),

                  TextFormField(
                    controller: _zipController,
                    decoration: InputDecoration(
                      labelText: 'ZIP Code',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 16),

                  // Other Fields
                  TextFormField(
                    controller: _clubTeamController,
                    decoration: InputDecoration(
                      labelText: 'Club Team',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 16),

                  TextFormField(
                    controller: _schoolController,
                    decoration: InputDecoration(
                      labelText: 'School',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 16),

                  TextFormField(
                    controller: _graduationYearController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Graduation Year',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        final year = int.tryParse(value);
                        if (year == null || year < 1900 || year > 2100) {
                          return 'Please enter a valid year between 1900 and 2100';
                        }
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),

                  TextFormField(
                    controller: _instagramController,
                    decoration: InputDecoration(
                      labelText: 'Instagram Handle',
                      prefixText: '@',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 24),

                  // Save Button
                  ElevatedButton(
                    onPressed: profileProvider.isLoading ? null : _saveProfile,
                    child:
                        profileProvider.isLoading
                            ? CircularProgressIndicator()
                            : Text('Save Profile'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(double.infinity, 50),
                    ),
                  ),

                  // Error Display
                  if (profileProvider.error != null) ...[
                    SizedBox(height: 16),
                    Text(
                      profileProvider.error!,
                      style: TextStyle(color: Colors.red),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _clubTeamController.dispose();
    _schoolController.dispose();
    _graduationYearController.dispose();
    _instagramController.dispose();
    _streetController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipController.dispose();
    super.dispose();
  }
}
