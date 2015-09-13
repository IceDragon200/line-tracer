module LineTracer
  # Deprecated, will be replace by Entity in the future
  class PointBuffer
    attr_accessor :points
    attr_accessor :stage_points
    attr_accessor :offset
    attr_accessor :options

    def initialize(points, **options)
      @points = points
      @offset = options.delete(:offset) || 0
      @options = options
    end
  end
end
