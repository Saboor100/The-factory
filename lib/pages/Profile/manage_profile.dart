import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/profile_provider.dart';
import '../../models/profile.dart';

class ManageProfileScreen extends StatefulWidget {
  const ManageProfileScreen({super.key});

  @override
  State<ManageProfileScreen> createState() => _ManageProfileScreenState();
}

class _ManageProfileScreenState extends State<ManageProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final profile = Provider.of<ProfileProvider>(context).profile;
    if (profile != null && !_fieldsPopulated) {
      _populateFields(profile);
    }
  }

  // Controllers
  late TextEditingController _fullNameController;
  late TextEditingController _streetController;
  late TextEditingController _cityController;
  late TextEditingController _stateController;
  late TextEditingController _zipController;
  late TextEditingController _clubTeamController;
  late TextEditingController _schoolController;
  late TextEditingController _graduationYearController;
  late TextEditingController _instagramController;

  // FIXED: Updated positions to match backend enum values
  String selectedPosition = 'Midfield';
  DateTime? selectedDate;
  bool _fieldsPopulated = false;

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
    _streetController = TextEditingController();
    _cityController = TextEditingController();
    _stateController = TextEditingController();
    _zipController = TextEditingController();
    _clubTeamController = TextEditingController();
    _schoolController = TextEditingController();
    _graduationYearController = TextEditingController();
    _instagramController = TextEditingController();
  }

  void _loadProfile() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProfileProvider>().loadProfile();
    });
  }

  void _populateFields(Profile? profile) {
    if (profile != null && !_fieldsPopulated) {
      _fullNameController.text = profile.fullName ?? '';
      _streetController.text = profile.address?.street ?? '';
      _cityController.text = profile.address?.city ?? '';
      _stateController.text = profile.address?.state ?? '';
      _zipController.text = profile.address?.zip ?? '';
      _clubTeamController.text = profile.clubTeam ?? '';
      _schoolController.text = profile.school ?? '';
      _graduationYearController.text = profile.graduationYear?.toString() ?? '';
      _instagramController.text = profile.instagramHandle ?? '';
      selectedDate = profile.dob;

      // FIXED: Ensure position matches backend enum
      if (profile.position != null && positions.contains(profile.position)) {
        selectedPosition = profile.position!;
      } else {
        selectedPosition = 'Other'; // Default fallback
      }

      _fieldsPopulated = true;
      setState(() {});
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (image != null) {
        await context.read<ProfileProvider>().uploadAvatar(File(image.path));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile image updated successfully!'),
              backgroundColor: Color(0xFFB8FF00),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile image: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime(2005, 1, 1),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFFB8FF00),
              onPrimary: Colors.black,
              surface: Color(0xFF1E1E1E),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      try {
        // Clear any previous errors
        context.read<ProfileProvider>().clearError();

        await context.read<ProfileProvider>().updateProfile(
          fullName:
              _fullNameController.text.trim().isEmpty
                  ? null
                  : _fullNameController.text.trim(),
          dob: selectedDate,
          street:
              _streetController.text.trim().isEmpty
                  ? null
                  : _streetController.text.trim(),
          city:
              _cityController.text.trim().isEmpty
                  ? null
                  : _cityController.text.trim(),
          state:
              _stateController.text.trim().isEmpty
                  ? null
                  : _stateController.text.trim(),
          zip:
              _zipController.text.trim().isEmpty
                  ? null
                  : _zipController.text.trim(),
          clubTeam:
              _clubTeamController.text.trim().isEmpty
                  ? null
                  : _clubTeamController.text.trim(),
          school:
              _schoolController.text.trim().isEmpty
                  ? null
                  : _schoolController.text.trim(),
          graduationYear:
              _graduationYearController.text.trim().isEmpty
                  ? null
                  : int.tryParse(_graduationYearController.text.trim()),
          position: selectedPosition,
          instagramHandle:
              _instagramController.text.trim().isEmpty
                  ? null
                  : _instagramController.text.trim(),
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile updated successfully!'),
              backgroundColor: Color(0xFFB8FF00),
            ),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to update profile: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Manage Profile',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Consumer<ProfileProvider>(
        builder: (context, profileProvider, child) {
          // Auto-populate fields when profile loads

          if (profileProvider.isLoading && !profileProvider.hasProfile) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFB8FF00)),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  // Profile Image Upload
                  Center(
                    child: Stack(
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF2A2A2A),
                            border: Border.all(
                              color: const Color(0xFFB8FF00),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.25),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child:
                                profileProvider.profile?.avatar?.url != null
                                    ? CachedNetworkImage(
                                      imageUrl:
                                          profileProvider.profile!.avatar!.url!,
                                      fit: BoxFit.cover,
                                      width: 120,
                                      height: 120,
                                      placeholder:
                                          (context, url) =>
                                              const CircularProgressIndicator(
                                                color: Color(0xFFB8FF00),
                                              ),
                                      errorWidget:
                                          (context, url, error) => const Icon(
                                            Icons.person,
                                            size: 60,
                                            color: Colors.grey,
                                          ),
                                    )
                                    : const Icon(
                                      Icons.person,
                                      size: 60,
                                      color: Colors.grey,
                                    ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: _pickImage,
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: const Color(0xFFB8FF00),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.black,
                                  width: 2,
                                ),
                              ),
                              child:
                                  profileProvider.isLoading
                                      ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          color: Colors.black,
                                          strokeWidth: 2,
                                        ),
                                      )
                                      : const Icon(
                                        Icons.camera_alt,
                                        color: Colors.black,
                                        size: 18,
                                      ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Name Field
                  _buildTextField(
                    controller: _fullNameController,
                    label: 'Full Name',
                    hint: 'John Doe',
                    icon: Icons.person_outline,
                  ),
                  const SizedBox(height: 20),

                  // Date of Birth
                  GestureDetector(
                    onTap: () => _selectDate(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 18,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2A2A2A),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF404040)),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.calendar_today,
                            color: Color(0xFFB8FF00),
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            selectedDate != null
                                ? DateFormat(
                                  'MMMM d, yyyy',
                                ).format(selectedDate!)
                                : 'Select Date of Birth',
                            style: TextStyle(
                              color:
                                  selectedDate != null
                                      ? Colors.white
                                      : Colors.grey,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Street Address
                  _buildTextField(
                    controller: _streetController,
                    label: 'Street Address',
                    hint: '123 Main St',
                    icon: Icons.home_outlined,
                  ),
                  const SizedBox(height: 20),

                  // City, State & Zip Code
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: _buildTextField(
                          controller: _cityController,
                          label: 'City',
                          hint: 'City',
                          icon: Icons.location_city_outlined,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildTextField(
                          controller: _stateController,
                          label: 'State',
                          hint: 'State',
                          icon: Icons.map_outlined,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildTextField(
                          controller: _zipController,
                          label: 'Zip',
                          hint: 'Zip Code',
                          icon: Icons.local_post_office_outlined,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Club Team
                  _buildTextField(
                    controller: _clubTeamController,
                    label: 'Club Team',
                    hint: 'Enter your club team',
                    icon: Icons.sports,
                  ),
                  const SizedBox(height: 20),

                  // School
                  _buildTextField(
                    controller: _schoolController,
                    label: 'School',
                    hint: 'Enter your school',
                    icon: Icons.school_outlined,
                  ),
                  const SizedBox(height: 20),

                  // Graduation Year
                  _buildTextField(
                    controller: _graduationYearController,
                    label: 'Graduation Year',
                    hint: '2025',
                    icon: Icons.calendar_month_outlined,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 20),

                  // Position Dropdown
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A2A2A),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF404040)),
                    ),
                    child: DropdownButtonFormField<String>(
                      value: selectedPosition,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        labelText: 'Position',
                        labelStyle: TextStyle(color: Color(0xFFB8FF00)),
                      ),
                      dropdownColor: const Color(0xFF2A2A2A),
                      style: const TextStyle(color: Colors.white),
                      items:
                          positions
                              .map(
                                (String position) => DropdownMenuItem<String>(
                                  value: position,
                                  child: Text(position),
                                ),
                              )
                              .toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedPosition = newValue!;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Instagram Handle
                  _buildTextField(
                    controller: _instagramController,
                    label: 'Instagram Handle',
                    hint: 'username',
                    icon: Icons.alternate_email,
                    prefixText: '@',
                  ),
                  const SizedBox(height: 40),

                  // Error Display
                  if (profileProvider.error != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red),
                      ),
                      child: Text(
                        profileProvider.error!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed:
                          profileProvider.isLoading ? null : _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFB8FF00),
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child:
                          profileProvider.isLoading
                              ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.black,
                                  strokeWidth: 2,
                                ),
                              )
                              : const Text(
                                'Save Profile',
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
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    String? prefixText,
    TextInputType? keyboardType,
    IconData? icon,
    bool isRequired = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixText: prefixText,
        labelStyle: const TextStyle(color: Color(0xFFB8FF00)),
        hintStyle: const TextStyle(color: Colors.grey),
        prefixStyle: const TextStyle(color: Colors.white),
        filled: true,
        fillColor: const Color(0xFF2A2A2A),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF404040)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF404040)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFB8FF00)),
        ),
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        prefixIcon:
            icon != null
                ? Icon(icon, color: const Color(0xFFB8FF00), size: 22)
                : null,
      ),
      validator: (value) {
        if (isRequired && (value == null || value.trim().isEmpty)) {
          return '$label is required';
        }
        return null;
      },
    );
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _streetController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipController.dispose();
    _clubTeamController.dispose();
    _schoolController.dispose();
    _graduationYearController.dispose();
    _instagramController.dispose();
    super.dispose();
  }
}
