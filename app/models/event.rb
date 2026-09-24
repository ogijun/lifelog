# 遷移イベント。現在の状態はこの列の最新から導出する (current_state ビュー)。
#
# type だけが追記のみ。状態の変化は追記で表すので、遷移の種類は後から変更させない。
# occurred_on (精度可変の日付、FuzzyDate) / rating / note は普通に UPDATE してよい。
# 日付を直すと並び順が変わって状態が変わりうるが、状態は current_state ビューの導出なので整合する。
class Event < ApplicationRecord
  # `type` は STI の予約カラムだが、DDL の語彙に忠実であることを優先する。
  self.inheritance_column = nil

  TYPES = %w[wished did dropped].freeze
  IMMUTABLE = %w[type].freeze
  # 登録ミスの取り消しを許す期間。過ぎたら追記のみに戻る。
  UNDO_WINDOW = 1.hour

  belongs_to :subject
  belongs_to :cause, class_name: "Event", foreign_key: :caused_by, optional: true
  has_many :effects, class_name: "Event", foreign_key: :caused_by, dependent: :nullify

  # フォームの「きっかけ: —」は空文字を送る。そのままだと FK 制約に落ちる。
  normalizes :caused_by, with: ->(id) { id.presence }

  validates :type, inclusion: { in: TYPES }
  validate :occurred_on_is_fuzzy_date
  validates :rating, numericality: { in: 1..5 }, allow_nil: true
  validate :transition_is_append_only, on: :update

  before_create { self.id ||= ShortId.generate }

  def undoable?(now: Time.current) = created_at > now - UNDO_WINDOW

  private

  def occurred_on_is_fuzzy_date
    return if FuzzyDate.valid?(occurred_on)

    errors.add(:occurred_on, "は「2019」「2019-05」「2019-05-03」の形の、暦にある日付にしてください")
  end

  def transition_is_append_only
    IMMUTABLE.each do |attr|
      errors.add(attr, "は後から変更できません") if send(:"#{attr}_changed?")
    end
  end
end
