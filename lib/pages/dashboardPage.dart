import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:wvsu_attendance_system/services/api_service.dart';
import 'package:wvsu_attendance_system/pages/sidebar.dart'; // verify path!

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
        final List<Color> colors = [
          Colors.orange,
          Colors.blue,
          Colors.cyan,
          Colors.yellow,
          Colors.red
        ];

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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 40, vertical: 25),
                  child: const Text(
                    "Dashboard",
                    style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937)),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(30),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            _buildStatCard(totalVisits, "Total visits today",
                                Icons.person_outline, Colors.deepPurple),
                            const SizedBox(width: 20),
                            _buildStatCard(topDept, "Most visit by Dept.",
                                Icons.apartment, Colors.green),
                            const SizedBox(width: 20),
                            _buildPieChartCard(),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Expanded(
                          child: Row(
                            children: [
                              Expanded(
                                  flex: 2,
                                  child: _whiteBox("Student Visits Overview")),
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

  Widget _buildStatCard(
      String value, String label, IconData icon, Color color) {
    return Expanded(
      child: Container(
        height: 160,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(20)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 26),
            const Spacer(),
            isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : Text(value,
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(label,
                style: const TextStyle(color: Colors.grey, fontSize: 13)),
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
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(20)),
        child: (isLoading || pieSections.isEmpty)
            ? const Center(
                child: Icon(Icons.pie_chart, size: 40, color: Colors.grey))
            : PieChart(PieChartData(
                sections: pieSections,
                sectionsSpace: 2,
                centerSpaceRadius: 25)),
      ),
    );
  }

  Widget _whiteBox(String title) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const Text("Daily breakdown of students check in this week",
              style: TextStyle(color: Colors.grey, fontSize: 12)),
          const Spacer(),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("S",
                    style: TextStyle(
                        color: Colors.grey, fontWeight: FontWeight.bold)),
                Text("M",
                    style: TextStyle(
                        color: Colors.grey, fontWeight: FontWeight.bold)),
                Text("T",
                    style: TextStyle(
                        color: Colors.grey, fontWeight: FontWeight.bold)),
                Text("W",
                    style: TextStyle(
                        color: Colors.grey, fontWeight: FontWeight.bold)),
                Text("TH",
                    style: TextStyle(
                        color: Colors.grey, fontWeight: FontWeight.bold)),
                Text("F",
                    style: TextStyle(
                        color: Colors.grey, fontWeight: FontWeight.bold)),
                Text("S",
                    style: TextStyle(
                        color: Colors.grey, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarCard() {
    return Container(
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: const BoxDecoration(
              color: Color(0xFFA7C7E7),
              borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20), topRight: Radius.circular(20)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon:
                      const Icon(Icons.chevron_left, color: Color(0xFF1E3A8A)),
                  onPressed: () {
                    setState(() {
                      _focusedDay =
                          DateTime(_focusedDay.year, _focusedDay.month - 1);
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
                        style: const TextStyle(
                            color: Color(0xFF1E3A8A),
                            fontWeight: FontWeight.bold,
                            fontSize: 16),
                      ),
                      const Icon(Icons.arrow_drop_down,
                          color: Color(0xFF1E3A8A)),
                    ],
                  ),
                ),
                IconButton(
                  icon:
                      const Icon(Icons.chevron_right, color: Color(0xFF1E3A8A)),
                  onPressed: () {
                    setState(() {
                      _focusedDay =
                          DateTime(_focusedDay.year, _focusedDay.month + 1);
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
                todayDecoration: BoxDecoration(
                    color: Color(0xFF3B82F6), shape: BoxShape.circle),
                selectedDecoration: BoxDecoration(
                    color: Color(0xFF1E40AF), shape: BoxShape.circle),
                defaultTextStyle: TextStyle(fontSize: 12),
              ),
              daysOfWeekStyle: const DaysOfWeekStyle(
                weekdayStyle:
                    TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                weekendStyle: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.red),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
