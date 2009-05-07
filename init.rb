$:.unshift "#{File.dirname(__FILE__)}/lib"

require 'mitosis'

FileUtils.mkdir_p "#{Rails.public_path}/javascripts/gen"
FileUtils.mkdir_p "#{Rails.public_path}/stylesheets/gen"


