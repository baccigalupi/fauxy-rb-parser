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
        list = parse_statement(terminators)
        # convert to list as some point
        list.type = :list if list.type == :group
        method_call.add(list)
      else
        method_call.add(Statement.new(:list))
      end

      if peek_type == :block_declaration
        tokens.next
        block = parse_block(terminators)
        method_call.last.add(block) # add to list
      end

      if terminators.include?(peek_type)
        return_statement(method_call)
      else
        tokens.next
        return_statement(parse_statement(terminators, method_call))
      end
    end

    def parse_group_or_list(terminators)
      return unless token_type

      list_or_group = Statement.new(:group)
      tokens.next # to pass the opening paren

      while token_type != :closing_paren && token_type != nil
        if token_type == :comma
          list_or_group.type = :list
          tokens.next
        else
          # keep going
          statement = parse_statement([:comma, :closing_paren])
          if token_type == :comma
            list_or_group.type == :list
          end
          list_or_group.add(statement)
        end
      end

      # does not cover lists with only one value, like in arguments
      # or even, empty lists

      if terminators.include?(peek_type)
        # we are done
        return_statement(list_or_group)
      else
        # it is the first part of another statement
        tokens.next
        return_statement(parse_statement(terminators, list_or_group))
      end
    end

    def parse_block(terminators)
      return unless token_type
      tokens.next

      block = Statement.new(:block)

      list = if token_type == :opening_paren
        parse_group_or_list(terminators << :block_start)
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
