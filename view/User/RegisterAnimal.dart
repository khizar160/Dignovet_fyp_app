
// import 'dart:developer';
// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:flutter_application_1/services/animal_services/animal_service.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';

// import '../../model/animal_model.dart';
// import '../../services/animal_service.dart';

// class RegisterAnimalPage extends StatefulWidget {
//   const RegisterAnimalPage({super.key});

//   @override
//   State<RegisterAnimalPage> createState() => _RegisterAnimalPageState();
// }

// class _RegisterAnimalPageState extends State<RegisterAnimalPage> {
//   final _formKey = GlobalKey<FormState>();

//   final _name = TextEditingController();
//   final _breed = TextEditingController();
//   final _age = TextEditingController();
//   final _disease = TextEditingController();
//   final _symptoms = TextEditingController();
// final _supabase = Supabase.instance.client;

//   String _gender = 'Male';
//   List<File> _images = [];
//   bool _loading = false;

//   final _picker = ImagePicker();
//   final _service = AnimalService();

//   Future<void> _pickImages() async {
//     final files = await _picker.pickMultiImage();
//     if (files != null && files.isNotEmpty) {
//       setState(() {
//         _images = files.map((e) => File(e.path)).toList();
//       });
//     }
//   }
//   Future<List<String>> _uploadAnimalImages(String userId) async {
//   List<String> urls = [];

//   for (int i = 0; i < _images.length; i++) {
//     final file = _images[i];
//     final path =
//         '$userId/${DateTime.now().millisecondsSinceEpoch}_$i.jpg';

//     await _supabase.storage
//         .from('animal') // ✅ bucket name
//         .upload(
//           path,
//           file,
//           fileOptions: const FileOptions(upsert: true),
//         );

//     final publicUrl =
//         _supabase.storage.from('animal').getPublicUrl(path);

//     urls.add(publicUrl);
//   }

//   return urls;
// }


//   Future<void> _registerAnimal() async {
//   if (_loading) return;
//   if (!_formKey.currentState!.validate()) return;

//   setState(() => _loading = true);

//   try {
//     final userId = FirebaseAuth.instance.currentUser!.uid;

//     // 1️⃣ Upload images to Supabase
//     List<String> imageUrls = [];
//     if (_images.isNotEmpty) {
//       imageUrls = await _uploadAnimalImages(userId);
//     }

//     // 2️⃣ Create animal model
//     final animal = Animal(
//       name: _name.text.trim(),
//       breed: _breed.text.trim(),
//       age: int.parse(_age.text),
//       gender: _gender,
//       userId: userId,
//       suspectedDisease: _disease.text.trim(),
//       symptoms: _symptoms.text.trim(),
//       createdAt: DateTime.now(),
//       imageUrls: imageUrls, // ✅ ADD THIS FIELD
//     );

//     // 3️⃣ Save to Firestore
//     await _service.registerAnimal(animal);

//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(
//         content: Text('Animal Registered Successfully 🎉'),
//         backgroundColor: Colors.teal,
//       ),
//     );

//     _formKey.currentState!.reset();
//     setState(() {
//       _images.clear();
//       _gender = 'Male';
//     });
//   } catch (e) {
//     log(  'Register Animal Error: $e');
//     ScaffoldMessenger.of(context)
//         .showSnackBar(SnackBar(content: Text('Error: $e')));
//   }

//   setState(() => _loading = false);
// }


//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF5FDFC),
//       appBar: AppBar(
//         backgroundColor: Colors.white,
//         elevation: 0,
//         centerTitle: true,
//         title: const Text(
//           'Register Animal',
//           style: TextStyle(
//             color: Colors.teal,
//             fontWeight: FontWeight.bold,
//             fontSize: 24,
//           ),
//         ),
//       ),
//       body: Stack(
//         children: [
//           SingleChildScrollView(
//             padding: const EdgeInsets.all(24),
//             child: Form(
//               key: _formKey,
//               child: Column(
//                 children: [
//                   _field(_name, 'Animal Name', Icons.pets),
//                   _field(_breed, 'Breed', Icons.category),
//                   _field(_age, 'Age', Icons.cake, TextInputType.number),
//                   _field(_disease, 'Suspected Disease', Icons.medical_information),
//                   _field(_symptoms, 'Symptoms', Icons.report),

//                   const SizedBox(height: 16),

//                   DropdownButtonFormField(
//                     value: _gender,
//                     decoration: _decoration('Gender', Icons.wc),
//                     items: ['Male', 'Female']
//                         .map((e) =>
//                             DropdownMenuItem(value: e, child: Text(e)))
//                         .toList(),
//                     onChanged: (v) => setState(() => _gender = v!),
//                   ),

//                   const SizedBox(height: 20),

//                   ElevatedButton.icon(
//                     onPressed: _pickImages,
//                     icon: const Icon(Icons.photo_library),
//                     label: Text(
//                       _images.isEmpty
//                           ? 'Select Images (Preview Only)'
//                           : '${_images.length} Images Selected',
//                     ),
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: const Color(0xFF80CBC4),
//                       padding: const EdgeInsets.symmetric(
//                           horizontal: 24, vertical: 16),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(30),
//                       ),
//                     ),
//                   ),

//                   const SizedBox(height: 16),

//                   /// 🖼️ IMAGE PREVIEW ONLY
//                   if (_images.isNotEmpty)
//                     SizedBox(
//                       height: 110,
//                       child: ListView.builder(
//                         scrollDirection: Axis.horizontal,
//                         itemCount: _images.length,
//                         itemBuilder: (_, i) => Padding(
//                           padding: const EdgeInsets.only(right: 12),
//                           child: ClipRRect(
//                             borderRadius: BorderRadius.circular(14),
//                             child: Image.file(
//                               _images[i],
//                               width: 110,
//                               height: 110,
//                               fit: BoxFit.cover,
//                             ),
//                           ),
//                         ),
//                       ),
//                     ),

//                   const SizedBox(height: 30),

//                   SizedBox(
//                     width: double.infinity,
//                     child: ElevatedButton(
//                       onPressed: _loading ? null : _registerAnimal,
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: Colors.teal,
//                         padding: const EdgeInsets.symmetric(vertical: 18),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(30),
//                         ),
//                       ),
//                       child: const Text(
//                         'Register Animal',
//                         style: TextStyle(
//                             fontSize: 18, fontWeight: FontWeight.bold),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),

//           /// 🔄 LOADER
//           if (_loading)
//             Container(
//               color: Colors.black.withOpacity(0.3),
//               child: const Center(
//                 child: CircularProgressIndicator(color: Colors.teal),
//               ),
//             ),
//         ],
//       ),
//     );
//   }

//   Widget _field(TextEditingController c, String l, IconData i,
//       [TextInputType t = TextInputType.text]) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 18),
//       child: TextFormField(
//         controller: c,
//         keyboardType: t,
//         validator: (v) => v!.isEmpty ? 'Required' : null,
//         decoration: _decoration(l, i),
//       ),
//     );
//   }

//   InputDecoration _decoration(String label, IconData icon) {
//     return InputDecoration(
//       labelText: label,
//       prefixIcon: Icon(icon, color: Colors.teal),
//       filled: true,
//       fillColor: Colors.white,
//       border: OutlineInputBorder(
//         borderRadius: BorderRadius.circular(16),
//         borderSide: BorderSide.none,
//       ),
//     );
//   }
// }

import 'dart:developer';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/services/animal_services/animal_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import '../../model/animal_model.dart';
import '../../services/animal_service.dart';
import '../../provider/language_provider.dart';

class RegisterAnimalPage extends StatefulWidget {
  const RegisterAnimalPage({super.key});

  @override
  State<RegisterAnimalPage> createState() => _RegisterAnimalPageState();
}

class _RegisterAnimalPageState extends State<RegisterAnimalPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _breed = TextEditingController();
  final _age = TextEditingController();
  final _disease = TextEditingController();
  final _symptoms = TextEditingController();
  final _supabase = Supabase.instance.client;

  String _gender = 'Male';
  List<File> _images = [];
  bool _loading = false;

  final _picker = ImagePicker();
  final _service = AnimalService();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _name.dispose();
    _breed.dispose();
    _age.dispose();
    _disease.dispose();
    _symptoms.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final files = await _picker.pickMultiImage();
    if (files != null && files.isNotEmpty) {
      setState(() {
        _images = files.map((e) => File(e.path)).toList();
      });
    }
  }

  Future<List<String>> _uploadAnimalImages(String userId) async {
    List<String> urls = [];
    for (int i = 0; i < _images.length; i++) {
      final file = _images[i];
      final path = '$userId/${DateTime.now().millisecondsSinceEpoch}_$i.jpg';

      await _supabase.storage.from('animal').upload(
            path,
            file,
            fileOptions: const FileOptions(upsert: true),
          );

      final publicUrl = _supabase.storage.from('animal').getPublicUrl(path);
      urls.add(publicUrl);
    }
    return urls;
  }

  Future<void> _registerAnimal(LanguageProvider languageProvider) async {
    if (_loading) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      final userId = FirebaseAuth.instance.currentUser!.uid;

      List<String> imageUrls = [];
      if (_images.isNotEmpty) {
        imageUrls = await _uploadAnimalImages(userId);
      }

      final animal = Animal(
        name: _name.text.trim(),
        breed: _breed.text.trim(),
        age: int.parse(_age.text),
        gender: _gender,
        userId: userId,
        suspectedDisease: _disease.text.trim(),
        symptoms: _symptoms.text.trim(),
        createdAt: DateTime.now(),
        imageUrls: imageUrls,
      );

      await _service.registerAnimal(animal);

      _showSnackBar(languageProvider.translate('animal_registered_success'), const Color(0xFF00796B));

      _formKey.currentState!.reset();
      setState(() {
        _images.clear();
        _gender = 'Male';
        _name.clear();
        _breed.clear();
        _age.clear();
        _disease.clear();
        _symptoms.clear();
      });
    } catch (e) {
      log('Register Animal Error: $e');
      _showSnackBar(languageProvider.translate('error_unable_to_register'), Colors.red);
    }

    setState(() => _loading = false);
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              color == Colors.red ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF00796B),
              const Color(0xFF4DB6AC),
              const Color(0xFF80CBC4),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(languageProvider),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(top: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: Stack(
                    children: [
                      _buildForm(languageProvider),
                      if (_loading) _buildLoader(languageProvider),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(LanguageProvider languageProvider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              languageProvider.translate('register_animal'),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 24,
                letterSpacing: -0.5,
                shadows: [
                  Shadow(
                    color: Colors.black26,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm(LanguageProvider languageProvider) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            _buildSectionHeader(languageProvider.t('Basic Information', 'بنیادی معلومات'), Icons.info_outline),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _name,
              label: languageProvider.translate('animal_name'),
              icon: Icons.pets,
              hint: languageProvider.t('e.g., Max, Luna', 'مثلاً، میکس، لونا'),
              languageProvider: languageProvider,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _breed,
              label: languageProvider.translate('breed'),
              icon: Icons.category_outlined,
              hint: languageProvider.t('e.g., Labrador, Persian Cat', 'مثلاً، لیبراڈور، فارسی بلی'),
              languageProvider: languageProvider,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _age,
                    label: languageProvider.translate('age'),
                    icon: Icons.cake_outlined,
                    hint: languageProvider.t('Years', 'سال'),
                    keyboardType: TextInputType.number,
                    languageProvider: languageProvider,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(child: _buildGenderDropdown(languageProvider)),
              ],
            ),
            const SizedBox(height: 28),
            _buildSectionHeader(languageProvider.t('Health Information', 'صحت کی معلومات'), Icons.medical_services_outlined),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _disease,
              label: languageProvider.translate('suspected_disease'),
              icon: Icons.medical_information_outlined,
              hint: languageProvider.t('If any', 'اگر کوئی ہے'),
              languageProvider: languageProvider,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _symptoms,
              label: languageProvider.translate('symptoms'),
              icon: Icons.description_outlined,
              hint: languageProvider.t('Describe any symptoms', 'علامات بیان کریں'),
              maxLines: 3,
              languageProvider: languageProvider,
            ),
            const SizedBox(height: 28),
            _buildSectionHeader(languageProvider.t('Images', 'تصاویر'), Icons.image_outlined),
            const SizedBox(height: 16),
            _buildImagePicker(languageProvider),
            if (_images.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildImagePreview(),
            ],
            const SizedBox(height: 32),
            _buildRegisterButton(languageProvider),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF00796B).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: const Color(0xFF00796B), size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2C3E50),
            letterSpacing: -0.3,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    required LanguageProvider languageProvider,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        prefixIcon: Container(
          margin: const EdgeInsets.only(right: 12),
          child: Icon(icon, color: const Color(0xFF00796B), size: 22),
        ),
        labelText: label,
        hintText: hint,
        hintStyle: TextStyle(
          color: Colors.grey[400],
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        labelStyle: TextStyle(
          color: Colors.grey[600],
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
        filled: true,
        fillColor: const Color(0xFFF5F5F5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey[200]!, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF00796B), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      validator: (value) => value == null || value.isEmpty ? languageProvider.translate('required') : null,
    );
  }

  Widget _buildGenderDropdown(LanguageProvider languageProvider) {
    return DropdownButtonFormField<String>(
      value: _gender,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Color(0xFF2C3E50)),
      decoration: InputDecoration(
        prefixIcon: Container(
          margin: const EdgeInsets.only(right: 12),
          child: const Icon(Icons.wc, color: Color(0xFF00796B), size: 22),
        ),
        labelText: languageProvider.translate('gender'),
        labelStyle: TextStyle(
          color: Colors.grey[600],
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
        filled: true,
        fillColor: const Color(0xFFF5F5F5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey[200]!, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF00796B), width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      items: ['Male', 'Female'].map((e) => DropdownMenuItem(
        value: e,
        child: Text(languageProvider.translate(e.toLowerCase())),
      )).toList(),
      onChanged: (v) => setState(() => _gender = v!),
    );
  }

  Widget _buildImagePicker(LanguageProvider languageProvider) {
    return GestureDetector(
      onTap: _pickImages,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
        decoration: BoxDecoration(
          color: const Color(0xFF00796B).withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF00796B).withOpacity(0.3),
            width: 2,
            style: BorderStyle.solid,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF00796B),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00796B).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(Icons.photo_library_outlined, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _images.isEmpty ? languageProvider.t('Add Photos', 'تصاویر شامل کریں') : '${_images.length} ${languageProvider.t('Photo', 'تصویر')}${_images.length > 1 ? languageProvider.t('s', '') : ''} ${languageProvider.translate('selected')}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _images.isEmpty ? languageProvider.t('Tap to select images', 'تصاویر منتخب کرنے کے لیے ٹیپ کریں') : languageProvider.t('Tap to change selection', 'انتخاب تبدیل کرنے کے لیے ٹیپ کریں'),
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: const Color(0xFF00796B),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    return SizedBox(
      height: 120,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _images.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) => Stack(
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(
                  _images[i],
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Positioned(
              top: 6,
              right: 6,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _images.removeAt(i);
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRegisterButton(LanguageProvider languageProvider) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color(0xFF00796B), Color(0xFF4DB6AC)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00796B).withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _loading ? null : () => _registerAnimal(languageProvider),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: _loading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle_outline, size: 22),
                  const SizedBox(width: 12),
                  Text(
                    languageProvider.translate('register_animal_button'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildLoader(LanguageProvider languageProvider) {
    return Container(
      color: Colors.black.withOpacity(0.3),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(
                color: Color(0xFF00796B),
                strokeWidth: 3,
              ),
              const SizedBox(height: 20),
              Text(
                languageProvider.t('Registering Animal...', 'جانور رجسٹر ہو رہا ہے...'),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                languageProvider.t('Please wait', 'براہ کرم انتظار کریں'),
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}