%{
//
// FILE: gel.yy -- Grammar file for GEL
//
// $Id$
//

#include <stdlib.h>
#include <assert.h>
#include <ctype.h>
#include "gstream.h"
#include "gtext.h"
#include "gblock.h"
#include "gstack.h"

#include "gnlist.h"

#include "gnumber.h"
#include "tristate.h"
#include "exprtree.h"
#include "match.h"
%}

%name GELCompiler

%define MEMBERS   \
  gText m_Signature; \
  gText m_TypeName; \
  gTriState bval; \
  int ival; \
  double dval; \
  gText tval; \
  gList< int > listdim; \
  int listsep; \
  gList<gTriState> blist; \
  gList<gNumber> dlist; \
  gList<gText> tlist; \
  int current_char, current_line; \
  gText current_expr, current_file, current_rawline; \
  gelEnvironment environment; \
  gelVariableTable* m_GlobalVarTable; \
  gelVariableTable* m_FuncVarTable; \
  gelSignature* m_SigObj; \
  gStack<gText> funcnames; \
  gelExpr *compiled_expr; \
  gelExpr *Compile(const gText &line, const gText &file, int lineno, \
        	   const gText &rawline); \
  gelExpr *MatchAssignment(gelExpr *lhs, gelExpr *rhs); \
  gelExpr *MatchWhile(gelExpr *guard, gelExpr *body); \
  gelExpr *MatchFor(gelExpr *, gelExpr *, gelExpr *, gelExpr *); \
  gelExpr *MatchConditional(gelExpr *, gelExpr *); \
  gelExpr *MatchConditional(gelExpr *, gelExpr *, gelExpr *); \
  gelExpr *DefineFunction( gelSignature* sig ); \
  gelExpr *LookupVar(const gText &); \
  virtual ~GELCompiler(); \
  void RecoverFromError(void); \
  char nextchar(void); \
  void ungetchar(char);

%define CONSTRUCTOR_PARAM      gelVariableTable *vt

%define CONSTRUCTOR_INIT       : m_GlobalVarTable( vt ), m_FuncVarTable( NULL ), m_SigObj( NULL ), compiled_expr(0)

%union  {
  gelExpr *eval;
  gelVariable<gNumber> *lval;
  gBlock<gelExpr *> *exprlist;
}

%type <eval> expression constant list whileloop forloop conditional function 
%type <eval> funcdecl
%type <lval> lvalue
%type <exprlist> parameterlist paramlist

%token LOR
%token LAND
%token LNOT
%token EQU
%token NEQ
%token LTN
%token LEQ
%token GTN
%token GEQ
%token PLUS
%token MINUS
%token STAR
%token SLASH
%token ASSIGN
%token SEMI
%token LBRACK
%token DBLLBRACK
%token RBRACK
%token LBRACE
%token RBRACE
%token RARROW
%token LARROW
%token DBLARROW
%token COMMA
%token HASH
%token DOT
%token CRET
%token UNDERSCORE
%token AMPER
%token WRITE
%token READ

%token PERCENT
%token DIV
%token LPAREN
%token RPAREN

%token IF
%token WHILE
%token FOR
%token QUIT
%token DEFFUNC
%token DELFUNC
%token TYPEDEF
%token INCLUDE

%token NAME
%token BOOLEAN
%token INTEGER
%token FLOAT
%token TEXT
%token STDIN
%token STDOUT
%token gNULL
%token MACHINEPREC
%token RATIONALPREC

%token DEFFUNC


%token CRLF
%token EOC

%right  SEMI
%left  UWRITE
%right  ASSIGN
%left  WRITE  READ
%left  LNOT
%left  LOR
%left  LAND
%nonassoc  EQU  NEQ  LTN  LEQ  GTN  GEQ
%left  PLUS  MINUS  AMPER
%left  STAR  SLASH  PERCENT  DIV  DOT  CARET
%left  UMINUS
%left  HASH  UNDERSCORE

%%

program: expression  EOC  { compiled_expr = $1; return 0; }
       | error EOC    { compiled_expr = 0; RecoverFromError(); return 1; }
       | error CRLF   { compiled_expr = 0; RecoverFromError(); return 1; }
       ;
 
expression:      constant
          |      whileloop
          |      forloop 
	  |      conditional
          |      function
          |      funcdecl
          |      LPAREN expression RPAREN   { $$ = $2; }
          |      expression SEMI expression
              { $$ = environment.Match("Semi", $1, $3); }
          |      expression SEMI
	      { $$ = $1; }
          |      lvalue ASSIGN expression 
              { $$ = MatchAssignment($1, $3); }
/*
	  |      expression ASSIGN
              { $$ = new gclUnAssignment($1); }
*/
          |      WRITE expression   %prec UWRITE
              { $$ = environment.Match("Print", $2); } 
          |      expression HASH expression
              { $$ = environment.Match("NthChild", $1, $3); }
          |      expression UNDERSCORE expression
              { $$ = environment.Match("NthElement", $1, $3); }
          |      expression PLUS expression
              { $$ = environment.Match("Plus", $1, $3); }
          |      expression MINUS expression
              { $$ = environment.Match("Minus", $1, $3); }
          |      expression AMPER expression  
              { $$ = environment.Match("Concat", $1, $3); }
          |      PLUS expression    %prec UMINUS
              { $$ = $2; }
          |      MINUS expression   %prec UMINUS
              { $$ = environment.Match("Negate", $2); }
          |      expression STAR expression
              { $$ = environment.Match("Times", $1, $3); }
          |      expression SLASH expression
              { $$ = environment.Match("Divide", $1, $3); }
          |      expression PERCENT expression
              { $$ = environment.Match("Modulus", $1, $3); }
          |      expression DIV expression
              { $$ = environment.Match("IntegerDivide", $1, $3); }
          |      expression DOT expression
              { $$ = environment.Match("Dot", $1, $3); }
          |      expression CARET expression
              { $$ = environment.Match("Power", $1, $3); }
          |      expression EQU expression
              { $$ = environment.Match("Equal", $1, $3); }
          |      expression NEQ expression
              { $$ = environment.Match("NotEqual", $1, $3); }
          |      expression LTN expression
              { $$ = environment.Match("Less", $1, $3); }
          |      expression LEQ expression
              { $$ = environment.Match("LessEqual", $1, $3); }
          |      expression GTN expression
              { $$ = environment.Match("Greater", $1, $3); }
          |      expression GEQ expression
              { $$ = environment.Match("GreaterEqual", $1, $3); }
          |      LNOT expression
              { $$ = environment.Match("Not", $2); }
          |      expression LAND expression
              { $$ = environment.Match("And", $1, $3); }
          |      expression LOR expression
              { $$ = environment.Match("Or", $1, $3); }
	  |      expression WRITE expression
              { $$ = environment.Match("Write", $1, $3); }
          |      expression READ expression
              { $$ = environment.Match("Read", $1, $3); }
          ;

whileloop:       WHILE LBRACK expression COMMA expression RBRACK
              { $$ = MatchWhile($3, $5); }

forloop:         FOR LBRACK expression COMMA expression COMMA expression 
                 COMMA expression RBRACK
              { $$ = MatchFor($3, $5, $7, $9); }

conditional:     IF LBRACK expression COMMA expression COMMA expression RBRACK
              { $$ = MatchConditional($3, $5, $7); }
           |     IF LBRACK expression COMMA expression RBRACK
              { $$ = MatchConditional($3, $5); }

constant:        FLOAT    { $$ = new gelConstant<gNumber>(dval); }
        |        INTEGER  { $$ = new gelConstant<gNumber>(ival); }
        |        BOOLEAN  { $$ = new gelConstant<gTriState>(bval); }
        |        TEXT     { $$ = new gelConstant<gText>(tval); }
        |        NAME     { $$ = LookupVar(tval); }
        |        QUIT     { $$ = new gelQuitExpr(); }
        |        LBRACE   { dlist.Flush(); tlist.Flush(); blist.Flush(); 
                            listdim.Flush(); listdim.Append( 1 ); 
                            listsep = 1; }
                 list     
                 RBRACE   { $$ = $3; }
        ;

list:            numberlist  { listdim.Append( -listsep );
                               $$ = new gelConstant<gNumber>
                               ( gNestedList<gNumber>( dlist, listdim ) ); }
        |        textlist    { listdim.Append( -listsep );
                               $$ = new gelConstant<gText>
                               ( gNestedList<gText>( tlist, listdim ) ); }
        |        booleanlist { listdim.Append( -listsep );
                               $$ = new gelConstant<gTriState>
                               ( gNestedList<gTriState>( blist, listdim ) ); }
        ;

numberitem:      INTEGER { dlist += gNumber( ival ); ++listsep; }
        |        FLOAT   { dlist += gNumber( dval ); ++listsep; }
        |        listopen numberlist listclose
        ;

numberlist:      numberitem
        |        numberitem COMMA numberlist 
        ;

textitem:        TEXT { tlist += tval; ++listsep; }
        |        listopen textlist listclose
        ;

textlist:        textitem
        |        textitem COMMA textlist
        ;

booleanitem:     BOOLEAN { blist += bval; ++listsep; }
        |        listopen booleanlist listclose
        ;

booleanlist:     booleanitem
        |        booleanitem COMMA booleanlist 
        ;

listopen:        LBRACE { listdim.Append( listsep ); listsep = 1; } 
        ;

listclose:       RBRACE { listdim.Append( -listsep ); listsep = 1; }
        ;


lvalue:          NAME  { $$ = new gelVariable<gNumber>(tval); }

function:        NAME  { funcnames.Push(tval); }  LBRACK
                 parameterlist RBRACK
                 { $$ = environment.Match(funcnames.Pop(), *$4);
                   delete $4; }  

parameterlist:   { $$ = new gBlock<gelExpr *>; }
             |   paramlist
 

paramlist:       expression    { $$ = new gBlock<gelExpr *>;
	                         $$->Append($1); } 
         |       paramlist COMMA expression
                  { $$ = $1;  $$->Append($3); }
         ; 



funcdecl:        DEFFUNC { if (m_FuncVarTable) YYERROR;  
                           m_FuncVarTable = new gelVariableTable; }
                 LBRACK 
                 signature { assert( !m_SigObj );
                             m_SigObj = new gelSignature( m_Signature ); 
                             m_SigObj->DefineParams( m_FuncVarTable ); }
                 COMMA 
                 expression 
                 RBRACK
                 { delete m_FuncVarTable; m_FuncVarTable = NULL; 
                   if( $7 == NULL ) YYERROR;
                   m_SigObj->SetUdf( $7 );
                   $$ = DefineFunction( m_SigObj ); 
                   m_SigObj = NULL; /* do not delete m_SigObj! */ }


signature:       NAME       { m_Signature = tval; }   
                 LBRACK     { m_Signature += '['; }
                 formalparams
                 RBRACK     { m_Signature += ']'; }
                 typeOpt

typeOpt:         { m_Signature += "=:ANYTYPE"; }
       |         TYPEDEF  { m_Signature += "=:"; m_TypeName = ""; } 
                 typename { m_Signature += m_TypeName; }

typename:        NAME   { m_TypeName += tval; }
        |        NAME   { m_TypeName += tval; } 
                 STAR   { m_TypeName += '*'; }
        |        NAME   { m_TypeName += tval; }
                 LPAREN { m_TypeName += '('; }
                 typename
                 RPAREN { m_TypeName += ')'; }

formalparams:    
            |    formalparam 
            |    formalparams 
                 COMMA        { m_Signature += ','; }
                 formalparam

formalparam:     NAME     { m_Signature += tval; }  
                 binding  { m_TypeName = ""; }
                 typename { m_Signature += m_TypeName; }
           |     LBRACE   { m_Signature += '{'; }
                 NAME     { m_Signature += tval; }
                 binding  { m_TypeName = ""; }
                 typename { m_Signature += m_TypeName; }
                 RBRACE   { m_Signature += '}'; }

binding:         RARROW    { m_Signature += "->";  }
       |         DBLARROW  { m_Signature += "<->"; }




%%


const char CR = (char) 10;


char GELCompiler::nextchar(void)
{
  char c = current_expr[current_char];
  if( c == '\r' || c == '\n' )
    ++current_line;
  ++current_char;
  return c;
}

void GELCompiler::ungetchar(char /*c*/)
{
  char c = current_expr[current_char-1];
  if( (current_char > 0) && (c == '\r' || c == '\n') )
    --current_line;
  --current_char;
}

typedef struct tokens  { long tok; char *name; } TOKENS_T;

void GELCompiler::yyerror(char *s)
{
static struct tokens toktable[] =
{ { LOR, "OR or ||" },  { LAND, "AND or &&" }, { LNOT, "NOT or !" },
    { EQU, "=" }, { NEQ, "!=" }, { LTN, "<" }, { LEQ, "<=" },
    { GTN, ">" }, { GEQ, ">=" }, { PLUS, "+" }, { MINUS, "-" },
    { STAR, "*" }, { SLASH, "/" }, { ASSIGN, ":=" }, { SEMI, ";" },
    { LBRACK, "[" }, { DBLLBRACK, "[[" }, { RBRACK, "]" },
    { LBRACE, "{" }, { RBRACE, "}" }, { RARROW, "->" },
    { LARROW, "<-" }, { DBLARROW, "<->" }, { COMMA, "," }, { HASH, "#" },
    { DOT, "." }, { CARET, "^" }, { UNDERSCORE, "_" },
    { AMPER, "&" }, { WRITE, "<<" }, { READ, ">>" },
    { IF, "If" }, { WHILE, "While" }, { FOR, "For" },
    { QUIT, "Quit" }, 
    { DEFFUNC, "NewFunction" }, 
    { DELFUNC, "DeleteFunction" },
    { TYPEDEF, "=:" },
    { INCLUDE, "Include" },
    { PERCENT, "%" }, { DIV, "DIV" }, { LPAREN, "(" }, { RPAREN, ")" },
    { CRLF, "carriage return" }, { EOC, "carriage return" }, { 0, 0 }
};
  gerr << s << " at line " << current_line << " in file " << current_file
       << ": ";

  for (int i = 0; toktable[i].tok != 0; i++)
    if (toktable[i].tok == yychar)   {
      gerr << toktable[i].name << '\n';
      return;
    }
  switch (yychar)   {
    case NAME:
      gerr << "identifier " << tval << '\n';
      break;
    case BOOLEAN:
      gerr << ((bval) ? "True" : "False") << '\n';
      break;
    case FLOAT:
      gerr << "floating-point constant " << dval << '\n';
      break;
    case INTEGER:
      gerr << "integer constant " << ival << '\n';
      break;
    case TEXT:
      gerr << "text string " << tval << '\n';
      break;
    case STDIN:
      gerr << "StdIn\n";
      break;
    case STDOUT:
      gerr << "StdOut\n";
      break;
    case gNULL:
      gerr << "NullOut\n";
      break;
    default:
      if (isprint(yychar) && !isspace(yychar))
        gerr << ((char) yychar) << '\n';
      else 
        gerr << "nonprinting character " << yychar << '\n';
      break;
  }    
}

int GELCompiler::yylex(void)
{
  char c;
  
  do  {
    c = nextchar();
  }  while (isspace(c) || c == '\r' || c == '\n');

  if (isalpha(c))  {
    gText s(c);
    c = nextchar();
    while (isalpha(c) || isdigit(c))   {
      s += c;
      c = nextchar();
    }
    ungetchar(c);

    if (s == "True")   {
      bval = triTRUE;
      return BOOLEAN;
    }
    else if (s == "False")  {
      bval = triFALSE;
      return BOOLEAN;
    }
    else if (s == "Maybe")  {
      bval = triMAYBE;
      return BOOLEAN;
    }
 
    else if (s == "StdIn")  return STDIN;
    else if (s == "StdOut") return STDOUT;
    else if (s == "NullOut")   return gNULL;
    else if (s == "AND")    return LAND;
    else if (s == "OR")     return LOR;
    else if (s == "NOT")    return LNOT;
    else if (s == "DIV")    return DIV;
    else if (s == "MOD")    return PERCENT;
    else if (s == "If")     return IF;
    else if (s == "While")  return WHILE;
    else if (s == "For")    return FOR;
    else if (s == "Quit")   return QUIT;
    else if (s == "NewFunction")   return DEFFUNC;
    else if (s == "DeleteFunction")   return DELFUNC;
    else if (s == "Machine")   return MACHINEPREC;
    else if (s == "Rational")  return RATIONALPREC;
    else if (s == "Include")   return INCLUDE;
    else  { tval = s; return NAME; }
  }

  if (c == '"')   {
    tval = "";
    while (true)  {
      c = nextchar();
      if (c == '"')  break;
      tval += c;
    }
    return TEXT;
  }

  if (isdigit(c))   {
    gText s(c);
    c = nextchar();
    while (isdigit(c))   {
      s += c;
      c = nextchar();
    }

    if (c == '.')   {
      s += c;
      c = nextchar();
      while (isdigit(c))  {
	s += c;
	c = nextchar();
      }

      ungetchar(c);
      dval = atof((char *) s);
      return FLOAT;
    }
    else  {
      ungetchar(c);
      ival = atoi((char *) s);
      return INTEGER;
    }
  }

  switch (c)  {
    case ',':   return COMMA;
    case '.':   c = nextchar();
      if (c < '0' || c > '9')  { ungetchar(c);  return DOT; }
      else  {
	gText s(".");
	s += c;
        c = nextchar();
        while (isdigit(c))  {
	  s += c;
	  c = nextchar();
        }

        ungetchar(c);
        dval = atof((char *) s);
        return FLOAT;
      }

    case ';':   return SEMI;
    case '_':   return UNDERSCORE;
    case '(':   return LPAREN;
    case ')':   return RPAREN;
    case '{':   return LBRACE;
    case '}':   return RBRACE;
    case '+':   return PLUS;
    case '-':   c = nextchar();
                if (c == '>')  return RARROW;
                else  { ungetchar(c);  return MINUS; }
    case '*':   return STAR;
    case '/':   return SLASH;
    case '%':   return PERCENT;
    case '=':   c = nextchar();
                if (c == ':')  return TYPEDEF;
                else   { ungetchar(c);  return EQU; }  
    case '#':   return HASH;
    case '^':   return CARET;
    case '[':   c = nextchar();
                if (c == '[')  return DBLLBRACK;
                else   {
		  ungetchar(c);
		  return LBRACK;
		}
    case ']':   return RBRACK;
    case ':':   c = nextchar();
                if (c == '=')  return ASSIGN;
                else   { ungetchar(c);  return ':'; }  
    case '!':   c = nextchar();
                if (c == '=')  return NEQ;
		else   { ungetchar(c);  return LNOT; }
    case '<':   c = nextchar();
                if (c == '=')  return LEQ;
	        else if (c == '<')  return WRITE; 
                else if (c != '-')  { ungetchar(c);  return LTN; }
                else   { 
		  c = nextchar();
		  if (c == '>')   return DBLARROW;
		  ungetchar(c);
		  return LARROW;
		}
    case '>':   c = nextchar();
                if (c == '=')  return GEQ;
                else if (c == '>')  return READ;
                else   { ungetchar(c);  return GTN; }
    case '&':   c = nextchar();
                if (c == '&')  return LAND;
                else   { ungetchar(c);  return AMPER; }
    case '|':   c = nextchar();
                if (c == '|')  return LOR;
                else   { ungetchar(c);  return '|'; }
    case '\0':  return EOC;
    case CR:    assert(0);
    default:    return c;
  }
}

gelExpr *GELCompiler::Compile(const gText& line, const gText &file, int lineno,
        	              const gText& rawline )
{
  current_expr = line;
  current_char = 0;
  current_file = file;
  current_line = lineno;
  current_rawline = rawline;

  for (int i = 0; i < line.Length(); i++)   {
    if (!isspace(line[i]))  {
      if (!yyparse()) 
	return compiled_expr;
      else
	return 0;
    }		
  }

  return 0;
}


void GELCompiler::RecoverFromError(void)
{
  delete m_FuncVarTable;
  m_FuncVarTable = NULL;
  delete m_SigObj;
  m_SigObj = NULL;
}

gelExpr *GELCompiler::MatchAssignment(gelExpr *lhs, gelExpr *rhs)
{
  if (!lhs || !rhs)   {
    if (lhs)   delete lhs;
    if (rhs)   delete rhs;
    return 0;
  }

  gelVariableTable* vartable = m_GlobalVarTable;
  if( m_FuncVarTable )
    vartable = m_FuncVarTable;

  switch (rhs->Type())   {
    case gelBOOLEAN:
      vartable->Define(((gelVariable<gTriState> *) lhs)->Name(), gelBOOLEAN);  
      return new gelAssignment<gTriState>(((gelVariable<gTriState> *) lhs)->Name(),
		   		        ((gelExpression<gTriState> *) rhs));
    case gelNUMBER:
      vartable->Define(((gelVariable<gNumber> *) lhs)->Name(), gelNUMBER);  
      return new gelAssignment<gNumber>(((gelVariable<gNumber> *) lhs)->Name(),
		   		        ((gelExpression<gNumber> *) rhs));
    case gelTEXT:
      vartable->Define(((gelVariable<gText> *) lhs)->Name(), gelTEXT);  
      return new gelAssignment<gText>(((gelVariable<gText> *) lhs)->Name(),
		   		      ((gelExpression<gText> *) rhs));
    case gelEFG:
      vartable->Define(((gelVariable<Efg *> *) lhs)->Name(), gelEFG);
      return new gelAssignment<Efg *>(((gelVariable<Efg *> *) lhs)->Name(),
				      ((gelExpression<Efg *> *) rhs));
    case gelNODE:
      vartable->Define(((gelVariable<Node *> *) lhs)->Name(), gelNODE);
      return new gelAssignment<Node *>(((gelVariable<Node *> *) lhs)->Name(),
				      ((gelExpression<Node *> *) rhs));
    case gelACTION:
      vartable->Define(((gelVariable<Action *> *) lhs)->Name(), gelACTION);
      return new gelAssignment<Action *>(((gelVariable<Action *> *) lhs)->Name(),
				      ((gelExpression<Action *> *) rhs));
    case gelINFOSET:
      vartable->Define(((gelVariable<Infoset *> *) lhs)->Name(), gelINFOSET);
      return new gelAssignment<Infoset *>(((gelVariable<Infoset *> *) lhs)->Name(),
				      ((gelExpression<Infoset *> *) rhs));
    case gelEFPLAYER:
      vartable->Define(((gelVariable<EFPlayer *> *) lhs)->Name(), gelEFPLAYER);
      return new gelAssignment<EFPlayer *>(((gelVariable<EFPlayer *> *) lhs)->Name(),
				      ((gelExpression<EFPlayer *> *) rhs));
    case gelEFOUTCOME:
      vartable->Define(((gelVariable<EFOutcome *> *) lhs)->Name(), gelEFOUTCOME);
      return new gelAssignment<EFOutcome *>(((gelVariable<EFOutcome *> *) lhs)->Name(),
				      ((gelExpression<EFOutcome *> *) rhs));
    case gelEFSUPPORT:
      vartable->Define(((gelVariable<EFSupport *> *) lhs)->Name(), gelEFSUPPORT);
      return new gelAssignment<EFSupport *>(((gelVariable<EFSupport *> *) lhs)->Name(),
				      ((gelExpression<EFSupport *> *) rhs));
    case gelBEHAV:
      vartable->Define(((gelVariable<BehavSolution *> *) lhs)->Name(), gelBEHAV);
      return new gelAssignment<BehavSolution *>(((gelVariable<BehavSolution *> *) lhs)->Name(),
				      ((gelExpression<BehavSolution *> *) rhs));
    case gelNFG:
      vartable->Define(((gelVariable<Nfg *> *) lhs)->Name(), gelNFG);
      return new gelAssignment<Nfg *>(((gelVariable<Nfg *> *) lhs)->Name(),
				      ((gelExpression<Nfg *> *) rhs));
    case gelSTRATEGY:
      vartable->Define(((gelVariable<Strategy *> *) lhs)->Name(), gelSTRATEGY);
      return new gelAssignment<Strategy *>(((gelVariable<Strategy *> *) lhs)->Name(),
				      ((gelExpression<Strategy *> *) rhs));
    case gelNFPLAYER:
      vartable->Define(((gelVariable<NFPlayer *> *) lhs)->Name(), gelNFPLAYER);
      return new gelAssignment<NFPlayer *>(((gelVariable<NFPlayer *> *) lhs)->Name(),
				      ((gelExpression<NFPlayer *> *) rhs));
    case gelNFOUTCOME:
      vartable->Define(((gelVariable<NFOutcome *> *) lhs)->Name(), gelNFOUTCOME);
      return new gelAssignment<NFOutcome *>(((gelVariable<NFOutcome *> *) lhs)->Name(),
				      ((gelExpression<NFOutcome *> *) rhs));
    case gelNFSUPPORT:
      vartable->Define(((gelVariable<NFSupport *> *) lhs)->Name(), gelNFSUPPORT);
      return new gelAssignment<NFSupport *>(((gelVariable<NFSupport *> *) lhs)->Name(),
				      ((gelExpression<NFSupport *> *) rhs));
    case gelMIXED:
      vartable->Define(((gelVariable<MixedSolution *> *) lhs)->Name(), gelMIXED);
      return new gelAssignment<MixedSolution *>(((gelVariable<MixedSolution *> *) lhs)->Name(),
				      ((gelExpression<MixedSolution *> *) rhs));
    default:
      delete lhs;
      delete rhs;
      return 0;
  }
}

gelExpr *GELCompiler::MatchWhile(gelExpr *guard, gelExpr *body)
{
  if (!guard || !body)   {
    if (guard)   delete guard;
    if (body)    delete body;
  }

  if (guard->Type() != gelBOOLEAN)  {
    delete guard;
    delete body;
    return 0;
  }

  switch (body->Type())   {
    case gelBOOLEAN:
      return new gelWhileLoop<gTriState>(((gelExpression<gTriState> *) guard),
	  	   		         ((gelExpression<gTriState> *) body));
    case gelNUMBER:
      return new gelWhileLoop<gNumber>(((gelExpression<gTriState> *) guard),
	  	   		       ((gelExpression<gNumber> *) body));
    case gelTEXT:
      return new gelWhileLoop<gText>(((gelExpression<gTriState> *) guard),
	  	   		     ((gelExpression<gText> *) body));
    case gelEFG:
      return new gelWhileLoop<Efg *>(((gelExpression<gTriState> *) guard),
				     ((gelExpression<Efg *> *) body));
    case gelNODE:
      return new gelWhileLoop<Node *>(((gelExpression<gTriState> *) guard),
				     ((gelExpression<Node *> *) body));
    case gelACTION:
      return new gelWhileLoop<Action *>(((gelExpression<gTriState> *) guard),
				     ((gelExpression<Action *> *) body));
    case gelINFOSET:
      return new gelWhileLoop<Infoset *>(((gelExpression<gTriState> *) guard),
				     ((gelExpression<Infoset *> *) body));
    case gelEFPLAYER:
      return new gelWhileLoop<EFPlayer *>(((gelExpression<gTriState> *) guard),
				     ((gelExpression<EFPlayer *> *) body));
    case gelEFOUTCOME:
      return new gelWhileLoop<EFOutcome *>(((gelExpression<gTriState> *) guard),
				     ((gelExpression<EFOutcome *> *) body));
    case gelEFSUPPORT:
      return new gelWhileLoop<EFSupport *>(((gelExpression<gTriState> *) guard),
					   ((gelExpression<EFSupport *> *) body));
    case gelBEHAV:
      return new gelWhileLoop<BehavSolution *>(((gelExpression<gTriState> *) guard),
					       ((gelExpression<BehavSolution *> *) body));
    case gelNFG:
      return new gelWhileLoop<Nfg *>(((gelExpression<gTriState> *) guard),
				     ((gelExpression<Nfg *> *) body));
    case gelSTRATEGY:
      return new gelWhileLoop<Strategy *>(((gelExpression<gTriState> *) guard),
				     ((gelExpression<Strategy *> *) body));
    case gelNFPLAYER:
      return new gelWhileLoop<NFPlayer *>(((gelExpression<gTriState> *) guard),
				     ((gelExpression<NFPlayer *> *) body));
    case gelNFOUTCOME:
      return new gelWhileLoop<NFOutcome *>(((gelExpression<gTriState> *) guard),
				     ((gelExpression<NFOutcome *> *) body));
    case gelNFSUPPORT:
      return new gelWhileLoop<NFSupport *>(((gelExpression<gTriState> *) guard),
				     ((gelExpression<NFSupport *> *) body));
    case gelMIXED:
      return new gelWhileLoop<MixedSolution *>(((gelExpression<gTriState> *) guard),
				     ((gelExpression<MixedSolution *> *) body));

    default:
      delete guard;
      delete body;
      return 0;
  }
}

gelExpr *GELCompiler::MatchFor(gelExpr *init, gelExpr *guard,
			       gelExpr *incr, gelExpr *body)
{
  if (!init || !guard || !incr || !body)   {
    if (init)  delete init;
    if (guard) delete guard;
    if (incr)  delete incr;
    if (body)  delete body;
    return 0;
  }

  if (guard->Type() != gelBOOLEAN)   {
    delete init;
    delete guard;
    delete incr;
    delete body;
    return 0;
  }

  switch (body->Type())   {
    case gelBOOLEAN:
      return new gelForLoop<gTriState>(init,
				       (gelExpression<gTriState> *) guard,
                                       incr,
                                       (gelExpression<gTriState> *) body);
    case gelNUMBER:
      return new gelForLoop<gNumber>(init,
				     (gelExpression<gTriState> *) guard,
                                     incr,
                                     (gelExpression<gNumber> *) body);
    case gelTEXT:
      return new gelForLoop<gText>(init,
				   (gelExpression<gTriState> *) guard,
                                   incr,
                                   (gelExpression<gText> *) body);
    case gelEFG:
      return new gelForLoop<Efg *>(init,
				   (gelExpression<gTriState> *) guard,
				   incr,
				   (gelExpression<Efg *> *) body);
    case gelNODE:
      return new gelForLoop<Node *>(init,
				   (gelExpression<gTriState> *) guard,
				   incr,
				   (gelExpression<Node *> *) body);
    case gelACTION:
      return new gelForLoop<Action *>(init,
				   (gelExpression<gTriState> *) guard,
				   incr,
				   (gelExpression<Action *> *) body);
    case gelINFOSET:
      return new gelForLoop<Infoset *>(init,
				   (gelExpression<gTriState> *) guard,
				   incr,
				   (gelExpression<Infoset *> *) body);
    case gelEFPLAYER:
      return new gelForLoop<EFPlayer *>(init,
				   (gelExpression<gTriState> *) guard,
				   incr,
				   (gelExpression<EFPlayer *> *) body);
    case gelEFSUPPORT:
      return new gelForLoop<EFSupport *>(init,
				   (gelExpression<gTriState> *) guard,
				   incr,
				   (gelExpression<EFSupport *> *) body);
    case gelBEHAV:
      return new gelForLoop<BehavSolution *>(init,
				   (gelExpression<gTriState> *) guard,
				   incr,
				   (gelExpression<BehavSolution *> *) body);
    case gelNFG:
      return new gelForLoop<Nfg *>(init,
				   (gelExpression<gTriState> *) guard,
				   incr,
				   (gelExpression<Nfg *> *) body);
    case gelSTRATEGY:
      return new gelForLoop<Strategy *>(init,
				   (gelExpression<gTriState> *) guard,
				   incr,
				   (gelExpression<Strategy *> *) body);
    case gelNFPLAYER:
      return new gelForLoop<NFPlayer *>(init,
				   (gelExpression<gTriState> *) guard,
				   incr,
				   (gelExpression<NFPlayer *> *) body);
    case gelNFOUTCOME:
      return new gelForLoop<NFOutcome *>(init,
				   (gelExpression<gTriState> *) guard,
				   incr,
				   (gelExpression<NFOutcome *> *) body);
    case gelNFSUPPORT:
      return new gelForLoop<NFSupport *>(init,
				   (gelExpression<gTriState> *) guard,
				   incr,
				   (gelExpression<NFSupport *> *) body);
    case gelMIXED:
      return new gelForLoop<MixedSolution *>(init,
				   (gelExpression<gTriState> *) guard,
				   incr,
				   (gelExpression<MixedSolution *> *) body);
    default:
      delete init;
      delete guard;
      delete incr;
      delete body;
      return 0;
  }
}

gelExpr *GELCompiler::MatchConditional(gelExpr *guard,
			               gelExpr *iftrue, gelExpr *iffalse)
{
  if (!guard || !iftrue || !iffalse)   {
    if (guard)   delete guard;
    if (iftrue)  delete iftrue;
    if (iffalse) delete iffalse;
    return 0;
  }

  if (guard->Type() != gelBOOLEAN ||
      iftrue->Type() != iffalse->Type())   {
    delete guard;
    delete iftrue;
    delete iffalse;
  }

  switch (iftrue->Type())   {
    case gelBOOLEAN:
      return new gelConditional<gTriState>((gelExpression<gTriState> *) guard, 
	    	   		           (gelExpression<gTriState> *) iftrue,
					   (gelExpression<gTriState> *) iffalse);
    case gelNUMBER:
      return new gelConditional<gNumber>((gelExpression<gTriState> *) guard, 
	    	   		         (gelExpression<gNumber> *) iftrue,
					 (gelExpression<gNumber> *) iffalse);
    case gelTEXT:
      return new gelConditional<gText>((gelExpression<gTriState> *) guard, 
	    	   		       (gelExpression<gText> *) iftrue,
				       (gelExpression<gText> *) iffalse);
    case gelEFG:
      return new gelConditional<Efg *>((gelExpression<gTriState> *) guard, 
	    	   		       (gelExpression<Efg *> *) iftrue,
				       (gelExpression<Efg *> *) iffalse);
    case gelNODE:
      return new gelConditional<Node *>((gelExpression<gTriState> *) guard, 
	    	   		       (gelExpression<Node *> *) iftrue,
				       (gelExpression<Node *> *) iffalse);
    case gelACTION:
      return new gelConditional<Action *>((gelExpression<gTriState> *) guard, 
	    	   		       (gelExpression<Action *> *) iftrue,
				       (gelExpression<Action *> *) iffalse);
    case gelINFOSET:
      return new gelConditional<Infoset *>((gelExpression<gTriState> *) guard, 
	    	   		       (gelExpression<Infoset *> *) iftrue,
				       (gelExpression<Infoset *> *) iffalse);
    case gelEFPLAYER:
      return new gelConditional<EFPlayer *>((gelExpression<gTriState> *) guard, 
	    	   		       (gelExpression<EFPlayer *> *) iftrue,
				       (gelExpression<EFPlayer *> *) iffalse);
    case gelEFOUTCOME:
      return new gelConditional<EFOutcome *>((gelExpression<gTriState> *) guard, 
	    	   		       (gelExpression<EFOutcome *> *) iftrue,
				       (gelExpression<EFOutcome *> *) iffalse);
    case gelEFSUPPORT:
      return new gelConditional<EFSupport *>((gelExpression<gTriState> *) guard, 
	    	   		       (gelExpression<EFSupport *> *) iftrue,
				       (gelExpression<EFSupport *> *) iffalse);
    case gelBEHAV:
      return new gelConditional<BehavSolution *>((gelExpression<gTriState> *) guard, 
	    	   		       (gelExpression<BehavSolution *> *) iftrue,
				       (gelExpression<BehavSolution *> *) iffalse);
    case gelNFG:
      return new gelConditional<Nfg *>((gelExpression<gTriState> *) guard, 
	    	   		       (gelExpression<Nfg *> *) iftrue,
				       (gelExpression<Nfg *> *) iffalse);
    case gelSTRATEGY:
      return new gelConditional<Strategy *>((gelExpression<gTriState> *) guard, 
	    	   		       (gelExpression<Strategy *> *) iftrue,
				       (gelExpression<Strategy *> *) iffalse);
    case gelNFPLAYER:
      return new gelConditional<NFPlayer *>((gelExpression<gTriState> *) guard, 
	    	   		       (gelExpression<NFPlayer *> *) iftrue,
				       (gelExpression<NFPlayer *> *) iffalse);
    case gelNFOUTCOME:
      return new gelConditional<NFOutcome *>((gelExpression<gTriState> *) guard, 
	    	   		       (gelExpression<NFOutcome *> *) iftrue,
				       (gelExpression<NFOutcome *> *) iffalse);
    case gelNFSUPPORT:
      return new gelConditional<NFSupport *>((gelExpression<gTriState> *) guard, 
	    	   		       (gelExpression<NFSupport *> *) iftrue,
				       (gelExpression<NFSupport *> *) iffalse);
    case gelMIXED:
      return new gelConditional<MixedSolution *>((gelExpression<gTriState> *) guard, 
	    	   		       (gelExpression<MixedSolution *> *) iftrue,
				       (gelExpression<MixedSolution *> *) iffalse);
      
    default:
      delete guard;
      delete iftrue;
      delete iffalse;
      return 0;
  }
}

gelExpr *GELCompiler::MatchConditional(gelExpr *guard, gelExpr *iftrue)
{
  if (!guard || !iftrue)   {
    if (guard)  delete guard;
    if (iftrue) delete iftrue;
    return 0;
  }

  if (guard->Type() != gelBOOLEAN)  {
    delete guard;
    delete iftrue;
    return 0;
  }

  switch (iftrue->Type())   {
    case gelBOOLEAN:
      return new gelConditional<gTriState>((gelExpression<gTriState> *) guard, 
	    	   		           (gelExpression<gTriState> *) iftrue,
					   new gelConstant<gTriState>(triFALSE));
    case gelNUMBER:
      return new gelConditional<gNumber>((gelExpression<gTriState> *) guard, 
	    	   		         (gelExpression<gNumber> *) iftrue,
					 new gelConstant<gNumber>(0));
    case gelTEXT:
      return new gelConditional<gText>((gelExpression<gTriState> *) guard, 
	    	   		       (gelExpression<gText> *) iftrue,
				       new gelConstant<gText>(""));

    default:
      delete guard;
      delete iftrue;
      return 0;
  }
}



gelExpr* GELCompiler::DefineFunction( gelSignature* sig )
{
  environment.Register( sig );
  return new gelConstant< gNumber >( 0 );
}



gelExpr *GELCompiler::LookupVar(const gText &name)
{ 

  gelVariableTable* vartable = m_GlobalVarTable;
  if( m_FuncVarTable )
    vartable = m_FuncVarTable;


  if (!vartable->IsDefined(name))  return 0;

  switch (vartable->Type(name))   {
    case gelNUMBER:
      return new gelVariable<gNumber>(name);
    case gelBOOLEAN:
      return new gelVariable<gTriState>(name);
    case gelTEXT:
      return new gelVariable<gText>(name);
    case gelEFG:
      return new gelVariable<Efg *>(name); 
    case gelNODE:
      return new gelVariable<Node *>(name); 
    case gelACTION:
      return new gelVariable<Action *>(name); 
    case gelINFOSET:
      return new gelVariable<Infoset *>(name); 
    case gelEFPLAYER:
      return new gelVariable<EFPlayer *>(name); 
    case gelEFOUTCOME:
      return new gelVariable<EFOutcome *>(name); 
    case gelEFSUPPORT:
      return new gelVariable<EFSupport *>(name);
    case gelBEHAV:
      return new gelVariable<BehavSolution *>(name); 
    case gelNFG:
      return new gelVariable<Nfg *>(name); 
    case gelSTRATEGY:
      return new gelVariable<Strategy *>(name); 
    case gelNFPLAYER:
      return new gelVariable<NFPlayer *>(name); 
    case gelNFOUTCOME:
      return new gelVariable<NFOutcome *>(name); 
    case gelNFSUPPORT:
      return new gelVariable<NFSupport *>(name);
    case gelMIXED:
      return new gelVariable<MixedSolution *>(name);
    default:
      return 0;
  }
}   
    
GELCompiler::~GELCompiler()
{
}


#include "gstack.imp"

template class gStack<gText>;
template class gStack<int>;
template class gStack<gInput *>;

#include "gblock.imp"

template class gBlock<gelExpr *>;


