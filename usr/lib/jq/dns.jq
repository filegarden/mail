# Accepts DNS record data in text form, and returns the data with its character
# strings joined and unquoted. Character strings in text form can be escaped,
# quoted, and spaced according to RFC 1035 (section 5.1).
#
# Ideally, escaped quotes shouldn't be unquoted, and escaped characters should
# be unescaped, but that would be very complex for little gain, and our records
# shouldn't have escaped characters anyway.
def decode_character_strings:
  gsub("^[ \\t]*\"|\"[ \\t]*(?:\"|$)"; "");

# Encodes the inputs as a series of quoted DNS character strings separated by
# spaces. Character strings in text form can be escaped, quoted, and spaced
# according to RFC 1035 (section 5.1).
#
# Ideally, special characters should be escaped, but that would be very complex
# for little gain, and our records shouldn't have special characters anyway.
def encode_character_strings:
  # A character string can have at most 255 characters as per RFC 1035 (section
  # 3.3).
  [match(".{1,255}"; "g") | ("\"" + .string + "\"")] | join(" ");
