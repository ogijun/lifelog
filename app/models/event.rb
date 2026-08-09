# 遷移イベント。現在の状態はこの列の最新から導出する (current_state ビュー)。
#
# type と occurred_on だけが追記のみ。時系列上の意味が壊れるため後から変更させない。
# rating / note は最新の判断だけあればよいので普通に UPDATE してよい。
class Event < ApplicationRecord
  # `type` は STI の予約カラムだが、DDL の語彙に忠実であることを優先する。
  self.inheritance_column = nil

  TYPES = %w[wished did dropped].freeze
  IMMUTABLE = %w[type occurred_on].freeze

  belongs_to :subject
  belongs_to :cause, class_name: "Event", foreign_key: :caused_by, optional: true
  has_many :effects, class_name: "Event", foreign_key: :caused_by, dependent: :nullify

  validates :type, inclusion: { in: TYPES }
  validates :occurred_on, presence: true
  validates :rating, numericality: { in: 1..5 }, allow_nil: true
  validate :transition_is_append_only, on: :update

  before_create { self.id ||= SecureRandom.uuid }

  private

  def transition_is_append_only
    IMMUTABLE.each do |attr|
      errors.add(attr, "は後から変更できません") if send(:"#{attr}_changed?")
    end
  end
end
