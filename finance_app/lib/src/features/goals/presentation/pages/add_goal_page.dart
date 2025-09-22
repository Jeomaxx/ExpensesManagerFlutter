import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/goal_providers.dart';
import '../../../../core/models/goal.dart';
import '../../../../core/models/account.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../accounts/providers/account_providers.dart';

class AddGoalPage extends ConsumerStatefulWidget {
  final Goal? goalToEdit;

  const AddGoalPage({super.key, this.goalToEdit});

  @override
  ConsumerState<AddGoalPage> createState() => _AddGoalPageState();
}

class _AddGoalPageState extends ConsumerState<AddGoalPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _targetAmountController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  DateTime? _targetDate;
  String? _selectedAccountId;

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  void _initializeForm() {
    if (widget.goalToEdit != null) {
      final goal = widget.goalToEdit!;
      _titleController.text = goal.title;
      _targetAmountController.text = goal.targetAmount.toString();
      _targetDate = goal.targetDate;
      _selectedAccountId = goal.linkedAccountId;
    } else {
      _targetDate = DateTime.now().add(const Duration(days: 365));
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _targetAmountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final goalFormState = ref.watch(goalFormProvider);
    final accountsAsyncValue = ref.watch(accountListDataProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.goalToEdit != null ? 'Edit Goal' : 'Add New Goal'),
        actions: [
          if (goalFormState.isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Goal Title
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Goal Title',
                hintText: 'e.g., Emergency Fund, Vacation',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a goal title';
                }
                return null;
              },
              onChanged: (value) {
                ref.read(goalFormProvider.notifier).updateTitle(value);
              },
            ),

            const SizedBox(height: 16),

            // Target Amount
            TextFormField(
              controller: _targetAmountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Target Amount',
                prefixText: '\$',
                hintText: '0.00',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a target amount';
                }
                final amount = double.tryParse(value);
                if (amount == null || amount <= 0) {
                  return 'Please enter a valid amount greater than 0';
                }
                return null;
              },
              onChanged: (value) {
                final amount = double.tryParse(value) ?? 0.0;
                ref.read(goalFormProvider.notifier).updateTargetAmount(amount);
              },
            ),

            const SizedBox(height: 16),

            // Target Date
            InkWell(
              onTap: () => _selectTargetDate(),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                decoration: BoxDecoration(
                  border: Border.all(color: Theme.of(context).colorScheme.outline),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Target Date',
                            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                          Text(
                            _targetDate != null
                                ? _formatDate(_targetDate!)
                                : 'Select target date',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Linked Account (Optional)
            accountsAsyncValue.when(
              data: (_) {
                final accountState = ref.watch(accountListProvider);
                return DropdownButtonFormField<String>(
                  value: _selectedAccountId,
                  decoration: const InputDecoration(
                    labelText: 'Linked Account (Optional)',
                    hintText: 'Select an account to track from',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem<String>(
                      value: null,
                      child: Text('No linked account'),
                    ),
                    ...accountState.accounts.map((Account account) {
                      return DropdownMenuItem<String>(
                        value: account.id,
                        child: Text('${account.name} (\$${account.balance.toStringAsFixed(2)})'),
                      );
                    }),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedAccountId = value;
                    });
                    ref.read(goalFormProvider.notifier).updateLinkedAccount(value);
                  },
                );
              },
              loading: () => const LinearProgressIndicator(),
              error: (error, stack) => const SizedBox(),
            ),

            const SizedBox(height: 16),

            // Description (Optional)
            TextFormField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Description (Optional)',
                hintText: 'Add notes about this goal...',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              onChanged: (value) {
                ref.read(goalFormProvider.notifier).updateDescription(value);
              },
            ),

            const SizedBox(height: 24),

            // Error Message
            if (goalFormState.error != null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        goalFormState.error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: goalFormState.isLoading ? null : _saveGoal,
                child: goalFormState.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(widget.goalToEdit != null ? 'Update Goal' : 'Create Goal'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectTargetDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _targetDate ?? DateTime.now().add(const Duration(days: 365)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
      helpText: 'Select target date',
      cancelText: 'Cancel',
      confirmText: 'Select',
    );

    if (picked != null && picked != _targetDate) {
      setState(() {
        _targetDate = picked;
      });
      ref.read(goalFormProvider.notifier).updateTargetDate(picked);
    }
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                   'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  Future<void> _saveGoal() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_targetDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a target date')),
      );
      return;
    }

    final authState = ref.read(authProvider);
    if (authState.user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not authenticated')),
      );
      return;
    }

    // Update form state with current values
    ref.read(goalFormProvider.notifier).updateTitle(_titleController.text);
    ref.read(goalFormProvider.notifier).updateTargetAmount(double.tryParse(_targetAmountController.text) ?? 0.0);
    ref.read(goalFormProvider.notifier).updateTargetDate(_targetDate!);
    ref.read(goalFormProvider.notifier).updateLinkedAccount(_selectedAccountId);
    ref.read(goalFormProvider.notifier).updateDescription(_descriptionController.text.isNotEmpty ? _descriptionController.text : null);

    final success = await ref.read(goalFormProvider.notifier).saveGoal(
      authState.user!.id,
      existingGoal: widget.goalToEdit,
    );

    if (success && mounted) {
      // Refresh goals list
      ref.read(goalListProvider.notifier).loadGoals(authState.user!.id);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.goalToEdit != null
                ? 'Goal updated successfully!'
                : 'Goal created successfully!',
          ),
        ),
      );

      Navigator.pop(context);
    }
  }
}