# Podfile
platform :ios, '16.0'
use_frameworks!
inhibit_all_warnings!

target 'TherianDiary' do
  # Firebase
  pod 'Firebase/Auth'
  pod 'Firebase/Firestore'
  pod 'Firebase/Storage'
  pod 'Firebase/Crashlytics'
  pod 'Firebase/Analytics'

  # Google Sign-In
  pod 'GoogleSignIn'

  # Monetization
  pod 'RevenueCat'
  pod 'Google-Mobile-Ads-SDK'

  # UI / Async Images
  pod 'SDWebImageSwiftUI'

  # Animations
  pod 'lottie-ios'

  target 'TherianDiaryTests' do
    inherit! :search_paths
  end
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['SWIFT_VERSION'] = '5.9'
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '16.0'
    end
  end
end
