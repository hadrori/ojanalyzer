require 'ojanalyzer/analyzers/tokenizer'

class FeatureExtracter
  def run(filepath)
    @tokenizer = Tokenizer.new
    tokens = @tokenizer.run(filepath)
    lines = []
    File.open(filepath) do |file|
      lines = file.read.split("\n")
    end
    analyze(lines, tokens)
  end

  # [
  #   average length of line,
  #   variance length of line,
  #   average length of indent,
  #   variance length of indent,
  #   average length of indent / level,
  #   variance length of indent / level,
  #   average length of name,
  #   variance length of name,
  #   ratio of only upcase name,
  #   ratio of only downcase name,
  #   ratio of include underscore in name,
  #   ratio of space after reserved control word like "if", "while", "for", "switch" "else",
  #   ratio of newline after reserved control word like "if", "while", "for", "switch" "else",
  #   ratio of space before {,
  #   ratio of space after {,
  #   ratio of newline before {,
  #   ratio of newline after {,
  #   ratio of space before (,
  #   ratio of space after (,
  #   ratio of newline before (,
  #   ratio of newline after (,
  #   ratio of space before [,
  #   ratio of space after [,
  #   ratio of newline before [,
  #   ratio of newline after [,
  #   ratio of space before },
  #   ratio of space after },
  #   ratio of newline before },
  #   ratio of newline after },
  #   ratio of space before ),
  #   ratio of space after ),
  #   ratio of newline before ),
  #   ratio of newline after ),
  #   ratio of space before ],
  #   ratio of space after ],
  #   ratio of newline before ],
  #   ratio of newline after ],
  #   number of define,
  #   number of include,
  #   ratio of < after include
  #   ratio of " after include
  # ]
  def analyze(lines, tokens)
    result = []
    result += line_features(lines)
    result += indent_features(tokens)
    result += naming_features(tokens)
    result += keywords_features(tokens)
    result += bracket_features(tokens)
    result += preprocessor_features(tokens)
    result
  end

  def preprocessor_features(tokens)
    counter = {}
    tokens.each do |token, tag|
      next unless tag == "preprocessor"
      add(counter, :define, token.include?("#define"))
      add(counter, :include, token.include?("#include"))
      add(counter, :kakko, token =~ /\#include\s*\</)
      add(counter, :quote, token =~ /\#include\s*\"/)
    end
    result = []
    result << counter[:define]
    result << counter[:include]
    result << div(counter[:kakko], counter[:include])
    result << div(counter[:quote], counter[:include])
    result
  end

  def bracket_features(tokens)
    targets = %w({ \( [ } \) ])
    prev_blank_counter = {}
    prev_newline_counter = {}
    next_blank_counter = {}
    next_newline_counter = {}
    counter = {}
    cur = 0; len = tokens.size
    while cur < len
      token = tokens[cur][0]
      tag   = tokens[cur][1]
      unless targets.include?(token)
        cur += 1
        next
      end
      add(counter, token, true)
      if cur > 0
        add(prev_blank_counter, token, tokens[cur-1][1] == "blank")
        add(prev_newline_counter, token, tokens[cur-1][1] == "newline")
      end
      if cur < len - 1
        add(next_blank_counter, token, tokens[cur+1][1] == "blank")
        add(next_newline_counter, token, tokens[cur+1][1] == "newline")
      end
      cur += 1
    end

    result = []
    targets.each do |t|
      result << div(prev_blank_counter[t], counter[t])
      result << div(prev_newline_counter[t], counter[t])
      result << div(next_blank_counter[t], counter[t])
      result << div(next_newline_counter[t], counter[t])
    end
    result
  end

  def div(x, y)
    x ||= 0
    y ||= 0
    return 0 if y == 0
    1.0 * x / y
  end

  def add(counter, key, flag)
    counter[key] ||= 0
    counter[key] += 1 if flag
  end

  def keywords_features(tokens)
    target_words = %w(if else while do for switch case)
    target = false
    cur = 0; len = tokens.size
    blanks = []; newlines = []
    while cur < len
      token = tokens[cur][0]
      tag   = tokens[cur][1]
      if target_words.include?(token)
        ntag = tokens[cur+1][1]
        blanks << (ntag == "blank" ? 1 : 0)
        newlines << (ntag == "newline" ? 1 : 0)
      end
      cur += 1
    end
    [average(blanks), average(newlines)]
  end

  def naming_features(tokens)
    exception = %w(vector string pair int64_t queue stack priority_queue cin cout printf scanf gets getline puts push_back make_pair main ios_base std sync_with_stdio endl memset malloc free calloc complex min max sin cos tan sqrt abs ostream __builtin_popcount __gcd __buitlin_popcountll memcpy first second size erase unique begin end)
    names = tokens.select { |token, tag| tag == "name" }.map(&:first).reject {|name| exception.include?(name) }.uniq
    lens = names.map(&:size)
    upcs = names.map { |name| name.upcase == name ? 1 : 0 }
    dwcs = names.map { |name| name.downcase == name ? 1 : 0 }
    uscs = names.map { |name| name.include?('_') ? 1 : 0 }
    result = []
    result += ave_var(lens)
    result << average(upcs)
    result << average(dwcs)
    result << average(uscs)
    result
  end

  def indent_features(tokens)
    depth = 0; semicolon = true; newline = true
    indents = []; levels = []

    tokens.each do |token|
      tag = token[1]

      case tag
      when "newline"
        newline = true
        next
      when "blank"
        if newline
          depth += 1 unless semicolon
          indents << indent_size(token[0])
          levels  << depth
          depth -= 1 unless semicolon
          newline = false
        end
      when "delimiter"
        if token[0] =~ /[\{\(\[]/
          depth += 1
        elsif token[0] =~ /[\}\)\]]/
          depth -= 1
        elsif token[0] == ';'
          semicolon = true
          next
        end
      end
      if newline
        indents << 0
        levels  << depth
      end
      semicolon = false
      newline = false
    end

    indents_levels = indents.zip(levels).select{|blank, level| level > 0}

    result = ave_var(indents_levels.map(&:first))
    result += ave_var(indents_levels.map{|blank, level| 1.0 * blank.size / level})
    result
  end

  def indent_size(blanks)
    blanks.gsub(/\t/, ' '*16).size
  end

  def line_features(lines)
    ave_var(lines.map(&:size))
  end

  def ave_var(arr)
    ave = average(arr)
    [ave, variance(arr, ave)]
  end

  def average(arr)
    return 0 if arr.empty?
    1.0 * arr.inject(:+) / arr.size
  end

  def variance(arr, ave)
    return 0 if arr.empty?
    1.0 * arr.inject{ |s, x| s + (x-ave)**2 } / arr.size
  end
end
