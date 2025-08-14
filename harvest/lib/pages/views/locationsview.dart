// Locations View
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:harvest/model/harvestrecord.dart';
import 'package:harvest/pages/homepage.dart';
import 'package:intl/intl.dart';

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
