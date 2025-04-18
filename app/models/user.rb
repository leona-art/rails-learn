class User < ApplicationRecord
    has_secure_password

    validates :username, presence: true, uniqueness: true
    validates :password, presence: true, length: { minimum: 6 }, on: :create # 登録時のみパスワード必須
end
