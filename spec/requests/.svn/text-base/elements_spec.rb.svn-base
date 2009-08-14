require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

describe "Element" do

  before(:all) { prepare_favourite(prepare_public_topic); prepare_closed_topic; prepare_private_topic }

  describe "adding form" do

    describe "for topic's element" do

      it "should be shown for owner or maintainer" do
        [@topic_owner, @topic_maintainer].each do |user|
          as(user) do
            response = request("/topics/#{@topic.id}/elements/new")
            response.should be_successful
          end
        end
      end

      it "should show 403 when user is not owner or maintainer" do
        [Guest.new, User.gen].each do |user|
          as(user) do
            response = request("/topics/#{@topic.id}/elements/new")
            response.status.should == 403
          end
        end
      end

    end

    describe "for favourite's element" do

      it "should be shown for owner or maintainer" do
        as(@favourite_owner) do
          response = request("/favourites/#{@favourite.id}/elements/new")
          response.should be_successful
        end
      end

      it "should show 403 when user is not owner or maintainer" do
        [Guest.new, User.gen].each do |user|
          as(user) do
            response = request("/favourites/#{@favourite.id}/elements/new")
            response.status.should == 403
          end
        end
      end

    end

  end

  describe "creation" do

    describe "for topic's element" do

      it "should be successful for valid data" do
        as(@topic_owner) do
          lambda do
            lambda do
              lambda do
                lambda do
                  response = request("/topics/#{@topic.id}/elements", :method => "post",
                                     :params => { :element =>  { :url => "https://lol.pl/?p=3", :name => "Misio" } })
                  response.body.to_s.should =~ /#{Regexp.escape(resource(@topic))}\/elements\/\d+/
                end.should change(Element, :count).by(1)
              end.should change(TopicElement, :count).by(1)
            end.should change(Link, :count).by(1)
          end.should change(LinkLanguage, :count).by(1)
        end

      end

      it "shouldn't be successful for invalid data" do
        as(@topic_maintainer) do
          [{ :url => "http://jo.com", :name => "" }, { :url => "//lol.pl/?p=3", :name => "Misio" }, { :url => "", :name => "" }].each do |element_hash|
            lambda do
              lambda do
                lambda do
                  response = request("/topics/#{@topic.id}/elements", :method => "post", :params => { :element => element_hash })
                  response.should be_successful
                end.should_not change(Element, :count)
              end.should_not change(TopicElement, :count)
            end.should_not change(Link, :count)
          end
        end

        as(@topic_owner) do
          lambda do
            lambda do
              lambda do
                response = request("/topics/#{@topic.id}/elements", :method => "post",
                                   :params => { :element => { :url => "asdf", :name => "something", :description => "" } })
                response.should be_successful
              end.should_not change(Element, :count)
            end.should_not change(TopicElement, :count)
          end.should_not change(Link, :count)
        end
      end

      it "should show 403 error when user is not owner or maintainer" do
        [Guest.new, User.gen].each do |user|
          as(user) do
            response = request("/topics/#{@topic.id}/elements", :method => "post",
                               :params => { :element => { :url => "http://jo.com", :name => "Yo!" } })
            response.status.should == 403
          end
        end
      end

    end

    describe "for favourite's element" do

      it "should be successful for valid data" do
        as(@favourite_owner) do
          lambda do
            lambda do
              lambda do
                lambda do
                  lambda do
                    response = request(resource(@favourite, :elements), :method => "post",
                                       :params => { :element =>  { :url => "https://lol.pl/?p=3", :name => "Misio", :tag_list => "foo, bar" }, :language => "jp" })
                    response.body.to_s.should =~ /#{Regexp.escape(resource(@favourite))}\/elements\/\d+/
                    response = request(resource(@favourite))
                    response.should be_successful
                  end.should change(Element, :count).by(1)
                end.should change(ElementTag, :count).by(2)
              end.should change(FavouriteElement.custom, :count).by(1)
            end.should change(Link, :count).by(1)
          end.should change(LinkLanguage, :count).by(1)
        end

      end

      it "shouldn't be successful for invalid data" do
        as(@favourite_owner) do
          lambda do
            lambda do
              lambda do
                response = request(resource(@favourite, :elements), :method => "post",
                                   :params => { :element => { :url => "asdf", :name => "", :description => "" } })
                response.should be_successful
              end.should_not change(Element, :count)
            end.should_not change(FavouriteElement, :count)
          end.should_not change(Link, :count)
        end
      end

      it "should show 403 error when user is not owner or maintainer" do
        [Guest.new, User.gen].each do |user|
          as(user) do
            response = request(resource(@favourite, :elements), :method => "post",
                               :params => { :element => { :url => "http://jo.com", :name => "Yo!" } })
            response.status.should == 403
          end
        end
      end

    end

  end

  describe "editing form" do

    describe "for topic's element" do

      it "should be shown for owner or maintainer" do
        [@topic_owner, @topic_maintainer].each do |user|
          as(user) do
            response = request(resource(@topic, @element, :edit))
            response.should be_successful
          end
        end
      end

      it "should show 403 when user is not owner or maintainer" do
        [Guest.new, User.gen].each do |user|
          as(user) do
            response = request(resource(@topic, @element, :edit))
            response.status.should == 403
          end
        end
      end

    end

    describe "for favourite's element" do

      it "should be shown for owner for custom element" do
        as(@favourite_owner) do
          response = request(resource(@favourite, @favourite_custom_element, :edit))
          response.should be_successful
        end
      end

      it "should show 403 when user is not owner or element was imported from topic" do
        [Guest.new, User.gen, @favourite_owner].each do |user|
          as(user) do
            response = request(resource(@favourite, @favourite_imported_element, :edit))
            response.status.should == 403
          end
        end
      end

    end

  end

  describe "updating" do

    describe "for topic's element" do

      it "should be successful when valid data is sent" do
        as(@topic_owner) do
          response = request(resource(@topic, @element), :method => 'put', :params => { :lang => "pl", :element => { :name => 'new name' } })
          response.body.to_s.should =~ /#{Regexp.escape(resource(@topic, @element))}/
          Element.get(@element.id).name["pl"].should == 'new name'
        end
      end

      it "should show edit form when invalid data is sent" do
        as(@topic_maintainer) do
          response = request(resource(@topic, @element), :method => 'put', :params => { :element => { :name => '' } })
          response.should be_successful
        end
      end

      it "should show 403 error when user is not owner or maintainer" do
        [Guest.new, User.gen].each do |user|
          as(user) do
            response = request(resource(@topic, @element), :method => 'put', :params => { :element => { :name => 'new name' } })
            response.status.should == 403
          end
        end
      end

    end

    describe "for favourite's element" do

      it "should be successful when valid data is sent" do
        as(@favourite_owner) do
          response = request(resource(@favourite, @favourite_custom_element), :method => 'put', :params => { :lang => "pl", :element => { :name => 'new name' } })
          response.body.to_s.should =~ /#{Regexp.escape(resource(@favourite, @favourite_custom_element))}/
          Element.get(@favourite_custom_element.id).name["pl"].should == 'new name'
        end
      end

      it "should show edit form when invalid data is sent" do
        as(@favourite_owner) do
          response = request(resource(@favourite, @favourite_custom_element), :method => 'put', :params => { :element => { :name => '' } })
          response.should be_successful
        end
      end

      it "should show 403 error when user is not owner or element was imported" do
        [Guest.new, User.gen, @favourite_owner].each do |user|
          as(user) do
            response = request(resource(@favourite, @favourite_imported_element), :method => 'put', :params => { :element => { :name => 'new name' } })
            response.status.should == 403
          end
        end
      end

    end

  end

  describe "removing" do

    describe "for topic's element" do

      it "should be successful when user is owner or maintainer" do
        [@topic_owner, @topic_maintainer].each do |user|
          # generate new element for each user
          @element = Element.gen(:name => { :pl => 'cool name' })
          @topic.topic_elements.create(:element => @element)
          as(user) do
            lambda do
              lambda do
                lambda do
                  response = request(resource(@topic, @element), :method => 'delete')
                  response.should redirect_to(resource(@topic))
                end.should change(Element, :count).by(-1)
              end.should change(TopicElement, :count).by(-1)
            end.should_not change(Link, :count)
          end
        end
      end

      it "should show 404 error if element doesn't exist" do
        as(@topic_owner) do
          response = request("/topics/#{@topic.id}/elements/1234567", :method => 'delete')
          response.status.should == 404
        end
      end

      it "should show 403 error when user is not owner or maintainer" do
        [Guest.new, User.gen].each do |user|
          as(user) do
            lambda do
              lambda do
                lambda do
                  response = request(resource(@topic, @element), :method => 'delete')
                  response.status.should == 403
                end.should_not change(Element, :count)
              end.should_not change(TopicElement, :count)
            end.should_not change(Link, :count)
          end
        end
      end

    end

    describe "for favourite's element" do

      it "should be successful for custom element when user is owner" do
        as(@favourite_owner) do
          lambda do
            lambda do
              lambda do
                response = request(resource(@favourite, @favourite_custom_element), :method => 'delete')
                response.should redirect_to(resource(@favourite))
              end.should change(Element, :count).by(-1)
            end.should change(FavouriteElement, :count).by(-1)
          end.should_not change(Link, :count)
        end
      end

      it "should be successful for imported element when user is owner" do
        as(@favourite_owner) do
          lambda do
            lambda do
              lambda do
                response = request(resource(@favourite, @favourite_imported_element), :method => 'delete')
                response.should redirect_to(resource(@favourite))
              end.should_not change(Element, :count)
            end.should change(FavouriteElement, :count).by(-1)
          end.should change(FavouriteElement.removed, :count).by(1)
        end
      end

      it "should show 404 error if element doesn't exist" do
        as(@favourite_owner) do
          response = request("/favourites/#{@favourite.id}/elements/1234567", :method => 'delete')
          response.status.should == 404
        end
      end

      it "should show 403 error when user is not owner" do
        [Guest.new, User.gen].each do |user|
          as(user) do
            lambda do
              lambda do
                lambda do
                  response = request(resource(@favourite, @favourite_imported_element), :method => 'delete')
                  response.status.should == 403
                end.should_not change(Element, :count)
              end.should_not change(TopicElement, :count)
            end.should_not change(Link, :count)
          end
        end
      end

    end

  end

  describe "tagging" do

    it "should add specified tags to element" do
      as(@topic_owner) do
        request("/topics/#{@topic.id}/elements/#{@element.id}", :method => 'put', :params => { :element => { :name => 'new name', :tag_list => "foo,bar" } })
        response = request("/topics/#{@topic.id}/elements/#{@element.id}/edit")
        response.should have_selector("input[type='text'][value*='foo']")
        response.should have_selector("input[type='text'][value*='bar']")
      end
    end

  end

  describe "viewing" do

    describe "for topic's element" do

      it "should be successfull for every user for public topic" do
        [@topic_owner, @topic_maintainer, Guest.new, User.gen].each do |user|
          as(user) do
            response = request(resource(@topic, @element))
            response.should be_successful
          end
        end
      end

      it "should be successfull for admin for any topic" do
        as(User.gen(:admin => true)) do
          { @topic => @topic_element.element, @closed_topic => @closed_element, @private_topic => @private_element }.each do |topic, element|
            response = request(resource(topic, element))
            response.should be_successful
          end
        end
      end

      it "should not be successfull for user who don't have access to topic" do
        as(User.gen) do
          response = request(resource(@closed_topic, @closed_element))
          response.status.should == 403
        end
      end

      it "should show Flag link for every user" do
        [User.gen, Guest.new].each do |user|
          as(user) do
            response = request(resource(@topic, @element))
            response.should be_successful
            response.should have_selector("a.flag_element_link")
          end
        end
      end

      it "should show 'Link' link for every user" do
        [User.gen, Guest.new, @topic_owner].each do |user|
          as(user) do
            response = request(resource(@topic, @element))
            response.should be_successful
            response.should have_selector("a#permalink_link")
          end
        end
      end

    end

    describe "for favourite's element" do

      it "should be successfull for favourite owner" do
        as(@favourite_owner) do
          [@favourite_imported_element, @favourite_custom_element].each do |element|
            response = request(resource(@favourite, element))
            response.should be_successful
          end
        end
      end

      it "should show Propose link for custom element" do
        as(@favourite_owner) do
          response = request(resource(@favourite, @favourite_custom_element))
          response.should be_successful
          response.should have_selector(".action_links a:contains('Propose for topic')")
        end
      end

      it "shouldn't show Propose link for imported or already proposed custom element" do
        @favourite.favourite_elements.first(:element_id => @favourite_custom_element.id).propose!
        as(@favourite_owner) do
          [@favourite_imported_element, @favourite_custom_element].each do |element|
            response = request(resource(@favourite, element))
            response.should be_successful
            response.should_not have_selector(".action_links a:contains('Propose for topic')")
          end
        end
      end

      it "shouldn't show Propose link if favourite's topic has been hidden" do
        @favourite.topic.hide!
        as(@favourite_owner) do
          response = request(resource(@favourite, @favourite_custom_element))
          response.should be_successful
          response.should_not have_selector(".action_links a:contains('Propose for topic')")
        end
      end

      it "should not be successfull for user who don't have access to favourite" do
        as(User.gen) do
          [@favourite_imported_element, @favourite_custom_element].each do |element|
            response = request(resource(@favourite, element))
            response.status.should == 403
          end
        end
      end

      it "should not be successfull if element is marked as removed" do
        @favourite.favourite_elements.first(:element_id => @favourite_imported_element.id).remove!
        as(@favourite_owner) do
          response = request(resource(@favourite, @favourite_imported_element))
          response.status.should == 404
        end
      end

    end
  end

  describe "visits" do

    it "should be incremented for public element for guests and users not involved in this element's topic" do
      [Guest.new, User.gen, @closed_topic_owner, @closed_topic_consumer, @closed_topic_maintainer].each do |user|
        as(user) do
          lambda do
            response = request("/topics/#{@topic.id}/elements/#{@element.id}")
            response.should be_successful
            @element.reload
          end.should change(@element, :views).by(1)
        end
      end
    end

    it "should be incremented for closed element for consumers" do
      as(@closed_topic_consumer) do
        lambda do
          response = request("/topics/#{@closed_topic.id}/elements/#{@closed_element.id}")
          response.should be_successful
          @closed_element.reload
        end.should change(@closed_element, :views).by(1)
      end
    end

    it "should not be incremented for public element for owners and maintainers" do
      [@topic_owner, @topic_maintainer].each do |user|
        as(user) do
          lambda do
            response = request("/topics/#{@topic.id}/elements/#{@element.id}")
            response.should be_successful
            @element = Element.get(@element.id)
          end.should_not change(@element, :views)
        end
      end
    end

    it "should not be incremented for closed element for owners and maintainers" do
      [@closed_topic_owner, @closed_topic_maintainer].each do |user|
        as(user) do
          lambda do
            response = request("/topics/#{@closed_topic.id}/elements/#{@closed_element.id}")
            response.should be_successful
            @closed_element = Element.get(@closed_element.id)
          end.should_not change(@closed_element, :views)
        end
      end
    end

  end

  describe "proposing" do

    it "should add proposition for new custom element" do
      as(@favourite_owner) do
        response = request(resource(@favourite, @favourite_custom_element, :propose))
        response.should redirect
        response = request(response.headers['Location'])
        response.should have_selector(".notice:contains('has been proposed')")
      end
    end

    it "should show warning for already proposed element" do
      @favourite.favourite_elements.first(:element_id => @favourite_custom_element.id).propose!
      as(@favourite_owner) do
        response = request(resource(@favourite, @favourite_custom_element, :propose))
        response.should redirect
        response = request(response.headers['Location'])
        response.should have_selector(".error:contains('has already been proposed')")
      end
    end

    it "should show warning if topic has been hidden" do
      @topic.hide!
      as(@favourite_owner) do
        response = request(resource(@favourite, @favourite_custom_element, :propose))
        response.should redirect
        response = request(response.headers['Location'])
        response.should have_selector(".error:contains('removed')")
      end
    end

    it "should raise NotFound for nonexistent element" do
      as(@favourite_owner) do
        response = request("/favourites/#{@favourite.id}/elements/12334567/propose")
        response.status.should == 404
      end
    end

    it "should raise Forbidden when user doesn't have access to favourite" do
      as(User.gen) do
        response = request(resource(@favourite, @favourite_custom_element, :propose))
        response.status.should == 403
      end
    end

  end

  describe "permalink" do

    it "should be shown without form for guest" do
      as(Guest.new) do
        response = request(resource(@topic, @element, :permalink))
        response.should be_successful
        response.should have_selector("input#permalink")
        response.should_not have_selector("form")
      end
    end

    it "should be shown with form for cayox user" do
      as(User.gen) do
        response = request(resource(@topic, @element, :permalink))
        response.should be_successful
        response.should have_selector("input#permalink")
        response.should have_selector("form")
      end
    end

    it "should be shown without form for private topic owner" do
      as(@private_topic_owner) do
        response = request(resource(@private_topic, @private_element, :permalink))
        response.should be_successful
        response.should have_selector("input#permalink")
        response.should_not have_selector("form")
      end
    end

    it "shouldn't be shown for private topic and not-owner" do
      as(User.gen) do
        response = request(resource(@private_topic, @private_element, :permalink))
        response.should be_forbidden
      end
    end

    it "should be send to friend if form is valid" do
      as(User.gen) do
        lambda do
          response = request(resource(@topic, @element, :permalink), :method => 'post', :params => { :permalink_form => { :email => "email@email.com" } })
          response.should be_successful
          response.body.to_s.should == ""
        end.should change(Merb::Mailer.deliveries, :count).by(1)
      end
    end

    it "should not be send to friend if form is invalid" do
      as(User.gen) do
        lambda do
          response = request(resource(@topic, @element, :permalink), :method => 'post', :params => { :permalink_form => { :email => "email" } })
          response.should be_successful
          response.should have_selector("form")
        end.should_not change(Merb::Mailer.deliveries, :count)
      end
    end
  end

end
