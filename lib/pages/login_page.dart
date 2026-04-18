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
                  style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                  decoration: InputDecoration(
                    labelText: "Password",
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 30),

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

                // DIVIDER (Updated to match the video)
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
                  // ✅ Changed to local asset path
                  assetPath: "assets/images/google_logo.png",
                  onPressed: isLoading ? null : _signInWithGoogle,
                ),

                const SizedBox(height: 16),

                _buildFullWidthSocialButton(
                  context: context,
                  text: "Continue with Microsoft",
                  // ✅ Changed to local asset path
                  assetPath: "assets/images/microsoft_logo.png",
                  onPressed: isLoading ? null : _signInWithMicrosoft,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- NEW FULL-WIDTH HELPER WIDGET ---
  // ✅ Changed 'iconUrl' to 'assetPath'
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
            // ✅ Changed Image.network to Image.asset
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

  // ✅ THE ULTIMATE BYPASS FIX (Preserved!)
  // ✅ THE ULTIMATE BYPASS FIX (V7 SYNTAX)
  Future<void> _signInWithGoogle() async {
    setState(() => isLoading = true);
    try {
      if (kIsWeb) {
        final provider = GoogleAuthProvider();
        await FirebaseAuth.instance.signInWithPopup(provider);
      } else {

        // 1. HARDCODE WEB CLIENT ID USING V7 INITIALIZE
        await GoogleSignIn.instance.initialize(
          serverClientId: '1078975084440-pi5isfm1t6rtm0jo1n0spaf4qe0801oo.apps.googleusercontent.com',
        );

        // 2. V7 USES .authenticate() INSTEAD OF .signIn()
        final GoogleSignInAccount? gUser = await GoogleSignIn.instance.authenticate();

        if (gUser == null) {
          if (mounted) setState(() => isLoading = false);
          _showError("popup-closed-by-user");
          return;
        }

        // 3. V7 AUTHENTICATION IS SYNCHRONOUS (No 'await' allowed here!)
        final GoogleSignInAuthentication gAuth = gUser.authentication;

        // 4. V7 REMOVED accessToken, FIREBASE ONLY NEEDS idToken
        final credential = GoogleAuthProvider.credential(
          idToken: gAuth.idToken,
        );

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

    String message = "Login Failed: $code";

    if (code.contains('user-not-found')) message = "No user found for that email.";
    if (code.contains('wrong-password')) message = "Wrong password provided.";
    if (code.contains('popup-closed-by-user') || code.contains('cancelled')) message = "Sign-in was cancelled.";

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}