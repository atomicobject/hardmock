#
# Stubbing support
#
# Stubs methods on classes and instances
#

# Why's "metaid.rb":
class Object #:nodoc:#
	# The hidden singleton lurks behind everyone
	def metaclass #:nodoc:#
    class << self
      self
    end
  end
	
  # Evaluate a block of code within the metaclass
	def meta_eval(&blk) #:nodoc:#
    metaclass.instance_eval(&blk)
  end

	# Adds methods to a metaclass
	def meta_def(name, &blk) #:nodoc:#
		meta_eval { define_method name, &blk }
	end

	# Defines an instance method within a class
	def class_def(name, &blk) #:nodoc:#
		class_eval { define_method name, &blk }
	end
end



module Hardmock
  class StubbedMethod
    attr_reader :target, :method_name

    def initialize(target, method_name)
      @target = target
      @method_name = method_name

      Hardmock.add_stubbed_method self
    end

    def invoke(args)
      @return_value
    end

    def returns(stubbed_return)
      @return_value = stubbed_return
    end
  end

  class MockedMethod < StubbedMethod

    def initialize(target, method_name, mock)
      super target,method_name
      @mock = mock
    end

    def invoke(args)
      @mock.__send__(self.method_name.to_sym, *args)
    end

  end

  class ::Object
    def stubs!(method_name)
      _ensure_stubbable method_name

      method_name = method_name.to_s
      stubbed_method = Hardmock::StubbedMethod.new(self, method_name)

      meta_eval do 
        alias_method "_hardmock_original_#{method_name}".to_sym, method_name.to_sym

        define_method(method_name) do |*args|
          stubbed_method.invoke(args)
        end
      end

      stubbed_method
    end

    def expects!(method_name, *args, &block)
      _ensure_stubbable method_name

      method_name = method_name.to_s

      if @_my_mock.nil?
        @_my_mock = Mock.new(_my_name, $main_mock_control)
        stubbed_method = Hardmock::MockedMethod.new(self, method_name, @_my_mock)
        meta_eval do 
          alias_method "_hardmock_original_#{method_name}".to_sym, method_name.to_sym
          define_method(method_name) do |*args|
            stubbed_method.invoke(args)
          end
        end
      end

      return @_my_mock.expects(method_name, *args, &block)
    end
      
    def _ensure_stubbable(method_name)
      unless self.respond_to?(method_name.to_sym)
        msg = "Cannot stub non-existant "
        if self.kind_of?(Class) 
          msg += "class method #{_my_name}."
        else
          msg += "method #{_my_name}#"
        end
        msg += method_name.to_s
        raise Hardmock::StubbingError.new(msg)
      end
    end

    def _my_name
      self.kind_of?(Class) ? self.name : self.class.name
    end

    def _clear_mock
      @_my_mock = nil
    end

  end

  class << self
    def add_stubbed_method(stubbed_method)
      all_stubbed_methods << stubbed_method
    end

    def all_stubbed_methods
      $all_stubbed_methods ||= []
    end

    def restore_all_stubbed_methods
      all_stubbed_methods.each do |sm|
        sm.target.meta_eval do
          alias_method sm.method_name.to_sym, "_hardmock_original_#{sm.method_name}".to_sym 
        end
        sm.target._clear_mock
      end
    end
  end

end

