module Enumerable
  def map_with_index
    return to_enum :map_with_index unless block_given?

    i = 0
    map do |a|
      r = yield a, i
      i += 1
      r
    end
  end
end
