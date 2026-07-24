# frozen_string_literal: true

require "digest"

class Rack::Attack
  # Allow localhost requests without rate limiting.
  safelist("allow-localhost") do |request|
    ["127.0.0.1", "::1"].include?(request.ip)
  end

  # Limit login attempts to five requests every five minutes per IP address.
  throttle("login-attempts-by-ip", limit: 5, period: 5.minutes) do |request|
    request.ip if request.post? && request.path == "/api/v1/login"
  end

  # Limit unauthenticated API requests by IP address.
  throttle(
    "unauthenticated-api-requests-by-ip",
    limit: 100,
    period: 1.minute
  ) do |request|
    authorization = request.get_header("HTTP_AUTHORIZATION")

    request.ip if request.path.start_with?("/api/") && authorization.blank?
  end

  # Limit authenticated API requests by authorization token.
  throttle(
    "authenticated-api-requests-by-token",
    limit: 500,
    period: 1.minute
  ) do |request|
    authorization = request.get_header("HTTP_AUTHORIZATION")

    Digest::SHA256.hexdigest(authorization) if request.path.start_with?("/api/") && authorization.present?
  end

  # Return a JSON response when a request exceeds its rate limit.
  self.throttled_responder = lambda do |request|
    match_data = request.env.fetch("rack.attack.match_data", {})
    period = match_data.fetch(:period, 60)
    epoch_time = match_data.fetch(:epoch_time, Time.now.to_i)
    retry_after = period - (epoch_time % period)

    [
      429,
      {
        "Content-Type" => "application/json",
        "Retry-After" => retry_after.to_s,
      },
      [
        JSON.generate(
          error: "too_many_requests",
          message: "You have exceeded the rate limit. Please try again later.",
          retry_after_seconds: retry_after
        ),
      ],
    ]
  end
end

Rack::Attack.enabled = !Rails.env.in?(['development', 'test'])

unless Rack::Attack.enabled
  Rails.logger.info(
    "Rack::Attack initialized but disabled in development and test"
  )
end
