# Gemfile - Ruby dependencies for MonoTimer

source "https://rubygems.org"

# Fastlane - iOS automation tool
gem "fastlane", "~> 2.220"
plugins_path = File.join(File.dirname(__FILE__), 'fastlane', 'Pluginfile')
eval_gemfile(plugins_path) if File.exist?(plugins_path)
