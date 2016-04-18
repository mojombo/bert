#include "ruby.h"
#include "ruby/encoding.h"
#include <stdint.h>
#include <netinet/in.h>

#define ERL_SMALL_INT     97
#define ERL_INT           98
#define ERL_FLOAT         99
#define ERL_ATOM          100
#define ERL_SMALL_TUPLE   104
#define ERL_LARGE_TUPLE   105
#define ERL_NIL           106
#define ERL_STRING        107
#define ERL_LIST          108
#define ERL_BIN           109
#define ERL_SMALL_BIGNUM  110
#define ERL_LARGE_BIGNUM  111

/* These two types are specific to version 2 of the protocol.  They diverge
 * from Erlang, but allow us to pass string encodings across the wire. */
#define ERLEXT_ENC_STRING    112
#define ERLEXT_UNICODE_STRING 113

/* Protocol version constants. */
#define ERL_VERSION       131
#define ERL_VERSION2      132

#define BERT_VALID_TYPE(t) ((t) >= ERL_SMALL_INT && (t) <= ERLEXT_UNICODE_STRING)
#define BERT_TYPE_OFFSET (ERL_SMALL_INT)

static VALUE rb_mBERT;
static VALUE rb_cDecode;
static VALUE rb_cTuple;

struct bert_buf {
	const uint8_t *data;
	const uint8_t *end;
};

static VALUE bert_read_invalid(struct bert_buf *buf);

static VALUE bert_read_sint(struct bert_buf *buf);
static VALUE bert_read_int(struct bert_buf *buf);
static VALUE bert_read_float(struct bert_buf *buf);
static VALUE bert_read_atom(struct bert_buf *buf);
static VALUE bert_read_stuple(struct bert_buf *buf);
static VALUE bert_read_ltuple(struct bert_buf *buf);
static VALUE bert_read_nil(struct bert_buf *buf);
static VALUE bert_read_string(struct bert_buf *buf);
static VALUE bert_read_list(struct bert_buf *buf);
static VALUE bert_read_bin(struct bert_buf *buf);
static VALUE bert_read_enc_string(struct bert_buf *buf);
static VALUE bert_read_unicode_string(struct bert_buf *buf);
static VALUE bert_read_sbignum(struct bert_buf *buf);
static VALUE bert_read_lbignum(struct bert_buf *buf);

typedef VALUE (*bert_ptr)(struct bert_buf *buf);
static bert_ptr bert_callbacks[] = {
	&bert_read_sint,
	&bert_read_int,
	&bert_read_float,
	&bert_read_atom,
	&bert_read_invalid,
	&bert_read_invalid,
	&bert_read_invalid,
	&bert_read_stuple,
	&bert_read_ltuple,
	&bert_read_nil,
	&bert_read_string,
	&bert_read_list,
	&bert_read_bin,
	&bert_read_sbignum,
	&bert_read_lbignum,
	&bert_read_enc_string,
	&bert_read_unicode_string
};

static inline uint8_t bert_buf_read8(struct bert_buf *buf)
{
	return *buf->data++;
}

static inline uint16_t bert_buf_read16(struct bert_buf *buf)
{
	/* Note that this will trigger -Wcast-align and throw a
	 * bus error on platforms where unaligned reads are not
	 * allowed. Also note that this is not breaking any
	 * strict aliasing rules. */
	uint16_t short_val = *(uint16_t *)buf->data;
	buf->data += sizeof(uint16_t);
	return ntohs(short_val);
}

static inline uint32_t bert_buf_read32(struct bert_buf *buf)
{
	/* Note that this will trigger -Wcast-align and throw a
	 * bus error on platforms where unaligned reads are not
	 * allowed. Also note that this is not breaking any
	 * strict aliasing rules. */
	uint32_t long_val = *(uint32_t *)buf->data;
	buf->data += sizeof(uint32_t);
	return ntohl(long_val);
}

static inline void bert_buf_ensure(struct bert_buf *buf, size_t size)
{
	if (buf->data + size > buf->end)
		rb_raise(rb_eEOFError, "Unexpected end of BERT stream");
}

static VALUE bert_read(struct bert_buf *buf)
{
	uint8_t type;

	bert_buf_ensure(buf, 1);
	type = bert_buf_read8(buf);

	if (!BERT_VALID_TYPE(type))
		rb_raise(rb_eRuntimeError, "Invalid tag '%d' for term", type);

	return bert_callbacks[type - BERT_TYPE_OFFSET](buf);
}

static VALUE bert_read_dict(struct bert_buf *buf)
{
	uint8_t type;
	uint32_t length = 0, i;
	VALUE rb_dict;

	bert_buf_ensure(buf, 1);
	type = bert_buf_read8(buf);

	if (type != ERL_LIST && type != ERL_NIL)
		rb_raise(rb_eTypeError, "Invalid dict spec, not an erlang list");

	if (type == ERL_LIST) {
		bert_buf_ensure(buf, 4);
		length = bert_buf_read32(buf);
	}

	rb_dict = rb_hash_new();

	for (i = 0; i < length; ++i) {
		VALUE key, val;
		bert_buf_ensure(buf, 2);

		if (bert_buf_read8(buf) != ERL_SMALL_TUPLE || bert_buf_read8(buf) != 2)
			rb_raise(rb_eTypeError, "Invalid dict tuple");

		key = bert_read(buf);
		val = bert_read(buf);

		rb_hash_aset(rb_dict, key, val);
	}

	if (type == ERL_LIST) {
		/* disregard tail; adquire women */
		bert_buf_ensure(buf, 1);
		(void)bert_buf_read8(buf);
	}

	return rb_dict;
}

static inline void bert_ensure_arity(uint32_t arity, uint32_t expected)
{
	if (arity != expected)
		rb_raise(rb_eTypeError, "Invalid tuple arity for complex type");
}

static VALUE bert_read_complex(struct bert_buf *buf, uint32_t arity)
{
	VALUE rb_type;
	ID id_type;

	rb_type = bert_read(buf);
	Check_Type(rb_type, T_SYMBOL);

	id_type = SYM2ID(rb_type);

	if (id_type == rb_intern("nil")) {
		bert_ensure_arity(arity, 2);
		return Qnil;

	} else if (id_type == rb_intern("true")) {
		bert_ensure_arity(arity, 2);
		return Qtrue;

	} else if (id_type == rb_intern("false")) {
		bert_ensure_arity(arity, 2);
		return Qfalse;

	} else if (id_type == rb_intern("time")) {
		VALUE rb_megasecs, rb_secs, rb_microsecs, rb_stamp, rb_msecs;

		bert_ensure_arity(arity, 5);

		rb_megasecs = bert_read(buf);
		rb_secs = bert_read(buf);
		rb_microsecs = bert_read(buf);

		rb_msecs = rb_funcall(rb_megasecs, rb_intern("*"), 1, INT2NUM(1000000));
		rb_stamp = rb_funcall(rb_msecs, rb_intern("+"), 1, rb_secs);

		return rb_funcall(rb_cTime, rb_intern("at"), 2, rb_stamp, rb_microsecs);

	} else if (id_type == rb_intern("regex")) {
		VALUE rb_source, rb_opts;
		int flags = 0;
		
		bert_ensure_arity(arity, 4);

		rb_source = bert_read(buf);
		rb_opts = bert_read(buf);

		Check_Type(rb_source, T_STRING);
		Check_Type(rb_opts, T_ARRAY);

		if (rb_ary_includes(rb_opts, ID2SYM(rb_intern("caseless"))))
			flags = flags | 1;

		if (rb_ary_includes(rb_opts, ID2SYM(rb_intern("extended"))))
			flags = flags | 2;

		if (rb_ary_includes(rb_opts, ID2SYM(rb_intern("multiline"))))
			flags = flags | 4;

		return rb_funcall(rb_cRegexp, rb_intern("new"), 2, rb_source, INT2NUM(flags));

	} else if (id_type == rb_intern("dict")) {
		bert_ensure_arity(arity, 3);
		return bert_read_dict(buf);
	}

	rb_raise(rb_eTypeError, "Invalid tag for complex value");
	return Qnil;
}

static VALUE bert_read_tuple(struct bert_buf *buf, uint32_t arity)
{
	if (arity > 0) {
		VALUE rb_tag = bert_read(buf);

		if (TYPE(rb_tag) == T_SYMBOL && SYM2ID(rb_tag) == rb_intern("bert")) {
			return bert_read_complex(buf, arity);
		} else {
			uint32_t i;
			VALUE rb_tuple;

			rb_tuple = rb_funcall(rb_cTuple, rb_intern("new"), 1, INT2NUM(arity));
			rb_ary_store(rb_tuple, 0, rb_tag);

			for(i = 1; i < arity; ++i)
				rb_ary_store(rb_tuple, i, bert_read(buf));

			return rb_tuple;
		}
	}

	return rb_funcall(rb_cTuple, rb_intern("new"), 0);
}

static VALUE bert_read_stuple(struct bert_buf *buf)
{
	bert_buf_ensure(buf, 1);
	return bert_read_tuple(buf, bert_buf_read8(buf));
}

static VALUE bert_read_ltuple(struct bert_buf *buf)
{
	bert_buf_ensure(buf, 4);
	return bert_read_tuple(buf, bert_buf_read32(buf));
}

static VALUE bert_read_list(struct bert_buf *buf)
{
	uint32_t i, length;
	VALUE rb_list;

	bert_buf_ensure(buf, 4);
	length = bert_buf_read32(buf);
	rb_list = rb_ary_new2(length);

	for(i = 0; i < length; ++i)
		rb_ary_store(rb_list, i, bert_read(buf));

	/* disregard tail; adquire currency */
	bert_buf_ensure(buf, 1);
	(void)bert_buf_read8(buf);

	return rb_list;
}

static VALUE bert_read_bin(struct bert_buf *buf)
{
	uint32_t length;
	VALUE rb_bin;

	bert_buf_ensure(buf, 4);
	length = bert_buf_read32(buf);

	bert_buf_ensure(buf, length);
	rb_bin = rb_str_new((char *)buf->data, length);
	buf->data += length;

	return rb_bin;
}

static VALUE bert_read_unicode_string(struct bert_buf *buf)
{
    VALUE rb_str;

    rb_str = bert_read_bin(buf);
    rb_enc_associate(rb_str, rb_utf8_encoding());

    return rb_str;
}

static VALUE bert_read_enc_string(struct bert_buf *buf)
{
	uint8_t type;
	VALUE rb_bin, enc;

	rb_bin = bert_read_bin(buf);

	bert_buf_ensure(buf, 1);
	type = bert_buf_read8(buf);
	if (ERL_BIN != type)
		rb_raise(rb_eRuntimeError, "Invalid tag '%d' for term", type);

	enc = bert_read_bin(buf);
	rb_enc_associate(rb_bin, rb_find_encoding(enc));

	return rb_bin;
}

static VALUE bert_read_string(struct bert_buf *buf)
{
	uint16_t i, length;
	VALUE rb_string;

	bert_buf_ensure(buf, 2);
	length = bert_buf_read16(buf);

	bert_buf_ensure(buf, length);
	rb_string = rb_ary_new2(length);

	for (i = 0; i < length; ++i)
		rb_ary_store(rb_string, i, INT2FIX(buf->data[i]));

	buf->data += length;
	return rb_string;
}

static VALUE bert_read_atom(struct bert_buf *buf)
{
	VALUE rb_atom;
	uint32_t atom_len;

	bert_buf_ensure(buf, 2);
	atom_len = bert_buf_read16(buf);

	/* Instead of trying to build the symbol
	 * from here, just create a Ruby string
	 * and internalize it. this will be faster for
	 * unique symbols */
	bert_buf_ensure(buf, atom_len);
	rb_atom = rb_str_new((char *)buf->data, atom_len);
	buf->data += atom_len;

	return rb_str_intern(rb_atom);
}

static VALUE bert_read_sint(struct bert_buf *buf)
{
	bert_buf_ensure(buf, 1);
	return INT2FIX((uint8_t)bert_buf_read8(buf));
}

static VALUE bert_read_int(struct bert_buf *buf)
{
	bert_buf_ensure(buf, 4);
	return LONG2NUM((int32_t)bert_buf_read32(buf));
}

static VALUE bert_buf_tobignum(struct bert_buf *buf, uint8_t sign, uint32_t bin_digits)
{
#ifdef BERT_FAST_BIGNUM
	uint32_t *bin_buf = NULL;
	VALUE rb_num;
	uint32_t round_size;

	bert_buf_ensure(buf, bin_digits);

	/* Hack: ensure that we have at least a full word
	 * of extra padding for the actual string, so Ruby
	 * cannot guess the sign of the bigint from the MSB */
	round_size = 4 + ((bin_digits + 3) & ~3);
	bin_buf = xmalloc(round_size);

	memcpy(bin_buf, buf->data, bin_digits);
	memset((char *)bin_buf + bin_digits, 0x0, round_size - bin_digits);

	/* Make Ruby unpack the string internally.
	 * this is significantly faster than adding
	 * the bytes one by one */
	rb_num = rb_big_unpack(bin_buf, round_size / 4);

	/* Enfore sign. So fast! */
	RBIGNUM_SET_SIGN(rb_num, !sign);

	free(bin_buf);
	return rb_num;
#else
	/**
	 * Slower bignum serialization; convert to a base16
	 * string and then let ruby parse it internally.
	 *
	 * We're shipping with this by default because
	 * `rb_big_unpack` is not trustworthy
	 */
	static const char to_hex[] = "0123456789abcdef";
	char *num_str = NULL, *ptr;
	VALUE rb_num;
	int32_t i;

	bert_buf_ensure(buf, bin_digits);

	/* 2 digits per byte + sign + trailing null */
	num_str = ptr = xmalloc((bin_digits * 2) + 2);

	*ptr++ = sign ? '-' : '+';

	for (i = (int32_t)bin_digits - 1; i >= 0; --i) {
		uint8_t val = buf->data[i];
		*ptr++ = to_hex[val >> 4];
		*ptr++ = to_hex[val & 0xf];
	}

	*ptr = 0;
	buf->data += bin_digits;

	rb_num = rb_cstr_to_inum(num_str, 16, 1);
	free(num_str);

	return rb_num;
#endif
}

VALUE bert_read_sbignum(struct bert_buf *buf)
{
	uint8_t sign, bin_digits;

	bert_buf_ensure(buf, 2);

	bin_digits = bert_buf_read8(buf);
	sign = bert_buf_read8(buf);

	return bert_buf_tobignum(buf, sign, (uint32_t)bin_digits);
}

VALUE bert_read_lbignum(struct bert_buf *buf)
{
	uint32_t bin_digits;
	uint8_t sign;

	bert_buf_ensure(buf, 5);

	bin_digits = bert_buf_read32(buf);
	sign = bert_buf_read8(buf);

	return bert_buf_tobignum(buf, sign, bin_digits);
}

/*
 * -------------------
 * |1  | 31          |
 * |99 | Float String|
 * -------------------
 *
 * A float is stored in string format. the format used in sprintf
 * to format the float is "%.20e" (there are more bytes allocated 
 * than necessary). To unpack the float use sscanf with format "%lf".
 */
static VALUE bert_read_float(struct bert_buf *buf)
{
	VALUE rb_float;

	bert_buf_ensure(buf, 31);

	rb_float = rb_str_new((char *)buf->data, 31);
	buf->data += 31;

	return rb_funcall(rb_float, rb_intern("to_f"), 0);
}

static VALUE bert_read_nil(struct bert_buf *buf)
{
	return rb_ary_new2(0);
}

static VALUE bert_read_invalid(struct bert_buf *buf)
{
	rb_raise(rb_eTypeError, "Invalid object tag in BERT stream");
	return Qnil;
}

static VALUE rb_bert_decode(VALUE klass, VALUE rb_string)
{
	struct bert_buf buf;
	uint8_t proto_version;

	Check_Type(rb_string, T_STRING);
	buf.data = (uint8_t *)RSTRING_PTR(rb_string);
	buf.end = buf.data + RSTRING_LEN(rb_string);

	bert_buf_ensure(&buf, 1);

	proto_version = bert_buf_read8(&buf);
	if (proto_version == ERL_VERSION || proto_version == ERL_VERSION2) {
	    return bert_read(&buf);
	} else {
	    rb_raise(rb_eTypeError, "Invalid magic value for BERT string");
	}
}

static VALUE rb_bert_impl(VALUE klass)
{
	return rb_str_new("C", 1);
}

void Init_decode()
{
	rb_mBERT = rb_const_get(rb_cObject, rb_intern("BERT"));
	rb_cTuple = rb_const_get(rb_mBERT, rb_intern("Tuple"));

	rb_cDecode = rb_define_class_under(rb_mBERT, "Decode", rb_cObject);
	rb_define_singleton_method(rb_cDecode, "decode", rb_bert_decode, 1);
	rb_define_singleton_method(rb_cDecode, "impl", rb_bert_impl, 0);
}
