import 'package:flutter/material.dart';

class AcademicDialog extends StatelessWidget {
  final String title;
  final String codeLabel;
  final String nameLabel;
  final String? departmentLabel;
  final String? departmentValue;

  final bool showDepartmentDropdown;
  final List<String>? departmentItems;
  final String? selectedDepartment;
  final ValueChanged<String?>? onDepartmentChanged;

  final TextEditingController codeController;
  final TextEditingController nameController;

  final String? codeError;
  final String? nameError;

  final VoidCallback onSave;
  final VoidCallback? onDelete;

  final bool showDelete;

  final bool deleteEnabled;

  const AcademicDialog({
    super.key,
    required this.title,
    required this.codeLabel,
    required this.nameLabel,
    required this.codeController,
    required this.nameController,
    required this.onSave,
    this.onDelete,
    this.showDelete = false,
    this.departmentLabel,
    this.departmentValue,
    this.showDepartmentDropdown = false,
    this.departmentItems,
    this.selectedDepartment,
    this.onDepartmentChanged,
    this.codeError,
    this.nameError,
    this.deleteEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Container(
        width: 430,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            if (showDepartmentDropdown) ...[
              const Text(
                "Department",
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                isExpanded: true,
                value: selectedDepartment,
                items: departmentItems!
                    .map(
                      (dept) => DropdownMenuItem(
                        value: dept,
                        child: Text(dept),
                      ),
                    )
                    .toList(),
                onChanged: onDepartmentChanged,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
              ),
              const Divider(height: 28),
            ] else if (departmentLabel != null && departmentValue != null) ...[
              Text(
                departmentLabel!,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.grey,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                departmentValue!,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Divider(height: 28),
            ],
            Text(
              codeLabel,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: codeController,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                errorText: codeError,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              nameLabel,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                errorText: nameError,
              ),
            ),
            const SizedBox(height: 24),
            if (showDelete)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: deleteEnabled ? onDelete : null,
                  icon: Icon(
                    Icons.delete_outline,
                    color: deleteEnabled ? Colors.red : Colors.grey,
                  ),
                  label: Text(
                    "Delete",
                    style: TextStyle(
                      color: deleteEnabled ? Colors.red : Colors.grey,
                    ),
                  ),
                ),
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text("Cancel"),
                ),
                const SizedBox(width: 10),
                ElevatedButton(onPressed: onSave, child: const Text("Save")),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
