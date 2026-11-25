# frozen_string_literal: true

module AccountLogo
  extend ActiveSupport::Concern

  ALLOWED_LOGO_CONTENT_TYPES = %w[image/png image/jpeg image/webp image/svg+xml].freeze
  LOGO_MAX_SIZE = 5.megabytes

  included do
    has_one_attached :logo
    validate :acceptable_logo, if: -> { logo.attached? && logo.changed? }
  end

  def logo_url
    return unless logo.attached?

    Rails.application.routes.url_helpers.rails_blob_path(logo, only_path: true)
  end

  private

  def acceptable_logo
    errors.add(:logo, 'is too big') if logo.byte_size > LOGO_MAX_SIZE
    return if ALLOWED_LOGO_CONTENT_TYPES.include?(logo.content_type)

    errors.add(:logo, 'filetype not supported')
  end
end
