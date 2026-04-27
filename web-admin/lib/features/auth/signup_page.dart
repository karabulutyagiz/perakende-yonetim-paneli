import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api.dart';

class SignupPage extends ConsumerStatefulWidget {
  const SignupPage({super.key});

  @override
  ConsumerState<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends ConsumerState<SignupPage> {
  final _form = GlobalKey<FormState>();
  final _business = TextEditingController();
  final _fullName = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _password2 = TextEditingController();
  bool _loading = false;
  String? _error;
  bool _done = false;

  @override
  void dispose() {
    _business.dispose();
    _fullName.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    _password2.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final dio = ref.read(dioProvider);
      await dio.post('/auth/signup', data: {
        'business_name': _business.text.trim(),
        'full_name': _fullName.text.trim(),
        'email': _email.text.trim(),
        'password': _password.text,
        if (_phone.text.trim().isNotEmpty) 'contact_phone': _phone.text.trim(),
      });
      if (mounted) setState(() => _done = true);
    } on DioException catch (e) {
      String msg = 'Kayıt başarısız';
      final data = e.response?.data;
      if (data is Map && data['detail'] is String) {
        msg = data['detail'] as String;
      }
      setState(() => _error = msg);
    } catch (_) {
      setState(() => _error = 'Kayıt başarısız');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Card(
            margin: const EdgeInsets.all(24),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: _done ? _doneView() : _formView(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _doneView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.check_circle_outline,
            size: 64, color: Color(0xFF0E6E4E)),
        const SizedBox(height: 12),
        const Text(
          'Kaydınız alındı',
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20),
        ),
        const SizedBox(height: 8),
        const Text(
          'Platform yöneticisi hesabınızı onayladıktan sonra giriş yapabilirsiniz.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.black54),
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: () => context.go('/login'),
          child: const Text('Girişe dön'),
        ),
      ],
    );
  }

  Widget _formView() {
    return Form(
      key: _form,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.storefront_rounded,
              size: 56, color: Color(0xFF0E6E4E)),
          const SizedBox(height: 12),
          const Text(
            'Yeni İşletme Kaydı',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20),
          ),
          const Text(
            'Toptan Perakende Paneli',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _business,
            decoration: const InputDecoration(
              labelText: 'İşletme adı',
              prefixIcon: Icon(Icons.business_outlined),
            ),
            validator: (v) =>
                (v == null || v.trim().length < 2) ? 'İşletme adı girin' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _fullName,
            decoration: const InputDecoration(
              labelText: 'Ad Soyad',
              prefixIcon: Icon(Icons.person_outline),
            ),
            validator: (v) =>
                (v == null || v.trim().length < 2) ? 'Ad Soyad girin' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'E-posta',
              prefixIcon: Icon(Icons.mail_outline),
            ),
            validator: (v) {
              final t = v?.trim() ?? '';
              if (!t.contains('@') || !t.contains('.')) {
                return 'Geçerli bir e-posta girin';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Telefon (opsiyonel)',
              prefixIcon: Icon(Icons.phone_outlined),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _password,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Parola',
              prefixIcon: Icon(Icons.lock_outline),
            ),
            validator: (v) =>
                (v == null || v.length < 8) ? 'En az 8 karakter' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _password2,
            obscureText: true,
            onFieldSubmitted: (_) => _submit(),
            decoration: const InputDecoration(
              labelText: 'Parola (tekrar)',
              prefixIcon: Icon(Icons.lock_outline),
            ),
            validator: (v) =>
                (v != _password.text) ? 'Parolalar eşleşmiyor' : null,
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: Colors.red)),
          ],
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _loading ? null : _submit,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
            child: _loading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Kayıt Ol'),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => context.go('/login'),
            child: const Text('Zaten hesabım var — Giriş yap'),
          ),
        ],
      ),
    );
  }
}
