import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:intl/intl.dart';

import '../../../../core/models/budget.dart';
import '../../../../core/models/category.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../providers/budget_providers.dart';

class AddBudgetPage extends ConsumerStatefulWidget {
  final Budget? editingBudget;

  const AddBudgetPage({super.key, this.editingBudget});

  @override
  ConsumerState<AddBudgetPage> createState() => _AddBudgetPageState();
}

class _AddBudgetPageState extends ConsumerState<AddBudgetPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    
    // Load categories and setup form if editing
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authState = ref.read(authProvider);
      if (authState.user != null) {
        ref.read(budgetFormProvider.notifier).loadCategories(authState.user!.id);
      }

      if (widget.editingBudget != null) {
        final notifier = ref.read(budgetFormProvider.notifier);
        notifier.loadBudgetForEdit(widget.editingBudget!);
        _nameController.text = widget.editingBudget!.name;
        _amountController.text = widget.editingBudget!.amount.toString();
        _descriptionController.text = widget.editingBudget!.description ?? '';
      } else {
        // Set default budget type to monthly
        ref.read(budgetFormProvider.notifier).updateType(BudgetType.monthly);
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(budgetFormProvider);
    final authState = ref.watch(authProvider);

    final isEditing = widget.editingBudget != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Budget' : 'Create Budget'),
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
              // Budget Name Input
              _buildNameInput(formState),
              
              const SizedBox(height: 16),
              
              // Category Selection
              _buildCategorySelection(formState),
              
              const SizedBox(height: 16),
              
              // Budget Amount Input
              _buildAmountInput(formState),
              
              const SizedBox(height: 16),
              
              // Budget Type Selection
              _buildBudgetTypeSelection(formState),
              
              const SizedBox(height: 16),
              
              // Date Range
              _buildDateRangeSection(formState),
              
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
                onPressed: formState.isLoading ? null : () => _saveBudget(authState.user?.id),
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

  Widget _buildNameInput(BudgetFormState formState) {
    return TextFormField(
      controller: _nameController,
      decoration: InputDecoration(
        labelText: 'Budget Name',
        prefixIcon: const Icon(Icons.label),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter a budget name';
        }
        return null;
      },
      onChanged: (value) {
        ref.read(budgetFormProvider.notifier).updateName(value);
      },
    );
  }

  Widget _buildCategorySelection(BudgetFormState formState) {
    return DropdownButtonFormField<String>(
      value: formState.categoryId,
      decoration: InputDecoration(
        labelText: 'Category',
        prefixIcon: const Icon(Icons.category),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
      hint: const Text('Select a category'),
      items: formState.availableCategories.map((category) {
        return DropdownMenuItem<String>(
          value: category.id,
          child: Row(
            children: [
              Icon(
                IconData(
                  int.tryParse(category.iconName) ?? Icons.category.codePoint,
                  fontFamily: 'MaterialIcons',
                ),
                color: category.color,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(category.name),
            ],
          ),
        );
      }).toList(),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please select a category';
        }
        return null;
      },
      onChanged: (value) {
        ref.read(budgetFormProvider.notifier).updateCategory(value);
      },
    );
  }

  Widget _buildAmountInput(BudgetFormState formState) {
    return TextFormField(
      controller: _amountController,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
      ],
      decoration: InputDecoration(
        labelText: 'Budget Amount',
        prefixIcon: const Icon(Icons.attach_money),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter a budget amount';
        }
        final amount = double.tryParse(value);
        if (amount == null || amount <= 0) {
          return 'Please enter a valid amount';
        }
        return null;
      },
      onChanged: (value) {
        final amount = double.tryParse(value) ?? 0.0;
        ref.read(budgetFormProvider.notifier).updateAmount(amount);
      },
    );
  }

  Widget _buildBudgetTypeSelection(BudgetFormState formState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Budget Period',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        
        const SizedBox(height: 12),
        
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: BudgetType.values.map((type) {
            final isSelected = formState.type == type;
            return GestureDetector(
              onTap: () {
                ref.read(budgetFormProvider.notifier).updateType(type);
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
                      _getBudgetTypeIcon(type),
                      size: 18,
                      color: isSelected ? Colors.white : Colors.grey.shade700,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _getBudgetTypeName(type),
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

  Widget _buildDateRangeSection(BudgetFormState formState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Budget Period',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        
        const SizedBox(height: 12),
        
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: formState.startDate ?? DateTime.now(),
                    firstDate: DateTime.now().subtract(const Duration(days: 365)),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (date != null) {
                    ref.read(budgetFormProvider.notifier).updateStartDate(date);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey.shade50,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Start Date',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        formState.startDate != null
                            ? DateFormat.yMMMd().format(formState.startDate!)
                            : 'Select date',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            const SizedBox(width: 16),
            
            Expanded(
              child: InkWell(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: formState.endDate ?? DateTime.now().add(const Duration(days: 30)),
                    firstDate: formState.startDate ?? DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (date != null) {
                    ref.read(budgetFormProvider.notifier).updateEndDate(date);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey.shade50,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'End Date',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        formState.endDate != null
                            ? DateFormat.yMMMd().format(formState.endDate!)
                            : 'Select date',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDescriptionInput(BudgetFormState formState) {
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
        ref.read(budgetFormProvider.notifier).updateDescription(value);
      },
    );
  }

  Widget _buildActiveToggle(BudgetFormState formState) {
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
                  'Budget Status',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  formState.isActive 
                      ? 'Budget is active and will track spending'
                      : 'Budget is inactive and will not track spending',
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
              ref.read(budgetFormProvider.notifier).updateIsActive(value);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _saveBudget(String? userId) async {
    if (_formKey.currentState?.validate() != true || userId == null) {
      return;
    }

    final success = await ref
        .read(budgetFormProvider.notifier)
        .saveBudget(userId, editingBudgetId: widget.editingBudget?.id);

    if (success && mounted) {
      // Reset form for next budget
      ref.read(budgetFormProvider.notifier).reset();
      _nameController.clear();
      _amountController.clear();
      _descriptionController.clear();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.editingBudget != null 
              ? 'Budget updated successfully'
              : 'Budget created successfully'),
          backgroundColor: Colors.green,
        ),
      );

      // Refresh budget data
      ref.refresh(budgetListDataProvider);
      
      Navigator.of(context).pop();
    }
  }

  IconData _getBudgetTypeIcon(BudgetType type) {
    switch (type) {
      case BudgetType.weekly:
        return Icons.calendar_view_week;
      case BudgetType.monthly:
        return Icons.calendar_view_month;
      case BudgetType.yearly:
        return Icons.calendar_today;
      case BudgetType.custom:
        return Icons.date_range;
    }
  }

  String _getBudgetTypeName(BudgetType type) {
    switch (type) {
      case BudgetType.weekly:
        return 'Weekly';
      case BudgetType.monthly:
        return 'Monthly';
      case BudgetType.yearly:
        return 'Yearly';
      case BudgetType.custom:
        return 'Custom';
    }
  }
}