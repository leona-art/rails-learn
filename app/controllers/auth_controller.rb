# app/controllers/auth_controller.rb
class AuthController < ApplicationController
  # Authenticatableモジュールに必要なメソッド（encode_*, decode_*）が含まれていると仮定
  # include Authenticatable # 必要に応じて



  # POST /login
  # ユーザー名とパスワードで認証し、成功したらトークンをCookieに設定
  def create
    user = User.find_by(username: params[:username])

    if user && user.authenticate(params[:password])
      # アクセストークンとリフレッシュトークンを生成
      access_token = encode_access_token(user.id)
      refresh_token = encode_refresh_token(user.id)

      # トークンをHttpOnly Cookieに設定
      set_token_cookies(access_token, refresh_token)


      # レスポンスにはユーザー情報のみを含める (パスワード情報は除外)
      render json: { user: user.as_json(except: [ :password_digest ]) }, status: :ok
    else
      render json: { error: "ユーザー名またはパスワードが違います" }, status: :unauthorized
    end
  end

  # POST /auth/refresh
  # Cookieからリフレッシュトークンを取得し、新しいトークンペアをCookieに設定
  def refresh
    # Cookieからリフレッシュトークンを取得
    token = cookies[:refresh_token]

    unless token
      return render json: { error: "リフレッシュトークンが見つかりません" }, status: :unauthorized
    end

    # リフレッシュトークンをデコード・検証
    decoded_payload = decode_refresh_token(token) # 検証に失敗した場合はnilや例外を返す想定

    if decoded_payload && (user_id = decoded_payload[0]["user_id"]) # decoded_payloadの構造に注意
      user = User.find_by(id: user_id)

      if user
        # 新しいアクセストークンとリフレッシュトークンを発行
        access_token = encode_access_token(user.id)
        refresh_token = encode_refresh_token(user.id)

        # Cookieを新しいトークンで更新
        set_token_cookies(access_token, refresh_token)

        # 成功レスポンス (トークン自体はCookieで送信されるため、JSONには含めない)
        # 必要に応じてユーザー情報などを返す
        render json: { message: "トークンが更新されました", user: user.as_json(except: [ :password_digest ]) }, status: :ok
      else
        # トークンは形式上有効だがユーザーが存在しない場合
        delete_token_cookies # 無効なセッションなのでCookieを削除
        render json: { error: "ユーザーが見つかりません" }, status: :unauthorized
      end
    else
      # リフレッシュトークンが無効または期限切れの場合
      delete_token_cookies # 無効なセッションなのでCookieを削除
      render json: { error: "無効なリフレッシュトークンです" }, status: :unauthorized
    end
  rescue JWT::DecodeError => e # decode_refresh_token が例外を投げる場合
    Rails.logger.error("Refresh token decode error: #{e.message}")
    delete_token_cookies
    render json: { error: "無効なリフレッシュトークンです" }, status: :unauthorized
  end

  # DELETE /auth/logout (ログアウト処理の例)
  # Cookieを削除する
  def destroy
    delete_token_cookies
    render json: { message: "ログアウトしました" }, status: :ok
  end

  private



  # トークンCookieを削除するヘルパーメソッド
  def delete_token_cookies
    cookie_options = {
        httponly: true,
        secure: Rails.env.production?,
        same_site: :lax
      # domain: '.yourdomain.com' # 設定した場合、削除時も同じドメイン指定が必要
    }
    cookies.delete(:access_token, cookie_options)
    cookies.delete(:refresh_token, cookie_options)
  end

  # encode_access_token, encode_refresh_token, decode_refresh_token は
  # 既存のAuthenticatableモジュール等で定義されていることを前提とします。
  # decode_refresh_token は検証（有効期限、署名など）も行う必要があります。
end
