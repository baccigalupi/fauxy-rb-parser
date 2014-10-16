module Fauxy
  class Tokens
    attr_accessor :values, :cursor

    def initialize(values)
      @values = values
      @cursor = 0
    end

    def current
      values[cursor]
    end

    def next
      self.cursor += 1
      current
    end

    def complete?
      cursor >= values.length
    end
  end
end
