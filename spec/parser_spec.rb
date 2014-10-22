require 'spec_helper'

describe Fauxy::Parser do
  let(:parser) { Fauxy::Parser.new(tokens) }
  let(:statements) { parser.run.value }

  def assert_statement_types(statement, *types)
    expect(
      statement.value.map{ |i| i.type }
    ).to be == types
  end

  describe "unary statements" do
    describe "single number token" do
      let(:tokens) { [Fauxy::Token.new(:number, 1.324)] }

      it "should have the right statement type" do
        expect(statements.first.type).to be == :literal
      end

      it "should have only one statement that is the token" do
        assert_statement_types(statements.first, :number)
      end
    end

    describe "single number token" do
      let(:tokens) { [Fauxy::Token.new(:string, "hello")] }

      it "should have the right statement type" do
        expect(statements.first.type).to be == :literal
      end

      it "should have only one statement that is the token" do
        assert_statement_types(statements.first, :string)
      end
    end

    describe "identifier" do
      let(:tokens) { [Fauxy::Token.new(:id, "identifier")] }

      it "should have the right statement type" do
        expect(statements.first.type).to be == :lookup
      end

      it "should have only one statement that is the token" do
        assert_statement_types(statements.first, :id)
      end
    end

    describe "identifier" do
      let(:tokens) { [Fauxy::Token.new(:class_id, "Identifier")] }

      it "should have the right statement type" do
        expect(statements.first.type).to be == :lookup
      end

      it "should have only one statement that is the token" do
        assert_statement_types(statements.first, :class_id)
      end
    end
  end

  describe "two unary statements" do
    describe 'separated by statement end' do
      let(:tokens) {
        [
          Fauxy::Token.new(:class_id, "Identifier"),
          Fauxy::Token.new(:statement_end),
          Fauxy::Token.new(:number, 0.13)
        ]
      }

      it "builds the right number of statements" do
        expect(statements.length).to be == 2
      end
    end

    describe 'separated by a line end' do
      let(:tokens) {
        [
          Fauxy::Token.new(:class_id, "Identifier"),
          Fauxy::Token.new(:line_end),
          Fauxy::Token.new(:number, 0.13)
        ]
      }

      it "builds the right number of statements" do
        expect(statements.length).to be == 2
      end
    end
  end

  describe "method calls" do
    describe "separated by a space" do
      let(:tokens) { [Fauxy::Token.new(:number, 0), Fauxy::Token.new(:id, '++')] }

      it "should build the right number of statements" do
        expect(statements.size).to be == 1
      end

      it "should build a method call statement" do
        expect(statements.first.type).to be == :method_call
      end

      it "statement should have the right number of substaments" do
        expect(statements.first.size).to be == 2
      end

      it "should have the right tokens" do
        expect(statements.first.first.type).to be == :literal
        expect(statements.first.last.type).to be == :lookup
      end
    end

    describe "separated by attribute accessor" do
      let(:tokens) {
        [
          Fauxy::Token.new(:number, 0),
          Fauxy::Token.new(:dot_accessor),
          Fauxy::Token.new(:id, "++")
        ]
      }

      it "should build the right number of statements" do
        expect(statements.size).to be == 1
      end

      it "statement should have the right number of substaments" do
        expect(statements.first.size).to be == 2
      end

      it "should build a method call statement" do
        expect(statements.first.type).to be == :method_call
      end

      it "should have the right tokens" do
        expect(statements.first.first.type).to be == :literal
        expect(statements.first.last.type).to be == :lookup
      end
    end

    describe 'nested method calls' do
      describe "with dots" do
        let(:tokens) {
          [
            Fauxy::Token.new(:number, 0),
            Fauxy::Token.new(:dot_accessor),
            Fauxy::Token.new(:id, "to_s"),
            Fauxy::Token.new(:dot_accessor),
            Fauxy::Token.new(:id, "to_i")
          ]
        }

        # <Statement: :method_call(
        #   <Statement: :method_call(
        #      <Statement: :literal( <Token: :number, 0> )>,
        #      <Statement: :lookup( <Token: :id, "to_s">)>
        #   )>,
        #   <Statement: :lookup( <Token: :id, "to_i"> )>
        # )>

        let(:nested) { statements.first.first }

        it "should build the right number of statements" do
          expect(statements.size).to be == 1
        end

        it "should containe a nested method call" do
          expect(statements.first.type).to be == :method_call

          expect(nested.type).to be == :method_call
          expect(nested.size).to be == 2
        end

        it "should put the tokens in the right place in the nested method call" do

          nested_first_token = nested.first.first
          expect(nested_first_token.type).to be == :number
          expect(nested_first_token.value).to be == 0

          nested_last_token = nested.last.first
          expect(nested_last_token.type).to be == :id
          expect(nested_last_token.value).to be == "to_s"
        end

        it "should put the right method name on to the back of the first method call" do
          method_name = statements.first.last
          expect(method_name.first.type).to be == :id
          expect(method_name.first.value).to be == "to_i"
        end
      end

      describe "with spaces" do
        let(:tokens) {
          [
            Fauxy::Token.new(:number, 0),
            Fauxy::Token.new(:id, "to_s"),
            Fauxy::Token.new(:id, "to_i")
          ]
        }

        # <Statement: :method_call(
        #   <Statement: :method_call(
        #      <Statement: :literal( <Token: :number, 0> )>,
        #      <Statement: :lookup( <Token: :id, "to_s">)>
        #   )>,
        #   <Statement: :lookup( <Token: :id, "to_i"> )>
        # )>

        let(:nested) { statements.first.first }

        it "should build the right number of statements" do
          expect(statements.size).to be == 1
        end

        it "should containe a nested method call" do
          expect(statements.first.type).to be == :method_call

          expect(nested.type).to be == :method_call
          expect(nested.size).to be == 2
        end

        it "should put the tokens in the right place in the nested method call" do

          nested_first_token = nested.first.first
          expect(nested_first_token.type).to be == :number
          expect(nested_first_token.value).to be == 0

          nested_last_token = nested.last.first
          expect(nested_last_token.type).to be == :id
          expect(nested_last_token.value).to be == "to_s"
        end

        it "should put the right method name on to the back of the first method call" do
          method_name = statements.first.last
          expect(method_name.first.type).to be == :id
          expect(method_name.first.value).to be == "to_i"
        end
      end
    end
  end

  describe "lists" do
    describe "with unary statements" do
      let(:tokens) {
        [
          Fauxy::Token.new(:opening_paren),
          Fauxy::Token.new(:number, 0),
          Fauxy::Token.new(:comma),
          Fauxy::Token.new(:number, 7),
          Fauxy::Token.new(:comma),
          Fauxy::Token.new(:closing_paren)
        ]
      }

      it "should build one list statement" do
        expect(statements.size).to be == 1
        expect(statements.first.type).to be == :list
      end

      it "should not add statement/tokens for the commas, or parens" do
        expect(statements.first.size).to be == 2
        expect(statements.first.first.type).to be == :literal
        expect(statements.first.last.type).to be == :literal
      end
    end

    describe "with nested statements" do
      # "(0.to_s, (42, 13))"
      let(:tokens) {
        [
          Fauxy::Token.new(:opening_paren),
          Fauxy::Token.new(:number, 0),
          Fauxy::Token.new(:dot_accessor),
          Fauxy::Token.new(:id, "to_s"),
          Fauxy::Token.new(:comma),
          Fauxy::Token.new(:opening_paren),
          Fauxy::Token.new(:number, 42),
          Fauxy::Token.new(:comma),
          Fauxy::Token.new(:number, 13),
          Fauxy::Token.new(:closing_paren),
          Fauxy::Token.new(:closing_paren)
        ]
      }

      let(:method_call) { statements.first.first }
      let(:nested_list) { statements.first.last }

      it "should build one list statement" do
        expect(statements.size).to be == 1
        expect(statements.first.type).to be == :list
      end

      it "should build a method call within that" do
        expect(method_call.type).to be == :method_call
      end

      it "should build a nested list within that" do
        expect(nested_list.type).to be == :list
      end
    end
  end

  describe 'grouped statement' do
    let(:tokens) {
      [
        Fauxy::Token.new(:opening_paren),
        Fauxy::Token.new(:number, 0),
        Fauxy::Token.new(:id, '++'),
        Fauxy::Token.new(:closing_paren)
      ]
    }

    it "should build one grouped statement" do
      expect(statements.size).to be == 1
      expect(statements.first.type).to be == :group
    end
  end

  describe 'methods with complicated parens' do
    describe "grouped statement receiving a method call" do
      # (0 ++).to_s
      let(:tokens) {
        [
          Fauxy::Token.new(:opening_paren),
          Fauxy::Token.new(:number, 0),
          Fauxy::Token.new(:id, '++'),
          Fauxy::Token.new(:closing_paren),
          Fauxy::Token.new(:dot_accessor),
          Fauxy::Token.new(:id, "to_s"),
        ]
      }

      <<-STATEMENT
        <Statement: :method_call(
          <Statement: :group(
            <Statement: :method_call(
              <Statement: :literal( <Token: :number, 0> )>,
              <Statement: :lookup( <Token: :id, "++"> )>
            )>
          )>,
          <Statement: :lookup( <Token: :id, "to_s"> )>
        )>
      STATEMENT

      let(:statement) { statements.first }

      it "should build a method call as the base statement" do
        expect(statements.size).to be == 1
        expect(statement.type).to be == :method_call
      end

      it "should have a grouped statement as the first element" do
        group = statement.first
        expect(group.type).to be == :group
        method_call = group.first
        expect(method_call.type).to be == :method_call
        expect(method_call.first.type).to be == :literal
        expect(method_call.last.first.value).to be == '++'
      end

      it "should have a method call at the end" do
        lookup = statement.last
        expect(lookup.type).to be == :lookup
        expect(lookup.first.type).to be == :id
        expect(lookup.first.value).to be == "to_s"
      end
    end

    describe "method call with arguments" do
      # MyClass.new(arg1, arg2)
      let(:tokens) {
        [
          Fauxy::Token.new(:class_id, "MyClass"),
          Fauxy::Token.new(:dot_accessor),
          Fauxy::Token.new(:id, "new"),
          Fauxy::Token.new(:opening_paren),
          Fauxy::Token.new(:id, "arg1"),
          Fauxy::Token.new(:comma),
          Fauxy::Token.new(:id, "arg2"),
          Fauxy::Token.new(:closing_paren),
        ]
      }

      <<-STATEMENT
        <Statement: :method_call(
          <Statement: :lookup( <Token: :class_id, "MyClass"> )>,
          <Statement: :lookup( <Token: :id, "new"> )>,
          <Statement: :list(
            <Statement: :lookup( <Token: :id, "arg1"> )>,
            <Statement: :lookup( <Token: :id, "arg2"> )>
          )>
        )>
      STATEMENT

      it "should build a method_call statement" do
        expect(statements.size).to be == 1
        expect(statements.first.type).to be == :method_call
      end

      it "should include a list as the third element" do
        list = statements.first.last
        expect(list.first.first.value).to be == "arg1"
        expect(list.last.first.value).to be == "arg2"
      end
    end

    describe "method call with arguments and no dot accessor" do
      # MyClass new(arg1, arg2)
      let(:tokens) {
        [
          Fauxy::Token.new(:class_id, "MyClass"),
          Fauxy::Token.new(:id, "new"),
          Fauxy::Token.new(:opening_paren),
          Fauxy::Token.new(:id, "arg1"),
          Fauxy::Token.new(:comma),
          Fauxy::Token.new(:id, "arg2"),
          Fauxy::Token.new(:closing_paren),
        ]
      }

      <<-STATEMENT
        <Statement: :method_call(
          <Statement: :lookup( <Token: :class_id, "MyClass"> )>,
          <Statement: :lookup( <Token: :id, "new"> )>,
          <Statement: :list(
            <Statement: :lookup( <Token: :id, "arg1"> )>,
            <Statement: :lookup( <Token: :id, "arg2"> )>
          )>
        )>
      STATEMENT

      it "should build a method_call statement" do
        expect(statements.size).to be == 1
        expect(statements.first.type).to be == :method_call
      end

      it "should include a list as the third element" do
        list = statements.first.last
        expect(list.first.first.value).to be == "arg1"
        expect(list.last.first.value).to be == "arg2"
      end
    end

    describe "method call on list with only one argument" do
      # ('1','2','3').join(", ")
      let(:tokens) {
        [
          Fauxy::Token.new(:opening_paren),
          Fauxy::Token.new(:string, "1"),
          Fauxy::Token.new(:comma),
          Fauxy::Token.new(:string, "2"),
          Fauxy::Token.new(:comma),
          Fauxy::Token.new(:string, "3"),
          Fauxy::Token.new(:closing_paren),
          Fauxy::Token.new(:id, "join"),
          Fauxy::Token.new(:opening_paren),
          Fauxy::Token.new(:string, ", "),
          Fauxy::Token.new(:closing_paren)
        ]
      }

      it "should build a method_call statement" do
        expect(statements.size).to be == 1
        expect(statements.first.type).to be == :method_call
      end

      it "should build out a list as the first element" do
        list = statements.first.first
        expect(list.type).to be == :list
        expect(list.size).to be == 3
      end

      it "second element should be the method name" do
        method_name = statements.first[1]
        expect(method_name.type).to be == :lookup
        expect(method_name.first.value).to be == "join"
      end

      it "last element is a list" do
        arguments = statements.first.last
        expect(arguments.type).to be == :list
        expect(arguments.size).to be == 1
      end
    end
  end

  describe 'blocks' do
    describe 'without arguments, one statement' do
      # -> { "hello" }
      let(:tokens) {
        [
          Fauxy::Token.new(:block_declaration),
          Fauxy::Token.new(:block_start),
          Fauxy::Token.new(:string, "hello"),
          Fauxy::Token.new(:block_end)
        ]
      }

      <<-STATEMENT
        <Statement: :block(
          <Statement: :list(  )>,
          <Statement: :statements(
            <Statement: :literal( <Token: :string, "hello"> )>
          )>
        )>
      STATEMENT

      it "creates a block statement" do
        expect(statements.size).to be == 1
        expect(statements.first.type).to be == :block
      end

      it "creates an empty arguments list" do
        expect(statements.first.first.type).to be == :list
      end

      it "adds a statements statement" do
        expect(statements.first.last.type).to be == :statements
      end

      it "statements include the right statement" do
        expect(statements.first.last.size).to be == 1
        expect(statements.first.last.first.type).to be == :literal
      end
    end

    describe 'without arguments, statements separated by ;' do
      # -> { "hello"; "world" }
      let(:tokens) {
        [
          Fauxy::Token.new(:block_declaration),
          Fauxy::Token.new(:block_start),
          Fauxy::Token.new(:string, "hello"),
          Fauxy::Token.new(:statement_end),
          Fauxy::Token.new(:string, "world"),
          Fauxy::Token.new(:block_end)
        ]
      }

      <<-STATEMENT
        <Statement: :block(
          <Statement: :list(  )>,
          <Statement: :statements(
            <Statement: :literal( <Token: :string, "hello"> )>,
            <Statement: :literal( <Token: :string, "world"> )>
          )>
        )>
      STATEMENT

      it "creates a block statement" do
        expect(statements.size).to be == 1
        expect(statements.first.type).to be == :block
      end

      it "creates an empty arguments list" do
        expect(statements.first.first.type).to be == :list
      end

      it "adds a statements statement" do
        expect(statements.first.last.type).to be == :statements
      end

      it "statements include the right statement" do
        expect(statements.first.last.size).to be == 2
        expect(statements.first.last.first.type).to be == :literal
        expect(statements.first.last.last.type).to be == :literal
      end
    end

    describe 'without arguments, statements separated by ;' do
      # -> {\n"hello"\n"world" }
      let(:tokens) {
        [
          Fauxy::Token.new(:block_declaration),
          Fauxy::Token.new(:block_start),
          Fauxy::Token.new(:line_end),
          Fauxy::Token.new(:string, "hello"),
          Fauxy::Token.new(:line_end),
          Fauxy::Token.new(:string, "world"),
          Fauxy::Token.new(:block_end)
        ]
      }

      <<-STATEMENT
        <Statement: :block(
          <Statement: :list(  )>,
          <Statement: :statements(
            <Statement: :literal( <Token: :string, "hello"> )>,
            <Statement: :literal( <Token: :string, "world"> )>
          )>
        )>
      STATEMENT

      it "creates a block statement" do
        expect(statements.size).to be == 1
        expect(statements.first.type).to be == :block
      end

      it "creates an empty arguments list" do
        expect(statements.first.first.type).to be == :list
      end

      it "adds a statements statement" do
        expect(statements.first.last.type).to be == :statements
      end

      it "statements include the right statement" do
        expect(statements.first.last.size).to be == 2
        expect(statements.first.last.first.type).to be == :literal
        expect(statements.first.last.last.type).to be == :literal
      end
    end

    describe 'with arguments' do
      # -> ('foo', 'bar') { "hello" }
      let(:tokens) {
        [
          Fauxy::Token.new(:block_declaration),
          Fauxy::Token.new(:opening_paren),
          Fauxy::Token.new(:string, "foo"),
          Fauxy::Token.new(:comma),
          Fauxy::Token.new(:string, "bar"),
          Fauxy::Token.new(:closing_paren),
          Fauxy::Token.new(:block_start),
          Fauxy::Token.new(:string, "hello"),
          Fauxy::Token.new(:block_end)
        ]
      }

      <<-STATEMENT
        <Statement: :block(
          <Statement: :list(
            <Statement: :literal( <Token: :string, "foo"> )>,
            <Statement: :literal( <Token: :string, "bar"> )>
          )>,
          <Statement: :statements(
            <Statement: :literal( <Token: :string, "hello"> )>
          )>
        )>
      STATEMENT

      it "creates a block statement" do
        expect(statements.size).to be == 1
        expect(statements.first.type).to be == :block
      end

      it "creates an arguments list" do
        list = statements.first.first
        expect(list.type).to be == :list
        expect(list.size).to be == 2
        expect(list.first.value.first.value).to be == 'foo'
        expect(list.last.value.first.value).to be == 'bar'
      end

      it "adds a statements statement" do
        expect(statements.first.last.type).to be == :statements
      end

      it "statements include the right statement" do
        expect(statements.first.last.size).to be == 1
        expect(statements.first.last.first.type).to be == :literal
      end
    end
  end
end
