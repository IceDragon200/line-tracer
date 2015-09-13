module LineTracer
  module PointsTransform
    def round_points(points)
      points.map { |point| point.map(&:round) }
    end

    def int_points(points)
      points.map { |point| point.map(&:to_i) }
    end

    def translate_point(point, x, y)
      [point[0] + x, point[1] + y]
    end

    def translate_points(points, x, y)
      points.map { |point| translate_point(point, x, y) }
    end

    def rotate_points_cw(points, cw, ch)
      points.map { |point| [ch - point[1] - 1, point[0]] }
    end

    def rotate_points_ccw(points, cw, ch)
      points.map { |point| [point[1], cw - point[0] - 1] }
    end

    def rotate_points(points, origin, angle)
      rads = Math::DEG_TO_RADS * angle
      c = Math.cos(rads)
      s = Math.sin(rads)
      m = Matrix[[c, s], [-s, c]]
      ox, oy = *origin
      points.map do |point|
        r = m * Matrix.column_vector(translate_point(point, -ox, -oy))
        translate_point([r[0, 0], r[1, 0]], ox, oy)
      end
    end

    def scale_points(points, sx, sy = sx)
      points.map { |point| [point[0] * sx, point[1] * sy] }
    end
  end
end
