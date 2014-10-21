module Fauxy
  class Parser
    attr_accessor :tokens, :statements

    def initialize(token_list)
      @tokens = Tokens.new(token_list)
      tokens.convert_unaries
    end

    def token
      tokens.current
    end

    def run
      self.statements = parse_statements
    end

    # parse_statements, takes terminating character, in case of blocks or grouped statements
    # parse_statements called by run loop, and is the while loop that keeps going until terminated condition
    # parse_statements calls parse_statment for each line, with the terminator line_end or line_break

    def parse_statements(terminators=[nil])
      statements = Statement.new(:statements)
      while !tokens.complete?
        statement = parse_statement
        statements.add(statement) if statement
      end
      statements
    end

    def return_statement(statement)
      tokens.next
      statement
    end

    def peek_type
      tokens.peek.type
    end

    def token_type
      token.type
    end

    def default_terminators
      [:statement_end, :line_end, nil]
    end

    # within that parse_statement looks at first token and tries reads tokens until it determines a substatement parser
    def parse_statement(terminators = default_terminators, statement=nil)
      return unless token_type
      return nil if token_type == nil

      if default_terminators.include?(token_type)
        tokens.next
      end

      if statement
        return_statement(parse_method_call(terminators, statement))
      elsif token_type == :lookup || token_type == :literal
        if terminators.include?(peek_type)
          statement = token
          tokens.next
          statement
        elsif peek_type == :dot_accessor
          parse_method_call(terminators)
        elsif peek_type == :local_assign
          parse_local_assign(terminators)
        elsif token_type == :literal
          parse_method_call(terminators)
        elsif peek_type == :attr_assign
          parse_attr_assign(terminators)
        else
          parse_method_call(terminators)
        end
      else token_type == :opening_paren
        parse_group_or_list(terminators)
      # else token_type == :block_declaration
      #   # do that
      end
    end

    # current tests only cover two unary statements to this
    def parse_method_call(terminators, statement = token)
      return unless token_type

      # deal with the receiver
      method_call = Statement.new(:method_call)
      method_call.add(statement)

      tokens.next if statement == token
      tokens.next if token_type == :dot_accessor

      # add the method name
      method_call.add(token)

      # add optional list
      # add optional block

      if terminators.include?(peek_type)
        return_statement(method_call)
      else
        tokens.next
        return_statement(parse_statement(terminators, method_call))
      end
    end

    def parse_group_or_list(terminators)
      return unless token_type

      list = Statement.new(:group)
      tokens.next # to pass the opening paren

      while token_type != :closing_paren && token_type != nil
        if token_type == :comma
          list.type = :list
          tokens.next
        else
          statement = parse_statement([:comma, :closing_paren])
          if token_type == :comma
            list.type == :list
          end
          list.add(statement)
        end
      end

      return_statement(list)
    end
  end
end
