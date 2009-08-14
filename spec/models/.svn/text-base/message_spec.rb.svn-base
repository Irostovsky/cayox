require File.join( File.dirname(__FILE__), '..', "spec_helper" )

describe Message do

  it "should not be empty" do
    m = Message.new
    m.should_not be_valid
  end

  it "new message should be not read" do
    m = Message.new
    m.read.should be(false)
  end

  it "new message should be created" do
    user = User.gen
    m = Message.create(:user_id => user.id, :body => "Kapitan Bomba has arrived!", :type => :friendship)
    m.should be_valid
  end

end