import 'package:flutter/widgets.dart';
import './sidebar.dart';
import 'package:flutter/material.dart';

//Sample destination class sang import
class ImportPlaceHolderClass extends StatelessWidget {
  const ImportPlaceHolderClass({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          const SideBar(selectedIndex: 3),
          Expanded(
            child: Center(
              child: Text("Import Page"),
            ),
          ),
        ],
      ),
    );
  }
}