class Range
  # @param [Integer] x  offset
  # @return [Range]
  def translate(x)
    Range.new(x + self.begin, x + self.end, exclude_end?)
  end

  def diff
    self.end - self.begin
  end
end
