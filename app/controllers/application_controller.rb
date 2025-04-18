class ApplicationController < ActionController::API
    include Authenticatable # 認証モジュールをインクルード
end
