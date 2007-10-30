require File.expand_path(File.dirname(__FILE__) + "/../test_helper")
require 'hardmock'
require 'assert_error'

class StubbingTest < Test::Unit::TestCase

  #
  # TESTS
  # 

  def test_should_let_you_stub_a_class_method
    assert_equal "stones and gravel", Concrete.pour
    assert_equal "glug glug", Jug.pour

    Concrete.stubs!(:pour).returns("dust and plaster")

    3.times do
      assert_equal "dust and plaster", Concrete.pour
    end

    assert_equal "glug glug", Jug.pour, "Jug's 'pour' method broken"
    assert_equal "stones and gravel", Concrete._hardmock_original_pour, "Original 'pour' method not aliased"

    assert_equal "For roads", Concrete.describe, "'describe' method broken"

    Hardmock.restore_all_stubbed_methods

    assert_equal "stones and gravel", Concrete.pour, "'pour' method not restored"
    assert_equal "For roads", Concrete.describe, "'describe' method broken after verify"

  end

  def test_should_let_you_stub_several_class_methods
    Concrete.stubs!(:pour).returns("sludge")
    Concrete.stubs!(:describe).returns("awful")
    Jug.stubs!(:pour).returns("milk")

    assert_equal "sludge", Concrete.pour
    assert_equal "awful", Concrete.describe
    assert_equal "milk", Jug.pour

    Hardmock.restore_all_stubbed_methods

    assert_equal "stones and gravel", Concrete.pour
    assert_equal "For roads", Concrete.describe
    assert_equal "glug glug", Jug.pour
  end

  def test_should_let_you_stub_instance_methods
    slab = Concrete.new
    assert_equal "bonk", slab.hit

    slab.stubs!(:hit).returns("slap")
    assert_equal "slap", slab.hit, "'hit' not stubbed"

    Hardmock.restore_all_stubbed_methods

    assert_equal "bonk", slab.hit, "'hit' not restored"
  end

  def test_should_let_you_stub_instance_methods_without_breaking_class_methods_or_other_instances
    slab = Concrete.new
    scrape = Concrete.new
    assert_equal "an instance", slab.describe
    assert_equal "an instance", scrape.describe
    assert_equal "For roads", Concrete.describe

    slab.stubs!(:describe).returns("new instance describe")
    assert_equal "new instance describe", slab.describe, "'describe' on instance not stubbed"
    assert_equal "an instance", scrape.describe, "'describe' on 'scrape' instance broken"
    assert_equal "For roads", Concrete.describe, "'describe' class method broken"

    Hardmock.restore_all_stubbed_methods

    assert_equal "an instance", slab.describe, "'describe' instance method not restored"
    assert_equal "an instance", scrape.describe, "'describe' on 'scrape' instance broken after restore"
    assert_equal "For roads", Concrete.describe, "'describe' class method broken after restore"
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

