import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:wvsu_attendance_system/pages/sidebar.dart';
import 'package:wvsu_attendance_system/pages/admin_session.dart';
import '../widgets/academic_dialog.dart';
import '../utils/validators.dart';
import '../utils/dialogs.dart';
import 'package:wvsu_attendance_system/config/api_config.dart';

// ─── Data Models ────────────────────────────────────────────────────────────
// ProgramModel & DepartmentModel

class ProgramModel {
  int? id;
  String name;
  String code;
  ProgramModel({this.id, required this.name, required this.code});
}

class DepartmentModel {
  int? id;
  String name;
  String code;
  bool isExpanded;
  List<ProgramModel> programs;

  DepartmentModel({
    this.id,
    required this.name,
    required this.code,
    this.isExpanded = false,
    List<ProgramModel>? programs,
  }) : programs = programs ?? [];

  void dispose() {}
}

// AcadSetupPage

class AcadSetupPage extends StatefulWidget {
  const AcadSetupPage({super.key});

  @override
  State<AcadSetupPage> createState() => _AcadSetupPageState();
}

class _AcadSetupPageState extends State<AcadSetupPage> {
  final List<DepartmentModel> _departments = [];

  DepartmentModel? _selectedDepartment;
  ProgramModel? _selectedProgram;

  final String apiUrl = ApiConfig.academic;

  bool _isLoading = true;

  final _deptNameCtrl = TextEditingController();
  final _deptCodeCtrl = TextEditingController();
  final _searchCtrl = TextEditingController();

  final String _searchQuery = '';

  String get _adminId => AdminSession.id;

  int get _totalPrograms =>
      _departments.fold(0, (sum, d) => sum + d.programs.length);

  List<DepartmentModel> get _filtered {
    if (_searchQuery.isEmpty) return _departments;
    final q = _searchQuery.toLowerCase();
    return _departments.where((d) {
      if (d.name.toLowerCase().contains(q) ||
          d.code.toLowerCase().contains(q)) {
        return true;
      }
      return d.programs.any((c) =>
          c.name.toLowerCase().contains(q) || c.code.toLowerCase().contains(q));
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(
        Uri.parse('$apiUrl?action=fetch&admin_id=$_adminId'),
      );
      print(response.statusCode);
      print(response.body);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          _departments.clear();
          for (var d in data['data']) {
            List<ProgramModel> programsList = [];
            if (d['programs'] != null) {
              for (var c in d['programs']) {
                programsList.add(ProgramModel(
                  id: int.parse(c['id'].toString()),
                  name: c['name'],
                  code: c['code'],
                ));
              }
            }
            _departments.add(DepartmentModel(
              id: int.parse(d['id'].toString()),
              name: d['name'],
              code: d['code'],
              programs: programsList,
            ));
          }
        }
      }
    } /*catch (e) {
      _showSnack('Error loading data from database');
    } */

    catch (e) {
      print(e);
      _showSnack(e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // _addDepartment

  Future<void> _addDepartment() async {
    final name = Validators.normalize(_deptNameCtrl.text);
    final code = Validators.normalize(_deptCodeCtrl.text);

    String? error = Validators.required(name, "Department Name");
    if (error != null) {
      await DialogUtils.showError(
        context,
        error,
      );
      return;
    }

    error = Validators.required(code, "Department Code");
    if (error != null) {
      await DialogUtils.showError(
        context,
        error,
      );
      return;
    }

    if (name.isEmpty || code.isEmpty) return;

    try {
      final response = await http.post(Uri.parse(apiUrl), body: {
        'action': 'add_dept',
        'name': name,
        'code': code,
        'admin_id': _adminId,
      });
      final data = jsonDecode(response.body);

      if (data['status'] == 'success') {
        _deptNameCtrl.clear();
        _deptCodeCtrl.clear();

        await _fetchData();

        await DialogUtils.showSuccess(
          context,
          'Department "$code" added successfully.',
        );
      } else {
        _showSnack('Failed to save to database.');
      }
    } catch (e) {
      _showSnack('Network Error: Could not connect to server.');
    }
  }

// showEditDepartmentDialog & _showEditProgramDialog
  void _showEditDepartmentDialog(DepartmentModel department) {
    final codeController = TextEditingController(text: department.code);
    final nameController = TextEditingController(text: department.name);

    String? codeError;
    String? nameError;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AcademicDialog(
              title: "Edit Department",
              codeLabel: "Department Code",
              nameLabel: "Department Name",
              codeController: codeController,
              nameController: nameController,
              codeError: codeError,
              nameError: nameError,
              showDelete: true,
              deleteEnabled: department.programs.isEmpty,
              onDelete: () async {
                Navigator.pop(dialogContext);
                await _deleteDepartment(department);
              },
              onSave: () async {
                final code = Validators.normalize(codeController.text);
                final name = Validators.normalize(nameController.text);

                // Clear previous errors
                codeError = null;
                nameError = null;

                // Required validation
                final codeRequired =
                    Validators.required(code, "Department Code");
                final nameRequired =
                    Validators.required(name, "Department Name");

                // Letters only validation
                final codeLetters = codeRequired == null
                    ? Validators.lettersOnly(
                        code,
                        "Department Code",
                      )
                    : null;

                final nameLetters = nameRequired == null
                    ? Validators.lettersOnly(
                        name,
                        "Department Name",
                      )
                    : null;

                // Duplicate validation
                final duplicateCode = Validators.isDuplicate(
                  code,
                  _departments.map((d) => d.code),
                  ignore: department.code,
                );

                final duplicateName = Validators.isDuplicate(
                  name,
                  _departments.map((d) => d.name),
                  ignore: department.name,
                );

                // Show all errors
                setDialogState(() {
                  codeError = codeRequired ??
                      codeLetters ??
                      (duplicateCode
                          ? "Department Code already exists."
                          : null);

                  nameError = nameRequired ??
                      nameLetters ??
                      (duplicateName
                          ? "Department Name already exists."
                          : null);
                });

                if (codeError != null || nameError != null) {
                  return;
                }

                Navigator.pop(dialogContext);

                await _editDepartment(
                  department,
                  name,
                  code,
                );
              },
            );
          },
        );
      },
    );
  }

  void _showEditProgramDialog(
    DepartmentModel department,
    ProgramModel program,
  ) {
    final codeController = TextEditingController(text: program.code);
    final nameController = TextEditingController(text: program.name);

    String? codeError;
    String? nameError;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AcademicDialog(
              title: "Edit Program",
              departmentLabel: "Department",
              departmentValue: "${department.name} - ${department.code}",
              codeLabel: "Program Code",
              nameLabel: "Program Name",
              codeController: codeController,
              nameController: nameController,
              codeError: codeError,
              nameError: nameError,
              showDelete: true,
              onDelete: () {
                Navigator.pop(dialogContext);
                _deleteProgram(program);
              },
              onSave: () async {
                final code = Validators.normalize(codeController.text);
                final name = Validators.normalize(nameController.text);

                codeError = null;
                nameError = null;

                // Required
                final codeRequired = Validators.required(code, "Program Code");

                final nameRequired = Validators.required(name, "Program Name");

                // Letters only
                final codeLetters = codeRequired == null
                    ? Validators.lettersOnly(
                        code,
                        "Program Code",
                      )
                    : null;

                final nameLetters = nameRequired == null
                    ? Validators.lettersOnly(
                        name,
                        "Program Name",
                      )
                    : null;

                // Duplicate across ALL departments
                final duplicateCode = Validators.isDuplicate(
                  code,
                  _departments.expand((d) => d.programs).map((p) => p.code),
                  ignore: program.code,
                );

                final duplicateName = Validators.isDuplicate(
                  name,
                  _departments.expand((d) => d.programs).map((p) => p.name),
                  ignore: program.name,
                );

                setDialogState(() {
                  codeError = codeRequired ??
                      codeLetters ??
                      (duplicateCode ? "Program Code already exists." : null);

                  nameError = nameRequired ??
                      nameLetters ??
                      (duplicateName ? "Program Name already exists." : null);
                });

                if (codeError != null || nameError != null) {
                  return;
                }

                Navigator.pop(dialogContext);

                await _editProgram(
                  program,
                  name,
                  code,
                );
              },
            );
          },
        );
      },
    );
  }

// _editProgram & _editDepartment
  Future<void> _editProgram(
    ProgramModel program,
    String name,
    String code,
  ) async {
    if (program.id == null) {
      await DialogUtils.showError(
        context,
        "Program not found.",
      );
      return;
    }

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        body: {
          'action': 'edit_program',
          'id': program.id.toString(),
          'name': name,
          'code': code,
          'admin_id': _adminId,
        },
      );

      final data = jsonDecode(response.body);

      if (data['status'] == 'success') {
        setState(() {
          program.name = name;
          program.code = code;
        });

        await DialogUtils.showSuccess(
          context,
          'Program "$code" updated successfully.',
        );
      } else {
        await DialogUtils.showError(
          context,
          data['message'] ?? 'Failed to update program.',
        );
      }
    } catch (e) {
      await DialogUtils.showError(
        context,
        'Failed to connect to the server.',
      );
    }
  }

  Future<void> _editDepartment(
    DepartmentModel dept,
    String name,
    String code,
  ) async {
    if (dept.id == null) {
      await DialogUtils.showError(
        context,
        "Department not found.",
      );
      return;
    }

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        body: {
          'action': 'edit_dept',
          'id': dept.id.toString(),
          'name': name,
          'code': code,
          'admin_id': _adminId,
        },
      );

      final data = jsonDecode(response.body);

      if (data['status'] == 'success') {
        setState(() {
          dept.name = name;
          dept.code = code;
        });

        await DialogUtils.showSuccess(
          context,
          'Department "$code" updated successfully.',
        );
      } else {
        await DialogUtils.showError(
          context,
          data['message'] ?? 'Failed to update department.',
        );
      }
    } catch (e) {
      await DialogUtils.showError(
        context,
        'Failed to connect to the server.',
      );
    }
  }

// _deleteDepartment & deleteProgram
  Future<void> _deleteDepartment(DepartmentModel dept) async {
    if (dept.id == null) return;

    final confirmed = await DialogUtils.showDeleteConfirmation(
      context,
      title: "Delete Department",
      message: 'Are you sure you want to delete "${dept.name}"?',
    );

    if (!confirmed) return;

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        body: {
          'action': 'delete_dept',
          'id': dept.id.toString(),
          'admin_id': _adminId,
        },
      );

      final data = jsonDecode(response.body);

      if (data['status'] == 'success') {
        setState(() {
          _departments.removeWhere((d) => d.id == dept.id);

          if (_selectedDepartment?.id == dept.id) {
            _selectedDepartment = null;
            _selectedProgram = null;
          }
        });

        dept.dispose();

        await DialogUtils.showSuccess(
          context,
          'Department "${dept.code}" deleted successfully.',
        );
      }
    } catch (e) {
      await DialogUtils.showError(
        context,
        'Failed to delete department.',
      );
    }
  }

  Future<void> _deleteProgram(ProgramModel program) async {
    if (program.id == null) return;

    final confirmed = await DialogUtils.showDeleteConfirmation(
      context,
      title: "Delete Program",
      message: 'Are you sure you want to delete "${program.name}"?',
    );

    if (!confirmed) return;

    try {
      final response = await http.post(Uri.parse(apiUrl), body: {
        'action': 'delete_program',
        'id': program.id.toString(),
        'admin_id': _adminId,
      });

      final data = jsonDecode(response.body);

      if (data['status'] == 'success') {
        setState(() {
          _selectedDepartment?.programs.removeWhere(
            (p) => p.id == program.id,
          );

          _selectedProgram = null;
        });

        await DialogUtils.showSuccess(
          context,
          'Program "${program.code}" deleted successfully.',
        );
      } else {
        await DialogUtils.showError(
          context,
          data['message'] ?? "Delete failed.",
        );
      }
    } catch (e) {
      await DialogUtils.showError(
        context,
        'Failed to delete program.',
      );
    }
  }

// _showAddProgramDialog & showAddDepartment
  void _showAddProgramDialog(DepartmentModel department) {
    final codeController = TextEditingController();
    final nameController = TextEditingController();

    String? codeError;
    String? nameError;
    DepartmentModel selectedDepartment = department;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AcademicDialog(
              title: "Add Program",
              showDepartmentDropdown: true,
              departmentItems: _departments.map((d) => d.code).toList(),
              selectedDepartment: selectedDepartment.code,
              onDepartmentChanged: (value) {
                setDialogState(() {
                  selectedDepartment = _departments.firstWhere(
                    (d) => d.code == value,
                  );
                });
              },
              codeLabel: "Program Code",
              nameLabel: "Program Name",
              codeController: codeController,
              nameController: nameController,
              codeError: codeError,
              nameError: nameError,
              onSave: () async {
                final code = Validators.normalize(codeController.text);
                final name = Validators.normalize(nameController.text);

                // Clear previous errors
                codeError = null;
                nameError = null;

                // Required validation
                final codeRequired = Validators.required(code, "Program Code");
                final nameRequired = Validators.required(name, "Program Name");

                // Letters only validation
                final codeLetters = codeRequired == null
                    ? Validators.lettersOnly(code, "Program Code")
                    : null;

                final nameLetters = nameRequired == null
                    ? Validators.lettersOnly(name, "Program Name")
                    : null;

                // Duplicate validation
                final duplicateCode = Validators.isDuplicate(
                  code,
                  _departments.expand((d) => d.programs).map((p) => p.code),
                );

                final duplicateName = Validators.isDuplicate(
                  name,
                  _departments.expand((d) => d.programs).map((p) => p.name),
                );

                // Show ALL errors together
                setDialogState(() {
                  codeError = codeRequired ??
                      codeLetters ??
                      (duplicateCode ? "Program Code already exists." : null);

                  nameError = nameRequired ??
                      nameLetters ??
                      (duplicateName ? "Program Name already exists." : null);
                });

                if (codeError != null || nameError != null) {
                  return;
                }

                Navigator.pop(dialogContext);

                await _addProgram(
                  selectedDepartment,
                  name,
                  code,
                );

                await _fetchData();
              },
            );
          },
        );
      },
    );
  }

  void _showAddDepartmentDialog() {
    final codeController = TextEditingController();
    final nameController = TextEditingController();

    String? codeError;
    String? nameError;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AcademicDialog(
              title: "Add Department",
              codeLabel: "Department Code",
              nameLabel: "Department Name",
              codeController: codeController,
              nameController: nameController,
              codeError: codeError,
              nameError: nameError,
              onSave: () async {
                final code = Validators.normalize(codeController.text);
                final name = Validators.normalize(nameController.text);

                // Clear previous errors
                codeError = null;
                nameError = null;

                // Required validation
                final codeRequired =
                    Validators.required(code, "Department Code");
                final nameRequired =
                    Validators.required(name, "Department Name");

                // Letters only validation
                final codeLetters = codeRequired == null
                    ? Validators.lettersOnly(code, "Department Code")
                    : null;

                final nameLetters = nameRequired == null
                    ? Validators.lettersOnly(name, "Department Name")
                    : null;

                // Duplicate validation
                final duplicateCode = Validators.isDuplicate(
                  code,
                  _departments.map((d) => d.code),
                );

                final duplicateName = Validators.isDuplicate(
                  name,
                  _departments.map((d) => d.name),
                );

                // Show ALL errors together
                setDialogState(() {
                  codeError = codeRequired ??
                      codeLetters ??
                      (duplicateCode
                          ? "Department Code already exists."
                          : null);

                  nameError = nameRequired ??
                      nameLetters ??
                      (duplicateName
                          ? "Department Name already exists."
                          : null);
                });

                if (codeError != null || nameError != null) {
                  return;
                }

                _deptCodeCtrl.text = code;
                _deptNameCtrl.text = name;

                Navigator.pop(dialogContext);

                await _addDepartment();
              },
            );
          },
        );
      },
    );
  }

// _addProgram &
  Future<void> _addProgram(
    DepartmentModel dept,
    String name,
    String code,
  ) async {
    if (name.isEmpty || code.isEmpty || dept.id == null) return;

    try {
      final response = await http.post(Uri.parse(apiUrl), body: {
        'action': 'add_program',
        'department_id': dept.id.toString(),
        'name': name,
        'code': code,
        'admin_id': _adminId,
      });

      final data = jsonDecode(response.body);

      if (data['status'] == 'success') {
        setState(() {
          dept.programs.add(
            ProgramModel(
              id: data['id'],
              name: name,
              code: code,
            ),
          );
        });

        await DialogUtils.showSuccess(
          context,
          'Program "$code" added successfully.',
        );
      } else {
        await DialogUtils.showError(
          context,
          data['message'] ?? 'Failed to add program.',
        );
      }
    } catch (e) {
      await DialogUtils.showError(
        context,
        'Failed to connect to the server.',
      );
    }
  }

// Uncommented
  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 2)),
    );
  }

  @override
  void dispose() {
    _deptNameCtrl.dispose();
    _deptCodeCtrl.dispose();
    _searchCtrl.dispose();
    for (final d in _departments) {
      d.dispose();
    }
    super.dispose();
  }

  // ─── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE5E5E5),
      body: Row(
        children: [
          const SideBar(selectedIndex: 3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // HEADER
                Container(
                  width: double.infinity,
                  color: const Color(0xFFD6D6D6),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 40, vertical: 25),
                  child: const Text(
                    'Academic Setup',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                ),

                // BODY
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : SingleChildScrollView(
                          padding: const EdgeInsets.all(24),
                          child: _AcademicManager(
                            departments: _departments,
                            selectedDepartment: _selectedDepartment,
                            selectedProgram: _selectedProgram,
                            onDepartmentSelected: (department) {
                              setState(() {
                                _selectedDepartment = department;
                                _selectedProgram = null;
                              });
                            },
                            onProgramSelected: (program) {
                              setState(() {
                                _selectedProgram = program;
                              });
                            },
                            onEditDepartment: _showEditDepartmentDialog,
                            onEditProgram: _showEditProgramDialog,
                            onDeleteDepartment: _deleteDepartment,
                            onDeleteProgram: (program) {
                              if (_selectedDepartment != null) {
                                _deleteProgram(program);
                              }
                            },
                            onAddDepartment: _showAddDepartmentDialog,
                            onAddProgram: _showAddProgramDialog,
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
}

// Two Panels

class _AcademicManager extends StatelessWidget {
  final List<DepartmentModel> departments;
  final DepartmentModel? selectedDepartment;
  final ValueChanged<DepartmentModel> onDepartmentSelected;
  final ValueChanged<DepartmentModel> onEditDepartment;
  final void Function(
    DepartmentModel,
    ProgramModel,
  ) onEditProgram;
  final ValueChanged<DepartmentModel> onDeleteDepartment;
  final ValueChanged<ProgramModel> onDeleteProgram;
  final VoidCallback onAddDepartment;
  final ValueChanged<DepartmentModel> onAddProgram;

  final ProgramModel? selectedProgram;
  final ValueChanged<ProgramModel> onProgramSelected;

  const _AcademicManager({
    required this.departments,
    required this.selectedDepartment,
    required this.onDepartmentSelected,
    required this.selectedProgram,
    required this.onEditDepartment,
    required this.onEditProgram,
    required this.onDeleteDepartment,
    required this.onDeleteProgram,
    required this.onAddDepartment,
    required this.onAddProgram,
    required this.onProgramSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 650,
      child: Row(
        children: [
          // =======================
          // Departments Panel
          // =======================
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Departments",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: onAddDepartment,
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text("Add"),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    const Divider(),

                    const SizedBox(height: 16),

                    Expanded(
                      child: ListView.builder(
                        itemCount: departments.length,
                        itemBuilder: (context, index) {
                          final department = departments[index];

                          final isSelected =
                              selectedDepartment?.id == department.id;

                          return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFFE3F2FD)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFF1976D2)
                                      : Colors.grey.shade300,
                                ),
                              ),
                              child: ListTile(
                                onTap: () {
                                  onDepartmentSelected(department);
                                },
                                title: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        department.name,
                                        style: TextStyle(
                                          fontWeight: isSelected
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                        ),
                                      ),
                                    ),
                                    if (isSelected)
                                      IconButton(
                                        icon: const Icon(
                                          Icons.edit_outlined,
                                          color: Colors.blue,
                                        ),
                                        tooltip: "Edit Department",
                                        onPressed: () {
                                          onEditDepartment(department);
                                        },
                                      ),
                                  ],
                                ),
                                subtitle: Text(department.code),
                              ));
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(width: 20),

          // =======================
          // Programs Panel
          // =======================
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Programs",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: selectedDepartment == null
                              ? null
                              : () {
                                  onAddProgram(selectedDepartment!);
                                },
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text("Add"),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    const Divider(),

                    const SizedBox(height: 16),

                    Expanded(
                      child: selectedDepartment == null
                          ? const Center(
                              child: Text("Select a department"),
                            )
                          : ListView.builder(
                              itemCount: selectedDepartment!.programs.length,
                              itemBuilder: (context, index) {
                                final program =
                                    selectedDepartment!.programs[index];

                                final isSelected =
                                    selectedProgram?.id == program.id;

                                return Card(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  child: ListTile(
                                    onTap: () {
                                      onProgramSelected(program);
                                    },
                                    title: Text(program.name),
                                    subtitle: Text(program.code),
                                    trailing: isSelected
                                        ? IconButton(
                                            icon: const Icon(Icons.edit,
                                                color: Colors.blue),
                                            onPressed: () => onEditProgram(
                                                selectedDepartment!, program),
                                          )
                                        : null,
                                  ),
                                );
                              },
                            ),
                    )
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/*
// ─── How It Works Card ────────────────────────────────────────────────────────

class _HowItWorksCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('How this works',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937))),
          const SizedBox(height: 4),
          Text('A simpler way to organize academic data.',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
          const SizedBox(height: 12),
          _HowStep(
              num: '1',
              label: 'Create a department',
              color: const Color(0xFF1565C0)),
          const SizedBox(height: 8),
          _HowStep(
              num: '2',
              label: 'Add program inside the department',
              color: const Color(0xFF1565C0)),
          const SizedBox(height: 8),
          _HowStep(
              num: '3',
              label: 'Edit or remove anytime',
              color: const Color(0xFF1565C0)),
        ],
      ),
    );
  }
}

class _HowStep extends StatelessWidget {
  final String num;
  final String label;
  final Color color;

  const _HowStep({required this.num, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
            radius: 10,
            backgroundColor: color.withOpacity(0.15),
            child: Text(num,
                style: TextStyle(
                    fontSize: 11, fontWeight: FontWeight.bold, color: color))),
        const SizedBox(width: 8),
        Expanded(
          child: Text(label,
              style: const TextStyle(fontSize: 12, color: Color(0xFF374151))),
        ),
      ],
    );
  }
}


// ─── Create Department Card ───────────────────────────────────────────────────

class _CreateDepartmentCard extends StatelessWidget {
  final TextEditingController nameCtrl;
  final TextEditingController codeCtrl;
  final VoidCallback onSave;

  const _CreateDepartmentCard({
    required this.nameCtrl,
    required this.codeCtrl,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Create Department',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937))),
          const SizedBox(height: 12),
          _FormLabel('Department Name'),
          const SizedBox(height: 4),
          _FormField(ctrl: nameCtrl, hint: 'e.g. College of Nursing'),
          const SizedBox(height: 10),
          _FormLabel('Department Code'),
          const SizedBox(height: 4),
          _FormField(ctrl: codeCtrl, hint: 'e.g. CON'),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onSave,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Save Department'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1565C0),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ),
    );
  }
} */

/*
class _InfoStep extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoStep({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: const Color(0xFF1565C0)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text,
              style: const TextStyle(fontSize: 12, color: Color(0xFF374151))),
        ),
      ],
    );
  }
} 

// ─── Reusable Small Widgets ───────────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  final Color textColor;

  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration:
          BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
      child: Column(
        children: [
          Text(label,
              style:
                  TextStyle(fontSize: 12, color: textColor.withOpacity(0.8))),
          const SizedBox(height: 2),
          Text('$value',
              style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.bold, color: textColor)),
        ],
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;
  final VoidCallback onTap;

  const _IconBtn({
    required this.icon,
    required this.color,
    required this.onTap,
    this.size = 20,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(icon, size: size, color: color),
      ),
    );
  }
}


class _SmallField extends StatelessWidget {
  final TextEditingController ctrl;
  final String hint;

  const _SmallField({required this.ctrl, required this.hint});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: ctrl,
      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 12),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
      ),
    );
  }
}


class _FormLabel extends StatelessWidget {
  final String text;
  const _FormLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151)));
  }
}

class _FormField extends StatelessWidget {
  final TextEditingController ctrl;
  final String hint;

  const _FormField({required this.ctrl, required this.hint});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: ctrl,
      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade400),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
      ),
    );
  }
} */
