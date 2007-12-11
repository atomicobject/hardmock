require 'test/unit'
require 'test/unit/testcase'
require 'test/unit/assertions'

# == TestCase Modifications
#
# Monkey-patch to provide a formal mechanism for appending actions to be executed after teardown.
# Use after_teardown to define one or more actions to be executed after teardown for ALL tests.
#
# COMING SOON?
# * Hook for running actions prior to setup
# * Hooks for before_teardown, after_setup, on_error
# * Options for positional control, eg, after_teardown :before_other_actions
# * Provide tagging/filtering so action execution can be controlled specifically?
#
# == Usage
#
# Invoke TestCase.after_teardown with optional parameter, which will be invoked with a reference
# to the test instance that has just been torn down.
#
# Example:
# 
#   Test::Unit::TestCase.after_teardown do |test|
#     test.verify_mocks
#   end
#   
# == Justification
#
# There are a number of tools and libraries that play fast-n-loose with setup and teardown by 
# wrapping them, and by overriding method_added as a means of upholding special setup/teardown 
# behavior, usually by re-wrapping newly defined user-level setup/teardown methods.
# mocha and active_record/fixtures (and previously, hardmock) will fight for this
# territory with often unpredictable results.
#
# We wouldn't have to battle if Test::Unit provided a formal pre- and post- hook mechanism.
#
module Test #:nodoc:#
  module Unit #:nodoc:#
    class TestCase

      class << self
        
        # Define an action to be run after teardown. Subsequent calls result in 
        # multiple actions.  The block will be given a reference to the test
        # being executed.
        #
        # Example:
        # 
        #   Test::Unit::TestCase.after_teardown do |test|
        #     test.verify_mocks
        #   end
        def after_teardown(&block)
          post_teardown_actions << block
        end

        # Used internally. Access the list of post teardown actions for to be
        # used by all tests.
        def post_teardown_actions
          @@post_teardown_actions ||= []
        end
      end

      # OVERRIDE: This is a reimplementation of the default "run", updated to
      # execute actions after teardown.
      def run(result)
        yield(STARTED, name)
        @_result = result
        begin
          setup
          __send__(@method_name)
        rescue Test::Unit::AssertionFailedError => e
          add_failure(e.message, auxiliary_backtrace_filter(e.backtrace))
        rescue Exception
          raise if should_passthru_exception($!) # See implementation; this is for pre-1.8.6 compat
          add_error($!)
        ensure
          begin
            teardown
          rescue Test::Unit::AssertionFailedError => e
            add_failure(e.message, auxiliary_backtrace_filter(e.backtrace))
          rescue Exception
            raise if should_passthru_exception($!) # See implementation; this is for pre-1.8.6 compat
            add_error($!)
          ensure
            execute_post_teardown_actions(self)
          end
        end
        result.add_run
        yield(FINISHED, name)
      end

      private

      # Run through the after_teardown actions, treating failures and errors
      # in the same way that "run" does: they are reported, and the remaining
      # actions are executed.
      def execute_post_teardown_actions(test_instance)
        self.class.post_teardown_actions.each do |action|
          begin
            action.call test_instance
          rescue Test::Unit::AssertionFailedError => e
            add_failure(e.message, auxiliary_backtrace_filter(e.backtrace))
          rescue Exception
            raise if should_passthru_exception($!)
            add_error($!)
          end
        end
      end

      # Make sure that this extension doesn't show up in failure backtraces
      def auxiliary_backtrace_filter(trace)
        trace.reject { |x| x =~ /test_unit_before_after/ }
      end

      # Is the given error of the type that we allow to fly out (rather than catching it)?
      def should_passthru_exception(ex)
        return passthrough_exception_types.include?($!.class)
      end

      # Provide a list of exception types that are to be allowed to explode out.
      # Pre-ruby-1.8.6 doesn't use this functionality, so the PASSTHROUGH_EXCEPTIONS
      # constant won't be defined.  This methods defends against that and returns
      # an empty list instead.
      def passthrough_exception_types
        begin 
          return PASSTHROUGH_EXCEPTIONS
        rescue NameError
          # older versions of test/unit do not have PASSTHROUGH_EXCEPTIONS constant
          return []
        end
      end
    end
  end
end
