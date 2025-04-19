# config/initializers/cors.rb

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    # Next.js アプリケーションのオリジンを正確に指定
    origins "http://localhost:3001"

    resource "*",
      headers: :any,
      methods: [ :get, :post, :put, :patch, :delete, :options, :head ],
      # ★★★ credentials: true が重要 ★★★
      # これにより、オリジン間リクエストでCookieを含むヘッダー(Set-Cookie含む)の送受信が許可される
      credentials: true,
      # ★★★ expose オプションを追加してみる ★★★
      # Set-Cookieヘッダーを明示的に公開する必要があるか試す (通常は不要だが念のため)
      expose: [ "Set-Cookie" ]
  end
end
