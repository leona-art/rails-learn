# app/controllers/concerns/authenticatable.rb
module Authenticatable
    # トークン生成
    def encode_token(user_id)
      # 有効期限を設定することも可能 (例: 24時間後)
      # expires_in = 24.hours.from_now.to_i
      payload = { user_id: user_id }
      JWT.encode(payload, Rails.application.credentials.secret_key_base) # シークレットキーは環境変数または credentials に保存
    end

    # リクエストヘッダーからトークン取得
    def auth_header
      request.headers["Authorization"]
    end

    # トークン検証
    def decode_token
      if auth_header
        token = auth_header.split(" ")[1] # "Bearer token" の "token" 部分を取得
        begin
          JWT.decode(token, Rails.application.credentials.secret_key_base, true, algorithm: "HS256")
        rescue JWT::DecodeError
          nil
        end
      end
    end

    # 現在のユーザーを取得
    def current_user
      if decoded_token = decode_token
        user_id = decoded_token[0]["user_id"]
        @current_user ||= User.find_by(id: user_id)
      end
    end

    # 認証が必要なアクションの前で呼び出す
    def authenticate_request!
      unless current_user
        render json: { message: "認証が必要です" }, status: :unauthorized
      end
    end
end
