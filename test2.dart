import 'package:screen_protector/screen_protector.dart';

void main() async {
  ScreenProtector.addListener(() {
    print('screenshot taken');
  }, (path) {
    print('screen record taken');
  });
}
