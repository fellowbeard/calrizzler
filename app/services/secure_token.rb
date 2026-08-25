class SecureToken
  def self.generate
    token = SecureRandom.urlsafe_base64(32)

    {
      token: token,
      digest: digest(token),
    }
  end

  def self.digest(token)
    Digest::SHA256.hexdigest(token)
  end
end
