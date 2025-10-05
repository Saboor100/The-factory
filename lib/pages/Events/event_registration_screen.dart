// lib/pages/Events/event_registration_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/event_model.dart';
import '../../providers/event_provider.dart';
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

              // Register Button
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
                          ? _submitRegistration
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
                                'Registering...',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
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
          (context) => Dialog(
            backgroundColor: const Color(0xFF2A2A2A),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            insetPadding: const EdgeInsets.all(20),
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.8,
                maxWidth: MediaQuery.of(context).size.width - 40,
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title Row
                    Row(
                      children: [
                        const Icon(
                          Icons.check_circle,
                          color: Color(0xFFB8FF00),
                          size: 28,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: const Text(
                            'Registration Successful!',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Success Message
                    const Text(
                      'Your registration has been confirmed.',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),

                    const SizedBox(height: 16),

                    // Confirmation Details
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A1A),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF3A3A3A)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Confirmation Number:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          SelectableText(
                            registrationResponse.confirmationNumber,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Color(0xFFB8FF00),
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Event: ${registrationResponse.event.title}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Participant: ${registrationResponse.participant.name}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Total: \${registrationResponse.pricing.finalPrice.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Payment Status Message
                    if (registrationResponse.paymentRequired)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange, width: 1),
                        ),
                        child: const Text(
                          'Please proceed with payment to complete your registration.',
                          style: TextStyle(
                            color: Colors.orange,
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFB8FF00).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(0xFFB8FF00),
                            width: 1,
                          ),
                        ),
                        child: const Text(
                          'Your registration is complete!',
                          style: TextStyle(
                            color: Color(0xFFB8FF00),
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                      ),

                    const SizedBox(height: 24),

                    // Action Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          if (registrationResponse.paymentRequired) {
                            _proceedToPayment(registrationResponse);
                          } else {
                            Navigator.of(context).pop();
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder:
                                    (context) => TicketViewerScreen(
                                      registrationId:
                                          registrationResponse.registrationId,
                                      confirmationNumber:
                                          registrationResponse
                                              .confirmationNumber,
                                    ),
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFB8FF00),
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          registrationResponse.paymentRequired
                              ? 'Proceed to Payment'
                              : 'View Ticket',
                          style: const TextStyle(
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
          ),
    );
  }

  void _showRegistrationError(String message) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: const Color(0xFF2A2A2A),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Row(
              children: [
                Icon(Icons.error, color: Colors.red, size: 28),
                SizedBox(width: 8),
                Text(
                  'Registration Failed',
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
            content: Text(message, style: const TextStyle(color: Colors.white)),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                style: TextButton.styleFrom(
                  backgroundColor: const Color(0xFFB8FF00),
                  foregroundColor: Colors.black,
                ),
                child: const Text(
                  'OK',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
    );
  }

  void _proceedToPayment(RegistrationResponse registrationResponse) async {
    final shouldProceed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            backgroundColor: const Color(0xFF2A2A2A),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              'Payment Integration',
              style: TextStyle(color: Colors.white),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Payment integration would go here.',
                  style: TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 12),
                Text(
                  'Registration ID: ${registrationResponse.registrationId}',
                  style: const TextStyle(color: Colors.grey),
                ),
                Text(
                  'Amount: \$${registrationResponse.pricing.finalPrice.toStringAsFixed(2)}',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFB8FF00),
                  foregroundColor: Colors.black,
                ),
                child: const Text(
                  'Simulate Payment',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
    );

    if (shouldProceed == true && mounted) {
      Navigator.of(context).pop();
      Navigator.of(context).pop();

      Navigator.of(context).push(
        MaterialPageRoute(
          builder:
              (context) => TicketViewerScreen(
                registrationId: registrationResponse.registrationId,
                confirmationNumber: registrationResponse.confirmationNumber,
              ),
        ),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment simulated successfully!'),
          backgroundColor: Color(0xFFB8FF00),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
}
