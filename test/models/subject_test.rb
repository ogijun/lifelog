require "test_helper"

class SubjectTest < ActiveSupport::TestCase
  test "id は UUID が自動採番される" do
    s = Subject.create!(kind: "book", title: "細雪")
    assert_match(/\A[0-9a-f-]{36}\z/, s.id)
  end

  test "kind は book / film / dish / place のみ" do
    assert_not Subject.new(kind: "album", title: "x").valid?
    assert Subject.new(kind: "place", title: "x").valid?
  end

  test "external_ids は JSON として往復する" do
    s = Subject.create!(kind: "book", title: "細雪", external_ids: { "isbn" => "9784101005058" })
    assert_equal "9784101005058", s.reload.external_ids["isbn"]
  end

  test "external_ids は未指定なら空ハッシュ" do
    assert_equal({}, Subject.create!(kind: "dish", title: "鯛の酒蒸し").reload.external_ids)
  end
end
