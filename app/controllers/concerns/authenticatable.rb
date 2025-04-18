# app/controllers/concerns/authenticatable.rb
module Authenticatable
    # アクセストークンの有効期限 (例: 30分)
    ACCESS_TOKEN_EXPIRATION = 30.minutes.from_now.to_i

    # リフレッシュトークンの有効期限 (例: 7日)
    REFRESH_TOKEN_EXPIRATION = 7.days.from_now.to_i

    # アクセストークン生成
    def encode_access_token(user_id)
      payload = {
        user_id: user_id,
        exp: ACCESS_TOKEN_EXPIRATION # 有効期限を追加
      }
      JWT.encode(payload, Rails.application.credentials.secret_key_base, "HS256")
    end

    # アクセストークンのデコード・検証
    # 期限切れの場合は JWT::ExpiredSignature エラーが発生する
    def decode_access_token
      if auth_header
        token = auth_header.split(" ")[1] # "Bearer token" の "token" 部分を取得
        begin
          # デコード時に有効期限も検証される
          JWT.decode(token, Rails.application.credentials.secret_key_base, true, algorithm: "HS256")
        rescue JWT::DecodeError => e
          # デコード失敗または期限切れの場合は nil を返す
          # 必要であれば JWT::ExpiredSignature とその他のエラーでハンドリングを分ける
          Rails.logger.warn "JWT Decode Error: #{e.message}" # デバッグ用にログ出力
          nil
        end
      end
    end

    # リフレッシュトークン生成
    def encode_refresh_token(user_id)
      payload = {
        user_id: user_id,
        exp: REFRESH_TOKEN_EXPIRATION # 有効期限を追加
      }
      JWT.encode(payload, Rails.application.credentials.secret_key_base, "HS256")
    end

    # リフレッシュトークンのデコード・検証 (authenticate_request! とは別に使う)
    # こちらも期限切れの場合は JWT::ExpiredSignature エラーが発生する
    def decode_refresh_token(token)
      begin
        # デコード時に有効期限も検証される
        JWT.decode(token, Rails.application.credentials.secret_key_base, true, algorithm: "HS256")
      rescue JWT::DecodeError => e
        # デコード失敗または期限切れの場合は nil を返す
        Rails.logger.warn "Refresh Token Decode Error: #{e.message}" # デバッグ用にログ出力
        nil
      end
    end

    # リクエストヘッダーからトークン取得
    def auth_header
      request.headers["Authorization"]
    end

    # 現在のユーザーを取得 (アクセストークンに基づく)
    def current_user
      # decode_access_token が成功した場合のみ実行
      if decoded_token = decode_access_token
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
