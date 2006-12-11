require 'hardmock'

class MyTest < Test::Unit::TestCase

  def setup
    create_mocks :garage, :car
  end

  def test_the_mocks
    # Set some expectations
    @garage.expects.open_door
    @car.expects.start(:choke)
    @car.expects.drive(:reverse, 5.mph)

    # Execute the code (normally your own classes do this)
    @garage.open_door  
    @car.start :choke
    @car.drive :reverse, 5.mph
  end

end
