// Copyright 2019 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file or at https://developers.google.com/open-source/licenses/bsd.

import 'package:flutter/material.dart';

import 'utils.dart';

extension SyntaxHighlightingExtension on ColorScheme {
  Color get functionSyntaxColor =>
      isLight ? const Color(0xFF795E26) : const Color(0xFFDCDCAA);

  Color get declarationsSyntaxColor =>
      isLight ? const Color(0xFF267f99) : const Color(0xFF4EC9B0);

  Color get modifierSyntaxColor =>
      isLight ? const Color(0xFF0000FF) : const Color(0xFF569CD6);

  Color get controlFlowSyntaxColor =>
      isLight ? const Color(0xFFAF00DB) : const Color(0xFFC586C0);

  Color get variableSyntaxColor =>
      isLight ? const Color(0xFF001080) : const Color(0xFF9CDCFE);

  Color get commentSyntaxColor =>
      isLight ? const Color(0xFF008000) : const Color(0xFF6A9955);

  Color get stringSyntaxColor =>
      isLight ? const Color(0xFFB20001) : const Color(0xFFD88E73);

  Color get numericConstantSyntaxColor =>
      isLight ? const Color(0xFF098658) : const Color(0xFFB5CEA8);
}
