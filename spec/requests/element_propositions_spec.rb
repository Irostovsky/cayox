require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

describe "Element propositions" do
  
  before(:all) do
    prepare_favourite(prepare_public_topic)
    propose_element(@favourite_custom_element)
  end

  describe "listing" do

    it "should raise Unauthenticated when user is guest" do
      as(Guest.new) do
        response = request(resource(:element_propositions))
        response.status.should == 401
      end
    end

    it "should redirect to My Topics if user doesn't manage any topics" do
      as(User.gen) do
        response = request(resource(:element_propositions))
        response.should redirect_to(url(:mytopics))
      end
    end

    it "should render list of pending propositions and remove element propo notifications" do
      ElementProposition.send_notifications!
      as(@topic_owner) do
        lambda do
          response = request(resource(:element_propositions))
          response.should be_successful
          response.should have_selector(".primary a:contains('#{@favourite_custom_element.name[:pl]}')")
        end.should change(ElementPropositionsNotification, :count).by(-1)
      end
    end

  end

  describe "accepting / rejecting" do

    it "should raise Unauthenticated when user is guest" do
      [:add, :reject].each do |submit_name|
        as(Guest.new) do
          response = request(resource(:element_propositions, :confirm), :params => { :element_ids => [1], submit_name => "Go!" })
          response.status.should == 401
        end
      end
    end

    it "should redirect to My Topics if user doesn't manage any topics" do
      as(User.gen) do
        response = request(resource(:element_propositions, :confirm), :params => { :element_ids => [@proposition.id], :add => "Go!" })
        response.should redirect_to(url(:mytopics))
      end
    end

    it "should accept elements" do
      as(@topic_owner) do
        response = request(resource(:element_propositions, :confirm), :params => { :element_ids => [@proposition.id], :add => "Go!" })
        response.should redirect_to(resource(:element_propositions))
      end
    end

    it "should reject elements" do
      as(@topic_owner) do
        response = request(resource(:element_propositions, :confirm), :params => { :element_ids => [@proposition.id], :reject => "Go!" })
        response.should redirect_to(resource(:element_propositions))
      end
    end

    it "should show error that elements has been accepted or topic removed" do
      @topic.hide!
      as(@topic_owner) do
        response = request(resource(:element_propositions, :confirm), :params => { :element_ids => [@proposition.id], :add => "Go!" })
        response.should redirect_to(resource(:element_propositions))
        response = request(response.headers['Location'])
        response.should have_selector(".error:contains('haven')")
      end
    end
  end
  
end