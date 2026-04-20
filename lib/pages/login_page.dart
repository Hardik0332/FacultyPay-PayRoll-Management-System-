import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: 450,
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
              boxShadow: const [
                BoxShadow(color: Colors.black26, blurRadius: 20, offset: Offset(0, 10))
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.school, size: 70, color: theme.primaryColor),
                const SizedBox(height: 20),
                const Text("FacultyPay", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                const Text("Login to your account", style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 40),

                // EMAIL FIELD
                TextField(
                  controller: emailController,
                  // ✅ Jumps to the password field when you press Enter
                  textInputAction: TextInputAction.next,
                  style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                  decoration: InputDecoration(
                    labelText: "Email",
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 20),

                // PASSWORD FIELD
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  // ✅ Tells the keyboard this is the final input
                  textInputAction: TextInputAction.done,
                  // ✅ Automatically runs the login function when Enter is pressed
                  onSubmitted: (_) {
                    if (!isLoading) {
                      _handleEmailLogin();
                    }
                  },
                  style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                  decoration: InputDecoration(
                    labelText: "Password",
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),

                // FORGOT PASSWORD BUTTON
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _showForgotPasswordDialog,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      "Forgot Password?",
                      style: TextStyle(color: theme.primaryColor, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // STANDARD LOGIN BUTTON
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primaryColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: isLoading ? null : _handleEmailLogin,
                    child: isLoading
                        ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3)
                    )
                        : const Text("Login", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),

                const SizedBox(height: 30),

                // DIVIDER
                Row(
                  children: [
                    Expanded(child: Divider(color: theme.dividerColor.withValues(alpha: 0.2))),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text("OR", style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                    Expanded(child: Divider(color: theme.dividerColor.withValues(alpha: 0.2))),
                  ],
                ),

                const SizedBox(height: 30),

                // FULL-WIDTH SSO BUTTONS
                _buildFullWidthSocialButton(
                  context: context,
                  text: "Continue with Google",
                  assetPath: "assets/images/google.png",
                  onPressed: isLoading ? null : _signInWithGoogle,
                ),

                const SizedBox(height: 16),

                _buildFullWidthSocialButton(
                  context: context,
                  text: "Continue with Microsoft",
                  assetPath: "assets/images/microsoft.png",
                  onPressed: isLoading ? null : _signInWithMicrosoft,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- FULL-WIDTH HELPER WIDGET ---
  Widget _buildFullWidthSocialButton({required BuildContext context, required String text, required String assetPath, required VoidCallback? onPressed}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SizedBox(
      width: double.infinity,
      height: 55,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          backgroundColor: isDark ? Colors.grey.shade900 : Colors.white,
          side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.2)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              assetPath,
              height: 22,
              width: 22,
              errorBuilder: (context, error, stackTrace) => const Icon(Icons.language, size: 22, color: Colors.grey),
            ),
            const SizedBox(width: 12),
            Text(
                text,
                style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontSize: 16,
                    fontWeight: FontWeight.bold
                )
            ),
          ],
        ),
      ),
    );
  }

  // --- AUTHENTICATION LOGIC ---

  Future<void> _handleEmailLogin() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please enter both email and password")));
      return;
    }

    setState(() => isLoading = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      if (mounted) setState(() => isLoading = false);
      _showError(e.code);
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
      _showError(e.toString());
    }
  }

  // FORGOT PASSWORD LOGIC
  void _showForgotPasswordDialog() {
    final TextEditingController resetEmailController = TextEditingController(text: emailController.text.trim());
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: theme.cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text("Reset Password", style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Enter your email address and we will send you a secure link to reset your password.",
                style: TextStyle(color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.8)),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: resetEmailController,
                decoration: InputDecoration(
                  labelText: "Email",
                  prefixIcon: const Icon(Icons.email_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () async {
                final email = resetEmailController.text.trim();
                if (email.isEmpty) return;

                Navigator.pop(context);

                try {
                  await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Reset link sent! Please check your email inbox.", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        backgroundColor: Colors.green,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                } on FirebaseAuthException catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(_getFriendlyErrorMessage(e.code)),
                        backgroundColor: Colors.redAccent,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                }
              },
              child: const Text("Send Link", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  // V7 GOOGLE SIGN-IN
  Future<void> _signInWithGoogle() async {
    setState(() => isLoading = true);
    try {
      if (kIsWeb) {
        final provider = GoogleAuthProvider();
        await FirebaseAuth.instance.signInWithPopup(provider);
      } else {
        await GoogleSignIn.instance.initialize(
          serverClientId: '1078975084440-pi5isfm1t6rtm0jo1n0spaf4qe0801oo.apps.googleusercontent.com',
        );

        final GoogleSignInAccount? gUser = await GoogleSignIn.instance.authenticate();

        if (gUser == null) {
          if (mounted) setState(() => isLoading = false);
          _showError("popup-closed-by-user");
          return;
        }

        final GoogleSignInAuthentication gAuth = gUser.authentication;
        final credential = GoogleAuthProvider.credential(idToken: gAuth.idToken);

        await FirebaseAuth.instance.signInWithCredential(credential);
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);

      if (e is FirebaseAuthException) {
        _showError(e.code);
      } else {
        _showError("popup-closed-by-user");
      }
    }
  }

  Future<void> _signInWithMicrosoft() async {
    setState(() => isLoading = true);
    try {
      final provider = OAuthProvider('microsoft.com');
      provider.setCustomParameters({'prompt': 'select_account'});

      if (kIsWeb) {
        await FirebaseAuth.instance.signInWithPopup(provider);
      } else {
        await FirebaseAuth.instance.signInWithProvider(provider);
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);

      if (e is FirebaseAuthException) {
        _showError(e.code);
      } else {
        _showError("popup-closed-by-user");
      }
    }
  }

  void _showError(String code) {
    if (!mounted) return;
    setState(() => isLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_getFriendlyErrorMessage(code))),
    );
  }

  String _getFriendlyErrorMessage(String code) {
    if (code.contains('user-not-found')) return "No account found for that email address.";
    if (code.contains('wrong-password')) return "Incorrect password. Please try again.";
    if (code.contains('invalid-email')) return "Please enter a valid email address.";
    if (code.contains('popup-closed-by-user') || code.contains('cancelled')) return "Sign-in was cancelled.";
    if (code.contains('too-many-requests')) return "Too many failed attempts. Please try resetting your password.";
    return "Authentication Failed: $code";
  }
}