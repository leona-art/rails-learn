# app/controllers/concerns/authenticatable.rb
module Authenticatable
    # アクセストークンの有効期限 (例: 30分)
    ACCESS_TOKEN_EXPIRATION = 30.minutes.from_now.to_i

    # リフレッシュトークンの有効期限 (例: 7日)
    REFRESH_TOKEN_EXPIRATION = 7.days.from_now.to_i

    # トークンの有効期限を設定 (例)
    ACCESS_TOKEN_EXPIRY = 15.minutes
    REFRESH_TOKEN_EXPIRY = 7.days

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
    # アクセストークンのデコード・検証 (Cookieから取得)
    def decode_access_token
      # requestオブジェクトからcookiesヘルパーメソッドを使ってCookieを取得
      token = cookies[:access_token] # Cookie名 'access_token' から値を取得
       if token
         puts "Token: #{token}" # デバッグ用にトークンを表示
       else
          puts "Token not found in cookies" # Cookieが存在しない場合
          puts cookies.inspect # Cookieの内容を表示
          Rails.logger.warn "Access Token not found in cookies"
       end

      if token
        begin
          # トークン文字列を直接デコード（Bearerプレフィックスは不要）
          JWT.decode(token, Rails.application.credentials.secret_key_base, true, algorithm: "HS256")
        rescue JWT::DecodeError => e
          Rails.logger.warn "Access Token Decode Error: #{e.message}"
          nil # 不正なトークンや期限切れの場合はnilを返す
        end
      else
        # Cookieが存在しない場合はnilを返す
        nil
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

    # トークンをCookieに設定するヘルパーメソッド
    def set_token_cookies(access_token, refresh_token)
      # ★★★ テスト用Cookieを追加 ★★★
      cookies[:test_cookie] = { value: "test_value_123", httponly: true, path: "/" }
      puts "Set test_cookie: #{cookies[:test_cookie]}"
      # ★★★ テスト用ここまで ★★★

      # 本番環境でのみSecure属性を付与、HttpOnlyは常に付与、SameSiteはLax推奨
      # domain属性はNext.jsアプリとAPIのドメインが異なる場合に設定が必要な場合があります
      cookie_options = {
        httponly: true,
        secure: Rails.env.production?,
        same_site: :lax, # または :strict
        path: "/"
        # domain: '.yourdomain.com' # 必要に応じて設定
      }

      cookies[:access_token] = { value: access_token, expires: ACCESS_TOKEN_EXPIRY.from_now }.merge(cookie_options)
      cookies[:refresh_token] = { value: refresh_token, expires: REFRESH_TOKEN_EXPIRY.from_now }.merge(cookie_options)
      puts "Set access_token: #{cookies[:access_token]}" # デバッグ用
    puts "Set refresh_token: #{cookies[:refresh_token]}" # デバッグ用
    end
end
