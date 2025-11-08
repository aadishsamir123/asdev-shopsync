import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_svg/svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:shopsync/services/connectivity_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter_expandable_fab/flutter_expandable_fab.dart';

import '/screens/list_view.dart';
import '/widgets/loading_spinner.dart';
import '/widgets/advert.dart';
import '/widgets/add_list_group_bottom_sheet.dart';
import '/widgets/expandable_list_group_widget.dart';
import '/widgets/splash_screen.dart';
import '/services/list_groups_service.dart';
import '/services/migration_service.dart';
import '/utils/permissions.dart';

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

  // Ad management
  BannerAd? _bannerAd;
  bool _isBannerAdLoaded = false;

  // Splash screen management
  bool _showSplashScreen = true;
  bool _dataLoaded = false;

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
        const SnackBar(
            content: Text('Failed to create list. Please try again.')),
      );
    }
  }

  // Widget _buildBanner() {
  //   return Container(
  //     margin: const EdgeInsets.all(16),
  //     decoration: BoxDecoration(
  //       gradient: LinearGradient(
  //         begin: Alignment.topLeft,
  //         end: Alignment.bottomRight,
  //         colors: [
  //           Colors.amber[100]!,
  //           Colors.amber[50]!,
  //         ],
  //       ),
  //       borderRadius: BorderRadius.circular(16),
  //       boxShadow: [
  //         BoxShadow(
  //           color: Colors.amber.withAlpha(51),
  //           blurRadius: 8,
  //           offset: const Offset(0, 4),
  //         ),
  //       ],
  //       border: Border.all(
  //         color: Colors.amber[200]!,
  //         width: 1,
  //       ),
  //     ),
  //     child: Material(
  //       color: Colors.transparent,
  //       child: Padding(
  //         padding: const EdgeInsets.all(16),
  //         child: Column(
  //           mainAxisSize: MainAxisSize.min,
  //           children: [
  //             Row(
  //               children: [
  //                 Container(
  //                   padding: const EdgeInsets.all(12),
  //                   decoration: BoxDecoration(
  //                     color: Colors.amber[200],
  //                     shape: BoxShape.circle,
  //                   ),
  //                   child: Icon(
  //                     FontAwesomeIcons.star,
  //                     color: Colors.amber[800],
  //                     size: 24,
  //                   ),
  //                 ),
  //                 const SizedBox(width: 16),
  //                 Expanded(
  //                   child: Column(
  //                     crossAxisAlignment: CrossAxisAlignment.start,
  //                     children: [
  //                       const Text(
  //                         'Give testing feedback',
  //                         style: TextStyle(
  //                           fontSize: 18,
  //                           fontWeight: FontWeight.bold,
  //                           color: Colors.black87,
  //                         ),
  //                       ),
  //                       const SizedBox(height: 4),
  //                       Text(
  //                         'To get my app on the Play Store, please leave feedback.',
  //                         style: TextStyle(
  //                           fontSize: 14,
  //                           color: Colors.grey[800],
  //                         ),
  //                       ),
  //                     ],
  //                   ),
  //                 ),
  //               ],
  //             ),
  //             const SizedBox(height: 16),
  //             SizedBox(
  //               width: double.infinity,
  //               child: TextButton(
  //                 onPressed: () async {
  //                   final Uri url = Uri.parse(
  //                     'https://play.google.com/store/apps/details?id=com.aadishsamir.shopsync',
  //                   );
  //                   if (!await launchUrl(url,
  //                       mode: LaunchMode.externalApplication)) {
  //                     if (!mounted) return;
  //                     ScaffoldMessenger.of(context).showSnackBar(
  //                       const SnackBar(
  //                           content: Text('Could not open Play Store')),
  //                     );
  //                   }
  //                 },
  //                 style: TextButton.styleFrom(
  //                   padding: const EdgeInsets.symmetric(
  //                     horizontal: 20,
  //                     vertical: 12,
  //                   ),
  //                   backgroundColor: Colors.amber[400],
  //                   foregroundColor: Colors.black87,
  //                   shape: RoundedRectangleBorder(
  //                     borderRadius: BorderRadius.circular(12),
  //                   ),
  //                 ),
  //                 child: const Text(
  //                   'Give Feedback',
  //                   style: TextStyle(
  //                     fontWeight: FontWeight.bold,
  //                   ),
  //                 ),
  //               ),
  //             ),
  //           ],
  //         ),
  //       ),
  //     ),
  //   );
  // }

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
  void initState() {
    super.initState();
    _loadBannerAd();
    _checkMigration();
    _cleanupOrphanedLists();
    _startSplashTimer();
  }

  void _startSplashTimer() {
    // Set a minimum display time for splash screen
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) {
        setState(() {
          _dataLoaded = true;
        });
        _hideSplashScreenAfterDelay();
      }
    });
  }

  void _hideSplashScreenAfterDelay() {
    if (_dataLoaded) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() {
            _showSplashScreen = false;
          });
        }
      });
    }
  }

  Future<void> _checkMigration() async {
    final needsMigration = await MigrationService.needsMigration();
    if (needsMigration && mounted) {
      // Navigate to migration screen
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacementNamed('/migration');
      });
    }
  }

  Future<void> _cleanupOrphanedLists() async {
    // Clean up any orphaned lists (lists pointing to deleted groups)
    await ListGroupsService.cleanupOrphanedLists();
  }

  void _loadBannerAd() {
    // Don't load ads on web platform
    if (kIsWeb) {
      return;
    }

    _bannerAd = BannerAd(
      adUnitId: 'ca-app-pub-6149170768233698/9243836096',
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          setState(() {
            _isBannerAdLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          setState(() {
            _bannerAd = null;
            _isBannerAdLoaded = false;
          });
        },
      ),
    );
    _bannerAd?.load();
  }

  @override
  void dispose() {
    _newListController.dispose();
    if (!kIsWeb) {
      _bannerAd?.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final connectivityService = ConnectivityService();

    // final l10n = AppLocalizations.of(context);

    PreferredSize buildCustomAppBar(BuildContext context) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      return PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: AppBar(
          backgroundColor: isDark ? Colors.grey[800] : Colors.green[800],
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () {
              _scaffoldKey.currentState?.openDrawer();
            },
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
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Stack(
      children: [
        GestureDetector(
          onHorizontalDragStart: _handleDragStart,
          onHorizontalDragUpdate: _handleDragUpdate,
          child: Scaffold(
            key: _scaffoldKey,
            backgroundColor: isDark ? Colors.grey[900] : Colors.grey[50],
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
                                (_auth.currentUser?.displayName?.isNotEmpty ==
                                        true)
                                    ? _auth.currentUser!.displayName![0]
                                        .toUpperCase()
                                    : 'U',
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color:
                                      isDark ? Colors.white : Colors.green[800],
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
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
                                          Spacer(flex: 1),
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
                                          Spacer(flex: 1),
                                          FaIcon(
                                            FontAwesomeIcons.arrowDown,
                                            size: 48,
                                            color: Colors.grey[400],
                                          ),
                                          const SizedBox(height: 16),
                                          Text(
                                            'Swipe down to view options',
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                          const SizedBox(height: 32),
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
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: ListTile(
                                            leading: Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color:
                                                    Colors.grey.withAlpha(25),
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
                                        icon: FontAwesomeIcons.gear,
                                        title: 'Settings',
                                        onTap: () {
                                          Navigator.popAndPushNamed(
                                              context, '/settings');
                                        },
                                      ),
                                      _buildDrawerItem(
                                        icon: FontAwesomeIcons.user,
                                        title: 'My Profile',
                                        onTap: () {
                                          Navigator.pop(context);
                                          Navigator.pushNamed(
                                              context, '/profile');
                                        },
                                      ),
                                      _buildDrawerItem(
                                        icon: FontAwesomeIcons.comment,
                                        title: 'Feedback',
                                        onTap: () async {
                                          if (await connectivityService
                                              .checkConnectivityAndShowDialog(
                                                  context,
                                                  feature: 'feedback')) {
                                            Navigator.pop(context);
                                            Navigator.pushNamed(
                                                context, '/feedback');
                                          }
                                        },
                                      ),
                                      _buildDrawerItem(
                                        icon: FontAwesomeIcons.scroll,
                                        title: 'Release Notes',
                                        onTap: () async {
                                          if (await connectivityService
                                              .checkConnectivityAndShowDialog(
                                                  context,
                                                  feature: 'release notes')) {
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
                                          }
                                        },
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
            body: Column(
              children: [
                Expanded(
                  child: CustomScrollView(
                    slivers: [
                      // List Groups Section
                      SliverToBoxAdapter(
                        child: StreamBuilder<QuerySnapshot>(
                          stream: ListGroupsService.getUserListGroups(),
                          builder: (context, groupSnapshot) {
                            if (groupSnapshot.hasError) {
                              Sentry.captureException(
                                groupSnapshot.error,
                                stackTrace: groupSnapshot.stackTrace,
                                hint: Hint.withMap(
                                    {'component': 'groups_stream'}),
                              );
                            }

                            if (groupSnapshot.hasData &&
                                groupSnapshot.data!.docs.isNotEmpty) {
                              final groups = groupSnapshot.data!.docs;
                              return Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          'List Groups',
                                          style: TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                            color: isDark
                                                ? Colors.green[300]
                                                : Colors.green[800],
                                          ),
                                        ),
                                        const Spacer(),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: isDark
                                                ? Colors.grey[800]
                                                : Colors.grey[100],
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              FaIcon(
                                                FontAwesomeIcons
                                                    .upDownLeftRight,
                                                size: 12,
                                                color: isDark
                                                    ? Colors.grey[400]
                                                    : Colors.grey[600],
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                'Hold to reorder',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: isDark
                                                      ? Colors.grey[400]
                                                      : Colors.grey[600],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    ReorderableListView.builder(
                                      shrinkWrap: true,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      itemCount: groups.length,
                                      onReorder: (oldIndex, newIndex) async {
                                        if (oldIndex < newIndex) {
                                          newIndex -= 1;
                                        }

                                        final reorderedGroups =
                                            List<DocumentSnapshot>.from(groups);
                                        final item =
                                            reorderedGroups.removeAt(oldIndex);
                                        reorderedGroups.insert(newIndex, item);

                                        final groupIds = reorderedGroups
                                            .map((doc) => doc.id)
                                            .toList();
                                        await ListGroupsService
                                            .reorderListGroups(groupIds);
                                      },
                                      itemBuilder: (context, index) {
                                        final groupDoc = groups[index];
                                        return Container(
                                          key: Key(groupDoc.id),
                                          margin:
                                              const EdgeInsets.only(bottom: 16),
                                          child: ExpandableListGroupWidget(
                                              groupDoc: groupDoc),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      ),

                      // Debug Lists Section
                      // Ungrouped Lists Section
                      SliverToBoxAdapter(
                        child: StreamBuilder<List<QueryDocumentSnapshot>>(
                          stream: ListGroupsService.getUngroupedLists(),
                          builder: (context, snapshot) {
                            if (snapshot.hasError) {
                              Sentry.captureException(
                                snapshot.error,
                                stackTrace: snapshot.stackTrace,
                                hint:
                                    Hint.withMap({'component': 'lists_stream'}),
                              );
                              return Center(
                                child: Text(
                                    'Error loading lists: ${snapshot.error}'),
                              );
                            }

                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(32.0),
                                  child: CustomLoadingSpinner(
                                    color: Colors.green,
                                    size: 60.0,
                                  ),
                                ),
                              );
                            }

                            // Show ungrouped lists if they exist
                            if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                              return Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Ungrouped Lists',
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: isDark
                                            ? Colors.green[300]
                                            : Colors.green[800],
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    ...snapshot.data!.map((doc) {
                                      final listName =
                                          doc['name'] ?? 'Unnamed List';
                                      final timestamp =
                                          doc['createdAt'] as Timestamp?;
                                      final createdAt = timestamp != null
                                          ? DateFormat('MMM dd, yyyy')
                                              .format(timestamp.toDate())
                                          : 'Unknown date';

                                      return Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 12),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                              colors: isDark
                                                  ? [
                                                      Colors.grey[900]!,
                                                      Colors.grey[850]!
                                                    ]
                                                  : [
                                                      Colors.white,
                                                      Colors.grey[50]!
                                                    ],
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(16),
                                            boxShadow: [
                                              BoxShadow(
                                                color:
                                                    Colors.black.withAlpha(25),
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
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                              onTap: () {
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
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.all(16),
                                                child: Row(
                                                  children: [
                                                    Container(
                                                      padding:
                                                          const EdgeInsets.all(
                                                              12),
                                                      decoration: BoxDecoration(
                                                        color: isDark
                                                            ? Colors.green[900]
                                                            : Colors.green[50],
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(12),
                                                      ),
                                                      child: FaIcon(
                                                        FontAwesomeIcons
                                                            .cartShopping,
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
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Text(
                                                            listName,
                                                            style: TextStyle(
                                                              fontSize: 18,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                              color: isDark
                                                                  ? Colors.white
                                                                  : Colors.grey[
                                                                      800],
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                              height: 4),
                                                          Row(
                                                            children: [
                                                              FaIcon(
                                                                FontAwesomeIcons
                                                                    .calendar,
                                                                size: 14,
                                                                color: isDark
                                                                    ? Colors.grey[
                                                                        400]
                                                                    : Colors.grey[
                                                                        600],
                                                              ),
                                                              const SizedBox(
                                                                  width: 4),
                                                              Text(
                                                                createdAt,
                                                                style:
                                                                    TextStyle(
                                                                  fontSize: 14,
                                                                  color: isDark
                                                                      ? Colors.grey[
                                                                          400]
                                                                      : Colors.grey[
                                                                          600],
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    FaIcon(
                                                      FontAwesomeIcons
                                                          .chevronRight,
                                                      color: isDark
                                                          ? Colors.grey[600]
                                                          : Colors.grey[400],
                                                      size: 16,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    }),
                                  ],
                                ),
                              );
                            }

                            // Check if we have any lists at all (for welcome screen)
                            return StreamBuilder<QuerySnapshot>(
                              stream: _firestore
                                  .collection('lists')
                                  .where('members',
                                      arrayContains: _auth.currentUser?.uid)
                                  .limit(1)
                                  .snapshots(),
                              builder: (context, allListsSnapshot) {
                                final hasAnyLists = allListsSnapshot.hasData &&
                                    allListsSnapshot.data!.docs.isNotEmpty;

                                if (!hasAnyLists) {
                                  // Show welcome screen if no lists exist
                                  return Center(
                                    child: Padding(
                                      padding: const EdgeInsets.all(24.0),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(16),
                                            decoration: BoxDecoration(
                                              color: isDark
                                                  ? Colors.green[900]
                                                  : Colors.green[50],
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(
                                              Icons.check_circle_outline,
                                              size: 64,
                                              color: isDark
                                                  ? Colors.green[100]
                                                  : Colors.green[800]
                                                      ?.withAlpha(178),
                                            ),
                                          ),
                                          const SizedBox(height: 24),
                                          Text(
                                            'Welcome to ShopSync',
                                            style: TextStyle(
                                              fontSize: 24,
                                              fontWeight: FontWeight.bold,
                                              color: isDark
                                                  ? Colors.green[300]
                                                  : Colors.green[800],
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          Text(
                                            'Share shopping lists with family and friends',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontSize: 16,
                                              color: isDark
                                                  ? Colors.grey[300]
                                                  : Colors.grey[700],
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
                                                    ? [
                                                        Colors.grey[900]!,
                                                        Colors.grey[850]!
                                                      ]
                                                    : [
                                                        Colors.green[50]!,
                                                        Colors.green[100]!
                                                      ],
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black
                                                      .withAlpha(25),
                                                  blurRadius: 8,
                                                  offset: const Offset(0, 4),
                                                ),
                                              ],
                                              border: Border.all(
                                                color: isDark
                                                    ? Colors.grey[800]!
                                                    : Colors.green[200]!,
                                              ),
                                            ),
                                            child: Column(
                                              children: [
                                                Row(
                                                  children: [
                                                    Container(
                                                      padding:
                                                          const EdgeInsets.all(
                                                              8),
                                                      decoration: BoxDecoration(
                                                        color: isDark
                                                            ? Colors.green[800]
                                                            : Colors.green[100],
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(8),
                                                      ),
                                                      child: FaIcon(
                                                        FontAwesomeIcons
                                                            .graduationCap,
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
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: isDark
                                                            ? Colors.green[100]
                                                            : Colors.green[900],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 20),
                                                AnimatedContainer(
                                                  duration: const Duration(
                                                      milliseconds: 300),
                                                  curve: Curves.easeInOut,
                                                  padding:
                                                      const EdgeInsets.all(16),
                                                  decoration: BoxDecoration(
                                                    color: isDark
                                                        ? Colors.grey[850]
                                                        : Colors.white,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12),
                                                    border: Border.all(
                                                      color: isDark
                                                          ? Colors.grey[700]!
                                                          : Colors.grey[200]!,
                                                    ),
                                                  ),
                                                  child: Column(
                                                    children: [
                                                      TutorialStep(
                                                        icon: FontAwesomeIcons
                                                            .bars,
                                                        title:
                                                            'Open the drawer from the left',
                                                        subtitle:
                                                            'Access your lists and settings',
                                                        color:
                                                            Colors.green[800]!,
                                                      ),
                                                      const SizedBox(
                                                          height: 16),
                                                      TutorialStep(
                                                        icon: FontAwesomeIcons
                                                            .layerGroup,
                                                        title:
                                                            'Create list groups',
                                                        subtitle:
                                                            'Organize your lists with the + button',
                                                        color:
                                                            Colors.green[800]!,
                                                      ),
                                                      const SizedBox(
                                                          height: 16),
                                                      TutorialStep(
                                                        icon: FontAwesomeIcons
                                                            .circlePlus,
                                                        title:
                                                            'Add items to your lists',
                                                        subtitle:
                                                            'Keep track of what you need to buy',
                                                        color:
                                                            Colors.green[800]!,
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

                                // If no ungrouped lists, just return empty
                                return const SizedBox.shrink();
                              },
                            );
                          },
                        ),
                      ),

                      // Bottom padding for FAB
                      const SliverToBoxAdapter(
                        child: SizedBox(height: 100),
                      ),
                    ],
                  ),
                ),
                // Viewer indicator
                FutureBuilder<bool>(
                  future: PermissionsHelper.hasViewerLists(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData && snapshot.data == true) {
                      return Container(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.blue[900] : Colors.blue[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color:
                                isDark ? Colors.blue[700]! : Colors.blue[200]!,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              FontAwesomeIcons.eye,
                              color:
                                  isDark ? Colors.blue[300] : Colors.blue[700],
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "You're a viewer",
                              style: TextStyle(
                                color: isDark
                                    ? Colors.blue[300]
                                    : Colors.blue[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
                // Advertisement at the bottom
                if (_isBannerAdLoaded && _bannerAd != null)
                  Container(
                    margin: const EdgeInsets.all(8.0),
                    child: BannerAdvertWidget(
                      bannerAd: _bannerAd,
                      backgroundColor:
                          Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey[800]!
                              : Colors.white,
                    ),
                  ),
              ],
            ),
            floatingActionButtonLocation: ExpandableFab.location,
            floatingActionButton: ExpandableFab(
              type: ExpandableFabType.up,
              distance: 70,
              fanAngle: 0,
              initialOpen: false,
              duration: const Duration(milliseconds: 500),
              childrenAnimation: ExpandableFabAnimation.none,
              openButtonBuilder: RotateFloatingActionButtonBuilder(
                child: const Icon(Icons.add),
                fabSize: ExpandableFabSize.regular,
                backgroundColor: isDark ? Colors.green[700] : Colors.green[600],
                foregroundColor: Colors.white,
                angle: 45,
              ),
              closeButtonBuilder: DefaultFloatingActionButtonBuilder(
                child: const Icon(Icons.close),
                fabSize: ExpandableFabSize.regular,
                backgroundColor: isDark ? Colors.green[700] : Colors.green[600],
                foregroundColor: Colors.white,
              ),
              overlayStyle: ExpandableFabOverlayStyle(
                color: Colors.black.withOpacity(0.5),
              ),
              children: [
                // First FAB - Create List (appears second with staggered delay)
                _AnimatedFabChild(
                  delay: const Duration(milliseconds: 100),
                  child: FloatingActionButton.extended(
                    heroTag: 'createList',
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          backgroundColor: isDark ? Colors.black : Colors.white,
                          title: Text(
                            'Create New List',
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          content: TextField(
                            controller: _newListController,
                            autofocus: true,
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black,
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
                                borderRadius: BorderRadius.circular(8),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: Colors.green.shade400,
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
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
                                backgroundColor: Colors.green[800],
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Create'),
                            ),
                          ],
                        ),
                      );
                    },
                    backgroundColor:
                        isDark ? Colors.green[700] : Colors.green[600],
                    foregroundColor: Colors.white,
                    icon: const FaIcon(FontAwesomeIcons.cartShopping, size: 20),
                    label: const Text('Create List'),
                  ),
                ),
                // Second FAB - Create List Group (appears first)
                _AnimatedFabChild(
                  delay: Duration.zero,
                  child: FloatingActionButton.extended(
                    heroTag: 'createListGroup',
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (context) => const AddListGroupBottomSheet(),
                      ).then((result) {
                        if (result == true) {
                          // Refresh the UI or handle success
                        }
                      });
                    },
                    backgroundColor:
                        isDark ? Colors.green[700] : Colors.green[600],
                    foregroundColor: Colors.white,
                    icon: const FaIcon(FontAwesomeIcons.layerGroup, size: 20),
                    label: const Text('Create List Group'),
                  ),
                ),
              ],
            ),
          ),
        ),
        // Splash screen overlay
        _showSplashScreen
            ? AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                child: const SplashScreen(),
              )
            : const SizedBox.shrink(),
      ],
    );
  }
}

// Custom animated FAB child with M3 expressive bouncy entrance and fade-out exit
class _AnimatedFabChild extends StatefulWidget {
  final Widget child;
  final Duration delay;

  const _AnimatedFabChild({
    required this.child,
    this.delay = Duration.zero,
  });

  @override
  State<_AnimatedFabChild> createState() => _AnimatedFabChildState();
}

class _AnimatedFabChildState extends State<_AnimatedFabChild>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  bool _hasAnimated = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    // Bouncy scale animation for entrance (M3 expressive style)
    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut, // Creates the bounce effect
    ));

    // Fade in animation
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
    ));

    // Slide up animation from bottom
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    // Start animation after staggered delay
    Future.delayed(widget.delay, () {
      if (mounted && !_hasAnimated) {
        _controller.forward();
        _hasAnimated = true;
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: widget.child,
        ),
      ),
    );
  }
}
