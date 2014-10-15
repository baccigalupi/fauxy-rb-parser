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

    def unary_statement_type
      if is_literal?
        :literal
      elsif is_lookup?
        :lookup
      end
    end

    def type_for_opening_bookend
      if type == :open_paren
        :list
      end
    end

    def print
      "<Token: #{type.inspect}, #{value.inspect}>"
    end
  end
end
