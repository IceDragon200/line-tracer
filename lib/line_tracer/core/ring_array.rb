module LineTracer
  class RingArray
    include Enumerable

    def initialize(array, offset)
      @array = array
      @offset = offset
    end

    def [](index)
      @array[(@offset + index) % @array.size]
    end

    def each
      return to_enum :each unless block_given?
      @array.size.times do |i|
        yield self[i]
      end
    end
  end
end
