import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:convert';
import '../services/api_service.dart'; // Ensure this path is correct
import './attendancepage.dart';
import './analyticspage.dart';
import './addAdmin.dart';

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
            tempSections.add(
              PieChartSectionData(
                color: colors[i % colors.length],
                value: val,
                radius: 25,
                showTitle: false,
              ),
            );
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
      } else {
        if (mounted) setState(() => isLoading = false);
      }
    } catch (e) {
      debugPrint("Dashboard Error: $e");
      if (mounted) setState(() => isLoading = false);
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Dashboard", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 30),
                  Row(
                    children: [
                      _buildStatCard(totalVisits, "Total visits today", Icons.person_outline, Colors.deepPurple),
                      const SizedBox(width: 20),
                      _buildStatCard(topDept, "Most visit by Dept.", Icons.apartment, Colors.green),
                      const SizedBox(width: 20),
                      _buildPieChartCard(),
                    ],
                  ),
                  const SizedBox(height: 30),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 2, child: _whiteBox("Student Visits Overview", height: 450)),
                      const SizedBox(width: 20),
                      Expanded(flex: 1, child: _whiteBox("February, 2026", height: 450)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String value, String label, IconData icon, Color color) {
    return Expanded(
      child: Container(
        height: 200,
        padding: const EdgeInsets.all(25),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(25)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 28),
            ),
            const Spacer(),
            isLoading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
            Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
          ],
        ),
      ),
    );
  }

Widget _buildPieChartCard() {
  return Expanded(
    child: Container(
      height: 200,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        children: [
          Expanded(
            child: (isLoading || pieSections.isEmpty)
                ? const Center(
                    child: Icon(
                      Icons.pie_chart_outline,
                      color: Colors.grey,
                      size: 40,
                    ),
                  )
                : PieChart(
                    PieChartData(
                      sections: pieSections,
                      sectionsSpace: 2,
                      centerSpaceRadius: 30,
                    ),
                  ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              "Department visit percentage today",
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ),
        ],
      ),
    ),
  );
}
  Widget _whiteBox(String title, {double? height}) {
    return Container(
      height: height,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(25)),
      child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
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