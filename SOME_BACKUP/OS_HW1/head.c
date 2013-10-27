//--------------------------------------------
// NAME: Martin Ivanov
// CLASS: 11B
// NUMBER: 19
// PROBLEM: #1
// FILE NAME: head.c
// FILE PURPOSE:
// The program is simple implementation of the Unix head command.
//--------------------------------------------
#include <unistd.h>
#include <fcntl.h>
#include <string.h>

char left_arrow[100] = "==>" ;
char right_arrow[6] = "<==" ;
//--------------------------------------------
// FUNCTION: error_handle
// Prints out the appropriate error massage for a given situation
// PARAMETERS:
// type --- the type of operation done.
// file --- the name of the file that gives an error.
//----------------------------------------------
	void error_handle(int type, char* file) {
		char error[150]="head: cannot";

		switch ( type ) { 
			case -1:          
				strcat(error, " open '");
				strcat(error, file);
				strcat(error, "' for reading");
				break;
			case -2:
				strcat(error, " close '");
				strcat(error, file);
				break;
			case -3:
				strcat(error, " read from '");
				strcat(error, file);
				break;
			case -4:
				strcat(error, " write in '");
				strcat(error, file);
				break;
		}
		
		perror(error);
	}

//--------------------------------------------
// FUNCTION: clean
// This function cleans up an array of chars
// PARAMETERS:
// var --- the array of chars
//----------------------------------------------

	void clean(char *var) {
    	int i = 0;
    	while(var[i] != '\0') {
       		var[i] = '\0';
        	i++;
    	}
	}

//--------------------------------------------
// FUNCTION: addNewLine
// This function prints out a new line symbol with the low level write()
// PARAMETERS:
// NONE
//----------------------------------------------

	void addNewLine() {
		char newLine[] = "\n" ;
		int fd = 0 ;

		fd = write(STDOUT_FILENO,newLine,strlen(newLine)) ;

		if(fd==-1) {
			error_handle(-4,"STDOUT_FILENO") ;
		}
	}

	int main(int argc, char* argv[]) {

		int i=0,o_ok=0,w_ok=0,r_ok=0,c_ok=0,counter=0 ;
		char buffer ;
		char header[100] ;

		for(i=1;i<argc;i++,counter=0) {
		
			if (*argv[i] == '-') {
				while( i < 10 ) { 
					r_ok = read(STDIN_FILENO, &buffer, 1);
					
					if( r_ok == -1 ) {
						error_handle(-3, "standart input");
						return -3;
					}
		
					if( r_ok == 0 ) // if read has reached EOF
						break;
		
					w_ok = write(STDOUT_FILENO, &buffer, 1);
		
					if( w_ok == -1 ) {
						error_handle(-4, "STDOUT_FILENO");
						return -4;
					}
		
					if( buffer == '\n' )
						i++;
				}
            }
			else {

				if(argc > 2) {
					strcpy(header,left_arrow) ;
					strcat(header,argv[i]) ;
					strcat(header,right_arrow) ;
					
					int h_ok = 0 ;
					h_ok = write(STDOUT_FILENO,header,strlen(header)) ;

					if(h_ok == -1){
						error_handle(-4,"STDOUT_FILENO");
						return -4 ;
					}

					addNewLine() ;
				}

				o_ok = open(argv[i],O_RDONLY,S_IRUSR|S_IWUSR) ;

				if (o_ok==-1) {
					error_handle(-1,argv[i]) ;
					return -1 ;
				}

				while (counter<10) {

					r_ok = read(o_ok,&buffer,1) ;

					if (r_ok==-1) {
						error_handle(-2,argv[i]) ;
						return -2 ;
					}

					w_ok = write(STDOUT_FILENO,&buffer,1) ;

					if (w_ok==-1) {
						error_handle(-3,"STDOUT_FILENO") ;
						return -3 ;
					}

					if (buffer == '\n') counter++ ;

				}

				c_ok = close(o_ok) ;

					if (c_ok==-1) {
						error_handle(-4,argv[i]) ;
						return -4 ;
				}

				clean(header) ;

				addNewLine() ;

			}
		}

		return 0 ;
	}