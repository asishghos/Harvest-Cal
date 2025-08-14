// Customer Detail View
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:harvest/model/harvestrecord.dart';
import 'package:harvest/pages/homepage.dart';
import 'package:intl/intl.dart';

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
                  Text('Total Cost: \$${record.totalCost.toStringAsFixed(2)}'),
                  Text('Paid: \$${record.paidAmount.toStringAsFixed(2)}'),
                  Text(
                    'Remaining: \$${record.remainingAmount.toStringAsFixed(2)}',
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
      text: record.paidAmount.toString(),
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Update Payment'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Total Cost: \$${record.totalCost.toStringAsFixed(2)}'),
              SizedBox(height: 10),
              TextField(
                controller: paymentController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Paid Amount',
                  prefixText: '\$',
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
