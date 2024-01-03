import 'package:flutter/widgets.dart';

class BuilderHelper {
  static T findAncestor<T>(BuildContext context) {
    T? ancestor;
    context.visitAncestorElements((Element element) {
      if (element.widget is T) {
        ancestor = element.widget as T;
        return false; // stop the search
      }
      return true; // continue the search
    });
    return ancestor!;
  }
}
