import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:harvest/model/harvestrecord.dart';
import 'package:harvest/pages/homepage.dart';
import 'package:intl/intl.dart';

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
                      Text('Total: \$${record.totalCost.toStringAsFixed(2)}'),
                      Text('Paid: \$${record.paidAmount.toStringAsFixed(2)}'),
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
              Text('Remaining: \$${record.remainingAmount.toStringAsFixed(2)}'),
              SizedBox(height: 10),
              TextField(
                controller: paymentController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Payment Amount',
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
