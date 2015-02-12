# Elparser

A parser for S-expression of emacs lisp and some utilities.

## Sample code

### Parsing S-exp and getting ruby objects

```ruby
require 'elparser'

parser = Elparser::Parser.new

 # list and literals
obj1 = parser.parse1("(1 2.3 a \"b\" () (c 'd))")

p obj1.to_ruby
 # => [1, 2.3, :a, "b", nil, [:c, [:d]]]


 # alist and hash
obj2 = parser.parse("( (a . 1) (b . \"xxx\") (c 3 4) (\"d\" . \"e\"))")

p obj2.to_ruby
 # => [[:a, 1], [:b, "xxx"], [:c, 3, 4], ["d", "e"]] 

p obj2.to_h
 #  => {:a=>1, :b=>"xxx", :c=>[3, 4], "d"=>"e"} 
```

### Encoding ruby objects into S-exp

```ruby
p Elparser::encode([1,1.2,-4,"xxx",:www,true,nil])
 # => "(1 1.2 -4 \"xxx\" www t nil)"
 
p Elparser::encode({:a => [1,2,3], :b => {:c => [4,5,6]}})
 # => "((a 1 2 3) (b (c 4 5 6)))"
```

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'elparser'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install elparser


## API Document

### Parser

The class `Elparser::Parser` is parser for emacs-lisp S-expression.
The user program creates an instance of the class and parses the S-exp
string with `parse1` method. If the source string has multiple
S-expressions, one can use `parse` method.

If the `Parser#parse1` method succeed in parsing the given S-exp
string, it returns a `SExp` object which is AST of S-exp. Invoking
`to_ruby` method of the `SExp` object, one can obtain a ruby object.
`Parser#parse` method returns an array of `SExp` objects.

The `SExp` objects are instances of `SExpXXX` classes: `SExpNumber`,
`SExpString`, `SExpSymbol`, `SExpNil`, `SExpCons`, `SExpList`,
`SExpListDot` and `SExpQuoted`. Each classes represent corresponding
S-exp objects.

If the given S-exp list is an alist, invoking `SExpList#to_h` method,
a `Hash` object can be obtained.

### Encoder

The module method `Elparser::encode` encodes the ruby objects into
elisp S-expressions. The another method `Elparser::encode_multi`
receives an array of ruby objects and returns a S-expression string in
which multiple S-expressions are concatenated.

If an object which is not defined in serialization rules is given,
this method raises the exception `StandardError` with some messages.
See the next section for the encoding detail.

### Object Mapping

The primitive objects are translated straightforwardly.

#### Decoding (S-expression -> Ruby)

A quoted expression is translated to an array.
Both `nil` and `()` are translated to `nil`.
Cons cells and lists are translated to arrays.

| type             | S-exp (input)       | Ruby (output)       |
|------------------|---------------------|---------------------|
| integer          | `1`                 | `1`                 |
| float            | `1.2`               | `1.2`               |
| float            | `1e4`               | `1e4`               |
| float            | `.45`               | `.45`               |
| symbol           | `abc`               | `:abc`              |
| string           | `"abc"`             | `"abc"`             |
| quote            | `'abc`              | `[:abc]`            |
| null             | `nil`               | `nil`               |
| empty list       | `()`                | `nil`               |
| list             | `(1 2)`             | `[1,2]`             |
| nest list        | `(a (b))`           | `[:a [:b]]`         |
| cons cell        | `(a . b)`           | `[:a,:b]`           |
| dot list         | `(a b . d)`         | `[:a,:b,:c]`        |
| alist(`to_ruby`) | `((a . 1) (b . 2))` | `[[:a,1],[:b,2]]`   |
| alist(`to_h`)    | `((a . 1) (b . 2))` | `{:a=>1,:b=>2}`     |
| alist list       | `((a 1 2) (b . 3))` | `{:a=>[1,2],:b=>3}` |

#### Encoding (Ruby -> S-expression)

The Array and Hash objects are translated to lists and alist
respectively.  Cons cells and quoted expressions can't be expressed by
any Ruby object.  If those S-expressions are needed, one can obtain
such S-expressions with creating instances of `SExpCons` and
`SExpQuoted` directly and calling the `to_s` method.

| type       | Ruby (input)                             | S-exp (output)               |
|------------|------------------------------------------|------------------------------|
| primitive  | `[1,1.2,-4,"xxx",:www,true,nil]`         | `(1 1.2 -4 "xxx" www t nil)` |
| empty list | `[]`                                     | `nil`                        |
| nest list  | `[1,[2,[3,4]]]`                          | `(1 (2 (3 4)))`              |
| hash       | `{"a" => "b", "c" => "d"}`               | `(("a" . "b") ("c" . "d"))`  |
| hash       | `{:a => [1,2,3], :b => {:c => [4,5,6]}}` | `((a 1 2 3) (b (c 4 5 6)))`  |

## License

Copyright (c) 2015 SAKURAI Masashi
Released under the MIT license
