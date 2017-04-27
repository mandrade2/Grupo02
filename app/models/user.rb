# == Schema Information
#
# Table name: users
#
#  id                     :integer          not null, primary key
#  name                   :string
#  role                   :string
#  email                  :string           default(""), not null
#  encrypted_password     :string           default(""), not null
#  reset_password_token   :string
#  reset_password_sent_at :datetime
#  remember_created_at    :datetime
#  sign_in_count          :integer          default("0"), not null
#  current_sign_in_at     :datetime
#  last_sign_in_at        :datetime
#  current_sign_in_ip     :inet
#  last_sign_in_ip        :inet
#  confirmation_token     :string
#  confirmed_at           :datetime
#  confirmation_sent_at   :datetime
#  unconfirmed_email      :string
#  failed_attempts        :integer          default("0"), not null
#  unlock_token           :string
#  locked_at              :datetime
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  username               :string
#

class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  after_initialize :set_defaults
  devise :database_authenticatable, :registerable, :recoverable,
         :rememberable, :trackable, :validatable, :confirmable, :lockable
  validates :username, presence: true, uniqueness: true,
                       length: { minimum: 6, maximum: 50 }
  validates :name, presence: true,
                   format: { with: /\A[a-z '-]+\z/i,
                             message: 'Nombre debe estar compuesto solo
                                      por letras, espacios, guiones y
                                      apostrofes.' },
                   length: { minimum: 2, maximum: 50 }
  validates :role, inclusion: { in: %w[admin user child],
                                message: '%{value} no es un rol valido' }

  def admin?
    role == 'admin'
  end

  def user?
    role == 'user'
  end

  private

  def set_defaults
    self.role = 'admin'
  end
end
