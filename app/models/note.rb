class Note < ApplicationRecord
  belongs_to :user
  belongs_to :client

  validates :body, presence: true
  validate :user_and_client_must_belong_to_same_account

  before_validation :format_body

  private

  def format_body
    self.body = TextFormatter.capitalize_first_preserving_whitespace(body)
  end

  def user_and_client_must_belong_to_same_account
    return if user.blank? || client.blank?
    return if user.account_id == client.account_id

    errors.add(:client, 'must belong to the same account as the user')
  end
end
