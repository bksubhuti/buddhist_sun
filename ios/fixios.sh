flutter clean
cd ios
pod cache clean --all
rm -rf Podfile.lock Pods
pod install --repo-update
cd ..
flutter pub get