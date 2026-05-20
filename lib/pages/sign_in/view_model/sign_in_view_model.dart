import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:afterdamage/config/app_config.dart';
import 'package:afterdamage/config/setting_keys.dart';
import 'package:afterdamage/pages/sign_in/view_model/model/public_homeserver_data.dart';
import 'package:afterdamage/pages/sign_in/view_model/sign_in_state.dart';
import 'package:afterdamage/widgets/matrix.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:matrix/matrix_api_lite/utils/logs.dart';

class SignInViewModel extends ValueNotifier<SignInState> {
  final MatrixState matrixService;
  final bool signUp;
  final TextEditingController filterTextController = TextEditingController();

  SignInViewModel(this.matrixService, {required this.signUp})
    : super(SignInState()) {
    refreshPublicHomeservers();
    filterTextController.addListener(_filterHomeservers);
  }

  @override
  void dispose() {
    filterTextController.removeListener(_filterHomeservers);
    super.dispose();
  }

  void _filterHomeservers() {
    final filterText = filterTextController.text.trim().toLowerCase();
    final filteredPublicHomeservers =
        value.publicHomeservers.data
            ?.where(
              (homeserver) =>
                  homeserver.name?.toLowerCase().contains(filterText) ?? false,
            )
            .toList() ??
        [];
    if (filterText.length >= 3 &&
        (filterText.contains('.') || filterText == 'localhost') &&
        Uri.tryParse(filterText) != null &&
        !filteredPublicHomeservers.any(
          (homeserver) => homeserver.name == filterText,
        )) {
      filteredPublicHomeservers.add(PublicHomeserverData(name: filterText));
    }

    value = value.copyWith(
      filteredPublicHomeservers: filteredPublicHomeservers,
    );
  }

  Future<void> refreshPublicHomeservers() async {
    value = value.copyWith(publicHomeservers: AsyncSnapshot.waiting());
    final defaultHomeserverData = PublicHomeserverData(
      name: AppSettings.defaultHomeserver.value,
    );
    try {
      final jsonString = await rootBundle.loadString(
        'assets/recommended_homeservers.json',
      );
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      final homeserverJsonList = json['public_servers'] as List;

      final publicHomeservers = homeserverJsonList
          .map((json) => PublicHomeserverData.fromJson(json))
          .toList();

      if (signUp) {
        publicHomeservers.removeWhere((server) {
          return server.regMethod == null && server.available != false;
        });
      }

      final defaultServer = publicHomeservers.singleWhereOrNull(
        (server) => server.name == AppSettings.defaultHomeserver.value,
      );

      if (defaultServer == null) {
        publicHomeservers.insert(0, defaultHomeserverData);
      }

      final firstSelectable = publicHomeservers.firstWhereOrNull(
        (s) => s.available != false,
      );
      value = value.copyWith(
        selectedHomeserver:
            value.selectedHomeserver ?? firstSelectable ?? publicHomeservers.first,
        publicHomeservers: AsyncSnapshot.withData(
          ConnectionState.done,
          publicHomeservers,
        ),
      );
    } catch (e, s) {
      Logs().w('Unable to load homeservers from asset...', e, s);
      final fallbackList = AppConfig.knownHomeservers
          .map(
            (s) => PublicHomeserverData(
              name: s['name'],
              description: s['description'],
            ),
          )
          .toList();
      final defaultServer = fallbackList.singleWhereOrNull(
        (server) => server.name == AppSettings.defaultHomeserver.value,
      );
      if (defaultServer == null) fallbackList.insert(0, defaultHomeserverData);
      value = value.copyWith(
        selectedHomeserver: defaultHomeserverData,
        publicHomeservers: AsyncSnapshot.withData(
          ConnectionState.done,
          fallbackList,
        ),
      );
    }
    _filterHomeservers();
  }

  void selectHomeserver(PublicHomeserverData? publicHomeserverData) {
    value = value.copyWith(selectedHomeserver: publicHomeserverData);
  }

  void setLoginLoading(AsyncSnapshot<bool> loginLoading) {
    value = value.copyWith(loginLoading: loginLoading);
  }
}
