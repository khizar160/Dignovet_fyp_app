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
  Set<String> _downloadingImages =
      {}; // Track which images are currently downloading

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
            images = List<String>.from(
              data['imageUrls'].map((e) => e.toString()),
            );
          } else {
            debugPrint("Warning: 'imageUrls' is not a List for doc ${doc.id}");
          }
        }

        final label =
            '${data['name'] ?? 'Unnamed'} (${data['breed'] ?? 'Unknown'})';

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
    final file = File(
      '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}_${url.hashCode}.jpg',
    );
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
      final languageProvider = Provider.of<LanguageProvider>(
        context,
        listen: false,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${_downloadedImages.length} ${languageProvider.translate('images_loaded')}',
          ),
          duration: const Duration(seconds: 1),
          backgroundColor: Colors.teal,
        ),
      );
    }
  }

  /// Display animal images horizontally with multi-select
  Widget _animalImagesWidget(
    Map<String, dynamic> animal,
    LanguageProvider languageProvider,
  ) {
    final images = animal['images'] as List<String>;
    debugPrint("Images for ${animal['label']}: $images");

    if (images.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Icon(
                Icons.image_not_supported,
                size: 50,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 10),
              Text(
                languageProvider.translate('no_registered_images'),
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF00796B).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${_selectedImageUrls.length} / ${images.length} ${languageProvider.translate('selected')}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF00796B),
                ),
              ),
            ),
            TextButton.icon(
              onPressed: _loadingImages
                  ? null
                  : () async {
                      if (_selectedImageUrls.length == images.length) {
                        setState(() {
                          _selectedImages.clear();
                          _selectedImageUrls.clear();
                        });
                      } else {
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
                    ? Icons.check_circle
                    : Icons.radio_button_unchecked,
                size: 18,
                color: const Color(0xFF00796B),
              ),
              label: Text(
                _selectedImageUrls.length == images.length
                    ? languageProvider.translate('deselect_all')
                    : languageProvider.translate('select_all'),
                style: const TextStyle(
                  color: Color(0xFF00796B),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        if (_loadingImages)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Color(0xFF00796B),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  languageProvider.translate('loading_images'),
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF00796B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        SizedBox(
          height: 130,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: images.length,
            itemBuilder: (_, index) {
              final imgUrl = images[index];
              final isSelected = _selectedImageUrls.contains(imgUrl);
              final isDownloading = _downloadingImages.contains(imgUrl);
              final isDownloaded = _downloadedImages.containsKey(imgUrl);

              return GestureDetector(
                onTap: isDownloading || !isDownloaded
                    ? null
                    : () async {
                        debugPrint("Toggled image: $imgUrl");

                        if (isSelected) {
                          setState(() {
                            final idx = _selectedImageUrls.indexOf(imgUrl);
                            _selectedImageUrls.removeAt(idx);
                            _selectedImages.removeAt(idx);
                          });
                        } else {
                          setState(() {
                            _selectedImages.add(_downloadedImages[imgUrl]!);
                            _selectedImageUrls.add(imgUrl);
                          });
                          debugPrint(
                            "Image selected: ${_downloadedImages[imgUrl]!.path}",
                          );
                        }
                      },
                child: Container(
                  margin: const EdgeInsets.only(right: 15),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: isSelected
                            ? const Color(0xFF00796B).withOpacity(0.3)
                            : Colors.black.withOpacity(0.1),
                        blurRadius: isSelected ? 12 : 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Container(
                          width: 110,
                          height: 110,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFF00796B)
                                  : Colors.grey[300]!,
                              width: isSelected ? 3 : 2,
                            ),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Image.network(
                            imgUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: Colors.grey[200],
                              child: Icon(
                                Icons.broken_image,
                                size: 40,
                                color: Colors.grey[400],
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (isDownloading)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: Container(
                            width: 110,
                            height: 110,
                            color: Colors.black54,
                            child: const Center(
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 3,
                              ),
                            ),
                          ),
                        ),
                      if (!isDownloading && !isDownloaded)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: Container(
                            width: 110,
                            height: 110,
                            color: Colors.black38,
                            child: const Center(
                              child: Icon(
                                Icons.cloud_download,
                                color: Colors.white,
                                size: 35,
                              ),
                            ),
                          ),
                        ),
                      if (isSelected && isDownloaded)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF00796B), Color(0xFF4DB6AC)],
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFF00796B,
                                  ).withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.check_circle,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
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

        request.files.add(
          await http.MultipartFile.fromPath(
            'file', // Use the name your backend expects
            imageFile.path,
            filename: 'animal_image_$i.jpg',
          ),
        );
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
    final languageProvider = Provider.of<LanguageProvider>(
      context,
      listen: false,
    );

    if (_selectedAnimalId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            languageProvider.translate('please_select_animal_error'),
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }
    if (_detailsController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(languageProvider.translate('please_enter_symptoms')),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }
    if (_selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(languageProvider.translate('please_select_one_image')),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    // Verify the image files still exist
    for (var image in _selectedImages) {
      if (!await image.exists()) {
        debugPrint("Selected image file no longer exists!");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(languageProvider.translate('image_file_not_found')),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }
    }

    if (!context.mounted) return;
    setState(() => _isPredicting = true);

    final prediction = await _predictFMD(_selectedImages);

    if (prediction != null) {
      final selectedAnimal = _animals.firstWhere(
        (a) => a['id'] == _selectedAnimalId,
      );
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(languageProvider.translate('prediction_failed')),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }

    if (!context.mounted) return;
    setState(() => _isPredicting = false);
  }

  void _showResultDialog(Map<String, dynamic> prediction) {
    final languageProvider = Provider.of<LanguageProvider>(
      context,
      listen: false,
    );
    final selectedAnimal = _animals.firstWhere(
      (a) => a['id'] == _selectedAnimalId,
    )['label'];

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        backgroundColor: Colors.white,
        contentPadding: EdgeInsets.zero,
        content: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFF8F9FA), Colors.white],
            ),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with gradient
                Container(
                  padding: const EdgeInsets.all(25),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF00796B), Color(0xFF4DB6AC)],
                    ),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.analytics_rounded,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                      const SizedBox(height: 15),
                      Text(
                        languageProvider.translate('prediction_result'),
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'AI Analysis Complete',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),

                // Content
                Padding(
                  padding: const EdgeInsets.all(25),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Animal Info
                      Container(
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00796B).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.pets, color: Color(0xFF00796B)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    languageProvider.translate('animal'),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  Text(
                                    selectedAnimal,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 15),

                      // Images Analyzed
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.photo_library,
                              size: 20,
                              color: Colors.blue,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            '${languageProvider.translate('images_analyzed')}: ${_selectedImages.length}',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Prediction Result
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.red.withOpacity(0.1),
                              Colors.orange.withOpacity(0.1),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: Colors.red.withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              languageProvider
                                  .translate('prediction')
                                  .toUpperCase(),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              prediction['prediction'],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 22,
                                color: Colors.redAccent,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 15),

                      // Confidence Score
                      Container(
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00796B).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.verified,
                                  color: Color(0xFF00796B),
                                  size: 22,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  languageProvider.translate('confidence'),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              '${prediction['confidence']}%',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF00796B),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Probabilities
                      Text(
                        languageProvider.translate('probabilities'),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                      const SizedBox(height: 10),
                      ...prediction['probabilities'].entries.map(
                        (e) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF00796B),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  e.key,
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF00796B,
                                  ).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${e.value}%',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: Color(0xFF00796B),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Close Button
                Padding(
                  padding: const EdgeInsets.only(
                    left: 25,
                    right: 25,
                    bottom: 25,
                  ),
                  child: Container(
                    width: double.infinity,
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF00796B), Color(0xFF4DB6AC)],
                      ),
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00796B).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: Text(
                        languageProvider.translate('close'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF00796B), // Teal
              Color(0xFF4DB6AC), // Medium teal
              Color(0xFF80CBC4), // Light teal
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Dashboard Header
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.arrow_back_ios_new,
                            color: Colors.white,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const Icon(
                          Icons.health_and_safety_rounded,
                          color: Colors.white,
                          size: 40,
                        ),
                        const SizedBox(width: 40),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      languageProvider.translate('disease_prediction'),
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
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
                    const SizedBox(height: 5),
                    Text(
                      'AI-Powered Veterinary Diagnosis',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),

              // Main Content Card
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(top: 20),
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: _loadingAnimals
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF00796B),
                            strokeWidth: 3,
                          ),
                        )
                      : SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Animal Selection Card
                              _buildSectionTitle(
                                languageProvider.translate('select_animal'),
                                Icons.pets,
                              ),
                              const SizedBox(height: 12),
                              _buildAnimalDropdownCard(languageProvider),

                              if (_selectedAnimalId != null) ...[
                                const SizedBox(height: 24),
                                _buildAnimalInfoCard(languageProvider),

                                const SizedBox(height: 24),
                                _buildSectionTitle(
                                  '${languageProvider.translate('select_images_text')} (${_selectedImageUrls.length})',
                                  Icons.photo_library,
                                ),
                                const SizedBox(height: 12),
                                _buildImageSelectionCard(languageProvider),
                              ],

                              const SizedBox(height: 24),
                              _buildSectionTitle(
                                languageProvider.translate('describe_symptoms'),
                                Icons.description,
                              ),
                              const SizedBox(height: 12),
                              _buildSymptomsCard(languageProvider),

                              const SizedBox(height: 30),
                              _buildPredictButton(languageProvider),
                              const SizedBox(height: 20),
                            ],
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
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
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2C3E50),
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildAnimalDropdownCard(LanguageProvider languageProvider) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      child: DropdownButtonFormField<String>(
        value: _selectedAnimalId,
        hint: Text(languageProvider.translate('select_animal')),
        decoration: const InputDecoration(
          border: InputBorder.none,
          prefixIcon: Icon(Icons.pets, color: Color(0xFF00796B)),
        ),
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

          if (v != null) {
            final selectedAnimal = _animals.firstWhere((a) => a['id'] == v);
            final images = selectedAnimal['images'] as List<String>;
            await _downloadAllImages(images);
          }
        },
      ),
    );
  }

  Widget _buildAnimalInfoCard(LanguageProvider languageProvider) {
    final animalData = _animals.firstWhere(
      (a) => a['id'] == _selectedAnimalId,
    )['data'];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF00796B), Color(0xFF4DB6AC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00796B).withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildInfoItem(
              languageProvider.translate('breed'),
              animalData['breed'] ?? languageProvider.translate('unknown'),
              Icons.category,
            ),
          ),
          Container(height: 50, width: 1, color: Colors.white.withOpacity(0.3)),
          Expanded(
            child: _buildInfoItem(
              languageProvider.translate('age'),
              '${animalData['age'] ?? languageProvider.translate('unknown')}',
              Icons.calendar_today,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white.withOpacity(0.9), size: 28),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildImageSelectionCard(LanguageProvider languageProvider) {
    final animal = _animals.firstWhere((a) => a['id'] == _selectedAnimalId);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: _animalImagesWidget(animal, languageProvider),
    );
  }

  Widget _buildSymptomsCard(LanguageProvider languageProvider) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      padding: const EdgeInsets.all(5),
      child: TextField(
        controller: _detailsController,
        maxLines: 5,
        decoration: InputDecoration(
          hintText: languageProvider.translate('describe_symptoms'),
          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
          prefixIcon: const Padding(
            padding: EdgeInsets.only(bottom: 60),
            child: Icon(Icons.edit_note, color: Color(0xFF00796B)),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.grey[50],
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(color: Color(0xFF00796B), width: 2),
          ),
        ),
      ),
    );
  }

  Widget _buildPredictButton(LanguageProvider languageProvider) {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF00796B), Color(0xFF4DB6AC)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00796B).withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isPredicting ? null : _predictDisease,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: _isPredicting
            ? const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 3,
                    ),
                  ),
                  SizedBox(width: 15),
                  Text(
                    'Analyzing...',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.psychology, color: Colors.white, size: 24),
                  const SizedBox(width: 12),
                  Text(
                    languageProvider.translate('predict_disease_btn'),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
      ),
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