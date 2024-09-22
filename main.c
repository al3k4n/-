#include <stdlib.h>
#include "lib/string.h"
#include <stdio.h>
#include <readline/readline.h>

#define SIZE 10

int main()
{
	char *str = readline("Enter your string \n");
	char * array = malloc(SIZE * sizeof(char));

	if(str == NULL)
		return 0;

	strcpy(array, str);
	printf("%s", array);

	free(str);
	free(array);
	return 0;
}
