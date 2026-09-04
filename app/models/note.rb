class Note < ApplicationRecord
  belongs_to :user
  belongs_to :client

  validates :body, presence: true

  before_validation :format_body

  private

  def format_body
    self.body = TextFormatter.capitalize_first(body)
  end
end