import 'dart:async';
import 'package:flutter/material.dart';
import 'package:wvsu_attendance_system/pages/sidebar.dart';
import 'package:wvsu_attendance_system/services/api_service.dart';

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  final ApiService apiService = ApiService();

  String peakDay = "None";
  String topDepartment = "None";
  String topCourse = "None";

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
    try {
      final data = await apiService.getAnalytics();
      if (!mounted) return;
      if (data != null) {
        setState(() {
          weeklyData = List<int>.from(data['weekly'] ?? List.filled(7, 0));
          var rawMonthly = data['monthly'] ?? [];
          monthlyData = List<int>.generate(12, (i) => i < rawMonthly.length ? rawMonthly[i] : 0);
          peakDay = data['peakDay'] ?? "None";
          topDepartment = data['topDepartment'] ?? "None";
          topCourse = data['topCourse'] ?? "None";
        });
      }
    } catch (e) {
      debugPrint("Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<String> weeklyLabels = ["S", "M", "T", "W", "TH", "F", "S"];
    final List<String> monthlyLabels = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
    
    final currentLabels = selectedRange == "Weekly" ? weeklyLabels : monthlyLabels;
    final currentData = selectedRange == "Weekly" ? weeklyData : monthlyData;

    return Scaffold(
      backgroundColor: const Color(0xFFE5E5E5), // Matches Figma background
      body: Row(
        children: [
          const SideBar(selectedIndex: 1),
          Expanded(
            child: Column(
              children: [
                
                // HEADER - 
                Container(
                  width: double.infinity,
                  color: const Color(0xFFD6D6D6), 
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 25),
                  child: const Text(
                    "Analytics",
                    style: TextStyle(
                      fontSize: 24, 
                      fontWeight: FontWeight.bold, 
                      color: Color(0xFF1F2937),
                    ),
                  ),
                ),

                // MAIN CONTENT AREA - No Scrolling
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(40.0),
                    child: Column(
                      children: [
                        // STAT CARDS - Using AspectRatio to keep them consistent
                        Row(
                          children: [
                            Expanded(child: _buildStatCard("Peak traffic day", peakDay, Icons.wb_sunny_outlined, Colors.orange)),
                            const SizedBox(width: 25),
                            Expanded(child: _buildStatCard("Most visited by Department", topDepartment, Icons.apartment, Colors.green)),
                            const SizedBox(width: 25),
                            Expanded(child: _buildStatCard("Most visited by Course", topCourse, Icons.groups_outlined, Colors.blue)),
                          ],
                        ),

                        const SizedBox(height: 30),

                        // CHART CONTAINER - Occupies remaining space
                        Expanded(
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(35),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          "Student Visits Overview", 
                                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          selectedRange == "Weekly"
                                              ? "Daily breakdown of student check-ins"
                                              : "Monthly breakdown of student check-ins",
                                          style: const TextStyle(fontSize: 14, color: Colors.grey),
                                        ),
                                      ],
                                    ),
                                    _buildToggleContainer(),
                                  ],
                                ),
                                
                                // CHART BARS 
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.only(top: 40),
                                    child: LayoutBuilder(
                                      builder: (context, constraints) {
                                        return Row(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: List.generate(currentData.length, (i) {
                                            return Expanded(
                                              child: Column(
                                                mainAxisAlignment: MainAxisAlignment.end,
                                                children: [
                                                  _buildBar(
                                                    currentData[i].toDouble(), 
                                                    constraints.maxHeight * 0.8, // Scale bar to container height
                                                    selectedRange == "Weekly" ? i == 3 : false, 
                                                    selectedRange == "Monthly",
                                                  ),
                                                  const SizedBox(height: 15),
                                                  Text(
                                                    currentLabels[i],
                                                    style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500),
                                                  ),
                                                ],
                                              ),
                                            );
                                          }),
                                        );
                                      }
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
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      // Height set via AspectRatio or fixed value for consistency
      height: 160, 
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w500)),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, size: 18, color: color),
              ),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleContainer() {
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
          boxShadow: active ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)] : null,
        ),
        child: Text(
          label,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: active ? Colors.black : Colors.grey),
        ),
      ),
    );
  }

  Widget _buildBar(double value, double maxHeight, bool highlight, bool isMonthly) {
    // Dynamic height calculation based on input data
    double barHeight = (value * 10).clamp(10, maxHeight); 

    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      width: isMonthly ? 18 : 45,
      height: barHeight,
      decoration: BoxDecoration(
        color: highlight ? const Color(0xFF3B82F6) : const Color(0xFFD1D5DB).withOpacity(0.6),
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}