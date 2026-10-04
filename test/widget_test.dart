import 'package:flutter_test/flutter_test.dart';
import 'package:app_lavadoras_movil/main.dart';

void main() {
  testWidgets('Carga inicial de la app', (WidgetTester tester) async {
    await tester.pumpWidget(const TiendaLavadorasApp());
    expect(find.byType(TiendaLavadorasApp), findsOneWidget);
  });
}