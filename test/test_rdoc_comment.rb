# coding: us-ascii

require 'rdoc/test_case'

class TestRDocComment < RDoc::TestCase

  def setup
    super

    @top_level = RDoc::TopLevel.new 'file.rb'
    @comment = RDoc::Comment.new
    @comment.location = @top_level
    @comment.text = 'this is a comment'
  end

  def test_empty_eh
    refute_empty @comment

    @comment = ''

    assert_empty @comment
  end

  def test_equals2
    assert_equal @comment, @comment.dup

    c2 = @comment.dup
    c2.text = nil

    refute_equal @comment, c2

    c3 = @comment.dup
    c3.location = nil

    refute_equal @comment, c3
  end

  def test_extract_call_seq
    m = RDoc::AnyMethod.new nil, 'm'

    comment = RDoc::Comment.new <<-COMMENT, @top_level
call-seq:
  bla => true or false

moar comment
    COMMENT

    comment.extract_call_seq m

    assert_equal "bla => true or false\n", m.call_seq
  end

  def test_extract_call_seq_blank
    m = RDoc::AnyMethod.new nil, 'm'

    comment = RDoc::Comment.new <<-COMMENT, @top_level
call-seq:
  bla => true or false

    COMMENT

    comment.extract_call_seq m

    assert_equal "bla => true or false\n", m.call_seq
  end

  def test_extract_call_seq_no_blank
    m = RDoc::AnyMethod.new nil, 'm'

    comment = RDoc::Comment.new <<-COMMENT, @top_level
call-seq:
  bla => true or false
    COMMENT

    comment.extract_call_seq m

    assert_equal "bla => true or false\n", m.call_seq
  end

  def test_extract_call_seq_undent
    m = RDoc::AnyMethod.new nil, 'm'

    comment = RDoc::Comment.new <<-COMMENT, @top_level
call-seq:
  bla => true or false
moar comment
    COMMENT

    comment.extract_call_seq m

    assert_equal "bla => true or false\nmoar comment\n", m.call_seq
  end

  def test_extract_call_seq_c
    comment = RDoc::Comment.new <<-COMMENT
call-seq:
  commercial() -> Date <br />
  commercial(cwyear, cweek=41, cwday=5, sg=nil) -> Date [ruby 1.8] <br />
  commercial(cwyear, cweek=1, cwday=1, sg=nil) -> Date [ruby 1.9]

If no arguments are given:
* ruby 1.8: returns a +Date+ for 1582-10-15 (the Day of Calendar Reform in
  Italy)
* ruby 1.9: returns a +Date+ for julian day 0

Otherwise, returns a +Date+ for the commercial week year, commercial week,
and commercial week day given. Ignores the 4th argument.
    COMMENT

    method_obj = RDoc::AnyMethod.new nil, 'blah'

    comment.extract_call_seq method_obj

    expected = <<-CALL_SEQ.chomp
commercial() -> Date <br />
commercial(cwyear, cweek=41, cwday=5, sg=nil) -> Date [ruby 1.8] <br />
commercial(cwyear, cweek=1, cwday=1, sg=nil) -> Date [ruby 1.9]

    CALL_SEQ

    assert_equal expected, method_obj.call_seq
  end

  def test_extract_call_seq_c_no_blank
    comment = RDoc::Comment.new <<-COMMENT
call-seq:
  commercial() -> Date <br />
  commercial(cwyear, cweek=41, cwday=5, sg=nil) -> Date [ruby 1.8] <br />
  commercial(cwyear, cweek=1, cwday=1, sg=nil) -> Date [ruby 1.9]
    COMMENT

    method_obj = RDoc::AnyMethod.new nil, 'blah'

    comment.extract_call_seq method_obj

    expected = <<-CALL_SEQ.chomp
commercial() -> Date <br />
commercial(cwyear, cweek=41, cwday=5, sg=nil) -> Date [ruby 1.8] <br />
commercial(cwyear, cweek=1, cwday=1, sg=nil) -> Date [ruby 1.9]

    CALL_SEQ

    assert_equal expected, method_obj.call_seq
  end

  def test_extract_call_seq_c_separator
    comment = RDoc::Comment.new <<-'COMMENT'
call-seq:
   ARGF.readlines(sep=$/)     -> array
   ARGF.readlines(limit)      -> array
   ARGF.readlines(sep, limit) -> array

   ARGF.to_a(sep=$/)     -> array
   ARGF.to_a(limit)      -> array
   ARGF.to_a(sep, limit) -> array

Reads +ARGF+'s current file in its entirety, returning an +Array+ of its
lines, one line per element. Lines are assumed to be separated by _sep_.

   lines = ARGF.readlines
   lines[0]                #=> "This is line one\n"

    COMMENT

    method_obj = RDoc::AnyMethod.new nil, 'blah'

    comment.extract_call_seq method_obj

    expected = <<-CALL_SEQ
ARGF.readlines(sep=$/)     -> array
ARGF.readlines(limit)      -> array
ARGF.readlines(sep, limit) -> array
ARGF.to_a(sep=$/)     -> array
ARGF.to_a(limit)      -> array
ARGF.to_a(sep, limit) -> array
    CALL_SEQ

    assert_equal expected, method_obj.call_seq

    expected = <<-'COMMENT'

Reads +ARGF+'s current file in its entirety, returning an +Array+ of its
lines, one line per element. Lines are assumed to be separated by _sep_.

   lines = ARGF.readlines
   lines[0]                #=> "This is line one\n"

    COMMENT

    assert_equal expected, comment.text
  end

  def test_force_encoding
    skip "Encoding not implemented" unless Object.const_defined? :Encoding

    @comment.force_encoding Encoding::UTF_8

    assert_equal Encoding::UTF_8, @comment.text.encoding
  end

  def test_initialize_copy
    copy = @comment.dup

    refute_same @comment.text, copy.text
    assert_same @comment.location, copy.location
  end

  def test_location
    assert_equal @top_level, @comment.location
  end

  def test_normalize
    @comment.text = <<-TEXT
  # comment
    TEXT

    assert_same @comment, @comment.normalize

    assert_equal 'comment', @comment.text
  end

  def test_text
    assert_equal 'this is a comment', @comment.text
  end

  def test_remove_private
    @comment.text = <<-TEXT
#--
# private
#++
# public
    TEXT

    @comment.remove_private

    assert_equal "# public\n", @comment.text
  end

  def test_remove_private_comments
    comment = RDoc::Comment.new <<-EOS, @top_level
# This is text
#--
# this is private
    EOS

    expected = RDoc::Comment.new <<-EOS, @top_level
# This is text
    EOS

    comment.remove_private

    assert_equal expected, comment
  end

  def test_remove_private_comments_encoding
    skip "Encoding not implemented" unless Object.const_defined? :Encoding

    comment = RDoc::Comment.new <<-EOS, @top_level
# This is text
#--
# this is private
    EOS

    comment.force_encoding Encoding::IBM437

    comment.remove_private

    assert_equal Encoding::IBM437, comment.text.encoding
  end

  def test_remove_private_comments_long
    comment = RDoc::Comment.new <<-EOS, @top_level
#-----
#++
# this is text
#-----
    EOS

    expected = RDoc::Comment.new <<-EOS, @top_level
# this is text
    EOS

    comment.remove_private

    assert_equal expected, comment
  end

  def test_remove_private_comments_rule
    comment = RDoc::Comment.new <<-EOS, @top_level
# This is text with a rule:
# ---
# this is also text
    EOS

    expected = comment.dup

    comment.remove_private

    assert_equal expected, comment
  end

  def test_remove_private_comments_toggle
    comment = RDoc::Comment.new <<-EOS, @top_level
# This is text
#--
# this is private
#++
# This is text again.
    EOS

    expected = RDoc::Comment.new <<-EOS, @top_level
# This is text
# This is text again.
    EOS

    comment.remove_private

    assert_equal expected, comment
  end

  def test_remove_private_comments_toggle_encoding
    skip "Encoding not implemented" unless Object.const_defined? :Encoding

    comment = RDoc::Comment.new <<-EOS, @top_level
# This is text
#--
# this is private
#++
# This is text again.
    EOS

    comment.force_encoding Encoding::IBM437

    comment.remove_private

    assert_equal Encoding::IBM437, comment.text.encoding
  end

  def test_remove_private_comments_toggle_encoding_ruby_bug?
    skip "Encoding not implemented" unless Object.const_defined? :Encoding

    comment = RDoc::Comment.new <<-EOS, @top_level
#--
# this is private
#++
# This is text again.
    EOS

    comment.force_encoding Encoding::IBM437

    comment.remove_private

    assert_equal Encoding::IBM437, comment.text.encoding
  end

end
