import 'dart:async';

import 'package:esp_terminal/services/data_service.dart';
import 'package:esp_terminal/services/storage_service.dart';
import 'package:esp_terminal/ui/panels/base_panel.dart';
import 'package:esp_terminal/ui/widgets/edit_form.dart';
import 'package:esp_terminal/util/constants.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class Variable {
  final RxInt id;
  final RxString name;
  final RxDouble value;

  Variable({required int id, required String name, double value = 0.0})
    : id = id.obs,
      name = name.obs,
      value = value.obs;
}

class VariablesPanel extends BasePanel<List<(int, String)>> {
  /// Flag whether we can add new variables
  final bool editable;

  /// Store state of all variables in this panel.
  final vars = <Variable>[].obs;

  VariablesPanel({
    super.key,
    required super.id,
    super.title = "Variables",
    super.constraintHeight = true,
    super.showTitle = false,
    this.editable = true,
  });

  @override
  Future<List<(int, String)>> loadState() async {
    final ss = StorageService.to;
    final int numExtraVars = id.contains("home") ? 0 : 8;

    // Update vars when we receive packets
    vars.bindStream(
      DataService.to.currentPacket.stream
          .map((p) {
            if (p.cmd == FLOAT_RECV) {
              for (final v in vars.where((v) => v.id.value == p.id)) {
                v.value.value = p.value;
              }
            }
            return vars;
          })
          .skipWhile((_) => true),
    );

    // Save variables to disk whenever it is changed
    debounce(vars, (vars) {
      ss.set(
        "variables_$id",
        vars.map((v) => "${v.id.value};${v.name.value}").toList(),
      );
    });

    // Load variables from disk, load default if not found in disk
    final varList = await ss.get("variables_$id", <String>[
      "${0x3};V motor",
      "${0x4};V ref",
      "${0x7};Mode",
      "${0x5};I motor",
      "${0x6};I_m limit",
      "${0x8};Fault",

      ...List.generate(numExtraVars, (i) => "$i;Var ${7 + i}"),
    ]);

    return varList.map((v) {
      final i = v.indexOf(";");
      return (int.parse(v.substring(0, i)), v.substring(i + 1));
    }).toList();
  }

  @override
  Widget? buildPanel(BuildContext context, List<(int, String)>? state) {
    if (state != null && state.isNotEmpty) {
      vars.clear();
      vars.addAll(state.map((e) => Variable(id: e.$1, name: e.$2)));
    }

    return Obx(
      () => GridView.builder(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 1.4,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: vars.length + (editable ? 1 : 0),
        itemBuilder: (ctx, index) => ElevatedButton(
          onPressed: () => _showAddOrEditItemDialog(index),
          style: ElevatedButton.styleFrom(
            // Button styling.
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: editable && index == vars.length
              ? const Icon(Icons.add)
              : _buildVariableGridItem(vars[index]),
        ),
      ),
    );
  }

  Widget _buildVariableGridItem(Variable v) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      spacing: 8,
      children: [
        Obx(
          () => Text(
            v.name.value,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            textAlign: TextAlign.center,
            overflow: TextOverflow.fade,
            maxLines: 1,
          ),
        ),

        Obx(
          () => Text(
            v.value.value.toStringAsFixed(3),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
            overflow: TextOverflow.fade,
            maxLines: 1,
          ),
        ),
      ],
    );
  }

  /// Shows the dialog for adding or editing a variable.
  ///
  /// [updateFn] is called with the updated variable or null if deleted.
  void _showAddOrEditItemDialog(int index) {
    final variable = index < vars.length ? vars[index] : null;

    Get.dialog(
      EditForm(
        title: variable == null ? "Add" : "Edit",
        submitLabel: variable == null ? "Add" : "Save",
        titleSuffix: variable == null || !editable
            ? null
            : IconButton(
                onPressed: () {
                  vars.removeAt(index);
                  Get.back();
                },
                icon: const Icon(Icons.delete),
              ),
        onSubmit: (data) {
          final int id = data["ID"];
          final String name = data["Name"];

          if (variable != null) {
            variable.id.value = id;
            variable.name.value = name;
            vars.refresh();
          } else {
            vars.add(Variable(id: id, name: name));
          }
        },
        items: [
          FormItemData(FormItemType.id, "ID", data: variable?.id.value ?? 0),
          FormItemData(
            FormItemType.text,
            "Name",
            data: variable?.name.value ?? "Var ${vars.length + 1}",
          ),
        ],
      ),
    );
  }
}
