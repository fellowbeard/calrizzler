class TextFormatter
  def self.titleize(value)
    NameNormalizer.normalize(value).titleize if value.present?
  end

  def self.capitalize_first(value)
    normalized = NameNormalizer.normalize(value)
    return if normalized.blank?

    normalized[0].upcase + normalized[1..]
  end

  def self.phone_number(value)
    return if value.blank?

    digits = value.gsub(/\D/, "")

    return value unless digits.length == 10

    "(#{digits[0..2]}) #{digits[3..5]}-#{digits[6..9]}"
  end

  def self.email(value)
    value.to_s.strip.downcase.presence
  end
end
