require 'hardmock'

class MyTest < Test::Unit::TestCase

  def test_the_mocks
    create_mocks :garage, :car
    # Set some expectations
    @garage.expects.open_door
    @car.expects.start(:choke)
    @car.expects.drive(:reverse, 5.mph)
    # You can also stub methods for mocks:
    @garage.stubs!(:has_roof?).returns(true)

    # Execute the code (normally your own classes do this)
    @garage.open_door  
    @car.start :choke
    @car.drive :reverse, 5.mph
  end

  class SchoolBus
    def self.color
      "yellow"
    end
    def stop(street)
      "stopping at #{street}"
    end
  end

  def test_the_concrete_stubbing_and_mocking
    # blind stubbing:
    SchoolBus.stubs!(:color).returns("red")
    #  ...or you can use strict, ordered expectations:
    SchoolBus.expect!(:color).returns("green") 

    bus = SchoolBus.new
    bus.stubs!(:stop).returns("screeee")
    # or...
    bus.expects!(:stop, "Bourbon Street").returns("ok")
  end

end

