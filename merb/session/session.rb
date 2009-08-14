module Merb
  module Session
    
    # The Merb::Session module gets mixed into Merb::SessionContainer to allow 
    # app-level functionality; it will be included and methods will be available 
    # through request.session as instance methods.

    def user
      authentication.user || Guest.new
    end
  end
end