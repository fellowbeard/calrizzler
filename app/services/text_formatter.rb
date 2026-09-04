class TextFormatter
  def self.titleize(value)
    NameNormalizer.normalize(value).titleize if value.present?
  end

  def self.capitalize_first(value)
    normalized = NameNormalizer.normalize(value)
    return if normalized.blank?

    normalized[0].upcase + normalized[1..]
  end
end
