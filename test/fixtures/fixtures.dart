import 'dart:convert';
import 'dart:io';

/// Loads a JSON fixture (real TheMealDB response shapes) from test/fixtures.
Map<String, dynamic> loadFixture(String name) =>
    jsonDecode(File('test/fixtures/$name.json').readAsStringSync())
        as Map<String, dynamic>;
