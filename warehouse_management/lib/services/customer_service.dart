import '../repositories/customer_repository.dart';
import '../models/customer.dart';
import '../models/customer_transaction.dart';

class CustomerService {
  final CustomerRepository _repository = CustomerRepository();

  // Get all customers (offline-first from repository)
  Stream<List<Customer>> getAllCustomers() {
    return _repository.getAllCustomers();
  }

  // Get customers with filtering (offline-first from repository)
  Future<List<Customer>> getCustomers({String? filter}) async {
    return await _repository.getCustomersByFilter(filter);
  }

  // Get customer by ID (offline-first from repository)
  Future<Customer?> getCustomerById(String customerId) async {
    return await _repository.getCustomerById(customerId);
  }

  // Search customers (offline-first from repository)
  Future<List<Customer>> searchCustomers(String query) async {
    return await _repository.searchCustomers(query);
  }

  // Create customer (offline-first via repository)
  Future<Customer> createCustomer(Customer customer) async {
    return await _repository.createCustomer(customer);
  }

  // Update customer (offline-first via repository)
  Future<void> updateCustomer(String id, Customer customer) async {
    await _repository.updateCustomer(id, customer);
  }

  // Delete customer (offline-first via repository)
  Future<void> deleteCustomer(String id) async {
    await _repository.deleteCustomer(id);
  }

  // Get summary (computed from local data via repository)
  Future<Map<String, double>> getSummary() async {
    return await _repository.getSummary();
  }

  /// Adds customer transaction using offline-first repository
  /// Amount must ALWAYS be positive - transaction_type determines balance direction
  /// GIVEN = we gave to customer (increases their balance)
  /// RECEIVED = customer paid us (decreases their balance)
  Future<void> addTransaction(CustomerTransaction transaction) async {
    await _repository.addTransaction(transaction);
  }

  // Get customer transactions (offline-first from repository)
  Stream<List<CustomerTransaction>> getCustomerTransactions(String customerId) {
    return _repository.getCustomerTransactions(customerId);
  }

  // Get recent transactions with customer details (for history view)
  Future<List<Map<String, dynamic>>> getRecentTransactions({int limit = 50}) async {
    return await _repository.getRecentTransactions(limit: limit);
  }
}
