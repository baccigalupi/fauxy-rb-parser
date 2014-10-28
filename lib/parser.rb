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

    def peek_type
      tokens.peek.type
    end

    def token_type
      token.type
    end

    def default_terminators
      [:statement_end, :line_end, nil]
    end

    def print_state(msg, statement)
      puts msg
      puts "statement: #{statement.inspect}"
      puts "current: #{token.inspect}"
      puts "peek: #{peek_type}"
    end

    def conclude_or_chain(terminators, statement)
      tokens.next
      if terminators.include?(token_type)
        # we are done
        statement
      else
        # it is the first part of another statement
        statement = parse_statement(terminators, statement)
        tokens.next
        statement
      end
    end

    def parse_statements(terminators=[nil])
      statements = Statement.new(:statements)
      while !terminators.include?(token_type)
        statement = parse_statement(terminators == [nil] ? default_terminators : default_terminators + terminators)
        statements.add(statement) if statement
      end
      statements
    end

    # within that parse_statement looks at first token and tries reads tokens until it determines a substatement parser
    def parse_statement(terminators = default_terminators, statement=nil)
      return unless token_type
      return nil if token_type == nil

      if default_terminators.include?(token_type)
        tokens.next
      end

      if statement
        statement = parse_method_call(terminators, statement)
        tokens.next
        statement
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
      elsif token_type == :opening_paren
        parse_group_or_list(terminators)
      elsif token_type == :block_declaration
        parse_block(terminators)
      else
        raise ArgumentError, "Unknown token type #{token.inspect}"
      end
    end

    # current tests only cover two unary statements to this
    def parse_method_call(terminators, statement = nil)
      return unless token_type
      statement ||= token

      # deal with the receiver
      method_call = Statement.new(:method_call)
      method_call.add(statement)

      tokens.next if statement == token
      tokens.next if token_type == :dot_accessor

      # add the method name
      method_call.add(token)

      # list
      if peek_type == :opening_paren
        tokens.next
        method_call.add(parse_list(terminators << :block_declaration))
      else
        method_call.add(Statement.new(:list))
      end


      if peek_type == :block_declaration || token_type == :block_declaration
        tokens.next if peek_type == :block_declaration
        block = parse_block(terminators)
        method_call.last.add(block) # add to list
      end

      conclude_or_chain(terminators, method_call)
    end

    def parse_group_or_list(terminators)
      return unless token_type

      list_or_group = Statement.new(:group)
      tokens.next # to pass the opening paren

      while token_type != :closing_paren && token_type != nil
        unless handle_comma(list_or_group)
          # keep going
          statement = parse_statement([:comma, :closing_paren])
          handle_comma(list_or_group)
          list_or_group.add(statement)
        end
      end

      # last statement is terminated by the closing_paren
      # list is also terminated by closing paren
      # therefore for consistency, we want to roll back
      # so that peek type is closing_paren

      tokens.rollback if token_type != :closing_paren

      conclude_or_chain(terminators, list_or_group)
    end

    def handle_comma(statement)
      return unless token_type == :comma
      statement.type = :list
      tokens.next
      true
    end

    def parse_list(terminators)
      return unless token_type
      list = parse_group_or_list(terminators)
      list.type = :list
      list
    end

    def parse_block(terminators)
      return unless token_type
      tokens.next

      block = Statement.new(:block)

      list = if token_type == :opening_paren
        parse_list(terminators << :block_start)
      else
        Statement.new(:list)
      end
      block.add(list)

      if token_type == :block_start
        tokens.next
        statements = parse_statements([:block_end, nil])
        tokens.next
        block.add(statements)
      end

      block
    end
  end
end
