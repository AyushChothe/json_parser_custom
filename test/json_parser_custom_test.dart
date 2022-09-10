import 'package:json_parser_custom/json_parser_custom.dart';
import 'package:test/test.dart';

void main() {
  test('Parse JSON', () {
    String code = """{
  "str": "Hello, Ash",
  "arr": [1, 2, 3, 4, 5],
  "bool": true,
  "null": null,
  "num": 12345,
  "obj": {
    "str": "Strings are Awesome",
    "arr": [1, 2, 3],
    "bool": false,
    "null": null,
    "num": 123
  }
}""";
    List<Token> tokens = Tokenizer(code: code).tokenize();
    assert(Parser(tokens: tokens).parse() != null);
  });
}
