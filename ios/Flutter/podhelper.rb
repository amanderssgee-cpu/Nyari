# CocoaPods pod helper script for Flutter iOS projects.

def flutter_root
  generated_xcode_build_settings_path = File.expand_path(File.join('..', 'Flutter', 'Generated.xcconfig'), __FILE__)

  unless File.exist?(generated_xcode_build_settings_path)
    raise "Generated.xcconfig must exist. If you're running pod install manually, run 'flutter pub get' first."
  end

  File.foreach(generated_xcode_build_settings_path) do |line|
    matches = line.match(/FLUTTER_ROOT\=(.*)/)
    return matches[1].strip if matches
  end

  raise "FLUTTER_ROOT not found in Generated.xcconfig"
end

require File.expand_path(File.join('packages', 'flutter_tools', 'bin', 'podhelper'), flutter_root)
