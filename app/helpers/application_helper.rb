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

  # 状態を次に進めるボタンの文言。「見た」のあとは「また見たい」と「もう一度見た」(再読・再訪)。
  def transition_label(type, kind, from:)
    label = type_label(type, kind)
    return label unless from == "did"

    type == "did" ? "もう一度#{label}" : "また#{label}"
  end

  # 精度可変の日時 (FuzzyTimestamp)。不明なら time 要素にしない。
  def fuzzy_date_tag(value)
    return tag.span(FuzzyTimestamp.label(nil), class: "unknown-date") if value.nil?

    tag.time FuzzyTimestamp.label(value), datetime: value
  end

  # したいと思ってからの期間。日の精度でなければ期間を言えないので、いつからかだけ言う。
  def wished_since(as_of)
    return "いつからか分からない" if as_of.nil?
    return "#{FuzzyTimestamp.label(as_of)}から" unless %i[day minute].include?(FuzzyTimestamp.precision(as_of))

    "#{distance_of_time_in_words(Date.iso8601(as_of[0, 10]), Date.current)} 前から"
  end

  # 外部 ID の値。http(s) の URL だけ別タブのリンクにする (javascript: などはリンクにしない)。
  def external_link(value)
    return value unless HttpUrl.valid?(value)

    link_to value, value, target: "_blank", rel: "noopener noreferrer"
  end

  # Google マップで探すリンク (名前や住所で検索する)。地図で店を開いてブックマークレットを押し直せば、
  # 店名と座標まで入る。
  def maps_search_link(*terms)
    query = terms.compact_blank.join(" ")
    return if query.empty?

    link_to "Google マップで探す", "https://www.google.com/maps/search/?api=1&query=#{CGI.escape(query)}",
            target: "_blank", rel: "noopener noreferrer", class: "maps-search"
  end

  # 状態の判子。読んだ・行った (did) は朱の判子、読みたい (wished) は鉛筆の下書き、やめた (dropped) は打ち消し。
  def state_stamp(type, kind, large: false)
    tag.span(type_label(type, kind), class: [ "type", "type-#{type}", "stamp", ("stamp-large" if large) ])
  end

  # 一覧の画像の枠。画像が無くても同じ大きさを取り、種類の1文字を薄く置く (行の高さと文字の位置をそろえる)。
  def cover_thumb(subject)
    cover_image(subject, "thumb") || tag.span(kind_label(subject.kind).first, class: "thumb thumb-empty", "aria-hidden": true)
  end

  # 出どころは長い URL をそのまま出さず、ホスト名で「x.com から」と出す。
  def source_link(url)
    return url unless HttpUrl.valid?(url)

    link_to "#{URI(url).host.delete_prefix('www.')} から", url, target: "_blank", rel: "noopener noreferrer"
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
