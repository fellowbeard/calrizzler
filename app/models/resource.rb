class Resource < ApplicationRecord
  belongs_to :account

  validates :name, presence: true
  validates :name, uniqueness: { scope: :account_id }

  before_validation :format_name

  private

  def format_name
    self.name = TextFormatter.titleize(name)
  end
end
