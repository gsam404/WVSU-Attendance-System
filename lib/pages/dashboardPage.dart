import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:wvsu_attendance_system/pages/sidebar.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  String totalVisits = "0";
  String topDept = "None";
  List<PieChartSectionData> pieSections = [];
  List<Map<String, dynamic>> pieLabels = [];
  List<int> weeklyData = List.filled(7, 0);
  bool isLoading = true;

  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay = DateTime.now();

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    try {
      final response1 = await http.get(Uri.parse('http://localhost/libgate_api/get_dashboard_stats.php'));
      final response2 = await http.get(Uri.parse('http://localhost/libgate_api/get_analytics.php'));

      if (response1.statusCode == 200 && response2.statusCode == 200) {
        final data1 = jsonDecode(response1.body);
        final data2 = jsonDecode(response2.body);

        if (data1['status'] == 'success') {
          final List<dynamic> pieData = data1['pie_stats'] ?? [];
          final List<dynamic> rawWeekly = data2['weekly'] ?? [];

          final List<Color> colors = [
            const Color(0xFF3B82F6), Colors.orange, Colors.green,
            Colors.cyan, Colors.red, Colors.purple, Colors.amber,
          ];

          List<PieChartSectionData> tempSections = [];
          List<Map<String, dynamic>> tempLabels = [];

          double grandTotal = 0;
          for (var item in pieData) {
            grandTotal += double.tryParse(item['value'].toString()) ?? 0.0;
          }

          for (int i = 0; i < pieData.length; i++) {
            double val = double.tryParse(pieData[i]['value'].toString()) ?? 0.0;
            if (val > 0) {
              double pct = grandTotal > 0 ? (val / grandTotal * 100) : 0;
              tempSections.add(PieChartSectionData(
                color: colors[i % colors.length],
                value: val,
                radius: 35, // FIX: increased from 20 to fill the space
                showTitle: false,
              ));
              tempLabels.add({
                "label": pieData[i]['label'] ?? '',
                "color": colors[i % colors.length],
                "pct": pct.toStringAsFixed(1),
              });
            }
          }

          String highestDept = "None";
          if (tempLabels.isNotEmpty) {
            var sorted = List.from(tempLabels)
              ..sort((a, b) => double.parse(b['pct']).compareTo(double.parse(a['pct'])));
            highestDept = sorted.first['label'];
          }

          if (mounted) {
            setState(() {
              totalVisits = data1['total_visits'].toString();
              topDept = highestDept;
              pieSections = tempSections;
              pieLabels = tempLabels;

              weeklyData = List<int>.generate(
                7,
                (i) => i < rawWeekly.length ? (rawWeekly[i] as num).toInt() : 0,
              );

              isLoading = false;
            });
          }
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
                Container(
                  width: double.infinity,
                  color: const Color(0xFFD6D6D6),
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 25),
                  child: const Text(
                    "Dashboard",
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(30),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            _buildStatCard(
                              totalVisits,
                              "Total visits today",
                              Icons.person_outline,
                              Colors.deepPurple,
                            ),
                            const SizedBox(width: 20),
                            _buildStatCard(
                              topDept,
                              "Most visit by Department today",
                              Icons.apartment,
                              Colors.green,
                            ),
                            const SizedBox(width: 20),
                            _buildPieChartCard(),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Expanded(
                          child: Row(
                            children: [
                              Expanded(flex: 2, child: _buildLineChartCard()),
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
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const Spacer(),
            isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    value,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111827),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPieChartCard() {
    return Expanded(
      child: Container(
        height: 160,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Row(
                children: [
                  // FIX: centered pie chart with no hole (centerSpaceRadius: 0)
                  SizedBox(
                    width: 70,
                    height: 70,
                    child: isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : Center(
                            child: PieChart(
                              PieChartData(
                                sectionsSpace: 2,
                                centerSpaceRadius: 0, // FIX: removed hole
                                sections: pieSections.isEmpty
                                    ? [
                                        PieChartSectionData(
                                          color: Colors.grey.shade300,
                                          value: 1,
                                          radius: 35,
                                          showTitle: false,
                                        )
                                      ]
                                    : pieSections,
                              ),
                            ),
                          ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: isLoading
                        ? const SizedBox()
                        : SingleChildScrollView(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: pieLabels.isEmpty
                                  ? [
                                      const Text(
                                        "No data today",
                                        style: TextStyle(fontSize: 10, color: Colors.grey),
                                      )
                                    ]
                                  : pieLabels.map((item) {
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 3),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 9,
                                              height: 9,
                                              decoration: BoxDecoration(
                                                color: item['color'] as Color,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                            const SizedBox(width: 5),
                                            Expanded(
                                              child: Text(
                                                "${item['label']} ${item['pct']}%",
                                                style: const TextStyle(
                                                  fontSize: 10,
                                                  color: Colors.black87,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                            ),
                          ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              "Department visit percentage today",
              style: TextStyle(color: Colors.grey, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLineChartCard() {
    const labels = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];
    final spots = List.generate(
      7,
      (i) => FlSpot(i.toDouble(), weeklyData[i].toDouble()),
    );
    final maxY = weeklyData.isEmpty
        ? 1.0
        : weeklyData.reduce((a, b) => a > b ? a : b).toDouble();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Student Visits Overview",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const Text(
            "Daily breakdown for the current week",
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (value) =>
                            FlLine(color: Colors.grey.shade200, strokeWidth: 1),
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: 1, // FIX: force one label per integer step
                            reservedSize: 28,
                            getTitlesWidget: (value, meta) {
                              // FIX: skip non-integer values to prevent duplicate labels
                              if (value != value.roundToDouble()) {
                                return const SizedBox();
                              }
                              final index = value.toInt();
                              if (index >= 0 && index < labels.length) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    labels[index],
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey,
                                    ),
                                  ),
                                );
                              }
                              return const SizedBox();
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      minX: 0,
                      maxX: 6,
                      minY: 0,
                      maxY: maxY > 0 ? maxY * 1.2 : 10,
                      lineBarsData: [
                        LineChartBarData(
                          spots: spots,
                          isCurved: true,
                          color: const Color(0xFF3B82F6),
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: const FlDotData(show: true),
                          belowBarData: BarAreaData(
                            show: true,
                            color: const Color(0xFF3B82F6).withOpacity(0.1),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: const BoxDecoration(
              color: Color(0xFFA7C7E7),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left, color: Colors.black87),
                  onPressed: () {
                    setState(() {
                      _focusedDay = DateTime(_focusedDay.year, _focusedDay.month - 1);
                    });
                  },
                ),
                GestureDetector(
                  onTap: () => _selectYearAndMonth(context),
                  child: Text(
                    DateFormat('MMMM yyyy').format(_focusedDay),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right, color: Colors.black87),
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
                todayDecoration: BoxDecoration(
                  color: Color(0xFF3B82F6),
                  shape: BoxShape.circle,
                ),
                selectedDecoration: BoxDecoration(
                  color: Color(0xFF1E40AF),
                  shape: BoxShape.circle,
                ),
                defaultTextStyle: TextStyle(fontSize: 12),
              ),
              daysOfWeekStyle: const DaysOfWeekStyle(
                weekdayStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                weekendStyle: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}