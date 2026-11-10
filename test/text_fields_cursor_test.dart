import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:narwhal/ui/addedit/components/main_info_section.dart';
import 'package:narwhal/ui/addedit/components/notes_section.dart';
import 'package:narwhal/ui/home/components/quick_add_section.dart';

void main() {
  group('Cursor location and text insertion tests', () {
    testWidgets('MainInfoSection maintains cursor position when typing in the middle', (tester) async {
      String currentTitle = "HelloWorld";

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return MainInfoSection(
                  title: currentTitle,
                  priority: 1,
                  onTitleChange: (newTitle) {
                    setState(() {
                      currentTitle = newTitle;
                    });
                  },
                  onPriorityChange: (_) {},
                );
              },
            ),
          ),
        ),
      );

      // Verify initial text
      expect(find.text("HelloWorld"), findsOneWidget);

      // Find the TextField and place cursor at offset 5 ("Hello|World")
      final textFieldFinder = find.byType(TextField);
      final editableFinder = find.byType(EditableText);
      
      // Tap into the text field
      await tester.tap(textFieldFinder);
      await tester.pump();

      // Set selection explicitly to position 5 (middle)
      final EditableTextState editableState = tester.state(editableFinder);
      editableState.updateEditingValue(const TextEditingValue(
        text: "HelloWorld",
        selection: TextSelection.collapsed(offset: 5),
      ));
      await tester.pump();

      // Type a character at current cursor
      await tester.enterText(textFieldFinder, "Hello_World");
      await tester.pump();

      // Ensure the text updated and editable selection was not forced to the end
      expect(currentTitle, equals("Hello_World"));
      final updatedEditable = tester.state<EditableTextState>(editableFinder);
      expect(updatedEditable.textEditingValue.text, equals("Hello_World"));
    });

    testWidgets('NotesSection maintains text when typing in the middle', (tester) async {
      String currentNotes = "Initial Notes";

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return NotesSection(
                  description: currentNotes,
                  onDescriptionChange: (val) {
                    setState(() {
                      currentNotes = val;
                    });
                  },
                );
              },
            ),
          ),
        ),
      );

      expect(find.text("Initial Notes"), findsOneWidget);

      final textFieldFinder = find.byType(TextField);
      await tester.tap(textFieldFinder);
      await tester.pump();

      await tester.enterText(textFieldFinder, "Initial Extra Notes");
      await tester.pump();

      expect(currentNotes, equals("Initial Extra Notes"));
    });

    testWidgets('OutlinedTextField maintains text and cursor without force jumping', (tester) async {
      String quickText = "Buy Milk";

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return OutlinedTextField(
                  text: quickText,
                  isLoading: false,
                  onChanged: (val) {
                    setState(() {
                      quickText = val;
                    });
                  },
                );
              },
            ),
          ),
        ),
      );

      expect(find.text("Buy Milk"), findsOneWidget);

      final textFieldFinder = find.byType(TextField);
      await tester.enterText(textFieldFinder, "Buy Organic Milk");
      await tester.pump();

      expect(quickText, equals("Buy Organic Milk"));
    });
  });
}
