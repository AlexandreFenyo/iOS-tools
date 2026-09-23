platform :ios, '15.0'
workspace 'iOS tools.xcodeproj'

#pod 'CTHelp'

def available_pods
    pod 'CTHelp'
end

target 'iOS tools' do
  available_pods
end

# Le podspec de CTHelp déclare une cible iOS 10.0, refusée par les SDK récents
# (plage supportée : 15.0+). On aligne tous les pods sur la plate-forme du Podfile.
post_install do |installer|
  installer.pods_project.targets.each do |t|
    t.build_configurations.each do |config|
      if config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'].to_f < 15.0
        config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '15.0'
      end
    end
  end
end

# CocoaPods écrit ALWAYS_EMBED_SWIFT_STANDARD_LIBRARIES = YES dans les xcconfig de la cible,
# ce que Xcode 27 signale (« Remove Embed Swift Standard Libraries Setting ») sans pouvoir le
# retirer lui-même : inutile depuis iOS 12.2 (runtime Swift intégré à l'OS, minimum 16.6 ici).
post_integrate do |installer|
  Dir.glob(File.join(installer.sandbox.root, 'Target Support Files', 'Pods-*', '*.xcconfig')).each do |path|
    content = File.read(path)
    cleaned = content.gsub(/^ALWAYS_EMBED_SWIFT_STANDARD_LIBRARIES = YES\n/, '')
    File.write(path, cleaned) if cleaned != content
  end
end
