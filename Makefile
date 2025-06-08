run-macos-firebase:
	fvm flutter run -t lib/main.firebase.dart -d macos

run-macos-local:
	fvm flutter run -t lib/main.local.dart -d macos

clean:
	fvm flutter clean && fvm flutter pub get

clean-macos:
	make clean && cd macos && pod install --repo-update

build-macos-firebase:
	fvm flutter build macos -t lib/main.firebase.dart -d --release

build-macos-local:
	fvm flutter build macos -t lib/main.local.dart -d --release
