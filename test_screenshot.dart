import 'package:screen_protector/screen_protector.dart';

void main() async {
  await ScreenProtector.preventScreenshotOn();
  await ScreenProtector.preventScreenshotOff();
}
