require "elparser/version"
require 'elparser/parser.tab.rb'
require 'strscan'

module Elparser
  
  class AbstractSExp
    def atom?
      false
    end
    def cons?
      false
    end
    def list?
      false
    end
    def ==(obj)
      self.class == obj.class && self.to_s == obj.to_s
    end
    def visit
      raise "Not implemented!"
    end
    def to_ruby
      raise "Not implemented!"
    end
  end

  class AbstractSExpAtom < AbstractSExp
    def atom?
      true
    end
  end

  class SExpNil < AbstractSExpAtom
    def list?
      true
    end
    def to_s
      "nil"
    end
    def visit
      # do nothing
    end
    def to_ruby
      nil
    end
  end

  class SExpSymbol < AbstractSExpAtom
    attr_reader :name
    def initialize(name)
      @name = name
    end
    def to_s
      @name
    end
    def to_ruby
      @name.to_sym
    end
  end

  class SExpString < AbstractSExpAtom
    attr_reader :str
    def initialize(str)
      @str = str
    end
    def to_s
      @str.dump
    end
    def to_ruby
      @str
    end
  end
  
  class SExpNumber < AbstractSExpAtom
    def self.int(val)
      SExpNumber.new(:INTEGER, val)
    end
    def self.float(val)
      SExpNumber.new(:FLOAT, val)
    end

    def initialize(type, val)
      @type = type
      @val = val
    end
    def value
      case @type
      when :INTEGER
        @val.to_i
      when :FLOAT
        @val.to_f
      else
        raise "Unknown type #{@type}:#{@val}"
      end
    end
    def to_s
      @val
    end
    def to_ruby
      value
    end
  end

  class AbstractSExpCons < AbstractSExp
    def cons?
      true
    end
  end

  class SExpCons < AbstractSExpCons
    attr_reader :car, :cdr
    def initialize(car, cdr)
      @car = car
      @cdr = cdr
    end
    def visit
      @car = yield @car
      @cdr = yield @cdr
    end
    def to_s
      if @cdr.class == SExpList then
        "(#{@car} "+@cdr.list.map{|i| i.to_s }.join(" ")+")"
      else
        "(#{@car} . #{@cdr})"
      end
    end
    def to_ruby
      [@car.to_ruby, @cdr.to_ruby]
    end
  end

  class SExpList < AbstractSExpCons
    attr_reader :list
    def initialize(list)
      @list = list
    end
    def car
      @list[0]
    end
    def cdr
      if @list.size == 1
        SExpNil.new
      else
        SExpList.new @list.slice(1..-1)
      end
    end
    def list?
      true
    end
    def to_s
      "("+@list.map{|i| i.to_s }.join(" ")+")"
    end
    def visit(&block)
      @list = @list.map(&block)
    end
    def to_ruby
      @list.map {|i| i.to_ruby}
    end
    def alist?
      @list.all? {|i| i.cons? }
    end
    # alist -> hash
    def to_h
      ret = Hash.new
      @list.each do |i|
        ret[i.car.to_ruby] = i.cdr.to_ruby
      end
      ret
    end
  end

  # (list . last)
  class SExpListDot < AbstractSExpCons
    def initialize(list, last)
      @list = list
      @last = last
    end
    def car
      @list[0]
    end
    def cdr
      if @list.size == 2 then
        SExpCons.new(@list[1], @last)
      else
        SExpListDot.new(@list.slice(1..-1),@last)
      end
    end
    def list?
      false
    end
    def to_s
      "("+@list.map{|i| i.to_s }.join(" ") + " . #{@last.to_s})"
    end
    def visit(&block)
      @list = @list.map(&block)
      @last = block.call(@last)
    end
    def to_ruby
      @list.map {|i| i.to_ruby}.push(@last.to_ruby)
    end
  end

  class SExpQuoted < AbstractSExp
    def initialize(sexp)
      @sexp = sexp
    end
    def to_s
      "'#{@sexp.to_s}"
    end
    def visit(&blcok)
      @sexp.visit(&block)
    end
    def to_ruby
      [@sexp.to_ruby]
    end
  end

  class ParserError < StandardError
    attr_reader :message, :pos, :sample
    def initialize(message, pos, sample)
      @message = message
      @pos = pos
      @sample = sample
    end
  end

  # parser class for 
  class Parser

    # parse s-expression string and return one sexp object.
    def parse1(str)
      parse(str)[0]
    end

    # parse s-expression string and return sexp objects.
    def parse(str)
      if str.nil? || str == ""
        raise ParserError.new("Empty input",0,"")
      end

      s = StringScanner.new str
      @tokens = []

      until s.eos?
        s.skip(/\s+/) ? nil :
          s.scan(/\A[-+]?[0-9]*\.[0-9]+(e[-+]?[0-9]+)?/i) ? (@tokens << [:FLOAT, s.matched]) :
          s.scan(/\A[-+]?(0|[1-9]\d*)/)      ? (@tokens << [:INTEGER, s.matched]) :
          s.scan(/\A\.(?=\s)/)               ? (@tokens << ['.', '.']) :
          s.scan(/\A[a-z\-.\/_:*+=$][a-z\-.\/_:$*+=0-9]*/i) ? (@tokens << [:SYMBOL, s.matched]) :
          s.scan(/\A"(([^\\"]|\\.)*)"/)        ? (@tokens << [:STRING, s.matched.slice(1...-1)])  :
          s.scan(/\A./)                      ? (a = s.matched; @tokens << [a, a]) :
          (raise ParserError.new("Scanner error",s.pos,s.peek(5)))
      end
      @tokens.push [false, 'END']

      return do_parse.map do |i|
        normalize(i)
      end
    end

    def next_token
      @tokens.shift
    end

    # replace special symbols
    def normalize(ast)
      if ast.class == SExpSymbol
        case ast.name
        when "nil"
          return SExpNil.new
        else
          return ast
        end
      elsif ast.cons? then
        ast.visit do |i|
          normalize(i)
        end
      end
      return ast
    end
  end

  
  # Translate a ruby object to s-expression string.
  def self.encode(obj)
    return _encode(obj).to_s
  end

  # Translate many ruby objects to s-expression string.
  # The result s-exps are concatenated into one string.
  def self.encode_multi(objs, sep = "\n")
    return objs.map {|obj| _encode(obj).to_s }.join(sep)
  end

  class EncodingError < StandardError
    attr_reader :message, :object
    def initialize(message, object)
      @message = message
      @object = object
    end
    def to_s
      @message
    end
  end

  private 

  def self._encode(arg)
    return "nil" if arg.nil?
    c = arg.class
    if c ==  Fixnum then
      return SExpNumber.new :INTEGER, arg.to_s
    elsif c ==  Float then
      return SExpNumber.new :FLOAT, arg.to_s
    elsif c ==  String then
      return SExpString.new arg
    elsif c ==  Symbol then
      return SExpSymbol.new arg.to_s
    elsif c ==  Array then
      return _encode_array(arg)
    elsif c ==  Hash then
      return _encode_hash(arg)
    elsif c ==  TrueClass then
      return SExpSymbol.new "t"
    elsif c ==  FalseClass then
      return SExpNil.new
    end
    raise EncodingError.new("Can't encode object : #{arg}", arg)
  end

  def self._encode_array(arg)
    return SExpNil.new if arg.nil? || arg.size == 0
    return SExpList.new arg.map{|i| _encode(i)}
  end

  def self._encode_hash(arg)
    return SExpNil.new if arg.nil? || arg.size == 0
    return SExpList.new arg.map{|k,v| SExpCons.new(_encode(k),_encode(v))}
  end

end
