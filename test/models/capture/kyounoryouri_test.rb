require "test_helper"

class Capture::KyounoryouriTest < ActiveSupport::TestCase
  # 形式は 2026-09 に実物で確認した。料理名と講師名は架空。
  URL = "https://www.kyounoryouri.jp/recipe/600001_%E9%AF%9B%E3%81%AE%E5%AD%90%E3%81%AE%E7%85%AE%E4%BB%98%E3%81%91.html"

  def recognize(url, title) = Capture::Kyounoryouri.call(url:, title:)

  test "料理名と講師名を取り、URL はレシピ URL に入れる" do
    hit = recognize("#{URL}?utm_source=x#step", "鯛の子の煮付け レシピ 山田 花子さん｜みんなのきょうの料理")
    assert_equal "dish", hit.kind
    assert_equal({ title: "鯛の子の煮付け", creator: "山田 花子", recipe_url: URL }, hit.subject)
  end

  test "講師名が無ければ料理名だけ" do
    assert_equal({ title: "鯛の子の煮付け", recipe_url: URL },
                 recognize(URL, "鯛の子の煮付け レシピ｜みんなのきょうの料理").subject)
  end

  test "タイトルの形が崩れていたら末尾のサイト名だけ外す" do
    assert_equal "鯛の子の煮付け", recognize(URL, "鯛の子の煮付け｜みんなのきょうの料理").subject[:title]
  end

  test "レシピのページでなければ nil" do
    assert_nil recognize("https://www.kyounoryouri.jp/search/recipe?keyword=x", "検索｜みんなのきょうの料理")
    assert_nil recognize("https://evil.example/recipe/600001_x.html", "x レシピ｜みんなのきょうの料理")
  end
end
