#!/usr/bin/ruby

require 'test/unit'
require 'elparser'

STDOUT.sync = true

include Elparser

# short cut functions

def _int(v)
  SExpNumber.int(v.to_s)
end
def _float(v)
  SExpNumber.float(v.to_s)
end
def _symbol(v)
  SExpSymbol.new(v)
end
def _string(v)
  SExpString.new(v)
end
def _nil
  SExpNil.new
end
def _cons(a,b)
  SExpCons.new(a,b)
end
def _list(*args)
  SExpList.new(args)
end
def _dotlist(a,b)
  SExpListDot.new(a,b)
end
def _q(a)
  SExpQuoted.new(a)
end



class TestElparser < Test::Unit::TestCase
  
  setup do
    @parser = Elparser::Parser.new
  end



  sub_test_case "Decoder" do

    sub_test_case "Primitive Decoder" do
      
      data({
         'integer'      => ['123', _int("123")],
         'unary-'       => ['-22', _int("-22")],
         'unary+'       => ['+33', _int("+33")],
         'float'        => ['1.23', _float("1.23")],
         'float period' => ['.45', _float(".45")],
         'float exp+'   => ['1.4e5', _float("1.4e5")],
         'float exp-'   => ['1.4e-5', _float("1.4e-5")],
         'symbol'       => ['abc', _symbol('abc')],
         'symbol2'      => ['$sf-/p.post', _symbol('$sf-/p.post')],
         'string'       => ['"qwert"', _string("qwert")],
         'string2'      => ['"abc\"dds\"dfff\'123\' \\n\nok?"', _string('abc\"dds\"dfff\'123\' \\n\nok?')],
         'quote'        => ['\'symbol', _q(_symbol('symbol'))],
         'nil'          => ['nil', _nil],
           })
      def test_primitive(data)
        src, expected = data
        assert_equal expected, @parser.parse(src)
      end
    
    end

    sub_test_case "List Structure" do
      
      data({
         "nil list"          => ["()", _nil], 
         "list1"             => ["(1)", _list(_int(1))], 
         "list2"             => ["(1 2)",_list(_int(1),_int(2))], 
         "nest list1"        => ["(1 (2 3) 4)",_list(_int(1),_list(_int(2),_int(3)),_int(4))],
         "nest list2"        => ["(((1)))",_list(_list(_list(_int(1))))],
         "type values"       => ["(1 'a \"b\" ())",_list(_int(1),_q(_symbol("a")),_string("b"),_nil)],
         "calc terms"        => ["(+ 1 2 (- 2 (* 3 4)))",_list(_symbol("+"),_int(1),_int(2),_list(_symbol("-"),_int(2),_list(_symbol("*"),_int(3),_int(4))))],
         "reverse cons list" => ["(((1.0) 0.2) 3.4e+4)",_list(_list(_list(_float(1.0)),_float(0.2)),_float("3.4e+4"))],
         "cons cell"         => ["(1 . 2)",_cons(_int(1),_int(2))],
         "dot list"          => ["(1 2 . 3)",_dotlist([_int(1),_int(2)],_int(3))],
           })
      def test_list(data)
        src, expected = data
        assert_equal expected, @parser.parse(src)
      end
      
    end

    sub_test_case "Cons and List operation" do
      
      def test_cons1
        v = @parser.parse("(1 . 2)")
        assert_equal _int(1), v.car
        assert_equal _int(2), v.cdr
      end

      def test_list1
        v = @parser.parse("(1 2 3)")
        assert_equal _int(1), v.car
        assert_equal _int(2), v.cdr.car
        assert_equal _int(3), v.cdr.cdr.car
        assert_equal _nil, v.cdr.cdr.cdr
      end

      def test_dotlist
        v = @parser.parse("(1 2 . 3)")
        assert_equal _int(1), v.car
        assert_equal _int(2), v.cdr.car
        assert_equal _int(3), v.cdr.cdr
      end

      def test_ruby_object
        v = @parser.parse("(1 2.1 \"xxx\" www)")
        ro = v.to_ruby
        assert_equal ro.size, 4
        assert_equal ro[0], 1
        assert_equal ro[1], 2.1
        assert_equal ro[2], "xxx"
        assert_equal ro[3], :www

        v = @parser.parse("(1 (2 3 (4)))")
        ro = v.to_ruby
        assert_equal ro.size, 2
        assert_equal ro[0], 1
        assert_equal ro[1][0], 2
        assert_equal ro[1][1], 3
        assert_equal ro[1][2][0], 4
      end

      def test_alist
        v = @parser.parse("( (a . 1) (b . \"xxx\") (c 3 4) (\"d\" . \"e\"))")
        assert_true v.alist?
        hash = v.to_h
        assert_equal hash[:a], 1
        assert_equal hash[:b], "xxx"
        assert_equal hash[:c], [3,4]
        assert_equal hash["d"], "e"

        v = @parser.parse("((a . 1) (b))")
        assert_true v.alist?
        v = @parser.parse("((a . 1) b)")
        assert_false v.alist?
      end

    end

  end



  sub_test_case "Encoder" do
    
    data({
       "primitive and list" => [[1,1.2,-4,"xxx",:www,true,nil], "(1 1.2 -4 \"xxx\" www t nil)"],
       "nested list" => [[1,[2,[3,4]]], "(1 (2 (3 4)))"],
       "hash1" => [{"a" => "b", "c" => "d"}, "((\"a\" . \"b\") (\"c\" . \"d\"))"],
       "hash2" => [{:a => [1,2,3], :b => {:c => [4,5,6]}}, "((a 1 2 3) (b (c 4 5 6)))"],
    })
    def test_encode(data)
      src, expected = data
      assert_equal(expected, Elparser.encode(src))
    end

  end

end
