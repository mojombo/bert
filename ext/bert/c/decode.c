#include "ruby.h"
#include <string.h>

#define ERL_VERSION       131
#define ERL_SMALL_INT     97
#define ERL_INT           98
#define ERL_SMALL_BIGNUM  110
#define ERL_LARGE_BIGNUM  111
#define ERL_FLOAT         99
#define ERL_ATOM          100
#define ERL_SMALL_TUPLE   104
#define ERL_LARGE_TUPLE   105
#define ERL_NIL           106
#define ERL_STRING        107
#define ERL_LIST          108
#define ERL_BIN           109

static VALUE mBERT;
static VALUE cDecode;
static VALUE cTuple;
void Init_decode();

VALUE method_decode(VALUE klass, VALUE rString);

VALUE read_any_raw(unsigned char **pData);

// printers

void p(VALUE val) {
  rb_funcall(rb_mKernel, rb_intern("p"), 1, val);
}

// checkers

void check_int(int num) {
  char buf[17];
  sprintf(buf, "%u", num);
  rb_raise(rb_eStandardError, buf);
}

void check_str(char *str) {
  rb_raise(rb_eStandardError, str);
}

// string peekers/readers

unsigned int peek_1(unsigned char **pData) {
  return (unsigned int) **pData;
}

unsigned int peek_2(unsigned char **pData) {
  return (unsigned int) ((**pData << 8) + *(*pData + 1));
}

unsigned int peek_4(unsigned char **pData) {
  return (unsigned int) ((**pData << 24) + (*(*pData + 1) << 16) + (*(*pData + 2) << 8) + *(*pData + 3));
}

unsigned int read_1(unsigned char **pData) {
  unsigned int val = peek_1(pData);
  *pData += 1;
  return val;
}

unsigned int read_2(unsigned char **pData) {
  unsigned int val = peek_2(pData);
  *pData += 2;
  return val;
}

unsigned int read_4(unsigned char **pData) {
  unsigned int val = peek_4(pData);
  *pData += 4;
  return val;
}

// tuples

VALUE read_tuple(unsigned char **pData, unsigned int arity);

VALUE read_dict_pair(unsigned char **pData) {
  if(read_1(pData) != ERL_SMALL_TUPLE) {
    rb_raise(rb_eStandardError, "Invalid dict pair, not a small tuple");
  }

  int arity = read_1(pData);

  if(arity != 2) {
    rb_raise(rb_eStandardError, "Invalid dict pair, not a 2-tuple");
  }

  return read_tuple(pData, arity);
}

VALUE read_dict(unsigned char **pData) {
  int type = read_1(pData);
  if(!(type == ERL_LIST || type == ERL_NIL)) {
    rb_raise(rb_eStandardError, "Invalid dict spec, not an erlang list");
  }

  unsigned int length = 0;
  if(type == ERL_LIST) {
    length = read_4(pData);
  }

  VALUE cHash = rb_const_get(rb_cObject, rb_intern("Hash"));
  VALUE hash = rb_funcall(cHash, rb_intern("new"), 0);

  int i;
  for(i = 0; i < length; ++i) {
    VALUE pair = read_dict_pair(pData);
    VALUE first = rb_ary_entry(pair, 0);
    VALUE last = rb_ary_entry(pair, 1);
    rb_funcall(hash, rb_intern("store"), 2, first, last);
  }

  if(type == ERL_LIST) {
    read_1(pData);
  }

  return hash;
}

VALUE read_complex_type(unsigned char **pData, int arity) {
  VALUE type = read_any_raw(pData);
  ID id = SYM2ID(type);
  if(id == rb_intern("nil")) {
    return Qnil;
  } else if(id == rb_intern("true")) {
    return Qtrue;
  } else if(id == rb_intern("false")) {
    return Qfalse;
  } else if(id == rb_intern("time")) {
    VALUE megasecs = read_any_raw(pData);
    VALUE msecs = rb_funcall(megasecs, rb_intern("*"), 1, INT2NUM(1000000));
    VALUE secs = read_any_raw(pData);
    VALUE microsecs = read_any_raw(pData);
    VALUE stamp = rb_funcall(msecs, rb_intern("+"), 1, secs);
    return rb_funcall(rb_cTime, rb_intern("at"), 2, stamp, microsecs);
  } else if(id == rb_intern("regex")) {
    VALUE source = read_any_raw(pData);
    VALUE opts = read_any_raw(pData);
    int flags = 0;
    if(rb_ary_includes(opts, ID2SYM(rb_intern("caseless"))))
      flags = flags | 1;
    if(rb_ary_includes(opts, ID2SYM(rb_intern("extended"))))
      flags = flags | 2;
    if(rb_ary_includes(opts, ID2SYM(rb_intern("multiline"))))
      flags = flags | 4;
    return rb_funcall(rb_cRegexp, rb_intern("new"), 2, source, INT2NUM(flags));
  } else if(id == rb_intern("dict")) {
    return read_dict(pData);
  } else {
    return Qnil;
  }
}

VALUE read_tuple(unsigned char **pData, unsigned int arity) {
  if(arity > 0) {
    VALUE tag = read_any_raw(pData);
    if(SYM2ID(tag) == rb_intern("bert")) {
      return read_complex_type(pData, arity);
    } else {
      VALUE tuple = rb_funcall(cTuple, rb_intern("new"), 1, INT2NUM(arity));
      rb_ary_store(tuple, 0, tag);
      int i;
      for(i = 1; i < arity; ++i) {
        rb_ary_store(tuple, i, read_any_raw(pData));
      }
      return tuple;
    }
  } else {
    return rb_funcall(cTuple, rb_intern("new"), 0);
  }
}

VALUE read_small_tuple(unsigned char **pData) {
  if(read_1(pData) != ERL_SMALL_TUPLE) {
    rb_raise(rb_eStandardError, "Invalid Type, not a small tuple");
  }

  int arity = read_1(pData);
  return read_tuple(pData, arity);
}

VALUE read_large_tuple(unsigned char **pData) {
  if(read_1(pData) != ERL_LARGE_TUPLE) {
    rb_raise(rb_eStandardError, "Invalid Type, not a large tuple");
  }

  unsigned int arity = read_4(pData);
  return read_tuple(pData, arity);
}

// lists

VALUE read_list(unsigned char **pData) {
  if(read_1(pData) != ERL_LIST) {
    rb_raise(rb_eStandardError, "Invalid Type, not an erlang list");
  }

  unsigned int size = read_4(pData);

  VALUE array = rb_ary_new2(size);

  int i;
  for(i = 0; i < size; ++i) {
    rb_ary_store(array, i, read_any_raw(pData));
  }

  read_1(pData);

  return array;
}

// primitives

void read_string_raw(unsigned char *dest, unsigned char **pData, unsigned int length) {
  memcpy((char *) dest, (char *) *pData, length);
  *(dest + length) = (unsigned char) 0;
  *pData += length;
}

VALUE read_bin(unsigned char **pData) {
  if(read_1(pData) != ERL_BIN) {
    rb_raise(rb_eStandardError, "Invalid Type, not an erlang binary");
  }

  unsigned int length = read_4(pData);

  VALUE rStr = rb_str_new((char *) *pData, length);
  *pData += length;

  return rStr;
}

VALUE read_string(unsigned char **pData) {
  if(read_1(pData) != ERL_STRING) {
    rb_raise(rb_eStandardError, "Invalid Type, not an erlang string");
  }

  int length = read_2(pData);
  VALUE array = rb_ary_new2(length);

  int i = 0;
  for(i; i < length; ++i) {
    rb_ary_store(array, i, INT2NUM(**pData));
    *pData += 1;
  }

  return array;
}

VALUE read_atom(unsigned char **pData) {
  if(read_1(pData) != ERL_ATOM) {
    rb_raise(rb_eStandardError, "Invalid Type, not an atom");
  }

  int length = read_2(pData);

  unsigned char buf[length + 1];
  read_string_raw(buf, pData, length);

  return ID2SYM(rb_intern((char *) buf));
}

VALUE read_small_int(unsigned char **pData) {
  if(read_1(pData) != ERL_SMALL_INT) {
    rb_raise(rb_eStandardError, "Invalid Type, not a small int");
  }

  int value = read_1(pData);

  return INT2FIX(value);
}

VALUE read_int(unsigned char **pData) {
  if(read_1(pData) != ERL_INT) {
    rb_raise(rb_eStandardError, "Invalid Type, not an int");
  }

  long long value = read_4(pData);

  long long negative = ((value >> 31) & 0x1 == 1);

  if(negative) {
    value = (value - ((long long) 1 << 32));
  }

  return INT2FIX(value);
}

VALUE read_small_bignum(unsigned char **pData) {
  if(read_1(pData) != ERL_SMALL_BIGNUM) {
    rb_raise(rb_eStandardError, "Invalid Type, not a small bignum");
  }

  unsigned int size = read_1(pData);
  unsigned int sign = read_1(pData);

  VALUE num = INT2NUM(0);
  VALUE tmp;

  unsigned char buf[size + 1];
  read_string_raw(buf, pData, size);

  int i;
  for(i = 0; i < size; ++i) {
    tmp = INT2FIX(*(buf + i));
    tmp = rb_funcall(tmp, rb_intern("<<"), 1, INT2NUM(i * 8));
    num = rb_funcall(num, rb_intern("+"), 1, tmp);
  }

  if(sign) {
    num = rb_funcall(num, rb_intern("*"), 1, INT2NUM(-1));
  }

  return num;
}

VALUE read_large_bignum(unsigned char **pData) {
  if(read_1(pData) != ERL_LARGE_BIGNUM) {
    rb_raise(rb_eStandardError, "Invalid Type, not a small bignum");
  }

  unsigned int size = read_4(pData);
  unsigned int sign = read_1(pData);

  VALUE num = INT2NUM(0);
  VALUE tmp;

  unsigned char buf[size + 1];
  read_string_raw(buf, pData, size);

  int i;
  for(i = 0; i < size; ++i) {
    tmp = INT2FIX(*(buf + i));
    tmp = rb_funcall(tmp, rb_intern("<<"), 1, INT2NUM(i * 8));

    num = rb_funcall(num, rb_intern("+"), 1, tmp);
  }

  if(sign) {
    num = rb_funcall(num, rb_intern("*"), 1, INT2NUM(-1));
  }

  return num;
}

VALUE read_float(unsigned char **pData) {
  if(read_1(pData) != ERL_FLOAT) {
    rb_raise(rb_eStandardError, "Invalid Type, not a float");
  }

  unsigned char buf[32];
  read_string_raw(buf, pData, 31);

  VALUE rString = rb_str_new2((char *) buf);

  return rb_funcall(rString, rb_intern("to_f"), 0);
}

VALUE read_nil(unsigned char **pData) {
  if(read_1(pData) != ERL_NIL) {
    rb_raise(rb_eStandardError, "Invalid Type, not a nil list");
  }

  return rb_ary_new2(0);
}

// read_any_raw

VALUE read_any_raw(unsigned char **pData) {
  switch(peek_1(pData)) {
    case ERL_SMALL_INT:
      return read_small_int(pData);
      break;
    case ERL_INT:
      return read_int(pData);
      break;
    case ERL_FLOAT:
      return read_float(pData);
      break;
    case ERL_ATOM:
      return read_atom(pData);
      break;
    case ERL_SMALL_TUPLE:
      return read_small_tuple(pData);
      break;
    case ERL_LARGE_TUPLE:
      return read_large_tuple(pData);
      break;
    case ERL_NIL:
      return read_nil(pData);
      break;
    case ERL_STRING:
      return read_string(pData);
      break;
    case ERL_LIST:
      return read_list(pData);
      break;
    case ERL_BIN:
      return read_bin(pData);
      break;
    case ERL_SMALL_BIGNUM:
      return read_small_bignum(pData);
      break;
    case ERL_LARGE_BIGNUM:
      return read_large_bignum(pData);
      break;
  }
  return Qnil;
}

VALUE method_decode(VALUE klass, VALUE rString) {
  unsigned char *data = (unsigned char *) StringValuePtr(rString);

  unsigned char **pData = &data;

  // check protocol version
  if(read_1(pData) != ERL_VERSION) {
    rb_raise(rb_eStandardError, "Bad Magic");
  }

  return read_any_raw(pData);
}

VALUE method_impl(VALUE klass) {
  return rb_str_new("C", 1);
}

void Init_decode() {
  mBERT = rb_const_get(rb_cObject, rb_intern("BERT"));
  cDecode = rb_define_class_under(mBERT, "Decode", rb_cObject);
  cTuple = rb_const_get(mBERT, rb_intern("Tuple"));
  rb_define_singleton_method(cDecode, "decode", method_decode, 1);
  rb_define_singleton_method(cDecode, "impl", method_impl, 0);
}
