require File.join( File.dirname(__FILE__), '..', "spec_helper" )

describe Bookmark do
  
  it "should be valid" do
    b = Bookmark.new(:url => "http://jolka.com.pl")
    b.should_not be_valid
    b.name = "test bookmark"
    b.should be_valid
  end
  
  it "should create bookmark" do
    b = Bookmark.new
    b.url = "http://valid.test.url"
    b.name = "uniq bookmark name"
    b.description = "test description"
    b.should be_valid
  end
  
  it "should be one bookmark per one user" do
    user = User.gen
    link = Link.gen
    b = Bookmark.create(:link => link, :user => user, :name => "test", :description => "test")
    b2 = Bookmark.new(:link => link, :user => user)
    b2.should_not be_valid
  end
  
  it "should create bookmark tags when creating bookmarks with tags" do
    user = User.gen
    link = Link.gen
    bookmark = Bookmark.new(:tag_list => "1,2,3,4", :name => "bookmark", :description => "valid description", :user => user, :link => link)
    lambda do
      bookmark.save.should be(true)
      bookmark.reload
    end.should change(BookmarkTag, :count).by(4)
  end
  
  it "should destroy bookmark_tags when removing bookmark" do
    bookmark = Bookmark.gen(:tag_list => "1,2,3,4")
    lambda do
      bookmark.destroy
    end.should change(BookmarkTag, :count).by(-4)
  end
  
  it "should not create two bookmarks with same link" do
    user = User.gen
    link = Link.gen
    b = Bookmark.gen(:name => "test bookmark", :description => "test description", :link => link, :user => user)
    b.should be_valid
    bookmark = Bookmark.new(:name => "test bookmark2", :description => "test description2", :link => link, :user => user)
    bookmark.should_not be_valid
  end

  describe "tags" do

    it "should remove one tag" do
      bookmark = Bookmark.gen(:tag_list => "tag1, tag2, tag3")
      bookmark.should be_valid
      bookmark.bookmark_tags.should_not be_empty
      bookmark = Bookmark.get(bookmark.id)
      bookmark.tags.should_not be_empty

      bookmark.update_attributes(:tag_list => "tag1, tag2")
      bookmark = Bookmark.get(bookmark.id)
      bookmark.tags.size.should == 2
    end

    it "should remove all tags when empty string as tag_list is given" do
      bookmark = Bookmark.gen(:tag_list => "tag1, tag2, tag3")
      bookmark.should be_valid
      bookmark.bookmark_tags.should_not be_empty
      bookmark = Bookmark.get(bookmark.id)
      bookmark.tags.should_not be_empty

      bookmark.update_attributes(:tag_list => "")
      bookmark = Bookmark.get(bookmark.id)
      bookmark.tags.should be_empty
    end

  end

end
