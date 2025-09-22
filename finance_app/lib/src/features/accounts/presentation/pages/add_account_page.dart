import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../../../core/models/account.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../providers/account_providers.dart';

class AddAccountPage extends ConsumerStatefulWidget {
  final Account? editingAccount;

  const AddAccountPage({super.key, this.editingAccount});

  @override
  ConsumerState<AddAccountPage> createState() => _AddAccountPageState();
}

class _AddAccountPageState extends ConsumerState<AddAccountPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _balanceController = TextEditingController();
  final _descriptionController = TextEditingController();

  final List<String> _currencies = ['USD', 'EUR', 'GBP', 'SAR', 'AED', 'EGP'];

  @override
  void initState() {
    super.initState();
    
    // If editing, load the account data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.editingAccount != null) {
        final notifier = ref.read(accountFormProvider.notifier);
        notifier.loadAccountForEdit(widget.editingAccount!);
        _nameController.text = widget.editingAccount!.name;
        _balanceController.text = widget.editingAccount!.balance.toString();
        _descriptionController.text = widget.editingAccount!.description ?? '';
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(accountFormProvider);
    final authState = ref.watch(authProvider);

    final isEditing = widget.editingAccount != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Account' : 'Add Account'),
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
              // Account Name Input
              _buildNameInput(formState),
              
              const SizedBox(height: 16),
              
              // Account Type Selection
              _buildTypeSelection(formState),
              
              const SizedBox(height: 16),
              
              // Currency and Balance Row
              Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: _buildCurrencyDropdown(formState),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: _buildBalanceInput(formState),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Description Input
              _buildDescriptionInput(formState),
              
              const SizedBox(height: 16),
              
              // Active Status Toggle
              _buildActiveToggle(formState),
              
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
                onPressed: formState.isLoading ? null : () => _saveAccount(authState.user?.id),
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

  Widget _buildNameInput(AccountFormState formState) {
    return TextFormField(
      controller: _nameController,
      decoration: InputDecoration(
        labelText: 'Account Name',
        prefixIcon: const Icon(Icons.account_balance_wallet),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter an account name';
        }
        return null;
      },
      onChanged: (value) {
        ref.read(accountFormProvider.notifier).updateName(value);
      },
    );
  }

  Widget _buildTypeSelection(AccountFormState formState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Account Type',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        
        const SizedBox(height: 12),
        
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: AccountType.values.map((type) {
            final isSelected = formState.type == type;
            return GestureDetector(
              onTap: () {
                ref.read(accountFormProvider.notifier).updateType(type);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.blue.shade600 : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? Colors.blue.shade600 : Colors.grey.shade300,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getAccountTypeIcon(type),
                      size: 18,
                      color: isSelected ? Colors.white : Colors.grey.shade700,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _getAccountTypeName(type),
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.grey.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCurrencyDropdown(AccountFormState formState) {
    return DropdownButtonFormField<String>(
      value: formState.currency,
      decoration: InputDecoration(
        labelText: 'Currency',
        prefixIcon: const Icon(Icons.attach_money),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
      items: _currencies.map((currency) {
        return DropdownMenuItem<String>(
          value: currency,
          child: Text(currency),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          ref.read(accountFormProvider.notifier).updateCurrency(value);
        }
      },
    );
  }

  Widget _buildBalanceInput(AccountFormState formState) {
    return TextFormField(
      controller: _balanceController,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
      ],
      decoration: InputDecoration(
        labelText: 'Initial Balance',
        prefixIcon: const Icon(Icons.account_balance),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter an initial balance';
        }
        final balance = double.tryParse(value);
        if (balance == null || balance < 0) {
          return 'Please enter a valid balance';
        }
        return null;
      },
      onChanged: (value) {
        final balance = double.tryParse(value) ?? 0.0;
        ref.read(accountFormProvider.notifier).updateBalance(balance);
      },
    );
  }

  Widget _buildDescriptionInput(AccountFormState formState) {
    return TextFormField(
      controller: _descriptionController,
      maxLines: 3,
      decoration: InputDecoration(
        labelText: 'Description (Optional)',
        prefixIcon: const Icon(Icons.description),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
      onChanged: (value) {
        ref.read(accountFormProvider.notifier).updateDescription(value);
      },
    );
  }

  Widget _buildActiveToggle(AccountFormState formState) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(
            Icons.toggle_on,
            color: formState.isActive ? Colors.green : Colors.grey,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Account Status',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  formState.isActive 
                      ? 'Account is active and will appear in transaction lists'
                      : 'Account is inactive and will be hidden from transaction lists',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: formState.isActive,
            onChanged: (value) {
              ref.read(accountFormProvider.notifier).updateIsActive(value);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _saveAccount(String? userId) async {
    if (_formKey.currentState?.validate() != true || userId == null) {
      return;
    }

    final success = await ref
        .read(accountFormProvider.notifier)
        .saveAccount(userId, editingAccountId: widget.editingAccount?.id);

    if (success && mounted) {
      // Reset form for next account
      ref.read(accountFormProvider.notifier).reset();
      _nameController.clear();
      _balanceController.clear();
      _descriptionController.clear();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.editingAccount != null 
              ? 'Account updated successfully'
              : 'Account added successfully'),
          backgroundColor: Colors.green,
        ),
      );

      // Refresh accounts data
      ref.refresh(accountListDataProvider);
      
      Navigator.of(context).pop();
    }
  }

  IconData _getAccountTypeIcon(AccountType type) {
    switch (type) {
      case AccountType.cash:
        return Icons.money;
      case AccountType.bankCard:
        return Icons.credit_card;
      case AccountType.mobileWallet:
        return Icons.phone_android;
      case AccountType.savings:
        return Icons.savings;
      case AccountType.checking:
        return Icons.account_balance;
      case AccountType.credit:
        return Icons.credit_score;
    }
  }

  String _getAccountTypeName(AccountType type) {
    switch (type) {
      case AccountType.cash:
        return 'Cash';
      case AccountType.bankCard:
        return 'Bank Card';
      case AccountType.mobileWallet:
        return 'Mobile Wallet';
      case AccountType.savings:
        return 'Savings';
      case AccountType.checking:
        return 'Checking';
      case AccountType.credit:
        return 'Credit';
    }
  }
}