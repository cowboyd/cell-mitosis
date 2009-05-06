namespace :mitosis do
  desc 'Clear out mitosis generated javascripts and stylesheets.'
  task :clobber => :environment do
    FileUtils.rm_rf "#{Rails.public_path}/javascripts/gen" 
    FileUtils.rm_rf "#{Rails.public_path}/stylesheets/gen"
  end

# desc 'Clear out mitosis generated javascripts and stylesheets.'
# task
#   FileUtils.mkdir_p "#{Rails.public_path}/javascripts/gen"
#   FileUtils.mkdir_p "#{Rails.public_path}/stylesheets/gen"
# end

end
