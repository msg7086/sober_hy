require 'chunky_png'

module SoberHy
  class Decoder
    KEY_MAP = {
      0x01C9B463 => 'n', 0x54AEAE1A => 'r', 0xAF2D6B89 => 'h',
      0x14D5978E => 'm', 0x5D2970BF => '7', 0xB807DA49 => 'p',
      0x22A48B6B => 'w', 0x65D52263 => 'f', 0xBD84094C => '9',
      0x2CBC6846 => 'a', 0x665493DF => 't', 0xC0A35B08 => '4',
      0x474812AA => '5', 0x819B4227 => 'k', 0xD80D9A8C => 'y',
      0x525BD604 => 'e', 0x82CB7BE3 => 'j', 0xFA0E1C5F => 'c',
      0x540C91BF => 'x', 0xAEC788C3 => 's', 0xFD05CC2C => '6'
    }.freeze

    EXPECTED_WIDTH = 60
    EXPECTED_HEIGHT = 22
    SAMPLE_X_OFFSETS = [2, 12, 13].freeze

    SEED = 5381
    MIN_MATCH_LEN = 130

    def initialize(image_path_or_blob)
      if image_path_or_blob.encoding == Encoding::BINARY
        @image = ChunkyPNG::Image.from_blob(image_path_or_blob)
      elsif File.exist?(image_path_or_blob)
        @image = ChunkyPNG::Image.from_file(image_path_or_blob)
      else
        @image = ChunkyPNG::Image.from_blob(image_path_or_blob)
      end
    end

    def solve
      verify_dimensions!

      row_bg_colors = scan_row_backgrounds
      stdc = @image[1, 1]

      state = :skip
      current_hash = SEED
      bit_count = 0
      result = String.new

      (1...(EXPECTED_WIDTH - 1)).each do |x|
        (0...EXPECTED_HEIGHT).each do |y|
          pixel_color = @image[x, y]
          bg_color = row_bg_colors[y]

          bit = [bg_color, stdc].include?(pixel_color) ? 0 : 1

          if state == :skip
            next if bit == 0
            state = :match
          end

          current_hash = ((current_hash << 5) + current_hash) + bit
          current_hash &= 0xFFFFFFFF
          bit_count += 1

          if bit_count > MIN_MATCH_LEN
            if (char = KEY_MAP[current_hash])
              result << char

              state = :skip
              current_hash = SEED
              bit_count = 0
            end
          end
        end
      end

      result
    end

    private

    def verify_dimensions!
      unless @image.width == EXPECTED_WIDTH && @image.height == EXPECTED_HEIGHT
        raise ArgumentError, "Image must be exactly #{EXPECTED_WIDTH}x#{EXPECTED_HEIGHT} pixels (got #{@image.width}x#{@image.height})"
      end
    end

    def scan_row_backgrounds
      (0...@image.height).map do |y|
        SAMPLE_X_OFFSETS.map { |x| @image[x, y] }.sort[1]
      end
    end

  end
end
