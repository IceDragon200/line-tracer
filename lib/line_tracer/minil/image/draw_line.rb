require 'minil/image'
require_relative '../../utils/point_utils'

module Minil
  class Image
    def draw_line(p1, p2, color)
      LineTracer::PointUtils.draw_line(p1, p2) { |x, y| set_pixel(x, y, color) }
      self
    end

    def draw_line_shape(points, color)
      points.each_with_index do |p, i|
        np = points[(i + 1) % points.size]
        draw_line(p, np, color)
      end
      self
    end
  end
end
