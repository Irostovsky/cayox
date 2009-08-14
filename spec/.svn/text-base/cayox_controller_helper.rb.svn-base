module Cayox
  module Test
    module ControllerHelper
      private
  
      def as(u, &blk)
        Merb::CookieSession.class_eval do
          alias_method :old_user, :user
          define_method :user do
            u
          end

          alias_method :old_authenticated?, :authenticated?
          define_method :authenticated? do
            u && !u.guest?
          end
        end
        yield
      ensure
        Merb::CookieSession.class_eval do
          undef_method :user
          alias_method :user, :old_user

          undef_method :authenticated?
          alias_method :authenticated?, :old_authenticated?
        end
      end
    end
  end # Test
end # Cayox
