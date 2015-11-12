#include "imx291.c" 
#include "i2c.c"
#include <stdlib.h>
#define initi2c 1
#define powerUpCamera 2	
#define powerDownCamera 3 
#define i2cwrite 4
#define BADKEY -1

typedef struct { char *key;int  val; } t_symstruct;
static t_symstruct lookUpTable[] = 
	{
		{"--initi2c",initi2c},
		{"--powerUpCamera",powerUpCamera},
		{"--powerDownCamera",powerDownCamera}
	};
#define NKEYS (sizeof(lookUpTable)/sizeof(t_symstruct))
static void usage(char *name);
static int keyfromstring(char *key);
static void i2c_init();
static void write8test(uint16_t regAddr, uint8_t value);
static void write16test(uint8_t regAddr, uint16_t value); 



int main(int argc, char **argv)
	{
	//handle command line arguments
	if (argc < 2){
		usage(argv[0]);
		return -1;
	}

	switch(keyfromstring(argv[1])){
		case initi2c:
			printf("starti2c\n");
			i2c_init();
			write8test(0x0309,0x10);
			break;
		case powerUpCamera:
			printf("power Up Camera and pins\n");
			imx291_turnOn();
			break;
		case powerDownCamera:
			printf("Power Down Camera\n");
			imx291_turnOff();
			break;
		case BADKEY:
			printf("badcommand'\n");
			usage(argv[0]);
			break;
		default:
		usage(argv[0]);
	}
	exit(0);
}
	
static void usage(char *name){
	printf("usage: %s [OPTION] \n",name);
	printf("\t %-30s %-15s\n","--initi2c", "initiliaze i2c hardware");
	printf("\t %-30s %-15s\n","--i2cwrite [address] [value]", "writes to i2c register");
	printf("\t %-30s %-15s\n","--powerUpCamera", "Enables power to camera");
	printf("\t %-30s %-15s\n","--powerDownCamera", "Powers Down camera");
}

static int keyfromstring(char *keyWord){
	int i;
	for(i = 0;i<NKEYS;i++){
		if (strcmp(lookUpTable[i].key,keyWord) == 0)
		    return lookUpTable[i].val;
	    }
    return BADKEY;
}

void i2c_init (){
	//int addr = 0b00110100;
    	int addr = 0b11010;
	sprintf(filename,"/dev/i2c-1");
	if ((file = open(filename,O_RDWR)) < 0) {
   	printf("Failed to open the i2c bus.\n");
    /* ERROR HANDLING; you can check errno to see what went wrong */
printf("Oh dear, something went wrong with read()! %s\n", strerror(errno));


   	exit(1);
 }
   
if (ioctl(file,I2C_SLAVE,addr) < 0) {
	     printf("Failed to acquire bus access and/or talk to slave.\n");
	      printf("%s\n", strerror(errno));
	       /* ERROR HANDLING; you can check errno to see what went wrong */
		exit(1);
	    }
}


void write8test(uint16_t regAddr, uint8_t value) {
  i2c_comm_buf[0] = slaveAddress
  i2c_comm_buf[1] = regAddr >> 8; 
  i2c_comm_buf[2] = regAddr & 0xff;
  i2c_comm_buf[3] = value; 
  printf("%s\n",filename);
  printf("write addr:%u%u , val : %u\n",i2c_comm_buf[1],i2c_comm_buf,i2c_comm_buf[3]);   
  if (write(file,i2c_comm_buf,4) != 4) {
        //ERROR HANDLING: i2c transaction failed 
       
	printf("Oh dear, something went wrong with write()! %s\n", strerror(errno));
   }else
   {
	printf("worked");	   
   }
}

//write value to regAddr. Byte order reversal is taken care of. 
////(assumes little-endian machine)
void write16test(uint8_t regAddr, uint16_t value) {
  uint8_t* valPtr = (uint8_t*) &value; 
    i2c_comm_buf[0] = regAddr; 
      i2c_comm_buf[1] = *(valPtr + 1); 
        i2c_comm_buf[2] = *valPtr; 
        printf("about to write\n");     
	if (write(file,i2c_comm_buf,3) != 3) {
                     //ERROR HANDLING: i2c transaction failed 
		    printf("Failed to write to the i2c bus.\n");
		   buffer = g_strerror(errno);
			  printf("%s error" ,buffer);
			 printf("\n\n");
	    }
    }

