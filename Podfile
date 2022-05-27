# Uncomment the next line to define a global platform for your project
# platform :ios, '12.0'
use_frameworks!


target 'ARKitMeasuringTape' do

	pod 'ARCore/Geospatial', '~> 1.31.0'

end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '12.0'
    end
  end
end
