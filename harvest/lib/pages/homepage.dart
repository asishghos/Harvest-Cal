import 'package:flutter/material.dart';
import 'package:harvest/pages/views/addrecordview.dart';
import 'package:harvest/pages/views/customersview.dart';
import 'package:harvest/pages/views/datesview.dart';
import 'package:harvest/pages/views/locationsview.dart';
import 'package:harvest/pages/views/paymentupdateview.dart';

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
