class UsersController < ApplicationController
    def create
        user = User.new(user_params)
        if user.save
          # 登録成功したら JWT を発行して返す
          token = encode_token(user.id) # Authenticatable モジュールのメソッド
          render json: { user: user, token: token }, status: :created
        else
          render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
        end
    end
    private

    def user_params
        params.require(:user).permit(:username, :password, :password_confirmation)
    end
end
