# frozen_string_literal: true

# Base class for all Sms sent to Users
class Users::BaseSms < ApplicationSms
  def initialize(rdv, user)
    super

    @phone_number = user.phone_number_formatted

    @provider = rdv.organisation&.territory&.sms_provider
    @key = rdv.organisation&.territory&.sms_configuration

    @tags = [
      ENV["APP"]&.gsub("-rdv-solidarites", ""), # shorter names
      "dpt-#{rdv.organisation&.departement_number}",
      "org-#{rdv.organisation&.id}",
      self.class.name.demodulize.underscore
    ].compact
  end
end
