import 'package:shared_preferences/shared_preferences.dart';

class LanguageService {
  static const String _languageKey = 'app_language';
  static const String english = 'en';
  static const String urdu = 'ur';

  // Singleton pattern
  static final LanguageService _instance = LanguageService._internal();
  factory LanguageService() => _instance;
  LanguageService._internal();

  String _currentLanguage = english;

  String get currentLanguage => _currentLanguage;
  bool get isUrdu => _currentLanguage == urdu;
  bool get isEnglish => _currentLanguage == english;

  // Initialize and load saved language
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _currentLanguage = prefs.getString(_languageKey) ?? english;
  }

  // Switch language and save preference
  Future<void> setLanguage(String language) async {
    if (language != english && language != urdu) return;
    _currentLanguage = language;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, language);
  }

  // Toggle between English and Urdu
  Future<void> toggleLanguage() async {
    final newLanguage = _currentLanguage == english ? urdu : english;
    await setLanguage(newLanguage);
  }

  // Get translated text
  String translate(String englishText, String urduText) {
    return _currentLanguage == urdu ? urduText : englishText;
  }
}

// Translation constants for User Dashboard
class AppTranslations {
  static const Map<String, Map<String, String>> translations = {
    // App Name
    'app_name': {'en': 'DignoVet', 'ur': 'ڈگنووٹ'},

    // Dashboard
    'dashboard': {'en': 'Dashboard', 'ur': 'ڈیش بورڈ'},
    'welcome_back': {'en': 'Welcome Back!', 'ur': 'خوش آمدید!'},
    'explore_services': {
      'en': 'Explore our services',
      'ur': 'ہماری خدمات دریافت کریں',
    },

    // Settings
    'settings': {'en': 'Settings', 'ur': 'ترتیبات'},
    'language': {'en': 'Language', 'ur': 'زبان'},
    'language_settings': {'en': 'Language Settings', 'ur': 'زبان کی ترتیبات'},
    'select_language': {
      'en': 'Select your preferred language',
      'ur': 'اپنی پسندیدہ زبان منتخب کریں',
    },
    'english': {'en': 'English', 'ur': 'انگریزی'},
    'urdu': {'en': 'Urdu', 'ur': 'اردو'},
    'save': {'en': 'Save', 'ur': 'محفوظ کریں'},
    'back': {'en': 'Back', 'ur': 'واپس'},

    // Menu Items
    'register_animal': {'en': 'Register Animal', 'ur': 'جانور رجسٹر کریں'},
    'register_animal_subtitle': {
      'en': 'Add your pet to the system',
      'ur': 'اپنے پالتو جانور کو سسٹم میں شامل کریں',
    },
    'predict_disease': {'en': 'Predict Disease', 'ur': 'بیماری کی پیشن گوئی'},
    'predict_disease_subtitle': {
      'en': 'AI-powered diagnosis',
      'ur': 'اے آئی سے تشخیص',
    },
    'book_appointment': {'en': 'Book Appointment', 'ur': 'ملاقات بک کریں'},
    'book_appointment_subtitle': {
      'en': 'Schedule with a doctor',
      'ur': 'ڈاکٹر کے ساتھ وقت طے کریں',
    },
    'my_appointments': {'en': 'My Appointments', 'ur': 'میری ملاقاتیں'},
    'my_appointments_subtitle': {
      'en': 'View upcoming visits',
      'ur': 'آنے والی ملاقاتیں دیکھیں',
    },
    'view_history': {'en': 'View History', 'ur': 'سابقہ ریکارڈ'},
    'view_history_subtitle': {
      'en': 'Pet medical records',
      'ur': 'پالتو جانور کا طبی ریکارڈ',
    },

    // Notifications
    'notifications': {'en': 'Notifications', 'ur': 'اطلاعات'},
    'no_notifications': {
      'en': 'No notifications yet',
      'ur': 'ابھی کوئی اطلاع نہیں',
    },
    'activity_center': {'en': 'Activity Center', 'ur': 'سرگرمی مرکز'},
    'stay_updated': {
      'en': "Stay updated with your pet's health",
      'ur': 'اپنے پالتو جانور کی صحت سے باخبر رہیں',
    },

    // Profile
    'profile': {'en': 'Profile', 'ur': 'پروفائل'},
    'edit_profile': {'en': 'Edit Profile', 'ur': 'پروفائل میں ترمیم'},

    // Chat
    'chat': {'en': 'Chat', 'ur': 'چیٹ'},
    'chat_with_doctor': {'en': 'Chat with Doctor', 'ur': 'ڈاکٹر سے بات کریں'},

    // Common
    'logout': {'en': 'Logout', 'ur': 'لاگ آؤٹ'},
    'cancel': {'en': 'Cancel', 'ur': 'منسوخ کریں'},
    'confirm': {'en': 'Confirm', 'ur': 'تصدیق کریں'},
    'yes': {'en': 'Yes', 'ur': 'ہاں'},
    'no': {'en': 'No', 'ur': 'نہیں'},
    'ok': {'en': 'OK', 'ur': 'ٹھیک ہے'},
    'loading': {'en': 'Loading...', 'ur': 'لوڈ ہو رہا ہے...'},
    'error': {'en': 'Error', 'ur': 'خرابی'},
    'success': {'en': 'Success', 'ur': 'کامیاب'},

    // Register Animal Page
    'animal_name': {'en': 'Animal Name', 'ur': 'جانور کا نام'},
    'animal_type': {'en': 'Animal Type', 'ur': 'جانور کی قسم'},
    'breed': {'en': 'Breed', 'ur': 'نسل'},
    'age': {'en': 'Age', 'ur': 'عمر'},
    'weight': {'en': 'Weight', 'ur': 'وزن'},
    'gender': {'en': 'Gender', 'ur': 'جنس'},
    'male': {'en': 'Male', 'ur': 'نر'},
    'female': {'en': 'Female', 'ur': 'مادہ'},
    'submit': {'en': 'Submit', 'ur': 'جمع کرائیں'},
    'suspected_disease': {'en': 'Suspected Disease', 'ur': 'مشتبہ بیماری'},
    'select_images': {'en': 'Select Images', 'ur': 'تصاویر منتخب کریں'},
    'images_selected': {'en': 'Images Selected', 'ur': 'تصاویر منتخب ہیں'},
    'select_images_preview': {'en': 'Select Images (Preview Only)', 'ur': 'تصاویر منتخب کریں (صرف پیش نظارہ)'},
    'register_animal_button': {'en': 'Register Animal', 'ur': 'جانور رجسٹر کریں'},
    'animal_registered_success': {'en': 'Animal Registered Successfully! 🎉', 'ur': 'جانور کامیابی سے رجسٹر ہو گیا! 🎉'},
    'error_unable_to_register': {'en': 'Error: Unable to register animal', 'ur': 'خرابی: جانور رجسٹر نہیں ہو سکا'},
    'required': {'en': 'Required', 'ur': 'ضروری'},

    // Appointment
    'select_doctor': {'en': 'Select Doctor', 'ur': 'ڈاکٹر منتخب کریں'},
    'select_date': {'en': 'Select Date', 'ur': 'تاریخ منتخب کریں'},
    'select_time': {'en': 'Select Time', 'ur': 'وقت منتخب کریں'},
    'appointment_details': {
      'en': 'Appointment Details',
      'ur': 'ملاقات کی تفصیلات',
    },
    'pending': {'en': 'Pending', 'ur': 'زیر التواء'},
    'approved': {'en': 'Approved', 'ur': 'منظور شدہ'},
    'declined': {'en': 'Declined', 'ur': 'مسترد'},
    'doctor': {'en': 'Doctor', 'ur': 'ڈاکٹر'},
    'animal_details': {'en': 'Animal Details', 'ur': 'جانور کی تفصیلات'},
    'available_slots': {'en': 'Available Slots', 'ur': 'دستیاب اوقات'},
    'problem_description': {'en': 'Problem Description', 'ur': 'مسئلہ کی تفصیل'},
    'briefly_describe_issue': {'en': 'Briefly describe the issue', 'ur': 'مسئلہ کی مختصر تفصیل بیان کریں'},
    'book_appointment_now': {'en': 'Book Appointment Now', 'ur': 'ابھی ملاقات بک کریں'},
    'pending_approval': {'en': 'Pending Approval', 'ur': 'منظوری کے منتظر'},
    'appointment_declined': {'en': 'Appointment Declined by Doctor', 'ur': 'ڈاکٹر نے ملاقات مسترد کر دی'},
    'request_sent_success': {'en': 'Your request has been sent to the doctor', 'ur': 'آپ کی درخواست ڈاکٹر کو بھیج دی گئی ہے'},
    'please_select_animal': {'en': 'Please select an animal', 'ur': 'براہ کرم جانور منتخب کریں'},
    'please_select_slot_problem': {'en': 'Please select slot & write problem', 'ur': 'براہ کرم وقت منتخب کریں اور مسئلہ لکھیں'},
    'no_animal_registered': {'en': 'No animal registered. Please register an animal first.', 'ur': 'کوئی جانور رجسٹرڈ نہیں۔ پہلے جانور رجسٹر کریں۔'},
    'register_animal_btn': {'en': 'Register Animal', 'ur': 'جانور رجسٹر کریں'},
    'select_animal': {'en': 'Select Animal', 'ur': 'جانور منتخب کریں'},
    'unknown': {'en': 'Unknown', 'ur': 'نامعلوم'},
    'veterinarian': {'en': 'Veterinarian', 'ur': 'جانوروں کے ڈاکٹر'},

    // Disease Prediction
    'symptoms': {'en': 'Symptoms', 'ur': 'علامات'},
    'analyze': {'en': 'Analyze', 'ur': 'تجزیہ کریں'},
    'results': {'en': 'Results', 'ur': 'نتائج'},
    'disease_prediction': {'en': 'Disease Prediction', 'ur': 'بیماری کی پیشن گوئی'},
    'select_your_animal': {'en': 'Select Your Animal', 'ur': 'اپنا جانور منتخب کریں'},
    'enter_symptoms_details': {'en': 'Enter Symptoms & Details', 'ur': 'علامات اور تفصیلات درج کریں'},
    'describe_symptoms': {'en': 'Describe the symptoms in detail...', 'ur': 'علامات کی تفصیل سے وضاحت کریں...'},
    'select_images_text': {'en': 'Select images:', 'ur': 'تصاویر منتخب کریں:'},
    'deselect_all': {'en': 'Deselect All', 'ur': 'سب کو منتخب نہ کریں'},
    'select_all': {'en': 'Select All', 'ur': 'سب منتخب کریں'},
    'of': {'en': 'of', 'ur': 'میں سے'},
    'selected': {'en': 'selected', 'ur': 'منتخب'},
    'loading_images': {'en': 'Loading images...', 'ur': 'تصاویر لوڈ ہو رہی ہیں...'},
    'images_loaded': {'en': 'images loaded', 'ur': 'تصاویر لوڈ ہو گئیں'},
    'no_registered_images': {'en': 'No registered images for this animal.', 'ur': 'اس جانور کی کوئی رجسٹرڈ تصویر نہیں۔'},
    'predict_disease_btn': {'en': 'Predict Disease', 'ur': 'بیماری کی پیشن گوئی کریں'},
    'please_select_animal_error': {'en': 'Please select an animal', 'ur': 'براہ کرم جانور منتخب کریں'},
    'please_enter_symptoms': {'en': 'Please enter symptoms', 'ur': 'براہ کرم علامات درج کریں'},
    'please_select_one_image': {'en': 'Please select at least one image of the animal', 'ur': 'براہ کرم جانور کی کم از کم ایک تصویر منتخب کریں'},
    'image_file_not_found': {'en': 'Image file not found. Please select again.', 'ur': 'تصویر کی فائل نہیں ملی۔ براہ کرم دوبارہ منتخب کریں۔'},
    'prediction_failed': {'en': 'Prediction failed. Please check your connection and try again.', 'ur': 'پیشن گوئی ناکام۔ اپنا کنکشن چیک کریں اور دوبارہ کوشش کریں۔'},
    'prediction_result': {'en': 'Prediction Result', 'ur': 'پیشن گوئی کا نتیجہ'},
    'animal': {'en': 'Animal', 'ur': 'جانور'},
    'images_analyzed': {'en': 'Images analyzed', 'ur': 'تصاویر کا تجزیہ'},
    'prediction': {'en': 'Prediction', 'ur': 'پیشن گوئی'},
    'confidence': {'en': 'Confidence', 'ur': 'اعتماد'},
    'probabilities': {'en': 'Probabilities', 'ur': 'امکانات'},
    'close': {'en': 'Close', 'ur': 'بند کریں'},
    'no_animals_registered': {'en': 'No animals registered yet', 'ur': 'ابھی تک کوئی جانور رجسٹرڈ نہیں'},
    'tap_to_register': {'en': 'Tap the button above to register your first animal', 'ur': 'اپنا پہلا جانور رجسٹر کرنے کے لیے اوپر والے بٹن پر ٹیپ کریں'},
  };

  // Helper method to get translation
  static String get(String key, String languageCode) {
    final translation = translations[key];
    if (translation == null) return key;
    return translation[languageCode] ?? translation['en'] ?? key;
  }
}
