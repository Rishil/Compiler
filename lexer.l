%{
	#include<stdio.h>
	#include<string.h>
	#include "y.tab.h"
%}
%option yylineno
%%
main {return mainFunction;}
"//".*                                    { /* DO NOTHING */ }
[/][*][^*]*[*]+([^*/][^*]*[*]+)*[/]       { /* DO NOTHING */ }
[/][*]                                    { /* DO NOTHING */ }
[ \n\t]+ ;
int|float|double|char {strcpy(yylval.string,yytext); return typeOfInput; }
[a-zA-Z_][a-zA-Z_\d]* {strcpy(yylval.string,yytext);return anIdentifier; }
[-+]?[0-9]+ |
[-+]?[0-9]+\.[0-9]+ {yylval.numberVar=atof(yytext);return aNumber;}
. return yytext[0];
%%
int yywrap(){
return 1;
}