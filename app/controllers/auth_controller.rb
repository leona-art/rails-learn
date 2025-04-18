class AuthController < ApplicationController
    def create
        user = User.find_by(username: params[:username])
        if user && user.authenticate(params[:password])
          # 認証成功したら アクセストークン と リフレッシュトークン の両方を発行
          access_token = encode_access_token(user.id) # Authenticatable モジュールのメソッド
          refresh_token = encode_refresh_token(user.id) # Authenticatable モジュールのメソッド

          render json: {
            user: user,
            access_token: access_token,
            refresh_token: refresh_token
          }, status: :ok
        else
          render json: { error: "ユーザー名またはパスワードが違います" }, status: :unauthorized # username に変更した場合はメッセージも修正
        end
    end

    # リフレッシュトークンを受け取り、新しいアクセストークンとリフレッシュトークンを返す
    def refresh
      # リクエストボディからリフレッシュトークンを取得することを想定
      # 例: { "refresh_token": "..." }
      token = params[:refresh_token]

      # リフレッシュトークンをデコード・検証
      if decoded_token = decode_refresh_token(token) # Authenticatable モジュールのメソッド
        user_id = decoded_token[0]["user_id"]
        user = User.find_by(id: user_id)

        if user
          # リフレッシュトークンが有効なユーザーに対応していれば、新しいトークンペアを発行
          access_token = encode_access_token(user.id)
          refresh_token = encode_refresh_token(user.id)

          render json: {
            user: user,
            access_token: access_token,
            refresh_token: refresh_token
          }, status: :ok
        else
          # トークンは有効だがユーザーが見つからない場合 (例えばユーザーが削除された)
          render json: { error: "\u30E6\u30FC\u30B6\u30FC\u304C\u898B\u3064\u304B\u308A\u307E\u305B\u3093" }, status: :unauthorized
        end
      else
        # リフレッシュトークンが無効または期限切れの場合
        render json: { error: "\u7121\u52B9\u306A\u30EA\u30D5\u30EC\u30C3\u30B7\u30E5\u30C8\u30FC\u30AF\u30F3\u3067\u3059" }, status: :unauthorized
      end
    end
end
