module ApplicationHelper
  KIND_LABELS = { "book" => "本", "film" => "映画", "dish" => "料理", "place" => "場所" }.freeze
  TYPE_LABELS = { "wished" => "したい", "did" => "した", "dropped" => "やめた" }.freeze

  def kind_label(kind) = KIND_LABELS.fetch(kind, kind)
  def type_label(type) = TYPE_LABELS.fetch(type, type)

  def rating_stars(rating)
    return if rating.blank?
    tag.span "★" * rating, class: "rating", title: "#{rating}/5"
  end
end
