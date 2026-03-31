import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:flutter_todo/providers/task_provider.dart';
import 'package:flutter_todo/app.dart';

void main() {
  testWidgets('App renders home screen', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => TaskProvider()..init(),
        child: const TodoApp(),
      ),
    );

    // Verify the app renders the My Tasks title
    expect(find.text('My Tasks'), findsOneWidget);
  });
}
