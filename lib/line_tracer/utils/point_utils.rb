require_relative '../core_ext/math'
require_relative 'points_builder'
require_relative 'points_transformer'
require 'matrix'

module LineTracer
  module PointUtils
    include PointsBuilder
    include PointsTransformer

    # Calculates the bounding box for the given points
    # This method will operate on any number of dimensions and returns it.
    #
    # @param [Array<Array<Integer>>] points
    # @return [Array<Integer>]
    def calc_bb_for_points(points)
      bb = []
      dims = points.first.size
      points.each do |point|
        dims.times do |i|
          i2 = dims + i
          bb[i]  ||= point[i]
          bb[i2] ||= point[i2]
          bb[i]  = point[i] if point[i] < bb[i]
          bb[i2] = point[i2] if point[i2] > bb[i2]
        end
      end
      bb
    end

    # Calculates the center point of the given points.
    # This method will operate on any number of dimensions
    #
    # @param [Array<Array<Integer>>] points
    # @return [Array<Integer>]
    def center_point_of(points)
      dims = points.first.size
      bb = calc_bb_for_points(points)
      dims.map do |i|
        bb[i] + (bb[dims + i] - bb[i]) / 2
      end
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

    def draw_line_polygon(points, &block)
      points.each_with_index do |p, i|
        np = points[(i + 1) % points.size]
        draw_line(p, np, &block)
      end
    end

    def draw_line_fan(points, length, &block)
      origin = points.first
      rest_points = points[1, points.size]
      rest_points.cycle.each_slice(length - 1).limited_each(rest_points.size) do |pnts|
        pnts.unshift(origin)
        draw_line_polygon(pnts, &block)
      end
    end

    extend self
  end
end
