module LineTracer
  class PointBuffer
    attr_accessor :points
    attr_accessor :frame_points

    def initialize(points)
      @points = points
    end
  end
end
