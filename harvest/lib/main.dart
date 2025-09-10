// pubspec.yaml dependencies needed:
// flutter:
//   sdk: flutter
// firebase_core: ^2.24.2
// cloud_firestore: ^4.13.6
// intl: ^0.18.1

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(FarmerHarvestApp());
}

class FarmerHarvestApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Farmer Harvest Manager',
      theme: ThemeData(
        primarySwatch: Colors.green,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    CustomersView(),
    LocationsView(),
    DatesView(),
    AddRecordView(),
    PaymentUpdateView(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Customers'),
          BottomNavigationBarItem(
            icon: Icon(Icons.location_on),
            label: 'Locations',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Dates',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.add), label: 'Add Record'),
          BottomNavigationBarItem(icon: Icon(Icons.payment), label: 'Payments'),
        ],
      ),
    );
  }
}

// Model class for Harvest Record
class HarvestRecord {
  final String id;
  final String customerName;
  final String locationName;
  final DateTime harvestDate;
  final double landSize;
  final double harvestQuantity;
  final double totalCost;
  final double paidAmount;
  final double remainingAmount;

  HarvestRecord({
    required this.id,
    required this.customerName,
    required this.locationName,
    required this.harvestDate,
    required this.landSize,
    required this.harvestQuantity,
    required this.totalCost,
    required this.paidAmount,
    required this.remainingAmount,
  });

  factory HarvestRecord.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return HarvestRecord(
      id: doc.id,
      customerName: data['customerName'] ?? '',
      locationName: data['locationName'] ?? '',
      harvestDate: (data['harvestDate'] as Timestamp).toDate(),
      landSize: (data['landSize'] ?? 0).toDouble(),
      harvestQuantity: (data['harvestQuantity'] ?? 0).toDouble(),
      totalCost: (data['totalCost'] ?? 0).toDouble(),
      paidAmount: (data['paidAmount'] ?? 0).toDouble(),
      remainingAmount: (data['remainingAmount'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'customerName': customerName,
      'locationName': locationName,
      'harvestDate': Timestamp.fromDate(harvestDate),
      'landSize': landSize,
      'harvestQuantity': harvestQuantity,
      'totalCost': totalCost,
      'paidAmount': paidAmount,
      'remainingAmount': remainingAmount,
    };
  }
}

// Customers View
class CustomersView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Customers'), backgroundColor: Colors.green),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('harvest_records')
            .orderBy('customerName')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No records found'));
          }

          List<HarvestRecord> records = snapshot.data!.docs
              .map((doc) => HarvestRecord.fromFirestore(doc))
              .toList();

          // Group by customer name
          Map<String, List<HarvestRecord>> customerGroups = {};
          for (var record in records) {
            if (!customerGroups.containsKey(record.customerName)) {
              customerGroups[record.customerName] = [];
            }
            customerGroups[record.customerName]!.add(record);
          }

          return ListView.builder(
            itemCount: customerGroups.length,
            itemBuilder: (context, index) {
              String customerName = customerGroups.keys.elementAt(index);
              List<HarvestRecord> customerRecords =
                  customerGroups[customerName]!;

              // Calculate totals for the customer
              double totalCost = customerRecords.fold(
                0,
                (sum, record) => sum + record.totalCost,
              );
              double totalPaid = customerRecords.fold(
                0,
                (sum, record) => sum + record.paidAmount,
              );
              double totalRemaining = totalCost - totalPaid;

              return Card(
                margin: EdgeInsets.all(8.0),
                child: ListTile(
                  title: Text(
                    customerName,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Records: ${customerRecords.length}'),
                      Text('Total Cost: \$${totalCost.toStringAsFixed(2)}'),
                      Text('Paid: \₹${totalPaid.toStringAsFixed(2)}'),
                      Text(
                        'Remaining: \₹${totalRemaining.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: totalRemaining > 0 ? Colors.red : Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CustomerDetailView(
                          customerName: customerName,
                          records: customerRecords,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// Customer Detail View
class CustomerDetailView extends StatelessWidget {
  final String customerName;
  final List<HarvestRecord> records;

  CustomerDetailView({required this.customerName, required this.records});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(customerName), backgroundColor: Colors.green),
      body: ListView.builder(
        itemCount: records.length,
        itemBuilder: (context, index) {
          HarvestRecord record = records[index];
          return Card(
            margin: EdgeInsets.all(8.0),
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Location: ${record.locationName}',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Date: ${DateFormat('MMM dd, yyyy').format(record.harvestDate)}',
                  ),
                  Text('Land Size: ${record.landSize} acres'),
                  Text('Quantity: ${record.harvestQuantity} tons'),
                  Text('Total Cost: \₹${record.totalCost.toStringAsFixed(2)}'),
                  Text('Paid: \₹${record.paidAmount.toStringAsFixed(2)}'),
                  Text(
                    'Remaining: \₹${record.remainingAmount.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: record.remainingAmount > 0
                          ? Colors.red
                          : Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () {
                      _showPaymentDialog(context, record);
                    },
                    child: Text('Update Payment'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showPaymentDialog(BuildContext context, HarvestRecord record) {
    TextEditingController paymentController = TextEditingController(
      text: record.remainingAmount.toStringAsFixed(2),
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Update Payment'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Total Cost: \₹${record.totalCost.toStringAsFixed(2)}'),
              SizedBox(height: 10),
              TextField(
                controller: paymentController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Paid Amount',
                  prefixText: '\₹',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                double newPaidAmount =
                    double.tryParse(paymentController.text) ?? 0;
                double newRemainingAmount = record.totalCost - newPaidAmount;

                await FirebaseFirestore.instance
                    .collection('harvest_records')
                    .doc(record.id)
                    .update({
                      'paidAmount': newPaidAmount,
                      'remainingAmount': newRemainingAmount,
                    });

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Payment updated successfully')),
                );
              },
              child: Text('Update'),
            ),
          ],
        );
      },
    );
  }
}

// Locations View
class LocationsView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Locations'), backgroundColor: Colors.green),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('harvest_records')
            .orderBy('locationName')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No records found'));
          }

          List<HarvestRecord> records = snapshot.data!.docs
              .map((doc) => HarvestRecord.fromFirestore(doc))
              .toList();

          // Group by location
          Map<String, List<HarvestRecord>> locationGroups = {};
          for (var record in records) {
            if (!locationGroups.containsKey(record.locationName)) {
              locationGroups[record.locationName] = [];
            }
            locationGroups[record.locationName]!.add(record);
          }

          return ListView.builder(
            itemCount: locationGroups.length,
            itemBuilder: (context, index) {
              String locationName = locationGroups.keys.elementAt(index);
              List<HarvestRecord> locationRecords =
                  locationGroups[locationName]!;

              return Card(
                margin: EdgeInsets.all(8.0),
                child: ExpansionTile(
                  title: Text(
                    locationName,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('${locationRecords.length} records'),
                  children: locationRecords.map((record) {
                    return ListTile(
                      title: Text(record.customerName),
                      subtitle: Text(
                        'Date: ${DateFormat('MMM dd, yyyy').format(record.harvestDate)}\n'
                        'Size: ${record.landSize} acres, Quantity: ${record.harvestQuantity} tons',
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('\₹${record.totalCost.toStringAsFixed(2)}'),
                          Text(
                            'Remaining: \₹${record.remainingAmount.toStringAsFixed(2)}',
                            style: TextStyle(
                              color: record.remainingAmount > 0
                                  ? Colors.red
                                  : Colors.green,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// Dates View
class DatesView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Harvest Dates'),
        backgroundColor: Colors.green,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('harvest_records')
            .orderBy('harvestDate', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No records found'));
          }

          List<HarvestRecord> records = snapshot.data!.docs
              .map((doc) => HarvestRecord.fromFirestore(doc))
              .toList();

          // Group by date
          Map<String, List<HarvestRecord>> dateGroups = {};
          for (var record in records) {
            String dateKey = DateFormat(
              'MMM dd, yyyy',
            ).format(record.harvestDate);
            if (!dateGroups.containsKey(dateKey)) {
              dateGroups[dateKey] = [];
            }
            dateGroups[dateKey]!.add(record);
          }

          return ListView.builder(
            itemCount: dateGroups.length,
            itemBuilder: (context, index) {
              String dateKey = dateGroups.keys.elementAt(index);
              List<HarvestRecord> dateRecords = dateGroups[dateKey]!;

              return Card(
                margin: EdgeInsets.all(8.0),
                child: ExpansionTile(
                  title: Text(
                    dateKey,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('${dateRecords.length} harvests'),
                  children: dateRecords.map((record) {
                    return ListTile(
                      title: Text(record.customerName),
                      subtitle: Text(
                        'Location: ${record.locationName}\n'
                        'Size: ${record.landSize} acres, Quantity: ${record.harvestQuantity} tons',
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('\₹${record.totalCost.toStringAsFixed(2)}'),
                          Text(
                            'Remaining: \₹${record.remainingAmount.toStringAsFixed(2)}',
                            style: TextStyle(
                              color: record.remainingAmount > 0
                                  ? Colors.red
                                  : Colors.green,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// Add Record View
class AddRecordView extends StatefulWidget {
  @override
  _AddRecordViewState createState() => _AddRecordViewState();
}

class _AddRecordViewState extends State<AddRecordView> {
  final _formKey = GlobalKey<FormState>();
  final _customerNameController = TextEditingController();
  final _locationNameController = TextEditingController();
  final _landSizeController = TextEditingController();
  final _harvestQuantityController = TextEditingController();
  final _totalCostController = TextEditingController();
  final _paidAmountController = TextEditingController(text: '0');

  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  List<String> _existingCustomers = [];
  List<String> _existingLocations = [];
  List<String> _filteredCustomers = [];
  List<String> _filteredLocations = [];
  bool _showCustomerDropdown = false;
  bool _showLocationDropdown = false;

  @override
  void initState() {
    super.initState();
    _loadExistingData();
    _customerNameController.addListener(_onCustomerNameChanged);
    _locationNameController.addListener(_onLocationNameChanged);
  }

  Future<void> _loadExistingData() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('harvest_records')
          .get();

      Set<String> customers = {};
      Set<String> locations = {};

      for (var doc in snapshot.docs) {
        var data = doc.data() as Map<String, dynamic>;
        customers.add(data['customerName'] ?? '');
        locations.add(data['locationName'] ?? '');
      }

      setState(() {
        _existingCustomers = customers.toList()..sort();
        _existingLocations = locations.toList()..sort();
      });
    } catch (e) {
      print('Error loading existing data: $e');
    }
  }

  void _onCustomerNameChanged() {
    String query = _customerNameController.text.toLowerCase();
    setState(() {
      _filteredCustomers = _existingCustomers
          .where((customer) => customer.toLowerCase().contains(query))
          .toList();
      _showCustomerDropdown = query.isNotEmpty && _filteredCustomers.isNotEmpty;
    });
  }

  void _onLocationNameChanged() {
    String query = _locationNameController.text.toLowerCase();
    setState(() {
      _filteredLocations = _existingLocations
          .where((location) => location.toLowerCase().contains(query))
          .toList();
      _showLocationDropdown = query.isNotEmpty && _filteredLocations.isNotEmpty;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add New Record'),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Customer Name Field with Autocomplete
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: _customerNameController,
                    decoration: InputDecoration(
                      labelText: 'Customer Name',
                      border: OutlineInputBorder(),
                      suffixIcon:
                          _existingCustomers.contains(
                            _customerNameController.text,
                          )
                          ? Icon(Icons.check_circle, color: Colors.green)
                          : Icon(Icons.person_add, color: Colors.blue),
                      helperText:
                          _existingCustomers.contains(
                            _customerNameController.text,
                          )
                          ? 'Existing customer'
                          : 'New customer will be added',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter customer name';
                      }
                      return null;
                    },
                  ),
                  if (_showCustomerDropdown)
                    Container(
                      margin: EdgeInsets.only(top: 4),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _filteredCustomers.length,
                        itemBuilder: (context, index) {
                          return ListTile(
                            dense: true,
                            title: Text(_filteredCustomers[index]),
                            onTap: () {
                              _customerNameController.text =
                                  _filteredCustomers[index];
                              setState(() {
                                _showCustomerDropdown = false;
                              });
                            },
                          );
                        },
                      ),
                    ),
                ],
              ),
              SizedBox(height: 16),
              // Location Name Field with Autocomplete
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: _locationNameController,
                    decoration: InputDecoration(
                      labelText: 'Location Name',
                      border: OutlineInputBorder(),
                      suffixIcon:
                          _existingLocations.contains(
                            _locationNameController.text,
                          )
                          ? Icon(Icons.check_circle, color: Colors.green)
                          : Icon(Icons.add_location, color: Colors.blue),
                      helperText:
                          _existingLocations.contains(
                            _locationNameController.text,
                          )
                          ? 'Existing location'
                          : 'New location will be added',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter location name';
                      }
                      return null;
                    },
                  ),
                  if (_showLocationDropdown)
                    Container(
                      margin: EdgeInsets.only(top: 4),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _filteredLocations.length,
                        itemBuilder: (context, index) {
                          return ListTile(
                            dense: true,
                            title: Text(_filteredLocations[index]),
                            onTap: () {
                              _locationNameController.text =
                                  _filteredLocations[index];
                              setState(() {
                                _showLocationDropdown = false;
                              });
                            },
                          );
                        },
                      ),
                    ),
                ],
              ),
              SizedBox(height: 16),
              InkWell(
                onTap: () => _selectDate(context),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Harvest Date',
                    border: OutlineInputBorder(),
                  ),
                  child: Text(DateFormat('MMM dd, yyyy').format(_selectedDate)),
                ),
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _landSizeController,
                decoration: InputDecoration(
                  labelText: 'Land Size (acres)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter land size';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _harvestQuantityController,
                decoration: InputDecoration(
                  labelText: 'Harvest Quantity (tons)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter harvest quantity';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _totalCostController,
                decoration: InputDecoration(
                  labelText: 'Total Cost',
                  prefixText: '\$',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter total cost';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _paidAmountController,
                decoration: InputDecoration(
                  labelText: 'Paid Amount (optional)',
                  prefixText: '\$',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    if (double.tryParse(value) == null) {
                      return 'Please enter a valid number';
                    }
                  }
                  return null;
                },
              ),
              SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _saveRecord,
                child: _isLoading
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text('Save Record'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveRecord() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        double totalCost = double.parse(_totalCostController.text);
        double paidAmount = double.tryParse(_paidAmountController.text) ?? 0;
        double remainingAmount = totalCost - paidAmount;

        HarvestRecord newRecord = HarvestRecord(
          id: '',
          customerName: _customerNameController.text.trim(),
          locationName: _locationNameController.text.trim(),
          harvestDate: _selectedDate,
          landSize: double.parse(_landSizeController.text),
          harvestQuantity: double.parse(_harvestQuantityController.text),
          totalCost: totalCost,
          paidAmount: paidAmount,
          remainingAmount: remainingAmount,
        );

        await FirebaseFirestore.instance
            .collection('harvest_records')
            .add(newRecord.toFirestore());

        // Clear form
        _customerNameController.clear();
        _locationNameController.clear();
        _landSizeController.clear();
        _harvestQuantityController.clear();
        _totalCostController.clear();
        _paidAmountController.text = '0';
        _selectedDate = DateTime.now();

        // Show success message with customer info
        bool isExistingCustomer = _existingCustomers.contains(
          _customerNameController.text,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isExistingCustomer
                  ? 'New harvest added for existing customer!'
                  : 'New customer and harvest record created!',
            ),
            backgroundColor: isExistingCustomer ? Colors.blue : Colors.green,
          ),
        );
        // Refresh the existing data after saving
        await _loadExistingData();
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving record: $e')));
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _customerNameController.removeListener(_onCustomerNameChanged);
    _locationNameController.removeListener(_onLocationNameChanged);
    _customerNameController.dispose();
    _locationNameController.dispose();
    _landSizeController.dispose();
    _harvestQuantityController.dispose();
    _totalCostController.dispose();
    _paidAmountController.dispose();
    super.dispose();
  }
}

// Payment Update View
class PaymentUpdateView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Payment Updates'),
        backgroundColor: Colors.green,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('harvest_records')
            .where('remainingAmount', isGreaterThan: 0)
            .orderBy('remainingAmount', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No pending payments found'));
          }

          List<HarvestRecord> records = snapshot.data!.docs
              .map((doc) => HarvestRecord.fromFirestore(doc))
              .toList();

          return ListView.builder(
            itemCount: records.length,
            itemBuilder: (context, index) {
              HarvestRecord record = records[index];
              return Card(
                margin: EdgeInsets.all(8.0),
                child: ListTile(
                  title: Text(record.customerName),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Location: ${record.locationName}'),
                      Text(
                        'Date: ${DateFormat('MMM dd, yyyy').format(record.harvestDate)}',
                      ),
                      Text('Total: \₹${record.totalCost.toStringAsFixed(2)}'),
                      Text('Paid: \₹${record.paidAmount.toStringAsFixed(2)}'),
                    ],
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '\$${record.remainingAmount.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text('Due', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                  onTap: () {
                    _showQuickPaymentDialog(context, record);
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showQuickPaymentDialog(BuildContext context, HarvestRecord record) {
    TextEditingController paymentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Add Payment'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Customer: ${record.customerName}'),
              Text('Remaining: \₹${record.remainingAmount.toStringAsFixed(2)}'),
              SizedBox(height: 10),
              TextField(
                controller: paymentController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Payment Amount',
                  prefixText: '\₹',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                double paymentAmount =
                    double.tryParse(paymentController.text) ?? 0;
                double newPaidAmount = record.paidAmount + paymentAmount;
                double newRemainingAmount = record.totalCost - newPaidAmount;

                if (newRemainingAmount < 0) newRemainingAmount = 0;

                await FirebaseFirestore.instance
                    .collection('harvest_records')
                    .doc(record.id)
                    .update({
                      'paidAmount': newPaidAmount,
                      'remainingAmount': newRemainingAmount,
                    });

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Payment added successfully')),
                );
              },
              child: Text('Add Payment'),
            ),
          ],
        );
      },
    );
  }
}
