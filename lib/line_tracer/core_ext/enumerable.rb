module Enumerable
  def limited_each(length)
    each do |*args|
      break if length <= 0
      yield(*args)
      length -= 1
    end
  end

  def map_with_index
    return to_enum :map_with_index unless block_given?

    i = 0
    map do |*a|
      r = yield(*a, i)
      i += 1
      r
    end
  end
end
