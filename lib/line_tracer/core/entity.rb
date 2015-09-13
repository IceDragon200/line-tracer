module LineTracer
  class Entity
    attr_accessor :shape
    attr_accessor :options

    # keyframe points
    attr_accessor :key_points

    def initialize(shape, **options)
      @shape = shape
      @options = options
      @key_points = nil
    end
  end
end
