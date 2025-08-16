#include  <stdio.h>
#include <signal.h>
#include  <sys/types.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include<sys/wait.h>
#define MAX_INPUT_SIZE 1024
#define MAX_TOKEN_SIZE 64
#define MAX_NUM_TOKENS 64
#define MAX_BG_PROCESSES 64
/* Splits the string by space and returns the array of tokens
*
*/

struct backgroundJobs{
  pid_t pid;
  char cmd[1024];
} backgroundProcesses[MAX_BG_PROCESSES]; 

void killBackgroundProcesses(){
  for(int i = 0; i<MAX_BG_PROCESSES; i++){
    kill(backgroundProcesses[i].pid,9);
    waitpid(-1, &status, WNOHANG);
  }
}



int bgp=0; 
void reapKids(){
  int status;
  while(1){
    pid_t pid = waitpid(-1, &status, WNOHANG);
    if(pid<=0){break;}
    for(int i = 0; i<MAX_BG_PROCESSES; i++){
      if(backgroundProcesses[i].pid == pid)
      {
	backgroundProcesses[i].pid = 0;
	if(WIFEXITED(status)){
	  if(WEXITSTATUS(status)==0){
	    printf("%s\n", backgroundProcesses[i].cmd);
	    printf("[+] Background process %d completed successfully\n",pid);
	  }
	  else if(WEXITSTATUS(status)==1){
	    printf("%s\n", backgroundProcesses[i].cmd);
	    printf("[-] Background process %d completed successfully\n",pid);
	  }
	  else if(WEXITSTATUS(status)==127){
	    printf("%s\n", backgroundProcesses[i].cmd);
	    printf("[-] Background command issued isn't correct\n");
	  }
	}
	break;
      }

    }
  }
}

char **tokenize(char *line)
{
  char **tokens = (char **)malloc(MAX_NUM_TOKENS * sizeof(char *));
  char *token = (char *)malloc(MAX_TOKEN_SIZE * sizeof(char));
  int i, tokenIndex = 0, tokenNo = 0;

  for(i =0; i < strlen(line); i++){

    char readChar = line[i];

    if (readChar == ' ' || readChar == '\n' || readChar == '\t'){
      token[tokenIndex] = '\0';
      if (tokenIndex != 0){
	tokens[tokenNo] = (char*)malloc(MAX_TOKEN_SIZE*sizeof(char));
	strcpy(tokens[tokenNo++], token);
	tokenIndex = 0; 
      }
    } else {
      token[tokenIndex++] = readChar;
    }
  }

  free(token);
  tokens[tokenNo] = NULL ;
  return tokens;
}


int main(int argc, char* argv[]) {
  char  line[MAX_INPUT_SIZE];            
  char  **tokens;              
  int i;
  int errorCode;
  pid_t pid;
  int background=0;
  signal(SIGINT, SIG_IGN);
  while(1) {			
    /* BEGIN: TAKING INPUT */
    reapKids();
    bzero(line, sizeof(line));
    printf("$ ");
    scanf("%[^\n]", line);
    getchar();


    if(line[0]=='\0'){continue;}
    if(line[strlen(line)-1]=='&'){
      printf("Process is background\n");
      background = 1;
      line[strlen(line)-1]='\0';
    }
    line[strlen(line)] = '\n'; 
    tokens = tokenize(line);



    if(strcmp(tokens[0], "exit")==0){
      for(i=0;tokens[i]!=NULL;i++){
	free(tokens[i]);
      }
      free(tokens);
      killBackgroundProcesses();
      return 0;
    }
    if(strcmp(tokens[0], "cd")==0){
      int stat = chdir(tokens[1]);
      if(stat != 0){printf("Something went wrong while trying to change the directory!\n");continue;}
      else{continue;}
    }
    if(line[strlen(line)-1]=='&'){
      printf("Process is background\n");
    }
    pid = fork();
    if(pid<0){printf("Number of max processes exceeded, Please try again later\n");}
    else if(pid==0){
      if(background){
	setpgid(0,0);
      }
      signal(SIGINT, SIG_DFL);
      execvp(tokens[0], &tokens[0]);
      _exit(127);
    }
    else {
      if(background){
	strcpy(backgroundProcesses[bgp].cmd,line);
	backgroundProcesses[bgp].pid = pid;
	bgp++;
	if(bgp == 63){
	  bgp = 0;
	}
	background = 0;
	for(i=0;tokens[i]!=NULL;i++){
	  free(tokens[i]);
	}
	free(tokens);
	continue;
      }

    }
    waitpid(pid,&errorCode,0);
    if(WIFEXITED(errorCode)){
      if(WEXITSTATUS(errorCode)==1){printf("Exit Code: %d\n", 1);}
      else if(WEXITSTATUS(errorCode)==127) {
	printf("The command you entered doesn't make sense to me\n");
	printf("Exit Code: %d\n", WEXITSTATUS(errorCode));
      }
    }
    for(i=0;tokens[i]!=NULL;i++){
      free(tokens[i]);
    }
    free(tokens);
  }
return 0;
}
