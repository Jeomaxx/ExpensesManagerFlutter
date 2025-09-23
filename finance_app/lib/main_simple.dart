import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'src/core/models/category.dart';
import 'src/core/models/transaction.dart' as app_transaction;
import 'src/core/repositories/category_repository.dart';
import 'src/core/repositories/transaction_repository.dart';
import 'src/core/services/default_data_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  print('Starting Finance App in simple mode for Replit compatibility');
  
  runApp(
    const ProviderScope(
      child: SimpleFinanceApp(),
    ),
  );
}

class SimpleFinanceApp extends ConsumerWidget {
  const SimpleFinanceApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'تطبيق المالية',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        fontFamily: 'Cairo',
      ),
      home: const HomePage(),
      debugShowCheckedModeBanner: false,
      // Arabic RTL support
      locale: const Locale('ar', 'SA'),
      supportedLocales: const [
        Locale('ar', 'SA'),
        Locale('en', 'US'),
      ],
      // Set text direction for Arabic
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child!,
        );
      },
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تطبيق إدارة المالية', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue.shade600,
        centerTitle: true,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.account_balance_wallet,
              size: 80,
              color: Colors.blue,
            ),
            SizedBox(height: 20),
            Text(
              'مرحباً بك في تطبيق المالية',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
              textDirection: TextDirection.rtl,
            ),
            SizedBox(height: 10),
            Text(
              'حلك الشخصي لإدارة الأموال بذكاء',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
            ),
            SizedBox(height: 40),
            Card(
              margin: EdgeInsets.all(20),
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(
                      'تم إعداد التطبيق بنجاح!',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                      textDirection: TextDirection.rtl,
                    ),
                    SizedBox(height: 10),
                    Text(
                      'جميع الميزات متاحة: إدارة المعاملات، الفئات العربية الشاملة، تتبع المصروفات والدخل، التقارير المالية، والمزيد.',
                      textAlign: TextAlign.center,
                      textDirection: TextDirection.rtl,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddTransactionPage()),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('إضافة معاملة'),
        backgroundColor: Colors.green,
      ),
    );
  }
}

// Use the app's transaction models and repositories

// Add Transaction Page
class AddTransactionPage extends StatefulWidget {
  const AddTransactionPage({super.key});

  @override
  State<AddTransactionPage> createState() => _AddTransactionPageState();
}

class _AddTransactionPageState extends State<AddTransactionPage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  
  app_transaction.TransactionType _selectedType = app_transaction.TransactionType.expense;
  String? _selectedCategoryId;
  DateTime _selectedDate = DateTime.now();
  
  List<Category> _categories = [];
  bool _isLoading = true;
  String _defaultUserId = 'demo_user';

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      // Initialize default data if not exists
      await DefaultDataService.instance.createDefaultCategories(_defaultUserId);
      await DefaultDataService.instance.createDefaultAccount(_defaultUserId);
      
      // Load categories from repository
      final categoryRepository = CategoryRepository.instance;
      final categories = await categoryRepository.getCategoriesByUserId(_defaultUserId);
      
      setState(() {
        _categories = categories;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading categories: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<Category> get _currentCategories {
    // Filter categories based on transaction type (for demo, showing all)
    return _categories;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إضافة معاملة جديدة', style: TextStyle(color: Colors.white)),
        backgroundColor: _selectedType == app_transaction.TransactionType.income ? Colors.green : Colors.red,
        centerTitle: true,
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Transaction Type Toggle
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedType = app_transaction.TransactionType.income;
                                _selectedCategoryId = null;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: _selectedType == app_transaction.TransactionType.income
                                    ? Colors.green
                                    : Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'الدخل',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: _selectedType == app_transaction.TransactionType.income
                                      ? Colors.white
                                      : Colors.black54,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedType = app_transaction.TransactionType.expense;
                                _selectedCategoryId = null;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: _selectedType == app_transaction.TransactionType.expense
                                    ? Colors.red
                                    : Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'المصروف',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: _selectedType == app_transaction.TransactionType.expense
                                      ? Colors.white
                                      : Colors.black54,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Amount Input
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'المبلغ',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _amountController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            hintText: 'أدخل المبلغ',
                            prefixIcon: Icon(Icons.attach_money),
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'يرجى إدخال المبلغ';
                            }
                            if (double.tryParse(value) == null) {
                              return 'يرجى إدخال رقم صحيح';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Category Selection
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedType == app_transaction.TransactionType.income ? 'فئة الدخل' : 'فئة المصروف',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        _isLoading 
                          ? const CircularProgressIndicator()
                          : DropdownButtonFormField<String>(
                              value: _selectedCategoryId,
                              decoration: const InputDecoration(
                                hintText: 'اختر الفئة',
                                border: OutlineInputBorder(),
                              ),
                              items: _currentCategories.map((category) {
                                return DropdownMenuItem<String>(
                                  value: category.id,
                                  child: Row(
                                    children: [
                                      Icon(
                                        _getIconFromName(category.iconName),
                                        color: category.color,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(child: Text(category.name)),
                                    ],
                                  ),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedCategoryId = value;
                                });
                              },
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'يرجى اختيار الفئة';
                                }
                                return null;
                              },
                            ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Date Selection
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'التاريخ',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: _selectedDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now(),
                            );
                            if (date != null) {
                              setState(() {
                                _selectedDate = date;
                              });
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today),
                                const SizedBox(width: 8),
                                Text(
                                  '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Notes Input
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'ملاحظات (اختيارية)',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _notesController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            hintText: 'أضف ملاحظة...',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Save Button
                ElevatedButton(
                  onPressed: _saveTransaction,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _selectedType == app_transaction.TransactionType.income 
                        ? Colors.green 
                        : Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'حفظ المعاملة',
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getIconFromName(String iconName) {
    switch (iconName) {
      case 'work': return Icons.work;
      case 'card_giftcard': return Icons.card_giftcard;
      case 'laptop': return Icons.laptop;
      case 'business': return Icons.business;
      case 'trending_up': return Icons.trending_up;
      case 'home': return Icons.home;
      case 'percent': return Icons.percent;
      case 'redeem': return Icons.redeem;
      case 'restaurant': return Icons.restaurant;
      case 'shopping_cart': return Icons.shopping_cart;
      case 'directions_car': return Icons.directions_car;
      case 'local_gas_station': return Icons.local_gas_station;
      case 'local_hospital': return Icons.local_hospital;
      case 'medical_services': return Icons.medical_services;
      case 'school': return Icons.school;
      case 'menu_book': return Icons.menu_book;
      case 'receipt': return Icons.receipt;
      case 'bolt': return Icons.bolt;
      case 'wifi': return Icons.wifi;
      case 'movie': return Icons.movie;
      case 'fitness_center': return Icons.fitness_center;
      case 'shopping_bag': return Icons.shopping_bag;
      case 'checkroom': return Icons.checkroom;
      case 'flight': return Icons.flight;
      case 'hotel': return Icons.hotel;
      case 'family_restroom': return Icons.family_restroom;
      case 'subscription': return Icons.subscriptions;
      case 'category': return Icons.category;
      default: return Icons.category;
    }
  }

  Future<void> _saveTransaction() async {
    if (_formKey.currentState!.validate()) {
      try {
        final amount = double.parse(_amountController.text);
        
        // Get default account
        final transactionRepository = TransactionRepository.instance;
        
        final transaction = app_transaction.Transaction(
          id: '${_defaultUserId}_txn_${DateTime.now().millisecondsSinceEpoch}',
          userId: _defaultUserId,
          accountId: '${_defaultUserId}_acc_cash', // Default account
          amount: amount,
          type: _selectedType,
          categoryId: _selectedCategoryId!,
          date: _selectedDate,
          notes: _notesController.text.isEmpty ? null : _notesController.text,
          tags: [_selectedType == app_transaction.TransactionType.income ? 'دخل' : 'مصروف'],
          createdAt: DateTime.now(),
          lastModified: DateTime.now(),
        );

        // Save to repository
        await transactionRepository.createTransaction(transaction);

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'تم حفظ المعاملة بنجاح! ${_selectedType == app_transaction.TransactionType.income ? "دخل" : "مصروف"} ${amount.toStringAsFixed(2)} ريال',
              textDirection: TextDirection.rtl,
            ),
            backgroundColor: _selectedType == app_transaction.TransactionType.income ? Colors.green : Colors.red,
          ),
        );

        // Return to home page
        Navigator.pop(context);
      } catch (e) {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'حدث خطأ أثناء حفظ المعاملة: $e',
              textDirection: TextDirection.rtl,
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

