require_relative '../core_ext/enumerable'

module LineTracer
  module MathUtils
    def lerp(a, b, d)
      a + (b - a) * d
    end

    def lerp_a(a, b, d)
      a.map_with_index do |x, i|
        lerp(x, b[i], d)
      end
    end

    def diff_a(a, b)
      a.map_with_index do |x, i|
        b[i] - x
      end
    end

    extend self
  end
end
