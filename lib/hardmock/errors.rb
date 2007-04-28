module Hardmock
  # Raised when:
  # * Unexpected method is called on a mock object
  # * Bad arguments passed to an expected call
  class ExpectationError < StandardError; end

  # Raised for methods that should no longer be called.  Hopefully, the exception message contains helpful alternatives.
  class DeprecationError < StandardError; end

  # Raised when it is discovered that an expected method call was never made.
  class VerifyError < StandardError
    def initialize(msg,unmet_expectations)
      super("#{msg}:" + unmet_expectations.map { |ex| "\n * #{ex.to_s}" }.join)
    end
  end
end