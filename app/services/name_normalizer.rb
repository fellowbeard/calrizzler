# app/services/name_normalizer.rb

class NameNormalizer
  ONES = {
    'zero' => 0,
    'one' => 1,
    'two' => 2,
    'three' => 3,
    'four' => 4,
    'five' => 5,
    'six' => 6,
    'seven' => 7,
    'eight' => 8,
    'nine' => 9,
    'ten' => 10,
    'eleven' => 11,
    'twelve' => 12,
    'thirteen' => 13,
    'fourteen' => 14,
    'fifteen' => 15,
    'sixteen' => 16,
    'seventeen' => 17,
    'eighteen' => 18,
    'nineteen' => 19,
  }.freeze

  TENS = {
    'twenty' => 20,
    'thirty' => 30,
    'forty' => 40,
    'fifty' => 50,
    'sixty' => 60,
    'seventy' => 70,
    'eighty' => 80,
    'ninety' => 90,
  }.freeze

  def self.normalize(text)
    new(text).normalize
  end

  def initialize(text)
    @words = text.to_s.strip.tr('-', ' ').split
    @index = 0
  end

  def normalize
    normalized_words = []

    while current_word
      normalized_words << normalized_current_value
      advance_index
    end

    normalized_words.join(' ')
  end

  private

  def normalized_current_value
    return '100' if one_hundred?
    return compound_tens_value if compound_tens?
    return TENS[current_word].to_s if TENS.key?(current_word)
    return ONES[current_word].to_s if ONES.key?(current_word)

    current_word
  end

  def advance_index
    @index += compound_value? ? 2 : 1
  end

  def compound_value?
    one_hundred? || compound_tens?
  end

  def one_hundred?
    current_word == 'one' && next_word == 'hundred'
  end

  def compound_tens?
    TENS.key?(current_word) && ONES.key?(next_word) && ONES[next_word].between?(1, 9)
  end

  def compound_tens_value
    (TENS[current_word] + ONES[next_word]).to_s
  end

  def current_word
    @words[@index]
  end

  def current_word_key
    current_word&.downcase
  end

  def next_word
    @words[@index + 1]
  end

  def next_word_key
    next_word&.downcase
  end
end
