class ApplicationController < ActionController::API
    include Authenticatable # 認証モジュールをインクルード
    include ActionController::Cookies # Cookie操作のために必要
end
