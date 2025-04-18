class ProfileController < ApplicationController
    before_action :authenticate_request! # 認証が必要

    # GET /profile
    def show
        # authenticate_request! で @current_user が設定されている
        render json: { user: current_user }, status: :ok
    end
end
