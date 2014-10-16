module Fauxy
  class Statement
    attr_accessor :type
    attr_reader :value

    extend Forwardable
    def_delegators :@value, :size, :<<, :map, :each, :first, :last, :[]

    def initialize(type=nil, val=nil)
      self.type = type if type
      @value = []
      value << val if val
    end

    def add(val)
      value << val
    end

    def unary?
      type == :lookup || type == :literal
    end

    def inspect
      "<Statement: #{type.inspect}( " + value.map do |v|
        v.inspect
      end.join(", ") + " )>"
    end
  end
end
