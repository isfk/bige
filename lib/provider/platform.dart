import 'package:flutter/foundation.dart';
import 'package:bige/common/global.dart';

class MirrorProvider with ChangeNotifier, DiagnosticableTreeMixin {
  MirrorProvider() {
    setMirror();
  }

  String _mirror = Global.getMirror();

  String get mirror => _mirror;

  void setMirror({String newMirror = ""}) {
    if (newMirror.isEmpty) {
      newMirror = Global.getMirror();
    }
    _mirror = newMirror;
    notifyListeners();
  }

  /// Makes `mirror` readable inside the devtools by listing all of its properties
  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty('mirror', mirror));
  }
}
