namespace :cayox do
  desc "Prepare flags"
  task :prepare_flags => :merb_env do
    flags = {
      :element => [
        GetText._("Spam or junk"),
        GetText._("Porn adult content"),
        GetText._("Hateful or offensive"),
      ],
      :topic => [
        GetText._("Spam or junk"),
        GetText._("Porn adult content"),
        GetText._("Hateful or offensive"),
      ]
    }
    flags.each do |type, descs|
      descs.each do |desc|
        Flag.create(:type => type, :description => desc) unless Flag.first(:type => type, :description => desc)
      end
    end
  end
end