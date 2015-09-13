module LineTracer
  class Shape
    include Enumerable

    attr_accessor :points

    # should get_point looping around?
    attr_accessor :looped

    def initialize(points = [])
      @points = points
      @looped = false
    end

    # @return [Integer]
    def point_count
      @points.size
    end

    # @param [Integer] index
    # @return [nil, Array<Integer>] point
    def get_point(index)
      if @looped
        @points[index % point_count]
      else
        return nil if index < 0 || point_count <= index
        @points[index]
      end
    end

    def each
      return to_enum :each unless block_given?
      point_count.times do |i|
        get_point(i)
      end
    end
  end
end
