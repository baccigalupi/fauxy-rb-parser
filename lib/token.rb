module Fauxy
  class Token
    attr_reader :type, :value

    def initialize(type, value=nil)
      @type = type
      @value = value
    end

    def is_literal?
      [:number, :string].include?(type)
    end

    def is_lookup?
      [:id, :class_id].include?(type)
    end

    def unary?
      is_literal? || is_lookup?
    end

    def unary_statement_type
      if is_literal?
        :literal
      elsif is_lookup?
        :lookup
      end
    end

    def inspect
      "<Token: #{type.inspect}, #{value.inspect}>"
    end
  end
end
