class Range
  def translate(x)
    Range.new(x + self.begin, x + self.end, exclude_end?)
  end
end
