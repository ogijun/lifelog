require "test_helper"

class ApplicationHelperTest < ActionView::TestCase
  test "述語は種類ごとに変わる" do
    assert_equal "読みたい", type_label("wished", "book")
    assert_equal "観た", type_label("did", "film")
    assert_equal "作りたい", type_label("wished", "dish")
    assert_equal "行った", type_label("did", "place")
  end

  test "やめた は種類によらない" do
    assert_equal "やめた", type_label("dropped", "book")
  end

  test "未知の種類は汎用の述語に落ちる" do
    assert_equal "したい", type_label("wished", "album")
  end
end
