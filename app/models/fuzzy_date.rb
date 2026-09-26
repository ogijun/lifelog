# 精度が可変の日付。ISO 8601 の精度を落とした文字列 ("2026" / "2026-03" / "2026-03-05") か nil (不明)。
# 精度は桁数そのものなので、日付と精度の2列が食い違うという状態を持たない (DESIGN.md)。
# 文字列のまま並べると「年だけ = その年の初め」になり、SQLite の NULL は最小なので不明はいちばん古い。
module FuzzyDate
  FORMAT = /\A(\d{4})(?:-(\d{2})(?:-(\d{2}))?)?\z/

  module_function

  # フォームの年・月・日から組むだけ。正しさは valid? (Event のバリデーション) が判定する。
  # 粗い欄が空なら細かい欄は無視し、年が空なら不明。
  def from_parts(year:, month:, day:)
    year, month, day = [ year, month, day ].map { |part| part.to_s.strip.presence }
    return unless year
    return year unless month
    return "#{year}-#{pad(month)}" unless day

    "#{year}-#{pad(month)}-#{pad(day)}"
  end

  def from_date(date) = date.iso8601

  SEPARATOR = %r{[/.\-]}
  WORDS = {
    "今日" => ->(today) { from_date(today) },
    "昨日" => ->(today) { from_date(today - 1) },
    "一昨日" => ->(today) { from_date(today - 2) },
    "おととい" => ->(today) { from_date(today - 2) },
    "今月" => ->(today) { today.strftime("%Y-%m") },
    "先月" => ->(today) { today.prev_month.strftime("%Y-%m") },
    "今年" => ->(today) { today.year.to_s },
    "去年" => ->(today) { today.prev_year.year.to_s },
    "昨年" => ->(today) { today.prev_year.year.to_s }
  }.freeze

  # 入力欄に書かれた日付を読み取る。「2026/9/25」「2026年9月」「2026」「9/25」(今年)「20260925」
  # 「今日」「先月」「去年」など。全角も読む。空なら不明 (nil)。
  # 読めないものは書いたまま返し、正しさは valid? (Event のバリデーション) が判定する。
  def parse(text, today: Date.current)
    text = text.to_s.unicode_normalize(:nfkc).strip
    return if text.empty?
    return WORDS[text].call(today) if WORDS.key?(text)

    case text
    when /\A(\d{4})(\d{2})(\d{2})\z/ then join($1, $2, $3)
    when /\A(\d{4})年?\z/ then $1
    when /\A(\d{4})(?:#{SEPARATOR}|年)(\d{1,2})月?\z/ then join($1, $2)
    when /\A(\d{4})(?:#{SEPARATOR}|年)(\d{1,2})(?:#{SEPARATOR}|月)(\d{1,2})日?\z/ then join($1, $2, $3)
    when /\A(\d{1,2})(?:#{SEPARATOR}|月)(\d{1,2})日?\z/ then join(today.year.to_s, $1, $2)
    else text
    end
  end

  # 入力欄に戻すときの書き方。読めない値 (エラーで戻ったとき) は書いたまま。
  def input_value(value)
    year, month, day = parts(value).values
    return value.to_s unless year

    [ year, month, day ].compact.join("/")
  end

  def join(year, *rest) = [ year, *rest.map { pad(it) } ].join("-")

  def valid?(value)
    return true if value.nil?

    match = FORMAT.match(value.to_s) or return false
    year, month, day = match.captures
    return true unless month
    return (1..12).cover?(month.to_i) unless day

    Date.valid_date?(year.to_i, month.to_i, day.to_i)
  end

  def label(value)
    year, month, day = parts(value).values
    return "日付不明" unless year
    return "#{year}年" unless month
    return "#{year}年#{month}月" unless day

    "#{year}年#{month}月#{day}日"
  end

  # フォームに戻すための年・月・日。先頭の 0 は落とす。
  def parts(value)
    year, month, day = FORMAT.match(value.to_s)&.captures
    { year:, month: month&.to_i&.to_s, day: day&.to_i&.to_s }
  end

  def pad(part) = part.match?(/\A\d\z/) ? "0#{part}" : part
end
