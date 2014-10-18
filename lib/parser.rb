module Fauxy
  class Parser
    attr_reader :tokens, :statements, :bookends
    attr_accessor :current_statement

    def initialize(tokens)
      @tokens = Tokens.new(tokens)
      @statements = Statement.new(:statements)
      @bookends = []
    end

    def token
      tokens.current
    end

    # parse_statements, takes terminating character, in case of blocks or grouped statements
    # parse_statements called by run loop, and is the while loop that keeps going until terminated condition
    # parse_statements calls parse_statment for each line, with the terminator line_end or line_break
    # within that parse_statement looks at first token and tries reads tokens until it determines a substatement parser
    #

    def run
      parse_statements
      statements
    end

    def parse_statements(terminators=[nil])
      while !tokens.complete? || (token && terminators.include?(token.type))
        statement = parse_statement(nil)
        statements.add(statement) if statement
      end
    end

    def parse_statement(statement)
      return statement unless token

      if statement
        if [:statement_end, :line_end].include?(token.type)
          # just move along, end of statement
        elsif statement.unary?
          statement = parse_method_call(statement)
        end

        tokens.next
        statement
      else
        if token.unary?
          statement = parse_token
          tokens.next
          parse_statement(statement)
        else
        end
      end
    end

    def parse_method_call(statement)
      return statement unless token
      return statement if [:statement_end, :line_end].include?(token.type)

      if token.type == :dot_accessor
        tokens.next
        return statement unless token
      end

      if statement.type != :method_call || statement.size >= 2
        statement = Statement.new(:method_call, statement)
      end
      statement.add(parse_token)
      tokens.next

      parse_method_call(statement)
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
