# frozen_string_literal: true

class Admin::ReferentsController < AgentAuthController
  def index
    @user = policy_scope(User).find(params[:user_id])
    authorize(@user, :update?)
    @referents = policy_scope(@user.agents).distinct.order(:last_name)
    @agents = policy_scope(Agent)
    @agents = @agents.search_by_text(params[:search]) if params[:search].present?
  end

  def create
    find_agent_and_user_save_and_redirect_with(params) do |user, agent|
      user.agents << agent
    end
  end

  def destroy
    find_agent_and_user_save_and_redirect_with(params) do |user, agent|
      user.agents.delete(agent)
    end
  end

  def find_agent_and_user_save_and_redirect_with(params)
    user = policy_scope(User).find(params[:user_id])
    authorize(user, :update?)
    agent = policy_scope(Agent).find(params[:agent_id]) if params[:agent_id]
    agent ||= policy_scope(Agent).find(params[:id])

    yield(user, agent)

    flash[:error] = user.errors.full_messages.join(", ") unless user.save
    redirect_to admin_organisation_user_referents_path(current_organisation, user)
  end
end
