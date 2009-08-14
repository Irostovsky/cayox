require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

describe "Roles" do
  
  before(:all) do
    @topic = Topic.gen
    @owner = User.gen
    @owner_membership = @topic.add_owner(@owner)
    @owner_2 = User.gen
    @owner_membership_2 = @topic.add_owner(@owner_2)
    @maintainer = User.gen
    @maintainer_membership = @topic.add_maintainer(@maintainer)
    @consumer = User.gen
    @consumer_membership = @topic.add_consumer(@consumer)
    @private_topic = Topic.gen(:access_level => :private)
    @private_topic.add_owner(@owner)
    @friend = User.gen
    @owner.friendships.create(:friend => @friend, :accepted => true)
    @admin = User.gen(:admin => true)
    @admin_owner = User.gen(:admin => true)
    @admin_owner_membership = @topic.add_owner(@admin_owner)
    @admin_consumer = User.gen(:admin => true)
    @admin_consumer_membership = @topic.add_consumer(@admin_consumer)
  end

  describe "listing" do
  
    it "should show roles for topic including owners (readonly)" do
      @topic.membership_requests.create(:user_id => @friend.id)
      MembershipRequest.daily_notification
      lambda do
        as(@owner) do
          response = request(resource(@topic, :sig_members))
          response.should be_successful
          response.should have_selector("table#role_administration td:contains('#{@owner.name}')")
          response.should_not have_selector("table#role_administration td form[action='#{resource(@topic, @owner_membership)}']")
        end
      end.should change(MembershipRequestsNotification, :count).by(-1)
    end

    it "should show roles for topic including owners (read-write) if admin" do
      [@admin, @admin_owner].each do |user|
        as(user) do
          response = request(resource(@topic, :sig_members))
          response.should be_successful
          response.should have_selector("table#role_administration td form[action='#{resource(@topic, @owner_membership)}']")
          response.should have_selector("table#role_administration td form[action='#{resource(@topic, @admin_owner_membership)}']")
          response.should have_selector("table#role_administration td form[action='#{resource(@topic, @consumer_membership)}']")
        end
      end
    end

    it "should be displayed for owners (with access requests)" do
      (@topic.owners - [@admin_owner]).each do |user|
        as(user) do
          response = request(resource(@topic, :sig_members))
          response.should be_successful
          response.should have_selector("h2:contains('ACCESS REQUESTS')")
        end
      end
    end

    it "should be displayed for admins (without access requests)" do
      [@admin, @admin_consumer].each do |user|
        as(user) do
          response = request(resource(@topic, :sig_members))
          response.should be_successful
          response.should_not have_selector("h2:contains('ACCESS REQUESTS')")
        end
      end
    end

    it "should raise forbidden for maintainers and consumers" do
      [@maintainer, @consumer].each do |user|
        as(user) do
          response = request(resource(@topic, :sig_members))
          response.should be_forbidden
        end
      end
    end

    it "should raise unauthenticated for guest" do
      as(Guest.new) do
        response = request(resource(@topic, :sig_members))
        response.should be_unauthorized
      end
    end

    it "should not include user in friends dropdown if user has role assigned" do
      as(@owner) do
        [@owner, @maintainer, @consumer].each do |user|
          response = request(resource(@topic, :sig_members))
          response.should_not have_selector("form option:contains('#{user.name}')")
        end
        
        response = request(resource(@topic, :sig_members))
        response.should have_selector("form option:contains('#{@friend.name}')")
      end
    end

  end

  describe "change" do

    it "should raise bad request for any owner (except admins)" do
      (@topic.owners - [@admin_owner]).each do |user|
        as(user) do
          response = request(resource(@topic, @owner_membership), :method => "put", :params => { :sig_member => { :role => "consumer" } } )
          response.should be_bad_request
        end
      end
    end

    it "should be successful from owner to maintainer (as admin)" do
      [@admin, @admin_owner].each do |user|
        as(user) do
          response = request(resource(@topic, @owner_membership), :method => "put", :params => { :sig_member => { :role => "maintainer" } } )
          response.should redirect
        end
      end
    end

    it "should be successfull from consumer to maintainer (and send email)" do
      [@owner, @admin, @admin_consumer, @admin_owner].each do |user|
        topic = Topic.gen
        topic.add_owner(@owner)
        [topic.add_consumer(@admin), topic.add_consumer(@admin_consumer), topic.add_consumer(@admin_owner), topic.add_consumer(User.gen)].each do |membership|
          as(user) do
            lambda do
              lambda do
                response = request(resource(topic, membership), :method => "put", :params => { :sig_member => { :role => "maintainer" } } )
                response.should redirect
                response = request(response.headers['Location'])
                response.should have_selector(".notice:contains('changed')")
              end.should change(Merb::Mailer.deliveries, :count).by(1)
            end.should_not change(SigMember.pending, :count)
          end
        end
      end
    end

    it "should be successfull from consumer to owner (and send email + increment pending roles count)" do
      as(@owner) do
        lambda do
          lambda do
            lambda do
              response = request(resource(@topic, @consumer_membership), :method => "put", :params => { :sig_member => { :role => "owner" } } )
              response.should redirect
              response = request(response.headers['Location'])
              response.should have_selector(".notice:contains('changed')")
            end.should change(Merb::Mailer.deliveries, :count).by(1)
          end.should_not change(SigMember, :count)
        end.should change(SigMember.pending, :count).by(1)
      end
    end

    it "should not send email if role didn't change" do
      as(@owner) do
        lambda do
          lambda do
            response = request(resource(@topic, @consumer_membership), :method => "put", :params => { :sig_member => { :role => "consumer" } } )
            response.should redirect
            response = request(response.headers['Location'])
            response.should have_selector(".error:contains('choose')")
          end.should_not change(Merb::Mailer.deliveries, :count)
        end.should_not change(SigMember, :count)
      end
    end

    it "should not be allowed if changed role is only owner" do
      topic = Topic.gen
      membership = topic.add_owner(User.gen)
      as(@admin) do
        response = request(resource(topic, membership), :method => "put", :params => { :sig_member => { :role => "consumer" } } )
        response.should redirect
        response = request(response.headers['Location'])
        response.should have_selector(".error:contains('only owner')")
      end
    end

  end

  describe "removal" do

    it "should raise bad request for any owner (except admins)" do
      (@topic.owners - [@admin_owner]).each do |user|
        as(@owner) do
          membership = @topic.sig_members.first(:user_id => user.id)
          response = request(resource(@topic, membership), :method => 'delete')
          response.should be_bad_request
        end
      end
    end

    it "should be successfull for consumer or maintainer (as owner)" do
      [@consumer_membership, @maintainer_membership].each do |membership|
        as(@owner) do
          lambda do
            response = request(resource(@topic, membership), :method => 'delete')
            response.should redirect
            response = request(response.headers['Location'])
            response.should have_selector(".notice:contains('removed')")
          end.should change(Merb::Mailer.deliveries, :count).by(1)
        end
      end
    end

    it "should be successfull for owner (as admin)" do
      as(@admin) do
        lambda do
          response = request(resource(@topic, @admin_owner_membership), :method => 'delete')
          response.should redirect
        end.should change(@topic.owners, :count).by(-1)
      end
    end

    it "should reassign owner role to admin if none owner is left" do
      topic = Topic.gen
      membership = topic.add_owner(User.gen)
      as(@admin) do
        lambda do
          response = request(resource(topic, membership), :method => 'delete')
          response.should redirect
          response = request(response.headers['Location'])
          response.should have_selector(".notice:contains('reassigned')")
        end.should_not change(topic.owners, :count)
      end
      topic.owners.first.should == @admin
    end

    it "shouldn't remove owner role from admin if none owner is left" do
      topic = Topic.gen
      membership = topic.add_owner(@admin)
      as(@admin) do
        lambda do
          response = request(resource(topic, membership), :method => 'delete')
          response.should redirect
          response = request(response.headers['Location'])
          response.should have_selector(".error:contains('only')")
        end.should_not change(topic.owners, :count)
      end
      topic.owners.first.should == @admin
    end
    
  end

  describe "creation" do

    it "should be successfull for cayox user" do
      [@owner, @admin].each do |user|
        as(user) do
          ["owner", "maintainer", "consumer"].each do |role|
            friend = User.gen
            user.add_friend(friend, true)
            lambda do
              lambda do
                response = request(resource(@topic, :sig_members), :method => 'post', :params => { :sig_member => { :user_id => friend.id, :role => role } })
                response.should redirect
                response = request(response.headers['Location'])
                response.should have_selector(".notice:contains('assigned')")
              end.should change(Merb::Mailer.deliveries, :count).by(1)
            end.should change(SigMember, :count).by(1)
          end
        end
      end
    end

    it "shouldn't be successfull when provided user id is not friend's id" do
      as(@owner) do
        response = request(resource(@topic, :sig_members), :method => 'post', :params => { :sig_member => { :user_id => User.gen.id, :role => "consumer" } })
        response.should be_bad_request
      end
    end

    it "should create pending sig_member for owner role" do
      friend = User.gen
      @owner.add_friend(friend, true)
      as(@owner) do
        lambda do
          lambda do
            response = request(resource(@topic, :sig_members), :method => 'post', :params => { :sig_member => { :user_id => friend.id, :role => "owner" } })
            response.should redirect
          end.should change(SigMember, :count).by(1)
        end.should change(SigMember.pending, :count).by(1)
      end
    end

    it "should create accepted sig_member for maintainer and consumer" do
      as(@owner) do
        ["maintainer", "consumer"].each do |role|
          friend = User.gen
          @owner.add_friend(friend, true)
          lambda do
            lambda do
              response = request(resource(@topic, :sig_members), :method => 'post', :params => { :sig_member => { :user_id => friend.id, :role => role } })
              response.should redirect
            end.should change(SigMember, :count).by(1)
          end.should_not change(SigMember.pending, :count)
        end
      end
    end

    it "should be successfull for external user" do
      as(@owner) do
        lambda do
          lambda do
            lambda do
              response = request(resource(@topic, :sig_members), :method => 'post', :params => { :sig_member => { :email => "some@email.com", :role => "maintainer" } })
              response.should redirect
              response = request(response.headers['Location'])
              response.should have_selector(".notice:contains('assigned')")
            end.should change(Merb::Mailer.deliveries, :count).by(2)
          end.should change(User, :count).by(1)
        end.should change(SigMember, :count).by(1)
      end
    end

    it "should raise bad request for private topic" do
      as(@owner) do
        response = request(resource(@private_topic, :sig_members), :method => 'post', :params => { :sig_member => { :email => "some@email.com", :role => "maintainer" } })
        response.should be_bad_request
      end
    end

    it "should show error message for empty or invalid email" do
      as(@owner) do
        ["", "invalid"].each do |email|
          response = request(resource(@topic, :sig_members), :method => 'post', :params => { :sig_member => { :email => email, :role => "maintainer" } })
          response.should redirect
          response = request(response.headers['Location'])
          response.should have_selector(".error:contains('email')")
        end
      end
    end

    it "should show error message if user has already role assigned" do
      email = "kill@kill.pl"
      user = User.gen(:email => email)
      @topic.add_consumer(user)
      @owner.reload
      as(@owner) do
        response = request(resource(@topic, :sig_members), :method => 'post', :params => { :sig_member => { :email => email, :role => "maintainer" } })
        response.should redirect
        response = request(response.headers['Location'])
        response.should have_selector(".error:contains('already')")
      end
    end

    it "should remove membership requests for user and this topic" do
      user = User.gen
      @owner.add_friend(user, true)
      user.membership_requests.create(:topic_id => @topic.id)
      user.membership_requests.create(:topic_id => Topic.gen.id)
      as(@owner) do
        lambda do
          lambda do
            lambda do
              response = request(resource(@topic, :sig_members), :method => 'post', :params => { :sig_member => { :user_id => user.id, :role => "maintainer" } })
              response.should redirect
              response = request(response.headers['Location'])
              response.should have_selector(".notice:contains('assigned')")
            end.should change(Merb::Mailer.deliveries, :count).by(1)
          end.should change(SigMember, :count).by(1)
        end.should change(MembershipRequest, :count).by(-1)
      end
    end

  end

  describe "accepting / rejecting" do

    it "should be successful for user with pending request (accept)" do
      user = User.gen
      sig_member = @topic.sig_members.create(:user => user, :role => :owner, :accepted => false)
      user.reload
      as(user) do
        response = request(resource(@topic, sig_member, :accept))
        response.should redirect
      end
    end

    it "should be successful for user with pending request (reject)" do
      user = User.gen
      sig_member = @topic.sig_members.create(:user => user, :role => :owner, :accepted => false)
      user.reload
      as(user) do
        response = request(resource(@topic, sig_member, :reject))
        response.should redirect
      end
    end

    it "shouldn't be successful for user without pending request" do
      user = User.gen
      [Topic.gen.sig_members.create(:user => user, :role => :owner, :accepted => false), @topic.sig_members.create(:user => User.gen, :role => :owner, :accepted => false)].each do |sig_member|
        [:accept, :reject].each do |action|
          as(user) do
            response = request(resource(@topic, sig_member, action))
            response.should be_forbidden
          end
        end
      end
    end

  end
  
end