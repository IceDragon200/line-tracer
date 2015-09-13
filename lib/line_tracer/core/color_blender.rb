require_relative '../utils/color_utils'

module LineTracer
  class ColorBlender
    include ColorUtils

    def per_channel(c1, c2, preserve_alpha = true)
      c = c1.map_with_index { |c, i| yield c, c2[i] }
      c[3] = c1[3] if preserve_alpha
      color_clamped(c)
    end

    def per_channel_norm(c1, c2, preserve_alpha = true)
      per_channel(c1, c2, preserve_alpha) do |a, b|
        (yield(a / 255.0, b / 255.0) * 255).to_i
      end
    end

    def add(c1, c2, preserve_alpha = true)
      per_channel(c1, c2, preserve_alpha) { |a, b| a + b }
    end

    def avg(c1, c2, preserve_alpha = true)
      per_channel(c1, c2, preserve_alpha) { |a, b| (a + b) / 2 }
    end

    def sub(c1, c2, preserve_alpha = true)
      per_channel(c1, c2, preserve_alpha) { |a, b| a - b }
    end

    def mul(c1, c2, preserve_alpha = true)
      per_channel(c1, c2, preserve_alpha) { |a, b| a * b / 255 }
    end

    def overlay(c1, c2, preserve_alpha = true)
      per_channel_norm(c1, c2, preserve_alpha) do |a, b|
        if a < 0.5
          2 * (a * b)
        else
          1 - 2 * (1 - a) * (1 - b)
        end
      end
    end

    def alpha(c1, c2, alpha = 255)
      r1, g1, b1, a1 = color_decode(c1)
      r2, g2, b2, a2 = color_decode(c2)
      beta = (a2 * alpha) >> 8
      [
        [[r1 + (((r2 - r1) * beta) >> 8), 255].min, 0].max << 16,
        [[g1 + (((g2 - g1) * beta) >> 8), 255].min, 0].max <<  8,
        [[b1 + (((b2 - b1) * beta) >> 8), 255].min, 0].max <<  0,
        (beta > a1 ? beta : a1) << 24
      ]
    end

    def self.instance
      @instance ||= new
    end
  end
end
