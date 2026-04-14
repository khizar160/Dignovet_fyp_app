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



// import 'dart:developer';
// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:geocoding/geocoding.dart';
// import '../../model/app_user.dart';

// class EditDoctorProfilePage extends StatefulWidget {
//   final AppUser user;

//   const EditDoctorProfilePage({
//     super.key,
//     required this.user,
//   });

//   @override
//   State<EditDoctorProfilePage> createState() => _EditDoctorProfilePageState();
// }

// class _EditDoctorProfilePageState extends State<EditDoctorProfilePage> {
//   final _formKey = GlobalKey<FormState>();

//   late TextEditingController _nameController;
//   late TextEditingController _phoneController;
//   late TextEditingController _specializationController;
//   late TextEditingController _experienceController;
//   late TextEditingController _clinicNameController;
//   late TextEditingController _clinicAddressController;
//   late TextEditingController _latitudeController;
//   late TextEditingController _longitudeController;
//   late TextEditingController _aboutController;
//   late TextEditingController _onlineConsultationFeeController;
//   late TextEditingController _homeVisitFeeController;

//   File? _imageFile;
//   bool _saving = false;

//   List<String> _selectedDays = [];
//   List<String> _selectedSlots = [];

//   final List<String> _days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
//   final List<String> _slots = [
//     "09:00-10:00",
//     "10:00-11:00",
//     "11:00-12:00",
//     "02:00-03:00",
//     "03:00-04:00",
//     "04:00-05:00",
//     "05:00-06:00",
//     "06:00-07:00",
//   ];

//   final Color primaryTeal = Color(0xFF00796B);
//   final Color lightTeal = Color(0xFF4DB6AC);
//   final Color darkGrey = Color(0xFF2C3E50);

//   @override
//   void initState() {
//     super.initState();
//     _nameController = TextEditingController(text: widget.user.name);
//     _phoneController = TextEditingController(text: widget.user.phone);
//     _specializationController = TextEditingController(text: widget.user.specialization ?? "");
//     _experienceController = TextEditingController(text: widget.user.experience?.toString() ?? "");
//     _clinicNameController = TextEditingController(text: widget.user.clinicName ?? "");
//     _clinicAddressController = TextEditingController(text: widget.user.clinicAddress ?? "");
//     _latitudeController = TextEditingController(text: widget.user.latitude?.toString() ?? "");
//     _longitudeController = TextEditingController(text: widget.user.longitude?.toString() ?? "");
//     _aboutController = TextEditingController(text: widget.user.about ?? "");
//     _onlineConsultationFeeController = TextEditingController(text: widget.user.onlineConsultationFee?.toString() ?? "");
//     _homeVisitFeeController = TextEditingController(text: widget.user.homeVisitFee?.toString() ?? "");

//     _selectedDays = List.from(widget.user.availableDays ?? []);
//     _selectedSlots = List.from(widget.user.availableSlots ?? []);
//   }

//   @override
//   void dispose() {
//     _nameController.dispose();
//     _phoneController.dispose();
//     _specializationController.dispose();
//     _experienceController.dispose();
//     _clinicNameController.dispose();
//     _clinicAddressController.dispose();
//     _latitudeController.dispose();
//     _longitudeController.dispose();
//     _aboutController.dispose();
//     _onlineConsultationFeeController.dispose();
//     _homeVisitFeeController.dispose();
//     super.dispose();
//   }

//   /// Pick Image from Gallery
//   Future<void> _pickImage() async {
//     try {
//       final picked = await ImagePicker().pickImage(
//         source: ImageSource.gallery,
//         imageQuality: 80,
//         maxWidth: 1024,
//         maxHeight: 1024,
//       );
//       if (picked != null) {
//         setState(() => _imageFile = File(picked.path));
//         log('Image selected: ${picked.path}');
//       }
//     } catch (e) {
//       log('Pick Image Error: $e');
//       _showSnackBar('Failed to select image', isError: true);
//     }
//   }

//   /// Upload Image to Supabase
//   Future<String?> _uploadImageToSupabase() async {
//     if (_imageFile == null) return widget.user.imageUrl;

//     try {
//       final supabase = Supabase.instance.client;
//       final fileName = '${widget.user.id}_${DateTime.now().millisecondsSinceEpoch}.png';
//       final path = 'doctor/$fileName';

//       log('Uploading image to Supabase: $path');

//       await supabase.storage.from('images').upload(
//         path,
//         _imageFile!,
//         fileOptions: const FileOptions(
//           cacheControl: '3600',
//           upsert: true,
//         ),
//       );

//       final imageUrl = supabase.storage.from('images').getPublicUrl(path);
//       log('Image uploaded successfully: $imageUrl');
//       return imageUrl;
//     } catch (e) {
//       log('Upload Image Error: $e');
//       _showSnackBar('Failed to upload image', isError: true);
//       return widget.user.imageUrl;
//     }
//   }

//   /// Get Coordinates from Address using Geocoding
//   Future<void> _getCoordinatesFromAddress() async {
//     if (_clinicAddressController.text.trim().isEmpty) {
//       _showSnackBar('Please enter clinic address first', isError: true);
//       return;
//     }

//     try {
//       setState(() => _saving = true);
//       final address = _clinicAddressController.text.trim();
//       log('Geocoding address: $address');
      
//       List<Location> locations = await locationFromAddress(address);
      
//       if (locations.isNotEmpty) {
//         setState(() {
//           _latitudeController.text = locations.first.latitude.toStringAsFixed(6);
//           _longitudeController.text = locations.first.longitude.toStringAsFixed(6);
//         });
//         _showSnackBar('Location coordinates fetched successfully!');
//       } else {
//         _showSnackBar('No coordinates found for this address', isError: true);
//       }
//     } catch (e) {
//       log('Geocoding Error: $e');
//       _showSnackBar('Failed to get coordinates. Please enter manually', isError: true);
//     } finally {
//       setState(() => _saving = false);
//     }
//   }

//   /// Save Profile to Users Collection
//   Future<void> _saveProfile() async {
//     if (!_formKey.currentState!.validate()) {
//       _showSnackBar('Please fill all required fields', isError: true);
//       return;
//     }

//     if (_selectedDays.isEmpty) {
//       _showSnackBar('Please select at least one available day', isError: true);
//       return;
//     }

//     if (_selectedSlots.isEmpty) {
//       _showSnackBar('Please select at least one time slot', isError: true);
//       return;
//     }

//     setState(() => _saving = true);
//     log('Saving doctor profile for ${widget.user.id}');

//     try {
//       // Upload image if selected
//       String? imageUrl = await _uploadImageToSupabase();

//       // Prepare update data
//       final updateData = {
//         'name': _nameController.text.trim(),
//         'phone': _phoneController.text.trim(),
//         'imageUrl': imageUrl ?? '',
//         // Doctor-specific fields
//         'specialization': _specializationController.text.trim(),
//         'experience': int.parse(_experienceController.text.trim()),
//         'clinicName': _clinicNameController.text.trim(),
//         'clinicAddress': _clinicAddressController.text.trim(),
//         'latitude': _latitudeController.text.trim().isNotEmpty ? double.parse(_latitudeController.text.trim()) : null,
//         'longitude': _longitudeController.text.trim().isNotEmpty ? double.parse(_longitudeController.text.trim()) : null,
//         'about': _aboutController.text.trim(),
//         'availableDays': _selectedDays,
//         'availableSlots': _selectedSlots,
//         'onlineConsultationFee': _onlineConsultationFeeController.text.trim().isNotEmpty ? double.parse(_onlineConsultationFeeController.text.trim()) : null,
//         'homeVisitFee': _homeVisitFeeController.text.trim().isNotEmpty ? double.parse(_homeVisitFeeController.text.trim()) : null,
//         'profileCompleted': true,
//         'updatedAt': FieldValue.serverTimestamp(),
//       };

//       // Update in users collection
//       await FirebaseFirestore.instance
//           .collection('users')
//           .doc(widget.user.id)
//           .update(updateData);

//       log('Doctor profile updated successfully');
//       _showSnackBar('Profile updated successfully!');

//       // Navigate back
//       if (mounted) {
//         Navigator.pop(context, true);
//       }
//     } catch (e) {
//       log('Save Profile Error: $e');
//       _showSnackBar('Failed to update profile: ${e.toString()}', isError: true);
//     }

//     setState(() => _saving = false);
//   }

//   void _showSnackBar(String message, {bool isError = false}) {
//     if (!mounted) return;
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         backgroundColor: isError ? Colors.red : Colors.green,
//         behavior: SnackBarBehavior.floating,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Color(0xFFF0F4F8),
//       appBar: AppBar(
//         backgroundColor: primaryTeal,
//         title: Text(
//           widget.user.isDoctorProfileComplete() ? "Edit Profile" : "Complete Profile",
//           style: const TextStyle(color: Colors.white),
//         ),
//         iconTheme: const IconThemeData(color: Colors.white),
//         elevation: 0,
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(20),
//         child: Form(
//           key: _formKey,
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // Profile Image Section
//               Center(
//                 child: GestureDetector(
//                   onTap: _pickImage,
//                   child: Stack(
//                     children: [
//                       Container(
//                         decoration: BoxDecoration(
//                           shape: BoxShape.circle,
//                           boxShadow: [
//                             BoxShadow(
//                               color: primaryTeal.withOpacity(0.3),
//                               blurRadius: 20,
//                               offset: const Offset(0, 8),
//                             ),
//                           ],
//                         ),
//                         child: CircleAvatar(
//                           radius: 65,
//                           backgroundColor: Colors.white,
//                           backgroundImage: _imageFile != null
//                               ? FileImage(_imageFile!)
//                               : (widget.user.imageUrl.isNotEmpty
//                                   ? NetworkImage(widget.user.imageUrl) as ImageProvider
//                                   : null),
//                           child: _imageFile == null && widget.user.imageUrl.isEmpty
//                               ? Icon(Icons.person, size: 70, color: Colors.grey[400])
//                               : null,
//                         ),
//                       ),
//                       Positioned(
//                         bottom: 0,
//                         right: 0,
//                         child: Container(
//                           padding: const EdgeInsets.all(12),
//                           decoration: BoxDecoration(
//                             gradient: LinearGradient(
//                               colors: [primaryTeal, lightTeal],
//                             ),
//                             shape: BoxShape.circle,
//                             boxShadow: [
//                               BoxShadow(
//                                 color: primaryTeal.withOpacity(0.4),
//                                 blurRadius: 10,
//                                 offset: const Offset(0, 4),
//                               ),
//                             ],
//                           ),
//                           child: const Icon(
//                             Icons.camera_alt_rounded,
//                             color: Colors.white,
//                             size: 22,
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 30),

//               // Basic Information Section
//               _buildSectionTitle("Basic Information"),
//               _buildTextField("Full Name", _nameController, Icons.person_outline),
//               _buildTextField("Email", TextEditingController(text: widget.user.email),
//                   Icons.email_outlined, enabled: false),
//               _buildTextField("Phone Number", _phoneController, Icons.phone_outlined,
//                   keyboardType: TextInputType.phone),

//               const SizedBox(height: 24),

//               // Professional Information Section
//               _buildSectionTitle("Professional Information"),
//               _buildTextField("Specialization", _specializationController, Icons.medical_services_outlined),
//               _buildTextField("Experience (Years)", _experienceController, Icons.work_outline,
//                   keyboardType: TextInputType.number),
//               _buildTextField("Clinic Name", _clinicNameController, Icons.local_hospital_outlined),
//               _buildTextField("Clinic Address", _clinicAddressController, Icons.location_on_outlined),
              
//               // Location Coordinates Section with Get Location Button
//               const SizedBox(height: 12),
//               Row(
//                 children: [
//                   Expanded(
//                     child: _buildTextField(
//                       "Latitude", 
//                       _latitudeController, 
//                       Icons.my_location,
//                       keyboardType: TextInputType.numberWithOptions(decimal: true),
//                     ),
//                   ),
//                   const SizedBox(width: 12),
//                   Expanded(
//                     child: _buildTextField(
//                       "Longitude", 
//                       _longitudeController, 
//                       Icons.location_searching,
//                       keyboardType: TextInputType.numberWithOptions(decimal: true),
//                     ),
//                   ),
//                 ],
//               ),
              
//               // Get Location from Address Button
//               SizedBox(
//                 width: double.infinity,
//                 child: OutlinedButton.icon(
//                   onPressed: _getCoordinatesFromAddress,
//                   icon: const Icon(Icons.map_outlined),
//                   label: const Text('Get Coordinates from Address'),
//                   style: OutlinedButton.styleFrom(
//                     foregroundColor: primaryTeal,
//                     side: BorderSide(color: primaryTeal, width: 2),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(14),
//                     ),
//                     padding: const EdgeInsets.symmetric(vertical: 14),
//                   ),
//                 ),
//               ),
              
//               _buildTextField("About", _aboutController, Icons.info_outline, maxLines: 4),

//               const SizedBox(height: 24),

//               // Consultation Fees Section
//               _buildSectionTitle("Consultation Fees (PKR)"),
//               _buildTextField("Online Consultation Fee (Rs)", _onlineConsultationFeeController, Icons.videocam_outlined,
//                   keyboardType: TextInputType.numberWithOptions(decimal: true)),
//               _buildTextField("Home Visit Fee (Rs)", _homeVisitFeeController, Icons.home_outlined,
//                   keyboardType: TextInputType.numberWithOptions(decimal: true)),

//               const SizedBox(height: 24),

//               // Available Days Section
//               _buildSectionTitle("Available Days"),
//               Container(
//                 padding: const EdgeInsets.all(16),
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.circular(16),
//                   boxShadow: [
//                     BoxShadow(
//                       color: Colors.black.withOpacity(0.04),
//                       blurRadius: 10,
//                       offset: const Offset(0, 3),
//                     ),
//                   ],
//                 ),
//                 child: Wrap(
//                   spacing: 8,
//                   runSpacing: 8,
//                   children: _days.map((day) {
//                     final isSelected = _selectedDays.contains(day);
//                     return FilterChip(
//                       label: Text(day),
//                       selected: isSelected,
//                       onSelected: (selected) {
//                         setState(() {
//                           if (selected) {
//                             _selectedDays.add(day);
//                           } else {
//                             _selectedDays.remove(day);
//                           }
//                         });
//                       },
//                       backgroundColor: Colors.white,
//                       selectedColor: primaryTeal.withOpacity(0.2),
//                       checkmarkColor: primaryTeal,
//                       labelStyle: TextStyle(
//                         color: isSelected ? primaryTeal : Colors.grey[700],
//                         fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
//                       ),
//                       side: BorderSide(
//                         color: isSelected ? primaryTeal : Colors.grey[300]!,
//                         width: isSelected ? 2 : 1,
//                       ),
//                     );
//                   }).toList(),
//                 ),
//               ),

//               const SizedBox(height: 20),

//               // Time Slots Section
//               _buildSectionTitle("Available Time Slots"),
//               Container(
//                 padding: const EdgeInsets.all(16),
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.circular(16),
//                   boxShadow: [
//                     BoxShadow(
//                       color: Colors.black.withOpacity(0.04),
//                       blurRadius: 10,
//                       offset: const Offset(0, 3),
//                     ),
//                   ],
//                 ),
//                 child: Wrap(
//                   spacing: 8,
//                   runSpacing: 8,
//                   children: _slots.map((slot) {
//                     final isSelected = _selectedSlots.contains(slot);
//                     return FilterChip(
//                       label: Text(slot),
//                       selected: isSelected,
//                       onSelected: (selected) {
//                         setState(() {
//                           if (selected) {
//                             _selectedSlots.add(slot);
//                           } else {
//                             _selectedSlots.remove(slot);
//                           }
//                         });
//                       },
//                       backgroundColor: Colors.white,
//                       selectedColor: lightTeal.withOpacity(0.2),
//                       checkmarkColor: primaryTeal,
//                       labelStyle: TextStyle(
//                         color: isSelected ? primaryTeal : Colors.grey[700],
//                         fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
//                       ),
//                       side: BorderSide(
//                         color: isSelected ? primaryTeal : Colors.grey[300]!,
//                         width: isSelected ? 2 : 1,
//                       ),
//                     );
//                   }).toList(),
//                 ),
//               ),

//               const SizedBox(height: 40),

//               // Save Button
//               SizedBox(
//                 width: double.infinity,
//                 height: 56,
//                 child: ElevatedButton(
//                   onPressed: _saving ? null : _saveProfile,
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: primaryTeal,
//                     foregroundColor: Colors.white,
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(14),
//                     ),
//                     elevation: 2,
//                   ),
//                   child: _saving
//                       ? const SizedBox(
//                           height: 20,
//                           width: 20,
//                           child: CircularProgressIndicator(
//                             color: Colors.white,
//                             strokeWidth: 2,
//                           ),
//                         )
//                       : const Text(
//                           'Save Profile',
//                           style: TextStyle(
//                             fontSize: 16,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                 ),
//               ),
//               const SizedBox(height: 20),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildSectionTitle(String title) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 12, left: 4),
//       child: Text(
//         title,
//         style: TextStyle(
//           fontSize: 18,
//           fontWeight: FontWeight.bold,
//           color: darkGrey,
//         ),
//       ),
//     );
//   }

//   Widget _buildTextField(
//     String label,
//     TextEditingController controller,
//     IconData icon, {
//     int maxLines = 1,
//     bool enabled = true,
//     TextInputType keyboardType = TextInputType.text,
//   }) {
//     return Container(
//       margin: const EdgeInsets.only(bottom: 16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(14),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.04),
//             blurRadius: 10,
//             offset: const Offset(0, 3),
//           ),
//         ],
//       ),
//       child: TextFormField(
//         controller: controller,
//         enabled: enabled,
//         maxLines: maxLines,
//         keyboardType: keyboardType,
//         validator: (value) {
//           if (enabled && (value == null || value.trim().isEmpty)) {
//             return 'This field is required';
//           }
//           return null;
//         },
//         decoration: InputDecoration(
//           labelText: label,
//           prefixIcon: Icon(icon, color: primaryTeal),
//           filled: true,
//           fillColor: enabled ? Colors.white : Colors.grey[100],
//           border: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(14),
//             borderSide: BorderSide.none,
//           ),
//           enabledBorder: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(14),
//             borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
//           ),
//           focusedBorder: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(14),
//             borderSide: BorderSide(color: primaryTeal, width: 2),
//           ),
//           contentPadding: const EdgeInsets.symmetric(
//             horizontal: 16,
//             vertical: 16,
//           ),
//         ),
//       ),
//     );
//   }
// }




// latest version of edit_doctor_profile.dart is in the branch doctor-profile-refactor, which has been merged to main. Please check the main branch for the latest code.
import 'dart:developer';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geocoding/geocoding.dart';
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
  late TextEditingController _latitudeController;
  late TextEditingController _longitudeController;
  late TextEditingController _aboutController;
  late TextEditingController _onlineConsultationFeeController;
  late TextEditingController _homeVisitFeeController;

  File? _imageFile;
  bool _saving = false;

  List<String> _selectedDays = [];
  List<String> _selectedSlots = [];

  final List<String> _days = [
    "Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"
  ];

  // ✅ Master list of all valid slots — single source of truth
  final List<String> _slots = [
    "08:00 AM - 09:00 AM",
    "09:00 AM - 10:00 AM",
    "10:00 AM - 11:00 AM",
    "11:00 AM - 12:00 PM",
    "12:00 PM - 01:00 PM",
    "01:00 PM - 02:00 PM",
    "02:00 PM - 03:00 PM",
    "03:00 PM - 04:00 PM",
    "04:00 PM - 05:00 PM",
    "05:00 PM - 06:00 PM",
    "05:30 PM - 06:00 PM",
  
  ];

  final Color primaryTeal = const Color(0xFF00796B);
  final Color lightTeal = const Color(0xFF4DB6AC);
  final Color darkGrey = const Color(0xFF2C3E50);

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
    _phoneController = TextEditingController(text: widget.user.phone);
    _specializationController =
        TextEditingController(text: widget.user.specialization ?? "");
    _experienceController =
        TextEditingController(text: widget.user.experience?.toString() ?? "");
    _clinicNameController =
        TextEditingController(text: widget.user.clinicName ?? "");
    _clinicAddressController =
        TextEditingController(text: widget.user.clinicAddress ?? "");
    _latitudeController =
        TextEditingController(text: widget.user.latitude?.toString() ?? "");
    _longitudeController =
        TextEditingController(text: widget.user.longitude?.toString() ?? "");
    _aboutController = TextEditingController(text: widget.user.about ?? "");
    _onlineConsultationFeeController = TextEditingController(
        text: widget.user.onlineConsultationFee?.toString() ?? "");
    _homeVisitFeeController =
        TextEditingController(text: widget.user.homeVisitFee?.toString() ?? "");

    _selectedDays = List.from(widget.user.availableDays ?? []);

    // ✅ FIX: Migrate saved slots to new format, then keep ONLY those
    // that exist in the master _slots list. This removes all ghost slots
    // (e.g. "02:00 AM - 03:00 AM") that were created by bad migration.
    final rawSlots = List<String>.from(widget.user.availableSlots ?? []);
    final migratedSlots = rawSlots.map(_migrateOldSlot).toList();

    // Only keep slots that are present in the master list
    _selectedSlots = migratedSlots
        .where((slot) => _slots.contains(slot))
        .toSet() // remove duplicates
        .toList();

    log('Raw slots from DB: $rawSlots');
    log('Migrated slots: $migratedSlots');
    log('Valid selected slots: $_selectedSlots');
  }

  /// Converts old-format slot "09:00-10:00" → "09:00 AM - 10:00 AM"
  /// If slot already contains AM/PM, returns as-is.
  String _migrateOldSlot(String slot) {
    if (slot.toUpperCase().contains('AM') || slot.toUpperCase().contains('PM')) {
      return slot.trim(); // already new format
    }
    // Try to parse old "HH:MM-HH:MM" or "HH:MM - HH:MM" format
    try {
      // Handle both "09:00-10:00" and "09:00 - 10:00"
      final normalized = slot.replaceAll(' ', '');
      final parts = normalized.split('-');
      if (parts.length == 2) {
        final start = _addAmPm(parts[0].trim());
        final end = _addAmPm(parts[1].trim());
        return '$start - $end';
      }
    } catch (_) {}
    return slot; // fallback unchanged
  }

  String _addAmPm(String time) {
    final parts = time.split(':');
    final hour = int.parse(parts[0]);
    final min = parts.length > 1 ? parts[1] : '00';
    if (hour < 12) return '${parts[0].padLeft(2, '0')}:$min AM';
    if (hour == 12) return '12:$min PM';
    final h = (hour - 12).toString().padLeft(2, '0');
    return '$h:$min PM';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _specializationController.dispose();
    _experienceController.dispose();
    _clinicNameController.dispose();
    _clinicAddressController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _aboutController.dispose();
    _onlineConsultationFeeController.dispose();
    _homeVisitFeeController.dispose();
    super.dispose();
  }

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

  Future<String?> _uploadImageToSupabase() async {
    if (_imageFile == null) return widget.user.imageUrl;
    try {
      final supabase = Supabase.instance.client;
      final fileName =
          '${widget.user.id}_${DateTime.now().millisecondsSinceEpoch}.png';
      final path = 'doctor/$fileName';
      log('Uploading image to Supabase: $path');
      await supabase.storage.from('images').upload(
            path,
            _imageFile!,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
          );
      final imageUrl = supabase.storage.from('images').getPublicUrl(path);
      log('Image uploaded: $imageUrl');
      return imageUrl;
    } catch (e) {
      log('Upload Image Error: $e');
      _showSnackBar('Failed to upload image', isError: true);
      return widget.user.imageUrl;
    }
  }

  Future<void> _getCoordinatesFromAddress() async {
    if (_clinicAddressController.text.trim().isEmpty) {
      _showSnackBar('Please enter clinic address first', isError: true);
      return;
    }
    try {
      setState(() => _saving = true);
      final address = _clinicAddressController.text.trim();
      log('Geocoding address: $address');
      List<Location> locations = await locationFromAddress(address);
      if (locations.isNotEmpty) {
        setState(() {
          _latitudeController.text =
              locations.first.latitude.toStringAsFixed(6);
          _longitudeController.text =
              locations.first.longitude.toStringAsFixed(6);
        });
        _showSnackBar('Location coordinates fetched successfully!');
      } else {
        _showSnackBar('No coordinates found for this address', isError: true);
      }
    } catch (e) {
      log('Geocoding Error: $e');
      _showSnackBar('Failed to get coordinates. Please enter manually',
          isError: true);
    } finally {
      setState(() => _saving = false);
    }
  }

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
      String? imageUrl = await _uploadImageToSupabase();

      // ✅ Save only valid slots — deduplicated and from master list only
      final slotsToSave = _selectedSlots
          .where((s) => _slots.contains(s))
          .toSet()
          .toList();

      log('Slots being saved: $slotsToSave');

      final updateData = {
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'imageUrl': imageUrl ?? '',
        'specialization': _specializationController.text.trim(),
        'experience': int.parse(_experienceController.text.trim()),
        'clinicName': _clinicNameController.text.trim(),
        'clinicAddress': _clinicAddressController.text.trim(),
        'latitude': _latitudeController.text.trim().isNotEmpty
            ? double.parse(_latitudeController.text.trim())
            : null,
        'longitude': _longitudeController.text.trim().isNotEmpty
            ? double.parse(_longitudeController.text.trim())
            : null,
        'about': _aboutController.text.trim(),
        'availableDays': _selectedDays,
        'availableSlots': slotsToSave, // ✅ only valid, clean slots
        'onlineConsultationFee':
            _onlineConsultationFeeController.text.trim().isNotEmpty
                ? double.parse(_onlineConsultationFeeController.text.trim())
                : null,
        'homeVisitFee': _homeVisitFeeController.text.trim().isNotEmpty
            ? double.parse(_homeVisitFeeController.text.trim())
            : null,
        'profileCompleted': true,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.user.id)
          .update(updateData);

      log('Doctor profile updated successfully');
      _showSnackBar('Profile updated successfully!');
      if (mounted) Navigator.pop(context, true);
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
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        backgroundColor: primaryTeal,
        title: Text(
          widget.user.isDoctorProfileComplete()
              ? "Edit Profile"
              : "Complete Profile",
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
              // Profile Image
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
                                  ? NetworkImage(widget.user.imageUrl)
                                      as ImageProvider
                                  : null),
                          child: _imageFile == null &&
                                  widget.user.imageUrl.isEmpty
                              ? Icon(Icons.person,
                                  size: 70, color: Colors.grey[400])
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
                                colors: [primaryTeal, lightTeal]),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: primaryTeal.withOpacity(0.4),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.camera_alt_rounded,
                              color: Colors.white, size: 22),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // Basic Information
              _buildSectionTitle("Basic Information"),
              _buildTextField(
                  "Full Name", _nameController, Icons.person_outline),
              _buildTextField(
                "Email",
                TextEditingController(text: widget.user.email),
                Icons.email_outlined,
                enabled: false,
              ),
              _buildTextField(
                "Phone Number",
                _phoneController,
                Icons.phone_outlined,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 24),

              // Professional Information
              _buildSectionTitle("Professional Information"),
              _buildTextField("Specialization", _specializationController,
                  Icons.medical_services_outlined),
              _buildTextField(
                "Experience (Years)",
                _experienceController,
                Icons.work_outline,
                keyboardType: TextInputType.number,
              ),
              _buildTextField("Clinic Name", _clinicNameController,
                  Icons.local_hospital_outlined),
              _buildTextField("Clinic Address", _clinicAddressController,
                  Icons.location_on_outlined),

              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      "Latitude",
                      _latitudeController,
                      Icons.my_location,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTextField(
                      "Longitude",
                      _longitudeController,
                      Icons.location_searching,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ),
                ],
              ),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _getCoordinatesFromAddress,
                  icon: const Icon(Icons.map_outlined),
                  label: const Text('Get Coordinates from Address'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: primaryTeal,
                    side: BorderSide(color: primaryTeal, width: 2),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),

              _buildTextField(
                  "About", _aboutController, Icons.info_outline,
                  maxLines: 4),
              const SizedBox(height: 24),

              // Consultation Fees
              _buildSectionTitle("Consultation Fees (PKR)"),
              _buildTextField(
                "Online Consultation Fee (Rs)",
                _onlineConsultationFeeController,
                Icons.videocam_outlined,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
              _buildTextField(
                "Home Visit Fee (Rs)",
                _homeVisitFeeController,
                Icons.home_outlined,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 24),

              // Available Days
              _buildSectionTitle("Available Days"),
              _buildChipContainer(
                children: _days.map((day) {
                  final isSelected = _selectedDays.contains(day);
                  return FilterChip(
                    label: Text(day),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        selected
                            ? _selectedDays.add(day)
                            : _selectedDays.remove(day);
                      });
                    },
                    backgroundColor: Colors.white,
                    selectedColor: primaryTeal.withOpacity(0.2),
                    checkmarkColor: primaryTeal,
                    labelStyle: TextStyle(
                      color: isSelected ? primaryTeal : Colors.grey[700],
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                    side: BorderSide(
                      color: isSelected ? primaryTeal : Colors.grey[300]!,
                      width: isSelected ? 2 : 1,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // ✅ Available Time Slots — only master _slots list shown
              // Selected state driven purely by _selectedSlots membership
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Morning slots (08:00 AM - 12:00 PM range)
                    _slotGroupLabel("🌅 Morning"),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _slots
                          .where((s) {
                            // Morning: slots that start before 12 PM
                            // i.e. start time contains AM
                            final startPart = s.split(' - ').first;
                            return startPart.contains('AM');
                          })
                          .map((slot) => _slotChip(slot))
                          .toList(),
                    ),
                    const SizedBox(height: 16),
                    // Afternoon / Evening slots
                    _slotGroupLabel("🌆 Afternoon / Evening"),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _slots
                          .where((s) {
                            // Afternoon: slots that start at 12 PM or later
                            final startPart = s.split(' - ').first;
                            return startPart.contains('PM');
                          })
                          .map((slot) => _slotChip(slot))
                          .toList(),
                    ),
                  ],
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
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 2,
                  ),
                  child: _saving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : const Text(
                          'Save Profile',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
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

  // ── Helpers ───────────────────────────────────────────────────────────────

  Widget _slotGroupLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.grey[600],
        ),
      ),
    );
  }

  /// ✅ FIX: Slot chip selected state checked against _slots master list only.
  /// Toggle adds/removes from _selectedSlots cleanly.
  Widget _slotChip(String slot) {
    final isSelected = _selectedSlots.contains(slot);
    return FilterChip(
      label: Text(
        slot,
        style: const TextStyle(fontSize: 12),
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          if (selected) {
            if (!_selectedSlots.contains(slot)) {
              _selectedSlots.add(slot);
            }
          } else {
            _selectedSlots.remove(slot);
          }
        });
      },
      backgroundColor: Colors.white,
      selectedColor: lightTeal.withOpacity(0.25),
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
  }

  Widget _buildChipContainer({required List<Widget> children}) {
    return Container(
      width: double.infinity,
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
      child: Wrap(spacing: 8, runSpacing: 8, children: children),
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
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }
}