class UsersController < ApplicationController
    def create
        user = User.new(user_params)
        if user.save
          # 登録成功したら JWT を発行して返す

          access_token = encode_access_token(user.id)
          refresh_token = encode_refresh_token(user.id)

          # トークンをHttpOnly Cookieに設定
          set_token_cookies(access_token, refresh_token)

          render json: { user: user }, status: :created
        else
          render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
        end
    end
    private

    def user_params
        params.require(:user).permit(:username, :password, :password_confirmation)
    end
end
