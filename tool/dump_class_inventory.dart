import 'dart:io';

enum DeclarationKind { dartClass, mixin, extensionType, extension, enumType }

enum MemberKind { field, constructor, method, getter, setter }

class TypeDeclaration {
  const TypeDeclaration({
    required this.start,
    required this.kind,
    required this.name,
    required this.header,
    required this.bodyStart,
    required this.bodyEnd,
  });

  final int start;
  final DeclarationKind kind;
  final String name;
  final String header;
  final int bodyStart;
  final int bodyEnd;
}

class MemberDeclaration {
  const MemberDeclaration({required this.kind, required this.signature});

  final MemberKind kind;
  final String signature;
}

class FileInventory {
  const FileInventory({required this.path, required this.topLevelFunctions, required this.types});

  final String path;
  final List<String> topLevelFunctions;
  final List<TypeInventory> types;
}

class TypeInventory {
  const TypeInventory({
    required this.declaration,
    required this.fields,
    required this.constructors,
    required this.methods,
    required this.getters,
    required this.setters,
  });

  final TypeDeclaration declaration;
  final List<String> fields;
  final List<String> constructors;
  final List<String> methods;
  final List<String> getters;
  final List<String> setters;
}

final RegExp _declarationPattern = RegExp(
  r'\b(abstract\s+class|base\s+class|final\s+class|interface\s+class|sealed\s+class|class|mixin\s+class|mixin|enum|extension\s+type|extension)\s+([A-Za-z_]\w*(?:\s*<[^>{;]+>)?)?',
);

String _collapseWhitespace(String value) {
  return value.replaceAll(RegExp(r'\s+'), ' ').trim();
}

String _declarationLabel(DeclarationKind kind) {
  return switch (kind) {
    DeclarationKind.dartClass => 'class',
    DeclarationKind.mixin => 'mixin',
    DeclarationKind.extensionType => 'extension type',
    DeclarationKind.extension => 'extension',
    DeclarationKind.enumType => 'enum',
  };
}

String _sanitizeSource(String source) {
  final buffer = StringBuffer();
  var index = 0;

  while (index < source.length) {
    final current = source[index];
    final next = index + 1 < source.length ? source[index + 1] : '';
    final previous = index > 0 ? source[index - 1] : '';

    if (current == '/' && next == '/') {
      buffer.write('  ');
      index += 2;
      while (index < source.length && source[index] != '\n') {
        buffer.write(' ');
        index++;
      }
      continue;
    }

    if (current == '/' && next == '*') {
      buffer.write('  ');
      index += 2;
      while (index < source.length) {
        final blockCurrent = source[index];
        final blockNext = index + 1 < source.length ? source[index + 1] : '';
        if (blockCurrent == '*' && blockNext == '/') {
          buffer.write('  ');
          index += 2;
          break;
        }

        buffer.write(blockCurrent == '\n' ? '\n' : ' ');
        index++;
      }
      continue;
    }

    final isRawStringStart = current == 'r' && (next == '"' || next == "'");
    final isTripleSingle = current == "'" && next == "'" && index + 2 < source.length && source[index + 2] == "'";
    final isTripleDouble = current == '"' && next == '"' && index + 2 < source.length && source[index + 2] == '"';
    final isSingleQuoted = current == "'" && previous != '\\';
    final isDoubleQuoted = current == '"' && previous != '\\';

    if (isRawStringStart) {
      final quote = next;
      final isTriple = index + 3 < source.length && source[index + 2] == quote && source[index + 3] == quote;
      buffer.write(isTriple ? 'r   ' : 'r ');
      index += isTriple ? 4 : 2;
      while (index < source.length) {
        if (isTriple) {
          if (index + 2 < source.length &&
              source[index] == quote &&
              source[index + 1] == quote &&
              source[index + 2] == quote) {
            buffer.write('   ');
            index += 3;
            break;
          }
        } else if (source[index] == quote) {
          buffer.write(' ');
          index++;
          break;
        }

        buffer.write(source[index] == '\n' ? '\n' : ' ');
        index++;
      }
      continue;
    }

    if (isTripleSingle || isTripleDouble) {
      final quote = current;
      buffer.write('   ');
      index += 3;
      while (index < source.length) {
        if (index + 2 < source.length &&
            source[index] == quote &&
            source[index + 1] == quote &&
            source[index + 2] == quote) {
          buffer.write('   ');
          index += 3;
          break;
        }

        buffer.write(source[index] == '\n' ? '\n' : ' ');
        index++;
      }
      continue;
    }

    if (isSingleQuoted || isDoubleQuoted) {
      final quote = current;
      buffer.write(' ');
      index++;
      while (index < source.length) {
        final value = source[index];
        final escaped = value == quote && source[index - 1] != '\\';
        buffer.write(value == '\n' ? '\n' : ' ');
        index++;
        if (escaped) {
          break;
        }
      }
      continue;
    }

    buffer.write(current);
    index++;
  }

  return buffer.toString();
}

int _findMatchingBrace(String source, int openBraceIndex) {
  var depth = 0;
  for (var index = openBraceIndex; index < source.length; index++) {
    final character = source[index];
    if (character == '{') {
      depth++;
    } else if (character == '}') {
      depth--;
      if (depth == 0) {
        return index;
      }
    }
  }

  return -1;
}

DeclarationKind _parseDeclarationKind(String value) {
  if (value.contains('extension type')) {
    return DeclarationKind.extensionType;
  }
  if (value.startsWith('extension')) {
    return DeclarationKind.extension;
  }
  if (value.startsWith('enum')) {
    return DeclarationKind.enumType;
  }
  if (value.contains('mixin')) {
    return DeclarationKind.mixin;
  }
  return DeclarationKind.dartClass;
}

List<TypeDeclaration> _findTypeDeclarations(String source, String sanitizedSource) {
  final declarations = <TypeDeclaration>[];
  var depth = 0;
  var index = 0;

  while (index < sanitizedSource.length) {
    final character = sanitizedSource[index];

    if (character == '{') {
      depth++;
      index++;
      continue;
    }

    if (character == '}') {
      depth--;
      index++;
      continue;
    }

    if (depth == 0) {
      final match = _declarationPattern.matchAsPrefix(sanitizedSource, index);
      if (match != null) {
        final declarationText = _collapseWhitespace(match.group(1)!);
        final name = _collapseWhitespace(match.group(2) ?? '(anonymous)');
        final openBraceIndex = sanitizedSource.indexOf('{', match.end);
        if (openBraceIndex != -1) {
          final closeBraceIndex = _findMatchingBrace(sanitizedSource, openBraceIndex);
          if (closeBraceIndex != -1) {
            declarations.add(
              TypeDeclaration(
                start: match.start,
                kind: _parseDeclarationKind(declarationText),
                name: name,
                header: _collapseWhitespace(source.substring(match.start, openBraceIndex)),
                bodyStart: openBraceIndex + 1,
                bodyEnd: closeBraceIndex,
              ),
            );
            index = closeBraceIndex + 1;
            continue;
          }
        }
      }
    }

    index++;
  }

  return declarations;
}

List<String> _findTopLevelFunctions(String source, String sanitizedSource, List<TypeDeclaration> declarations) {
  final excludedRanges = declarations.map((declaration) => (declaration.start, declaration.bodyEnd)).toList();
  final functions = <String>[];
  var depth = 0;
  var parenDepth = 0;
  var statementStart = 0;

  bool isInsideType(int index) {
    for (final range in excludedRanges) {
      if (index >= range.$1 && index <= range.$2) {
        return true;
      }
    }
    return false;
  }

  for (var index = 0; index < sanitizedSource.length; index++) {
    if (isInsideType(index)) {
      continue;
    }

    final character = sanitizedSource[index];
    if (character == '(') {
      parenDepth++;
    } else if (character == ')') {
      if (parenDepth > 0) {
        parenDepth--;
      }
    } else if (character == '{') {
      if (depth == 0 && parenDepth == 0) {
        final candidate = _collapseWhitespace(source.substring(statementStart, index));
        if (_looksLikeFunction(candidate)) {
          functions.add(candidate);
        }
        statementStart = index + 1;
      }
      depth++;
    } else if (character == '}') {
      if (depth > 0) {
        depth--;
      }
      if (depth == 0) {
        statementStart = index + 1;
      }
    } else if (character == ';' && depth == 0 && parenDepth == 0) {
      statementStart = index + 1;
    }
  }

  return functions;
}

bool _looksLikeFunction(String candidate) {
  if (candidate.isEmpty) {
    return false;
  }
  if (candidate.startsWith('import ') || candidate.startsWith('export ') || candidate.startsWith('part ')) {
    return false;
  }
  if (candidate.startsWith('typedef ')) {
    return false;
  }

  final normalized = candidate.trimLeft();
  return normalized.contains('(') &&
      !normalized.startsWith('if ') &&
      !normalized.startsWith('for ') &&
      !normalized.startsWith('while ') &&
      !normalized.startsWith('switch ');
}

List<String> _splitMemberStatements(String source, String sanitizedSource, int start, int end) {
  final statements = <String>[];
  var braceDepth = 1;
  var parenDepth = 0;
  var statementStart = start;
  var index = start;

  while (index < end) {
    final character = sanitizedSource[index];
    if (character == '(') {
      parenDepth++;
    } else if (character == ')') {
      if (parenDepth > 0) {
        parenDepth--;
      }
    } else if (character == '{') {
      if (braceDepth == 1 && parenDepth == 0) {
        final statement = _collapseWhitespace(source.substring(statementStart, index));
        if (statement.isNotEmpty) {
          statements.add(statement);
        }
        final matchingBrace = _findMatchingBrace(sanitizedSource, index);
        if (matchingBrace == -1) {
          break;
        }
        braceDepth = 1;
        index = matchingBrace;
        statementStart = index + 1;
      } else {
        braceDepth++;
      }
    } else if (character == '}') {
      braceDepth--;
      if (braceDepth == 0) {
        break;
      }
    } else if (character == ';' && braceDepth == 1 && parenDepth == 0) {
      final statement = _collapseWhitespace(source.substring(statementStart, index + 1));
      if (statement.isNotEmpty) {
        statements.add(statement);
      }
      statementStart = index + 1;
    }
    index++;
  }

  return statements;
}

String _stripLeadingAnnotations(String signature) {
  var value = signature.trim();
  while (value.startsWith('@')) {
    final newlineIndex = value.indexOf('\n');
    final spaceIndex = value.indexOf(' ');
    final cutIndex = newlineIndex == -1
        ? spaceIndex
        : spaceIndex == -1
        ? newlineIndex
        : (newlineIndex < spaceIndex ? newlineIndex : spaceIndex);
    if (cutIndex == -1) {
      return value;
    }
    value = value.substring(cutIndex + 1).trimLeft();
  }
  return _collapseWhitespace(value);
}

String? _extractDeclaredName(String signature) {
  final match = RegExp(r'([A-Za-z_]\w*)\s*[;=]').firstMatch(signature);
  return match?.group(1);
}

({int open, int close})? _findOuterParameterList(String signature) {
  var depth = 0;
  var openIndex = -1;

  for (var index = 0; index < signature.length; index++) {
    final character = signature[index];
    if (character == '(') {
      if (depth == 0) {
        openIndex = index;
      }
      depth++;
      continue;
    }

    if (character == ')') {
      if (depth == 0) {
        continue;
      }
      depth--;
      if (depth == 0 && openIndex != -1) {
        return (open: openIndex, close: index);
      }
    }
  }

  return null;
}

MemberDeclaration? _classifyMember(String ownerName, String rawSignature) {
  final signature = _stripLeadingAnnotations(rawSignature);
  if (signature.isEmpty) {
    return null;
  }
  if (signature == '}' || signature == '{') {
    return null;
  }
  if (signature.startsWith('factory $ownerName') ||
      signature.startsWith('$ownerName(') ||
      signature.startsWith('$ownerName.') ||
      signature.contains(' $ownerName(') ||
      signature.contains(' $ownerName.')) {
    return MemberDeclaration(kind: MemberKind.constructor, signature: signature);
  }
  if (signature.contains(RegExp(r'\bget\b'))) {
    return MemberDeclaration(kind: MemberKind.getter, signature: signature);
  }
  if (signature.contains(RegExp(r'\bset\b'))) {
    return MemberDeclaration(kind: MemberKind.setter, signature: signature);
  }

  final parameterList = _findOuterParameterList(signature);
  if (parameterList != null) {
    final suffix = signature.substring(parameterList.close + 1).trim();
    final prefix = signature.substring(0, parameterList.open);
    final hasAssignmentBeforeParameterList = prefix.contains('=');
    final looksLikeMethod =
        suffix.isEmpty ||
        suffix == ';' ||
        suffix == 'async' ||
        suffix == 'async*' ||
        suffix == 'sync*' ||
        suffix.startsWith('=>') ||
        suffix.startsWith(':');
    if (looksLikeMethod && !hasAssignmentBeforeParameterList) {
      return MemberDeclaration(kind: MemberKind.method, signature: signature);
    }
  }

  final fieldName = _extractDeclaredName(signature);
  if (fieldName != null) {
    return MemberDeclaration(kind: MemberKind.field, signature: signature);
  }

  return null;
}

TypeInventory _buildTypeInventory(String source, String sanitizedSource, TypeDeclaration declaration) {
  final statements = _splitMemberStatements(source, sanitizedSource, declaration.bodyStart, declaration.bodyEnd);
  final fields = <String>[];
  final constructors = <String>[];
  final methods = <String>[];
  final getters = <String>[];
  final setters = <String>[];

  for (final statement in statements) {
    final member = _classifyMember(declaration.name.split('<').first.trim(), statement);
    if (member == null) {
      continue;
    }

    switch (member.kind) {
      case MemberKind.field:
        fields.add(member.signature);
        break;
      case MemberKind.constructor:
        constructors.add(member.signature);
        break;
      case MemberKind.method:
        methods.add(member.signature);
        break;
      case MemberKind.getter:
        getters.add(member.signature);
        break;
      case MemberKind.setter:
        setters.add(member.signature);
        break;
    }
  }

  return TypeInventory(
    declaration: declaration,
    fields: fields,
    constructors: constructors,
    methods: methods,
    getters: getters,
    setters: setters,
  );
}

FileInventory _buildFileInventory(String filePath, String repoRoot) {
  final source = File(filePath).readAsStringSync();
  final sanitizedSource = _sanitizeSource(source);
  final declarations = _findTypeDeclarations(source, sanitizedSource);
  final relativePath = filePath.replaceFirst('$repoRoot/', '');
  final topLevelFunctions = _findTopLevelFunctions(source, sanitizedSource, declarations);
  final typeInventories = declarations
      .map((declaration) => _buildTypeInventory(source, sanitizedSource, declaration))
      .toList();

  return FileInventory(path: relativePath, topLevelFunctions: topLevelFunctions, types: typeInventories);
}

String _formatSection(String title, List<String> values) {
  if (values.isEmpty) {
    return '';
  }

  final buffer = StringBuffer();
  buffer.writeln('  $title');
  for (final value in values) {
    buffer.writeln('    - $value');
  }
  return buffer.toString();
}

String _formatInventory(List<FileInventory> files) {
  final buffer = StringBuffer();
  buffer.writeln('Serenity code inventory');
  buffer.writeln('Generated: ${DateTime.now().toIso8601String()}');
  buffer.writeln();

  for (final file in files) {
    buffer.writeln(file.path);

    if (file.topLevelFunctions.isNotEmpty) {
      buffer.writeln('top-level functions');
      for (final function in file.topLevelFunctions) {
        buffer.writeln('  - $function');
      }
    }

    if (file.types.isEmpty && file.topLevelFunctions.isEmpty) {
      buffer.writeln('  (no classes, enums, mixins, extensions, or top-level functions)');
      buffer.writeln();
      continue;
    }

    for (final type in file.types) {
      buffer.writeln('${_declarationLabel(type.declaration.kind)} ${type.declaration.name}');
      buffer.writeln('  declaration');
      buffer.writeln('    - ${type.declaration.header}');
      final fieldsSection = _formatSection('fields', type.fields);
      final constructorsSection = _formatSection('constructors', type.constructors);
      final gettersSection = _formatSection('getters', type.getters);
      final settersSection = _formatSection('setters', type.setters);
      final methodsSection = _formatSection('methods', type.methods);
      if (fieldsSection.isNotEmpty) {
        buffer.write(fieldsSection);
      }
      if (constructorsSection.isNotEmpty) {
        buffer.write(constructorsSection);
      }
      if (gettersSection.isNotEmpty) {
        buffer.write(gettersSection);
      }
      if (settersSection.isNotEmpty) {
        buffer.write(settersSection);
      }
      if (methodsSection.isNotEmpty) {
        buffer.write(methodsSection);
      }
    }

    buffer.writeln();
  }

  return buffer.toString();
}

void _writeInventoryFile({required String repoRoot, required String outputPath}) {
  final libDirectory = Directory('$repoRoot/lib');
  final files =
      libDirectory
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart'))
          .map((file) => file.path)
          .toList()
        ..sort();

  final inventories = files.map((path) => _buildFileInventory(path, repoRoot)).toList();
  final outputFile = File(outputPath);
  outputFile.parent.createSync(recursive: true);
  outputFile.writeAsStringSync(_formatInventory(inventories));
}

void main(List<String> arguments) {
  final scriptFile = File.fromUri(Platform.script);
  final repoRoot = scriptFile.parent.parent.path;
  final outputPath = arguments.isNotEmpty ? arguments.first : '$repoRoot/docs/class_inventory.txt';
  _writeInventoryFile(repoRoot: repoRoot, outputPath: outputPath);
  stdout.writeln('Wrote inventory to $outputPath');
}
