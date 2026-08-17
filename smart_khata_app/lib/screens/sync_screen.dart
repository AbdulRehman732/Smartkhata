import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../core/constants.dart';
import '../core/database_helper.dart';
import '../core/sync_manager.dart';
import '../core/api_client.dart';

class SyncScreen extends StatefulWidget {
  const SyncScreen({super.key});

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
    if (!mounted) return;
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
      if (!mounted) return;
      setState(() {
        _syncMessage = 'Sync Complete! Pushed ${res['pushed_orders']} orders & ${res['pushed_attendance']} attendance records.';
        _isSyncing = false;
      });
      _loadPendingCounts();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _syncMessage = 'Sync Error: ${e.toString()}';
        _isSyncing = false;
      });
    }
  }

  Future<void> _exportBackupFile() async {
    setState(() {
      _isSyncing = true;
      _syncMessage = null;
    });
    try {
      final client = ApiClient();
      final backupData = await client.get('/backup/export');
      final jsonStr = const JsonEncoder.withIndent('  ').convert(backupData);

      final dateStr = DateTime.now().toIso8601String().split('T').first;
      final fileName = 'smart_khata_backup_$dateStr.json';

      if (!kIsWeb) {
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/$fileName');
        await file.writeAsString(jsonStr, flush: true);

        final xfile = XFile(file.path, mimeType: 'application/json', name: fileName);
        await Share.shareXFiles(
          [xfile],
          subject: 'Smart Khata JSON Database Backup ($dateStr)',
          text: 'Smart Khata complete store database backup for USB / Drive / WhatsApp storage.',
        );

        if (!mounted) return;
        setState(() {
          _syncMessage = 'Backup Exported & Shared! ($fileName - ${jsonStr.length} bytes)';
          _isSyncing = false;
        });
      } else {
        if (!mounted) return;
        setState(() {
          _syncMessage = 'Backup Export Ready! ($fileName - ${jsonStr.length} bytes)';
          _isSyncing = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _syncMessage = 'Export Error: ${e.toString()}';
        _isSyncing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.creamBg,
      appBar: AppBar(
        title: Text('Offline Sync & Backup', style: GoogleFonts.instrumentSerif(color: AppConstants.charcoal, fontSize: 24, fontWeight: FontWeight.bold)),
        backgroundColor: AppConstants.creamBg,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppConstants.charcoal),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppConstants.surfaceWhite,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppConstants.softBorder),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 30,
                    backgroundColor: AppConstants.softGreenChip,
                    child: Icon(Icons.cloud_sync, size: 32, color: AppConstants.deepEmerald),
                  ),
                  const SizedBox(height: 12),
                  Text('Pending Offline Sync Queue', style: GoogleFonts.instrumentSerif(color: AppConstants.charcoal, fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildQueueTile('Queued Orders', '$_pendingOrdersCount'),
                      Container(height: 40, width: 1, color: AppConstants.softBorder),
                      _buildQueueTile('Queued Attendance', '$_pendingAttendanceCount'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            if (_syncMessage != null)
              Container(
                padding: const EdgeInsets.all(14),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppConstants.softGreenChip,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppConstants.deepEmerald.withValues(alpha: 0.3)),
                ),
                child: Text(_syncMessage!, style: const TextStyle(color: AppConstants.deepEmerald, fontWeight: FontWeight.bold, fontSize: 13)),
              ),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _isSyncing ? null : _triggerManualSync,
                icon: const Icon(Icons.sync, color: Colors.white, size: 20),
                label: const Text('SYNC NOW WITH SERVER', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15, letterSpacing: 0.5)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.deepEmerald,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                onPressed: _isSyncing ? null : _exportBackupFile,
                icon: const Icon(Icons.share_rounded, color: AppConstants.mutedTerracotta, size: 20),
                label: const Text('EXPORT & SHARE BACKUP (USB/DRIVE)', style: TextStyle(color: AppConstants.mutedTerracotta, fontWeight: FontWeight.bold, fontSize: 14)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppConstants.mutedTerracotta, width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
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
        Text(count, style: GoogleFonts.instrumentSerif(color: AppConstants.mutedTerracotta, fontSize: 32, fontWeight: FontWeight.bold)),
        Text(title, style: const TextStyle(color: AppConstants.textMuted, fontSize: 13, fontWeight: FontWeight.w500)),
      ],
    );
  }
}
