# 主キー。11 文字の base58 で約 64 ビット (YouTube の動画 ID と同じ規模)。
# ランダムなので、オフラインで採番でき、後から合流でき、連番という「次の値」の状態を持たない。
# base58 は見間違えやすい 0 O I l と記号を含まないので URL に出しても読みやすい。
# 衝突は主キーの一意制約で守る。
module ShortId
  LENGTH = 11
  FORMAT = /\A[1-9A-HJ-NP-Za-km-z]{#{LENGTH}}\z/

  module_function

  def generate = SecureRandom.base58(LENGTH)
end
