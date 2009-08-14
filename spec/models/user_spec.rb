require File.join( File.dirname(__FILE__), '..', "spec_helper" )

describe User do
  it "should validate user name format" do
    ["stefan)(*&^%$)", "foo bar", "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa", "][;'/.,?><!@#}{}]", "jola@misio"].each do |name|
      user = User.make(:name => name)
      user.save.should(be_false)
      user.errors.on(:name).should_not(be_nil)
    end
  end

  it "shouldn't validate name format and length if invited and not activated" do
    inviter = User.gen
    user = nil
    lambda do
      user = User.invite("some@emailwithverlongdomainpart.com.pl", inviter)
    end.should change(User, :count).by(1)
    user = User.get(user.id)
    user.crypted_password.should == User::EMPTY_PASS
  end

  it "should validate name format and length if invited and already activated" do
    inviter = User.gen
    lambda do
      user = User.invite("some@emailwithverlongdomainpart.com.pl", inviter)
      user.activate!
      user.should_not be_valid
    end.should change(User, :count).by(1)
  end

  it "should activate invitied user" do
    inviter = User.gen
    user = User.invite("some@emailwithverlongdomainpart.com.pl", inviter)
    lambda do
      user.activate!.should be_true
    end.should change(InvitationNotification, :count).by(-1)
  end

  it "should activate new user" do
    user = User.gen(:inactive)
    lambda do
      user.activate!.should be_true
    end.should change(RegistrationNotification, :count).by(-1)
  end

  it "shouldn't be created without name" do
    user = User.gen(:name => nil)
    user.errors.on(:name).should_not be_nil
  end

  it "should be created with valid name" do
    %w(marcin-kulik stefan_ks bob kiszka123 12foo123).each do |name|
      user = User.make(:name => name)
      user.save.should be_true
    end
  end
  
  it "should send welcome email with activation link to new user" do
    user = nil
    lambda { user = User.gen }.should(change(Merb::Mailer.deliveries, :size).by(1))
    email = Merb::Mailer.deliveries.last.text
    email.should include("created")
    email.should include(user.activation_token)
  end

  it "should send email with password reset link to user requesting it" do
    user = User.gen
    lambda { user.generate_password_reset_token }.should(change(Merb::Mailer.deliveries, :size).by(1))
    email = Merb::Mailer.deliveries.last.text
    email.should include("reset password")
    email.should include(user.password_reset_token)
  end

  it "should require password" do
    User.new.password_required?.should be_true
    user = User.get(User.gen.id) #prevent from keeping password_confirmation set
    user.password_required?.should be_false
    user.password = "kiszka"
    user.password_required?.should be_true

    user = User.gen
    user.password_confirmation = "aaaaaa"
    user.password_required?.should be_true
  end

  it "should be editable by himself and admin" do
    user = User.gen
    other_user = User.gen
    admin = User.gen(:admin => true)
    user.editable_by?(user).should be_true
    user.editable_by?(admin).should be_true
    user.editable_by?(other_user).should be_false
  end
  
  it "should be authenticated with name if name provided" do
    name, pass = "stefan13", "kiszka123"
    user = User.gen(:name => name, :password => pass, :password_confirmation => pass)
    User.authenticate(name, pass).should == user #User.get(user.id)
  end

  it "should be authenticated with email if email provided" do
    email, pass = "stefan@haxx.org", "kiszka123"
    user = User.gen(:email => email, :password => pass, :password_confirmation => pass)
    User.authenticate(email, pass).should == user #User.get(user.id)
  end

  it "should return nil for authentication with bad login or password" do
    User.authenticate("bad-login", "bad-password").should be_nil
  end
  
  it "should be admin" do
    User.make(:admin => true).should be_admin
  end

  it "shouldn't be guest" do
    User.make.should_not be_guest
  end

  it "should remove malicious code upon creation" do
    user = User.gen(:full_name => '<script>ha</script>xxxor')
    user.should_not be_new_record
    user.full_name.should include('haxxxor')
    user.full_name.should_not include('<script>')
    user.full_name.should_not include('</script>')

    user = User.gen(:full_name => '<script>alert("o men!")</script>haxxxor')
    user.should be_valid
    user.full_name.should include('haxxxor')
    user.full_name.should include('alert')
    user.full_name.should_not include('<script>')
    user.full_name.should_not include('</script>')
  end

  it "should have correct status" do
    user = User.gen
    user.status.should include("active")
    inactive = User.gen(:inactive)
    inactive.status.should include("inactive")
    user.blocked = true
    user.status.should include("blocked")
  end

  it "should add pending friend" do
    user, friend = User.gen, User.gen
    lambda do
      lambda do
        user.add_friend(friend)
      end.should change(Friendship, :count).by(1)
    end.should_not change(user.friendships, :count)
  end

  it "should add accepted friend" do
    user, friend = User.gen, User.gen
    lambda do
      lambda do
        user.add_friend(friend, true)
      end.should change(Friendship, :count).by(2)
    end.should change(user.friendships, :count).by(1)
  end

  describe "removal" do

    it "should be successful" do
      user = User.gen
      user.remove!.should be_true
    end

    it "should remove all related objects" do
      user = User.gen
      topic = Topic.gen
      topic2 = Topic.gen
      element = Element.gen
      topic_element = topic.topic_elements.create(:element => element)
      topic_element.topic_element_flags.create(:user => user, :flag => Flag.gen(:type => :element))
      topic.add_owner(user)
      Bookmark.gen(:user => user, :tag_list => "foo, bar") # creates 2 x user_tag_stats
      user.messages.create(:body => "aaa", :type => :system)
      user.add_friend(User.gen)
      user.add_friend(User.gen, true)
      user.user_languages.create(:language => Language.gen)
      element.vote(3, user)
      element.element_comments.create(:body => "caligula", :user => user)
      favourite = Favourite.create_from_topic(topic, user)
      favourite.add_custom_element(Element.gen)
      user.membership_requests.create(:topic => topic2)
      topic2.topic_flags.create(:user => user, :flag => Flag.gen)
      topic.vote(4, user)
      topic.topic_comments.create(:body => "caligula", :user => user)
      n = user.notifications.count
      n.should > 0
      user.reload

      lambda do
        lambda do
          lambda do
            lambda do
              lambda do
                lambda do
                  lambda do
                    lambda do
                      lambda do
                        lambda do
                          lambda do
                            lambda do
                              lambda do
                                lambda do
                                  lambda do
                                    lambda do
                                      user.remove!
                                    end.should change(User, :count).by(-1)
                                  end.should change(SigMember, :count).by(-1)
                                end.should change(Bookmark, :count).by(-1)
                              end.should change(Message, :count).by(-1)
                            end.should change(Friendship, :count).by(-3)
                          end.should change(UserLanguage, :count).by(-1)
                        end.should change(ElementVote, :count).by(-1)
                      end.should change(Favourite, :count).by(-1)
                    end.should change(TopicComment, :count).by(-1)
                  end.should change(ElementComment, :count).by(-1)
                end.should change(FavouriteElement, :count).by(-2)
              end.should change(MembershipRequest, :count).by(-1)
            end.should change(TopicVote, :count).by(-1)
          end.should change(Notification, :count).by(-n)
        end.should change(TopicFlag, :count).by(-1)
      end.should change(TopicElementFlag, :count).by(-1)
    end

    it "should successfully reassign ownership to admin for hidden topic" do
      user = User.gen
      admin = User.gen(:admin => true)
      topic = Topic.gen
      topic.add_owner(user)
      topic.hide!
      lambda do
        user.remove!(admin)
      end.should_not change(SigMember, :count)
    end

    it "should reassign topic ownership to admin if topic doesn't have any other owners" do
      admin = User.gen
      user = User.gen
      topic = Topic.gen
      topic.add_owner(user)
      topic.owners.first.should == user
      lambda do
        user.remove!(admin)
      end.should_not change(Topic, :count)
      topic.owners.count.should == 1
      topic.owners.first.should == admin
    end

    it "shouldn't reassign topic ownership to admin if topic has other owners" do
      admin = User.gen
      user = User.gen
      topic = Topic.gen
      topic.add_owner(User.gen)
      topic.add_owner(user)
      topic.owners.should include(user)
      user.remove!(admin)
      topic.owners.count.should == 1
      topic.owners.should_not include(admin)
    end

    it "should remove all his private topics" do
      user = User.gen
      topic = Topic.gen(:access_level => :private)
      topic.add_owner(user)
      lambda do
        user.remove!
      end.should change(Topic, :count).by(-1)
    end

  end

end

describe "User pagination" do
  
  before(:all) do
    User.all.destroy!
    50.times { User.gen }
    @page_count, @users = User.paginated :per_page => 20
  end
  
  it "should paginate users by 20 on page" do
    @page_count.should be(3)
    
    @users.should be_a_kind_of(DataMapper::Collection)
    @users[0].should be_an_instance_of(User)
  end
  
  it "should paginate users by 13 on page" do
    @pc, @usr = User.paginated :per_page => 13
    @pc.should be(4)
  end
  
  it "should not be empty" do
    @users.should_not be_empty
  end
  
  it "should ensure types that pagination returns" do
    @users.should be_a_kind_of(DataMapper::Collection)
    @users[0].should be_an_instance_of(User)
  end
  
end

describe "Guest" do
  
  before(:all) do
    @guest = Guest.new
  end
  
  it "should not be admin" do
    @guest.should_not be_admin
  end
  
  it "should be guest" do
    @guest.should be_kind_of(Guest)
    @guest.should be_guest
  end
  
end
