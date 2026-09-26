# イベントの「出どころ」。どこでそれを知ったか (ブログや投稿の URL)。
# 対象そのものの URL (subjects.external_ids) とは別に、体験ごとに持つ。
class AddSourceUrlToEvents < ActiveRecord::Migration[8.1]
  def change
    add_column :events, :source_url, :string
  end
end
