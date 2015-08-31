require 'minil/color'

module LineTracer
  module ColorUtils
    # http://www.cs.rit.edu/~ncs/color/t_convert.html
    def hsv_to_rgb_norm(h, s, v)
      if s == 0
        # full gray
        return v, v, v
      end

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

    def color_encode(ary)
      Minil::Color.encode(*ary)
    end
  end
end
