# みんなのきょうの料理のレシピページ。タイトルは「料理名 レシピ 講師名さん｜みんなのきょうの料理」。
module Capture
  module Kyounoryouri
    RECIPE = %r{\A(https://www\.kyounoryouri\.jp/recipe/\d+_[^/?#]*\.html)}
    SUFFIX = "｜みんなのきょうの料理".freeze
    TITLE = /\A(.+?) レシピ(?: (.+)さん)?\z/

    module_function

    def call(url:, title:)
      recipe = RECIPE.match(url) or return
      name = title.delete_suffix(SUFFIX)
      name, creator = TITLE.match(name)&.captures || [ name ]
      Hit.new(kind: "dish", subject: { title: name, creator:, recipe_url: recipe[1] }.compact_blank)
    end
  end
end
