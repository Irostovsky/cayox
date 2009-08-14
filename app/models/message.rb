class Message
  include DataMapper::Resource

  property :id, Serial
  property :body, Text, :nullable => false
  property :type, Enum[:friendship, :system, :roles]
  property :read, Boolean, :default => false
  property :created_at, DateTime

  belongs_to :user


end
