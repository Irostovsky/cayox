require File.join( File.dirname(__FILE__), '..', "spec_helper" )

describe FavouriteTag do
  
  it "should update tag stats upon creation/removal" do
    user = User.gen
    favourite = nil

    lambda do
      favourite = Favourite.create_from_topic(Topic.gen(:tag_list => "tag1, tag2"), user)
    end.should change(UserTagStat, :count).by(2)

    user.user_tag_stats.first(:tag_id => Tag["tag1"].id).usage_in_favourites.should == 1
    user.user_tag_stats.first(:tag_id => Tag["tag2"].id).usage_in_favourites.should == 1

    lambda do
      Favourite.create_from_topic(Topic.gen(:tag_list => "tag1, tag2, tag3"), user)
    end.should change(UserTagStat, :count).by(1)

    user.user_tag_stats.first(:tag_id => Tag["tag1"].id).usage_in_favourites.should == 2
    user.user_tag_stats.first(:tag_id => Tag["tag2"].id).usage_in_favourites.should == 2
    user.user_tag_stats.first(:tag_id => Tag["tag3"].id).usage_in_favourites.should == 1

    favourite.tag_list = "tag2"
    favourite.save

    user.user_tag_stats.first(:tag_id => Tag["tag1"].id).usage_in_favourites.should == 1
    user.user_tag_stats.first(:tag_id => Tag["tag2"].id).usage_in_favourites.should == 2
    user.user_tag_stats.first(:tag_id => Tag["tag3"].id).usage_in_favourites.should == 1
  end
end