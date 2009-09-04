require 'test_helper'
require 'lib/settings'
require 'lib/geolocate'

class GeolocateTest < ActiveSupport::TestCase

  test "geolocating portland with metacarta" do
    text = "Portland, Oregon"
    name = SETTINGS[:site_metacarta_userid]
    password = SETTINGS[:site_metacarta_pass]
    key = SETTINGS[:site_metacarta_key]
    lat,lon = Geolocate.geolocate_via_metacarta(text,name,password,key)
    assert_equal lat, 45.54
    assert_equal lon, -122.66
  end

  test "geolocating portland with placemaker" do
    text = "Portland, Oregon"
    key = SETTINGS[:yahoo_placemaker_api]
    lat,lon = Geolocate.geolocate_via_placemaker(text,key)
    assert_equal lat, 45.54
    assert_equal lon, -122.66
  end

end
