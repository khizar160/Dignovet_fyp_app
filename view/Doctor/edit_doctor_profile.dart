// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';

// import '../../model/doctor_model.dart';
// import '../../services/doctor_profile_services/doctor_service.dart';

// class EditDoctorProfilePage extends StatefulWidget {
//   final DoctorProfile? doctor;
//   final String doctorId;

//   const EditDoctorProfilePage({
//     super.key,
//     required this.doctorId,
//     this.doctor,
//   });

//   @override
//   State<EditDoctorProfilePage> createState() => _EditDoctorProfilePageState();
// }

// class _EditDoctorProfilePageState extends State<EditDoctorProfilePage> {
//   final _formKey = GlobalKey<FormState>();

//   late TextEditingController specialization;
//   late TextEditingController experience;
//   late TextEditingController clinicName;
//   late TextEditingController clinicAddress;
//   late TextEditingController about;

//   File? imageFile;
//   bool saving = false;

//   List<String> selectedDays = [];
//   List<String> selectedSlots = [];

//   final days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
//   final slots = ["09-10", "10-11", "11-12", "05-06", "06-07", "07-08"];

//   final Color primaryTeal = const Color(0xFF80CBC4);
//   final Color darkTeal = const Color(0xFF00796B);

//   @override
//   void initState() {
//     super.initState();
//     specialization =
//         TextEditingController(text: widget.doctor?.specialization ?? "");
//     experience =
//         TextEditingController(text: widget.doctor?.experience.toString() ?? "");
//     clinicName =
//         TextEditingController(text: widget.doctor?.clinicName ?? "");
//     clinicAddress =
//         TextEditingController(text: widget.doctor?.clinicAddress ?? "");
//     about = TextEditingController(text: widget.doctor?.about ?? "");

//     selectedDays = List.from(widget.doctor?.availableDays ?? []);
//     selectedSlots = List.from(widget.doctor?.availableSlots ?? []);
//   }

//   @override
//   void dispose() {
//     specialization.dispose();
//     experience.dispose();
//     clinicName.dispose();
//     clinicAddress.dispose();
//     about.dispose();
//     super.dispose();
//   }

//   /// 📷 PICK IMAGE
//   Future<void> _pickImage() async {
//     final picked = await ImagePicker().pickImage(
//       source: ImageSource.gallery,
//       imageQuality: 70,
//     );
//     if (picked != null) {
//       setState(() => imageFile = File(picked.path));
//     }
//   }

//   /// ☁️ UPLOAD IMAGE TO SUPABASE
//   Future<String?> _uploadImageToSupabase() async {
//     if (imageFile == null) return widget.doctor?.imageUrl;

//     final supabase = Supabase.instance.client;

//     final fileName =
//         '${widget.doctorId}_${DateTime.now().millisecondsSinceEpoch}.jpg';

//     await supabase.storage
//         .from('doctor_images') // ✅ YOUR FOLDER NAME
//         .upload(fileName, imageFile!,
//             fileOptions: const FileOptions(upsert: true));

//     return supabase.storage
//         .from('doctor_images')
//         .getPublicUrl(fileName);
//   }

//   /// 💾 SAVE PROFILE
//   Future<void> _save() async {
//     if (!_formKey.currentState!.validate()) return;

//     setState(() => saving = true);

//     final imageUrl = await _uploadImageToSupabase();

//     final updated = DoctorProfile(
//       id: widget.doctorId,
//       imageUrl: imageUrl ?? "",
//       specialization: specialization.text.trim(),
//       experience: int.parse(experience.text.trim()),
//       clinicName: clinicName.text.trim(),
//       clinicAddress: clinicAddress.text.trim(),
//       about: about.text.trim(),
//       availableDays: selectedDays,
//       availableSlots: selectedSlots,
//     );

//     await DoctorService().saveDoctorProfile(widget.doctorId, updated);

//     if (mounted) Navigator.pop(context, true);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFE8F5F3),
//       appBar: AppBar(
//         backgroundColor: primaryTeal,
//         title: Text(widget.doctor == null
//             ? "Complete Profile"
//             : "Edit Profile"),
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(20),
//         child: Form(
//           key: _formKey,
//           child: Column(
//             children: [
//               /// 🧑‍⚕️ IMAGE
//               GestureDetector(
//                 onTap: _pickImage,
//                 child: Stack(
//                   alignment: Alignment.bottomRight,
//                   children: [
//                     CircleAvatar(
//                       radius: 60,
//                       backgroundColor: Colors.white,
//                       backgroundImage: imageFile != null
//                           ? FileImage(imageFile!)
//                           : (widget.doctor?.imageUrl.isNotEmpty ?? false)
//                               ? NetworkImage(widget.doctor!.imageUrl)
//                               : null,
//                       child: imageFile == null &&
//                               (widget.doctor?.imageUrl.isEmpty ?? true)
//                           ? Icon(Icons.person,
//                               size: 70, color: darkTeal)
//                           : null,
//                     ),
//                     CircleAvatar(
//                       radius: 18,
//                       backgroundColor: darkTeal,
//                       child: const Icon(Icons.camera_alt,
//                           size: 18, color: Colors.white),
//                     )
//                   ],
//                 ),
//               ),

//               const SizedBox(height: 30),

//               _field("Specialization", specialization),
//               _field("Experience (Years)", experience, isNumber: true),
//               _field("Clinic Name", clinicName),
//               _field("Clinic Address", clinicAddress),
//               _field("About", about, max: 3),

//               const SizedBox(height: 20),

//               _sectionTitle("Available Days"),
//               Wrap(
//                 spacing: 8,
//                 children: days.map((d) {
//                   return FilterChip(
//                     label: Text(d),
//                     selected: selectedDays.contains(d),
//                     selectedColor: primaryTeal,
//                     onSelected: (v) {
//                       setState(() {
//                         v ? selectedDays.add(d) : selectedDays.remove(d);
//                       });
//                     },
//                   );
//                 }).toList(),
//               ),

//               const SizedBox(height: 16),

//               _sectionTitle("Time Slots"),
//               Wrap(
//                 spacing: 8,
//                 children: slots.map((s) {
//                   return FilterChip(
//                     label: Text(s),
//                     selected: selectedSlots.contains(s),
//                     selectedColor: primaryTeal,
//                     onSelected: (v) {
//                       setState(() {
//                         v ? selectedSlots.add(s) : selectedSlots.remove(s);
//                       });
//                     },
//                   );
//                 }).toList(),
//               ),

//               const SizedBox(height: 40),

//               ElevatedButton(
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: darkTeal,
//                   padding: const EdgeInsets.symmetric(
//                       horizontal: 50, vertical: 16),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(30),
//                   ),
//                 ),
//                 onPressed: saving ? null : _save,
//                 child: saving
//                     ? const CircularProgressIndicator(color: Colors.white)
//                     : const Text("Save Profile",
//                         style: TextStyle(fontSize: 16)),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _field(String label, TextEditingController controller,
//       {int max = 1, bool isNumber = false}) {
//     return Card(
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
//       elevation: 6,
//       margin: const EdgeInsets.only(bottom: 16),
//       child: Padding(
//         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
//         child: TextFormField(
//           controller: controller,
//           maxLines: max,
//           keyboardType:
//               isNumber ? TextInputType.number : TextInputType.text,
//           validator: (v) =>
//               v == null || v.trim().isEmpty ? "Required" : null,
//           decoration: InputDecoration(
//             labelText: label,
//             border: InputBorder.none,
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _sectionTitle(String text) {
//     return Align(
//       alignment: Alignment.centerLeft,
//       child: Padding(
//         padding: const EdgeInsets.only(bottom: 8),
//         child: Text(text,
//             style:
//                 const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
//       ),
//     );
//   }
// }



import 'dart:developer';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../model/app_user.dart';

class EditDoctorProfilePage extends StatefulWidget {
  final AppUser user;

  const EditDoctorProfilePage({
    super.key,
    required this.user,
  });

  @override
  State<EditDoctorProfilePage> createState() => _EditDoctorProfilePageState();
}

class _EditDoctorProfilePageState extends State<EditDoctorProfilePage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _specializationController;
  late TextEditingController _experienceController;
  late TextEditingController _clinicNameController;
  late TextEditingController _clinicAddressController;
  late TextEditingController _aboutController;

  File? _imageFile;
  bool _saving = false;

  List<String> _selectedDays = [];
  List<String> _selectedSlots = [];

  final List<String> _days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
  final List<String> _slots = [
    "09:00-10:00",
    "10:00-11:00",
    "11:00-12:00",
    "02:00-03:00",
    "03:00-04:00",
    "04:00-05:00",
    "05:00-06:00",
    "06:00-07:00",
  ];

  final Color primaryTeal = Color(0xFF00796B);
  final Color lightTeal = Color(0xFF4DB6AC);
  final Color darkGrey = Color(0xFF2C3E50);

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
    _phoneController = TextEditingController(text: widget.user.phone);
    _specializationController = TextEditingController(text: widget.user.specialization ?? "");
    _experienceController = TextEditingController(text: widget.user.experience?.toString() ?? "");
    _clinicNameController = TextEditingController(text: widget.user.clinicName ?? "");
    _clinicAddressController = TextEditingController(text: widget.user.clinicAddress ?? "");
    _aboutController = TextEditingController(text: widget.user.about ?? "");

    _selectedDays = List.from(widget.user.availableDays ?? []);
    _selectedSlots = List.from(widget.user.availableSlots ?? []);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _specializationController.dispose();
    _experienceController.dispose();
    _clinicNameController.dispose();
    _clinicAddressController.dispose();
    _aboutController.dispose();
    super.dispose();
  }

  /// Pick Image from Gallery
  Future<void> _pickImage() async {
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1024,
        maxHeight: 1024,
      );
      if (picked != null) {
        setState(() => _imageFile = File(picked.path));
        log('Image selected: ${picked.path}');
      }
    } catch (e) {
      log('Pick Image Error: $e');
      _showSnackBar('Failed to select image', isError: true);
    }
  }

  /// Upload Image to Supabase
  Future<String?> _uploadImageToSupabase() async {
    if (_imageFile == null) return widget.user.imageUrl;

    try {
      final supabase = Supabase.instance.client;
      final fileName = '${widget.user.id}_${DateTime.now().millisecondsSinceEpoch}.png';
      final path = 'doctor/$fileName';

      log('Uploading image to Supabase: $path');

      await supabase.storage.from('images').upload(
        path,
        _imageFile!,
        fileOptions: const FileOptions(
          cacheControl: '3600',
          upsert: true,
        ),
      );

      final imageUrl = supabase.storage.from('images').getPublicUrl(path);
      log('Image uploaded successfully: $imageUrl');
      return imageUrl;
    } catch (e) {
      log('Upload Image Error: $e');
      _showSnackBar('Failed to upload image', isError: true);
      return widget.user.imageUrl;
    }
  }

  /// Save Profile to Users Collection
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      _showSnackBar('Please fill all required fields', isError: true);
      return;
    }

    if (_selectedDays.isEmpty) {
      _showSnackBar('Please select at least one available day', isError: true);
      return;
    }

    if (_selectedSlots.isEmpty) {
      _showSnackBar('Please select at least one time slot', isError: true);
      return;
    }

    setState(() => _saving = true);
    log('Saving doctor profile for ${widget.user.id}');

    try {
      // Upload image if selected
      String? imageUrl = await _uploadImageToSupabase();

      // Prepare update data
      final updateData = {
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'imageUrl': imageUrl ?? '',
        // Doctor-specific fields
        'specialization': _specializationController.text.trim(),
        'experience': int.parse(_experienceController.text.trim()),
        'clinicName': _clinicNameController.text.trim(),
        'clinicAddress': _clinicAddressController.text.trim(),
        'about': _aboutController.text.trim(),
        'availableDays': _selectedDays,
        'availableSlots': _selectedSlots,
        'profileCompleted': true,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Update in users collection
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.user.id)
          .update(updateData);

      log('Doctor profile updated successfully');
      _showSnackBar('Profile updated successfully!');

      // Navigate back
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      log('Save Profile Error: $e');
      _showSnackBar('Failed to update profile: ${e.toString()}', isError: true);
    }

    setState(() => _saving = false);
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF0F4F8),
      appBar: AppBar(
        backgroundColor: primaryTeal,
        title: Text(
          widget.user.isDoctorProfileComplete() ? "Edit Profile" : "Complete Profile",
          style: const TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Image Section
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: primaryTeal.withOpacity(0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 65,
                          backgroundColor: Colors.white,
                          backgroundImage: _imageFile != null
                              ? FileImage(_imageFile!)
                              : (widget.user.imageUrl.isNotEmpty
                                  ? NetworkImage(widget.user.imageUrl) as ImageProvider
                                  : null),
                          child: _imageFile == null && widget.user.imageUrl.isEmpty
                              ? Icon(Icons.person, size: 70, color: Colors.grey[400])
                              : null,
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [primaryTeal, lightTeal],
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: primaryTeal.withOpacity(0.4),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.camera_alt_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // Basic Information Section
              _buildSectionTitle("Basic Information"),
              _buildTextField("Full Name", _nameController, Icons.person_outline),
              _buildTextField("Email", TextEditingController(text: widget.user.email),
                  Icons.email_outlined, enabled: false),
              _buildTextField("Phone Number", _phoneController, Icons.phone_outlined,
                  keyboardType: TextInputType.phone),

              const SizedBox(height: 24),

              // Professional Information Section
              _buildSectionTitle("Professional Information"),
              _buildTextField("Specialization", _specializationController, Icons.medical_services_outlined),
              _buildTextField("Experience (Years)", _experienceController, Icons.work_outline,
                  keyboardType: TextInputType.number),
              _buildTextField("Clinic Name", _clinicNameController, Icons.local_hospital_outlined),
              _buildTextField("Clinic Address", _clinicAddressController, Icons.location_on_outlined),
              _buildTextField("About", _aboutController, Icons.info_outline, maxLines: 4),

              const SizedBox(height: 24),

              // Available Days Section
              _buildSectionTitle("Available Days"),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _days.map((day) {
                    final isSelected = _selectedDays.contains(day);
                    return FilterChip(
                      label: Text(day),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedDays.add(day);
                          } else {
                            _selectedDays.remove(day);
                          }
                        });
                      },
                      backgroundColor: Colors.white,
                      selectedColor: primaryTeal.withOpacity(0.2),
                      checkmarkColor: primaryTeal,
                      labelStyle: TextStyle(
                        color: isSelected ? primaryTeal : Colors.grey[700],
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      side: BorderSide(
                        color: isSelected ? primaryTeal : Colors.grey[300]!,
                        width: isSelected ? 2 : 1,
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 20),

              // Time Slots Section
              _buildSectionTitle("Available Time Slots"),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _slots.map((slot) {
                    final isSelected = _selectedSlots.contains(slot);
                    return FilterChip(
                      label: Text(slot),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedSlots.add(slot);
                          } else {
                            _selectedSlots.remove(slot);
                          }
                        });
                      },
                      backgroundColor: Colors.white,
                      selectedColor: lightTeal.withOpacity(0.2),
                      checkmarkColor: primaryTeal,
                      labelStyle: TextStyle(
                        color: isSelected ? primaryTeal : Colors.grey[700],
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      side: BorderSide(
                        color: isSelected ? primaryTeal : Colors.grey[300]!,
                        width: isSelected ? 2 : 1,
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 40),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _saving ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryTeal,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 2,
                  ),
                  child: _saving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Save Profile',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: darkGrey,
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    IconData icon, {
    int maxLines = 1,
    bool enabled = true,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        enabled: enabled,
        maxLines: maxLines,
        keyboardType: keyboardType,
        validator: (value) {
          if (enabled && (value == null || value.trim().isEmpty)) {
            return 'This field is required';
          }
          return null;
        },
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: primaryTeal),
          filled: true,
          fillColor: enabled ? Colors.white : Colors.grey[100],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: primaryTeal, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }
}