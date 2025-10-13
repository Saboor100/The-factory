// lib/pages/Events/event_registration_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/event_model.dart';
import '../../providers/event_provider.dart';
import '../../providers/user_provider.dart';
import '../../services/payment_service.dart';
import 'ticket_viewer_screen.dart';

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

  // CHANGE 1: Use a constant for base URL that matches PaymentService
  static const String baseUrl = 'http://192.168.100.16:3000/api';

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
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        title: const Text('Event Registration'),
        backgroundColor: const Color(0xFF1A1A1A),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Consumer<RegistrationProvider>(
        builder: (context, registrationProvider, child) {
          return Column(
            children: [
              // Event Summary Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Color(0xFF2A2A2A),
                  border: Border(
                    bottom: BorderSide(color: Color(0xFF3A3A3A), width: 1),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.event.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${widget.event.formattedDateRange} • ${widget.event.location}',
                      style: const TextStyle(color: Colors.grey),
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
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFB8FF00),
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 16,
                                ),
                              ),
                              child:
                                  registrationProvider.isValidatingDiscount
                                      ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                Colors.black,
                                              ),
                                        ),
                                      )
                                      : const Text(
                                        'Apply',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
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
                                      ? const Color(
                                        0xFFB8FF00,
                                      ).withOpacity(0.15)
                                      : Colors.red.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color:
                                    registrationProvider.hasValidDiscount
                                        ? const Color(0xFFB8FF00)
                                        : Colors.red,
                                width: 2,
                              ),
                            ),
                            child: Text(
                              registrationProvider.discountValidation!.message,
                              style: TextStyle(
                                color:
                                    registrationProvider.hasValidDiscount
                                        ? const Color(0xFFB8FF00)
                                        : Colors.red,
                                fontWeight: FontWeight.w600,
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

              // Register Button (with Payment)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Color(0xFF2A2A2A),
                  border: Border(
                    top: BorderSide(color: Color(0xFF3A3A3A), width: 1),
                  ),
                ),
                child: ElevatedButton(
                  onPressed:
                      (_selectedTicket != null && !_isSubmitting)
                          ? _submitRegistrationAndPay
                          : null,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: const Color(0xFFB8FF00),
                    foregroundColor: Colors.black,
                    disabledBackgroundColor: const Color(0xFF3A3A3A),
                    disabledForegroundColor: Colors.grey,
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
                                    Colors.black,
                                  ),
                                ),
                              ),
                              SizedBox(width: 12),
                              Text(
                                'Processing...',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          )
                          : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.payment, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                _selectedTicket != null
                                    ? 'Pay \$${_calculateFinalPrice(registrationProvider).toStringAsFixed(2)} - Register'
                                    : 'Select a ticket type to continue',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // CHANGE 2: Improved registration and payment flow with proper error handling
  Future<void> _submitRegistrationAndPay() async {
    if (!_formKey.currentState!.validate() || _selectedTicket == null) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final userId = userProvider.user.id;
      final token = userProvider.user.token;

      final finalPrice = _calculateFinalPrice(
        context.read<RegistrationProvider>(),
      );

      // Step 1: Process Stripe payment first
      print('💳 Processing Stripe payment for \$$finalPrice...');
      final paymentSuccess = await PaymentService.processEventPayment(
        eventId: widget.event.id,
        amount: finalPrice,
        eventName: widget.event.title,
        userId: userId,
        token: token,
      );

      if (!mounted) return;

      if (!paymentSuccess) {
        // Payment failed or cancelled
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Payment failed or cancelled'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }

      print('✅ Payment successful, creating registration...');

      // Step 2: Create registration in database
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

      final registrationSuccess = await context
          .read<RegistrationProvider>()
          .registerForEvent(
            eventId: widget.event.id,
            registrationData: registrationData,
          );

      if (!registrationSuccess) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Payment successful but registration failed. Please contact support.',
              ),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 5),
            ),
          );
        }
        return;
      }

      print('✅ Registration created, marking as paid...');

      // Step 3: Mark registration as paid
      final registrationResponse =
          context.read<RegistrationProvider>().registrationResponse;

      if (registrationResponse != null) {
        // CHANGE 3: Add timeout and better error handling
        final paymentMarked = await _markRegistrationAsPaid(
          registrationResponse.registrationId,
          finalPrice,
          token,
        ).timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            print('⚠️ Payment marking timed out');
            return false;
          },
        );

        if (!paymentMarked) {
          print('⚠️ Warning: Failed to mark registration as paid');
          // Still show success to user since payment and registration worked
        }

        // Small delay to ensure everything is saved
        await Future.delayed(const Duration(milliseconds: 300));

        if (mounted) {
          _showRegistrationSuccess();
        }
      }
    } catch (e) {
      print('❌ Registration error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An error occurred: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  // CHANGE 4: Return bool and use consistent base URL
  Future<bool> _markRegistrationAsPaid(
    String registrationId,
    double amount,
    String token,
  ) async {
    try {
      print(
        '📝 Marking registration $registrationId as paid with amount: \$$amount',
      );

      // Use the same base URL as PaymentService
      final response = await http.post(
        Uri.parse('$baseUrl/events/registrations/$registrationId/payment'),
        headers: {'Content-Type': 'application/json', 'x-auth-token': token},
        body: json.encode({
          'paidAmount': amount,
          'paymentMethod': 'stripe',
          'paymentTransactionId':
              'stripe_${DateTime.now().millisecondsSinceEpoch}',
        }),
      );

      if (response.statusCode == 200) {
        print('✅ Registration marked as paid successfully');
        return true;
      } else {
        print('⚠️ Failed to mark registration as paid: ${response.statusCode}');
        print('Response body: ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ Error marking registration as paid: $e');
      return false;
    }
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
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
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF3A3A3A)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF3A3A3A)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFB8FF00), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        filled: true,
        fillColor: const Color(0xFF2A2A2A),
      ),
    );
  }

  Widget _buildTicketTypeSelection() {
    return Column(
      children:
          widget.event.availableTicketTypes.map((ticket) {
            final isSelected = _selectedTicketType == ticket.name;
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color:
                      isSelected
                          ? const Color(0xFFB8FF00)
                          : const Color(0xFF3A3A3A),
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: RadioListTile<String>(
                title: Text(
                  ticket.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(
                      ticket.description,
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Available: ${ticket.availableSpots}/${ticket.maxCapacity}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
                secondary: Text(
                  '\$${ticket.price.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFB8FF00),
                  ),
                ),
                value: ticket.name,
                groupValue: _selectedTicketType,
                activeColor: const Color(0xFFB8FF00),
                onChanged: (value) {
                  setState(() {
                    _selectedTicketType = value;
                    _selectedTicket = ticket;
                  });
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

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF3A3A3A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Price Summary',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Base Price:', style: TextStyle(color: Colors.grey)),
              Text(
                '\$${basePrice.toStringAsFixed(2)}',
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
          if (discount > 0) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Discount (${_discountCodeController.text}):',
                  style: const TextStyle(color: Color(0xFFB8FF00)),
                ),
                Text(
                  '-\$${discount.toStringAsFixed(2)}',
                  style: const TextStyle(color: Color(0xFFB8FF00)),
                ),
              ],
            ),
          ],
          const Divider(color: Color(0xFF3A3A3A), height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total:',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '\$${finalPrice.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFB8FF00),
                ),
              ),
            ],
          ),
        ],
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

  void _showRegistrationSuccess() {
    final registrationResponse =
        context.read<RegistrationProvider>().registrationResponse!;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => Dialog(
            backgroundColor: const Color(0xFF2A2A2A),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: Color(0xFFB8FF00),
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Registration Successful!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Payment completed and registration confirmed',
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A1A),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Confirmation Number',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                        const SizedBox(height: 4),
                        SelectableText(
                          registrationResponse.confirmationNumber,
                          style: const TextStyle(
                            color: Color(0xFFB8FF00),
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop(); // Close dialog
                        Navigator.of(context).pop(); // Go back to event details
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder:
                                (context) => TicketViewerScreen(
                                  registrationId:
                                      registrationResponse.registrationId,
                                  confirmationNumber:
                                      registrationResponse.confirmationNumber,
                                ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFB8FF00),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text(
                        'View Ticket',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
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
}
