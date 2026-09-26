require "test_helper"

class ExternalIdsTest < ActionDispatch::IntegrationTest
  def show(external_ids)
    s = Subject.create!(kind: "dish", title: "鯛の子の煮付け", external_ids:)
    Event.create!(subject: s, type: "wished", occurred_on: "2026")
    get subject_path(s)
  end

  test "http(s) の URL は別タブで開くリンクにし、リファラは送らない" do
    show("recipe_url" => "https://www.kyounoryouri.jp/recipe/600001_x.html")
    assert_select ".external-ids a[href='https://www.kyounoryouri.jp/recipe/600001_x.html'][target=_blank][rel~=noreferrer]",
                  "https://www.kyounoryouri.jp/recipe/600001_x.html"
  end

  test "URL でない値や http(s) でない URL はリンクにしない" do
    show("isbn" => "9784101005058", "url" => "javascript:alert(1)")
    assert_select ".external-ids a", 0
    assert_select ".external-ids dd", "9784101005058"
    assert_select ".external-ids dd", "javascript:alert(1)"
  end
end
