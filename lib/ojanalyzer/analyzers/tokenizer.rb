class Tokenizer
  RESERVED = %w(
    int long short signed unsigned
    float double
    bool true false
    char wchar_t char16_t char32_t
    void
    auto
    class struct union
    enum
    const volatile extern register static mutable thread_local
    friend typedef
    constexpr explicit inline virtual
    public protected private
    operator this
    if else
    for
    while do
    switch case default
    break continue goto
    return
    try catch throw
    new delete
    dynamic_cast static_cast const_cast reinterpret_cast
    alignof decltype sizeof typeid
    noexcept static_assert
    template typename
    export
    namespace using
    asm
    alignas
    final override
    and and_eq bitand bitor compl not not_eq or or_eq xor xor_eq
    nullptr
  )

  TAG = %w(name reserved blank newline string char comment preprocessor operator number delimiter)

  def run(file_path)
    get_code_from_file(file_path)
    @cur = 0
    len = @code.size
    ret = []
    while @cur < len
      if name_start? then ret << get_name
      elsif blank?(@code[@cur]) then ret << get_blank
      elsif @code[@cur] == "\n" then ret << get_newline
      elsif @code[@cur] == '"' then ret << get_string
      elsif @code[@cur] == "'" then ret << get_char
      elsif oneline_comment_start? then ret << get_oneline_comment
      elsif multiline_comment_start? then ret << get_multiline_comment
      elsif @code[@cur] == "#" then ret << get_preprocessor
      elsif operator?(@code[@cur]) then ret << get_operator
      elsif number?(@code[@cur]) then ret << get_number
      else
        ret << [@code[@cur], "delimiter"]
        @cur += 1
      end
    end
    ret
  end

  def get_code_from_file(file_path)
    File.open(file_path) do |f|
      @code = f.read.chars
    end
  end

  def name_start?
    @code[@cur] =~ /^[A-Za-z_]$/
  end
  def namable?(c)
    c =~ /^\w$/
  end
  def get_name
    l = @cur
    @cur += 1 while namable?(@code[@cur])
    str = @code[l,@cur-l].join
    tag = if RESERVED.include?(str)
            "reserved"
          else
            "name"
          end
    [str, tag]
  end

  def blank?(c)
    c =~ /^[\t ]$/
  end
  def get_blank
    l = @cur
    @cur += 1 while blank?(@code[@cur])
    [@code[l,@cur-l].join, "blank"]
  end

  def get_newline
    @cur += 1
    ["\n", "newline"]
  end

  def get_string(del = '"', tag = "string")
    l = @cur; @cur += 1
    skip = false
    while skip || @code[@cur] != del
      if skip then skip = false
      elsif @code[@cur] == "\\" then skip = true
      end
      @cur += 1
    end
    @cur += 1
    [@code[l, @cur-l].join, tag]
  end

  def get_char
    get_string("'", "char")
  end

  def oneline_comment_start?
    @code[@cur] == '/' and @cur < @code.size - 1 and @code[@cur+1] == '/'
  end
  def get_oneline_comment
    l = @cur
    skip = false
    while skip || @code[@cur] != "\n"
      if skip then skip = false
      elsif @code[@cur] == "\\" then skip = true
      end
      @cur += 1
    end
    [@code[l, @cur-l].join, "comment"]
  end

  def multiline_comment_start?
    @code[@cur] == '/' and @cur < @code.size - 1 and @code[@cur+1] == '*'
  end
  def get_multiline_comment
    l = @cur; @cur += 2;
    skip = false
    while true
      if skip then skip = false
      elsif @code[@cur] == "\\" then skip = true
      elsif @code[@cur] == '*' and @code[@cur+1] == '/' then
        @cur += 2
        break
      end
      @cur+= 1
    end
    [@code[l, @cur-l].join, "comment"]
  end

  def get_preprocessor
    get_string("\n", "preprocessor")
  end

  def operator?(c)
    c =~ /[\+\-\*\/\&\|\=\%\<\>\!\:\?]/
  end
  def get_operator
    l = @cur;
    @cur += 1 while operator?(@code[@cur])
    [@code[l, @cur-l].join, "operator"]
  end

  def number?(c)
    # because number beginning with dot like ".9" is too complex to implement
    # so first dot will be ignore
    c =~ /[0-9]/
  end
  def numberable?(c)
    c =~ /[0-9.a-zA-Z]/
  end
  def get_number
    l = @cur;
    @cur += 1 while numberable?(@code[@cur])
    [@code[l, @cur-l].join, "number"]
  end
end
