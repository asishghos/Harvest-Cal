import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:harvest/model/harvestrecord.dart';
import 'package:harvest/pages/homepage.dart';
import 'package:intl/intl.dart';

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
              TextFormField(
                controller: _customerNameController,
                decoration: InputDecoration(
                  labelText: 'Customer Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter customer name';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _locationNameController,
                decoration: InputDecoration(
                  labelText: 'Location Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter location name';
                  }
                  return null;
                },
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

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Record saved successfully!')));
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
    _customerNameController.dispose();
    _locationNameController.dispose();
    _landSizeController.dispose();
    _harvestQuantityController.dispose();
    _totalCostController.dispose();
    _paidAmountController.dispose();
    super.dispose();
  }
}
