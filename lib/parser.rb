module Fauxy
  class Parser
    attr_reader :tokens, :statements, :bookends
    attr_accessor :current_statement

    def initialize(tokens)
      @tokens = tokens
      @statements = []
      @bookends = []
    end

    def run
      tokens.each do |token|
        if token.type == :statement_end || token.type == :line_end
          add_current_statement_to_stack
        else
          add_to_current_statement(token)
        end
      end

      add_current_statement_to_stack

      statements
    end

    def add_to_current_statement(token)
      type = token.unary_statement_type
      type ||= token.type_for_opening_bookend

      if current_statement.nil?
        if type == :list
          bookends << :paren
          self.current_statement = Statement.new(type)
        else
          self.current_statement = Statement.new(type, token)
        end
      elsif current_statement.unary? && current_statement.size == 1
        wrap_current_statement(:method_call)
        return if token.type == :dot_accessor
        current_statement.add(Statement.new(type, token))
      elsif current_statement.type == :list
        if token.type == :closing_paren
          if bookends.last == :paren
            bookends.pop
          else
            # raise error!
          end
        elsif token.type == :comma
          return
        else
          current_statement.add(Statement.new(type, token))
        end
      else
        current_statement.add(Statement.new(type, token))
      end
    end

    def wrap_current_statement(type)
      new_statement = Statement.new(type)
      new_statement.add(current_statement)
      self.current_statement = new_statement
    end

    def add_current_statement_to_stack
      return unless current_statement
      statements << current_statement
      self.current_statement = nil
    end
  end
end
