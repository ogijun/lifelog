module ApplicationHelper
  KIND_LABELS = { "book" => "本", "film" => "映画", "dish" => "料理", "place" => "店", "video" => "動画" }.freeze
  TYPE_LABELS = { "wished" => "したい", "did" => "した", "dropped" => "やめた" }.freeze
  # 表示上の述語だけを種類ごとに変える。許可するイベント型は種類によらず共通 (DESIGN.md)。
  VERB_LABELS = {
    "book" => { "wished" => "読みたい", "did" => "読んだ" },
    "film" => { "wished" => "観たい", "did" => "観た" },
    "dish" => { "wished" => "作りたい", "did" => "作った" },
    "place" => { "wished" => "行きたい", "did" => "行った" },
    "video" => { "wished" => "見たい", "did" => "見た" }
  }.freeze

  def kind_label(kind) = KIND_LABELS.fetch(kind, kind)
  def type_label(type, kind) = VERB_LABELS.dig(kind, type) || TYPE_LABELS.fetch(type, type)

  # 精度可変の日付 (FuzzyDate)。不明なら time 要素にしない。
  def fuzzy_date_tag(value)
    return tag.span(FuzzyDate.label(nil), class: "unknown-date") if value.nil?

    tag.time FuzzyDate.label(value), datetime: value
  end

  # したいと思ってからの期間。日の精度でなければ期間を言えないので、いつからかだけ言う。
  def wished_since(as_of)
    return "いつからか分からない" if as_of.nil?
    return "#{FuzzyDate.label(as_of)}から" unless as_of.length == 10

    "#{distance_of_time_in_words(Date.iso8601(as_of), Date.current)} 前から"
  end

  # 対象の顔になる画像。無ければ何も出さない。
  def cover_image(subject, css)
    return unless subject.cover.attached?

    image_tag subject.cover, alt: "", class: css, loading: "lazy"
  end

  def rating_stars(rating)
    return if rating.blank?
    tag.span "★" * rating, class: "rating", title: "#{rating}/5"
  end
end
