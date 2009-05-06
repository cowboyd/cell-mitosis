$:.unshift "#{File.dirname(__FILE__)}/lib"

FileUtils.mkdir_p "#{Rails.public_path}/javascripts/gen"
FileUtils.mkdir_p "#{Rails.public_path}/stylesheets/gen"


