module LineTracer
  class Project
    attr_accessor :entities
    attr_accessor :timeframe

    def initialize
      @entities = []
      @timeframe = 0...100
    end
  end
end
