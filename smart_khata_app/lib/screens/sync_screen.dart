import 'dart:convert';
import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../core/database_helper.dart';
import '../core/sync_manager.dart';
import '../core/api_client.dart';

class SyncScreen extends StatefulWidget {
  const SyncScreen({Key? key}) : super(key: key);

  @override
  State<SyncScreen> createState() => _SyncScreenState();
}

class _SyncScreenState extends State<SyncScreen> {
  int _pendingOrdersCount = 0;
  int _pendingAttendanceCount = 0;
  bool _isSyncing = false;
  String? _syncMessage;

  @override
  void initState() {
    super.initState();
    _loadPendingCounts();
  }

  Future<void> _loadPendingCounts() async {
    final orders = await DatabaseHelper.instance.getPendingOrders();
    final att = await DatabaseHelper.instance.getPendingAttendance();
    setState(() {
      _pendingOrdersCount = orders.length;
      _pendingAttendanceCount = att.length;
    });
  }

  Future<void> _triggerManualSync() async {
    setState(() {
      _isSyncing = true;
      _syncMessage = null;
    });

    try {
      final syncManager = SyncManager();
      final res = await syncManager.performSync();
      setState(() {
        _syncMessage = 'Sync Complete! Pushed ${res['pushed_orders']} orders & ${res['pushed_attendance']} attendance records.';
        _isSyncing = false;
      });
      _loadPendingCounts();
    } catch (e) {
      setState(() {
        _syncMessage = 'Sync Error: ${e.toString()}';
        _isSyncing = false;
      });
    }
  }

  Future<void> _exportBackupFile() async {
    setState(() => _isSyncing = true);
    try {
      final client = ApiClient();
      final backupData = await client.get('/backup/export');
      final jsonStr = jsonEncode(backupData);

      setState(() {
        _syncMessage = 'Backup Export Ready! (${jsonStr.length} bytes extracted for local JSON backup / USB storage)';
        _isSyncing = false;
      });
    } catch (e) {
      setState(() {
        _syncMessage = 'Export Error: ${e.toString()}';
        _isSyncing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.darkBg,
      appBar: AppBar(
        title: const Text('Offline Sync & Local Backup'),
        backgroundColor: AppConstants.cardDark,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppConstants.cardDark,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppConstants.accentGold),
              ),
              child: Column(
                children: [
                  const Icon(Icons.cloud_sync, size: 48, color: AppConstants.accentGold),
                  const SizedBox(height: 12),
                  const Text('Pending Offline Sync Queue', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildQueueTile('Queued Orders', '$_pendingOrdersCount'),
                      _buildQueueTile('Queued Attendance', '$_pendingAttendanceCount'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            if (_syncMessage != null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppConstants.primaryGreen.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppConstants.primaryGreen),
                ),
                child: Text(_syncMessage!, style: const TextStyle(color: Colors.white)),
              ),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isSyncing ? null : _triggerManualSync,
                icon: const Icon(Icons.sync, color: Colors.white),
                label: const Text('SYNC NOW WITH SERVER', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                style: ElevatedButton.styleFrom(backgroundColor: AppConstants.primaryGreen),
              ),
            ),
            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: _isSyncing ? null : _exportBackupFile,
                icon: const Icon(Icons.save_alt, color: AppConstants.accentGold),
                label: const Text('EXPORT LOCAL JSON BACKUP (USB / FILE)', style: TextStyle(color: AppConstants.accentGold, fontWeight: FontWeight.bold, fontSize: 14)),
                style: OutlinedButton.styleFrom(side: const BorderSide(color: AppConstants.accentGold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQueueTile(String title, String count) {
    return Column(
      children: [
        Text(count, style: const TextStyle(color: AppConstants.accentGold, fontSize: 24, fontWeight: FontWeight.bold)),
        Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }
}
