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
    # @param [Integer] h  hue
    # @param [Float] s  saturation
    # @param [Float] v  value
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

    def blender
      ColorBlender.instance
    end

    extend self
  end
end
