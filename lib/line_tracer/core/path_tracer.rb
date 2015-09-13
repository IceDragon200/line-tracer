require_relative '../core_ext/range'
require_relative '../utils/points_transform'

module LineTracer
  class PathTracer
    include PointsTransform

    attr_reader :shape
    attr_reader :keyframes

    def initialize(shape, keyframes = nil)
      @shape = shape
      # keyframes are normalized value between 0..1 they will be scaled against
      # the max frame count from the project
      @keyframes = []
      @ranges = []
      generate_keyframes
    end

    def generate_keyframes
      @keyframes ||= (@shape.point_count + 1).times { |i| [i.to_f / @shape.point_count, i] }
      @ranges = []
      @keyframes[1, @keyframes.size].each_with_index do |(r, _), ind|
        pr, i = @keyframes[ind]
        @ranges << [pr...r, i]
      end
    end

    def render(rate)
      range, index = @ranges.find { |(r, _)| r.cover?(rate) }
      actual_rate = (rate - range.begin) / range.diff
      cur = @shape.get_point(index)
      nxt = @shape.get_point(index + 1)
      return unless cur && nxt
      pnt = lerp_a(cur, nxt, actual_rate).map(&:to_i)
    end
  end
end
