#include <pthread.h>
#include <stdio.h>

#define BRASHNO 1000

int masa[4];
int counter=0;
int ivan_pos=0;
int mother_pos=0;

pthread_mutex_t lock;

void* bake(void* arg) {

	while(counter<BRASHNO){
		
		pthread_mutex_lock(&lock);

		if(masa[mother_pos]==0){
			masa[mother_pos] = 1;
			counter+=rand()%101;
			printf("Baked on : %d\n", mother_pos);
			mother_pos++;
		}					
			
		if(mother_pos==4){
			mother_pos=0;
		}
			
		pthread_mutex_unlock(&lock);
	}
	return NULL;
}

void* eat(void* arg){
	
	while(counter<BRASHNO){
		pthread_mutex_lock(&lock);

		if(masa[ivan_pos]==1){
			masa[ivan_pos] = 0;
			printf("Eaten on : %d\n", ivan_pos);
			ivan_pos++;
		}
					
		if(ivan_pos==4){
			ivan_pos=0;
		}

		pthread_mutex_unlock(&lock);
	}

	if(masa[ivan_pos] == 1){
		while(ivan_pos<4){
			masa[ivan_pos] = 0;
			printf("Eaten on : %d\n", ivan_pos);
			ivan_pos++;
		}
	}
	return NULL;
}

int main(){
	pthread_mutex_init(&lock, NULL);

	pthread_t ivan;
	pthread_t mama; 	
	
	pthread_create(&ivan,NULL,eat,NULL);
	pthread_create(&mama,NULL,bake,NULL);
	
	pthread_join(ivan, NULL);
	pthread_join(mama, NULL);

	return 0;
}
