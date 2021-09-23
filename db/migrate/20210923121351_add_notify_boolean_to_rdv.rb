# frozen_string_literal: true

class AddNotifyBooleanToRdv < ActiveRecord::Migration[6.0]
  def change
    add_column :rdvs, :notify_creation_by_sms, :boolean
    add_column :rdvs, :notify_reminder_by_sms, :boolean
    add_column :rdvs, :notify_creation_by_email, :boolean
    add_column :rdvs, :notify_reminder_by_email, :boolean
  end
end
