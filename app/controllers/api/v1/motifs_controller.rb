# frozen_string_literal: true

class Api::V1::MotifsController < Api::V1::BaseController
  def index
    motifs = policy_scope(Motif)
    motifs = motifs.active(params[:active].to_b) unless params[:active].nil?

    motifs = motifs.where(reservable_online: params[:reservable_online].to_b) unless params[:reservable_online].nil?

    render_collection(motifs.order(:id))
  end
end
