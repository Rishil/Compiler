%{
  /* C libraries included */
        #include<stdlib.h>
        #include<stdio.h>
        #include<string.h>
    
    /* Symbol table used to contain the identifiers,
    type of input, and the value */
    struct symbTable {
      char symbolID[10];
      char inputType[10];
      double value;
      } storedSymbol[10];

    /* Temporary buffer for manual input */ 
  typedef struct yy_buffer_state * YY_BUFFER_STATE;
  extern YY_BUFFER_STATE yy_scan_string(char * tempA);
  extern void yy_delete_buffer(YY_BUFFER_STATE buffer);

    extern int yylineno; // Line number declared to be used for yyerror()
    void yyerror (char *s); // Standard error
    int yylex(); // Lexer

    /* Variables initialised to be used later */
  int symbolNo=0;
  int indexVar=0;
  int temporaryVar=0;

  /* Methods for the symbol table and stack */
  int symbolLookup(char []);
  void addToSymbolTable(char [],char [],double);
  void showSymbolTable();   
  void codeGenContents(char [],char [],char [],char []);
  void codeGenerator(); 

  /* Code generator struct containing information to display to the
  user */
  struct codeGen {
      char operator[5];
      char firstOperand[10];
      char secondOperand[10];
      char output[10];
    } generatedCode[25];

    /* Stack info */
  void stackPush(char*);
  char* stackPop();

  struct stackOfVariables {
      char *stackContents[10];
      int highestPoint;
    } newStack;
%}

/* Union containing the number variable to be parsed and the text types (string) */
%union {          
    double numberVar;
    char string[10];
}

/* Operator precedence */
%left '+' '-'
%left '*' '/'

/* Tokens and types declared */
%token mainFunction
%token <numberVar> aNumber
%token <string> typeOfInput
%token <string> anIdentifier
%type <string> theVariables
%type <string> expression

%%
prg: mainFunction '('')''{' body '}' // User has to type main(){} to successfully parse
       ;
body   : varstmt listOfStatements
       ;
varstmt: vardecl varstmt
       |
       ;
vardecl: typeOfInput theVariables ';' 
       ;

theVariables : theVariables ',' anIdentifier {    
              int i;
              i=symbolLookup($3);
              if(i!=-1) printf("\n Symbol with the same identifer before has already been parsed");
                            else addToSymbolTable($3,$<string>0,0);
                  }

      | anIdentifier'='aNumber   {
                      int i;
                      i=symbolLookup($1);
                      if(i!=-1) printf("\n Symbol with the same identifier before has already been parsed");
                      else addToSymbolTable($1,$<string>0,$3);
                    }

    |theVariables ',' anIdentifier '=' aNumber {
                                  int i;
                                  i=symbolLookup($3);
                                  if(i!=-1) printf("\n Symbol with the same identifier before has already been parsed");
                                  else addToSymbolTable($3,$<string>0,$5);   
                               }

    |anIdentifier     {
          int i;
                i=symbolLookup($1);
                if(i!=-1) printf("\n Symbol with the same identifer before has already been parsed");
                else addToSymbolTable($1,$<string>0,0);
            }
    ;

listOfStatements: aStatement listOfStatements
    |
    ;
/* Add the contents of equal statements finishing with a semi-colon to the code generator */
aStatement : anIdentifier '=' aNumber ';'    {
                                      int i;
                                      i=symbolLookup($1);
                                        if(i==-1){
                                          printf("\n Invalid input. Please check the syntax on line: %d\n", yylineno-1);
                                        } else {
                                                  char temp[10];
                                                    if(strcmp(storedSymbol[i].inputType,"int")==0){
                                                      sprintf(temp,"%d",(int)$3);
                                                    } else snprintf(temp,10,"%f",$3);
                                                codeGenContents("=","",temp,$1);
                                              }
                                      }
            | anIdentifier '=' anIdentifier ';'   {
                        int firstInput,secondInput;
                        firstInput=symbolLookup($1);
                        secondInput=symbolLookup($3);
                        if(firstInput==-1 || secondInput==-1){
                        printf("\n Invalid input. Please check the syntax on line: %d\n", yylineno-1);
                        } else codeGenContents("=","",$3,$1);                  
                      }


            | anIdentifier '=' expression ';'   { 
                        codeGenContents("=","",stackPop(),$1);
                      }        
            ;

/*Operator calculations sent to the code generator for output to the user through the stack*/
expression    : expression '+' expression   {
                              char tempA[10],tempB[10]="tempVar";
                                sprintf(tempA, "%d", temporaryVar);   
                                strcat(tempB,tempA);
                                temporaryVar++;
                                codeGenContents("+",stackPop(),stackPop(),tempB);
                                stackPush(tempB);                          
                            }
        |expression '-' expression      {
                              char tempA[10],tempB[10]="tempVar";
                                sprintf(tempA, "%d", temporaryVar);    
                                strcat(tempB,tempA);
                                temporaryVar++;
                                codeGenContents("-",stackPop(),stackPop(),tempB);
                                stackPush(tempB);
                            }   
        |expression '*' expression      {
                            char tempA[10],tempB[10]="tempVar";
                            sprintf(tempA, "%d", temporaryVar);        
                            strcat(tempB,tempA);
                            temporaryVar++;
                            codeGenContents("*",stackPop(),stackPop(),tempB);
                            stackPush(tempB);
                            }       
        |expression '/' expression      {
                            char tempA[10],tempB[10]="tempVar";
                            sprintf(tempA, "%d", temporaryVar);        
                            strcat(tempB,tempA);
                            temporaryVar++;
                            codeGenContents("/",stackPop(),stackPop(),tempB);  
                            stackPush(tempB);
                          }
    
        |anIdentifier     {   
                    int i;
                    i=symbolLookup($1);
                    if(i==-1){
                      printf("\nIncorrect identifier. Please use an integer or float, or a double.\n");
                    } else stackPush($1);         
                }

        |aNumber {
                  char temp[10];
                    snprintf(temp,10,"%f",$1);    
                    stackPush(temp);                 
                }
        ;

%%
extern FILE *yyin; // File to be scanned through

void show(){
  showSymbolTable();
  printf("\n");
  codeGenerator();
}

/* Option to scan a file through for parsing*/   
void parseFile(){
  newStack.highestPoint = -1;
  yyin = fopen("codeExample.parse","r");
  yyparse();
  show();
}

/* Option to type in the code manually */
void manualInput(){
   char userInput[255];
   scanf("%[^\t]",userInput);
   YY_BUFFER_STATE buffer = yy_scan_string(userInput);
   yyparse();
   show();
   yy_delete_buffer(buffer);
}

/* User is presented with options at compiler launch */
void option(){
  char d;
  printf(" Parse an existing file? Y/N:");
  scanf(" %s",&d);
  if (d == 'Y' || d == 'y'){
    parseFile();
  } else if (d == 'N' || d == 'n'){
    printf(" Enter the code followed by a tab space to submit:\n");
    manualInput();
  } else option();
}

/* Main function calling the option(s) */
int main(void)
{
  option();
  return 0;
}

/* Method to lookup a stored symbol */
int symbolLookup(char aSymbol[10]){
  int i,flag=0;
  for(i=0;i<symbolNo;i++){
      if(strcmp(storedSymbol[i].symbolID,aSymbol)==0){
      flag=1;
          break;
      }
    }
    if(flag==0) return(-1);
    else return(i);
}
/* Method to add a new symbol to the symbol table */
void addToSymbolTable(char aSymbol[10],char dtype[10],double val){
  strcpy(storedSymbol[symbolNo].symbolID,aSymbol);
  strcpy(storedSymbol[symbolNo].inputType,dtype);
  storedSymbol[symbolNo].value=val;
  symbolNo++;
}

/* Method to display the symbol table to the user */
void showSymbolTable(){
  int i;
  printf(" ---------------------------------------------------");
  printf("\n Symbols that have been parsed successfully: \n");
  printf(" ---------------------------------------------------");
  for(i=0;i<symbolNo;i++){
      if (storedSymbol[i].value == 0){
        printf("\n\n Zero has been used. Dividing a variable by '%s' will result in a NaN.\n Dividing by itself will result in ∞\n", storedSymbol[i].symbolID);
      }
    printf("\n %s: %s with the value: %f",storedSymbol[i].symbolID,storedSymbol[i].inputType,storedSymbol[i].value);
  }
}

/* Method to display the generation of code */
void codeGenerator(){
  int i;
  printf(" ---------------------------------------------------");
  printf("\n Generating code....\n");
  printf(" ---------------------------------------------------");
  for(i=0;i<indexVar;i++){
    printf("\n %d-->   %s %s %s, %s",i,generatedCode[i].output,generatedCode[i].operator,generatedCode[i].firstOperand,generatedCode[i].secondOperand);
  }
}

/* A method to add parsed contents into the code generator. Parameters include the operator, operands and the output. The index variable is incremented to access the next line that has been parsed. */
void codeGenContents(char op[10],char secondOp[10],char firstOp[10],char finalOutput[10]){
  strcpy(generatedCode[indexVar].operator,op);
  strcpy(generatedCode[indexVar].secondOperand,secondOp);
  strcpy(generatedCode[indexVar].firstOperand,firstOp);
  strcpy(generatedCode[indexVar].output,finalOutput);
  indexVar++;
}

/* Variables are pushed into the stack */
void stackPush(char *tempA){
  newStack.highestPoint++;
  newStack.stackContents[newStack.highestPoint]=(char *)malloc(strlen(tempA)+1);
  strcpy(newStack.stackContents[newStack.highestPoint],tempA);
}

/* Variables are popped from the stack */
char * stackPop(){
  int i;
  if(newStack.highestPoint==-1){
      printf("The stack is currently empty. Please declare variables and operations.\n");
      exit(0);
  }
  char *tempA=(char *)malloc(strlen(newStack.stackContents[newStack.highestPoint])+1);;
  strcpy(tempA,newStack.stackContents[newStack.highestPoint]);
  newStack.highestPoint--;
  return(tempA);
}

/* Standard error printed */  
void yyerror(char *s){
  fprintf(stderr,"Error found on line: %d\n%s\n\n",yylineno-1,s); 
}