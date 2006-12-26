require File.expand_path(File.dirname(__FILE__) + "/../test_helper")
require 'hardmock'
class HardmockTest < Test::Unit::TestCase

  def setup
  end

  def teardown
  end

  #
  # HELPERS
  #

  def assert_mock_exists(name)
    assert_not_nil @all_mocks, "@all_mocks not here yet"
    mo = @all_mocks[name]
    assert_not_nil mo, "Mock '#{name}' not in @all_mocks"
    assert_kind_of Mock, mo, "Wrong type of object, wanted a Mock"
    assert_equal name.to_s, mo._name, "Mock '#{name}' had wrong name"
    ivar = self.instance_variable_get("@#{name}")
    assert_not_nil ivar, "Mock '#{name}' not set as ivar"
    assert_same mo, ivar, "Mock '#{name}' ivar not same as instance in @all_mocks"
    assert_same @main_mock_control, mo._control, "Mock '#{name}' doesn't share the main mock control"
  end
  
  #
  # TESTS
  # 

  def test_create_mock_and_create_mocks
    assert_nil @main_mock_control, "@main_mock_control not expected yet"

    h = create_mock :donkey
    assert_equal [ :donkey ], h.keys
    assert_not_nil @main_mock_control, "@main_mock_control should be here"

    assert_mock_exists :donkey
    assert_same @donkey, h[:donkey]

    assert_equal [ :donkey ], @all_mocks.keys, "Wrong keyset for @all_mocks"

    h2 = create_mocks :cat, 'dog' # symbol/string indifference at this level
    assert_equal [:cat,:dog].to_set, h2.keys.to_set, "Wrong keyset for second hash"
    assert_equal [:cat,:dog,:donkey].to_set, @all_mocks.keys.to_set, "@all_mocks wrong"   

    assert_mock_exists :cat
    assert_same @cat, h2[:cat]
    assert_mock_exists :dog
    assert_same @dog, h2[:dog]

    assert_mock_exists :donkey
  end

  def test_expect
    assert_nil @order, "Should be no @order yet"
    create_mock :order
    assert_not_nil @order, "@order should be built"

    # Setup an expectation
    @order.expects.update_stuff :key1 => 'val1', :key2 => 'val2'

    # Use the mock
    @order.update_stuff :key1 => 'val1', :key2 => 'val2'

    # Verify
    verify_mocks

    # See that it's ok to do it again
    verify_mocks
  end

  def test_typical_multi_mock_use
    create_mocks :order_builder, :order, :customer

    @order_builder.expects.create_new_order.returns @order
    @customer.expects.account_number.returns(1234)
    @order.expects.account_no = 1234
    @order.expects.save!

    # Run "the code"
    o = @order_builder.create_new_order
    o.account_no = @customer.account_number
    o.save!

    verify_mocks
  end

  def test_typical_multi_mock_use_out_of_order
    create_mocks :order_builder, :order, :customer

    @order_builder.expects.create_new_order.returns @order
    @customer.expects.account_number.returns(1234)
    @order.expects.account_no = 1234
    @order.expects.save!

    # Run "the code"
    o = @order_builder.create_new_order
    err = assert_raise ExpectationError do
      o.save!
    end
    assert_match(/wrong object/i, err.message) 
    assert_match(/order.save!/i, err.message) 
    assert_match(/customer.account_number/i, err.message) 

    assert_error VerifyError, /unmet expectations/i do
      verify_mocks
    end

    # Appease the verifier
    @order.account_no = 1234
    @order.save!
  end

  class UserPresenter
    def initialize(args)
      view = args[:view]
      model = args[:model]
      model.when :data_changes do
        view.user_name = model.user_name
      end
      view.when :user_edited do
        model.user_name = view.user_name
      end
    end
  end

  def test_mvp_usage_pattern
    mox = create_mocks :model, :view

    data_change = @model.expects.when(:data_changes) { |evt,block| block }
    user_edit = @view.expects.when(:user_edited) { |evt,block| block }
    
    UserPresenter.new mox

    # Expect user name transfer from model to view
    @model.expects.user_name.returns 'Da Croz'
    @view.expects.user_name = 'Da Croz'
    # Trigger data change event in model
    data_change.block_value.call

    # Expect user name transfer from view to model
    @view.expects.user_name.returns '6:8'
    @model.expects.user_name = '6:8'
    # Trigger edit event in view
    user_edit.block_value.call

    verify_mocks 
  end

  def test_verify_mocks_repeated_anger
    mox = create_mocks :model, :view
    data_change = @model.expects.when(:data_changes) { |evt,block| block }
    user_edit = @view.expects.when(:user_edited) { |evt,block| block }
    UserPresenter.new mox

    # Expect user name transfer from model to view
    @model.expects.user_name.returns 'Da Croz'
    @view.expects.user_name = 'Da Croz'

    assert_error ExpectationError, /model.monkey_wrench/i do
      @model.monkey_wrench
    end

    # This should raise because of unmet expectations
    assert_error VerifyError, /unmet expectations/i, /user_name/i do
      verify_mocks
    end

    # See that the non-forced verification remains quiet
    assert_nothing_raised VerifyError do
      verify_mocks(false)
    end
    
    # Finish meeting expectations and see good verification behavior
    @view.user_name = "Da Croz"    
    verify_mocks
    
    @model.expects.never_gonna_happen
    
    assert_error VerifyError, /unmet expectations/i, /never_gonna_happen/i do
      verify_mocks
    end

    # Appease the verifier
    @model.never_gonna_happen
  end

  class UserPresenterBroken
    def initialize(args)
      view = args[:view]
      model = args[:model]
      model.when :data_changes do
        view.user_name = model.user_name
      end
      # no view stuff, will break appropriately
    end
  end

  def test_mvp_usage_with_failures_in_constructor
    mox = create_mocks :model, :view

    data_change = @model.expects.when(:data_changes) { |evt,block| block }
    user_edit = @view.expects.when(:user_edited) { |evt,block| block }
    
    UserPresenterBroken.new mox

    err = assert_raise VerifyError do
      verify_mocks
    end
    assert_match(/unmet expectations/i, err.message) 
    assert_match(/view.when\(:user_edited\)/i, err.message) 

    assert_error VerifyError, /unmet expectations/i do
      verify_mocks
    end 

    # Appease the verifier
    @view.when(:user_edited)

  end

  def test_mvp_usage_pattern_with_convenience_trap
    mox = create_mocks :model, :view

    data_change = @model.trap.when(:data_changes) 
    user_edit = @view.trap.when(:user_edited) 
    
    UserPresenter.new mox

    # Expect user name transfer from model to view
    @model.expects.user_name.returns 'Da Croz'
    @view.expects.user_name = 'Da Croz'
    # Trigger data change event in model
    data_change.trigger

    # Expect user name transfer from view to model
    @view.expects.user_name.returns '6:8'
    @model.expects.user_name = '6:8'
    # Trigger edit event in view
    user_edit.trigger

    verify_mocks 
  end

  class Grinder
    def initialize(objects)
      @chute = objects[:chute]
      @bucket = objects[:bucket]
      @blade = objects[:blade]
    end

    def grind(slot)
      @chute.each_bean(slot) do |bean|
        @bucket << @blade.chop(bean)
      end
    end
  end

  def test_internal_iteration_usage
    grinder = Grinder.new create_mocks(:blade, :chute, :bucket)
    
    # Style 1: assertions on method args is done explicitly in block
    @chute.expects.each_bean { |slot,block| 
      assert_equal :side_slot, slot, "Wrong slot"
      block.call :bean1
      block.call :bean2
    }

    @blade.expects.chop(:bean1).returns(:grounds1)
    @bucket.expects('<<', :grounds1)

    @blade.expects.chop(:bean2).returns(:grounds2)
    @bucket.expects('<<', :grounds2)

    # Run "the code"
    grinder.grind(:side_slot)

    verify_mocks

    # Style 2: assertions on method arguments done implicitly in the expectation code
    @chute.expects.each_bean(:main_slot) { |slot,block| 
      block.call :bean3
    }
    @blade.expects.chop(:bean3).returns(:grounds3)
    @bucket.expects('<<', :grounds3)
    grinder.grind :main_slot
    verify_mocks
  end

  def test_internal_iteration_using_yield
    grinder = Grinder.new create_mocks(:blade, :chute, :bucket)
    
    @chute.expects.each_bean(:side_slot).yields :bean1, :bean2

    @blade.expects.chop(:bean1).returns(:grounds1)
    @bucket.expects('<<', :grounds1)

    @blade.expects.chop(:bean2).returns(:grounds2)
    @bucket.expects('<<', :grounds2)

    grinder.grind :side_slot

    verify_mocks
  end

  class HurtLocker
    attr_reader :caught
    def initialize(opts)
      @locker = opts[:locker]
      @store = opts[:store]
    end

    def do_the_thing(area,data)
      @locker.with_lock(area) do
        @store.eat(data)
      end
    rescue => oops
      @caught = oops
    end
  end

  def test_internal_locking_scenario
    hurt = HurtLocker.new create_mocks(:locker, :store)

    @locker.expects.with_lock(:main).yields
    @store.expects.eat("some info")

    hurt.do_the_thing(:main, "some info")

    verify_mocks
  end

  def test_internal_locking_scenario_with_inner_error
    hurt = HurtLocker.new create_mocks(:locker, :store)
    err = StandardError.new('fmshooop')  
    @locker.expects.with_lock(:main).yields
    @store.expects.eat("some info").raises(err)

    hurt.do_the_thing(:main, "some info")

    assert_same err, hurt.caught, "Expected that error to be handled internally"
    verify_mocks
  end
	
	def test_returning_false_actually_returns_false_and_not_nil
		create_mock :car
		@car.expects.ignition_on?.returns(true)
		assert_equal true, @car.ignition_on?, "Should be true"
		@car.expects.ignition_on?.returns(false)
		assert_equal false, @car.ignition_on?, "Should be false"
	end

  def test_should_be_able_to_mock_methods_inherited_from_object
    target_methods = %w|instance_eval instance_variables id clone display dup eql? ==|
    create_mock :foo
    target_methods.each do |m|
      eval %{@foo.expects(m, "some stuff")}
      eval %{@foo.#{m} "some stuff"}
    end
  end

  def test_should_support_expect_as_an_alias_for_expects 
    create_mock :foo
    @foo.expect.boomboom
    @foo.boomboom
    verify_mocks 
  end

  def test_should_not_raise_expectation_errors_for_the_method_inspect_or_to_s_methods
    create_mock :foo
    inspect_method = @foo.method(:inspect)
    assert_equal @foo.inspect, inspect_method.call
    @foo.to_s
    verify_mocks 
  end
end

