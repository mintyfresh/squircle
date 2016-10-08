namespace :schema do
  task :deploy do
    Dir[Rails.root.join('spec/support/api/schemas/**/*.json')].each do |file|
      FileUtils.cp(file, Rails.root.join('public/schemas/'), verbose: true)
    end
  end

  task :clean do
    Dir[Rails.root.join('public/schemas/**/*.json')].each do |file|
      File.delete(file)
    end
  end
end
