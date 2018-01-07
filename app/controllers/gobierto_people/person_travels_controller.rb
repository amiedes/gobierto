module GobiertoPeople
  class PersonTravelsController < GobiertoPeople::ApplicationController

    before_action :check_active_submodules

    def index
      redirect_to travels_service_url and return if travels_service_url.present?

      redirect_back(fallback_location: root_path, notice: t(".error"))
    end

    private

    def check_active_submodules
      if !statements_submodule_active?
        redirect_to gobierto_people_root_path
      end
    end
  end
end
