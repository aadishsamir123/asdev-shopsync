import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import '/screens/list_view.dart';
import '/screens/sign_out.dart';
import '/widgets/loading_spinner.dart';

class TutorialStep extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const TutorialStep({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withAlpha(25),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: color,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey[400]
                      : Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class AppBarClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0, size.height - 16);

    path.quadraticBezierTo(
      size.width / 4,
      size.height,
      size.width / 2,
      size.height,
    );

    path.quadraticBezierTo(
      size.width * 3 / 4,
      size.height,
      size.width,
      size.height - 16,
    );

    path.lineTo(size.width, 0);
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class _HomeScreenState extends State<HomeScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final _newListController = TextEditingController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  double _dragStartX = 0;

  void _handleDragStart(DragStartDetails details) {
    _dragStartX = details.globalPosition.dx;
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    if (_dragStartX < 50) {
      double dragDistance = details.globalPosition.dx - _dragStartX;
      if (dragDistance > 0) {
        _scaffoldKey.currentState?.openDrawer();
      }
    }
  }

  Future<void> _signOut() async {
    try {
      final shouldSignOut = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Sign Out'),
          content: const Text('Are you sure you want to sign out?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel', style: TextStyle(color: Colors.grey[700])),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red[700]),
              child: const Text('Sign Out'),
            ),
          ],
        ),
      );

      if (shouldSignOut == true) {
        await _auth.signOut();
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const SignOutScreen()),
        );
      }
    } catch (error, stackTrace) {
      await Sentry.captureException(
        error,
        stackTrace: stackTrace,
        hint: Hint.withMap({'action': 'sign_out'}),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to sign out. Please try again.')),
      );
    }
  }

  Future<void> _createList() async {
    try {
      if (_newListController.text.trim().isEmpty) return;

      final user = _auth.currentUser!;
      final transaction = {'name': _newListController.text.trim()};
      
      final sentryTransaction = Sentry.startTransaction(
        'create_list',
        'db.operation',
        bindToScope: true,
      );

      await _firestore.collection('lists').add({
        ...transaction,
        'createdBy': user.uid,
        'createdByName': user.displayName,
        'createdAt': FieldValue.serverTimestamp(),
        'members': [user.uid],
      });

      await sentryTransaction.finish();

      _newListController.clear();
      if (!mounted) return;
      Navigator.pop(context);
    } catch (error, stackTrace) {
      await Sentry.captureException(
        error,
        stackTrace: stackTrace,
        hint: Hint.withMap({
          'action': 'create_list',
          'list_name': _newListController.text,
        }),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to create list. Please try again.')),
      );
    }
  }

  Widget _buildReviewBanner() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.amber[100]!,
            Colors.amber[50]!,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withAlpha(51),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: Colors.amber[200]!,
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber[200],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      FontAwesomeIcons.star,
                      color: Colors.amber[800],
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Give testing feedback',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'To get my app on the Play Store, please leave feedback.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[800],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () async {
                    final Uri url = Uri.parse(
                      'https://play.google.com/store/apps/details?id=com.aadishsamir.shopsync',
                    );
                    if (!await launchUrl(url,
                        mode: LaunchMode.externalApplication)) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Could not open Play Store')),
                      );
                    }
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    backgroundColor: Colors.amber[400],
                    foregroundColor: Colors.black87,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Give Feedback',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
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

  Widget _buildDrawerItem({
    IconData? icon,
    SvgPicture? svg,
    required String title,
    required VoidCallback onTap,
    Color? color,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (color ?? Colors.grey).withAlpha(25),
            borderRadius: BorderRadius.circular(8),
          ),
          child: svg ??
              Icon(
                icon,
                color: color ?? Colors.grey[600],
                size: 20,
              ),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: color ??
                (Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[300]
                    : Colors.grey[800]),
          ),
        ),
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // final l10n = AppLocalizations.of(context);

    PreferredSize buildCustomAppBar(BuildContext context) {
      return PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight + 10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: Theme.of(context).brightness == Brightness.dark
                  ? [Colors.grey[900]!, Colors.grey[850]!]
                  : [Colors.green[800]!, Colors.green[600]!],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(25),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipPath(
            clipper: AppBarClipper(),
            child: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              foregroundColor: Colors.white,
              leading: Material(
                color: Colors.transparent,
                child: IconButton(
                  icon: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(51),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.menu),
                  ),
                  onPressed: () {
                    _scaffoldKey.currentState?.openDrawer();
                  },
                ),
              ),
              title: Row(
                children: [
                  Image.asset(
                    'assets/logos/shopsync.png',
                    height: 32,
                    width: 32,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'ShopSync',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return GestureDetector(
      onHorizontalDragStart: _handleDragStart,
      onHorizontalDragUpdate: _handleDragUpdate,
      child: Scaffold(
        key: _scaffoldKey,
        appBar: buildCustomAppBar(context),
        drawer: Drawer(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: Theme.of(context).brightness == Brightness.dark
                    ? [Colors.grey[900]!, Colors.grey[850]!]
                    : [Colors.green[800]!, Colors.green[700]!],
              ),
            ),
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + 24,
                    bottom: 32,
                    left: 20,
                    right: 20,
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white.withAlpha(204),
                              Colors.white.withAlpha(127),
                            ],
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 40,
                          backgroundColor:
                              isDark ? Colors.grey[800] : Colors.green[100],
                          child: Text(
                            (_auth.currentUser?.displayName?.isNotEmpty == true)
                                ? _auth.currentUser!.displayName![0]
                                    .toUpperCase()
                                : 'U',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.green[800],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _auth.currentUser?.displayName ?? 'User',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withAlpha(25),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _auth.currentUser?.email ?? '',
                          style: TextStyle(
                            color: Colors.white.withAlpha(229),
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[900] : Colors.white,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(32),
                        topRight: Radius.circular(32),
                      ),
                    ),
                    child: StreamBuilder<QuerySnapshot>(
                      stream: _firestore
                          .collection('lists')
                          .where('members',
                              arrayContains: _auth.currentUser?.uid)
                          .orderBy('createdAt', descending: true)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CustomLoadingSpinner(
                              color: Colors.green,
                              size: 60.0,
                            ),
                          );
                        }

                        return CustomScrollView(
                          slivers: [
                            SliverToBoxAdapter(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildReviewBanner(),
                                  Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Text(
                                      'My Lists',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: isDark
                                            ? Colors.grey[300]
                                            : Colors.grey[800],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (!snapshot.hasData ||
                                snapshot.data!.docs.isEmpty)
                              SliverFillRemaining(
                                child: Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      FaIcon(
                                        FontAwesomeIcons.listUl,
                                        size: 48,
                                        color: Colors.grey[400],
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'No lists yet',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            else
                              SliverList(
                                delegate: SliverChildBuilderDelegate(
                                  (context, index) {
                                    final doc = snapshot.data!.docs[index];
                                    final listName =
                                        doc['name'] ?? 'Unnamed List';

                                    return Container(
                                      margin: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.transparent,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: ListTile(
                                        leading: Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.grey.withAlpha(25),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: FaIcon(
                                            FontAwesomeIcons.cartShopping,
                                            color: Colors.grey[600],
                                            size: 18,
                                          ),
                                        ),
                                        title: Text(
                                          listName,
                                          style: TextStyle(
                                            color: isDark
                                                ? Colors.grey[300]
                                                : Colors.grey[800],
                                          ),
                                        ),
                                        onTap: () {
                                          Navigator.pop(context);
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  ListViewScreen(
                                                listId: doc.id,
                                                listName: listName,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    );
                                  },
                                  childCount: snapshot.data!.docs.length,
                                ),
                              ),
                            SliverToBoxAdapter(
                              child: Column(
                                children: [
                                  Divider(
                                    height: 32,
                                    color: isDark
                                        ? Colors.grey[700]
                                        : Colors.grey[300],
                                    thickness: 2,
                                  ),
                                  _buildDrawerItem(
                                    icon: FontAwesomeIcons.plus,
                                    title: 'Create New List',
                                    onTap: () {
                                      showDialog(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          backgroundColor: isDark
                                              ? Colors.black
                                              : Colors.white,
                                          title: Text(
                                            'Create New List',
                                            style: TextStyle(
                                              color: isDark
                                                  ? Colors.white
                                                  : Colors.black,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          content: TextField(
                                            controller: _newListController,
                                            autofocus: true,
                                            style: TextStyle(
                                              color: isDark
                                                  ? Colors.white
                                                  : Colors.black,
                                            ),
                                            decoration: InputDecoration(
                                              hintText: 'List name',
                                              hintStyle: TextStyle(
                                                color: isDark
                                                    ? Colors.grey[400]
                                                    : Colors.grey[700],
                                              ),
                                              filled: true,
                                              fillColor: isDark
                                                  ? const Color(0xFF1E1E1E)
                                                  : const Color(0xFFF5F5F5),
                                              enabledBorder: OutlineInputBorder(
                                                borderSide: BorderSide(
                                                  color: isDark
                                                      ? Colors.grey[600]!
                                                      : Colors.grey[400]!,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              focusedBorder: OutlineInputBorder(
                                                borderSide: BorderSide(
                                                  color: Colors.green.shade400,
                                                  width: 2,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                            ),
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context),
                                              style: TextButton.styleFrom(
                                                foregroundColor: isDark
                                                    ? Colors.grey[400]
                                                    : Colors.grey[700],
                                              ),
                                              child: const Text('Cancel'),
                                            ),
                                            ElevatedButton(
                                              onPressed: _createList,
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    Colors.green[800],
                                                foregroundColor: Colors.white,
                                              ),
                                              child: const Text('Create'),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                  _buildDrawerItem(
                                    icon: FontAwesomeIcons.user,
                                    title: 'My Profile',
                                    onTap: () {
                                      Navigator.pop(context);
                                      Navigator.pushNamed(
                                        context, '/profile'
                                      );
                                    },
                                  ),
                                  _buildDrawerItem(
                                    icon: FontAwesomeIcons.scroll,
                                    title: 'Release Notes',
                                    onTap: () async {
                                      final Uri url = Uri.parse(
                                          'https://github.com/aadishsamir123/asdev-shopsync/releases');
                                      if (!await launchUrl(url)) {
                                        if (!mounted) return;
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                                'Could not open release notes'),
                                          ),
                                        );
                                      }
                                      if (!mounted) return;
                                      Navigator.pop(context);
                                    },
                                  ),
                                  _buildDrawerItem(
                                    svg: SvgPicture.string(
                                      '''
                                      <svg xmlns="http://www.w3.org/2000/svg" width="248" height="248" viewBox="0 0 248 248" fill="none">
<path d="M163.024 177.312C157.024 177.312 151.667 175.514 147.239 171.995C141.954 167.851 137.739 161.674 137.597 154.402C137.525 150.727 141.525 150.727 141.525 150.727C141.525 150.727 148.025 150.649 151.167 150.649C154.31 150.727 155.238 155.106 155.381 156.2C156.595 166.053 162.166 170.353 166.452 172.308C169.023 173.481 168.38 177.156 163.024 177.312Z" fill="white"/>
<path d="M109.1 127.248C103.816 126.626 95.962 126.082 90.8924 124.839C82.6811 122.819 82.8953 115.438 83.2523 113.03C84.252 105.804 86.8939 99.1224 90.9638 92.9069C96.0334 85.2929 103.317 78.6112 112.67 73.1726C130.235 62.9947 154.798 57.323 181.788 57.323C201.567 57.323 222.202 59.8869 222.416 59.8869C224.273 60.12 225.63 61.907 225.558 63.927C225.487 65.9471 224.059 67.5009 222.202 67.6563C219.203 67.5786 216.276 67.5786 213.491 67.5786C186.001 67.5786 166.437 71.3079 151.87 79.3881C137.518 87.3129 127.522 99.4332 120.739 117.381C120.025 118.934 117.668 128.18 109.1 127.248Z" fill="white"/>
<path d="M133.089 201.326C119.451 201.326 106.594 195.437 96.863 184.681C88.6235 175.574 83.6513 166.388 82.7279 154.611C82.1597 146.917 85.5692 144.248 90.1862 144.719C93.3825 145.033 103.327 145.504 109.009 146.682C113.271 147.545 116.112 149.901 116.823 154.768C120.587 180.677 136.924 190.884 146.655 193.082C148.36 193.475 149.426 194.574 149.355 196.537C149.284 198.421 148.005 199.991 146.3 200.305C141.967 201.012 137.421 201.326 133.089 201.326Z" fill="white"/>
<path d="M94.2244 224.321C84.5472 224.321 75.0835 222.782 72.3796 222.296C60.9946 220.27 51.4598 216.786 43.2769 211.6C23.7091 199.203 11.8972 177.326 10.4741 151.397C10.1183 145.239 9.3356 133.49 23.9937 134.381C30.0419 134.705 39.6479 137.622 46.4077 139.567C54.8041 141.917 58.86 148.399 58.86 154.8C58.86 191.343 91.9474 215.489 106.392 215.489C112.583 215.489 110.306 222.134 107.602 222.863C102.834 224.159 96.7148 224.321 94.2244 224.321Z" fill="white"/>
<path d="M43.75 116.947C38.0259 115.921 32.445 113.554 27.0071 112.213C10.1926 108.031 13.0546 91.0665 14.6287 86.4112C29.9407 41.3568 78.5238 26.2861 117.734 22.262C154.654 18.4746 193.292 21.394 229.282 31.4149C232.216 32.2039 241.303 34.4132 236.079 39.8576C232.788 43.2505 219.98 39.6998 216.546 39.4631C195.438 37.885 174.545 37.6483 153.509 40.8834C131.257 44.2763 108.361 51.2987 89.972 66.1328C81.0997 73.3131 73.3006 82.4659 68.0774 93.2758C66.7179 96.1164 65.6447 98.957 64.7145 101.798C63.7843 104.796 60.2783 119.867 43.75 116.947Z" fill="white"/>
<path d="M137.892 125.638C141.043 111.538 155.044 89.1945 198.377 90.7355C208.318 91.0437 203.768 97.8239 198.867 97.6698C174.365 96.8223 162.744 112.617 156.654 128.643C154.694 133.805 150.213 134.576 144.613 133.651C140.693 132.958 136.422 132.496 137.892 125.638Z" fill="white"/>
</svg>
''',
                                      width: 20,
                                      height: 20,
                                      colorFilter: ColorFilter.mode(
                                        Colors.grey[600] ?? Colors.grey,
                                        BlendMode.srcIn,
                                      ),
                                    ),
                                    title: 'Crowdin',
                                    onTap: () async {
                                      final Uri url = Uri.parse(
                                          'https://crowdin.com/project/as-shopsync');
                                      if (!await launchUrl(url)) {
                                        if (!mounted) return;
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                                'Could not open GitHub page'),
                                          ),
                                        );
                                      }
                                      if (!mounted) return;
                                      Navigator.pop(context);
                                    },
                                  ),
                                  _buildDrawerItem(
                                    icon: FontAwesomeIcons.github,
                                    title: 'GitHub',
                                    onTap: () async {
                                      final Uri url = Uri.parse(
                                          'https://github.com/aadishsamir123/asdev-shopsync');
                                      if (!await launchUrl(url)) {
                                        if (!mounted) return;
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                                'Could not open GitHub page'),
                                          ),
                                        );
                                      }
                                      if (!mounted) return;
                                      Navigator.pop(context);
                                    },
                                  ),
                                  _buildDrawerItem(
                                    icon: FontAwesomeIcons.rightFromBracket,
                                    title: 'Sign Out',
                                    onTap: _signOut,
                                    color: Colors.red[400],
                                  ),
                                  const SizedBox(height: 16),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: _firestore
              .collection('lists')
              .where('members', arrayContains: _auth.currentUser?.uid)
              .orderBy('createdAt', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              Sentry.captureException(
                snapshot.error,
                stackTrace: snapshot.stackTrace,
                hint: Hint.withMap({'component': 'lists_stream'}),
              );
              return Center(
                child: Text('Error loading lists: ${snapshot.error}'),
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CustomLoadingSpinner(
                  color: Colors.green,
                  size: 60.0,
                ),
              );
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.green[900] : Colors.green[50],
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.check_circle_outline,
                          size: 64,
                          color: isDark
                              ? Colors.green[100]
                              : Colors.green[800]?.withAlpha(178),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Welcome to ShopSync',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.green[300] : Colors.green[800],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Share shopping lists with family and friends',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: isDark ? Colors.grey[300] : Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 32),
                      // Instructions Card with tutorial steps
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: isDark
                                ? [Colors.grey[900]!, Colors.grey[850]!]
                                : [Colors.green[50]!, Colors.green[100]!],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(25),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                          border: Border.all(
                            color:
                                isDark ? Colors.grey[800]! : Colors.green[200]!,
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? Colors.green[800]
                                        : Colors.green[100],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: FaIcon(
                                    FontAwesomeIcons.graduationCap,
                                    color: isDark
                                        ? Colors.green[100]
                                        : Colors.green[800],
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Quick Tutorial',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: isDark
                                        ? Colors.green[100]
                                        : Colors.green[900],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isDark ? Colors.grey[850] : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isDark
                                      ? Colors.grey[700]!
                                      : Colors.grey[200]!,
                                ),
                              ),
                              child: Column(
                                children: [
                                  TutorialStep(
                                    icon: FontAwesomeIcons.bars,
                                    title: 'Open the drawer from the left',
                                    subtitle: 'Access your lists and settings',
                                    color: Colors.green[800]!,
                                  ),
                                  const SizedBox(height: 16),
                                  TutorialStep(
                                    icon: FontAwesomeIcons.cartShopping,
                                    title: 'Select a shopping list to view',
                                    subtitle:
                                        'Or create a new one to get started',
                                    color: Colors.green[800]!,
                                  ),
                                  const SizedBox(height: 16),
                                  TutorialStep(
                                    icon: FontAwesomeIcons.circlePlus,
                                    title: 'Add items to your list',
                                    subtitle:
                                        'Keep track of what you need to buy',
                                    color: Colors.green[800]!,
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
              );
            }

            // Show lists in grid/list view
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildReviewBanner(),
                  Text(
                    'Your Lists',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.green[300] : Colors.green[800],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      itemCount: snapshot.data!.docs.length,
                      itemBuilder: (context, index) {
                        final doc = snapshot.data!.docs[index];
                        final listName = doc['name'] ?? 'Unnamed List';
                        final timestamp = doc['createdAt'] as Timestamp?;
                        final createdAt = timestamp != null
                            ? DateFormat('MMM dd, yyyy')
                                .format(timestamp.toDate())
                            : 'Unknown date';

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: isDark
                                    ? [Colors.grey[900]!, Colors.grey[850]!]
                                    : [Colors.white, Colors.grey[50]!],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withAlpha(25),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                              border: Border.all(
                                color: isDark
                                    ? Colors.grey[800]!
                                    : Colors.grey[200]!,
                              ),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ListViewScreen(
                                        listId: doc.id,
                                        listName: listName,
                                      ),
                                    ),
                                  );
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: isDark
                                              ? Colors.green[900]
                                              : Colors.green[50],
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: FaIcon(
                                          FontAwesomeIcons.cartShopping,
                                          color: isDark
                                              ? Colors.green[200]
                                              : Colors.green[700],
                                          size: 24,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              listName,
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.w600,
                                                color: isDark
                                                    ? Colors.white
                                                    : Colors.grey[800],
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                FaIcon(
                                                  FontAwesomeIcons.calendar,
                                                  size: 14,
                                                  color: isDark
                                                      ? Colors.grey[400]
                                                      : Colors.grey[600],
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  createdAt,
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color: isDark
                                                        ? Colors.grey[400]
                                                        : Colors.grey[600],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: isDark
                                              ? Colors.grey[800]
                                              : Colors.grey[100],
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: FaIcon(
                                          FontAwesomeIcons.arrowRight,
                                          size: 16,
                                          color: isDark
                                              ? Colors.grey[400]
                                              : Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _newListController.dispose();
    super.dispose();
  }
}

