// translation_provider.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AppState {
  static final ValueNotifier<bool> darkModeNotifier = ValueNotifier<bool>(false);
  static final ValueNotifier<int> languageIndexNotifier = ValueNotifier<int>(0);

  static bool get isDark => darkModeNotifier.value;
  static int get langIndex => languageIndexNotifier.value;

  static void toggleDarkMode(bool val) {
    darkModeNotifier.value = val;
  }

  static void setLanguage(int index) {
    languageIndexNotifier.value = index;
  }

  // List of all 22 official languages of India + English
  static final List<String> languages = [
    'English',
    'Assamese (অসমীয়া)',
    'Bengali (বাংলা)',
    'Bodo (बर\')',
    'Dogri (डोगरी)',
    'Gujarati (ગુજરાતી)',
    'Hindi (हिन्दी)',
    'Kannada (ಕನ್ನಡ)',
    'Kashmiri (کٲشुर)',
    'Konkani (कोंकणी)',
    'Maithili (मैथिली)',
    'Malayalam (മലയാളം)',
    'Manipuri (মৈতৈলোন)',
    'Marathi (मराठी)',
    'Nepali (नेपाली)',
    'Odia (ଓଡ଼ିଆ)',
    'Punjabi (ਪੰਜਾਬੀ)',
    'Sanskrit (संस्कृतम्)',
    'Santali (संताली)',
    'Sindhi (सिन्धी)',
    'Tamil (தமிழ்)',
    'Telugu (తెలుగు)',
    'Urdu (اردو)'
  ];

  // ISO language codes for Google Translate corresponding to the languages list above
  static final List<String> languageCodes = [
    'en',  // English
    'as',  // Assamese
    'bn',  // Bengali
    'brx', // Bodo
    'doi', // Dogri
    'gu',  // Gujarati
    'hi',  // Hindi
    'kn',  // Kannada
    'ks',  // Kashmiri
    'gom', // Konkani
    'mai', // Maithili
    'ml',  // Malayalam
    'mni', // Manipuri
    'mr',  // Marathi
    'ne',  // Nepali
    'or',  // Odia
    'pa',  // Punjabi
    'sa',  // Sanskrit
    'sat', // Santali
    'sd',  // Sindhi
    'ta',  // Tamil
    'te',  // Telugu
    'ur',  // Urdu
  ];

  static List<String> _te(String en, String te) {
    final list = List<String>.generate(23, (i) => en);
    list[21] = te;
    return list;
  }

  // Core UI Strings translated for 22 languages
  static final Map<String, List<String>> _translations = {
    'Weather Forecast': _te('Weather Forecast', 'వాతావరణ సూచన'),
    'Kurnool, Andhra Pradesh': _te('Kurnool, Andhra Pradesh', 'కర్నూలు, ఆంధ్రప్రదేశ్'),
    'Partly Cloudy': _te('Partly Cloudy', 'పాక్షికంగా మేఘావృతం'),
    'Feels like 31°C  ·  H: 34°  L: 20°': _te('Feels like 31°C  ·  H: 34°  L: 20°', '31°C లాగా అనిపిస్తుంది  ·  H: 34°  L: 20°'),
    'Humidity': _te('Humidity', 'తేమ'),
    'Wind': _te('Wind', 'గాలి'),
    'Pressure': _te('Pressure', 'పీడనం'),
    'UV Index': _te('UV Index', 'UV సూచిక'),
    'Home': _te('Home', 'హోమ్'),
    'Crop Advisory': _te('Crop Advisory', 'పంట సలహా'),
    'Weather': _te('Weather', 'వాతావరణం'),
    'Pest Alert': _te('Pest Alert', 'కీటక హెచ్చరిక'),
    'Market Prices': _te('Market Prices', 'మార్కెట్ ధరలు'),
    'Farming Tips': _te('Farming Tips', 'వ్యవసాయ చిట్కాలు'),
    'Profile': _te('Profile', 'ప్రొఫైల్'),
    "Today's Forecast": _te("Today's Forecast", 'ఈరోజు సూచన'),
    '6 AM': _te('6 AM', 'ఉదయం 6'),
    '9 AM': _te('9 AM', 'ఉదయం 9'),
    '12 PM': _te('12 PM', 'మధ్యాహ్నం 12'),
    '3 PM': _te('3 PM', 'మధ్యాహ్నం 3'),
    '6 PM': _te('6 PM', 'సాయంత్రం 6'),
    '9 PM': _te('9 PM', 'రాత్రి 9'),
    'Sunrise / Sunset': _te('Sunrise / Sunset', 'సూర్యోదయం / సూర్యాస్తమయం'),
    '6:04 AM / 6:48 PM': _te('6:04 AM / 6:48 PM', 'ఉదయం 6:04 / సాయంత్రం 6:48'),
    'Rain Probability': _te('Rain Probability', 'వర్ష సూచన'),
    '35% — 12mm': _te('35% — 12mm', '35% — 12 మిమీ'),
    '7-Day Forecast': _te('7-Day Forecast', '7 రోజుల వాతావరణం'),
    'Farming Weather Alerts': _te('Farming Weather Alerts', 'వ్యవసాయ వాతావరణ హెచ్చరికలు'),
    'Thu': _te('Thu', 'గురు'),
    'Fri': _te('Fri', 'శుక్ర'),
    'Sat': _te('Sat', 'శని'),
    'Sun': _te('Sun', 'ఆది'),
    'Mon': _te('Mon', 'సోమ'),
    'Tue': _te('Tue', 'మంగళ'),
    'Wed': _te('Wed', 'बुध'),
    'Partly cloudy': _te('Partly cloudy', 'పాక్షికంగా మేఘావృతం'),
    'Heavy rain likely': _te('Heavy rain likely', 'భారీ వర్ష సూచన'),
    'Moderate rain': _te('Moderate rain', 'మితమైన వర్షం'),
    'Mostly cloudy': _te('Mostly cloudy', 'ఎక్కువగా మేఘావృతం'),
    'Clear & sunny': _te('Clear & sunny', 'స్పష్టంగా & ఎండగా'),
    'Clear sky': _te('Clear sky', 'నిర్మలమైన ఆకాశం'),
    'Rain Alert': _te('Rain Alert', 'వర్ష హెచ్చరిక'),
    'Heavy rainfall (40-60mm) expected Friday. Drain paddy fields to prevent waterlogging.': _te(
      'Heavy rainfall (40-60mm) expected Friday. Drain paddy fields to prevent waterlogging.',
      'శుక్రవారం భారీ వర్షపాతం (40-60 మిమీ) అంచనా. నీటి నిల్వను నివారించడానికి వరి పొలాలను డ్రైన్ చేయండి.',
    ),
    'Heat Advisory': _te('Heat Advisory', 'వేడి సలహా'),
    'Temperatures above 34°C on Mon-Wed. Irrigate crops in the early morning.': _te(
      'Temperatures above 34°C on Mon-Wed. Irrigate crops in the early morning.',
      'సోమ-బుధవారాల్లో ఉష్ణోగ్రతలు 34°C కంటే ఎక్కువ. తెల్లవారుజామున పంటలకు నీరు పెట్టండి.',
    ),
    'Wind Warning': _te('Wind Warning', 'గాలి హెచ్చరిక'),
    'Strong winds 25-35 km/h Thursday afternoon. Avoid spraying pesticides.': _te(
      'Strong winds 25-35 km/h Thursday afternoon. Avoid spraying pesticides.',
      'గురువారం మధ్యాహ్నం 25-35 కిమీ/గం బలమైన గాలులు. పురుగుమందుల పిచికారీని నివారించండి.',
    ),
    'sign_in': [
      'Sign In', 'ছাইন ইন', 'সাইন ইন', 'साइन इन', 'साइन इन', 'સાઇન ઇન', 'साइन इन', 'ಸೈನ್ ಇನ್', 'سائن اِن', 'साइन इन',
      'साइन इन', 'സൈൻ ഇൻ', 'সাইন ইন', 'साइन इन', 'साइन इन', 'ସାଇନ୍ ଇନ୍', 'ਸਾਈਨ ਇਨ', 'साइन इन', 'साइन इन', 'साइन इन',
      'உள்நுழைக', 'సన్ ইন', 'سائن ان'
    ],
    'create_account': [
      'Create Account', 'একাউন্ট খোলক', 'অ্যাকাউন্ট তৈরি করুন', 'একাউন্ট বাও', 'একাউন্ট বানাও', 'ખાતું બનાવો', 'खाता बनाएं', 'ಖಾತೆ ರಚಿಸಿ', 'اکاؤنٹ بناو', 'खातो तयार करा',
      'खाता बनाओ', 'അക്കൗണ്ട് ഉണ്ടാക്കുക', 'অ্যাকাউন্ট তৈরি করুন', 'खाते तयार करा', 'खाता बनाउनुहोस्', 'ଖାତା ତିଆରି କରନ୍ତୁ', 'ਖਾਤਾ ਬਣਾਓ', 'खाता कुरु', 'खाता वेनाव', 'खातो ठाहियो',
      'கணக்கை உருவாக்கு', 'ఖాతాను సృష్టించు', 'اکاؤنٹ بنائیں'
    ],
    'password': [
      'Password', 'পাছৱৰ্ড', 'পাসওয়ার্ড', 'पासवर्ड', 'पासवर्ड', 'પાસવર્ડ', 'पासवर्ड', 'ಪಾಸ್‌ವರ್ಡ್', 'پاس ورڈ', 'पासवर्ड',
      'पासवर्ड', 'പാസ്‌വേഡ്', 'পাসওয়ার্ড', 'पासवर्ड', 'पासवर्ड', 'ପାସୱାର୍ଡ', 'ਪਾਸਵਰਡ', 'कूटशब्द', 'पासवर्ड', 'पासवर्ड',
      'கடவுச்சொல்', 'పాస్ వర్డ్', 'پاس ورڈ'
    ],
    'welcome': [
      'Welcome back,', 'স্বাগতম,', 'স্বাগতম,', 'वरायबाय,', 'स्वागत ऐ,', 'સ્વાગત,', 'स्वागत है,', 'ಸ್ವಾಗತ,', 'خوش آمدید', 'स्वागत आसा,',
      'स्वागत अछि,', 'സ്വാഗതം,', 'তরাম্না ওকচরি,', 'स्वागत आहे,', 'स्वागत छ,', 'ସ୍ଵାଗତ,', 'ਜੀ ਆਇਆਂ ਨੂੰ,', 'स्वागतम्,', 'सगुन দরাম,', 'भली कार आया,',
      'வரவேற்கிறோம்,', 'స్వాగతం,', 'خوش آمدید،'
    ],
    'advisory': [
      'Advisory', 'পৰামৰ্শ', 'পরামর্শ', 'सलाह', 'सलाह', 'સલાহ', 'सलाह', 'ಸಲಹೆ', 'صلاح', 'सल्লো',
      'सलाह', 'ഉപദേശം', 'পাউতাক', 'সিল্লা', 'সিল্লাহ', 'ପରାମର୍ଶ', 'ਸਲਾਹ', 'परामर्श', 'सलाहा', 'सलाह',
      'ஆலோசனை', 'సలహా', 'مشورہ'
    ],
    'pest_alert': [
      'Pest Alert', 'কীট-পতংগ সৰ্তকতা', 'পোকামাকড় সতর্কতা', 'এনাइ संकेत', 'कीड़ा चेतावनी', 'જીવાત ચેતવણી', 'कीट चेतावनी', 'ಕೀಟ எಚ್ಚரிಕೆ', 'پیسٹ الرٹ', 'किडो शिस्त',
      'कीट चेतावनी', 'കീട മുന്നറിയിപ്പ്', 'পোকামাকড় চেকশিন', 'कीड चेतावणी', 'कीरा चेतावनी', 'ପୋକ ଚେତାବନୀ', 'ਕੀਟ ਚੇਤਾਵਨੀ', 'कीट सचेत', 'कीट एर्ट', 'कीट चेतावनी',
      'பூச்சி எச்சரிக்கை', 'కీటక హెచ్చరిక', 'کیڑوں کی وارਨنگ'
    ],
    'market': [
      'Market', 'বজাৰ', 'বাজার', 'হাট', 'बाजार', 'બજાર', 'बाजार', 'ಮಾರುಕಟ್ಟೆ', 'बाजार', 'बाजार',
      'बाजार', 'മാർക്കറ്റ്', 'কৈথেল', 'बाजार', 'बजार', 'ବଜାର', 'ਮਾਰକੀਟ', 'आपण', 'হাট', 'बाजार',
      'சந்தை', 'మార్కెట్', 'مارکیٹ'
    ],
    'tips_news': [
      'Tips & News', 'পৰামৰ্শ আৰু বাতৰি', 'পরামর্শ ও খবর', 'सलाह आरो खौरां', 'सलाह ते खबरें', 'નવીન માહિતી', 'टिप्स और समाचार', 'සුದ್ದি మరియు ಸಲಹೆಗಳು', 'टिप्स व खबर', 'टिप्स आणि खबर',
      'सलाह आ समाचार', 'ടിപ്പുകളും വാർത്തകളും', 'পাউতাক অমসুং পাউ', 'सल्ला व बातम्या', 'सुझाव र समाचार', 'ଟିପ୍ସ ଏବଂ ସମାଚାର', 'ਸੁਝਾਅ ਅਤੇ ਖ਼ਬਰਾਂ', 'वार्ताः', 'सल्लाह आरो खवर', 'टिप्स ऐं खबरूं',
      'செய்திகள் & குறிப்புகள்', 'చిట్కాలు & వార్తలు', 'ٹپس اور خبریں'
    ],
    'profile': [
      'Profile', 'প্ৰফাইল', 'প্রোফাইল', 'प्रोफाइल', 'प्रोफाइल', 'પ્રોફાઇલ', 'प्रोफाइल', 'ಪ್ರೊಫೈಲ್', 'پروفائل', 'प्रोफाइल',
      'प्रोफाइल', 'പ്രൊഫൈൽ', 'প্রোফাইল', 'प्रोफाइल', 'प्रोफाइल', 'ପ୍ରୋଫାଇଲ୍', 'ପ୍ରଫਾਈਲ', 'व्यक्तिचित्रम्', 'प्रोफाइल', 'प्रोफाइल',
      'விவரக்குறிப்பு', 'ప్రొఫైల్', 'پروفائل'
    ],
    'dark_mode': [
      'Dark Mode', 'ডাৰ্ক ম’ড', 'ডার্ক মোড', 'डार्क मोड', 'डार्क मोड', 'ડાર્ક મોડ', 'डार्क मोड', 'ಡಾರ್ಕ್ ಮೋಡ್', 'ڈارک موڈ', 'डार्क मोड',
      'डार्क मोड', 'ഡാർക്ക് മോഡ്', 'অমোম্বা মোড', 'डार्क मोड', 'डार्क मोड', 'ଡାର୍କ ମୋଡ୍', 'ਡਾਰਕ ਮੋਡ', 'तमिस्रा', 'डार्क मोड', 'डार्क मोड',
      'இருண்ட பயன்முறை', 'డార్క్ మోడ్', 'ڈارک موڈ'
    ],
    'language': [
      'Language', 'ভাষা', 'ভাষা', 'राव', 'बोली', 'ભાષા', 'भाषा', 'ભાಷೆ', 'زبان', 'भास',
      'भाषा', 'ભાಷা', 'লোন', 'भाषा', 'भाषा', 'ଭାଷา', 'ਭਾਸ਼ਾ', 'भाषा', 'भासा', 'बोली',
      'மொழி', 'భాష', 'زبان'
    ],
    'logout': [
      'Log Out', 'লগ আউট', 'লগ আউট', 'लॉग आउट', 'लॉग आउट', 'લૉગ આউট', 'लॉग आउट', 'ಲಾಗ್ ಔಟ್', 'لاگ آوٹ', 'लॉग आउट',
      'लॉग आउट', 'ലോഗ് ഔട്ട്', 'লগ আউট', 'লগ আউট', 'लॉग आउट', 'ଲଗ୍ ଆଉଟ୍', 'ଲੌਗ ਆਉਟ', 'निर्गमनम्', 'लॉग आउट', 'लॉग आउट',
      'வெளியேறு', 'లాగ్ అవుట్', 'لاگ آؤٹ'
    ],
    'personal_info': [
      'Personal Information', 'ব্যক্তিগত তথ্য', 'ব্যক্তিগত তথ্য', 'गावनि खौरां', 'जाती मालूमात', 'વ્યક્તિগত માહિતી', 'व्यक्तिগত जानकारी', 'வೈಯক্তিক ಮಾಹಿತಿ', 'जाती माहिती', 'खाजगी माहिती',
      'व्यक्तिগত जानकारी', 'വ്യക്തിഗത വിവരങ്ങൾ', 'অপুনবা পাউ', 'वैयक्तिक माहिती', 'व्यक्तिগত विवरण', 'ବ୍ୟକ୍ତିଗত ସୂଚନା', 'ਨਿੱਜੀ ਜਾਣਕਾਰੀ', 'वैयक्तिक वृत्तम्', 'निजो खवर', 'जाती माहिती',
      'தনিப்பட்ட தகவல்', 'వ్యవసాయ సమాచారం', 'ذاتی معلومات'
    ],
    'farm_details': [
      'Farm Details', 'খেতিৰ সবিশেষ', 'খামারের বিবরণ', 'आबाद खौरां', 'खेती दे बारे', 'ખેતી વિગતો', 'कृषि विवरण', 'ಕೃಷಿ ವಿವರಗಳು', 'शेत माहिती', 'शेत माहिती',
      'कृषि विवरण', 'കൃഷി വിവരങ്ങൾ', 'লৌমী সবিশেষ', 'शेतीची माहिती', 'कृषि विवरण', 'କୃଷି ବିବରଣୀ', 'ਖੇਤੀਬਾੜੀ ਵੇਰਵੇ', 'कृषिक्षेत्रम्', 'खेत खवर', 'खेतीअ बाबत',
      'பண்ணை விவரங்கள்', 'వ్యవసాయ వివరాలు', 'فارم کی تفصیلات'
    ],
    'weather': [
      'Weather Forecast', 'বতৰৰ আগজাননী', 'আবহাওয়া পূর্বাভাস', 'বারहा খৌরাং', 'मौसम दी भविष्यवाणी', 'હવામાન આગાહી', 'मौसम पूर्वानुमान', 'ಹವಾಮಾನ ಮುನ್ಸೂಚನೆ', 'मौसम हाल', 'हवामान अंदाज',
      'मौसम पूर्वानुमान', 'കാലാവസ്ഥ പ്രവചനം', 'নোংফো সবিশেষ', 'हवामान अंदाज', 'मौसम पूर्वानुमान', 'ପାଣିପାଗ ପୂର୍ବାନୁମାନ', 'ਮੌਸਮ ਦੀ ਭਵਿੱਬਾਣੀ', 'ऋतुमानम्', 'मौसम खवर', 'मौसम बाबत',
      'வானிலை முன்னறிவிப்பு', 'వాతావరణ సూచన', 'موسم کی پیشگوئی'
    ],
    'ask_ai': [
      'Ask AI', 'এআইক সোধক', 'এআইকে জিজ্ঞাসা করুন', 'एआई सोंङ', 'एआई कोल पुच्छो', 'AI ને પૂછો', 'AI से पूछें', 'AI ಅನ್ನು ಕೇಳಿ', 'AI सोंद', 'AI विचात',
      'AI सँ পুছূ', 'AI-യോട് ചോദിക്കുക', 'AI হংউ', 'AI ला विचारा', 'AI लाई सोध्नुहोस्', 'AI କୁ ପଚାରନ୍ତু', 'AI ਨੂੰ ਪੁੱਛੋ', 'AI पृच्छ', 'AI कुली', 'AI खां पुछो',
      'AI வினவவும்', 'AI ని అడగండి', 'AI سے پوچھیں'
    ]
  };

  static final Set<String> _fetchingKeys = {};

  static String translate(String key) {
    final cleanKey = key.trim();
    if (cleanKey.isEmpty) return key;

    final idx = langIndex;
    if (idx == 0) return key; // English is the default key itself

    // 1. Check if the key exists in our pre-defined translations
    if (_translations.containsKey(cleanKey)) {
      final list = _translations[cleanKey]!;
      if (idx < list.length) {
        return list[idx];
      }
    }

    // 2. Check if we also have the case-insensitive or exact text matching in lowercase
    final lowerKey = cleanKey.toLowerCase();
    for (var entry in _translations.entries) {
      if (entry.key.toLowerCase() == lowerKey) {
        final list = entry.value;
        if (idx < list.length) {
          return list[idx];
        }
      }
    }

    // 3. Fallback: Trigger async translation in the background if not already fetching
    _triggerAsyncTranslation(cleanKey, idx);

    return key; // return original key as fallback while translating
  }

  static void _triggerAsyncTranslation(String key, int index) async {
    final fetchId = '${key}_$index';
    if (_fetchingKeys.contains(fetchId)) return;
    _fetchingKeys.add(fetchId);

    try {
      final langCode = languageCodes[index];
      // Skip translation if the code is invalid or English
      if (langCode == 'en') return;

      final url = Uri.parse(
          'https://translate.googleapis.com/translate_a/single?client=gtx&sl=auto&tl=$langCode&dt=t&q=${Uri.encodeComponent(key)}'
      );
      final res = await http.get(url).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        if (decoded != null && decoded[0] != null) {
          final StringBuffer buffer = StringBuffer();
          for (var part in decoded[0]) {
            if (part != null && part[0] != null) {
              buffer.write(part[0]);
            }
          }
          final translated = buffer.toString();
          if (translated.isNotEmpty) {
            // Initialize key list if not present
            if (!_translations.containsKey(key)) {
              _translations[key] = List.generate(languages.length, (i) => key);
            }
            _translations[key]![index] = translated;

            // Trigger UI update by assigning the same value to trigger listeners
            languageIndexNotifier.value = languageIndexNotifier.value;
          }
        }
      }
    } catch (e) {
      debugPrint('Dynamic translation error for "$key" to index $index: $e');
    } finally {
      _fetchingKeys.remove(fetchId);
    }
  }
}

extension TranslationExtension on String {
  String get tr => AppState.translate(this);
}
