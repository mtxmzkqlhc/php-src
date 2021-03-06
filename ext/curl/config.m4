dnl config.m4 for extension curl

PHP_ARG_WITH([curl],
  [for cURL support],
  [AS_HELP_STRING([--with-curl],
    [Include cURL support])])

if test "$PHP_CURL" != "no"; then
  PKG_CHECK_MODULES([CURL], [libcurl >= 7.15.5])
  PKG_CHECK_VAR([CURL_FEATURES], [libcurl], [supported_features])

  PHP_EVAL_LIBLINE($CURL_LIBS, CURL_SHARED_LIBADD)
  PHP_EVAL_INCLINE($CURL_CFLAGS)

  AC_MSG_CHECKING([for SSL support in libcurl])
  case "$CURL_FEATURES" in
    *SSL*)
      CURL_SSL=yes
      AC_MSG_RESULT([yes])
      ;;
    *)
      CURL_SSL=no
      AC_MSG_RESULT([no])
      ;;
  esac

  if test "$CURL_SSL" = yes; then
    AC_DEFINE([HAVE_CURL_SSL], [1], [Have cURL with  SSL support])

    save_CFLAGS="$CFLAGS"
    CFLAGS=$CURL_CFLAGS
    save_LDFLAGS="$LDFLAGS"
    LDFLAGS=$CURL_LIBS

    AC_PROG_CPP
    AC_MSG_CHECKING([for openssl support in libcurl])
    AC_RUN_IFELSE([AC_LANG_SOURCE([[
#include <strings.h>
#include <curl/curl.h>

int main(int argc, char *argv[])
{
  curl_version_info_data *data = curl_version_info(CURLVERSION_NOW);

  if (data && data->ssl_version && *data->ssl_version) {
    const char *ptr = data->ssl_version;

    while(*ptr == ' ') ++ptr;
    return strncasecmp(ptr, "OpenSSL", sizeof("OpenSSL")-1);
  }
  return 1;
}
    ]])],[
      AC_MSG_RESULT([yes])
      AC_CHECK_HEADERS([openssl/crypto.h], [
        AC_DEFINE([HAVE_CURL_OPENSSL], [1], [Have cURL with OpenSSL support])
      ])
    ], [
      AC_MSG_RESULT([no])
    ], [
      AC_MSG_RESULT([no])
    ])

    AC_MSG_CHECKING([for gnutls support in libcurl])
    AC_RUN_IFELSE([AC_LANG_SOURCE([[
#include <strings.h>
#include <curl/curl.h>

int main(int argc, char *argv[])
{
  curl_version_info_data *data = curl_version_info(CURLVERSION_NOW);

  if (data && data->ssl_version && *data->ssl_version) {
    const char *ptr = data->ssl_version;

    while(*ptr == ' ') ++ptr;
    return strncasecmp(ptr, "GnuTLS", sizeof("GnuTLS")-1);
  }
  return 1;
}
]])], [
      AC_MSG_RESULT([yes])
      AC_DEFINE([HAVE_CURL_GNUTLS], [1], [Have cURL with GnuTLS support])
    ], [
      AC_MSG_RESULT([no])
    ], [
      AC_MSG_RESULT([no])
    ])

    CFLAGS="$save_CFLAGS"
    LDFLAGS="$save_LDFLAGS"
  else
    AC_MSG_RESULT([no])
  fi

  PHP_CHECK_LIBRARY(curl,curl_easy_perform,
  [
    AC_DEFINE(HAVE_CURL,1,[ ])
  ],[
    AC_MSG_ERROR(There is something wrong. Please check config.log for more information.)
  ],[
    $CURL_LIBS
  ])

  PHP_CHECK_LIBRARY(curl,curl_easy_strerror,
  [
    AC_DEFINE(HAVE_CURL_EASY_STRERROR,1,[ ])
  ],[],[
    $CURL_LIBS
  ])

  PHP_CHECK_LIBRARY(curl,curl_multi_strerror,
  [
    AC_DEFINE(HAVE_CURL_MULTI_STRERROR,1,[ ])
  ],[],[
    $CURL_LIBS
  ])

  PHP_NEW_EXTENSION(curl, interface.c multi.c share.c curl_file.c, $ext_shared)
  PHP_SUBST(CURL_SHARED_LIBADD)
fi
