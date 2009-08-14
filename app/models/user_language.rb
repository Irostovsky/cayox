class UserLanguage
  include DataMapper::Resource

  property :id, Serial

  belongs_to :user
  belongs_to :language
end
