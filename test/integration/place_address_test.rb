require "test_helper"

class PlaceAddressTest < ActionDispatch::IntegrationTest
  test "店のフォームに住所の欄があり、記録すると external_ids に入る" do
    get new_place_path(subject: { title: "コ本や", address: "東京都新宿区神楽坂1-2-3" })
    assert_select "input[name='subject[address]'][value=?]", "東京都新宿区神楽坂1-2-3"

    post places_path, params: { subject: { title: "コ本や", address: "東京都新宿区神楽坂1-2-3" }, event: { type: "wished", occurred_on: "" } }
    assert_equal "東京都新宿区神楽坂1-2-3", Subject.find_by!(title: "コ本や").external_ids["address"]
  end
end
