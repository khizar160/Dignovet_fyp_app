import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../../provider/language_provider.dart';

class DiseasePredictionPage extends StatefulWidget {
  const DiseasePredictionPage({super.key});

  @override
  State<DiseasePredictionPage> createState() => _DiseasePredictionPageState();
}

class _DiseasePredictionPageState extends State<DiseasePredictionPage> {
  final TextEditingController _detailsController = TextEditingController();
  bool _isPredicting = false;
  bool _loadingAnimals = true;
  bool _loadingImages = false;
  List<Map<String, dynamic>> _animals = [];
  String? _selectedAnimalId;
  List<File> _selectedImages = []; // Multiple images
  List<String> _selectedImageUrls = []; // Track selected URLs
  Map<String, File> _downloadedImages = {}; // Cache downloaded images by URL
  Set<String> _downloadingImages = {}; // Track which images are currently downloading

  @override
  void initState() {
    super.initState();
    _fetchAnimals();
  }

  /// Fetch animals for current user from Firestore
  Future<void> _fetchAnimals() async {
    try {
      debugPrint("Fetching animals...");
      final userId = FirebaseAuth.instance.currentUser!.uid;

      final snapshot = await FirebaseFirestore.instance
          .collection('animals')
          .where('userId', isEqualTo: userId)
          .get();

      debugPrint("Documents fetched: ${snapshot.docs.length}");

      final List<Map<String, dynamic>> fetchedAnimals = [];

      for (var doc in snapshot.docs) {
        final data = doc.data();
        debugPrint("Animal doc data: $data");

        List<String> images = [];
        if (data.containsKey('imageUrls') && data['imageUrls'] != null) {
          if (data['imageUrls'] is List) {
            images = List<String>.from(data['imageUrls'].map((e) => e.toString()));
          } else {
            debugPrint("Warning: 'imageUrls' is not a List for doc ${doc.id}");
          }
        }

        final label = '${data['name'] ?? 'Unnamed'} (${data['breed'] ?? 'Unknown'})';

        fetchedAnimals.add({
          'id': doc.id,
          'label': label,
          'images': images,
          'data': data,
        });

        debugPrint("Animal added: $label with ${images.length} images");
      }

      setState(() {
        _animals = fetchedAnimals;
        _loadingAnimals = false;
      });

      debugPrint("Total animals loaded: ${_animals.length}");
    } catch (e) {
      setState(() => _loadingAnimals = false);
      debugPrint("Error fetching animals: $e");
    }
  }

  /// Download image from URL
  Future<File> _downloadImage(String url) async {
    // Check if already downloaded
    if (_downloadedImages.containsKey(url)) {
      debugPrint("Image already cached: $url");
      return _downloadedImages[url]!;
    }

    debugPrint("Downloading image: $url");
    final response = await http.get(Uri.parse(url));
    final tempDir = Directory.systemTemp;
    final file = File('${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}_${url.hashCode}.jpg');
    await file.writeAsBytes(response.bodyBytes);
    debugPrint("Downloaded image saved to ${file.path}");
    
    // Cache the downloaded image
    _downloadedImages[url] = file;
    return file;
  }

  /// Download all images for selected animal
  Future<void> _downloadAllImages(List<String> imageUrls) async {
    if (imageUrls.isEmpty) return;

    setState(() => _loadingImages = true);

    try {
      for (String url in imageUrls) {
        if (!_downloadedImages.containsKey(url)) {
          setState(() => _downloadingImages.add(url));
          
          try {
            await _downloadImage(url);
          } catch (e) {
            debugPrint("Error downloading image $url: $e");
          } finally {
            setState(() => _downloadingImages.remove(url));
          }
        }
      }
    } finally {
      setState(() => _loadingImages = false);
    }

    if (mounted) {
      final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_downloadedImages.length} ${languageProvider.translate('images_loaded')}'),
          duration: const Duration(seconds: 1),
          backgroundColor: Colors.teal,
        ),
      );
    }
  }

  /// Display animal images horizontally with multi-select
  Widget _animalImagesWidget(Map<String, dynamic> animal, LanguageProvider languageProvider) {
    final images = animal['images'] as List<String>;
    debugPrint("Images for ${animal['label']}: $images");

    if (images.isEmpty) {
      return Text(
        languageProvider.translate('no_registered_images'),
        style: const TextStyle(color: Colors.grey),
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                languageProvider.translate('select_images_text'),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              TextButton.icon(
                onPressed: _loadingImages ? null : () async {
                  // Select all images
                  if (_selectedImageUrls.length == images.length) {
                    // Deselect all
                    setState(() {
                      _selectedImages.clear();
                      _selectedImageUrls.clear();
                    });
                  } else {
                    // Select all
                    final List<File> allFiles = [];
                    final List<String> allUrls = [];
                    
                    for (String imgUrl in images) {
                      if (_downloadedImages.containsKey(imgUrl)) {
                        allFiles.add(_downloadedImages[imgUrl]!);
                        allUrls.add(imgUrl);
                      }
                    }
                    
                    setState(() {
                      _selectedImages = allFiles;
                      _selectedImageUrls = allUrls;
                    });
                  }
                },
                icon: Icon(
                  _selectedImageUrls.length == images.length 
                    ? Icons.check_box 
                    : Icons.check_box_outline_blank,
                  size: 20,
                  color: Colors.teal,
                ),
                label: Text(
                  _selectedImageUrls.length == images.length ? languageProvider.translate('deselect_all') : languageProvider.translate('select_all'),
                  style: const TextStyle(color: Colors.teal, fontSize: 12),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_loadingImages)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.teal),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    languageProvider.translate('loading_images'),
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          Text(
            '${_selectedImageUrls.length} ${languageProvider.translate('of')} ${images.length} ${languageProvider.translate('selected')}',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: images.length,
              itemBuilder: (_, index) {
                final imgUrl = images[index];
                final isSelected = _selectedImageUrls.contains(imgUrl);
                final isDownloading = _downloadingImages.contains(imgUrl);
                final isDownloaded = _downloadedImages.containsKey(imgUrl);
      
                return GestureDetector(
                  onTap: isDownloading || !isDownloaded ? null : () async {
                    debugPrint("Toggled image: $imgUrl");
                    
                    if (isSelected) {
                      // Deselect image
                      setState(() {
                        final idx = _selectedImageUrls.indexOf(imgUrl);
                        _selectedImageUrls.removeAt(idx);
                        _selectedImages.removeAt(idx);
                      });
                    } else {
                      // Select image (already downloaded)
                      setState(() {
                        _selectedImages.add(_downloadedImages[imgUrl]!);
                        _selectedImageUrls.add(imgUrl);
                      });
                      debugPrint("Image selected: ${_downloadedImages[imgUrl]!.path}");
                    }
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isSelected ? Colors.teal : (isDownloaded ? Colors.grey : Colors.grey[300]!),
                        width: isSelected ? 3 : 1,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: Stack(
                        children: [
                          Image.network(
                            imgUrl,
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 100,
                              height: 100,
                              color: Colors.grey[300],
                              child: const Icon(Icons.broken_image, size: 40),
                            ),
                          ),
                          if (isDownloading)
                            Container(
                              width: 100,
                              height: 100,
                              color: Colors.black45,
                              child: const Center(
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 3,
                                ),
                              ),
                            ),
                          if (!isDownloading && !isDownloaded)
                            Container(
                              width: 100,
                              height: 100,
                              color: Colors.black26,
                              child: const Center(
                                child: Icon(Icons.download, color: Colors.white, size: 30),
                              ),
                            ),
                          if (isSelected && isDownloaded)
                            Positioned(
                              top: 4,
                              right: 4,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.teal,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Predict disease API call - sends multiple images
  Future<Map<String, dynamic>?> _predictFMD(List<File> imageFiles) async {
    try {
      debugPrint("Sending ${imageFiles.length} image(s) to API...");
      
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('http://10.75.27.97:8000/predict'),
      );
          
      // Add all image files
      for (int i = 0; i < imageFiles.length; i++) {
        final imageFile = imageFiles[i];
        debugPrint("Image $i file path: ${imageFile.path}");
        debugPrint("Image $i file exists: ${await imageFile.exists()}");
        debugPrint("Image $i file size: ${await imageFile.length()} bytes");

      request.files.add(await http.MultipartFile.fromPath(
  'file', // Use the name your backend expects
  imageFile.path,
  filename: 'animal_image_$i.jpg',
));

      }
      
      debugPrint("Sending request to API...");
      var response = await request.send();
      debugPrint("API Response status: ${response.statusCode}");

      if (response.statusCode == 200) {
        var respStr = await response.stream.bytesToString();
        debugPrint("API Response body: $respStr");
        return json.decode(respStr) as Map<String, dynamic>;
      } else {
        var errorBody = await response.stream.bytesToString();
        debugPrint("API Error: ${response.statusCode}");
        debugPrint("Error body: $errorBody");
        return null;
      }
    } catch (e) {
      debugPrint("Error calling API: $e");
      return null;
    }
  }

  Future<void> _predictDisease() async {
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    
    if (_selectedAnimalId == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(languageProvider.translate('please_select_animal_error')),
        backgroundColor: Colors.redAccent,
      ));
      return;
    }
    if (_detailsController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(languageProvider.translate('please_enter_symptoms')),
        backgroundColor: Colors.redAccent,
      ));
      return;
    }
    if (_selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(languageProvider.translate('please_select_one_image')),
        backgroundColor: Colors.redAccent,
      ));
      return;
    }

    // Verify the image files still exist
    for (var image in _selectedImages) {
      if (!await image.exists()) {
        debugPrint("Selected image file no longer exists!");
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(languageProvider.translate('image_file_not_found')),
          backgroundColor: Colors.redAccent,
        ));
        return;
      }
    }

    if (!context.mounted) return;
    setState(() => _isPredicting = true);
    
    final prediction = await _predictFMD(_selectedImages);

    if (prediction != null) {
      final selectedAnimal = _animals.firstWhere((a) => a['id'] == _selectedAnimalId);
      final userId = FirebaseAuth.instance.currentUser!.uid;

      try {
        await FirebaseFirestore.instance.collection('predictions').add({
          'userId': userId,
          'animalId': _selectedAnimalId,
          'animalData': selectedAnimal['data'],
          'symptoms': _detailsController.text.trim(),
          'imageUrls': _selectedImageUrls,
          'imageCount': _selectedImages.length,
          'prediction': prediction['prediction'],
          'confidence': prediction['confidence'],
          'probabilities': prediction['probabilities'],
          'timestamp': FieldValue.serverTimestamp(),
        });
        debugPrint("Prediction saved successfully.");
      } catch (e) {
        debugPrint("Error saving prediction: $e");
      }

      _showResultDialog(prediction);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(languageProvider.translate('prediction_failed')),
          backgroundColor: Colors.redAccent,
        ));
      }
    }
    
    if (!context.mounted) return;
    setState(() => _isPredicting = false);
  }

  void _showResultDialog(Map<String, dynamic> prediction) {
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    final selectedAnimal = _animals.firstWhere((a) => a['id'] == _selectedAnimalId)['label'];

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            const Icon(Icons.health_and_safety, color: Colors.teal, size: 30),
            const SizedBox(width: 12),
            Text(languageProvider.translate('prediction_result')),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${languageProvider.translate('animal')}: $selectedAnimal', style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 5),
              Text('${languageProvider.translate('images_analyzed')}: ${_selectedImages.length}', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
              const SizedBox(height: 10),
              Text('${languageProvider.translate('prediction')}: ${prediction['prediction']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 5),
              Text('${languageProvider.translate('confidence')}: ${prediction['confidence']}%', style: const TextStyle(fontSize: 15)),
              const SizedBox(height: 10),
              Text('${languageProvider.translate('probabilities')}:', style: const TextStyle(fontWeight: FontWeight.bold)),
              ...prediction['probabilities'].entries.map((e) => 
                Padding(
                  padding: const EdgeInsets.only(left: 8, top: 4),
                  child: Text('• ${e.key}: ${e.value}%'),
                )
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(languageProvider.translate('close'), style: const TextStyle(color: Colors.teal, fontSize: 18)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    
    return Scaffold(
      backgroundColor: const Color(0xFFB2DFDB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFB2DFDB),
        elevation: 0,
        title: Text(languageProvider.translate('app_name'), style: const TextStyle(color: Colors.white, fontSize: 24)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            children: [
              Text(languageProvider.translate('disease_prediction'), style: const TextStyle(fontSize: 34, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 40),
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(32)),
                child: Column(
                  children: [
                    _loadingAnimals
                        ? const CircularProgressIndicator(color: Colors.teal)
                        : DropdownButtonFormField<String>(
                            value: _selectedAnimalId,
                            hint: Text(languageProvider.translate('select_animal')),
                            decoration: _inputDecoration(Icons.pets),
                            items: _animals.map((animal) {
                              return DropdownMenuItem<String>(
                                value: animal['id'],
                                child: Text(animal['label']),
                              );
                            }).toList(),
                            onChanged: (v) async {
                              setState(() {
                                _selectedAnimalId = v;
                                _selectedImages.clear();
                                _selectedImageUrls.clear();
                              });
                              
                              // Download all images for the selected animal
                              if (v != null) {
                                final selectedAnimal = _animals.firstWhere((a) => a['id'] == v);
                                final images = selectedAnimal['images'] as List<String>;
                                await _downloadAllImages(images);
                              }
                            },
                          ),
                    const SizedBox(height: 20),
                    _selectedAnimalId == null
                        ? const SizedBox()
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "${languageProvider.translate('breed')}: ${_animals.firstWhere((a) => a['id'] == _selectedAnimalId)['data']['breed'] ?? languageProvider.translate('unknown')}",
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                "${languageProvider.translate('age')}: ${_animals.firstWhere((a) => a['id'] == _selectedAnimalId)['data']['age'] ?? languageProvider.translate('unknown')}",
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 15),
                              _animalImagesWidget(_animals.firstWhere((a) => a['id'] == _selectedAnimalId), languageProvider),
                            ],
                          ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _detailsController,
                      maxLines: 5,
                      decoration: _inputDecoration(Icons.report).copyWith(hintText: languageProvider.translate('describe_symptoms')),
                    ),
                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      height: 65,
                      child: ElevatedButton(
                        onPressed: _isPredicting ? null : _predictDisease,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.teal,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
                        ),
                        child: _isPredicting
                            ? const CircularProgressIndicator(color: Colors.teal)
                            : Text(languageProvider.translate('predict_disease_btn'), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                      ),
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

  InputDecoration _inputDecoration(IconData icon) {
    return InputDecoration(
      prefixIcon: Icon(icon, color: Colors.teal),
      filled: true,
      fillColor: Colors.grey[50],
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: Colors.teal, width: 2)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: Colors.teal, width: 2)),
    );
  }
}

// import 'dart:convert';
// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:http/http.dart' as http;

// class DiseasePredictionPage extends StatefulWidget {
//   const DiseasePredictionPage({super.key});

//   @override
//   State<DiseasePredictionPage> createState() => _DiseasePredictionPageState();
// }

// class _DiseasePredictionPageState extends State<DiseasePredictionPage> {
//   // --- Professional Color Palette ---
//   final Color primaryTeal = const Color(0xFF00796B);
//   final Color secondaryTeal = const Color(0xFF004D40);
//   final Color accentColor = const Color(0xFF26A69A);
//   final Color bgLight = const Color(0xFFF5F7FA);

//   final TextEditingController _detailsController = TextEditingController();
//   bool _isPredicting = false;
//   bool _loadingAnimals = true;
//   bool _loadingImages = false;
//   List<Map<String, dynamic>> _animals = [];
//   String? _selectedAnimalId;
//   List<File> _selectedImages = [];
//   List<String> _selectedImageUrls = [];
//   Map<String, File> _downloadedImages = {};
//   Set<String> _downloadingImages = {};

//   @override
//   void initState() {
//     super.initState();
//     _fetchAnimals();
//   }

//   // --- Core Logic (Unchanged as per your request) ---
//   Future<void> _fetchAnimals() async {
//     try {
//       final userId = FirebaseAuth.instance.currentUser!.uid;
//       final snapshot = await FirebaseFirestore.instance
//           .collection('animals')
//           .where('userId', isEqualTo: userId)
//           .get();

//       final List<Map<String, dynamic>> fetchedAnimals = [];
//       for (var doc in snapshot.docs) {
//         final data = doc.data();
//         List<String> images = [];
//         if (data.containsKey('imageUrls') && data['imageUrls'] is List) {
//           images = List<String>.from(data['imageUrls'].map((e) => e.toString()));
//         }
//         fetchedAnimals.add({
//           'id': doc.id,
//           'label': '${data['name'] ?? 'Unnamed'} (${data['breed'] ?? 'Unknown'})',
//           'images': images,
//           'data': data,
//         });
//       }
//       setState(() {
//         _animals = fetchedAnimals;
//         _loadingAnimals = false;
//       });
//     } catch (e) {
//       setState(() => _loadingAnimals = false);
//     }
//   }

//   Future<File> _downloadImage(String url) async {
//     if (_downloadedImages.containsKey(url)) return _downloadedImages[url]!;
//     final response = await http.get(Uri.parse(url));
//     final tempDir = Directory.systemTemp;
//     final file = File('${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}_${url.hashCode}.jpg');
//     await file.writeAsBytes(response.bodyBytes);
//     _downloadedImages[url] = file;
//     return file;
//   }

//   Future<void> _downloadAllImages(List<String> imageUrls) async {
//     if (imageUrls.isEmpty) return;
//     setState(() => _loadingImages = true);
//     try {
//       for (String url in imageUrls) {
//         if (!_downloadedImages.containsKey(url)) {
//           setState(() => _downloadingImages.add(url));
//           try { await _downloadImage(url); } catch (e) {}
//           finally { setState(() => _downloadingImages.remove(url)); }
//         }
//       }
//     } finally { setState(() => _loadingImages = false); }
//   }

//   // --- UI Building ---
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: primaryTeal,
//       appBar: AppBar(
//         backgroundColor: Colors.transparent,
//         elevation: 0,
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
//           onPressed: () => Navigator.pop(context),
//         ),
//         title: const Text('DignoVet AI', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
//         centerTitle: true,
//       ),
//       body: Column(
//         children: [
//           _buildHeader(),
//           Expanded(
//             child: Container(
//               width: double.infinity,
//               padding: const EdgeInsets.symmetric(horizontal: 24),
//               decoration: const BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.only(
//                   topLeft: Radius.circular(40),
//                   topRight: Radius.circular(40),
//                 ),
//               ),
//               child: _loadingAnimals 
//                   ? Center(child: CircularProgressIndicator(color: primaryTeal))
//                   : SingleChildScrollView(
//                       physics: const BouncingScrollPhysics(),
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           const SizedBox(height: 35),
//                           _sectionTitle("Select Animal", Icons.pets),
//                           _buildAnimalDropdown(),
//                           if (_selectedAnimalId != null) ...[
//                             const SizedBox(height: 20),
//                             _buildAnimalSpecsCard(),
//                             const SizedBox(height: 25),
//                             _sectionTitle("Visual Evidence (Select Images)", Icons.camera_alt),
//                             const SizedBox(height: 12),
//                             _buildImageSelector(),
//                           ],
//                           const SizedBox(height: 25),
//                           _sectionTitle("Symptoms Description", Icons.analytics),
//                           const SizedBox(height: 12),
//                           _buildSymptomField(),
//                           const SizedBox(height: 40),
//                           _buildPredictButton(),
//                           const SizedBox(height: 30),
//                         ],
//                       ),
//                     ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildHeader() {
//     return Padding(
//       padding: const EdgeInsets.all(20.0),
//       child: Column(
//         children: [
//           const Icon(Icons.health_and_safety_outlined, color: Colors.white, size: 50),
//           const SizedBox(height: 10),
//           const Text(
//             "Disease Prediction",
//             style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
//           ),
//           Text(
//             "FMD & Mouth Disease Analysis",
//             style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.8)),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _sectionTitle(String title, IconData icon) {
//     return Row(
//       children: [
//         Icon(icon, size: 20, color: primaryTeal),
//         const SizedBox(width: 8),
//         Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: secondaryTeal)),
//       ],
//     );
//   }

//   Widget _buildAnimalDropdown() {
//     return Container(
//       margin: const EdgeInsets.only(top: 10),
//       padding: const EdgeInsets.symmetric(horizontal: 15),
//       decoration: BoxDecoration(
//         color: bgLight,
//         borderRadius: BorderRadius.circular(15),
//         border: Border.all(color: Colors.grey[300]!),
//       ),
//       child: DropdownButtonHideUnderline(
//         child: DropdownButtonFormField<String>(
//           value: _selectedAnimalId,
//           hint: const Text('Choose an animal'),
//           items: _animals.map((a) => DropdownMenuItem(value: a['id'] as String, child: Text(a['label']))).toList(),
//           onChanged: (v) async {
//             setState(() {
//               _selectedAnimalId = v;
//               _selectedImages.clear();
//               _selectedImageUrls.clear();
//             });
//             if (v != null) {
//               final selectedAnimal = _animals.firstWhere((a) => a['id'] == v);
//               await _downloadAllImages(selectedAnimal['images'] as List<String>);
//             }
//           },
//           decoration: const InputDecoration(border: InputBorder.none),
//         ),
//       ),
//     );
//   }

//   Widget _buildAnimalSpecsCard() {
//     final data = _animals.firstWhere((a) => a['id'] == _selectedAnimalId)['data'];
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         gradient: LinearGradient(colors: [primaryTeal.withOpacity(0.1), accentColor.withOpacity(0.05)]),
//         borderRadius: BorderRadius.circular(20),
//         border: Border.all(color: primaryTeal.withOpacity(0.2)),
//       ),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceAround,
//         children: [
//           _specItem("Breed", data['breed'] ?? 'N/A'),
//           Container(height: 30, width: 1, color: primaryTeal.withOpacity(0.2)),
//           _specItem("Age", "${data['age'] ?? 'N/A'} yrs"),
//         ],
//       ),
//     );
//   }

//   Widget _specItem(String label, String value) {
//     return Column(
//       children: [
//         Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
//         Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: secondaryTeal)),
//       ],
//     );
//   }

//   Widget _buildImageSelector() {
//     final animal = _animals.firstWhere((a) => a['id'] == _selectedAnimalId);
//     final images = animal['images'] as List<String>;

//     return SizedBox(
//       height: 120,
//       child: images.isEmpty 
//         ? const Center(child: Text("No registered images found."))
//         : ListView.builder(
//             scrollDirection: Axis.horizontal,
//             itemCount: images.length,
//             itemBuilder: (context, index) {
//               final url = images[index];
//               final isSelected = _selectedImageUrls.contains(url);
//               final isDownloaded = _downloadedImages.containsKey(url);
              
//               return GestureDetector(
//                 onTap: !isDownloaded ? null : () {
//                   setState(() {
//                     if (isSelected) {
//                       int idx = _selectedImageUrls.indexOf(url);
//                       _selectedImageUrls.removeAt(idx);
//                       _selectedImages.removeAt(idx);
//                     } else {
//                       _selectedImageUrls.add(url);
//                       _selectedImages.add(_downloadedImages[url]!);
//                     }
//                   });
//                 },
//                 child: Container(
//                   width: 100,
//                   margin: const EdgeInsets.only(right: 12),
//                   decoration: BoxDecoration(
//                     borderRadius: BorderRadius.circular(18),
//                     border: Border.all(color: isSelected ? accentColor : Colors.transparent, width: 3),
//                     boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 5)],
//                   ),
//                   child: ClipRRect(
//                     borderRadius: BorderRadius.circular(15),
//                     child: Stack(
//                       fit: StackFit.expand,
//                       children: [
//                         Image.network(url, fit: BoxFit.cover),
//                         if (!isDownloaded) Container(color: Colors.black45, child: const Center(child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))),
//                         if (isSelected) Container(color: accentColor.withOpacity(0.4), child: const Icon(Icons.check_circle, color: Colors.white, size: 30)),
//                       ],
//                     ),
//                   ),
//                 ),
//               );
//             },
//           ),
//     );
//   }

//   Widget _buildSymptomField() {
//     return TextField(
//       controller: _detailsController,
//       maxLines: 4,
//       decoration: InputDecoration(
//         hintText: 'e.g. Excessive drooling, blisters on mouth/feet, lameness, or loss of appetite...',
//         hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
//         filled: true,
//         fillColor: bgLight,
//         border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
//         focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide(color: primaryTeal)),
//       ),
//     );
//   }

//   Widget _buildPredictButton() {
//     return Container(
//       width: double.infinity,
//       height: 60,
//       decoration: BoxDecoration(
//         borderRadius: BorderRadius.circular(20),
//         gradient: LinearGradient(colors: [primaryTeal, secondaryTeal]),
//         boxShadow: [BoxShadow(color: primaryTeal.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6))],
//       ),
//       child: ElevatedButton(
//         onPressed: _isPredicting ? null : _predictDisease,
//         style: ElevatedButton.styleFrom(
//           backgroundColor: Colors.transparent,
//           shadowColor: Colors.transparent,
//           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
//         ),
//         child: _isPredicting 
//           ? const CircularProgressIndicator(color: Colors.white)
//           : const Text("Predict Disease", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
//       ),
//     );
//   }

//   // --- Logic Calls ---
//   Future<void> _predictDisease() async {
//     if (_selectedAnimalId == null || _detailsController.text.trim().isEmpty || _selectedImages.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select animal, images and enter symptoms')));
//       return;
//     }
//     setState(() => _isPredicting = true);
//     final prediction = await _predictFMD(_selectedImages);
//     if (prediction != null) {
//       _saveAndShow(prediction);
//     } else {
//       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Prediction failed. Check Server.')));
//     }
//     setState(() => _isPredicting = false);
//   }

//   Future<Map<String, dynamic>?> _predictFMD(List<File> imageFiles) async {
//     try {
//       var request = http.MultipartRequest('POST', Uri.parse('http://10.21.113.95:8000/predict'));
//       for (int i = 0; i < imageFiles.length; i++) {
//         request.files.add(await http.MultipartFile.fromPath('file', imageFiles[i].path, filename: 'fmd_check_$i.jpg'));
//       }
//       var response = await request.send();
//       if (response.statusCode == 200) {
//         return json.decode(await response.stream.bytesToString());
//       }
//     } catch (e) { debugPrint("Error: $e"); }
//     return null;
//   }

//   void _saveAndShow(Map<String, dynamic> prediction) async {
//     await FirebaseFirestore.instance.collection('predictions').add({
//       'userId': FirebaseAuth.instance.currentUser!.uid,
//       'animalId': _selectedAnimalId,
//       'symptoms': _detailsController.text.trim(),
//       'prediction': prediction['prediction'],
//       'confidence': prediction['confidence'],
//       'timestamp': FieldValue.serverTimestamp(),
//     });
//     _showResultDialog(prediction);
//   }

//   void _showResultDialog(Map<String, dynamic> prediction) {
//     showDialog(
//       context: context,
//       builder: (_) => AlertDialog(
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
//         title: Column(
//           children: [
//             Icon(Icons.check_circle_outline, color: primaryTeal, size: 50),
//             const SizedBox(height: 10),
//             const Text("Analysis Complete"),
//           ],
//         ),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Text(prediction['prediction'].toString().toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: Colors.redAccent)),
//             const SizedBox(height: 8),
//             Text("Confidence: ${prediction['confidence']}%", style: const TextStyle(fontSize: 16)),
//           ],
//         ),
//         actions: [
//           Center(
//             child: TextButton(
//               onPressed: () => Navigator.pop(context),
//               child: Text("Done", style: TextStyle(color: primaryTeal, fontWeight: FontWeight.bold, fontSize: 18)),
//             ),
//           )
//         ],
//       ),
//     );
//   }
// }