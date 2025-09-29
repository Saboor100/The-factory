// lib/pages/Events/event_registration_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/event_model.dart';
import '../../providers/event_provider.dart';

class EventRegistrationScreen extends StatefulWidget {
  final Event event;

  const EventRegistrationScreen({Key? key, required this.event})
    : super(key: key);

  @override
  State<EventRegistrationScreen> createState() =>
      _EventRegistrationScreenState();
}

class _EventRegistrationScreenState extends State<EventRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();

  // Form controllers
  final _athleteFirstNameController = TextEditingController();
  final _athleteLastNameController = TextEditingController();
  final _parentLastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _streetController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _zipCodeController = TextEditingController();
  final _usaLaxNumberController = TextEditingController();
  final _graduationYearController = TextEditingController();
  final _discountCodeController = TextEditingController();

  // Form state
  String? _selectedTicketType;
  TicketType? _selectedTicket;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _athleteFirstNameController.dispose();
    _athleteLastNameController.dispose();
    _parentLastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _streetController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipCodeController.dispose();
    _usaLaxNumberController.dispose();
    _graduationYearController.dispose();
    _discountCodeController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Event Registration'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Consumer<RegistrationProvider>(
        builder: (context, registrationProvider, child) {
          return Column(
            children: [
              // Event Summary Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                color: Colors.grey[50],
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.event.title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${widget.event.formattedDateRange} • ${widget.event.location}',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),

              // Registration Form
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Ticket Type Selection
                        _buildSectionTitle('Select Ticket Type'),
                        _buildTicketTypeSelection(),

                        const SizedBox(height: 24),

                        // Athlete Information
                        _buildSectionTitle('Athlete Information'),
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextFormField(
                                controller: _athleteFirstNameController,
                                label: 'First Name *',
                                validator: (value) {
                                  if (value?.isEmpty ?? true) {
                                    return 'First name is required';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildTextFormField(
                                controller: _athleteLastNameController,
                                label: 'Last Name *',
                                validator: (value) {
                                  if (value?.isEmpty ?? true) {
                                    return 'Last name is required';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        _buildTextFormField(
                          controller: _parentLastNameController,
                          label: 'Parent/Guardian Last Name *',
                          validator: (value) {
                            if (value?.isEmpty ?? true) {
                              return 'Parent last name is required';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 24),

                        // Contact Information
                        _buildSectionTitle('Contact Information'),
                        _buildTextFormField(
                          controller: _emailController,
                          label: 'Email Address *',
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value?.isEmpty ?? true) {
                              return 'Email is required';
                            }
                            if (!RegExp(
                              r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                            ).hasMatch(value!)) {
                              return 'Please enter a valid email';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 12),

                        _buildTextFormField(
                          controller: _phoneController,
                          label: 'Phone Number *',
                          keyboardType: TextInputType.phone,
                          validator: (value) {
                            if (value?.isEmpty ?? true) {
                              return 'Phone number is required';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 24),

                        // Address Information
                        _buildSectionTitle('Address'),
                        _buildTextFormField(
                          controller: _streetController,
                          label: 'Street Address *',
                          validator: (value) {
                            if (value?.isEmpty ?? true) {
                              return 'Street address is required';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 12),

                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: _buildTextFormField(
                                controller: _cityController,
                                label: 'City *',
                                validator: (value) {
                                  if (value?.isEmpty ?? true) {
                                    return 'City is required';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildTextFormField(
                                controller: _stateController,
                                label: 'State *',
                                validator: (value) {
                                  if (value?.isEmpty ?? true) {
                                    return 'State is required';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildTextFormField(
                                controller: _zipCodeController,
                                label: 'ZIP Code *',
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value?.isEmpty ?? true) {
                                    return 'ZIP code is required';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Lacrosse Information
                        _buildSectionTitle('Lacrosse Information'),
                        _buildTextFormField(
                          controller: _usaLaxNumberController,
                          label: 'USA LAX Number *',
                          validator: (value) {
                            if (value?.isEmpty ?? true) {
                              return 'USA LAX number is required';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 12),

                        _buildTextFormField(
                          controller: _graduationYearController,
                          label: 'Graduation Year *',
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value?.isEmpty ?? true) {
                              return 'Graduation year is required';
                            }
                            final year = int.tryParse(value!);
                            if (year == null || year < DateTime.now().year) {
                              return 'Please enter a valid graduation year';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 24),

                        // Discount Code Section
                        _buildSectionTitle('Discount Code (Optional)'),
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextFormField(
                                controller: _discountCodeController,
                                label: 'Discount Code',
                              ),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton(
                              onPressed:
                                  registrationProvider.isValidatingDiscount
                                      ? null
                                      : _validateDiscountCode,
                              child:
                                  registrationProvider.isValidatingDiscount
                                      ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                      : const Text('Apply'),
                            ),
                          ],
                        ),

                        // Discount feedback
                        if (registrationProvider.discountValidation != null)
                          Container(
                            margin: const EdgeInsets.only(top: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color:
                                  registrationProvider.hasValidDiscount
                                      ? Colors.green[50]
                                      : Colors.red[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color:
                                    registrationProvider.hasValidDiscount
                                        ? Colors.green
                                        : Colors.red,
                              ),
                            ),
                            child: Text(
                              registrationProvider.discountValidation!.message,
                              style: TextStyle(
                                color:
                                    registrationProvider.hasValidDiscount
                                        ? Colors.green[700]
                                        : Colors.red[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),

                        const SizedBox(height: 32),

                        // Price Summary
                        if (_selectedTicket != null)
                          _buildPriceSummary(registrationProvider),

                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),

              // Register Button
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      spreadRadius: 1,
                      blurRadius: 4,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed:
                      (_selectedTicket != null && !_isSubmitting)
                          ? _submitRegistration
                          : null,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  child:
                      _isSubmitting
                          ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              ),
                              SizedBox(width: 12),
                              Text('Registering...'),
                            ],
                          )
                          : Text(
                            _selectedTicket != null
                                ? 'Register for \$${_calculateFinalPrice(registrationProvider).toStringAsFixed(2)}'
                                : 'Select a ticket type to continue',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Theme.of(context).primaryColor),
        ),
      ),
    );
  }

  Widget _buildTicketTypeSelection() {
    return Column(
      children:
          widget.event.availableTicketTypes.map((ticket) {
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: RadioListTile<String>(
                title: Text(
                  ticket.name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(ticket.description),
                    const SizedBox(height: 4),
                    Text(
                      'Available: ${ticket.availableSpots}/${ticket.maxCapacity}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
                secondary: Text(
                  '\$${ticket.price.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                value: ticket.name,
                groupValue: _selectedTicketType,
                onChanged: (value) {
                  setState(() {
                    _selectedTicketType = value;
                    _selectedTicket = ticket;
                  });
                  // Clear discount when ticket type changes
                  context.read<RegistrationProvider>().clearDiscount();
                },
              ),
            );
          }).toList(),
    );
  }

  Widget _buildPriceSummary(RegistrationProvider registrationProvider) {
    final basePrice = _selectedTicket!.price;
    final finalPrice = _calculateFinalPrice(registrationProvider);
    final discount = basePrice - finalPrice;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Price Summary',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Base Price:'),
                Text('\$${basePrice.toStringAsFixed(2)}'),
              ],
            ),
            if (discount > 0) ...[
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Discount (${_discountCodeController.text}):',
                    style: const TextStyle(color: Colors.green),
                  ),
                  Text(
                    '-\$${discount.toStringAsFixed(2)}',
                    style: const TextStyle(color: Colors.green),
                  ),
                ],
              ),
            ],
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total:',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '\$${finalPrice.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  double _calculateFinalPrice(RegistrationProvider registrationProvider) {
    if (_selectedTicket == null) return 0.0;
    return registrationProvider.calculateFinalPrice(_selectedTicket!.price);
  }

  void _validateDiscountCode() async {
    final code = _discountCodeController.text.trim();
    if (code.isEmpty || _selectedTicketType == null) return;

    await context.read<RegistrationProvider>().validateDiscountCode(
      code: code,
      eventId: widget.event.id,
      ticketType: _selectedTicketType!,
      userEmail: _emailController.text.trim(),
    );
  }

  void _submitRegistration() async {
    if (!_formKey.currentState!.validate() || _selectedTicket == null) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final registrationData = RegistrationData(
        athleteFirstName: _athleteFirstNameController.text.trim(),
        athleteLastName: _athleteLastNameController.text.trim(),
        parentLastName: _parentLastNameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        address: Address(
          street: _streetController.text.trim(),
          city: _cityController.text.trim(),
          state: _stateController.text.trim(),
          zipCode: _zipCodeController.text.trim(),
        ),
        usaLaxNumber: _usaLaxNumberController.text.trim(),
        graduationYear: int.parse(_graduationYearController.text.trim()),
        ticketType: _selectedTicketType!,
        discountCode:
            _discountCodeController.text.isNotEmpty
                ? _discountCodeController.text.trim()
                : null,
      );

      final success = await context
          .read<RegistrationProvider>()
          .registerForEvent(
            eventId: widget.event.id,
            registrationData: registrationData,
          );

      if (success) {
        if (mounted) {
          _showRegistrationSuccess();
        }
      } else {
        if (mounted) {
          _showRegistrationError(
            context.read<RegistrationProvider>().registrationError ??
                'Registration failed. Please try again.',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        _showRegistrationError('An error occurred: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _showRegistrationSuccess() {
    final registrationResponse =
        context.read<RegistrationProvider>().registrationResponse!;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 28),
                SizedBox(width: 8),
                Text('Registration Successful!'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your registration has been confirmed.',
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 12),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Confirmation Number:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        registrationResponse.confirmationNumber,
                        style: TextStyle(
                          fontSize: 18,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text('Event: ${registrationResponse.event.title}'),
                      Text(
                        'Participant: ${registrationResponse.participant.name}',
                      ),
                      Text(
                        'Total: \${registrationResponse.pricing.finalPrice.toStringAsFixed(2)}',
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 12),
                if (registrationResponse.paymentRequired)
                  Text(
                    'Please proceed with payment to complete your registration.',
                    style: TextStyle(
                      color: Colors.orange[700],
                      fontWeight: FontWeight.w500,
                    ),
                  )
                else
                  Text(
                    'Your registration is complete!',
                    style: TextStyle(
                      color: Colors.green[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
            actions: [
              if (registrationResponse.paymentRequired)
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _proceedToPayment(registrationResponse);
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  child: Text('Proceed to Payment'),
                )
              else
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pop(); // Go back to events list
                  },
                  child: Text('Done'),
                ),
            ],
          ),
    );
  }

  void _showRegistrationError(String message) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.error, color: Colors.red, size: 28),
                SizedBox(width: 8),
                Text('Registration Failed'),
              ],
            ),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('OK'),
              ),
            ],
          ),
    );
  }

  void _proceedToPayment(RegistrationResponse registrationResponse) {
    // TODO: Implement payment processing
    // This is where you would integrate with Stripe, PayPal, etc.

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Payment Integration'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Payment integration would go here.'),
                SizedBox(height: 12),
                Text('Registration ID: ${registrationResponse.registrationId}'),
                Text(
                  'Amount: \${registrationResponse.pricing.finalPrice.toStringAsFixed(2)}',
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop(); // Go back to events list
                },
                child: Text('Done'),
              ),
            ],
          ),
    );
  }
}
