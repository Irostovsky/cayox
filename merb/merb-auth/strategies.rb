# This file is specifically for you to define your strategies 
#
# You should declare you strategies directly and/or use 
# Merb::Authentication.activate!(:label_of_strategy)
#
# To load and set the order of strategy processing

Merb::Slices::config[:"merb-auth-slice-password"][:no_default_strategies] = true

Merb::Authentication.activate!(:default_password_form)
Merb::Authentication.activate!(:default_basic_auth)

class Merb::Authentication
  module Strategies
    module Basic
      class Form < Base

        def run!
          if (login = request.params[login_param]) && (password = request.params[password_param])
            user = user_class.authenticate(login, password)
            if user
              if user.blocked?
                errors = request.session.authentication.errors
                errors.clear!
                errors.add(:general, GetText._("Sorry, your account has been blocked"))
                nil
              elsif !user.active?
                errors = request.session.authentication.errors
                errors.clear!  
                errors.add(:general, GetText._("Sorry, you need to activate your account first"))
                nil
              else
                user.last_login = DateTime::now
                user.save
                user # success !
              end
            else
              errors = request.session.authentication.errors
              errors.clear!
              errors.add(:general, GetText._("Invalid user/password combination"))
              nil
            end
          end
        end # run!

      end # Form
    end # Password
  end # Strategies
end # Authentication