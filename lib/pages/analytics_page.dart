import 'dart:async';
import 'package:flutter/material.dart';
import 'package:wvsu_attendance_system/pages/sidebar.dart';
import 'package:wvsu_attendance_system/pages/admin_session.dart'; // ← ADD
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:wvsu_attendance_system/config/api_config.dart';

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  String weeklyPeakDay = "None";
  String weeklyTopDepartment = "None";
  String weeklyTopCourse = "None";

  String monthlyPeakMonth = "None";
  String monthlyTopDepartment = "None";
  String monthlyTopCourse = "None";

  List<int> weeklyData = List.filled(7, 0);
  List<int> monthlyData = List.filled(12, 0);

  String selectedRange = "Weekly";
  Timer? timer;

  @override
  void initState() {
    super.initState();
    loadAnalytics();
    timer = Timer.periodic(const Duration(seconds: 5), (_) => loadAnalytics());
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  Future<void> loadAnalytics() async {
    // ── FIX: pass admin_id so analytics are scoped to this admin ─────────────
    final adminId = AdminSession.id;
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.analytics}?admin_id=$adminId'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (mounted) {
          setState(() {
            if (data['weekly'] != null) {
              weeklyData = List<int>.from(
                data['weekly'].map((x) => int.parse(x.toString())),
              );
            }
            if (data['monthly'] != null) {
              monthlyData = List<int>.from(
                data['monthly'].map((x) => int.parse(x.toString())),
              );
            }

            weeklyPeakDay = data['weeklyPeakDay'] ?? "None";
            weeklyTopDepartment = data['weeklyTopDepartment'] ?? "None";
            weeklyTopCourse = data['weeklyTopCourse'] ?? "None";

            monthlyPeakMonth = data['monthlyPeakMonth'] ?? "None";
            monthlyTopDepartment = data['monthlyTopDepartment'] ?? "None";
            monthlyTopCourse = data['monthlyTopCourse'] ?? "None";
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading analytics: $e');
    }
  }

  String get peakLabel =>
      selectedRange == "Weekly" ? weeklyPeakDay : monthlyPeakMonth;
  String get topDepartment =>
      selectedRange == "Weekly" ? weeklyTopDepartment : monthlyTopDepartment;
  String get topCourse =>
      selectedRange == "Weekly" ? weeklyTopCourse : monthlyTopCourse;
  String get peakCardTitle =>
      selectedRange == "Weekly" ? "Peak traffic day" : "Peak traffic month";

  @override
  Widget build(BuildContext context) {
    final weeklyLabels = ["S", "M", "T", "W", "TH", "F", "S"];
    final monthlyLabels = [
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec"
    ];

    final currentLabels =
        selectedRange == "Weekly" ? weeklyLabels : monthlyLabels;
    final currentData = selectedRange == "Weekly" ? weeklyData : monthlyData;
    final maxValue =
        currentData.isEmpty ? 1 : currentData.reduce((a, b) => a > b ? a : b);

    return Scaffold(
      backgroundColor: const Color(0xFFE5E5E5),
      body: Row(
        children: [
          const SideBar(selectedIndex: 1),
          Expanded(
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  color: const Color(0xFFD6D6D6),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 40, vertical: 25),
                  child: const Text(
                    "Analytics",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 155,
                                child: _buildStatCard(
                                  peakCardTitle,
                                  peakLabel,
                                  Icons.wb_sunny_outlined,
                                  Colors.orange,
                                ),
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: SizedBox(
                                height: 155,
                                child: _buildStatCard(
                                  "Most visited by Department",
                                  topDepartment,
                                  Icons.apartment,
                                  Colors.green,
                                ),
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: SizedBox(
                                height: 155,
                                child: _buildStatCard(
                                  "Most visited by Course",
                                  topCourse,
                                  Icons.groups_outlined,
                                  Colors.blue,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 30),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(35),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          "Student Visits Overview",
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          selectedRange == "Weekly"
                                              ? "Daily breakdown this week"
                                              : "Monthly breakdown this year",
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                    _buildToggleSwitch(),
                                  ],
                                ),
                                const SizedBox(height: 30),
                                Expanded(
                                  child: LayoutBuilder(
                                    builder: (context, constraints) {
                                      final maxHeight =
                                          constraints.maxHeight - 30;
                                      return Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceEvenly,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: List.generate(
                                            currentData.length, (i) {
                                          return Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.end,
                                            children: [
                                              _buildBar(
                                                currentData[i].toDouble(),
                                                maxValue.toDouble(),
                                                maxHeight,
                                                selectedRange == "Monthly",
                                              ),
                                              const SizedBox(height: 10),
                                              Text(
                                                currentLabels[i],
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                            ],
                                          );
                                        }),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
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
      String title, String value, IconData icon, Color iconColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(title,
                  style: const TextStyle(fontSize: 13, color: Colors.grey)),
              const SizedBox(height: 10),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
            ],
          ),
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleSwitch() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [_buildToggle("Weekly"), _buildToggle("Monthly")],
      ),
    );
  }

  Widget _buildToggle(String label) {
    final active = selectedRange == label;
    return GestureDetector(
      onTap: () => setState(() => selectedRange = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: active ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: active ? Colors.black : Colors.grey,
          ),
        ),
      ),
    );
  }

  Widget _buildBar(
      double value, double maxValue, double maxHeight, bool isMonthly) {
    if (value <= 0) {
      return SizedBox(width: isMonthly ? 20 : 30);
    }
    final ratio = maxValue > 0 ? value / maxValue : 0.0;
    final barHeight = (ratio * maxHeight).clamp(4.0, maxHeight);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      height: barHeight,
      width: isMonthly ? 20 : 30,
      decoration: BoxDecoration(
        color: const Color(0xFF3B82F6),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
