module LineTracer
  module PointsBuilder
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

    def make_stage_points(points, stages)
      stages.times.map do |i|
        index_r = i * points.size / stages.to_f
        index = index_r.to_i
        norm = index_r - index
        a, b = points[index % points.size], points[(index + 1) % points.size]
        lerp_a(a, b, norm).map(&:round)
      end
    end
  end
end
