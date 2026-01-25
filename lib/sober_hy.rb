require 'open-uri'
require_relative "sober_hy/version"
require_relative "sober_hy/decoder"

module SoberHy
  class Error < StandardError; end

  # Solves the captcha from a given URL or file path.
  #
  # @param source [String] URL or file path to the captcha image.
  # @return [String] The recognized 5-character string.
  def self.solve(source)
    content = if source =~ /\Ahttps?:\/\//
                URI.open(source) { |f| f.binmode; f.read }.force_encoding(Encoding::BINARY)
              else
                source # Assume file path, handled by Decoder
              end
    
    Decoder.new(content).solve
  end
end
