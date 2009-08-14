require File.join(File.dirname(__FILE__), '..', 'iso-639-1-list.rb')

namespace :cayox do
  desc "Generate translation template file (.pot) from app source code"
  task :generate_pot do
    `rm po/cayox.pot`
    `rgettext \`find app lib merb -type f | grep -v .svn\` -o po/cayox.pot`
  end

  desc "Generate .mo files from .po files"
  task :generate_mo do
    Dir[Merb.root / "po/**/*.po"].each do |file|
      outfile = file.split('.po')[0] + ".mo"
      `msgfmt #{file} -o #{outfile}`
    end
  end

  desc "Prepare languages"
  task :prepare_languages => :merb_env do
    ISO_LANGUAGES.each do |key, val|
      Language.create(:iso_code => key, :name => val)
    end
  end
end