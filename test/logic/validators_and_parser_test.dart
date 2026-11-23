import 'package:flutter_test/flutter_test.dart';
import 'package:food_planner/core/validators.dart';
import 'package:food_planner/features/meal_details/instruction_parser.dart';

void main() {
  group('Validators', () {
    test('email: valid, empty, no @, no domain', () {
      expect(Validators.email('a@b.co'), isNull);
      expect(Validators.email('  a@b.co  '), isNull);
      expect(Validators.email(''), isNotNull);
      expect(Validators.email(null), isNotNull);
      expect(Validators.email('abc.com'), isNotNull);
      expect(Validators.email('a@b'), isNotNull);
    });

    test('password: valid, empty, short', () {
      expect(Validators.password('12345678'), isNull);
      expect(Validators.password(''), isNotNull);
      expect(Validators.password('1234567'), isNotNull);
    });

    test('name and confirm', () {
      expect(Validators.name('Amr'), isNull);
      expect(Validators.name('  '), isNotNull);
      final confirm = Validators.confirm(() => 'secret123');
      expect(confirm('secret123'), isNull);
      expect(confirm('other'), isNotNull);
      expect(confirm(''), isNotNull);
    });
  });

  group('InstructionParser', () {
    test('null, empty and whitespace give no steps', () {
      expect(InstructionParser.parse(null), isEmpty);
      expect(InstructionParser.parse(''), isEmpty);
      expect(InstructionParser.parse('  \n \r\n '), isEmpty);
    });

    test('splits on line breaks (\\n and \\r\\n)', () {
      final steps = InstructionParser.parse(
        'Preheat the oven to 180C and grease the tin.\r\n\r\nMix the flour and the sugar together well.\r\nBake for thirty minutes until golden.',
      );
      expect(steps.length, 3);
    });

    test('removes "STEP 1" header lines', () {
      final steps = InstructionParser.parse(
        'STEP 1\nChop the onions into thin slices.\nSTEP 2\nFry them in butter until soft.',
      );
      expect(steps, [
        'Chop the onions into thin slices.',
        'Fry them in butter until soft.',
      ]);
    });

    test('removes leading numbers (1. / 2) / Step 3:)', () {
      final steps = InstructionParser.parse(
        '1. Boil the water in a large pot.\n2) Add the pasta and cook it.\nStep 3: Drain and serve while hot.',
      );
      expect(steps, [
        'Boil the water in a large pot.',
        'Add the pasta and cook it.',
        'Drain and serve while hot.',
      ]);
    });

    test('drops lines that are just a number', () {
      final steps = InstructionParser.parse(
        '1\nWash the rice until the water runs clear.\n2\nCook it for fifteen minutes.',
      );
      expect(steps.length, 2);
      expect(steps.first, startsWith('Wash'));
    });

    test('merges tiny fragments into the previous step', () {
      final steps = InstructionParser.parse(
        'Mix the dough and let it rest for an hour\nuntil doubled\nThen shape the loaves and bake them.',
      );
      expect(
        steps.first,
        'Mix the dough and let it rest for an hour until doubled',
      );
      expect(steps.length, 2);
    });

    test('keeps short complete sentences as their own steps', () {
      final steps = InstructionParser.parse(
        'Serve hot.\nEnjoy the meal with friends and family.',
      );
      expect(steps, ['Serve hot.', 'Enjoy the meal with friends and family.']);
    });

    test('a single paragraph stays one step', () {
      final steps = InstructionParser.parse(
        'Bring the water to a boil, add the salt, then cook the pasta for ten minutes.',
      );
      expect(steps.length, 1);
    });

    test('messy real meal: headers, numbers, blank lines', () {
      final steps = InstructionParser.parse(
        'STEP 1\r\n1. Heat the oil in a pan over medium heat.\r\n\r\nSTEP 2\r\n2. Add the garlic and fry for one minute.\r\n\r\nSTEP 3\r\nAdd tomatoes and simmer gently for 20 minutes.',
      );
      expect(steps.length, 3);
      expect(steps.every((s) => !RegExp(r'^\d').hasMatch(s)), isTrue);
    });
  });
}
