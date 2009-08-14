require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

describe "Flags" do
  
  before(:all) do
    TopicElement.all.destroy!
    Topic.all.destroy!
    Element.all.destroy!
    TopicFlag.all.destroy!
    TopicElementFlag.all.destroy!
    prepare_public_topic
    @topic_flag = @topic.topic_flags.create(:user => User.gen, :flag => Flag.gen)
    @element_flag = @topic_element.topic_element_flags.create(:user => User.gen, :flag => Flag.gen(:type => :element))
  end

  describe "list" do

    it "should raise Unauthenticated when user is guest" do
      as(Guest.new) do
        response = request(resource(:flags))
        response.status.should == 401
      end
    end

    it "should be successfull for owner, admins and user without topics" do
      { @topic_owner  => resource(:flags), User.gen(:admin => true) => resource(:admin, :flags), User.gen => resource(:flags) }.each do |user, path|
        as(user) do
          response = request(path)
          response.should be_successful
        end
      end
    end

    it "should remove pending FlagsNotifications" do
      Flag.send_notifications!
      as(@topic_owner) do
        lambda do
          response = request(resource(:flags))
        end.should change(FlagsNotification, :count).by(-1)
      end
    end

    it "shouldn't show flagged elements for hidden topics" do
      topic = Topic.gen
      topic.add_owner(@topic_owner)
      @topic_owner.reload
      topic.topic_flags.create(:user => User.gen, :flag => Flag.gen)
      @topic.hide!
      as(@topic_owner) do
        response = request(resource(:flags))
        response.should be_successful
        response.should have_selector("a:contains('#{topic.name["pl"]}')")
        response.should_not have_selector("a:contains('#{@topic_element.name[:pl]}')")
      end
    end

  end

  describe "status updating" do

    it "should raise Unauthenticated when user is guest" do
      as(Guest.new) do
        response = request(resource(:flags, :confirm), :method => 'post', :params => { :type => "topics", :flagging_ids => [1], "reject" => "Go!" })
        response.status.should == 401
      end
    end

    describe "for topic" do

      it "should be successfull and redirect for rejection" do
        as(@topic_owner) do
          response = request(resource(:flags, :confirm), :method => 'post', :params => { :type => "topics", :flagging_ids => [@topic_flag.id], "reject" => "Go!" })
          response.should redirect_to(url(:flags))
          response = request(response.headers['Location'])
          response.should have_selector(".notice:contains('rejected')")
        end
      end

      it "should show error when topics have been blocked" do
        @topic.hide!
        as(@topic_owner) do
          response = request(resource(:flags, :confirm), :method => 'post', :params => { :type => "topics", :flagging_ids => [@topic_flag.id], "reject" => "Go!" })
          response.should redirect_to(url(:flags))
          response = request(response.headers['Location'])
          response.should have_selector(".error:contains('haven')")
        end
      end

      it "should be successfull and redirect for acceptance" do
        as(@topic_owner) do
          response = request(resource(:flags, :confirm), :method => 'post', :params => { :type => "topics", :flagging_ids => [@topic_flag.id], "remove" => "Go!" })
          response.should redirect_to(url(:flags))
          response = request(response.headers['Location'])
          response.should have_selector(".notice:contains('removed')")
        end
      end

      it "should not be on list of flagged elements when bloked" do
        admin = User.gen(:admin => true)
        as(admin) do
          response = request(resource(:flags, :confirm), :method => 'post', :params => { :type => "topics", :flagging_ids => [@topic_flag.id], "remove" => "Go!" })
          @topic.reload
          @topic.topic_flags.count.should be(1)
        end
        
        as(@topic_owner) do
          response = request("/topics/#{@topic.id}")
          response.should be_successful
          response.should_not have_selector("a:contains('Show them')")
        end
        
      end

    end

    describe "for element" do

      it "should be successfull and redirect for rejection" do
        as(@topic_owner) do
          response = request(resource(:flags, :confirm), :method => 'post', :params => { :type => "elements", :flagging_ids => [@element_flag.id], "reject" => "Go!" })
          response.should redirect_to(url(:flags))
          response = request(response.headers['Location'])
          response.should have_selector(".notice:contains('rejected')")
        end
      end

      it "should show error if topic has been removed" do
        @topic.hide!
        as(@topic_owner) do
          response = request(resource(:flags, :confirm), :method => 'post', :params => { :type => "elements", :flagging_ids => [@element_flag.id], "reject" => "Go!" })
          response.should redirect_to(url(:flags))
          response = request(response.headers['Location'])
          response.should have_selector(".error:contains('haven')")
        end
      end

      it "should be successfull and redirect for acceptance" do
        as(@topic_owner) do
          response = request(resource(:flags, :confirm), :method => 'post', :params => { :type => "elements", :flagging_ids => [@element_flag.id], "remove" => "Go!" })
          response.should redirect_to(url(:flags))
          response = request(response.headers['Location'])
          response.should have_selector(".notice:contains('removed')")
        end
      end

      it "should be successfull when accepting and 2 users flagged this element" do
        ef2 =  @topic_element.topic_element_flags.create(:user => User.gen, :flag => Flag.gen(:type => :element))
        as(@topic_owner) do
          response = request(resource(:flags, :confirm), :method => 'post', :params => { :type => "elements", :flagging_ids => [ef2.id], "remove" => "Go!" })
          response.should redirect_to(url(:flags))
          response = request(response.headers['Location'])
          response.should have_selector(".notice:contains('removed')")
        end
      end
    end
  end

  describe "adding" do

    before(:all) do
      prepare_closed_topic
    end

    describe "for topic" do

      it "should show form" do
        as(User.gen) do
          response = request(resource(@topic, :flags, :new))
          response.should be_successful
        end
      end

      it "should show success message" do
        as(User.gen) do
          response = request(resource(@topic, :flags), :method => 'post', :params => { :flag_id => Flag.gen.id })
          response.should be_successful
          response.should have_selector("p:contains('waiting')")
        end
      end

      it "should show success message for guest" do
        as(Guest.new) do
          response = request(resource(@topic, :flags), :method => 'post', :params => { :flag_id => Flag.gen.id })
          response.should be_successful
          response.should have_selector("p:contains('waiting')")
        end
      end

      it "should raise forbidden for user who don't have access to topic" do
        [Guest.new, User.gen].each do |user|
          as(user) do
            response = request(resource(@closed_topic, :flags), :method => 'post', :params => { :flag_id => Flag.gen.id })
            response.should be_forbidden
          end
        end
      end

    end

    describe "for topic's element" do

      it "should show form" do
        as(User.gen) do
          response = request(resource(@topic, @element, :flags, :new))
          response.should be_successful
        end
      end

      it "should show success message" do
        as(User.gen) do
          response = request(resource(@topic, @element, :flags), :method => 'post', :params => { :flag_id => Flag.gen(:type => :element).id })
          response.should be_successful
          response.should have_selector("p:contains('waiting')")
        end
      end

      it "should show success message for guest" do
        as(Guest.new) do
          response = request(resource(@topic, @element, :flags), :method => 'post', :params => { :flag_id => Flag.gen(:type => :element).id })
          response.should be_successful
          response.should have_selector("p:contains('waiting')")
        end
      end

      it "should raise forbidden for user who don't have access to element" do
        [Guest.new, User.gen].each do |user|
          as(user) do
            response = request(resource(@closed_topic, @closed_element, :flags), :method => 'post', :params => { :flag_id => Flag.gen(:type => :element).id })
            response.should be_forbidden
          end
        end
      end

    end
  end
end