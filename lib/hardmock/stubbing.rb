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

#  def meta_eval_string(str)
#    metaclass.instance_eval(str)
#  end

	# Defines an instance method within a class
#	def class_def(name, &blk) #:nodoc:#
#		class_eval { define_method name, &blk }
#	end
end



module Hardmock

  # == Hardmock: Stubbing and Mocking Concrete Methods
  #
  # Hardmock lets you stub and/or mock methods on concrete classes or objects.
  #
  # * To "stub" a concrete method is to rig it to return the same thing always, disregarding any arguments.
  # * To "mock" a concrete method is to surplant its funcionality by delegating to a mock object who will cover this behavior.
  #
  # Mocked methods have their expectations considered along with all other mock object expectations.
  #
  # If you use stubbing or concrete mocking in the absence (or before creation) of other mocks, you need to invoke <tt>prepare_hardmock_control</tt>.
  # Once <tt>verify_mocks</tt> or <tt>clear_expectaions</tt> is called, the overriden behavior in the target objects is restored.
  #
  # == Examples
  #
  #   River.stubs!(:sounds_like).returns("gurgle")
  #
  #   River.expects!(:jump).returns("splash")
  #
  #   rogue.stubs!(:sounds_like).returns("pshshsh")
  #
  #   rogue.expects!(:rawhide_tanning_solvents).returns("giant snapping turtles")
  #
  module Stubbing
    # Exists only for documentation 
  end

  class StubbedMethod #:nodoc:#
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

  class MockedMethod < StubbedMethod #:nodoc:#

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

      unless _is_mock?
        meta_eval do 
          alias_method "_hardmock_original_#{method_name}".to_sym, method_name.to_sym
        end
      end

      meta_def method_name do |*args|
        stubbed_method.invoke(args)
      end

      stubbed_method
    end

    def expects!(method_name, *args, &block)
      if self._is_mock?
        raise Hardmock::StubbingError, "Cannot use 'expects!(:#{method_name})' on a Mock object; try 'expects' instead"
      end
      _ensure_stubbable method_name

      method_name = method_name.to_s

      if @_my_mock.nil?
        @_my_mock = Mock.new(_my_name, $main_mock_control)
        stubbed_method = Hardmock::MockedMethod.new(self, method_name, @_my_mock)
        meta_eval do 
          alias_method "_hardmock_original_#{method_name}".to_sym, method_name.to_sym
        end

        meta_def(method_name) do |*args|
          stubbed_method.invoke(args)
        end
      end

      return @_my_mock.expects(method_name, *args, &block)
    end
      
    def _ensure_stubbable(method_name)
      unless self.respond_to?(method_name.to_sym) or self._is_mock?
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

    def _is_mock?
      self.kind_of?(Mock)
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
        unless sm.target._is_mock?
          sm.target.meta_eval do
            alias_method sm.method_name.to_sym, "_hardmock_original_#{sm.method_name}".to_sym 
          end
          sm.target._clear_mock
        end
      end
    end
  end

end

