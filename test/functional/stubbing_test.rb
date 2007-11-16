require File.expand_path(File.dirname(__FILE__) + "/../test_helper")
require 'hardmock'
require 'assert_error'

class StubbingTest < Test::Unit::TestCase

  #
  # TESTS
  # 

  it "stubs a class method (and un-stubs after verify)" do
    assert_equal "stones and gravel", Concrete.pour
    assert_equal "glug glug", Jug.pour

    Concrete.stubs!(:pour).returns("dust and plaster")

    3.times do
      assert_equal "dust and plaster", Concrete.pour
    end

    assert_equal "glug glug", Jug.pour, "Jug's 'pour' method broken"
    assert_equal "stones and gravel", Concrete._hardmock_original_pour, "Original 'pour' method not aliased"

    assert_equal "For roads", Concrete.describe, "'describe' method broken"

    verify_mocks

    assert_equal "stones and gravel", Concrete.pour, "'pour' method not restored"
    assert_equal "For roads", Concrete.describe, "'describe' method broken after verify"

  end

  it "stubs several class methods" do
    Concrete.stubs!(:pour).returns("sludge")
    Concrete.stubs!(:describe).returns("awful")
    Jug.stubs!(:pour).returns("milk")

    assert_equal "sludge", Concrete.pour
    assert_equal "awful", Concrete.describe
    assert_equal "milk", Jug.pour

    verify_mocks

    assert_equal "stones and gravel", Concrete.pour
    assert_equal "For roads", Concrete.describe
    assert_equal "glug glug", Jug.pour
  end

  it "stubs instance methods" do
    slab = Concrete.new
    assert_equal "bonk", slab.hit

    slab.stubs!(:hit).returns("slap")
    assert_equal "slap", slab.hit, "'hit' not stubbed"

    verify_mocks

    assert_equal "bonk", slab.hit, "'hit' not restored"
  end

  it "stubs instance methods without breaking class methods or other instances" do
    slab = Concrete.new
    scrape = Concrete.new
    assert_equal "an instance", slab.describe
    assert_equal "an instance", scrape.describe
    assert_equal "For roads", Concrete.describe

    slab.stubs!(:describe).returns("new instance describe")
    assert_equal "new instance describe", slab.describe, "'describe' on instance not stubbed"
    assert_equal "an instance", scrape.describe, "'describe' on 'scrape' instance broken"
    assert_equal "For roads", Concrete.describe, "'describe' class method broken"

    verify_mocks

    assert_equal "an instance", slab.describe, "'describe' instance method not restored"
    assert_equal "an instance", scrape.describe, "'describe' on 'scrape' instance broken after restore"
    assert_equal "For roads", Concrete.describe, "'describe' class method broken after restore"
  end

  should "not allow stubbing of nonexistant class methods" do
    assert_error(Hardmock::StubbingError, /cannot stub/i, /class method/i, /Concrete.funky/) do   
      Concrete.stubs!(:funky)
    end
  end

  should "not allow stubbing of nonexistant instance methods" do
    assert_error(Hardmock::StubbingError, /cannot stub/i, /method/i, /Concrete#my_inst_mth/) do   
      Concrete.new.stubs!(:my_inst_mth)
    end
  end

  should "allow re-stubbing" do
    Concrete.stubs!(:pour).returns("one")
    assert_equal "one", Concrete.pour

    Concrete.stubs!(:pour).raises("hell")
    assert_error RuntimeError, /hell/ do
      Concrete.pour
    end

    Concrete.stubs!(:pour).returns("two")
    assert_equal "two", Concrete.pour

    verify_mocks

    assert_equal "stones and gravel", Concrete.pour
  end

  it "does nothing with a runtime block when simply stubbing" do
    prepare_hardmock_control
    slab = Concrete.new
    slab.stubs!(:hit) do |nothing|
      raise "BOOOMM!"
    end
    slab.hit
    verify_mocks
  end

  it "can raise errors from a stubbed method" do
    prepare_hardmock_control
    Concrete.stubs!(:pour).raises(StandardError.new("no!"))
    assert_error StandardError, /no!/ do
      Concrete.pour
    end
  end

  it "provides string syntax for convenient raising of RuntimeErrors" do
    prepare_hardmock_control
    Concrete.stubs!(:pour).raises("never!")
    assert_error RuntimeError, /never!/ do
      Concrete.pour
    end
  end


  #
  # Per-method mocking on classes or instances
  #

  it "mocks specific methods on existing classes, and returns the class method to normal after verification" do
    prepare_hardmock_control
    assert_equal "stones and gravel", Concrete.pour, "Concrete.pour is already messed up"

    Concrete.expects!(:pour).returns("ALIGATORS")
    assert_equal "ALIGATORS", Concrete.pour

    verify_mocks
    assert_equal "stones and gravel", Concrete.pour, "Concrete.pour not restored"
  end
   
  it "flunks if expected class method is not invoked" do
    prepare_hardmock_control
    Concrete.expects!(:pour).returns("ALIGATORS")
    assert_error(Hardmock::VerifyError, /Concrete.pour/, /unmet expectations/i) do
      verify_mocks
    end
    clear_expectations
  end

  it "supports all normal mock functionality for class methods" do
    prepare_hardmock_control
    Concrete.expects!(:pour, "two tons").returns("mice")
    Concrete.expects!(:pour, "three tons").returns("cats")
    Concrete.expects!(:pour, "four tons").raises("Can't do it")
    Concrete.expects!(:pour) do |some, args|
      "==#{some}+#{args}=="
    end

    assert_equal "mice", Concrete.pour("two tons")
    assert_equal "cats", Concrete.pour("three tons")
    assert_error(RuntimeError, /Can't do it/) do 
      Concrete.pour("four tons")
    end
    assert_equal "==first+second==", Concrete.pour("first","second")
  end


  it "enforces inter-mock ordering when mocking class methods" do
    create_mocks :truck, :foreman
    
    @truck.expects.backup
    Concrete.expects!(:pour, "something")
    @foreman.expects.shout

    @truck.backup
    assert_error Hardmock::ExpectationError, /wrong/i, /expected call/i, /Concrete.pour/ do
      @foreman.shout
    end
    assert_error Hardmock::VerifyError, /unmet expectations/i, /foreman.shout/ do
      verify_mocks
    end
    clear_expectations
  end

  should "not allow mocking non-existant class methods" do
    prepare_hardmock_control
    assert_error Hardmock::StubbingError, /non-existant/, /something/ do
      Concrete.expects!(:something)
    end
  end

  it "mocks specific methods on existing instances, then restore them after verify" do
    prepare_hardmock_control
    slab = Concrete.new
    assert_equal "bonk", slab.hit

    slab.expects!(:hit).returns("slap")
    assert_equal "slap", slab.hit, "'hit' not stubbed"

    verify_mocks
    assert_equal "bonk", slab.hit, "'hit' not restored"
  end

  it "flunks if expected instance method is not invoked" do
    prepare_hardmock_control
    slab = Concrete.new
    slab.expects!(:hit)

    assert_error Hardmock::VerifyError, /unmet expectations/i, /Concrete.hit/ do
      verify_mocks
    end
    clear_expectations
  end

  it "supports all normal mock functionality for instance methods" do
    prepare_hardmock_control
    slab = Concrete.new

    slab.expects!(:hit, "soft").returns("hey")
    slab.expects!(:hit, "hard").returns("OOF")
    slab.expects!(:hit).raises("stoppit")
    slab.expects!(:hit) do |some, args|
      "==#{some}+#{args}=="
    end

    assert_equal "hey", slab.hit("soft")
    assert_equal "OOF", slab.hit("hard")
    assert_error(RuntimeError, /stoppit/) do 
      slab.hit
    end
    assert_equal "==first+second==", slab.hit("first","second")
    
  end

  it "enforces inter-mock ordering when mocking instance methods" do
    create_mocks :truck, :foreman
    slab1 = Concrete.new
    slab2 = Concrete.new

    @truck.expects.backup
    slab1.expects!(:hit)
    @foreman.expects.shout
    slab2.expects!(:hit)
    @foreman.expects.whatever

    @truck.backup
    slab1.hit
    @foreman.shout
    assert_error Hardmock::ExpectationError, /wrong/i, /expected call/i, /Concrete.hit/ do
      @foreman.whatever
    end
    assert_error Hardmock::VerifyError, /unmet expectations/i, /foreman.whatever/ do
      verify_mocks
    end
    clear_expectations
  end

  should "not allow mocking non-existant instance methods" do
    prepare_hardmock_control
    slab = Concrete.new
    assert_error Hardmock::StubbingError, /non-existant/, /something/ do
      slab.expects!(:something)
    end
  end

  should "support concrete expectations that deal with runtime blocks" do
    prepare_hardmock_control

    Concrete.expects!(:pour, "a lot") do |how_much, block|
      assert_equal "a lot", how_much, "Wrong how_much arg"
      assert_not_nil block, "nil runtime block"
      assert_equal "the block value", block.call, "Wrong runtime block value"
    end

    Concrete.pour("a lot") do
      "the block value"
    end

  end

  it "can stub methods on mock objects" do
    create_mock :horse
    @horse.stubs!(:speak).returns("silence")
    @horse.stubs!(:hello).returns("nothing")
    @horse.expects(:canter).returns("clip clop")

    assert_equal "silence", @horse.speak
    assert_equal "clip clop", @horse.canter
    assert_equal "silence", @horse.speak
    assert_equal "silence", @horse.speak
    assert_equal "nothing", @horse.hello
    assert_equal "nothing", @horse.hello

    verify_mocks
  end

  it "will not allow expects! to be used on a mock object" do
    create_mock :cow
    assert_error Hardmock::StubbingError, /expects!/, /mock/i, /something/ do
      @cow.expects!(:something)
    end
  end

  #
  # HELPERS
  #

  class Concrete
    def self.pour
      "stones and gravel"
    end

    def self.describe
      "For roads"
    end

    def hit
      "bonk"
    end

    def describe
      "an instance"
    end
  end

  class Jug
    def self.pour
      "glug glug"
    end
  end

end

