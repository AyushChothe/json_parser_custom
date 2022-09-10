// ignore_for_file: constant_identifier_names

const whitepace = " \n\t\r";
const numbers = "0123456789";
final identifiers = RegExp(r"\w");

enum TokenType {
  StringLiteral,
  NumberLiteral,
  BooleanLiteral,
  NullLiteral,
  LeftCurly,
  RightCurly,
  LeftSquare,
  RightSquare,
  Comma,
  Colon,
  EOF
}

enum ValueType {
  StringValue,
  NumberValue,
  BooleanValue,
  JsonValue,
  ArrayValue,
  NullValue
}

class Position {
  int line, column;
  Position({
    required this.line,
    required this.column,
  });
}

class PositionRange {
  Position from;
  Position? to;
  PositionRange({
    required this.from,
    this.to,
  });
}

class Token {
  TokenType type;
  dynamic value;
  PositionRange pos;

  Token({
    required this.type,
    required this.value,
    required this.pos,
  });
  @override
  String toString() {
    return "$type($value)";
  }

  String getPos() => "[${pos.from.line}:${pos.from.column}]";
}

class Value {
  ValueType type;
  dynamic value;
  Value({
    required this.type,
    required this.value,
  });
  @override
  String toString() {
    return "$value";
  }
}

class Tokenizer {
  final String code;
  final List<Token> tokens = [];
  int _pos = 0, _line = 1, _col = 1;

  Tokenizer({
    required this.code,
  });

  void next() {
    if (_pos < code.length) {
      _pos++;
      _col++;
    }
  }

  String peek() => code[_pos];

  List<Token> tokenize() {
    while (_pos < code.length) {
      if (whitepace.contains(peek())) {
        if (peek() == '\n') {
          _line++;
          _col = 1;
        }
        next();
      } else if (numbers.contains(peek())) {
        tokens.add(parseNumber());
      } else if (peek() == '"') {
        tokens.add(parseString());
      } else if (identifiers.hasMatch(peek())) {
        tokens.add(parseIdentifier());
      } else if (peek() == "{") {
        tokens.add(Token(
            type: TokenType.LeftCurly,
            value: peek(),
            pos: PositionRange(from: Position(line: _line, column: _col))));
        next();
      } else if (peek() == "}") {
        tokens.add(Token(
            type: TokenType.RightCurly,
            value: peek(),
            pos: PositionRange(from: Position(line: _line, column: _col))));
        next();
      } else if (peek() == "[") {
        tokens.add(Token(
            type: TokenType.LeftSquare,
            value: peek(),
            pos: PositionRange(from: Position(line: _line, column: _col))));
        next();
      } else if (peek() == "]") {
        tokens.add(Token(
            type: TokenType.RightSquare,
            value: peek(),
            pos: PositionRange(from: Position(line: _line, column: _col))));
        next();
      } else if (peek() == ",") {
        tokens.add(Token(
            type: TokenType.Comma,
            value: peek(),
            pos: PositionRange(from: Position(line: _line, column: _col))));
        next();
      } else if (peek() == ":") {
        tokens.add(Token(
            type: TokenType.Colon,
            value: peek(),
            pos: PositionRange(from: Position(line: _line, column: _col))));
        next();
      } else {
        throw Exception("Invalid Token [$_line:$_col]: '${peek()}'");
      }
    }
    //Add EOF
    tokens.add(Token(
        type: TokenType.EOF,
        value: null,
        pos: PositionRange(from: Position(line: _line, column: _col))));
    return (tokens);
  }

  Token parseNumber() {
    Position start = Position(line: _line, column: _col);
    String number = "";
    while (_pos < code.length && numbers.contains(peek())) {
      number += peek();
      next();
    }
    Position end = Position(line: _line, column: _col);
    return Token(
        type: TokenType.NumberLiteral,
        value: int.parse(number),
        pos: PositionRange(from: start, to: end));
  }

  Token parseString() {
    Position start = Position(line: _line, column: _col);
    String str = "";
    // Advance first '"'
    next();
    while (_pos < code.length && peek() != "\"") {
      str += peek();
      next();
    }
    // Advance last '"'
    next();
    Position end = Position(line: _line, column: _col);
    return Token(
        type: TokenType.StringLiteral,
        value: str,
        pos: PositionRange(from: start, to: end));
  }

  Token parseIdentifier() {
    Position start = Position(line: _line, column: _col);
    String id = "";
    while (_pos < code.length && identifiers.hasMatch(peek())) {
      id += peek();
      next();
    }
    Position end = Position(line: _line, column: _col);
    if (id != "null") {
      return Token(
          type: TokenType.BooleanLiteral,
          value: id,
          pos: PositionRange(from: start, to: end));
    } else {
      return Token(
          type: TokenType.NullLiteral,
          value: id,
          pos: PositionRange(from: start, to: end));
    }
  }
}

// Parser

class Parser {
  List<Token> tokens;
  Parser({
    required this.tokens,
  });

  int _pos = 0;

  void parserException(String pos, String expected, String found) {
    throw Exception("Invalid Syntax $pos: Expected '$expected' found '$found'");
  }

  void eat(TokenType tokenType, {bool strict = true}) {
    Token curr = peek();
    if (curr.type == tokenType) {
      next();
    } else if (strict == true) {
      parserException(curr.getPos(), tokenType.name, curr.type.name);
    }
  }

  void next() {
    if (_pos < tokens.length) {
      _pos++;
    }
  }

  Token peek() => tokens[_pos];

  Token? peekNext() => (_pos + 1 < tokens.length) ? tokens[_pos + 1] : null;

  dynamic parse() {
    if (peek().type == TokenType.LeftCurly) {
      return parseJson();
    } else if (peek().type == TokenType.LeftSquare) {
      return parseArray();
    }
  }

  Map parseJson() {
    Map<String, Value> map = {};
    eat(TokenType.LeftCurly);
    while (_pos < tokens.length && peek().type != TokenType.RightCurly) {
      map.addEntries([parseKeyValue()]);
      //Check trailing comma
      if (peek().type == TokenType.Comma &&
          peekNext()!.type == TokenType.RightCurly) {
        eat(TokenType.RightCurly);
      } else if ((peek().type == TokenType.Comma &&
              peekNext()?.type != TokenType.RightCurly) ||
          (peek().type != TokenType.RightCurly)) {
        eat(TokenType.Comma);
      } else {
        break;
      }
    }

    eat(TokenType.RightCurly);
    return map;
  }

  List parseArray() {
    List list = [];
    eat(TokenType.LeftSquare);
    while (_pos < tokens.length && peek().type != TokenType.RightSquare) {
      list.add(parseValue());
      //Check trailing comma
      if (peek().type == TokenType.Comma &&
          peekNext()!.type == TokenType.RightSquare) {
        eat(TokenType.RightSquare);
      } else if ((peek().type == TokenType.Comma &&
              peekNext()?.type != TokenType.RightSquare) ||
          (peek().type != TokenType.RightSquare)) {
        eat(TokenType.Comma);
      } else {
        break;
      }
    }
    eat(TokenType.RightSquare);
    return list;
  }

  String parseKey() {
    Token key = peek();
    eat(TokenType.StringLiteral);
    eat(TokenType.Colon);
    return key.value;
  }

  Value parseValue() {
    switch (peek().type) {
      case TokenType.StringLiteral:
        Token value = peek();
        next();
        return Value(type: ValueType.StringValue, value: value.value);
      case TokenType.NumberLiteral:
        Token value = peek();
        next();
        return Value(type: ValueType.NumberValue, value: value.value);
      case TokenType.BooleanLiteral:
        Token value = peek();
        next();
        return Value(type: ValueType.BooleanValue, value: value.value);
      case TokenType.NullLiteral:
        Token value = peek();
        next();
        return Value(type: ValueType.NullValue, value: value.value);
      case TokenType.LeftCurly:
        Map value = parseJson();
        return Value(type: ValueType.JsonValue, value: value);
      case TokenType.LeftSquare:
        List value = parseArray();
        return Value(type: ValueType.ArrayValue, value: value);
      default:
        throw Exception("Invalid Syntax!");
    }
  }

  MapEntry<String, Value> parseKeyValue() {
    String key = parseKey();
    dynamic value = parseValue();
    return MapEntry(key, value);
  }
}
