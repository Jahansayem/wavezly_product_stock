import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/customer.dart';
import '../models/customer_transaction.dart';

class CustomerService {
  final _supabase = SupabaseConfig.client;

  // Get all customers
  Stream<List<Customer>> getAllCustomers() {
    return _supabase
        .from('customers')
        .stream(primaryKey: ['id'])
        .order('name')
        .map((data) => data.map((item) => Customer.fromMap(item)).toList());
  }

  // Get customers with filtering
  Future<List<Customer>> getCustomers({String? filter}) async {
    var query = _supabase.from('customers').select();

    if (filter == 'receive') {
      query = query.gt('total_due', 0);
    } else if (filter == 'give') {
      query = query.lt('total_due', 0);
    }

    final response = await query.order('name');
    return (response as List).map((item) => Customer.fromMap(item)).toList();
  }

  // Search customers
  Future<List<Customer>> searchCustomers(String query) async {
    final response = await _supabase
        .from('customers')
        .select()
        .or('name.ilike.%$query%,phone.ilike.%$query%')
        .order('name');

    return (response as List).map((item) => Customer.fromMap(item)).toList();
  }

  // Create customer
  Future<Customer> createCustomer(Customer customer) async {
    customer.avatarColor = _generateAvatarColor(customer.name ?? '');

    // Add user_id before inserting (following ProductService pattern)
    final data = customer.toMap();
    data['user_id'] = _supabase.auth.currentUser!.id;

    // Remove id if null to let database generate UUID
    if (data['id'] == null) {
      data.remove('id');
    }

    final response = await _supabase
        .from('customers')
        .insert(data)
        .select()
        .single();

    return Customer.fromMap(response);
  }

  // Update customer
  Future<void> updateCustomer(String id, Customer customer) async {
    await _supabase
        .from('customers')
        .update({...customer.toMap(), 'updated_at': DateTime.now().toIso8601String()})
        .eq('id', id);
  }

  // Delete customer
  Future<void> deleteCustomer(String id) async {
    await _supabase.from('customers').delete().eq('id', id);
  }

  // Get summary
  Future<Map<String, double>> getSummary() async {
    final customers = await getCustomers();

    double toReceive = 0.0;
    double toGive = 0.0;

    for (var customer in customers) {
      if (customer.totalDue > 0) {
        toReceive += customer.totalDue;
      } else {
        toGive += customer.totalDue.abs();
      }
    }

    return {
      'toReceive': toReceive,
      'toGive': toGive,
      'netTotal': toGive - toReceive, // Net amount to give
    };
  }

  // Add transaction
  Future<void> addTransaction(CustomerTransaction transaction) async {
    final data = transaction.toMap();
    data['user_id'] = _supabase.auth.currentUser!.id;

    // Remove id if null to let database generate UUID
    if (data['id'] == null) {
      data.remove('id');
    }

    await _supabase.from('customer_transactions').insert(data);

    // Update customer total_due
    final customer = await _supabase
        .from('customers')
        .select()
        .eq('id', transaction.customerId!)
        .single();

    final currentDue = (customer['total_due'] as num?)?.toDouble() ?? 0.0;
    final newDue = currentDue + (transaction.amount ?? 0.0);

    await _supabase.from('customers').update({
      'total_due': newDue,
      'last_transaction_date': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', transaction.customerId!);
  }

  // Get customer transactions
  Stream<List<CustomerTransaction>> getCustomerTransactions(String customerId) {
    return _supabase
        .from('customer_transactions')
        .stream(primaryKey: ['id'])
        .eq('customer_id', customerId)
        .order('created_at', ascending: false)
        .map((data) =>
            data.map((item) => CustomerTransaction.fromMap(item)).toList());
  }

  // Generate avatar color from name
  String _generateAvatarColor(String name) {
    final colors = [
      '#3B82F6', // blue
      '#10B981', // green
      '#8B5CF6', // purple
      '#F59E0B', // amber
      '#EF4444', // red
      '#06B6D4', // cyan
      '#EC4899', // pink
      '#6366F1', // indigo
    ];
    final index = name.isNotEmpty ? name.codeUnitAt(0) % colors.length : 0;
    return colors[index];
  }
}
