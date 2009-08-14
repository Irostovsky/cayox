require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

describe "Account creation" do

  it "shows a form" do
    response = request("/users/new")
    response.should be_successful
    response.should have_selector("form[action='/users'][method='post']")
    response.should have_selector("input[type='submit'][value='Create']")
  end

  it "creates an account and redirects to home for valid data" do
    response = request("/users", :method => "post", :params => { :user => { :name => "jola", :full_name => "Jola Rutowicz",
                                                                           :email => "jola@rutowicz.com",
                                                                           :password => "kobietakon",
                                                                           :password_confirmation => "kobietakon" }, :token => "" })
    response.should redirect_to(url(:complete_registration_users))
  end

  it "shows register form again for invalid data" do
    response = request("/users", :method => "post", :params => { :user => { :name => "", :full_name => "Jola Rutowicz",
                                                                           :email => "jola@rutowicz.com",
                                                                           :password => "kobietakon",
                                                                           :password_confirmation => "kobietakot" } })
    response.should be_successful
    response.should have_selector("form span:contains('not be blank')")
  end

  it "shows register form again when passwords don't match" do
    response = request("/users", :method => "post", :params => { :user => { :name => "jola", :full_name => "Jola Rutowicz",
                                                                           :email => "jola@rutowicz.com",
                                                                           :password => "KobietakoN",
                                                                           :password_confirmation => "KobietakoT" } })
    response.should be_successful
    response.should have_selector("form span:contains('not match')")
  end
end

describe "Account activation" do

  it "succeeds and user is logged in if activation token is valid" do
    user = User.gen
    token = user.activation_token
    response = request("/users/activate?token=#{token}")
    response.should redirect_to("/")

    response = request("/")
    response.should be_successful
    response.should have_selector("#user_menu:contains('#{user.name}')")
    response.should have_selector("#user_menu a[href='/logout']")
  end

  it "succeeds and user is redirected to profile editing if he was invited" do
    user = User.invite("damn@bones.com", User.gen)
    token = user.activation_token
    response = request("/users/activate?token=#{token}")
    response.should redirect_to(resource(user, :edit))
    response = request(response.headers['Location'])
    response.should have_selector(".notice:contains(' set ')")
  end

  it "fails if activation token is invalid" do
    user = User.gen
    response = request("/users/activate?token=1NVAL1D")
    response.should redirect

    response = request(response.headers["Location"])
    response.should have_selector("div#flash:contains('Invalid')")
  end

  it "fails if activation token has been already used" do
    user = User.gen
    token = user.activation_token
    response = request("/users/activate?token=#{token}")
    response.should redirect_to("/")

    response = request("/users/activate?token=#{token}")
    response.should redirect
    response = request(response.headers["Location"])
    response.should have_selector("div#flash:contains('Invalid')")
  end
  
  it "should show reset link" do
    user = User.gen(:inactive)
    response = request("/users/resend_activation/#{user.id}")
    response.status.should be(200)
  end
  
end

describe "Password reset" do

  it "shows reset link on login form" do
    response = request("/login", 'HTTP_X_REQUESTED_WITH' => 'XMLHttpRequest')
    response.should have_selector("a[href='/users/request_password']:contains('Forgot')")
  end

  it "shows form with field for screenname and email" do
    response = request("/users/request_password")
    response.should have_selector("form input[type='text'][name='email']")
    response.should have_selector("input[type='submit'][value='Send']")
  end

  it "sends password reset link and redirects to pass reset details for matching screenname and email" do
    user = User.gen
    response = request("/users/request_password", :method => "post", :params => { :screenname => user.name, :email => user.email })
    response.body.to_s.should == resource(:users, :password_reset_details)
  end

  it "shows message for invalid email" do
    response = request("/users/request_password", :method => "post", :params => { :email => "wrong@email.gg" })
    response.should be_successful
    response.should have_selector("div.error")
  end

  it "shows profile editing form for valid pass-reset token if link is valid and not expired" do
    user = User.gen
    user.generate_password_reset_token
    lambda do
      DateTime.is(DateTime.now + 0.5) do
        response = request("/users/reset_password?token=#{user.password_reset_token}")
        response.should redirect_to(resource(user, :profile))
      end
    end.should change(PasswordResetNotification, :count).by(-1)
  end

  it "shows homepage with message if link is valid but expired" do
    user = User.gen
    user.generate_password_reset_token
    DateTime.is(DateTime.now + 2) do
      response = request("/users/reset_password?token=#{user.password_reset_token}")
      response.should redirect_to(url(:home))
      url = response.headers["Location"]
      response = request(url)
      response.should have_selector("div#flash:contains('expired')")
    end
  end

  it "shows homepage with message if link is invalid" do
    response = request("/users/reset_password?token=INVALID")
    response.should redirect_to(url(:home))
    url = response.headers["Location"]
    response = request(url)
    response.should have_selector("div#flash:contains('Invalid')")
  end

  it "shows homepage with message if link has been already used" do
    user = User.gen
    user.generate_password_reset_token
    response = request("/users/reset_password?token=#{user.password_reset_token}")
    response.should redirect_to(resource(user, :profile))

    response = request("/users/reset_password?token=#{user.password_reset_token}")
    response.should redirect_to(url(:home))
    url = response.headers["Location"]
    response = request(url)
    response.should have_selector("div#flash:contains('Invalid')")
  end

  it "show message for blocked account" do
    user = User.gen(:blocked => true)
    response = request("/users/request_password", :method => "post", :params => { :screenname => user.name, :email => user.email })
    response.should be_successful
    response.should have_selector("div.error:contains('blocked')")
  end

  it "show message for inactive account" do
    user = User.gen(:inactive)
    response = request("/users/request_password", :method => "post", :params => { :screenname => user.name, :email => user.email })
    response.should be_successful
    response.should have_selector("div.error:contains('activate')")
  end
end

describe "User list, Admin functionality" do

  it "should show not found for guest" do
    response = request("/users")
    response.status.should == 404
  end

  it "should show not found for non admin" do
    as(User.gen) do
      response = request("/users")
      response.status.should be(404)
    end
  end


  it "should show user list for admin" do
    as(User.gen(:admin => true)) do
      response = request("/admin/users")
      response.should be_successful
    end
  end

  
  it "should block and unblock user" do
    test_user = User.gen
    test_user.blocked.should be(false)
    
    as(User.gen(:admin => true)) do
      response = request("/admin/users/#{test_user.id}/block")
      response.should redirect_to("/admin/users")
      User.get(test_user.id).blocked.should be(true)
      response = request("/admin/users/#{test_user.id}/unblock")
      response.should redirect_to("/admin/users")
      User.get(test_user.id).blocked.should be(false)
    end
    
  end
  
  it "should not be blockable by normal user" do
    test_user = User.gen
    test_user.blocked.should be(false)
    
    user = User.gen(:admin => false)
    
    as(user) do
      response = request("/admin/users/#{test_user.id}/block")
      response.status.should be(403)
    end
    
  end

  it "should be to resend invitation mail" do
    admin = User.gen(:admin => true)
    test_user = User.gen
    
    as(admin) do
      response = request("/admin/users/#{test_user.id}/resend_activation_mail")
      response.status.should be(302)
    end
  end

  it "should not be able to block admin" do
    admin = User.gen(:admin => true)
    
    as(admin) do
      response = request("/admin/users/#{admin.id}/block")
      response.status.should be(302)
    end
    admin.reload
    admin.should be_admin
    
  end


  it "should display filtered users list" do
    admin = User.gen(:admin => true)
    users = [User.gen(:inactive), User.gen(:blocked => true), User.gen, User.gen, User.gen(:blocked => true)]
    
    as(admin) do
      response = request("/admin/users", :params => { :blocked => "1", :active => "0", :inactive => "0" })
      response.status.should be(200)
      response.should have_selector("td:contains('blocked')")
      response.should_not have_selector("td:contains('active')")
    end
    
    as(admin) do
      response = request("/admin/users", :params => { :active => "1", :blocked => "0", :inactive => "0" })
      response.status.should be(200)
      response.should_not have_selector("td:contains('blocked')")
      response.should have_selector("td:contains('active')")
    end
    
    as(admin) do
      response = request("/admin/users", :params => { :blocked => "1", :inactive => "1", :active => "1" })
      response.status.should be(200)
      response.should have_selector("td:contains('blocked')")
      response.should have_selector("td:contains('active')")
      response.should have_selector("td:contains('inactive')")
    end
    
    as(admin) do
      response = request("/admin/users", :params => { :blocked => "1", :inactive => "1", :active => "0" })
      response.status.should be(200)
      response.should have_selector("td:contains('blocked')")
      response.should have_selector("td:contains('inactive')")
    end
    
  end
  
  
  it "should be able to find user by name or email" do
    admin = User.gen(:admin => true)
    users = [User.gen, User.gen(:blocked => true), User.gen(:inactive) ]
    
    as(admin) do
       response = request("/admin/users", :params => { :query => users[0].name } )
       response.status.should be(200)   
       response.should have_selector("td:contains('active')")
       response = request("/admin/users", :params => { :query => users[1].name[0..3] } )
       response.status.should be(200)   
       response.should have_selector("td:contains('blocked')")
       response = request("/admin/users", :params => { :query => users[2].name } )
       response.status.should be(200)   
       response.should have_selector("td:contains('inactive')")
    end
    
    
    as(admin) do
      response = request("/admin/users", :params => { :query => users[0].email } )
      response.status.should be(200)   
      response.should have_selector("td:contains('active')")
    end
    
  end
  
  it "should be able to promote user to admin" do
    admin = User.gen(:admin => true)
    user = User.gen
    as(admin) do
      response = request("/admin/users/#{user.id}/promote")
      response.status.should be(302)
      user.reload
      user.should be_admin
    end
    
    as(User.gen) do
      response = request("/admin/users/#{user.id}/promote")
      response.status.should be(403)
    end
    
  end
  
  it "should be able to demote admin to user" do
    admin = User.gen(:admin => true)
    admin2 = User.gen(:admin => true)
    as(admin) do
      response = request("/admin/users/#{admin2.id}/demote")
      response.status.should be(302)
      admin2.reload
      admin2.should_not be_admin
    end
  end

  it "should not be able to demote self" do
    admin = User.gen(:admin => true)
    as(admin) do
      response = request("/admin/users/#{admin.id}/demote")
      response.status.should be(302)
      admin.reload
      admin.should be_admin
    end
  end
  
  it "should warn if can't promote user to admin" do
    admin = User.gen(:admin => true)
    not_valid_user = User.gen(:email => "lol@lol.pl")
    not_valid_user.email = ""
    not_valid_user.save! #not valid
    as(admin) do
      response = request("/admin/users/#{not_valid_user.id}/promote")
      response.status.should be(302)
      not_valid_user.reload
      not_valid_user.should_not be_admin
    end
  end

  it "should be able to block user" do
    user = User.gen
    admin = User.gen(:admin => true)
    as(admin) do
      response = request("/admin/users/#{user.id}/block")
      response.status.should be(302)
      user.reload
      user.should be_blocked
    end
  end
  
  it "should not be able to block self" do
    admin = User.gen(:admin => true)
    as(admin) do
      response = request("/admin/users/#{admin.id}/block")
      response.status.should be(302)
      admin.reload
      admin.should be_admin
    end 
  end


end

describe "Profile editing" do

  it "should show user's profile form for profile owner and admin" do
    user = User.gen
      as(user) do
        response = request("/users/#{user.id}/edit")
        response.should be_successful
        response.should have_selector("form input[type='text'][name='user[name]']")
        response.should have_selector("form input[type='text'][name='user[email]']")
        response.should have_selector("form input[type='password'][name='user[password]']")
        response.should have_selector("form input[type='password'][name='user[password_confirmation]']")
    end
  
  end

  it "shouldn't show user's profile form for other user" do
    user = User.gen
    other_user = User.gen
    as(other_user) do
      response = request("/users/#{user.id}/edit")
      response.status.should be(403)
    end
  end

  it "should update user's profile for profile owner" do
    user = User.gen
    Topic.gen.add_owner(user)
    as(user) do
      lambda do
        response = request("/users/#{user.id}", :method => "put", :params => { :user => { :full_name => "Changed!",
                                                                                          :name => "changed" } })
        response.should redirect_to("/")
      end.should_not change(Merb::Mailer.deliveries, :count) # check for email hooks on sig_members and user
    end
  end

  it "should show profile form when passwords don't match" do
    user = User.gen
    as(user) do
      response = request("/users/#{user.id}", :method => "put", :params => { :user => { :password => "changed",
                                                                                        :password_confirmation => "Changed!" } })
      response.should be_successful
    end
  end

  it "shouldn't allow to update user's profile for other user" do
    user = User.gen
    other_user = User.gen
    as(other_user) do
      response = request("/users/#{user.id}", :method => "put", :params => { :user => { :full_name => "Haxxed!" } })
      response.status.should be(403)
    end
  end

  it "should update user's search_results_per_page setting" do
    user = User.gen
    user.search_results_per_page.should == Cayox::CONFIG[:search_results_per_page]
    as(user) do
      response = request("/users/#{user.id}", :method => "put", :params => { :user => { :search_results_per_page => "50" } })
      response.should redirect
      user.reload.search_results_per_page.should == 50
    end
  end
end
