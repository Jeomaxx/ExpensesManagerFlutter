import 'dart:io';
import 'dart:typed_data';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:image_picker/image_picker.dart';
import '../models/transaction.dart';

class ReceiptScanningService {
  static final ReceiptScanningService _instance = ReceiptScanningService._internal();
  static ReceiptScanningService get instance => _instance;
  ReceiptScanningService._internal();

  final ImagePicker _imagePicker = ImagePicker();
  final stt.SpeechToText _speechToText = stt.SpeechToText();
  late TextRecognizer _textRecognizer;
  bool _isInitialized = false;
  bool _speechInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      _textRecognizer = TextRecognizer();
      _isInitialized = true;
      print('Receipt scanning service initialized successfully');
      
      // Initialize speech recognition
      _speechInitialized = await _speechToText.initialize(
        onStatus: (status) => print('Speech recognition status: $status'),
        onError: (error) => print('Speech recognition error: $error'),
      );
      
      if (_speechInitialized) {
        print('Speech recognition initialized successfully');
      }
    } catch (e) {
      print('Failed to initialize receipt scanning service: $e');
    }
  }

  Future<void> dispose() async {
    if (_isInitialized) {
      await _textRecognizer.close();
      _isInitialized = false;
    }
  }

  // RECEIPT SCANNING FROM CAMERA/GALLERY
  
  Future<String?> scanReceiptFromCamera() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      
      if (image != null) {
        return await _extractTextFromImage(image.path);
      }
      return null;
    } catch (e) {
      print('Error capturing image from camera: $e');
      return null;
    }
  }

  Future<String?> scanReceiptFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      
      if (image != null) {
        return await _extractTextFromImage(image.path);
      }
      return null;
    } catch (e) {
      print('Error picking image from gallery: $e');
      return null;
    }
  }

  Future<String?> _extractTextFromImage(String imagePath) async {
    if (!_isInitialized) {
      await initialize();
    }
    
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);
      
      if (recognizedText.text.isEmpty) {
        return null;
      }
      
      return recognizedText.text;
    } catch (e) {
      print('Error extracting text from image: $e');
      return null;
    }
  }

  // RECEIPT DATA PARSING
  
  ReceiptData? parseReceiptText(String text) {
    try {
      final lines = text.split('\n').map((line) => line.trim()).where((line) => line.isNotEmpty).toList();
      
      if (lines.isEmpty) return null;
      
      // Extract merchant name (usually first or second line)
      String? merchantName = _extractMerchantName(lines);
      
      // Extract total amount
      double? totalAmount = _extractTotalAmount(lines);
      
      // Extract date
      DateTime? date = _extractDate(lines);
      
      // Extract items
      List<ReceiptItem> items = _extractItems(lines);
      
      // Extract tax
      double? tax = _extractTax(lines);
      
      if (totalAmount == null) {
        return null;
      }
      
      return ReceiptData(
        merchantName: merchantName ?? 'Unknown',
        totalAmount: totalAmount,
        date: date ?? DateTime.now(),
        items: items,
        tax: tax,
        rawText: text,
      );
    } catch (e) {
      print('Error parsing receipt text: $e');
      return null;
    }
  }

  String? _extractMerchantName(List<String> lines) {
    // Look for merchant name in first few lines
    for (int i = 0; i < lines.length && i < 5; i++) {
      final line = lines[i];
      // Skip lines that look like addresses or phone numbers
      if (!line.contains(RegExp(r'\d{3}-\d{3}-\d{4}|\d{10}')) && 
          !line.contains(RegExp(r'\d+\s+\w+\s+(st|ave|rd|blvd|street|avenue|road|boulevard)', caseSensitive: false)) &&
          line.length > 3 && line.length < 50) {
        return line;
      }
    }
    return null;
  }

  double? _extractTotalAmount(List<String> lines) {
    final totalPatterns = [
      RegExp(r'total[\s:]*\$?(\d+\.?\d*)', caseSensitive: false),
      RegExp(r'amount[\s:]*\$?(\d+\.?\d*)', caseSensitive: false),
      RegExp(r'\$(\d+\.?\d*)(?:\s+total)?', caseSensitive: false),
      RegExp(r'(\d+\.?\d*)\s*(?:total|amount)', caseSensitive: false),
    ];
    
    for (final line in lines.reversed) {
      for (final pattern in totalPatterns) {
        final match = pattern.firstMatch(line);
        if (match != null) {
          final amountStr = match.group(1);
          if (amountStr != null) {
            final amount = double.tryParse(amountStr);
            if (amount != null && amount > 0) {
              return amount;
            }
          }
        }
      }
    }
    
    // Fallback: look for any dollar amount in the last few lines
    for (int i = lines.length - 1; i >= 0 && i >= lines.length - 5; i--) {
      final match = RegExp(r'\$?(\d+\.\d{2})').firstMatch(lines[i]);
      if (match != null) {
        final amount = double.tryParse(match.group(1)!);
        if (amount != null && amount > 0) {
          return amount;
        }
      }
    }
    
    return null;
  }

  DateTime? _extractDate(List<String> lines) {
    final datePatterns = [
      RegExp(r'(\d{1,2})[\/\-](\d{1,2})[\/\-](\d{2,4})'),
      RegExp(r'(\d{4})[\/\-](\d{1,2})[\/\-](\d{1,2})'),
      RegExp(r'(jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)\s+(\d{1,2}),?\s+(\d{4})', caseSensitive: false),
    ];
    
    for (final line in lines) {
      for (final pattern in datePatterns) {
        final match = pattern.firstMatch(line);
        if (match != null) {
          try {
            if (pattern == datePatterns[0]) {
              // MM/DD/YYYY or MM-DD-YYYY
              final month = int.parse(match.group(1)!);
              final day = int.parse(match.group(2)!);
              var year = int.parse(match.group(3)!);
              if (year < 100) year += 2000;
              return DateTime(year, month, day);
            } else if (pattern == datePatterns[1]) {
              // YYYY/MM/DD or YYYY-MM-DD
              final year = int.parse(match.group(1)!);
              final month = int.parse(match.group(2)!);
              final day = int.parse(match.group(3)!);
              return DateTime(year, month, day);
            } else if (pattern == datePatterns[2]) {
              // Month DD, YYYY
              final monthStr = match.group(1)!.toLowerCase();
              final day = int.parse(match.group(2)!);
              final year = int.parse(match.group(3)!);
              final months = ['jan', 'feb', 'mar', 'apr', 'may', 'jun',
                             'jul', 'aug', 'sep', 'oct', 'nov', 'dec'];
              final month = months.indexOf(monthStr) + 1;
              if (month > 0) {
                return DateTime(year, month, day);
              }
            }
          } catch (e) {
            continue;
          }
        }
      }
    }
    
    return null;
  }

  List<ReceiptItem> _extractItems(List<String> lines) {
    final items = <ReceiptItem>[];
    
    for (final line in lines) {
      // Look for lines with item name and price pattern
      final itemPattern = RegExp(r'^(.+?)\s+\$?(\d+\.?\d*)$');
      final match = itemPattern.firstMatch(line.trim());
      
      if (match != null) {
        final name = match.group(1)?.trim();
        final priceStr = match.group(2);
        
        if (name != null && priceStr != null && name.length > 2) {
          final price = double.tryParse(priceStr);
          if (price != null && price > 0 && price < 1000) {
            // Skip lines that look like totals or taxes
            if (!name.toLowerCase().contains(RegExp(r'total|tax|subtotal|amount|change'))) {
              items.add(ReceiptItem(name: name, price: price));
            }
          }
        }
      }
    }
    
    return items;
  }

  double? _extractTax(List<String> lines) {
    final taxPatterns = [
      RegExp(r'tax[\s:]*\$?(\d+\.?\d*)', caseSensitive: false),
      RegExp(r'hst[\s:]*\$?(\d+\.?\d*)', caseSensitive: false),
      RegExp(r'gst[\s:]*\$?(\d+\.?\d*)', caseSensitive: false),
    ];
    
    for (final line in lines) {
      for (final pattern in taxPatterns) {
        final match = pattern.firstMatch(line);
        if (match != null) {
          final taxStr = match.group(1);
          if (taxStr != null) {
            return double.tryParse(taxStr);
          }
        }
      }
    }
    
    return null;
  }

  // VOICE INPUT FOR TRANSACTION DETAILS
  
  Future<String?> startVoiceInput({String locale = 'en_US'}) async {
    if (!_speechInitialized) {
      await initialize();
    }
    
    if (!_speechInitialized) {
      return null;
    }
    
    try {
      String recognizedText = '';
      
      await _speechToText.listen(
        onResult: (result) {
          recognizedText = result.recognizedWords;
        },
        localeId: locale,
        listenMode: stt.ListenMode.confirmation,
        partialResults: false,
      );
      
      // Wait for listening to complete
      while (_speechToText.isListening) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      
      return recognizedText.isNotEmpty ? recognizedText : null;
    } catch (e) {
      print('Error during voice input: $e');
      return null;
    }
  }

  void stopVoiceInput() {
    _speechToText.stop();
  }

  bool get isListening => _speechToText.isListening;
  bool get isAvailable => _speechInitialized;

  // TRANSACTION CREATION FROM RECEIPT
  
  Transaction createTransactionFromReceipt(
    ReceiptData receiptData,
    String userId,
    String accountId,
    String categoryId,
  ) {
    return Transaction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      accountId: accountId,
      categoryId: categoryId,
      amount: receiptData.totalAmount,
      description: 'Purchase at ${receiptData.merchantName}',
      notes: 'Auto-created from receipt scan\n${receiptData.items.isNotEmpty ? 'Items: ${receiptData.items.map((i) => '${i.name} (\$${i.price})').join(', ')}' : ''}',
      date: receiptData.date,
      type: TransactionType.expense,
      createdAt: DateTime.now(),
      lastModified: DateTime.now(),
      isDeleted: false,
    );
  }

  // SMART CATEGORIZATION
  
  String suggestCategory(ReceiptData receiptData) {
    final merchantName = receiptData.merchantName.toLowerCase();
    final items = receiptData.items.map((i) => i.name.toLowerCase()).join(' ');
    final allText = '$merchantName $items'.toLowerCase();
    
    // Food & Restaurants
    if (allText.contains(RegExp(r'restaurant|coffee|pizza|burger|food|cafe|bistro|grill|diner|taco|sushi|bar|pub'))) {
      return 'food_dining';
    }
    
    // Groceries
    if (allText.contains(RegExp(r'market|grocery|supermarket|walmart|target|costco|fresh|produce|milk|bread|meat'))) {
      return 'groceries';
    }
    
    // Gas & Transportation
    if (allText.contains(RegExp(r'gas|fuel|shell|bp|exxon|chevron|texaco|station|uber|lyft|taxi'))) {
      return 'transportation';
    }
    
    // Shopping
    if (allText.contains(RegExp(r'store|shop|mall|amazon|ebay|clothing|apparel|shoes|electronics'))) {
      return 'shopping';
    }
    
    // Health & Medical
    if (allText.contains(RegExp(r'pharmacy|medical|doctor|clinic|hospital|dental|cvs|walgreens'))) {
      return 'healthcare';
    }
    
    // Entertainment
    if (allText.contains(RegExp(r'theater|cinema|movie|game|sport|entertainment|netflix|spotify'))) {
      return 'entertainment';
    }
    
    // Default category
    return 'other';
  }
}

class ReceiptData {
  final String merchantName;
  final double totalAmount;
  final DateTime date;
  final List<ReceiptItem> items;
  final double? tax;
  final String rawText;

  ReceiptData({
    required this.merchantName,
    required this.totalAmount,
    required this.date,
    required this.items,
    this.tax,
    required this.rawText,
  });
}

class ReceiptItem {
  final String name;
  final double price;

  ReceiptItem({
    required this.name,
    required this.price,
  });
}