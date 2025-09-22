import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../../../core/models/transaction.dart';
import '../../../../core/models/account.dart';
import '../../../../core/models/category.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../providers/transaction_providers.dart';

class AddTransactionPage extends ConsumerStatefulWidget {
  final Transaction? editingTransaction;

  const AddTransactionPage({super.key, this.editingTransaction});

  @override
  ConsumerState<AddTransactionPage> createState() => _AddTransactionPageState();
}

class _AddTransactionPageState extends ConsumerState<AddTransactionPage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    
    // If editing, load the transaction data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.editingTransaction != null) {
        final notifier = ref.read(transactionFormProvider.notifier);
        notifier.loadTransactionForEdit(widget.editingTransaction!);
        _amountController.text = widget.editingTransaction!.amount.toString();
        _notesController.text = widget.editingTransaction!.notes ?? '';
      }
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(transactionFormProvider);
    final accountsAsync = ref.watch(userAccountsProvider);
    final categoriesAsync = ref.watch(userCategoriesProvider);
    final authState = ref.watch(authProvider);

    final isEditing = widget.editingTransaction != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'edit_transaction'.tr() : 'add_transaction'.tr()),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Transaction Type Toggle
              _buildTransactionTypeToggle(formState),
              
              const SizedBox(height: 24),
              
              // Amount Input
              _buildAmountInput(formState),
              
              const SizedBox(height: 16),
              
              // Account Dropdown
              _buildAccountDropdown(accountsAsync, formState),
              
              const SizedBox(height: 16),
              
              // Category Dropdown
              _buildCategoryDropdown(categoriesAsync, formState),
              
              const SizedBox(height: 16),
              
              // Date Picker
              _buildDatePicker(formState),
              
              const SizedBox(height: 16),
              
              // Notes Input
              _buildNotesInput(formState),
              
              const SizedBox(height: 32),
              
              // Error Message
              if (formState.error != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Text(
                    formState.error!,
                    style: TextStyle(color: Colors.red.shade700),
                  ),
                ),
              
              // Save Button
              ElevatedButton(
                onPressed: formState.isLoading ? null : () => _saveTransaction(authState.user?.id),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: formState.isLoading 
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        'save'.tr(),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionTypeToggle(TransactionFormState formState) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => ref.read(transactionFormProvider.notifier).updateType(TransactionType.expense),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: formState.type == TransactionType.expense ? Colors.red.shade500 : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'expense'.tr(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: formState.type == TransactionType.expense ? Colors.white : Colors.grey.shade600,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => ref.read(transactionFormProvider.notifier).updateType(TransactionType.income),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: formState.type == TransactionType.income ? Colors.green.shade500 : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'income'.tr(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: formState.type == TransactionType.income ? Colors.white : Colors.grey.shade600,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountInput(TransactionFormState formState) {
    return TextFormField(
      controller: _amountController,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
      ],
      decoration: InputDecoration(
        labelText: 'amount'.tr(),
        prefixIcon: const Icon(Icons.attach_money),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter an amount';
        }
        final amount = double.tryParse(value);
        if (amount == null || amount <= 0) {
          return 'Please enter a valid amount';
        }
        return null;
      },
      onChanged: (value) {
        final amount = double.tryParse(value) ?? 0.0;
        ref.read(transactionFormProvider.notifier).updateAmount(amount);
      },
    );
  }

  Widget _buildAccountDropdown(AsyncValue<List<Account>> accountsAsync, TransactionFormState formState) {
    return accountsAsync.when(
      loading: () => const CircularProgressIndicator(),
      error: (error, _) => Text('Error loading accounts: $error'),
      data: (accounts) {
        return DropdownButtonFormField<String>(
          value: formState.selectedAccountId,
          decoration: InputDecoration(
            labelText: 'account'.tr(),
            prefixIcon: const Icon(Icons.account_balance_wallet),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
          items: accounts.map((account) {
            return DropdownMenuItem<String>(
              value: account.id,
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: _getAccountTypeColor(account.type),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(account.name),
                        Text(
                          CurrencyFormatter.format(account.balance),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          validator: (value) => value == null ? 'Please select an account' : null,
          onChanged: (value) {
            if (value != null) {
              ref.read(transactionFormProvider.notifier).updateAccount(value);
            }
          },
        );
      },
    );
  }

  Widget _buildCategoryDropdown(AsyncValue<List<Category>> categoriesAsync, TransactionFormState formState) {
    return categoriesAsync.when(
      loading: () => const CircularProgressIndicator(),
      error: (error, _) => Text('Error loading categories: $error'),
      data: (categories) {
        return DropdownButtonFormField<String>(
          value: formState.selectedCategoryId,
          decoration: InputDecoration(
            labelText: 'category'.tr(),
            prefixIcon: const Icon(Icons.category),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
          items: categories.map((category) {
            return DropdownMenuItem<String>(
              value: category.id,
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: category.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(category.name)),
                ],
              ),
            );
          }).toList(),
          validator: (value) => value == null ? 'Please select a category' : null,
          onChanged: (value) {
            if (value != null) {
              ref.read(transactionFormProvider.notifier).updateCategory(value);
            }
          },
        );
      },
    );
  }

  Widget _buildDatePicker(TransactionFormState formState) {
    return InkWell(
      onTap: () => _selectDate(context),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'date'.tr(),
          prefixIcon: const Icon(Icons.calendar_today),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: Colors.grey.shade50,
        ),
        child: Text(
          DateFormat.yMMMd().format(formState.date),
          style: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }

  Widget _buildNotesInput(TransactionFormState formState) {
    return TextFormField(
      controller: _notesController,
      maxLines: 3,
      decoration: InputDecoration(
        labelText: 'notes'.tr(),
        prefixIcon: const Icon(Icons.note_alt),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
      onChanged: (value) {
        ref.read(transactionFormProvider.notifier).updateNotes(value);
      },
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final formState = ref.read(transactionFormProvider);
    final picked = await showDatePicker(
      context: context,
      initialDate: formState.date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );

    if (picked != null) {
      ref.read(transactionFormProvider.notifier).updateDate(picked);
    }
  }

  Future<void> _saveTransaction(String? userId) async {
    if (_formKey.currentState?.validate() != true || userId == null) {
      return;
    }

    final success = await ref
        .read(transactionFormProvider.notifier)
        .saveTransaction(userId, editingTransactionId: widget.editingTransaction?.id);

    if (success && mounted) {
      // Reset form for next transaction
      ref.read(transactionFormProvider.notifier).reset();
      _amountController.clear();
      _notesController.clear();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.editingTransaction != null 
              ? 'Transaction updated successfully'
              : 'Transaction added successfully'),
          backgroundColor: Colors.green,
        ),
      );

      // Refresh dashboard data
      ref.refresh(transactionListDataProvider);
      
      Navigator.of(context).pop();
    }
  }

  Color _getAccountTypeColor(AccountType type) {
    switch (type) {
      case AccountType.cash:
        return Colors.green;
      case AccountType.bankCard:
        return Colors.blue;
      case AccountType.mobileWallet:
        return Colors.purple;
      case AccountType.savings:
        return Colors.orange;
      case AccountType.checking:
        return Colors.teal;
      case AccountType.credit:
        return Colors.red;
    }
  }
}