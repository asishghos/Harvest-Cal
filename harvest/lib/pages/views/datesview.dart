// Dates View
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:harvest/model/harvestrecord.dart';
import 'package:harvest/pages/homepage.dart';
import 'package:intl/intl.dart';

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
                          Text('\$${record.totalCost.toStringAsFixed(2)}'),
                          Text(
                            'Remaining: \$${record.remainingAmount.toStringAsFixed(2)}',
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
