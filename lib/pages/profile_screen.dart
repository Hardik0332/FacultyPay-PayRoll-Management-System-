import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // State variables
  bool _isLoading = true;
  String _name = '';
  String _email = '';
  String _role = '';
  String _phone = '';

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        // Fetch the user document from the unified 'users' collection
        DocumentSnapshot userDoc =
        await _firestore.collection('users').doc(currentUser.uid).get();

        if (userDoc.exists) {
          setState(() {
            _name = userDoc.get('name') ?? 'No Name Set';
            _email = userDoc.get('email') ?? currentUser.email ?? '';
            _role = userDoc.get('role') ?? 'faculty'; // Default to faculty
            _phone = userDoc.get('phone') ?? 'No Phone Set';
            _isLoading = false;
          });
        } else {
          // Fallback if document doesn't exist yet
          setState(() {
            _email = currentUser.email ?? '';
            _role = 'faculty';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print("Error fetching user data: $e");
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load profile data.')),
      );
    }
  }

  Future<void> _signOut() async {
    await _auth.signOut();
    // Replace '/login' with your actual login route name
    Navigator.of(context).pushReplacementNamed('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: _role == 'admin' ? Colors.deepPurple : Colors.blue,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // --- HEADER SECTION (Shared by both) ---
            CircleAvatar(
              radius: 50,
              backgroundColor: _role == 'admin'
                  ? Colors.deepPurple.shade100
                  : Colors.blue.shade100,
              child: Icon(
                _role == 'admin' ? Icons.admin_panel_settings : Icons.person,
                size: 50,
                color: _role == 'admin' ? Colors.deepPurple : Colors.blue,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _name,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            // Dynamic Role Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _role == 'admin' ? Colors.red.shade100 : Colors.green.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _role.toUpperCase(),
                style: TextStyle(
                  color: _role == 'admin' ? Colors.red.shade900 : Colors.green.shade900,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            const SizedBox(height: 32),

            // --- SHARED INFO SECTION ---
            _buildInfoCard(Icons.email, 'Email', _email),
            const SizedBox(height: 12),
            _buildInfoCard(Icons.phone, 'Phone', _phone),
            const SizedBox(height: 32),

            // --- CONDITIONAL ADMIN UI ---
            if (_role == 'admin') ...[
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Admin Controls',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 12),
              _buildActionTile(
                icon: Icons.manage_accounts,
                title: 'Manage Faculty Accounts',
                onTap: () {
                  // Navigate to user management screen
                },
              ),
              _buildActionTile(
                icon: Icons.security,
                title: 'System Permissions',
                onTap: () {
                  // Navigate to permissions screen
                },
              ),
            ],

            // --- CONDITIONAL FACULTY UI ---
            if (_role == 'faculty') ...[
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Faculty Details',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 12),
              _buildActionTile(
                icon: Icons.book,
                title: 'My Subjects',
                onTap: () {
                  // Navigate to subjects
                },
              ),
              _buildActionTile(
                icon: Icons.history,
                title: 'Attendance History',
                onTap: () {
                  // Navigate to history
                },
              ),
            ],

            const SizedBox(height: 40),

            // --- LOGOUT BUTTON ---
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _signOut,
                icon: const Icon(Icons.logout),
                label: const Text('Sign Out'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper widget to keep the build method clean
  Widget _buildInfoCard(IconData icon, String title, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey.shade600),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
              Text(
                value,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Helper widget for conditional actions
  Widget _buildActionTile({required IconData icon, required String title, required VoidCallback onTap}) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: ListTile(
        leading: Icon(icon, color: _role == 'admin' ? Colors.deepPurple : Colors.blue),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}