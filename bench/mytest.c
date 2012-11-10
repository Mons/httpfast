#include <stdint.h>
#include <stdio.h>
#include <string.h>
#include <sys/time.h>
#include <sys/types.h>
#include "picohttpparser.h"
#include "httpfast.h"
#include <unistd.h>
#include <time.h>

int req_len;
int res_len;

void makelower(char *str, size_t len) {
	char *char_ptr;
	unsigned long int *longword_ptr;
	unsigned long int longword, magic_bits, himagic, lomagic;
	printf("convert [%d] %s\n", len, str);
	
	str += len;
	for (char_ptr = str - len; ((unsigned long int) char_ptr & (sizeof (longword) - 1)) != 0; ++char_ptr) {
		printf("convert %c\n", *char_ptr);
		if (char_ptr > str) return;
		*char_ptr |= 0x20;
	}
	printf("aligned: %s\n",char_ptr);
	if ( len % sizeof(longword) )
		str -= sizeof( longword );
	longword_ptr = (unsigned long int *) char_ptr;
	
	for (;(char *)longword_ptr < str;longword_ptr++) {
		longword = *longword_ptr;
		printf("convert %lu [%-.8s]\n", longword, (char *)&longword);
		if (sizeof(longword) == 4) {
			*longword_ptr |= 0x20202020;
		}
		else
		if (sizeof(longword) == 8) {
			*longword_ptr |= 0x2020202020202020;
		}
		else abort();
		printf("converted %lu [%-.8s]\n", *longword_ptr, (char *)longword_ptr);
	}
	if ( len % sizeof(longword) )
		str += sizeof( longword );
	for (char_ptr = (char *)longword_ptr; char_ptr < str ; ++char_ptr) {
		printf("convert %c\n", *char_ptr);
		*char_ptr |= 0x20;
	}
	
	str -= len;
	printf("done: %s\n",str);
}


const char *req = 
"GET /x HTTP/1.1\r\n"
"Cache-Control: no-cache,no-store,must-revalidate\r\n"
"Connection: close\r\n"
"Date: Thu, 01 Nov 2012 10:00:28 GMT\r\n"
"Pragma: no-cache\r\n"
"Server: Apache/1.3.27 (Unix) mru_xml/0.471 gorgona/2.1 mod_jk/1.2.4 mod_ruby/1.0.7 Ruby/1.6.8 mod_mrim/0.17\r\n"
"Content-Length: 219567\r\n"
"Content-Type: text/html; charset=utf-8\r\n"
"Expires: Wed, 02 Nov 2011 10:00:28 GMT\r\n"
"Last-Modified: Thu, 01 Nov 2012 14:00:28 GMT\r\n"
"Client-Date: Thu, 01 Nov 2012 10:00:33 GMT\r\n"
"Client-Peer: 94.100.180.201:80\r\n"
"Client-Response-Num: 1\r\n"
"Set-Cookie: mrcu=D8765092483C1386F12AABBFDAC3; expires=Sun, 30 Oct 2022 10:00:28 GMT; path=/; domain=.mail.ru\r\n"
"Multiline: some value\r\n"
"	continued\r\n"
"X-Host: lf31.mail.ru 8\r\n"
"X-Host: lf31.mail.ru 9\r\n"
"\r\n";

const char *res = 
"HTTP/1.1 200 OK\r\n"
"Cache-Control: no-cache,no-store,must-revalidate\r\n"
"Connection: close\r\n"
"Date: Thu, 01 Nov 2012 10:00:28 GMT\r\n"
"Pragma: no-cache\r\n"
"Server: Apache/1.3.27 (Unix) mru_xml/0.471 gorgona/2.1 mod_jk/1.2.4 mod_ruby/1.0.7 Ruby/1.6.8 mod_mrim/0.17\r\n"
"Content-Length: 219567\r\n"
"Content-Type: text/html; charset=utf-8\r\n"
"Expires: Wed, 02 Nov 2011 10:00:28 GMT\r\n"
"Last-Modified: Thu, 01 Nov 2012 14:00:28 GMT\r\n"
"Client-Date: Thu, 01 Nov 2012 10:00:33 GMT\r\n"
"Client-Peer: 94.100.180.201:80\r\n"
"Client-Response-Num: 1\r\n"
"Set-Cookie: mrcu=D8765092483C1386F12AABBFDAC3; expires=Sun, 30 Oct 2022 10:00:28 GMT; path=/; domain=.mail.ru\r\n"
"Multiline: some value\r\n"
"	continued\r\n"
"X-Host: lf31.mail.ru 8\r\n"
"X-Host: lf31.mail.ru 9\r\n"
"\r\n";

typedef void (*testfunc)( char *buf );

void test_pico(char *buf) {
	
	const char* method;
	size_t method_len;
	
	const char* path;
	size_t path_len;
	
	struct phr_header headers[24];
	size_t num_headers = 24;
	
	int minor_version;
	
	int i;
	
	int res = phr_parse_request(
		buf, req_len,
		&method, &method_len,
		&path, &path_len,
		&minor_version,
		headers, &num_headers,
		0
	);
	//printf("%d\n",res);
	return;
	/*
	printf( "Result: %d\n", res );
	printf("Method: %-.*s\n", (int)method_len, method);
	printf("Path: %-.*s\n", (int)path_len, path);
	
	for (i=0;i<num_headers;i++) {
		printf("\tHeader: %-.*s = %-.*s\n", (int)headers[i].name_len, headers[i].name, (int)headers[i].value_len, headers[i].value);
	}
	*/
}


//#define MYDEBUG
#ifdef MYDEBUG
#define WHERESTR    " at %s line %d.\n"
#define WHEREARG    __FILE__, __LINE__
#define debug(fmt, ...)   do{ \
	fprintf(stderr, "%s:%d: ", __FILE__, __LINE__); \
	fprintf(stderr, fmt, ##__VA_ARGS__); \
	if (fmt[strlen(fmt) - 1] != CR) { fprintf(stderr, "\n"); } \
	} while(0)
#else
#define debug(...)
#endif

#define cwarn(fmt, ...)   do{ \
	fprintf(stderr, "[WARN] %s:%d: ", __FILE__, __LINE__); \
	fprintf(stderr, fmt, ##__VA_ARGS__); \
	if (fmt[strlen(fmt) - 1] != CR) { fprintf(stderr, "\n"); } \
	} while(0)


void test_evhc(char *buf) {
	parse_http_state s;
	memset(&s,0,sizeof(s));

	header_t headers[24]; // headers: header_t*
	header_t *h = headers;
	memset(headers,0,sizeof(headers));
	//printf("allocated: %p -> %p\n", h, h[0]);
	s.headers = headers;
	s.header_max = 24;

	s.p = buf;
	s.e = buf + res_len;
	int rv = parse_http_response_line(&s);
	rv = parse_http_headers(&s);
}

typedef struct {
	time_t      sec;
	long int    nsec;
	intmax_t    delta;
} mytimediff;

mytimediff timedelta( struct timespec t1, struct timespec t2 ) {
	mytimediff d;
	intmax_t delta_nsec = ( (intmax_t)t2.tv_nsec - (intmax_t)t1.tv_nsec );
	intmax_t delta_sec = (intmax_t)t2.tv_sec - (intmax_t)t1.tv_sec;
	if (delta_nsec < 0) { delta_nsec += 1E9; delta_sec -=1; }
	if (delta_sec < 0) { delta_nsec = 1E9 - delta_nsec; }
	intmax_t delta = delta_sec*1E9 + delta_nsec;
	
	d.sec   = delta_sec;
	d.nsec  = delta_nsec;
	d.delta = delta;
	return d;
}

long double timeit( intmax_t maxtime, testfunc test, char * data ) {
	struct timeval tv;
	struct timespec t0,t1,t2;
	
	mytimediff d;
	
	intmax_t i,k, total;
	uint64_t time1, time2;
	uint64_t tx1, tx2;
	
	//for ( i = 1; i > 0 ; i <<= 1 ) {
	clock_gettime(CLOCK_PROCESS_CPUTIME_ID, &t0);
	long double ops;
	for ( i = 1; i < 0xfffffff ; i <<= 1 ) {
		//printf("i=%u...",i);
		
		gettimeofday(&tv, NULL); time1 = tv.tv_sec * 1000000 + tv.tv_usec;
		clock_gettime(CLOCK_PROCESS_CPUTIME_ID, &t1);
		
		
		for ( k=0; k < i; k++) {
			test(data);
		}
		
		clock_gettime(CLOCK_PROCESS_CPUTIME_ID, &t2);
		gettimeofday(&tv, NULL); time2 = tv.tv_sec * 1000000 + tv.tv_usec;
		
		total += i;
		
		d = timedelta( t1,t2 );
		/*
		intmax_t delta_nsec = ( (intmax_t)t2.tv_nsec - (intmax_t)t1.tv_nsec );
		intmax_t delta_sec = (intmax_t)t2.tv_sec - (intmax_t)t1.tv_sec;
		if (delta_nsec < 0) { delta_nsec += 1E9; delta_sec -=1; }
		if (delta_sec < 0) { delta_nsec = 1E9 - delta_nsec; }
		intmax_t delta = delta_sec*1E9 + delta_nsec;
		*/
		ops = i*1E9/d.delta;
		
		//printf("delta = %jd.%09jds (%jd us); wall = %0.4Lfs (ops = %.0Lf/s)\n", d.sec, d.nsec, d.delta, (long double)(time2-time1)/1E6, ops );
		
		d = timedelta( t0,t2 );
		
		if ( d.delta > 1E8 ) {
			//ops = total*1E9/d.delta;
			printf("END delta = %jd.%09jds (%jd us); (ops = %.0Lf/s)\n", d.sec, d.nsec, d.delta, ops );
			return ops;
			break;
		}
		
		//printf("real = %0.8Lf (%0.8Lf)\n", (double)(time2-time1)/1000000, tm2-tm1 );
		//printf("real = %0.8f (%u) (%u.%u, %u.%u [%u,%u]) rt: %0.6Lf, %0.6Lf\n", (double)(time2-time1)/1000000, (tx2-tx1), t2.tv_sec, t2.tv_nsec, t1.tv_sec, t1.tv_nsec, tx1,tx2, tm1, tm2 );
	}
	return -1;
}

int main(void) {
	char sample[] = "My_test thAt should-wOrk_";
	char *sx = malloc(strlen(sample)+1);
	memcpy(sx,sample,strlen(sample)+1);
	res_len = strlen(res);
	req_len = strlen(req);
	makelower(sx, strlen(sx));
	printf ("%d/%d; %s\n",res_len, req_len, sx);

	long double ops1 = timeit( 1E8, test_pico, (char *)req );
	long double ops2 = timeit( 1E8, test_evhc, (char *)res );
	
	printf("pico ops1 = %Lf\n", ops1);
	printf("ev   ops2 = %Lf\n", ops2);
	printf("ops2/ops1 = ( %+0.2Lf%% = x%0.1Lf )\n", 100.0 * ( ops2 - ops1 ) / ops1, ops2/ops1 );
	printf("ops1/ops2 = ( %+0.2Lf%% = x%0.1Lf )\n", 100.0 * ( ops1 - ops2 ) / ops2, ops1/ops2 );

	if (0){
	const char* method;
	size_t method_len;
	
	const char* path;
	size_t path_len;
	
	struct phr_header headers[24];
	size_t num_headers;
	
	int minor_version;
	
	int i;
	
	int rv = phr_parse_request(
		req, strlen(req),
		&method, &method_len,
		&path, &path_len,
		&minor_version,
		headers, &num_headers,
		0
	);
	printf( "Result: %d\n", rv );
	printf("Method: %-.*s\n", (int)method_len, method);
	printf("Path: %-.*s\n", (int)path_len, path);
	
	for (i=0;i<num_headers;i++) {
		printf("\tHeader: %-.*s = %-.*s\n", (int)headers[i].name_len, headers[i].name, (int)headers[i].value_len, headers[i].value);
	}
	}

	/*
	parse_http_state s;
	memset(&s,0,sizeof(s));

	header_t headers[24]; // headers: header_t*
	header_t *h = headers;
	memset(headers,0,sizeof(headers));
	s.headers = headers;
	s.header_max = 24;
	s.p = res;
	s.e = res + strlen(res);
	int rv =  parse_http_response_line(&s);

	printf( "Result[%d]: HTTP/%d.%d (%d: %-.*s)\n", rv, s.version.major, s.version.minor, s.status, s.reason.len, s.reason.str );
	
	rv = parse_http_headers(&s);
	
	printf( "Result[%d]: Headers: %zd\n", rv, s.header_i);
	
	int i;
	for (i=0;i < s.header_i; i++) {
		printf("\tHeader: %-.*s = %-.*s\n", (int)headers[i].name.len, headers[i].name.str, (int)headers[i].val.len, headers[i].val.str);
	}
	*/
	
	
	return 0;
}

