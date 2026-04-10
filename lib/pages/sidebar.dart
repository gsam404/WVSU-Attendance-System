import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:convert';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';


import './attendancepage.dart';
import './analyticspage.dart';
import './addAdmin.dart';
import './importpage.dart';

import '../services/api_service.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  String totalVisits = "0";
  String topDept = "None";
  List<PieChartSectionData> pieSections = [];
  bool isLoading = true;

  // Calendar State
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay = DateTime.now();

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    try {
      final data = await ApiService().getDashboardStats();
      if (data != null && data['status'] == 'success') {
        final List<dynamic> pieData = data['pie_stats'] ?? [];
        final List<Color> colors = [Colors.orange, Colors.blue, Colors.cyan, Colors.yellow, Colors.red];

        List<PieChartSectionData> tempSections = [];
        for (int i = 0; i < pieData.length; i++) {
          double val = double.tryParse(pieData[i]['count'].toString()) ?? 0.0;
          if (val > 0) {
            tempSections.add(PieChartSectionData(
              color: colors[i % colors.length],
              value: val,
              radius: 30,
              showTitle: false,
            ));
          }
        }

        if (mounted) {
          setState(() {
            totalVisits = data['total_today'].toString();
            topDept = data['top_dept']?.toString() ?? "No Logs";
            pieSections = tempSections;
            isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint("Dashboard Error: $e");
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _selectYearAndMonth(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _focusedDay,
      firstDate: DateTime.utc(2000, 1, 1),
      lastDate: DateTime.utc(DateTime.now().year + 100, 12, 31),
      helpText: 'SELECT CALENDAR VIEW',
    );
    if (picked != null && picked != _focusedDay) {
      setState(() {
        _focusedDay = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE5E5E5),
      body: Row(
        children: [
          const SideBar(selectedIndex: 0),
          Expanded(
            child: Column(
              children: [
                
                // HEADER - Restored 
                Container(
                  width: double.infinity,
                  color: const Color(0xFFD6D6D6),
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 25),
                  child: const Text(
                    "Dashboard",
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(30),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            _buildStatCard(totalVisits, "Total visits today", Icons.person_outline, Colors.deepPurple),
                            const SizedBox(width: 20),
                            _buildStatCard(topDept, "Most visit by Dept.", Icons.apartment, Colors.green),
                            const SizedBox(width: 20),
                            _buildPieChartCard(),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Expanded(
                          child: Row(
                            children: [
                              Expanded(flex: 2, child: _whiteBox("Student Visits Overview")),
                              const SizedBox(width: 20),
                              Expanded(flex: 1, child: _buildCalendarCard()),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String value, String label, IconData icon, Color color) {
    return Expanded(
      child: Container(
        height: 160,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 26),
            const Spacer(),
            isLoading
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildPieChartCard() {
    return Expanded(
      child: Container(
        height: 160,
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
        child: (isLoading || pieSections.isEmpty)
            ? const Center(child: Icon(Icons.pie_chart, size: 40, color: Colors.grey))
            : PieChart(PieChartData(sections: pieSections, sectionsSpace: 2, centerSpaceRadius: 25)),
      ),
    );
  }

  Widget _whiteBox(String title) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const Text("Daily breakdown of students check in this week", style: TextStyle(color: Colors.grey, fontSize: 12)),
          const Spacer(),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("S", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                Text("M", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                Text("T", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                Text("W", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                Text("TH", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                Text("F", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                Text("S", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarCard() {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: const BoxDecoration(
              color: Color(0xFFA7C7E7),
              borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left, color: Color(0xFF1E3A8A)),
                  onPressed: () {
                    setState(() {
                      _focusedDay = DateTime(_focusedDay.year, _focusedDay.month - 1);
                    });
                  },
                ),
                InkWell(
                  onTap: () => _selectYearAndMonth(context),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        DateFormat('MMMM, yyyy').format(_focusedDay),
                        style: const TextStyle(color: Color(0xFF1E3A8A), fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const Icon(Icons.arrow_drop_down, color: Color(0xFF1E3A8A)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right, color: Color(0xFF1E3A8A)),
                  onPressed: () {
                    setState(() {
                      _focusedDay = DateTime(_focusedDay.year, _focusedDay.month + 1);
                    });
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: TableCalendar(
              firstDay: DateTime.utc(2000, 1, 1),
              lastDay: DateTime.utc(DateTime.now().year + 100, 12, 31),
              focusedDay: _focusedDay,
              headerVisible: false,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              },
              onPageChanged: (focusedDay) {
                setState(() {
                  _focusedDay = focusedDay;
                });
              },
              calendarStyle: const CalendarStyle(
                todayDecoration: BoxDecoration(color: Color(0xFF3B82F6), shape: BoxShape.circle),
                selectedDecoration: BoxDecoration(color: Color(0xFF1E40AF), shape: BoxShape.circle),
                defaultTextStyle: TextStyle(fontSize: 12),
              ),
              daysOfWeekStyle: const DaysOfWeekStyle(
                weekdayStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                weekendStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.red),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// SIDEBAR CLASSES (SideBar, SideBarItems) REMAIN UNCHANGED BELOW THIS POINT
class SideBar extends StatefulWidget {
  final int selectedIndex;
  const SideBar({super.key, required this.selectedIndex});
  @override
  State<SideBar> createState() => _SideBarState();
}

class _SideBarState extends State<SideBar> {
  late int selectedIndex;
  bool isExpanded = true;
  bool isFullyExpanded = true;
  String name = 'Elra Di M. Madalogdog';
  String occupation = 'University Librarian';

  final sideBarItems = [
    {'icon': 'assets/dashboard.png', 'title': 'Dashboard', 'page': const DashboardPage()},
    {'icon': 'assets/analytics.png', 'title': 'Analytics', 'page': const AnalyticsPage()},
    {'icon': 'assets/attendance.png', 'title': 'Attendance', 'page': const AttendancePage()},
    {'icon': 'assets/import.png', 'title': 'Import', 'page': const ImportPage()},
  ];

  @override
  void initState() {
    super.initState();
    selectedIndex = widget.selectedIndex;
  }

  void _toggleSidebar() {
    if (isExpanded) {
      setState(() {
        isExpanded = false;
        isFullyExpanded = false;
      });
    } else {
      setState(() => isExpanded = true);
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) setState(() => isFullyExpanded = true);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: isExpanded ? 402 : 80,
      child: Container(
        clipBehavior: Clip.hardEdge,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/Rectangle.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: <Widget>[
                        Image.asset('assets/imageTwo.png', width: 75, height: 75),
                        if (isFullyExpanded)
                          const Text(
                            'WVSU LIBRARY ATTENDANCE',
                            style: TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 15),
                  Align(
                    alignment: isExpanded ? Alignment.centerRight : Alignment.center,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: FloatingActionButton.small(
                        onPressed: _toggleSidebar,
                        backgroundColor: const Color.fromARGB(255, 30, 100, 190),
                        child: Icon(isExpanded ? Icons.chevron_left : Icons.chevron_right, color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  ...sideBarItems.asMap().entries.map((entry) {
                    int index = entry.key;
                    var item = entry.value;
                    return SideBarItems(
                      assetPath: item['icon'] as String,
                      title: item['title'] as String,
                      destination: item['page'] as Widget,
                      isSelected: selectedIndex == index,
                      isExpanded: isFullyExpanded,
                      onTap: () {
                        setState(() => selectedIndex = index);
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => item['page'] as Widget),
                        );
                      },
                    );
                  }).toList(),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.only(left: isFullyExpanded ? 20 : 0, bottom: 30),
              child: isFullyExpanded
                  ? ProfilePopUp(
                      child: Align(
                        alignment: Alignment.bottomLeft,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CircleAvatar(
                              radius: 37,
                              backgroundColor: Colors.grey,
                              backgroundImage: AssetImage('assets/profile.png'),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                Text(occupation, style: const TextStyle(color: Colors.white70, fontSize: 14.0)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    )
                  : const CircleAvatar(radius: 26, backgroundImage: AssetImage('assets/profile.png')),
            ),
          ],
        ),
      ),
    );
  }
}

class SideBarItems extends StatelessWidget {
  final String assetPath;
  final String title;
  final Widget destination;
  final bool isSelected;
  final bool isExpanded;
  final VoidCallback onTap;

  const SideBarItems({
    super.key,
    required this.assetPath,
    required this.title,
    required this.destination,
    required this.isSelected,
    required this.onTap,
    required this.isExpanded,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isExpanded ? 25.0 : 8.0, vertical: 8.0),
      child: Container(
        decoration: isSelected
            ? BoxDecoration(
                color: const Color(0x52FAF2F2),
                border: Border.all(color: Colors.white, width: 2),
                borderRadius: BorderRadius.circular(15),
              )
            : null,
        child: isExpanded
            ? ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12.0),
                leading: SizedBox(
                  width: 32,
                  height: 32,
                  child: Image.asset(assetPath, fit: BoxFit.contain, color: Colors.white),
                ),
                title: Text(title, style: const TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.w300)),
                onTap: onTap,
              )
            : IconButton(
                icon: Image.asset(assetPath, width: 28, height: 28, color: Colors.white),
                iconSize: 32,
                onPressed: onTap,
                tooltip: title,
              ),
      ),
    );
  }
}