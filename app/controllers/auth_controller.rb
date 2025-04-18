class AuthController < ApplicationController
    def create
        user = User.find_by(username: params[:username])
        if user && user.authenticate(params[:password]) # bcrypt の authenticate メソッド
          # 認証成功したら JWT を発行して返す
          token = encode_token(user.id) # Authenticatable モジュールのメソッド
          render json: { user: user, token: token }, status: :ok
        else
          render json: { error: "メールアドレスまたはパスワードが違います" }, status: :unauthorized
        end
    end
end
