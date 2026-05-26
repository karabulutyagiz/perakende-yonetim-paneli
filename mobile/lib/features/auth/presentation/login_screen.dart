import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/auth_controller.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final ok = await ref
        .read(authControllerProvider.notifier)
        .login(_email.text.trim(), _password.text);
    if (!mounted) return;
    setState(() => _loading = false);
    if (!ok) {
      final msg =
          ref.read(authControllerProvider).errorMessage ?? 'Giriş başarısız';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final width = MediaQuery.of(context).size.width;
    final isPhone = width < 600;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: isPhone ? 12 : 32),
                    Image.asset(
                      'assets/icon/parasende.png',
                      width: isPhone ? 72 : 112,
                      height: isPhone ? 72 : 112,
                      fit: BoxFit.contain,
                    ),
                    SizedBox(height: isPhone ? 10 : 16),
                    Text(
                      'ParaSende',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Stok ve sipariş yönetimi',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    SizedBox(height: isPhone ? 22 : 40),
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'E-posta',
                        prefixIcon: Icon(Icons.mail_outline),
                      ),
                      validator: (v) => (v == null || !v.contains('@'))
                          ? 'Geçerli e-posta girin'
                          : null,
                    ),
                    SizedBox(height: isPhone ? 12 : 16),
                    TextFormField(
                      controller: _password,
                      obscureText: _obscure,
                      decoration: InputDecoration(
                        labelText: 'Parola',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscure ? Icons.visibility : Icons.visibility_off,
                          ),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                      validator: (v) => (v == null || v.length < 6)
                          ? 'En az 6 karakter'
                          : null,
                    ),
                    SizedBox(height: isPhone ? 18 : 24),
                    FilledButton(
                      onPressed: _loading ? null : _submit,
                      child: _loading
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2.5),
                            )
                          : const Text('Giriş yap'),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed:
                          _loading ? null : () => context.push('/signup'),
                      child: const Text(
                        'Hesabın yok mu? · İşletme hesabı aç',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
