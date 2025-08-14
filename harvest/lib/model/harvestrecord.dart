// Model class for Harvest Record
import 'package:cloud_firestore/cloud_firestore.dart';

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
