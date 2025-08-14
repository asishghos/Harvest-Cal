// Customers View
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:harvest/model/harvestrecord.dart';
import 'package:harvest/pages/homepage.dart';
import 'package:harvest/pages/views/customerdetailsview.dart';
import 'package:intl/intl.dart';

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
                      Text('Paid: \$${totalPaid.toStringAsFixed(2)}'),
                      Text(
                        'Remaining: \$${totalRemaining.toStringAsFixed(2)}',
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
