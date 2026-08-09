# wished が無限に溜まる問題への対策。
#
# 並びは日付から導出したシードのランダム。その日のうちは同じ並びになり、
# 日が変われば入れ替わる。シードは日付から計算するので保存する状態はゼロ。
module Wishlist
  module_function

  def suggestions(on: Date.current, kind: nil, limit: 7)
    all(kind:).shuffle(random: Random.new(seed_for(on))).first(limit)
  end

  def all(kind: nil)
    CurrentState.with_status("wished").of_kind(kind).order(as_of: :asc).to_a
  end

  def seed_for(date) = date.to_time.to_i
end
