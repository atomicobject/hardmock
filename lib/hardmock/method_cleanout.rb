
module Hardmock #:nodoc:
  module MethodCleanout #:nodoc:
    SACRED_METHODS = %w|__id__ __send__ equal? object_id send nil? class kind_of? respond_to? inspect method to_s instance_variables instance_eval ==|

    def self.included(base) #:nodoc:
      base.class_eval do
        instance_methods.each { |m| 
          undef_method m unless SACRED_METHODS.include?(m.to_s)
        }
      end
    end
  end
end
