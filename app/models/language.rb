class Language
  include DataMapper::Resource

  property :id,       Serial
  property :iso_code, String, :nullable => false, :length => 2
  property :name,     String, :nullable => false, :length => 100

  has n, :link_languages
  has n, :links, :through => :link_languages

  def self.[](code)
    self.first(:iso_code => code.to_s)
  end
end
