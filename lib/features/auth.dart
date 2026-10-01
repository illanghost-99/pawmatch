import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../app_state.dart';
import '../services/biometrics.dart';
import '../services/cloud.dart';
import '../widgets/paws_bg.dart';
import '../widgets/welcome_hero.dart';

const _coral = Color(0xFFE25C3A);
const _ink = Color(0xFF14202B);
const _cream = Color(0xFFFFF4EC);

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, required this.state});
  final AppState state;
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool create = false;
  bool bioOk = false;
  bool busy = false;
  final email = TextEditingController();
  final pass = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.state.email.contains('@')) email.text = widget.state.email;
    Biometrics.available().then((v) {
      if (mounted) setState(() => bioOk = v);
    });
  }

  @override
  void dispose() {
    email.dispose();
    pass.dispose();
    super.dispose();
  }

  String notice = '';

  Future<void> _go() async {
    if (busy) return;
    final mail = email.text.trim();
    if (!mail.contains('@') || pass.text.length < 6) {
      setState(() => notice = 'Skriv e-post och ett lösenord med minst 6 tecken.');
      return;
    }
    setState(() {
      busy = true;
      notice = '';
    });
    try {
      final mode = await Cloud.login(email: mail, password: pass.text, create: create);
      if (!mounted) return;
      if (mode == 'cloud') {
        widget.state.signIn(mail);
        return;
      }
      setState(() => notice = mode);
    } catch (e) {
      if (mounted) setState(() => notice = 'Det gick inte just nu. Försök igen.');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _face() async {
    HapticFeedback.mediumImpact();
    final ok = await Biometrics.unlock(reason: 'Logga in i PawMatch');
    if (!mounted) return;
    final saved = widget.state.email;
    if (ok && saved.contains('@')) {
      widget.state.signIn(saved);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Första gången: logga in med e-post. Face ID fungerar nästa gång.')),
      );
    }
  }

  Future<void> _apple() async {
    HapticFeedback.mediumImpact();
    setState(() => busy = true);
    try {
      final cred = await SignInWithApple.getAppleIDCredential(
        scopes: [AppleIDAuthorizationScopes.email, AppleIDAuthorizationScopes.fullName],
      );
      var used = (cred.email != null && cred.email!.contains('@'))
          ? cred.email!
          : (widget.state.email.contains('@') ? widget.state.email : 'apple-${cred.userIdentifier ?? 'user'}@pawmatch.app');
      final token = cred.identityToken;
      if (token != null && Cloud.ready) {
        try {
          await Supabase.instance.client.auth.signInWithIdToken(
            provider: OAuthProvider.apple,
            idToken: token,
          );
          final sessionMail = Supabase.instance.client.auth.currentUser?.email;
          if (sessionMail != null && sessionMail.contains('@')) used = sessionMail;
        } catch (e) {
          debugPrint('Apple-koppling: $e');
        }
      }
      if (cred.givenName != null) widget.state.firstName = cred.givenName!;
      if (cred.familyName != null) widget.state.lastName = cred.familyName!;
      widget.state.signIn(used);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            duration: Duration(seconds: 5),
            content: Text('Apple-ID är påslagen i Xcode men den här TestFlight-versionen saknar den än. Använd e-post + Face ID tills nästa build.'),
          ),
        );
      }
    }
    if (mounted) setState(() => busy = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _cream,
      body: PawsBg(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 12, 22, 20),
                child: Column(
                  children: [
                    const WelcomeHero(size: 176),
                    const SizedBox(height: 8),
                    const Text.rich(
                      TextSpan(
                        style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: _ink, height: 1),
                        children: [
                          TextSpan(text: 'Paw'),
                          TextSpan(text: 'Match', style: TextStyle(color: _coral)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Stor som liten. Vän eller avel.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF3D4A57)),
                    ),
                    const SizedBox(height: 20),
                    TextField(controller: email, keyboardType: TextInputType.emailAddress, decoration: _field('E-post')),
                    const SizedBox(height: 10),
                    TextField(controller: pass, obscureText: true, decoration: _field('Lösenord')),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: _mode('Logga in', !create)),
                        const SizedBox(width: 8),
                        Expanded(child: _mode('Skapa konto', create)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _PressBtn(
                      color: _coral,
                      label: busy ? 'Väntar...' : (create ? 'Skapa konto' : 'Logga in'),
                      onTap: busy ? null : _go,
                    ),
                    if (notice.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(notice, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF8B3A32), fontWeight: FontWeight.w700, height: 1.3)),
                    ],
                    const SizedBox(height: 14),
                    const Row(
                      children: [
                        Expanded(child: Divider()),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          child: Text('eller', style: TextStyle(color: Color(0xFF8A7A70), fontWeight: FontWeight.w600)),
                        ),
                        Expanded(child: Divider()),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _PressBtn(
                      color: _ink,
                      label: 'Fortsätt med Apple-ID',
                      icon: Icons.apple,
                      onTap: busy ? null : _apple,
                    ),
                    if (bioOk) ...[
                      const SizedBox(height: 10),
                      _PressBtn(
                        color: Colors.white,
                        textColor: _ink,
                        border: _ink,
                        label: 'Face ID',
                        onTap: busy ? null : _face,
                      ),
                    ],
                    TextButton(
                      onPressed: () => setState(() => create = !create),
                      child: Text(
                        create ? 'Har redan konto? Logga in' : 'Ny här? Skapa konto',
                        style: const TextStyle(color: _coral, fontWeight: FontWeight.w800),
                      ),
                    ),
                    const Text(
                      'Genom att fortsätta godkänner du villkor och integritetspolicy.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: Color(0xFF3D4A57)),
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

  Widget _mode(String label, bool on) {
    return GestureDetector(
      onTap: busy
          ? null
          : () => setState(() {
                create = label == 'Skapa konto';
                notice = '';
              }),
      child: Container(
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: on ? _ink : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: on ? _ink : const Color(0xFFE2C4B3)),
        ),
        child: Text(label, style: TextStyle(fontWeight: FontWeight.w800, color: on ? Colors.white : _ink)),
      ),
    );
  }

  InputDecoration _field(String label) => InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: _ink, fontWeight: FontWeight.w600, fontSize: 15),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFE2C4B3), width: 1.6),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: _coral, width: 2.2),
        ),
      );
}

class _PressBtn extends StatefulWidget {
  const _PressBtn({
    required this.color,
    required this.label,
    this.onTap,
    this.icon,
    this.textColor = Colors.white,
    this.border,
  });
  final Color color;
  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final Color textColor;
  final Color? border;

  @override
  State<_PressBtn> createState() => _PressBtnState();
}

class _PressBtnState extends State<_PressBtn> {
  bool down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.onTap == null ? null : (_) => setState(() => down = true),
      onTapCancel: () => setState(() => down = false),
      onTapUp: (_) => setState(() => down = false),
      onTap: widget.onTap == null
          ? null
          : () {
              HapticFeedback.lightImpact();
              widget.onTap!();
            },
      child: AnimatedScale(
        scale: down ? 0.97 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: double.infinity,
          height: 54,
          decoration: BoxDecoration(
            color: widget.color,
            borderRadius: BorderRadius.circular(18),
            border: widget.border == null ? null : Border.all(color: widget.border!, width: 1.5),
            boxShadow: down
                ? []
                : [BoxShadow(color: widget.color.withValues(alpha: 0.28), blurRadius: 16, offset: const Offset(0, 8))],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, color: widget.textColor),
                const SizedBox(width: 8),
              ],
              Text(widget.label, style: TextStyle(color: widget.textColor, fontSize: 16, fontWeight: FontWeight.w800)),
            ],
          ),
        ),
      ),
    );
  }
}
