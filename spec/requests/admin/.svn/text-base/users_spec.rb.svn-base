require File.join(File.dirname(__FILE__), '..', '..', 'spec_helper.rb')


describe "As admin" do

  describe "profile editing" do

    before(:each) do
      @admin = User.gen(:admin => true)
    end

    it "should show user's profile form for admin" do
      @admin = User.gen(:admin => true)
      user = User.gen
      as(@admin) do
        response = request(resource(:admin, user, :edit))
        response.should be_successful
        response.should have_selector("form input[type='text'][name='user[name]']")
        response.should have_selector("form input[type='text'][name='user[email]']")
      end

    end
    
    it "should show proper message after promoting and demoting from admin role" do
      user = User.gen
      as(@admin) do
        response = request(resource(:admin, user,:promote))
        response.status.should be(302)
        response = request(response.headers['Location'])
        response.should have_selector(".notice:contains('#{user.name}')")
      end
    end

  end

  describe "notifications" do
    
    before(:each) do
      @admin = User.gen(:admin => true)
      @user = User.gen
    end
    
    it "should send password reset link" do
      as(@admin) do
        lambda do
          response = request("/admin/users/#{@user.id}/password_reset_link")
          response.status.should be(302)
        end.should change(Merb::Mailer.deliveries, :length).by(1)
      end
    end
    
  end

end
