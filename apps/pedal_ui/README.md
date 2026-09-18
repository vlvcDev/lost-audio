# Pedal UI

This directory keeps the hand-maintained Dart application separate from Flutter's generated Linux runner. On a Linux development machine with GTK development packages and a working Flutter SDK, generate the runner once:

```sh
flutter create --platforms=linux .
flutter run -d linux
```

The app connects to `/tmp/pedal-control.sock` by default. Set `PEDAL_CONTROL_SOCKET=/run/pedal/control.sock` in the deployed appliance.
