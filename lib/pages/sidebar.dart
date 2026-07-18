import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import './attendance_page.dart';
import './analytics_page.dart';
import './add_admin.dart';
import './student_records_management/student_records_management_page.dart';
import './dashboard_page.dart';
import './acad_setup_page.dart';
import './admin_session.dart';

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

  final sideBarItems = [
    {
      'icon': 'assets/dashboard.png',
      'title': 'Dashboard',
      'page': const DashboardPage()
    },
    {
      'icon': 'assets/analytics.png',
      'title': 'Analytics',
      'page': const AnalyticsPage()
    },
    {
      'icon': 'assets/attendance.png',
      'title': 'Attendance',
      'page': const AttendancePage()
    },
    {
      'icon': 'assets/acadsetup.png',
      'title': 'Academic Setup',
      'page': const AcadSetupPage()
    },
    {
      'icon': 'assets/import.png',
      'title': 'Student Records',
      'page': const StudentRecordsManagementPage()
    },
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

  Widget _buildAvatar(double radius) {
    final String picUrl = AdminSession.profilePicUrl;
    final String initial =
        AdminSession.name.isNotEmpty ? AdminSession.name[0].toUpperCase() : "A";

    if (picUrl.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: const Color(0xFF1B36C2),
        backgroundImage: NetworkImage(picUrl),
        onBackgroundImageError: (_, __) {},
      );
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.white24,
      child: Text(
        initial,
        style: TextStyle(
          color: Colors.white,
          fontSize: radius * 0.8,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  /// Shows the 3-dot popup menu and opens Change Password dialog on tap
  void _showOptionsMenu(BuildContext context) async {
    final RenderBox button = context.findRenderObject() as RenderBox;
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(Offset.zero, ancestor: overlay),
        button.localToGlobal(button.size.bottomRight(Offset.zero),
            ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );

    final selected = await showMenu<String>(
      context: context,
      position: position,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: const Color(0xFF1B36C2),
      items: [
        PopupMenuItem<String>(
          value: 'change_password',
          child: Row(
            children: const [
              Icon(Icons.lock_outline, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text('Change Password',
                  style: TextStyle(color: Colors.white, fontSize: 14)),
            ],
          ),
        ),
      ],
    );

    if (selected == 'change_password' && context.mounted) {
      _showChangePasswordDialog(context);
    }
  }

  /// Change Password bottom-sheet / dialog
  void _showChangePasswordDialog(BuildContext context) {
    final oldPassCtrl = TextEditingController();
    final newPassCtrl = TextEditingController();
    final confirmPassCtrl = TextEditingController();
    bool oldVisible = false;
    bool newVisible = false;
    bool confirmVisible = false;
    bool isLoading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setStateDialog) {
          Future<void> submit() async {
            final oldPass = oldPassCtrl.text.trim();
            final newPass = newPassCtrl.text.trim();
            final confirmPass = confirmPassCtrl.text.trim();

            if (oldPass.isEmpty || newPass.isEmpty || confirmPass.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('All fields are required.')),
              );
              return;
            }

            if (newPass != confirmPass) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('New passwords do not match.')),
              );
              return;
            }

            if (newPass.length < 6) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Password must be at least 6 characters.')),
              );
              return;
            }

            setStateDialog(() => isLoading = true);

            try {
              final response = await http.post(
                Uri.parse('http://localhost/libgate_api/change_password.php'),
                body: {
                  'id': AdminSession.id.toString(),
                  'old_password': oldPass,
                  'new_password': newPass,
                },
              );

              final data = jsonDecode(response.body);

              if (ctx.mounted) {
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(data['message'] ?? 'Done'),
                    backgroundColor:
                        data['success'] == true ? Colors.green : Colors.red,
                  ),
                );
              }
            } catch (e) {
              setStateDialog(() => isLoading = false);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error: $e')),
              );
            }
          }

          return Dialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            backgroundColor: const Color(0xFF0D1B6E),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header ──────────────────────────────────────
                  Row(
                    children: [
                      const Icon(Icons.lock_outline,
                          color: Colors.white, size: 22),
                      const SizedBox(width: 8),
                      const Text(
                        'Change Password',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white70),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ── Current Password ─────────────────────────────
                  _PasswordField(
                    controller: oldPassCtrl,
                    label: 'Current Password',
                    isVisible: oldVisible,
                    onToggle: () =>
                        setStateDialog(() => oldVisible = !oldVisible),
                  ),
                  const SizedBox(height: 14),

                  // ── New Password ─────────────────────────────────
                  _PasswordField(
                    controller: newPassCtrl,
                    label: 'New Password',
                    isVisible: newVisible,
                    onToggle: () =>
                        setStateDialog(() => newVisible = !newVisible),
                  ),
                  const SizedBox(height: 14),

                  // ── Confirm Password ─────────────────────────────
                  _PasswordField(
                    controller: confirmPassCtrl,
                    label: 'Confirm New Password',
                    isVisible: confirmVisible,
                    onToggle: () =>
                        setStateDialog(() => confirmVisible = !confirmVisible),
                  ),
                  const SizedBox(height: 24),

                  // ── Buttons ──────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed:
                            isLoading ? null : () => Navigator.of(ctx).pop(),
                        child: const Text('Cancel',
                            style: TextStyle(color: Colors.white70)),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1B36C2),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                        ),
                        onPressed: isLoading ? null : submit,
                        child: isLoading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2),
                              )
                            : const Text('Update',
                                style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final String name = AdminSession.name;
    final String role = AdminSession.role;
    final String email = AdminSession.email;

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
            Flexible(
              child: ListView(
                padding: EdgeInsets.zero,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: <Widget>[
                        Image.asset('assets/imageTwo.png',
                            width: 75, height: 75),
                        if (isFullyExpanded)
                          const Text(
                            'WVSU Library Attendance',
                            style: TextStyle(
                              fontSize: 20,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 15),
                  Align(
                    alignment:
                        isExpanded ? Alignment.centerRight : Alignment.center,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: FloatingActionButton.small(
                        onPressed: _toggleSidebar,
                        backgroundColor:
                            const Color.fromARGB(255, 30, 100, 190),
                        child: Icon(
                          isExpanded ? Icons.chevron_left : Icons.chevron_right,
                          color: Colors.white,
                        ),
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
                          MaterialPageRoute(
                            builder: (context) => item['page'] as Widget,
                          ),
                        );
                      },
                    );
                  }),
                ],
              ),
            ),

            // ── PROFILE SECTION ──────────────────────────────────────
            Padding(
              padding: EdgeInsets.only(
                left: isFullyExpanded ? 10 : 0,
                right: 4,
                bottom: 30,
              ),
              child: isFullyExpanded
                  ? Row(
                      children: [
                        ProfilePopUp(child: _buildAvatar(37)),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name.isNotEmpty ? name : 'Admin',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                role.isNotEmpty ? role : email,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        // ── 3-dot menu button ────────────────────────
                        Builder(
                          builder: (menuContext) => IconButton(
                            icon: const Icon(Icons.more_vert,
                                color: Colors.white70, size: 20),
                            tooltip: 'Options',
                            onPressed: () => _showOptionsMenu(menuContext),
                          ),
                        ),
                      ],
                    )
                  : Center(
                      child: ProfilePopUp(child: _buildAvatar(26)),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Reusable password text field ─────────────────────────────────────────────
class _PasswordField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool isVisible;
  final VoidCallback onToggle;

  const _PasswordField({
    required this.controller,
    required this.label,
    required this.isVisible,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: !isVisible,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white60),
        filled: true,
        fillColor: Colors.white10,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.white38),
        ),
        suffixIcon: IconButton(
          icon: Icon(
            isVisible ? Icons.visibility_off : Icons.visibility,
            color: Colors.white54,
            size: 20,
          ),
          onPressed: onToggle,
        ),
      ),
    );
  }
}

// ── SideBarItems (unchanged) ─────────────────────────────────────────────────
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
      padding: EdgeInsets.symmetric(
        horizontal: isExpanded ? 25.0 : 8.0,
        vertical: 8.0,
      ),
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
                  child: Image.asset(
                    assetPath,
                    fit: BoxFit.contain,
                    color: Colors.white,
                  ),
                ),
                title: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 24,
                    color: Colors.white,
                    fontWeight: FontWeight.w300,
                  ),
                ),
                onTap: onTap,
              )
            : IconButton(
                icon: Image.asset(
                  assetPath,
                  width: 28,
                  height: 28,
                  color: Colors.white,
                ),
                iconSize: 32,
                onPressed: onTap,
                tooltip: title,
              ),
      ),
    );
  }
}
