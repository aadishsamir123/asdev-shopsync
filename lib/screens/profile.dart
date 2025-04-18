import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '/screens/sign_out.dart';
import '/widgets/loading_spinner.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class GridPainter extends CustomPainter {
  final bool isDark;

  GridPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1)
      ..strokeWidth = 1;

    for (var i = 0; i < size.width; i += 20) {
      canvas.drawLine(
        Offset(i.toDouble(), 0),
        Offset(i.toDouble(), size.height),
        paint,
      );
    }

    for (var i = 0; i < size.height; i += 20) {
      canvas.drawLine(
        Offset(0, i.toDouble()),
        Offset(size.width, i.toDouble()),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _isEditing = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.light,
      ),
    );
    _nameController.text = _auth.currentUser?.displayName ?? '';
  }

  @override
  void dispose() {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
    );
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _auth.currentUser?.updateDisplayName(_nameController.text.trim());
      await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .update({'displayName': _nameController.text.trim()});

      setState(() => _isEditing = false);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() => _errorMessage = 'Error updating profile: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _signOut() async {
    final shouldSignOut = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Sign Out'),
            content: const Text('Are you sure you want to sign out?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child:
                    Text('Cancel', style: TextStyle(color: Colors.grey[700])),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red[700]),
                child: const Text('Sign Out'),
              ),
            ],
          ),
        ) ??
        false;

    if (shouldSignOut) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const SignOutScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    final email = user?.email ?? 'No email';
    final displayName = user?.displayName ?? 'User';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Theme(
      data: Theme.of(context).copyWith(
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: isDark ? Colors.grey[800] : Colors.grey[50],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.green[700]!, width: 2),
          ),
          // Add shadow effect
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
      child: Scaffold(
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverAppBar.large(
              expandedHeight: 280,
              // Increased height
              pinned: true,
              backgroundColor: isDark ? Colors.grey[900] : Colors.green[800],
              leading: !_isEditing
                  ? Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.grey[800]!.withValues(alpha: 0.5)
                              : Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark
                                ? Colors.grey[700]!
                                : Colors.white.withValues(alpha: 0.3),
                          ),
                        ),
                        child: IconButton(
                          icon:
                              const FaIcon(FontAwesomeIcons.arrowLeft, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                          tooltip: 'Go Back',
                        ),
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.all(0.0),
                    ),
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Gradient background with pattern
                    ShaderMask(
                      shaderCallback: (bounds) => LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: isDark
                            ? [Colors.grey[900]!, Colors.grey[850]!]
                            : [Colors.green[800]!, Colors.green[700]!],
                      ).createShader(bounds),
                      blendMode: BlendMode.dstIn,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: isDark
                                ? [Colors.grey[900]!, Colors.grey[850]!]
                                : [Colors.green[800]!, Colors.green[600]!],
                          ),
                        ),
                      ),
                    ),
                    // Animated pattern overlay
                    Opacity(
                      opacity: 0.05,
                      child: CustomPaint(
                        painter: GridPainter(isDark: isDark),
                      ),
                    ),
                    // Profile content
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 32),
                          // Enhanced avatar with gradient border
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: isDark
                                    ? [Colors.grey[800]!, Colors.grey[600]!]
                                    : [Colors.green[400]!, Colors.green[600]!],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 15,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Hero(
                              tag: 'profile-avatar',
                              child: CircleAvatar(
                                radius: 50,
                                backgroundColor:
                                    isDark ? Colors.grey[800] : Colors.white,
                                child: Text(
                                  displayName.isNotEmpty
                                      ? displayName[0].toUpperCase()
                                      : 'U',
                                  style: TextStyle(
                                    fontSize: 40,
                                    fontWeight: FontWeight.bold,
                                    color: isDark
                                        ? Colors.white
                                        : Colors.green[800],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Enhanced name display
                          Text(
                            displayName,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              shadows: [
                                Shadow(
                                  color: Colors.black38,
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Enhanced edit button
              actions: [
                if (!_isEditing)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.grey[800]!.withValues(alpha: 0.5)
                            : Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark
                              ? Colors.grey[700]!
                              : Colors.white.withValues(alpha: 0.3),
                        ),
                      ),
                      child: IconButton(
                        icon: const FaIcon(FontAwesomeIcons.pen, color: Colors.white),
                        onPressed: () => setState(() => _isEditing = true),
                        tooltip: 'Edit Profile',
                      ),
                    ),
                  ),
              ],
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                child: Column(
                  children: [
                    if (_errorMessage != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 24),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.red[900]!.withValues(alpha: 0.2)
                              : Colors.red[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark ? Colors.red[800]! : Colors.red[200]!,
                          ),
                        ),
                        child: Row(
                          children: [
                            FaIcon(FontAwesomeIcons.squareXmark,
                                color:
                                    isDark ? Colors.red[300] : Colors.red[700]),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.red[300]
                                      : Colors.red[700],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Profile Information Card
                    Card(
                      elevation: isDark ? 0 : 2,
                      color: isDark ? Colors.grey[850] : Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                          width: 1,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Account Information',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color:
                                      isDark ? Colors.white : Colors.green[800],
                                ),
                              ),
                              const SizedBox(height: 24),
                              Text(
                                'Display Name',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isDark
                                      ? Colors.white70
                                      : Colors.grey[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              _isEditing
                                  ? TextFormField(
                                      controller: _nameController,
                                      decoration: InputDecoration(
                                        hintText: 'Enter your name',
                                        suffixIcon: Icon(FontAwesomeIcons.user,
                                            color: isDark
                                                ? Colors.white70
                                                : Colors.green[800]),
                                      ),
                                      validator: (value) {
                                        if (value == null ||
                                            value.trim().isEmpty) {
                                          return 'Please enter a display name';
                                        }
                                        return null;
                                      },
                                    )
                                  : ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      leading: CircleAvatar(
                                        backgroundColor: isDark
                                            ? Colors.green[900]
                                            : Colors.green[50],
                                        child: FaIcon(FontAwesomeIcons.user,
                                            color: isDark
                                                ? Colors.green[200]
                                                : Colors.green[800]),
                                      ),
                                      title: Text(
                                        displayName,
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w500,
                                          color: isDark ? Colors.white : null,
                                        ),
                                      ),
                                      subtitle: Text(
                                        'Display Name',
                                        style: TextStyle(
                                          color: isDark ? Colors.white60 : null,
                                        ),
                                      ),
                                    ),
                              const Divider(height: 32),
                              Text(
                                'Email Address',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isDark
                                      ? Colors.white70
                                      : Colors.grey[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: CircleAvatar(
                                  backgroundColor: isDark
                                      ? Colors.blue[900]
                                      : Colors.blue[50],
                                  child: FaIcon(FontAwesomeIcons.envelope,
                                      color: isDark
                                          ? Colors.blue[200]
                                          : Colors.blue[800]),
                                ),
                                title: Text(
                                  email,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                    color: isDark ? Colors.white : null,
                                  ),
                                ),
                                subtitle: Text(
                                  'Email (cannot be changed)',
                                  style: TextStyle(
                                    color: isDark ? Colors.white60 : null,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Activity Card
                    Card(
                      elevation: isDark ? 0 : 2,
                      color: isDark ? Colors.grey[850] : Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                          width: 1,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Account Activity',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color:
                                    isDark ? Colors.white : Colors.green[800],
                              ),
                            ),
                            const SizedBox(height: 16),
                            StreamBuilder<QuerySnapshot>(
                              stream: _firestore
                                  .collection('lists')
                                  .where('members', arrayContains: user?.uid)
                                  .snapshots(),
                              builder: (context, snapshot) {
                                int listCount = snapshot.hasData
                                    ? snapshot.data!.docs.length
                                    : 0;
                                return ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: CircleAvatar(
                                    backgroundColor: isDark
                                        ? Colors.amber[900]
                                        : Colors.amber[50],
                                    child: FaIcon(FontAwesomeIcons.listUl,
                                        color: isDark
                                            ? Colors.amber[200]
                                            : Colors.amber[800]),
                                  ),
                                  title: Text(
                                    '$listCount shopping lists',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w500,
                                      color: isDark ? Colors.white : null,
                                    ),
                                  ),
                                  subtitle: Text(
                                    'Lists you have access to',
                                    style: TextStyle(
                                      color: isDark ? Colors.white60 : null,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),

                    if (_isEditing) ...[
                      const SizedBox(height: 32),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () =>
                                  setState(() => _isEditing = false),
                              style: OutlinedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                side: BorderSide(
                                  color: isDark
                                      ? Colors.grey[600]!
                                      : Colors.grey[400]!,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _updateProfile,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green[700],
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                elevation: isDark ? 0 : 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: CustomLoadingSpinner(
                                        color: Colors.white,
                                        size: 24.0,
                                      ),
                                    )
                                  : const Text('Save Changes'),
                            ),
                          ),
                        ],
                      ),
                    ],

                    // Sign Out Button
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => {_signOut()},
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: BorderSide(
                            color: isDark ? Colors.red[300]! : Colors.red[300]!,
                          ),
                          foregroundColor:
                              isDark ? Colors.red[300] : Colors.red[700],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const FaIcon(FontAwesomeIcons.rightFromBracket),
                        label: const Text('Sign Out'),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
