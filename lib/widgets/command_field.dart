import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_command/flutter_command.dart';

class TextCommandField extends StatefulWidget {
  /// The [ValueListenable] whose value you depend on in order to build.
  ///
  /// This widget does not ensure that the [ValueListenable]'s value is not
  /// null, therefore your [builder] may need to handle null values.
  ///
  /// This [ValueListenable] itself must not be null.
  final Command<String, int> command;

  /// A function which builds a widget depending on the
  /// [command]'s value.
  ///
  /// Must not be null.
  final Widget Function(int, TextEditingController, FocusNode) builder;

  const TextCommandField({super.key, required this.command, required this.builder});

  @override
  State<TextCommandField> createState() => TextCommandFieldState();
}

class TextCommandFieldState extends State<TextCommandField> {
  final TextEditingController controller = TextEditingController();
  final FocusNode focus = FocusNode();

  late int value;

  @override
  void initState() {
    super.initState();

    value = widget.command.value;
    widget.command.addListener(_valueChanged);

    focus.addListener(() {
      widget.command.execute(controller.text);
    });
  }

  @override
  void didUpdateWidget(TextCommandField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.command != widget.command) {
      oldWidget.command.removeListener(_valueChanged);
      value = widget.command.value;
      widget.command.addListener(_valueChanged);
    }
  }

  @override
  void dispose() {
    widget.command.removeListener(_valueChanged);
    super.dispose();
  }

  void _valueChanged() {
    setState(() {
      value = widget.command.value;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!focus.hasFocus) {
      controller.text = value.toString();
    }

    return widget.builder(value, controller, focus);
  }
}
