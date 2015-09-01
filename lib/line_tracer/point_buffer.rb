module LineTracer
  class PointBuffer
    attr_accessor :points
    attr_accessor :frame_points
    attr_accessor :offset
    attr_accessor :options

    def initialize(points, **options)
      @points = points
      @offset = options.delete(:offset) || 0
      @options = options
    end
  end
end
