# frozen_string_literal: true

class Absence < ApplicationRecord
  include WebhookDeliverable
  include RecurrenceConcern
  include IcalHelpers::Ics
  include IcalHelpers::Rrule
  include Payloads::Absence
  include Expiration

  auto_strip_attributes :title

  belongs_to :agent
  belongs_to :organisation

  has_many :webhook_endpoints, through: :organisation

  before_validation :set_end_day

  validates :agent, :organisation, :first_day, :title, presence: true
  validate :ends_at_should_be_after_starts_at

  scope :by_starts_at, -> { order(first_day: :desc, start_time: :desc) }
  scope :with_agent, ->(agent) { where(agent_id: agent.id) }

  def ical_uid
    "absence_#{id}@#{BRAND}"
  end

  private

  def set_end_day
    return unless end_day.nil?

    self.end_day = first_day
  end

  def ends_at_should_be_after_starts_at
    return if starts_at.blank? || ends_at.blank?

    errors.add(:ends_time, "doit être après le début.") if starts_at >= ends_at
  end
end
