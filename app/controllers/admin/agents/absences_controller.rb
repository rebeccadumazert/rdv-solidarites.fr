# frozen_string_literal: true

class Admin::Agents::AbsencesController < ApplicationController
  include Admin::AuthenticatedControllerConcern
  respond_to :json

  def index
    agent = Agent.find(params[:agent_id])
    @organisation = Organisation.find(params[:organisation_id])
    @absence_occurrences = policy_scope_admin(Absence)
      .includes(:organisation)
      .where(agent: agent)
      .all_occurrences_for(date_range_params)
  end

  private

  def date_range_params
    start_param = Date.parse(params[:start])
    end_param = Date.parse(params[:end])
    start_param..end_param
  end

  def pundit_user
    AgentContext.new(current_agent)
  end
end
