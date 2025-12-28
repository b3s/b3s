# frozen_string_literal: true

class ConversationParticipantsController < ApplicationController
  requires_authentication
  requires_user

  before_action :find_conversation
  before_action :find_participant, only: [:destroy]
  before_action :verify_removeable, only: [:destroy]

  def create
    added = add_participants(@conversation, usernames_param)

    if added.any?
      flash[:notice] = t("participants.added", count: added.count)
    else
      flash[:error] = t("participants.none_added")
    end

    redirect_to @conversation
  end

  def destroy
    @conversation.remove_participant(@participant)

    if @participant == current_user
      flash[:notice] = t("conversation.you_have_been_removed")
      redirect_to conversations_url
    else
      flash[:notice] = t("conversation.user_removed", username: @participant.username)
      redirect_to @conversation
    end
  end

  private

  def add_participants(conversation, usernames)
    added = []
    User.where(username: usernames.map(&:strip)).find_each do |user|
      added << user if conversation.add_participant(user)
    end
    added
  end

  def find_conversation
    @conversation = Conversation.find(params[:conversation_id])
    render_error 403 unless @conversation.viewable_by?(current_user)
  end

  def find_participant
    username = params[:id] || params[:username]
    @participant = User.find_by(username:)
    render_error 404 unless @participant
  end

  def usernames_param
    usernames = params[:usernames] || params[:username]
    usernames = usernames.split(/\s*,\s*/) if usernames.is_a?(String)
    usernames
  end

  def verify_removeable
    return if @conversation.removeable_by?(@participant, current_user)

    flash[:error] = t("conversation.not_removeable")
    redirect_to @conversation
  end
end
