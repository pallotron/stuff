#include <stdio.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <sys/un.h>
#include <unistd.h>
#include <string.h>
#include <sys/stat.h>
#include <pwd.h>
#include <stdlib.h>
#include <sys/wait.h>
#include <sys/unistd.h>

#define SMBPASSWD_PATH 	 "/usr/local/bin/smbpasswd -s"
#define UNIX_SOCKET_PATH "/usr/local/www/apache22/data/smbpasswd/tmp/changesmbpasswd.sock"
#define APACHE_GID 80

int main(int argc, char *argv[]) {

	int sockfd, acceptfd, cli_addr_len;
	struct sockaddr_un serv_addr, cli_addr;
	pid_t childpid;

	// create a unix stream socket file descriptor	
	if ((sockfd = socket(AF_UNIX, SOCK_STREAM, 0)) < 0) {
		perror("server: socket");
		exit(1);
	}
	
	// reset to zero serv_addr struct
	bzero((char *) &serv_addr, sizeof(serv_addr));
	// socket is an unix domain socket
	serv_addr.sun_family = AF_UNIX;
	// set the path of the sockfile
	strncpy(serv_addr.sun_path, UNIX_SOCKET_PATH, strlen(UNIX_SOCKET_PATH));	
	// unlink any previous created socket
	unlink(UNIX_SOCKET_PATH);

	// bind the socket, this function create the file into filesystem
	if(bind(sockfd,(struct sockaddr *)&serv_addr,sizeof(serv_addr))<0) {
		perror("server: bind"); 
		exit(1);
	}

	// change permission
	// TODO: only apache can write to socket
	chmod(UNIX_SOCKET_PATH,S_IRWXU | S_IRWXG);
	chown(UNIX_SOCKET_PATH,0,APACHE_GID);

	// listen on socket
	if (listen(sockfd, 5) < 0) {
		perror("server: listen");
	        exit(1);
	}

	// Loop forever waiting for connections
	for (;;) {
		cli_addr_len = sizeof(cli_addr);

		// waiting for a connection - this function is blocking
		acceptfd = accept(sockfd,(struct sockaddr *)&cli_addr,&cli_addr_len);
		if(acceptfd<0) { perror("server: accept"); exit(1); }

		// when a connection has been established fork to the child
		if ((childpid = fork()) == 0) { /* i'm the child */
			char string[4096];
			char *username, *oldpwd, *newpwd;
			FILE *smbpipe;
			struct passwd *pw;
			char *p;
			
			// read the input from php
			// the format of the line is: "username;oldpassword;newpassword\n"
			read (acceptfd, &string, 4096);
			// split the line into the 3 parameters
			username = strtok (string,";");
			oldpwd = strtok (NULL, ";");
			newpwd = strtok (NULL, ";");
			// the '\n' char in the last string needs to be set up to '\0'
			for(p=newpwd;p!='\0';p++) { 
				if(*p=='\n') { *p='\0'; break; }
			}

			// get a struct containing all the infos about the username
			if (NULL == (pw = getpwnam(username)))
			      perror("getpwnam() error.");
			else {
				// became the user
				setuid(pw->pw_uid);
				setgid(pw->pw_gid);
				// open a full-duplex pipe with "smbpasswd -s 2>&1" command
				// stderr will be redirected to the acceptfd descriptor
				close(2);
				dup(acceptfd);
				smbpipe = popen(SMBPASSWD_PATH,"r+");
				// send the data to smbpasswd
				fprintf(smbpipe,"%s\n%s\n%s\n",oldpwd,newpwd,newpwd);
				// close the pipe
				pclose(smbpipe);
			}
			// close the connection and exit
			close (acceptfd);
			exit(0);
		} else {
			/* i'm the father and i'm closing the accept file descriptor */
			close(acceptfd);
			// wait for all the childrens to exit...
			// this prevent the presence of zombies processes into system
			wait(NULL);
		}
	}

	exit(0);
}

