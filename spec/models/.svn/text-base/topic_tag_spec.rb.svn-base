require File.join( File.dirname(__FILE__), '..', "spec_helper" )

describe TopicTag do
  
  it "should recount tag usage when (de)assigning to non-private topic" do
    tag = Tag.gen
    tag.non_private_topics_count.should == 0

    public_topic = Topic.gen(:access_level => :public, :tag_list => "")
    private_topic = Topic.gen(:access_level => :private, :tag_list => "")
    tag.reload
    tag.non_private_topics_count.should == 0

    public_topic.tag_list = tag.name
    public_topic.save
    private_topic.tag_list = tag.name # this shouldn't be counted
    private_topic.save
    tag.reload
    tag.non_private_topics_count.should == 1

    public_topic.tag_list = ""
    public_topic.save
    tag.reload
    tag.non_private_topics_count.should == 0
  end

end