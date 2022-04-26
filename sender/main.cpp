#include<stdlib.h>
#include<stdio.h>
#include<sys/types.h>
#include<sys/sysinfo.h>
#include<unistd.h>

//#define __USE_GNU
#include<sched.h>
#include<ctype.h>
#include<pthread.h>
#include <sys/time.h>
#include <queue>
#include <vector>
#include "iostream"
#include <fstream>
#include <math.h>

using namespace std;

#define THREAD_MAX_NUM 200
//#define ONE_SECOND 1000000  // 1s == 1000000us



pthread_t thread[THREAD_MAX_NUM];
int LO[THREAD_MAX_NUM];
pthread_barrier_t barrier[THREAD_MAX_NUM];
pthread_barrier_t all_tran_barrier; // 每 一个time ，都要把所有的 core（包括控制者） 进行同步


vector<vector<long> > data(10);
int m, n; // 分别是 data 的行与列的数量
vector<int> time_duration(100); // 每一个频率的持续显示时间为 XX us
vector<int> time_sleep(100);



void read_data(string file_name){
    //
    //ifstream f(file_name);
    //f >> m >> n;
    //long freq;
    m = 1;  // num of cpu core
    n = 1; // bits(n/2)
    for(int i = 0; i < m; i++){
        for(int j = 0; j < n; j++){
            data[i].push_back(5000);
            //cout<<data[m][j]<<"   ";
        }
        //cout<<endl;
    }
    //f.close();

//    fu zhi
    // for(int j = 0; j < n; j++){
    //     time_duration[j] = 5000000;
    //     time_sleep[j] = 5000000;
    //     //cout<<data[m][j]<<"   ";
    // }
   time_duration[0] = 50000;
   time_duration[1] = 50000;
   time_duration[2] = 100000;
   time_duration[3] = 100000;
   time_sleep[0] = 50000;
   time_sleep[1] = 200000;
   time_sleep[2] = 50000;
   time_sleep[3] = 100000;


    cout<<m<<endl<<n<<endl;
    for(int i = 0; i < m; i++){
        for(int j = 0; j < n; j++){
            cout<<data[i][j]<<"  ";
        }
        cout<<endl;
    }
    //cout<<"fucking high"<<endl;

}

void* worker(void* arg){

    int k = (int)((long)arg);
    cpu_set_t mask;  //CPU核的集合
    //cout<<"a:"<<a<<endl;
    //printf("这是被 %d 控制")

    //printf("%d\n", a);
    CPU_ZERO(&mask);    //置空
    CPU_SET(2*k+1,&mask);   //设置亲和力值

    if (sched_setaffinity(0, sizeof(mask), &mask) == -1){//设置线程CPU亲和力
        printf("warning: could not set CPU affinity,continuing...threadid: %d\n",k);
    }

    while(1){
        pthread_barrier_wait(&barrier[k]);
        while(!LO[k]);
        pthread_barrier_wait(&barrier[k+100]);
    }
}


void* transmit(void* arg){
    long k = (long)arg;
    printf("%ld", k);

    cpu_set_t mask;
    CPU_ZERO(&mask);
    CPU_SET((int)(k*2),&mask);
    sched_setaffinity(0, sizeof(mask), &mask);

    struct timeval tim;

    bool flag = false;
    if((k+1) < m){
        flag = true;
        long sdf = k+1;
        pthread_create(&thread[(k+1)*2], NULL, transmit, (void*)sdf);
    }

    double duty_cycle[6] = {1.0, 0.8, 0.6, 0.4, 0.2,0.05}; //占空比信息
    sleep(2);
    for(int i = 0; i < n; i++){

        //double duty_cycle_now = duty_cycle[i%3];
        double duty_cycle_now = 0.5;
        if(!i){
            pthread_create(&thread[2*k+1], NULL, worker, (void*)((long(k))) );
            pthread_barrier_init(&barrier[k],NULL,2);
            pthread_barrier_init(&barrier[k+100],NULL,2);
        }

        pthread_barrier_wait(&all_tran_barrier);

        gettimeofday(&tim, NULL);
        long current = tim.tv_sec*1000000 + tim.tv_usec;
        long end = current + time_duration[i];

        //long halfCycle = (long)(0.5*1000000/data[k][i]);
        long cycle = (long)(1000000/data[k][i]);

        cout<<duty_cycle_now<<endl;
        long cpu_work = (long)(duty_cycle_now * cycle);
        //duty_cycle = 1 - duty_cycle_now; // cpu 占空比不断再 0.3 与 0.7 之间变换。

        cout<<current<<endl;
        cout<<end<<endl;
        cout<<"cycle begin ..."<<endl;

        while(current < end){
            LO[k]=0;
            pthread_barrier_wait(&barrier[k]);
            gettimeofday(&tim, NULL);
            current=tim.tv_sec*1000000+tim.tv_usec;
            //cout<<current<<endl;

            while(current%cycle < cpu_work){
 //               cout<<current%cycle<<endl;
//                cout<<cpu_work<<endl;
 //               cout<<cycle<<endl;
//                cout<<current<<endl;
//                cout<<end<<endl;
                gettimeofday(&tim, NULL);
                current=tim.tv_sec*1000000+tim.tv_usec;
            }

            //cout<<"cycle..."<<endl;
            LO[k]=1;
            pthread_barrier_wait(&barrier[k+100]);

            gettimeofday(&tim, NULL);
            current=tim.tv_sec*1000000+tim.tv_usec;
            //cout<<current<<endl;

            //cout<<current<<endl;
            while(current%cycle >= cpu_work){
                gettimeofday(&tim, NULL);
                current=tim.tv_sec*1000000+tim.tv_usec;
 //               cout<<current%cycle<<endl;
//                cout<<cpu_work<<endl;
//                cout<<cycle<<endl;
//                cout<<current<<endl;
//                cout<<end<<endl;
            }
        }//while

        usleep(time_sleep[i]);
        cout<<"cycle finish ..."<<endl;

    }//for

    if(flag){
        pthread_join(thread[(k+1)*2],NULL);
    }

    return NULL;

}

int main(int argc, char* argv[]){


    string file_name = "data.txt";
    read_data(file_name);

    pthread_barrier_init(&all_tran_barrier,NULL,m );

    long k = 0; //依次占用 0，1，2，3  ； 4，5，6，7 cores
    transmit((void*)k);

    cout<<"finish ..."<<endl;


}
