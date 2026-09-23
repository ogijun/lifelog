module ApplicationHelper
  KIND_LABELS = { "book" => "本", "film" => "映画", "dish" => "料理", "place" => "場所" }.freeze
  TYPE_LABELS = { "wished" => "したい", "did" => "した", "dropped" => "やめた" }.freeze
  # 表示上の述語だけを種類ごとに変える。許可するイベント型は種類によらず共通 (DESIGN.md)。
  VERB_LABELS = {
    "book" => { "wished" => "読みたい", "did" => "読んだ" },
    "film" => { "wished" => "観たい", "did" => "観た" },
    "dish" => { "wished" => "作りたい", "did" => "作った" },
    "place" => { "wished" => "行きたい", "did" => "行った" }
  }.freeze

  def kind_label(kind) = KIND_LABELS.fetch(kind, kind)
  def type_label(type, kind) = VERB_LABELS.dig(kind, type) || TYPE_LABELS.fetch(type, type)

  def rating_stars(rating)
    return if rating.blank?
    tag.span "★" * rating, class: "rating", title: "#{rating}/5"
  end
end
