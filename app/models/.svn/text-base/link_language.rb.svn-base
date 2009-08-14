class LinkLanguage
  include DataMapper::Resource

  property :id, Serial

  belongs_to :link
  belongs_to :language

  # class methods
  
  def self.add_missing_link_languages(links, language)
    links.each do |link|
      if language && !language.in?(link.languages)
        LinkLanguage.create(:link => link, :language => language)
      end
    end
  end

end
