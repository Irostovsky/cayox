module Cayox
  module Test
    module Matchers
      def self.included(base)
        [:not_found, :forbidden, :bad_request, :unauthorized].each do |st|
          ::Spec::Matchers.create(:"be_#{st}") do
            expected_status = Merb::Controller::STATUS_CODES[st]

            matches do |rack|
              @status = rack.respond_to?(:status) ? rack.status : rack
              @inspect = describe_input(rack)

              @status == expected_status
            end

            message do |not_string, rack|
              "Expected #{@inspect} status to be #{expected_status}, but it was #{@status}."
            end
          end
        end
      end
    end
  end
end