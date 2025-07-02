import 'package:esp_terminal/util/util.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Enum to define the types of input widgets that can be used within an [EditForm].
///
/// This allows the [EditForm] to be flexible and handle different kinds of user input.
enum FormItemType {
  /// A standard text input field for entering string values.
  text,

  /// A number input field for entering floating-point values.
  number,

  /// An ID input field for entering integer values, specifically designed for IDs.
  id,

  /// A container that arranges other form items horizontally in a row.
  row,

  /// Allows embedding any custom Flutter widget within the form.
  custom,
}

/// Data class to configure a single input widget or group within an [EditForm].
///
/// Each instance of this class defines the type, label, validation rules,
/// optional extra data, and the initial value for a form element.
class FormItemData {
  /// The type of the form item widget, as defined by the [FormItemType] enum.
  final FormItemType type;

  /// The name or label displayed for this form item.
  /// This is also used as the key in the output map when the form is submitted.
  final String name;

  /// An optional validation function for this form item.
  ///
  /// The function takes the current value of the form item as input and should
  /// return a string containing an error message if the value is invalid,
  /// or an empty string if the value is valid.
  final String Function(dynamic)? validate;

  /// Optional extra data associated with this form item.
  ///
  /// The interpretation of this data depends on the [type]. For example:
  /// - For [FormItemType.custom], this should be the custom [Widget] to display.
  /// - For [FormItemType.text], this can be a string like "disabled" to disable the input.
  /// - For [FormItemType.row], this should be a `List<FormItemData>` for the items in the row.
  final dynamic extra;

  /// The data associated with the widget (input value).
  ///
  /// This field holds the initial value when the form is created and is updated
  /// with the user's input when the form is submitted. The type of data
  /// should match the [type] of the form item (e.g., `String` for text, `double`
  /// for number, `int` for id, `List<FormItemData>` for row).
  dynamic data;

  /// Constructs a [FormItemData].
  ///
  /// [type] and [name] are required. [extra], [validate], and [data] are optional.
  FormItemData(this.type, this.name, {this.extra, this.validate, this.data});
}

/// A generic and reusable dialog widget for editing data.
///
/// This widget presents an [AlertDialog] containing a list of input fields
/// defined by a list of [FormItemData]. It provides a title, optional suffix
/// widget in the title bar, and action buttons for submitting or canceling
/// the form. It handles basic validation and collects the input data into a map.
class EditForm extends StatelessWidget {
  /// The title displayed at the top of the dialog.
  final String title;

  /// Optional widget displayed as a suffix at the end of the title bar.
  /// Useful for adding icons or buttons next to the title (e.g., a delete button).
  final Widget? titleSuffix;

  /// The text displayed on the submit button. Defaults to "Ok".
  /// If `null`, the submit button is not shown.
  final String? submitLabel;

  /// The text displayed on the cancel button. Defaults to "Cancel".
  /// If `null`, the cancel button is not shown.
  final String? cancelLabel;

  /// Optional callback function executed when the submit button is pressed and
  /// validation passes.
  ///
  /// The function receives a `Map<String, dynamic>` containing the collected
  /// data from all form items, where keys are the `name` of each [FormItemData].
  final Function(Map<String, dynamic>)? onSubmit;

  /// The list of [FormItemData] objects that define the input fields and
  /// structure of the form.
  final List<FormItemData> items;

  /// Constructs an [EditForm].
  ///
  /// [items] is a required list of [FormItemData] defining the form content.
  /// Other parameters are optional for customization.
  const EditForm({
    super.key,
    this.title = "Edit",
    this.titleSuffix,
    this.submitLabel = "Ok",
    this.cancelLabel = "Cancel",
    this.onSubmit,
    required this.items,
  });

  @override
  /// Builds the main [AlertDialog] widget for the form.
  ///
  /// Sets up the title, makes the content scrollable, builds the form items
  /// using `_buildItem`, and configures the action buttons with validation
  /// and submission logic.
  ///
  /// [context]: The build context.
  /// Returns an [AlertDialog] widget.
  Widget build(BuildContext context) {
    return AlertDialog(
      title:
          // Display the title, optionally with a suffix widget in a Row.
          titleSuffix != null
          ? Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [Text(title), titleSuffix!],
            )
          : Text(title),
      scrollable: true, // Make the dialog content scrollable if it overflows.
      content: Column(
        // Arrange form items vertically.
        spacing: 8, // Vertical spacing between form items.
        crossAxisAlignment:
            CrossAxisAlignment.start, // Align items to the start (left).
        children: List.generate(
          items.length,
          (i) => _buildItem(items[i]),
        ), // Build each form item widget.
      ),
      actions: [
        // Display the cancel button if cancelLabel is provided.
        if (cancelLabel != null)
          TextButton(
            onPressed: () async {
              await closeSnackbar(); // Close any active snackbars before closing the dialog.
              Get.back(); // Close the dialog.
            },
            child: Text(cancelLabel!), // Button text.
          ),

        // Display the submit button if submitLabel is provided.
        if (submitLabel != null)
          TextButton(
            onPressed: () async {
              await closeSnackbar(); // Close any active snackbars before validation.

              final msg = _validate(items); // Validate the input data.

              if (msg.isEmpty) {
                // If validation passes:
                final data = _map(
                  items,
                ); // Collect the data from the form items.
                onSubmit?.call(
                  data,
                ); // Call the optional onSubmit callback with the data.
                Get.back(
                  result: data,
                ); // Close the dialog and return the collected data.
              } else {
                // If validation fails:
                await closeSnackbar(); // Close any existing snackbars.
                showSnackbar(
                  "Error",
                  msg,
                ); // Show a snackbar with validation error messages.
              }
            },
            child: Text(submitLabel!), // Button text.
          ),
      ],
    );
  }

  /// Builds the appropriate widget for a single [FormItemData].
  ///
  /// This method acts as a factory, returning a different widget based on the
  /// [item.type]. It handles text, number, and ID inputs by calling `_buildTextField`,
  /// custom widgets by returning `item.extra`, and rows by building a nested Column/Row
  /// structure and recursively calling `_buildItem` for the row's children.
  ///
  /// [item]: The [FormItemData] to build the widget for.
  /// Returns the corresponding [Widget] for the form item.
  Widget _buildItem(FormItemData item) {
    // Build a text input widget for text, number, or id types.
    if (item.type == FormItemType.text ||
        item.type == FormItemType.number ||
        item.type == FormItemType.id) {
      return _buildTextField(item);
    }

    // Return a custom widget if the type is custom.
    if (item.type == FormItemType.custom) {
      // We expect item.extra to be a valid widget provided by the user.
      return item.extra;
    }

    // Build a row of widgets if the type is row.
    if (item.type == FormItemType.row) {
      // Get the list of widget items in the row from item.data (which should be List<FormItemData>).
      final List<FormItemData> row = item.data;
      return Column(
        // Use a Column to stack the row's label and the row of widgets.
        mainAxisSize: MainAxisSize.min, // Take minimum vertical space.
        crossAxisAlignment:
            CrossAxisAlignment.start, // Align children to the start (left).
        spacing: 4, // Vertical spacing between the label and the row.
        children: [
          if (item.name.isNotEmpty)
            Text(item.name), // Display the row label if provided and not empty.

          Row(
            // Arrange the widgets horizontally in a row.
            mainAxisAlignment:
                MainAxisAlignment.center, // Center the widgets in the row.
            spacing: 8, // Horizontal spacing between widgets in the row.
            children: List<Widget>.generate(
              row.length, // Number of widgets in the row.
              (i) => Expanded(
                child: _buildItem(row[i]),
              ), // Build each item in the row and wrap in Expanded.
            ),
          ),
        ],
      );
    }

    // Throw an error for unsupported form item types.
    throw ArgumentError("Invalid form type: ${item.type}");
  }

  /// Builds a [TextField] widget based on the configuration in [FormItemData].
  ///
  /// This method handles the specific setup for text, number, and ID input
  /// fields, including setting the initial value, keyboard type, and updating
  /// the `item.data` when the text changes, with appropriate parsing for
  /// number and ID types. It also handles disabling the field based on `item.extra`.
  ///
  /// [item]: The [FormItemData] for the text field.
  /// Returns a configured [TextField] widget.
  Widget _buildTextField(FormItemData item) {
    // Validate that the item type is one of the supported text field types.
    if (!(item.type == FormItemType.id ||
        item.type == FormItemType.number ||
        item.type == FormItemType.text)) {
      throw ArgumentError("Invalid form type for text field: ${item.type}");
    }

    final TextEditingController controller =
        TextEditingController(); // Controller to manage the text field's content.
    var keyboardType = TextInputType.text; // Default keyboard type is text.

    // Configure the text field based on the widget type.
    if (item.type == FormItemType.id) {
      // Handle ID type (integer input).
      if (item.data is! int) {
        item.data = 0; // Default to 0 if initial data is not an integer.
      }

      // Set initial text from the integer data.
      controller.text = (item.data as int).toString();
      // Configure keyboard for non-decimal, non-signed numbers.
      keyboardType = const TextInputType.numberWithOptions(
        decimal: false,
        signed: false,
      );
    } else if (item.type == FormItemType.number) {
      // Handle number type (double input).
      if (item.data is! double) {
        item.data = 0.0; // Default to 0.0 if initial data is not a double.
      }
      // Set initial text from the double data, formatted to 3 decimal places.
      controller.text = (item.data as double).toStringAsFixed(3);
      // Configure keyboard for decimal and signed numbers.
      keyboardType = const TextInputType.numberWithOptions(
        decimal: true,
        signed: true,
      );
    } else if (item.type == FormItemType.text) {
      // Handle text type (string input).
      if (item.data is! String) {
        item.data =
            ""; // Default to empty string if initial data is not a string.
      }
      controller.text =
          item.data as String; // Set initial text from the string data.
    }

    // Build the TextField widget.
    return TextField(
      controller: controller,
      // Link the controller to the text field.
      // Enable or disable the text field based on the 'extra' data.
      enabled: !(item.extra is String && item.extra.contains("disabled")),
      decoration: InputDecoration(
        // Input field decoration.
        labelText: item.name, // Label text displayed above the input.
        border: const OutlineInputBorder(), // Border style for the input field.
      ),
      keyboardType: keyboardType,
      // Set the configured keyboard type.
      maxLines: 1,
      // Limit the input to a single line.
      onChanged: (value) {
        // Update the data when the text changes.
        // Parse the value to the correct type based on the item type.
        if (item.type == FormItemType.number) {
          item.data = double.tryParse(value); // Attempt to parse as a double.
        } else if (item.type == FormItemType.id) {
          if (value.toLowerCase().startsWith("0x")) {
            // Support for hexadecimal integer strings (e.g., "0x123").
            item.data = int.tryParse(value.substring(2), radix: 16);
          } else {
            item.data = int.tryParse(
              value,
            ); // Attempt to parse as a decimal integer.
          }
        } else {
          item.data =
              value; // For text type, the data is the string value directly.
        }
      },
    );
  }

  /// Recursively maps the data from a list of [FormItemData] into a JSON-like map.
  ///
  /// This static helper method iterates through the provided list of form items
  /// and creates a map where keys are the `name` of each item and values are
  /// the collected `data`. For items of type [FormItemType.row], it recursively
  /// calls itself to map the data of the nested items.
  ///
  /// [items]: The list of [FormItemData] to map data from.
  /// Returns a [Map<String, dynamic>] containing the data from the form items.
  static Map<String, dynamic> _map(List<FormItemData> items) {
    final entries =
        <
          MapEntry<String, dynamic>
        >[]; // List to hold map entries before creating the map.

    // Iterate through the form items and create map entries.
    for (final w in items) {
      entries.add(
        MapEntry(
          w.name, // Use the item's name as the key in the map.
          w.type == FormItemType.row
              ? _map(w.data)
              : w.data, // If it's a row, recursively map its children; otherwise, use the item's data.
        ),
      );
    }

    return Map.fromEntries(entries); // Return the map created from the entries.
  }

  /// Recursively validates the data in a list of [FormItemData].
  ///
  /// This static helper method iterates through the provided list of form items
  /// and performs validation. It first checks if a custom `validate` function
  /// is provided for an item and uses it if available. Otherwise, it performs
  /// default validation based on the item's [FormItemType]. For items of type
  /// [FormItemType.row], it recursively calls itself to validate the nested items.
  ///
  /// [items]: The list of [FormItemData] to validate.
  /// Returns a string containing all accumulated validation error messages,
  /// with each message on a new line. Returns an empty string if validation passes for all items.
  static String _validate(List<FormItemData> items) {
    String msg = ""; // String to accumulate validation error messages.

    // Iterate through the form items and perform validation.
    for (final wd in items) {
      // If a custom validate function is provided for this item, use it.
      if (wd.validate != null) {
        msg += wd.validate!(
          wd.data,
        ); // Append the result of the custom validation.
        continue; // Move to the next item after custom validation.
      }

      // Perform default validation based on the widget type.
      if (wd.type == FormItemType.text) {
        // Validate text type: data cannot be null, must be a string, and cannot be empty.
        if (wd.data == null ||
            wd.data is! String ||
            (wd.data as String).isEmpty) {
          msg +=
              "${wd.name} cannot be empty.\n"; // Add error message for empty text.
        }
      } else if (wd.type == FormItemType.number) {
        // Validate number type: data cannot be null and must be a double.
        if (wd.data == null || wd.data is! double) {
          msg +=
              "Invalid ${wd.name} value: '${wd.data}'\n"; // Add error message for invalid number.
        }
      } else if (wd.type == FormItemType.id) {
        // Validate ID type: data cannot be null, must be an integer, and cannot be -1.
        if (wd.data == null || wd.data is! int || wd.data == -1) {
          msg +=
              "Invalid ${wd.name} value: '${wd.data}'.\n"; // Add error message for invalid ID.
        }
      } else if (wd.type == FormItemType.row) {
        // Recursively validate widgets within a row.
        // Note: The result of the recursive call is appended to the current message.
        msg += _validate(wd.data);
      }
    }

    // Return the accumulated error messages, trimmed of leading/trailing whitespace.
    return msg.trim();
  }
}
