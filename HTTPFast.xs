/* vim: set ft=c */
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "httpfast.h"

#include <stdio.h>

static int
on_header(void *o,
    const char *name,
    size_t name_len,
    const char *value,
    size_t value_len,
    int continuation)
{
    AV *self = (AV *)o;
    AV *headers = (AV *)SvRV(*av_fetch(self, 1, 0));


    if (continuation) {
        if (av_len(headers) == -1)
            croak("Internal error: continuation at the first header");

        SV *value_sv = *av_fetch(headers, av_len(headers), 0);
        size_t len;
        char *s = SvPV(value_sv, len);

        s = SvGROW(value_sv, len + value_len + 1);
        if (len > 0)
            s[ len++ ] = ' ';
        memcpy(s + len, value, value_len);
        SvCUR_set(value_sv, len + value_len);


    } else {

        SV *name_sv = newSVpvn("", 0);
        av_push(headers, name_sv);
        av_push(headers, newSVpvn(value, value_len));
        SvGROW(name_sv, name_len);
        SvCUR_set(name_sv, name_len);
        char *s = SvPV_nolen(name_sv);
        int i;
        for (i = 0; i < name_len; i++) {
            switch(name[i]) {
                case 'A' ... 'Z':
                    s[i] = name[i] - 'A' + 'a';
                    break;
                case '-':
                    s[i] = '_';
                    break;
                default:
                    s[i] = name[i];
                    break;
            }
        }
    }
    return 0;
}
static int
on_request_line(
        void *o,
        const char *method,
        size_t method_len,
        const char *path,
        size_t path_len,

        int http_major,
        int http_minor
    )
{
    AV *self = (AV *)o;
    AV *rline = newAV();
    av_store(self, 3, newRV((SV*) rline));

    av_push(rline, newSVpvn(method, method_len));
    av_push(rline, newSVpvn(path, path_len));
    av_push(rline, newSViv(http_major));
    av_push(rline, newSViv(http_minor));

    return 0;
}
static int
on_response_line(
        void *o,
        unsigned code,
        const char *reason,
        size_t reason_len,
        int http_major,
        int http_minor
    )
{
    AV *self = (AV *)o;
    AV *rline = newAV();
    av_store(self, 3, newRV((SV*) rline));

    av_push(rline, newSViv(code));
    av_push(rline, newSVpvn(reason, reason_len));
    av_push(rline, newSViv(http_major));
    av_push(rline, newSViv(http_minor));

    return 0;
}

static int
on_body(void *o, const char *body, size_t body_len)
{
    AV *self = (AV *)o;
    av_store(self, 2, newSVpvn(body, body_len));
    return 0;
}

static void
on_error(void *o, int code, const char *fmt, va_list ap)
{
    AV *self = (AV *)o;

    SV *msg = *av_fetch(self, 0, 1);
    sv_setpvn(msg, "", 0);
    sv_vcatpvf(msg, fmt, ap);
}


MODULE = HTTPFast		PACKAGE = HTTPFast
PROTOTYPES: ENABLE


SV * _parse( type, hreq )

        SV *hreq
        int type


        CODE:
            AV *self = newAV();
            AV *headers = newAV();
            SV *rslf = newRV((SV *)self);

            struct parse_http_events ev = {
                .on_header          = on_header,
                .on_body            = on_body,
                .on_error           = on_error,
                //.on_warn            = on_warn,
            };


            av_push(self, newSVpvn("", 0));         /* status */
            av_push(self, newRV((SV *)headers));    /* headers */
            av_push(self, newSVpvn("", 0));         /* body */
            av_push(self, newRV((SV *)newAV()));    /* req/resp line */

            switch(type) {
                case 0:
                    sv_bless(rslf, gv_stashpv("HTTPFast::Message", 0));
                    break;
                case 1:
                    ev.on_request_line = on_request_line;
                    sv_bless(rslf, gv_stashpv("HTTPFast::Request", 0));
                    break;
                case 2:
                    ev.on_response_line = on_response_line;
                    sv_bless(rslf, gv_stashpv("HTTPFast::Response", 0));
                    break;
                default:
                    croak("Wrong parser type: %d", type);
            }

            RETVAL = rslf;



            size_t len;
            const char *s = SvPV(hreq, len);

            httpfast_parse(s, len, &ev, self);


        OUTPUT:
            RETVAL



MODULE = HTTPFast           PACKAGE = HTTPFast::Message


