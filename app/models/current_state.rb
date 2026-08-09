# current_state ビューの読み取り専用モデル。
# 「最新イベントが現在の状態」という導出の複雑性はビュー1箇所に閉じ込め、
# アプリ側は基本的にここを読む。
class CurrentState < ApplicationRecord
  self.table_name = "current_state"
  self.primary_key = "id"

  belongs_to :subject, foreign_key: :id

  scope :with_status, ->(status) { where(status:) }
  scope :of_kind, ->(kind) { kind.present? ? where(kind:) : all }

  def readonly? = true
end
