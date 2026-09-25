require "test_helper"

class TypeFieldsTest < ActionDispatch::IntegrationTest
  test "記録フォームの状態は「どうなった」の選択肢が全部見える形で出る" do
    { new_book_path => %w[読みたい 読んだ やめた], new_video_path => %w[見たい 見た やめた] }.each do |path, labels|
      get path
      assert_select "fieldset.type-choice legend", "どうなった"
      assert_select "fieldset.type-choice input[type=radio][name='event[type]']", 3
      labels.each { |label| assert_select "fieldset.type-choice label", label }
      assert_select "fieldset.type-choice input[type=radio][value=wished][checked]"
    end
  end

  test "詳細ページの記録フォームも「どうなった」で、見出しは役割が分かるもの" do
    s = Subject.create!(kind: "place", title: "芦屋の割烹")
    Event.create!(subject: s, type: "wished", occurred_on: "2026")

    get subject_path(s)
    assert_select "h3", "日付や評価をつけて記録する"
    assert_select "fieldset.type-choice legend", "どうなった"
    assert_select "fieldset.type-choice input[type=radio][value=did][checked]"
  end
end
