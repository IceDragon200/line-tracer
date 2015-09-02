require 'minil/image'
require_relative '../../utils/point_utils'

module Minil
  class Image
    def draw_line(p1, p2, color)
      LineTracer::PointUtils.draw_line(p1, p2) { |x, y| set_pixel(x, y, color) }
      self
    end

    def draw_line_polygon(points, color)
      LineTracer::PointUtils.draw_line_polygon(points) { |x, y| set_pixel(x, y, color) }
      self
    end

    def draw_line_fan(points, length, color)
      LineTracer::PointUtils.draw_line_fan(points, length) { |x, y| set_pixel(x, y, color) }
      self
    end
  end
end
