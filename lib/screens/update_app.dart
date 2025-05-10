import 'package:flutter/material.dart';
import 'package:in_app_update/in_app_update.dart';
import '../services/update_service.dart';

class UpdateAppScreen extends StatefulWidget {
  final AppUpdateInfo updateInfo;
  final Function(bool) onUpdateComplete;

  const UpdateAppScreen({
    super.key,
    required this.updateInfo,
    required this.onUpdateComplete,
  });

  @override
  State<UpdateAppScreen> createState() => _UpdateAppScreenState();
}

class _UpdateAppScreenState extends State<UpdateAppScreen> {
  bool _isDownloading = false;
  bool _isDownloaded = false;

  @override
  void initState() {
    super.initState();
    _checkDownloadStatus();
    
    // Listen to download status changes
    InAppUpdate.installUpdateListener.listen((status) {
      if (status == InstallStatus.downloaded) {
        setState(() {
          _isDownloaded = true;
          _isDownloading = false;
        });
      } else if (status == InstallStatus.downloading) {
        setState(() {
          _isDownloading = true;
          _isDownloaded = false;
        });
      } else if (status == InstallStatus.installed) {
        widget.onUpdateComplete(true);
      }
    });
  }

  Future<void> _checkDownloadStatus() async {
    final isDownloaded = await UpdateService.isUpdateDownloaded();
    if (isDownloaded) {
      setState(() {
        _isDownloaded = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.system_update,
                  size: 100,
                  color: Colors.green,
                ),
                const SizedBox(height: 32),
                const Text(
                  'ShopSync has an update',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Please update the app to continue using the latest features and improvements.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 32),
                if (_isDownloading && !_isDownloaded) ...[
                  StreamBuilder<InstallStatus>(
                    stream: UpdateService.getUpdateStatus(),
                    builder: (context, snapshot) {
                      return Column(
                        children: [
                          // Indeterminate progress indicator
                          const LinearProgressIndicator(
                            backgroundColor: Colors.grey,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Downloading update...',
                            style: TextStyle(fontSize: 14),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                ],
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: _isDownloading && !_isDownloaded
                        ? null
                        : () => _handleUpdateButtonPress(),
                    child: Text(
                      _isDownloaded
                          ? 'Install'
                          : (_isDownloading ? 'Downloading...' : 'Update'),
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleUpdateButtonPress() async {
    try {
      if (_isDownloaded) {
        // Complete the installation
        await InAppUpdate.completeFlexibleUpdate();
        widget.onUpdateComplete(true);
      } else {
        setState(() {
          _isDownloading = true;
        });

        // Start flexible update
        final result = await InAppUpdate.startFlexibleUpdate();
        
        if (result == AppUpdateResult.success) {
          // The download has started, we'll track status through the stream
          debugPrint('Flexible update started successfully');
        } else if (result == AppUpdateResult.userDeniedUpdate) {
          // User declined the update
          setState(() {
            _isDownloading = false;
          });
          debugPrint('User denied the update');
        } else {
          // Update failed
          setState(() {
            _isDownloading = false;
          });
          debugPrint('Update failed: $result');
        }
      }
    } catch (e) {
      debugPrint('Update action failed: $e');
      setState(() {
        _isDownloading = false;
      });
    }
  }
}
