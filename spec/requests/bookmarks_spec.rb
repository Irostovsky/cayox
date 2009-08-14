require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

describe "Bookmarks" do
  before(:each) do
    @user = User.gen
  end
  
  it "should create bookmark" do
    [Bookmark.gen( :user => @user ) ,Bookmark.gen( :user => @user )]
    as(@user) do
      response = request("/bookmarks", :method => "post", :params => {:bookmark => { :url => "http://onet.pl", :name => "onet", :description => "test portal" } } )
      response.status.should be(302)
    end
  end

   it "should not create bookmark with invalid link" do
     as(@user) do
       response = request("/bookmarks", :method => "post", :params => {:bookmark => {:url => "invalid-link", :name => "valid-name", :description => "valid description" } } )
       response.should have_selector("span:contains('is not valid')")
       response.status.should be(200)
     end
   end

  it "should show bookmark" do
    bookmark = Bookmark.gen(:user => @user)
    as(@user) do
      response = request("/bookmarks/#{bookmark.id}" )
      response.should be_successful
    end
  end
  
  it "should render edit form" do
    bookmark = Bookmark.gen(:user => @user)
    as(@user) do
      response = request("/bookmarks/#{bookmark.id}/edit" )
      response.should be_successful
    end
  end
  
  it "should update bookmark and redirect when data is valid" do
    bookmark = Bookmark.gen(:user => @user)
    as(@user) do
      response = request("/bookmarks/#{bookmark.id}", :method => "put", :params => { :bookmark => { :name => "new name", :description => "some desc", :tag_list => "tag1" } }, 'HTTP_X_REQUESTED_WITH' => 'XMLHttpRequest')
      response.should be_successful
      response.body.to_s.should == ""
    end
  end

  it "shouldn't update bookmark when data is invalid" do
    bookmark = Bookmark.gen(:user => @user)
    as(@user) do
      response = request("/bookmarks/#{bookmark.id}", :method => "put", :params => { :bookmark => { :name => "", :description => "", :tag_list => "" } }, 'HTTP_X_REQUESTED_WITH' => 'XMLHttpRequest')
      response.should be_successful
      response.body.to_s.should_not == ""
    end
  end

  it "should display bookmakrs" do
    as(@user) do
      response = request("/bookmarks")
      response.should be_successful
    end
  end

  it "should display new bookmark form" do
    as(@user) do
      response = request("/bookmarks/new")
      response.should be_successful
    end
  end

  it "should not display new bookmark form for not logged user " do
    response = request("/bookmarks/new")
    response.status.should be(401)
  end

  it "should add tags to bookmark" do
    bookmark = Bookmark.gen(:user => @user)
    as(@user) do
      response = request("/bookmarks/#{bookmark.id}", :method => "put", :params => {:bookmark => {:name => "onet", :description => "test portal", :tag_list => "lol, zmrol, test" } } )
      response.status.should be(302)
    end
    bookmark.reload
    bookmark.tags.length.should be(3)
  end

  it "should destroy bookmark" do
    bookmark = Bookmark.gen(:user => @user)
    as(@user) do
      response = request("/bookmarks/#{bookmark.id}/delete")
      response.status.should be(302)
    end
  end

  it "should be shown only to owner" do
    bookmark = Bookmark.gen(:user => @user)
    bookmark2 = Bookmark.gen(:user => User.gen)
    as(@user) do
      response = request("/bookmarks/#{bookmark2.id}")
      response.status.should be(403)
    end
  end

  it "should remove tags from bookmark" do
    owner = User.gen
    bookmark1 = Bookmark.gen(:user => owner, :tag_list => "123")
    bookmark2 = Bookmark.gen(:user => owner, :tag_list => "123, 456")

    as(owner) do
      request("/bookmarks/#{bookmark2.id}", :method => 'put', :params => { :bookmark => { :tag_list => "" } })
    end

    bookmark1 = Bookmark.get(bookmark1.id)
    bookmark2 = Bookmark.get(bookmark2.id)

    bookmark1.tag_list.should == ["123"]
    bookmark2.tag_list.should == []
  end
 
end
