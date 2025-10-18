import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/theme/theme.dart';
import '../provider/auth_provider.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final fullNameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final phoneController = TextEditingController();
  final dobController = TextEditingController();

  String role = 'doctor';
  String? gender;
  bool loading = false;
  bool _isFormValid = false;

  @override
  void initState() {
    super.initState();
    // Add listeners to all controllers to check form validity
    fullNameController.addListener(_checkFormValidity);
    emailController.addListener(_checkFormValidity);
    passwordController.addListener(_checkFormValidity);
    confirmPasswordController.addListener(_checkFormValidity);
    phoneController.addListener(_checkFormValidity);
    dobController.addListener(_checkFormValidity);
  }

  @override
  void dispose() {
    fullNameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    phoneController.dispose();
    dobController.dispose();
    super.dispose();
  }

  void _checkFormValidity() {
    setState(() {
      _isFormValid = fullNameController.text.trim().isNotEmpty &&
          emailController.text.trim().isNotEmpty &&
          passwordController.text.trim().length >= 8 &&
          confirmPasswordController.text.trim().isNotEmpty &&
          passwordController.text == confirmPasswordController.text &&
          phoneController.text.trim().isNotEmpty &&
          gender != null &&
          dobController.text.trim().isNotEmpty;
    });
  }

  Future<void> registerUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => loading = true);
    final supabase = ref.read(supabaseClientProvider);

    try {
      print('🔵 Starting registration...');

      // Step 1: Create auth user
      final authResponse = await supabase.auth.signUp(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
        data: {'full_name': fullNameController.text.trim(), 'role': role},
      );

      final user = authResponse.user;
      if (user == null) throw const AuthException('User creation failed');


      // Step 2: Wait for auth to fully process
      await Future.delayed(const Duration(milliseconds: 1000));


      final userInsert = await supabase.from('users').insert({
        'auth_id': user.id,
        'email': emailController.text.trim(),
        'full_name': fullNameController.text.trim(),
        'phone': phoneController.text.trim().isEmpty
            ? null
            : phoneController.text.trim(),
        'gender': gender,
        'date_of_birth': dobController.text.trim().isEmpty
            ? null
            : dobController.text.trim(),
        'role': role,
      }).select();

      print('✅ User record created successfully: $userInsert');

      // Step 4: Verify the user record was created
      final verifyUser = await supabase
          .from('users')
          .select()
          .eq('auth_id', user.id)
          .maybeSingle();

      if (verifyUser == null) {
        throw Exception(
          'User record was not created. Please contact support or try again.',
        );
      }

      print('✅ User record verified: $verifyUser');

      // Note: Doctor profile will be completed later through the app

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Registration successful! Please confirm your email before Log In.',
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 4),
        ),
      );

      context.pop(); // back to login
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Registration failed: ${e.message}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    } on PostgrestException catch (e) {

      if (!mounted) return;

      // Check if it's an RLS policy error
      if (e.message.contains('policy') || e.message.contains('permission')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Database permission error. Please check RLS policies in Supabase.',
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 7),
            action: SnackBarAction(
              label: 'Details',
              textColor: Colors.white,
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Database Error'),
                    content: Text('${e.message}\n\nDetails: ${e.details}'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Database error: ${e.message}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Registration failed: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.light_blue,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const Text(
                  'Sign up',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AppColors.blue,
                  ),
                ),
                const SizedBox(height: 25),

                // Full Name
                _buildInputField(
                  controller: fullNameController,
                  label: 'Full Name',
                  icon: Icons.person_outline,
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),

                // Email
                _buildInputField(
                  controller: emailController,
                  label: 'Email Address',
                  icon: Icons.email_outlined,
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),

                // Password
                _buildInputField(
                  controller: passwordController,
                  label: 'Password',
                  icon: Icons.lock_outline,
                  isPassword: true,
                  validator: (v) =>
                      v!.length < 8 ? 'Minimum 8 characters' : null,
                ),
                const SizedBox(height: 16),

                // Confirm Password
                _buildInputField(
                  controller: confirmPasswordController,
                  label: 'Confirm Password',
                  icon: Icons.lock_outline,
                  isPassword: true,
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return 'Please confirm your password';
                    }
                    if (v != passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Phone
                _buildInputField(
                  controller: phoneController,
                  label: 'Phone',
                  icon: Icons.phone_outlined,
                ),
                const SizedBox(height: 16),

                // Gender Dropdown
                DropdownButtonFormField<String>(
                  value: gender,
                  decoration: _inputDecoration(
                    label: 'Gender',
                    icon: Icons.person_pin_circle_outlined,
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Male', child: Text('Male')),
                    DropdownMenuItem(value: 'Female', child: Text('Female')),
                    DropdownMenuItem(value: 'Other', child: Text('Other')),
                  ],
                  onChanged: (val) {
                    setState(() => gender = val);
                    _checkFormValidity();
                  },
                  validator: (val) =>
                      val == null ? 'Please select gender' : null,
                ),
                const SizedBox(height: 16),

                // Date of Birth picker
                TextFormField(
                  controller: dobController,
                  readOnly: true,
                  decoration: _inputDecoration(
                    label: 'Date of Birth',
                    icon: Icons.calendar_today,
                  ),
                  onTap: () async {
                    final DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: DateTime(2000, 1, 1),
                      firstDate: DateTime(1900),
                      lastDate: DateTime.now(),
                    );

                    if (pickedDate != null) {
                      dobController.text = pickedDate.toIso8601String().split(
                        'T',
                      )[0];
                      _checkFormValidity();
                    }
                  },
                  validator: (v) => v == null || v.isEmpty
                      ? 'Please select your date of birth'
                      : null,
                ),
                const SizedBox(height: 25),

                // Register button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: loading || !_isFormValid ? null : registerUser,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.dark_blue,
                      disabledBackgroundColor: Colors.grey.shade400,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: loading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            'Sign up',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: _isFormValid ? Colors.white : Colors.grey.shade600,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 25),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Already have an account? "),
                    MouseRegion(
                      onEnter: (_) => setState(() => _isHovering = true),
                      onExit: (_) => setState(() => _isHovering = false),
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: () => context.push('/login'),
                        child: Text(
                          "Login",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.blue,
                            decoration: _isHovering
                                ? TextDecoration.underline
                                : TextDecoration.none,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool _isHovering = false;

  // Helper for consistent InputDecoration
  InputDecoration _inputDecoration({required String label, IconData? icon}) {
    return InputDecoration(
      floatingLabelBehavior: FloatingLabelBehavior.never,
      filled: true,
      fillColor: AppColors.white,
      labelText: label,
      prefixIcon: icon != null ? Icon(icon) : null,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }

  // Helper for text fields
  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    IconData? icon,
    bool isPassword = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      validator: validator,
      decoration: _inputDecoration(label: label, icon: icon),
    );
  }
}
