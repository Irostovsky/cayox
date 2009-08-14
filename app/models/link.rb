class Link
  include DataMapper::Resource

  # properties

  property :id,         Serial
  property :url,        Text, :nullable => false, :lazy => false, :unique => true,
                              :format => /^(http|https):\/\/[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,5}(([0-9]{1,5})?\/.*)?$/ix
  property :site,       String, :nullable => false
  property :is_root,    Boolean, :nullable => false
  property :created_at, DateTime
  property :updated_at, DateTime

  # associations

  has n, :bookmarks
  has 1, :element

  has n, :link_languages
  has n, :languages, :through => :link_languages

  # validations

  validates_length :url, :max => 512

  # hooks

  before :valid? do
    if m = self.url.to_s.match(/\w+:\/\/([^\/]+)(.*)/)
      self.site = m[1]
      self.is_root = (m[2] == "/")
    end
  end

  # class methods

  def self.get_by_url(url)
    url = "http://" + url if url !~ /^https?:\/\//
    url << "/" if url =~ /^\w+:\/\/[^\/]+$/ # add trailing "/" if domain root without "/"
    Link.first(:url => url) || Link.new(:url => url)
  end

  # instance methods

  def name
    url
  end

  def root?
    is_root
  end

  def short
    self.url.to_s[/https?:\/\/[^\/]+/] || "http://" + self.site
  end
end
