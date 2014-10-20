module Fauxy
  class Tokens
    attr_accessor :values, :cursor

    def initialize(values)
      @values = values
      @cursor = 0
    end

    def convert_unaries
      @values = values.map do |token|
        if token.unary?
          Statement.new(token.unary_statement_type, token)
        else
          token
        end
      end
      self
    end

    def prev
      values[cursor - 1] || Null.new
    end

    def current
      values[cursor] || Null.new
    end

    def peek
      values[cursor + 1] || Null.new
    end

    def next
      self.cursor += 1
      current
    end

    def complete?
      cursor >= values.length
    end

    class Null
      def type
      end
    end
  end
end
