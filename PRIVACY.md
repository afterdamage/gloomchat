# Privacy

GloomChat is available on Android, iOS, Linux and as a web version. Desktop versions for Windows and macOS may follow.

*   [Matrix](#matrix)
*   [Database](#database)
*   [Encryption](#encryption)
*   [App Permissions](#app-permissions)
*   [Push Notifications](#push-notifications)
*   [PlayStore Safety Standards](#playstore-safety)

## <a id="matrix" href="#matrix">#</a> Matrix
GloomChat uses the Matrix protocol. This means that GloomChat is just a client that can be connected to any compatible matrix server. The respective data protection agreement of the server selected by the user then applies.

For convenience, one or more servers are set as default that the GloomChat developers consider trustworthy. The developers of GloomChat do not guarantee their trustworthiness. Before the first communication, users are informed which server they are connecting to.

GloomChat only communicates with the selected server and with [OpenStreetMap](https://openstreetmap.org) to display maps.

More information is available at: [https://matrix.org](https://matrix.org)

## <a id="database" href="#database">#</a> Database
GloomChat caches some data received from the server in a local sqflite database on the device of the user. On web indexedDB is used. GloomChat always tries to encrypt the database by using SQLCipher and stores the encryption key in the [Secure Storage](https://pub.dev/packages/flutter_secure_storage) of the device.

More information is available at: [https://pub.dev/packages/sqflite](https://pub.dev/packages/sqflite) and [https://pub.dev/packages/sqlcipher_flutter_libs](https://pub.dev/packages/sqlcipher_flutter_libs)

## <a id="encryption" href="#encryption">#</a> Encryption
All communication of substantive content between GloomChat and any server is done in secure way, using transport encryption to protect it.

GloomChat also uses End-To-End-Encryption by using [Vodozemac](https://github.com/matrix-org/vodozemac) and enables it by default for private chats.

## <a id="app-permissions" href="#app-permissions">#</a> App Permissions

The permissions are the same on Android and iOS but may differ in the name. This are the Android Permissions:

#### Internet Access
GloomChat needs to have internet access to communicate with the Matrix Server.

#### Notifications
GloomChat uses local and push notifications to alert the user about new messages, calls, and other app activity.

#### Vibrate
GloomChat uses vibration for local notifications. More informations about this are at the used package:
[https://pub.dev/packages/flutter_local_notifications](https://pub.dev/packages/flutter_local_notifications)

#### Camera
GloomChat can use the camera for camera-based features such as taking photos or scanning QR codes when the user chooses to do so.

#### Record Audio
GloomChat can send voice messages and participate in calls, therefore it needs the permission to record audio.

#### Write External Storage
The user is able to save received files and therefore the app needs this permission.

#### Read External Storage
The user is able to send files from the device's file system.

#### Location
GloomChat makes it possible to share the current location via the chat. When the user shares their location, GloomChat uses the device location service and sends the geo-data via Matrix.

#### Bluetooth
GloomChat may use Bluetooth for audio accessories such as headsets or other connected devices during calls or voice use.

#### Modify Audio Settings
GloomChat may adjust audio routing and audio behavior during voice and call features.

#### Wake Lock
GloomChat may keep the device awake during calls, voice messages, or other active foreground tasks.

#### Foreground Service
GloomChat may run a foreground service for ongoing features such as calls, microphone use, camera use, or screen sharing when the user starts those features.

## <a id="push-notifications" href="#push-notifications">#</a> Push Notifications
GloomChat uses the Firebase Cloud Messaging service for push notifications on Android and iOS. This takes place in the following steps:
1. The matrix server sends the push notification to the GloomChat Push Gateway
2. The GloomChat Push Gateway forwards the message in a different format to Firebase Cloud Messaging
3. Firebase Cloud Messaging waits until the user's device is online again
4. The device receives the push notification from Firebase Cloud Messaging and displays it as a notification

The source code of the push gateway can be viewed here:
[https://github.com/matrix-org/sygnal](https://github.com/matrix-org/sygnal)

`event_id_only` is used as the format for the push notification. A typical push notification therefore only contains:
- Event ID
- Room ID
- Unread Count
- Information about the device that is to receive the message

A typical push notification could look like this:
```json
{
  "notification": {
    "event_id": "$3957tyerfgewrf384",
    "room_id": "!slw48wfj34rtnrf:example.com",
    "counts": {
      "unread": 2,
      "missed_calls": 1
    },
    "devices": [
      {
        "app_id": "im.gloomchat.android",
        "pushkey": "V2h5IG9uIGVhcnRoIGRpZCB5b3UgZGVjb2RlIHRoaXM/",
        "pushkey_ts": 12345678,
        "data": {},
        "tweaks": {
          "sound": "bing"
        }
      }
    ]
  }
}
```

GloomChat sets the `event_id_only` flag at the Matrix Server. This server is then responsible to send the correct data.


# <a id="playstore-safety" href="#playstore-safety">#</a> Explanation of GloomChat's Compliance with Google Play Store's Safety Standards

GloomChat is committed to promoting a safe and respectful environment for all users. As a Matrix client, GloomChat connects users to various Matrix servers. Please note that GloomChat does not host or manage any servers directly, and as such, we do not have the capability to enforce content moderation or deletion within the app itself.

To enhance user safety and help protect against the sexual abuse and exploitation of children, GloomChat enables users to report inappropriate content directly to server administrators.

#### Reporting Content or Users:

1. Mark a message in the chat: Tap and hold the message you wish to report.
2. Report the message: Select the "Report" option.
3. Provide a reason and score: Enter the reason for reporting and assign a score from 1-100 to indicate how offensive the content is.
4. Notification to admin: The server administrator will be notified of the reported content.

In addition to reporting messages, users can also report other users following a similar process.

We encourage server administrators to adhere to strict safety standards and provide mechanisms for addressing and moderating inappropriate content. For more information on the Matrix protocol and its safety standards, please refer to the following link: https://matrix.org/docs/older/moderation/
