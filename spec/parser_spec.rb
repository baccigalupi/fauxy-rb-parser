require 'spec_helper'

describe Fauxy::Parser do
  let(:parser) { Fauxy::Parser.new(tokens) }
  let(:statements) { parser.run }

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
          Fauxy::Token.new(:dot_accessor, nil),
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
  end
  #
  # describe "lists" do
  #   describe "with unary statements" do
  #     let(:tokens) {
  #       [
  #         Fauxy::Token.new(:open_paren),
  #         Fauxy::Token.new(:number, 0),
  #         Fauxy::Token.new(:comma),
  #         Fauxy::Token.new(:number, 7),
  #         Fauxy::Token.new(:comma),
  #         Fauxy::Token.new(:closing_paren)
  #       ]
  #     }
  #
  #     it "should build one list statement" do
  #       expect(statements.size).to be == 1
  #       expect(statements.first.type).to be == :list
  #     end
  #
  #     it "should not add statement/tokens for the commas, or parens" do
  #       expect(statements.first.size).to be == 2
  #       expect(statements.first.first.type).to be == :literal
  #       expect(statements.first.last.type).to be == :literal
  #     end
  #   end
  # end
  #
  # describe 'grouped statement' do
  #   let(:tokens) {
  #     [
  #       Fauxy::Token.new(:open_paren),
  #       Fauxy::Token.new(:number, 0),
  #       Fauxy::Token.new(:id, '++'),
  #       Fauxy::Token.new(:closing_paren)
  #     ]
  #   }
  #
  #   it "should build one grouped statement" do
  #     expect(statements.size).to be == 1
  #     expect(statements.first.type).to be == :grouped
  #   end
  # end
end
