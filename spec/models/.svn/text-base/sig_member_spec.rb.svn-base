require File.join( File.dirname(__FILE__), '..', "spec_helper" )

describe SigMember do
  before(:all) do
    @topic = Topic.gen
  end

  describe "creation" do
    
    it "should add notification for new topic user" do
      @topic.add_owner(User.gen)
      { :owner => User.gen, :maintainer => User.gen, :consumer => User.gen }.each do |role, user|
        lambda do
          lambda do
            lambda do
              @topic.send(:"add_#{role}", user)
            end.should change(SigMember, :count).by(1)
          end.should change(RoleAssignedNotification, :count).by(1)
        end.should change(Merb::Mailer.deliveries, :count).by(1)
      end
    end

    it "should add notification to new pending owner" do
      @topic.add_owner(User.gen)
      user = User.gen
      lambda do
        lambda do
          @topic.sig_members.create(:user => user, :role => :owner, :accepted => false)
        end.should change(SigMember, :count).by(1)
      end.should change(RoleAssignedNotification, :count).by(1)
    end

    it "shouldn't send email to topic's first owner" do
      owner = User.gen
      lambda do
        lambda do
          topic = Topic.gen
          topic.add_owner(owner)
        end.should change(SigMember, :count).by(1)
      end.should_not change(Merb::Mailer.deliveries, :count)
    end

  end
  
  describe "acceptance" do
    
    it "shouldn't send email" do
      sig_member = @topic.sig_members.create(:user => User.gen, :role => :owner, :accepted => false)
      lambda do
        lambda do
          lambda do
            sig_member.accept!
          end.should change(SigMember.pending, :count).by(-1)
        end.should_not change(SigMember, :count)
      end.should_not change(Merb::Mailer.deliveries, :count)
    end
    
  end

  describe "rejection" do

    it "shouldn't send email" do
      sig_member = @topic.sig_members.create(:user => User.gen, :role => :owner)
      lambda do
        lambda do
          sig_member.reject!
        end.should change(SigMember, :count).by(-1)
      end.should_not change(Merb::Mailer.deliveries, :count)
    end

  end
  
end