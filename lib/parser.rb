module Fauxy
  class Parser
    attr_reader :tokens, :statements, :bookends
    attr_accessor :current_statement

    def initialize(tokens)
      @tokens = Tokens.new(tokens)
      @statements = []
      @bookends = []
    end

    def run
      while !tokens.complete?
        statement = start_statement
        statements << statement if statement
      end

      statements
    end

    def start_statement
      statement = parse_token
      tokens.next
      parse_statement(statement) if statement
    end

    # starting an unknown statement
    def parse_statement(statement)
      token = tokens.current
      return statement unless token


      if [:statement_end, :line_end].include?(token.type)
        # just move along, end of statement
      elsif statement.unary?
        statement = parse_method_call(statement)
      end

      tokens.next
      statement
    end

    def parse_method_call(statement)
      statement = Statement.new(:method_call, statement)
      statement.add(parse_token)
      statement
    end

    def parse_token
      token = tokens.current
      return nil unless token

      if statement_type = token.unary_statement_type
        Statement.new(statement_type, token)
      end
    end
  end
end
