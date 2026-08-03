import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_client.dart';
import 'database_helper.dart';
import 'constants.dart';
import '../models/product.dart';
import '../models/customer.dart';

class SyncManager {
  final ApiClient _apiClient = ApiClient();
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<Map<String, dynamic>> performSync() async {
    int pushedOrders = 0;
    int pushedAttendance = 0;

    // 1. PUSH Pending Writes (Client Wins)
    final pendingOrders = await _dbHelper.getPendingOrders();
    final pendingAtt = await _dbHelper.getPendingAttendance();

    if (pendingOrders.isNotEmpty || pendingAtt.isNotEmpty) {
      List<Map<String, dynamic>> orderList = [];
      for (var o in pendingOrders) {
        orderList.add(jsonDecode(o['payload_json']));
      }

      List<Map<String, dynamic>> attList = [];
      for (var a in pendingAtt) {
        attList.add({
          'employee_id': a['employee_id'],
          'date': a['date'],
          'status': a['status'],
        });
      }

      try {
        await _apiClient.post('/sync/push', {
          'orders': orderList,
          'attendance': attList,
        });

        // Clear successfully pushed items from local queue
        for (var o in pendingOrders) {
          await _dbHelper.removePendingOrder(o['client_id']);
          pushedOrders++;
        }
        await _dbHelper.clearPendingAttendance();
        pushedAttendance += pendingAtt.length;
      } catch (e) {
        // Network or push failure - keep items queued for next attempt
      }
    }

    // 2. PULL Catalogue Updates (Server Wins)
    final prefs = await SharedPreferences.getInstance();
    final lastSync = prefs.getString(AppConstants.lastSyncKey);

    String pullPath = '/sync/pull';
    if (lastSync != null && lastSync.isNotEmpty) {
      pullPath += '?since_timestamp=$lastSync';
    }

    final pullData = await _apiClient.get(pullPath);
    if (pullData is Map) {
      if (pullData['products'] != null) {
        List<Product> prods = (pullData['products'] as List)
            .map((p) => Product.fromJson(p))
            .toList();
        await _dbHelper.saveProducts(prods);
      }

      if (pullData['customers'] != null) {
        List<Customer> custs = (pullData['customers'] as List)
            .map((c) => Customer.fromJson(c))
            .toList();
        await _dbHelper.saveCustomers(custs);
      }

      if (pullData['server_timestamp'] != null) {
        await prefs.setString(AppConstants.lastSyncKey, pullData['server_timestamp']);
      }
    }

    return {
      'status': 'success',
      'pushed_orders': pushedOrders,
      'pushed_attendance': pushedAttendance,
      'last_sync': DateTime.now().toIso8601String(),
    };
  }
}
