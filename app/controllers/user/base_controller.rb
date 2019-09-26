# frozen_string_literal: true

class User::BaseController < ApplicationController
  include User::SessionHelper
  include User::VerificationHelper

  layout "user/layouts/application"

  private

  def read_only_user_attributes
    return [] unless auth_modules_present?

    @read_only_user_attributes ||= current_site.configuration.auth_modules_data.inject([]) do |attributes, auth_module|
      attributes | (auth_module.read_only_user_attributes || [])
    end
  end
end
