class Elparser::Parser

rule
   target: sexp {}
   
   sexp: nil | val | cons | symbol | string | list | quoted;
   
   sexp_seq: sexp { result = [val[0]] }
           | sexp_seq sexp { result << val[1] }
   
   nil: "(" ")" {
       result = SExpNil.new
   }
   
   val: INTEGER { result = SExpNumber.int(val[0])}
      | FLOAT   { result = SExpNumber.float(val[0])}
   
   cons: "(" sexp_seq "." sexp ")" {
       if val[1].size == 1 then
          result = SExpCons.new(val[1][0], val[3])
       else
          result = SExpListDot.new(val[1], val[3])
       end
   }

   list: "(" sexp_seq ")" {
       result = SExpList.new(val[1])
   }
   
   quoted: "'" sexp {
       result = SExpQuoted.new(val[1])
   }
   
   symbol: SYMBOL {
       result = SExpSymbol.new(val[0])
   }
   
   string: STRING {
       result = SExpString.new(val[0])
   }
   
end
