import 'dart:io';

import 'package:json_parser_custom/json_parser_custom.dart';

void main(List<String> arguments) {
  String code = File("./bin/test.json").readAsStringSync();
  List<Token> tokens = Tokenizer(code: code).tokenize();
  print(Parser(tokens: tokens).parse());
}
