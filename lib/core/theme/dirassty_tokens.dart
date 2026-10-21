import 'package:flutter/material.dart';

/// Spacing scale: 4 / 8 / 12 / 16 / 24 / 32.
abstract final class DirasstySpace {
  static const xs = 4.0, sm = 8.0, md = 12.0, lg = 16.0, xl = 24.0, xxl = 32.0;
  static const screen = 20.0; // horizontal screen padding
  static const section = 20.0; // gap between sections
}

abstract final class DirasstyRadius {
  static const small = 8.0, card = 12.0, dialog = 20.0, pill = 999.0;
  static const smallR = BorderRadius.all(Radius.circular(small));
  static const cardR = BorderRadius.all(Radius.circular(card));
  static const dialogR = BorderRadius.all(Radius.circular(dialog));
  static const sheetR = BorderRadius.vertical(top: Radius.circular(dialog));
  static const pillR = BorderRadius.all(Radius.circular(pill));
}

abstract final class DirasstyShadow {
  static const level1 = [
    BoxShadow(color: Color(0x0F10231F), blurRadius: 2, offset: Offset(0, 1)),
  ];
  static const level2 = [
    BoxShadow(color: Color(0x0F10231F), blurRadius: 2, offset: Offset(0, 1)),
    BoxShadow(color: Color(0x0D10231F), blurRadius: 20, offset: Offset(0, 6)),
  ];
  static const sheet = [
    BoxShadow(color: Color(0x2410231F), blurRadius: 40, offset: Offset(0, 12)),
  ];
}

abstract final class DirasstySize {
  static const minTouch = 44.0;
  static const button = 52.0;
  static const buttonCompact = 44.0;
  static const input = 52.0;
  static const pinKey = 56.0;
  static const pinBox = 56.0;
  static const tabBar = 84.0; // incl. bottom safe area on a notched phone
  static const iconDefault = 24.0, iconList = 20.0, iconButton = 18.0;
  static const iconStroke = 1.8;
}

abstract final class DirasstyMotion {
  static const fast = Duration(milliseconds: 200);
  static const feedback = Duration(milliseconds: 250);
  static const shake = Duration(milliseconds: 240);
  static const push = Duration(milliseconds: 280);
  static const sheet = Duration(milliseconds: 300);
  static const celebrate = Duration(milliseconds: 380);
  static const progress = Duration(milliseconds: 400);
  static const splash = Duration(milliseconds: 1200);
  static const curve = Curves.easeOutCubic;
}
