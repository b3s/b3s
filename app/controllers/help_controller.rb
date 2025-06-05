# frozen_string_literal: true

class HelpController < ApplicationController
  requires_authentication only: %i[code_of_conduct]

  def index
    redirect_to keyboard_help_url
  end

  def code_of_conduct
    @code_of_conduct = B3S.config.code_of_conduct
  end

  def keyboard; end
end
