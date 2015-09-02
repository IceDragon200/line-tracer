module LineTracer
  module PointUtils
    def translate_points(points, ox, oy)
      points.map do |point|
        [point[0] + ox, point[1] + oy]
      end
    end

    def rotate_points_cw(points, cw, ch)
      points.map do |point|
        [ch - point[1] - 1, point[0]]
      end
    end

    def rotate_points_ccw(points, cw, ch)
      points.map do |point|
        [point[1], cw - point[0] - 1]
      end
    end

    def scale_points(points, sx, sy = sx)
      points.map do |point|
        [point[0] * sx, point[1] * sy]
      end
    end

    def get_point(points, i, length = nil)
      #return nil if i < 0
      #return nil if points.size < i
      points[i % (length || points.size)]
    end

    def prev_point(points, i, length = nil)
      get_point(points, i - 1, length)
    end

    # http://rosettacode.org/wiki/Bitmap/Bresenham's_line_algorithm#Ruby
    def draw_line(p1, p2)
      x1, y1 = p1[0], p1[1]
      x2, y2 = p2[0], p2[1]

      steep = (y2 - y1).abs > (x2 - x1).abs

      if steep
        x1, y1 = y1, x1
        x2, y2 = y2, x2
      end

      if x1 > x2
        x1, x2 = x2, x1
        y1, y2 = y2, y1
      end

      deltax = x2 - x1
      deltay = (y2 - y1).abs
      error = deltax / 2
      ystep = y1 < y2 ? 1 : -1

      y = y1
      x1.upto(x2) do |x|
        pixel = steep ? [y, x] : [x, y]
        yield(*pixel)
        error -= deltay
        if error < 0
          y += ystep
          error += deltax
        end
      end
    end

    def make_rect_points(x, y, w, h)
      [
        [x, y],
        [x + w - 1, y],
        [x + w - 1, y + h - 1],
        [x, y + h - 1]
      ]
    end

    # http://stackoverflow.com/questions/398299/looping-in-a-spiral
    def make_square_helix_points(w, h, rep = nil)
      x = y = 0
      dx = 0
      dy = -1

      points = []
      rep ||= [w, h].max ** 2
      rep.times do |i|
        wx = -w / 2
        hy = -h / 2
        if (wx < x && x < (w / 2)) && (hy < y && y < (h / 2))
          points << [x, y]
        end
        if x == y || (x < 0 && x == -y) || (x > 0 && x == 1-y)
          dx, dy = -dy, dx
        end
        x, y = x + dx, y + dy
      end
      points
    end

    def make_pinwheel_from_points(points1, cw, ch)
      points2 = rotate_points_cw(points1, cw, ch)
      points3 = rotate_points_cw(points2, cw, ch)
      points4 = rotate_points_cw(points3, cw, ch)
      return points1, points2, points3, points4
    end
  end
end
