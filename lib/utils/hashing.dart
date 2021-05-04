import 'dart:convert';

import 'package:crypto/crypto.dart';

String hashOnlineSong({String id, String source, String additionalInfo}) => sha1
    .convert(utf8.encode('${id ?? ''}${source ?? ''}${additionalInfo ?? ''}'))
    .toString()
    .substring(0, 10)
    .toUpperCase();
