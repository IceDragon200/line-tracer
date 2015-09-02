require 'minil/color'
require_relative '../core_ext/enumerable'

module LineTracer
  module ColorUtils
    def color_decode(c)
      Minil::Color.decode(c)
    end

    def color_encode(ary)
      Minil::Color.encode(*ary)
    end

    # http://www.cs.rit.edu/~ncs/color/t_convert.html
    def hsv_to_rgb_norm(h, s, v)
      if s == 0
        # full gray
        return v, v, v
      end

      h %= 360
      h /= 60.0      # sector 0 to 5
      i = h.floor
      f = h - i      # factorial part of h
      p = v * ( 1 - s )
      q = v * ( 1 - s * f )
      t = v * ( 1 - s * ( 1 - f ) )

      case i
      when 0
        return v, t, p
      when 1
        return q, v, p
      when 2
        return p, v, t
      when 3
        return p, q, v
      when 4
        return t, p, v
      else
        return v, p, q
      end
    end

    def hsv_to_rgb(h, s, v)
      hsv_to_rgb_norm(h, s, v).map { |f| [[0, f * 255].max, 255].min.to_i }
    end

    def hsv_to_rgba(h, s, v)
      [*hsv_to_rgb(h, s, v), 255]
    end

    def color_clamped(ary)
      ary.map { |c| [[c, 0].max, 255].min }
    end

    def color_blend_per_channel(c1, c2, preserve_alpha = true)
      c = c1.map_with_index { |c, i| yield c, c2[i] }
      c[3] = c1[3] if preserve_alpha
      color_clamped(c)
    end

    def color_blend_per_channel_norm(c1, c2, preserve_alpha = true)
      color_blend_per_channel(c1, c2, preserve_alpha) do |a, b|
        (yield(a / 255.0, b / 255.0) * 255).to_i
      end
    end

    def color_blend_add(c1, c2, preserve_alpha = true)
      color_blend_per_channel(c1, c2, preserve_alpha) { |a, b| a + b }
    end

    def color_blend_avg(c1, c2, preserve_alpha = true)
      color_blend_per_channel(c1, c2, preserve_alpha) { |a, b| (a + b) / 2 }
    end

    def color_blend_sub(c1, c2, preserve_alpha = true)
      color_blend_per_channel(c1, c2, preserve_alpha) { |a, b| a - b }
    end

    def color_blend_mul(c1, c2, preserve_alpha = true)
      color_blend_per_channel(c1, c2, preserve_alpha) { |a, b| a * b / 255 }
    end

    def color_blend_overlay(c1, c2, preserve_alpha = true)
      color_blend_per_channel_norm(c1, c2, preserve_alpha) do |a, b|
        if a < 0.5
          2 * (a * b)
        else
          1 - 2 * (1 - a) * (1 - b)
        end
      end
    end

    def color_blend_alpha(c1, c2, alpha = 255)
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

    extend self
  end
end
