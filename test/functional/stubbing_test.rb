require File.expand_path(File.dirname(__FILE__) + "/../test_helper")
require 'hardmock'
require 'assert_error'

class StubbingTest < Test::Unit::TestCase

  #
  # TESTS
  # 

  it "stubs a class method" do
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

