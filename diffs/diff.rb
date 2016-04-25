class Differ

  DiffResults = Struct.new(:before, :after, :removed, :added, :unchanged)

  def initialize(before, after)
    @before = before
    @after  = after
  end

  def make_memo
    num_rows = @after.length + 1
    num_cols = @before.length + 1
    memo = []
    num_rows.times {memo << Array.new(num_cols)}
    memo.each {|after_matches| after_matches[0] = 0}
    memo.first.map! { 0 }
    (1...num_rows).each do |i|
      (1...num_cols).each do |j|
        memo[i][j] = if @before[j - 1] == @after[i - 1] then
                       memo[i - 1][j - 1] + 1
                     else
                       [ memo[i - 1][j], memo[i][j - 1] ].max
                     end
      end
    end
    memo
  end

  def create_diff(memo, generate_memo_display=false)
    # Set up a string representation of the memo for display
    if generate_memo_display
      str_memo = memo.map { |row| row.map(&:to_s) }
      str_memo_cols_guide = (" " << @before).split ""
      str_memo_rows_guide = (" " << @after).split ""
    end

    only_in_before = []
    only_in_after = []
    matches = []
    row_i = memo.length - 1
    col_i = memo.first.length - 1
    while (row_i > 0)
      curr_row = memo[row_i]
      while (col_i > 0 and curr_row[col_i - 1] == curr_row[col_i])
        only_in_before << @before[col_i - 1]
        only_in_after << nil
        matches << nil

        if generate_memo_display
          colorize_str! str_memo[row_i][col_i], TERM_RED
          colorize_str! str_memo_cols_guide[col_i], TERM_RED
        end

        col_i -= 1
      end

      if (memo[row_i - 1][col_i] == curr_row[col_i])
        only_in_after << @after[row_i - 1]
        only_in_before << nil
        matches << nil

        if generate_memo_display
          colorize_str! str_memo[row_i][col_i], TERM_GREEN
          colorize_str! str_memo_rows_guide[row_i], TERM_GREEN
        end

        row_i -= 1
      else
        matches << @before[col_i - 1]
        only_in_before << nil
        only_in_after << nil

        if generate_memo_display
          colorize_str! str_memo[row_i][col_i], TERM_BLUE
          colorize_str! str_memo_cols_guide[col_i], TERM_BLUE
          colorize_str! str_memo_rows_guide[row_i], TERM_BLUE
        end

        row_i -= 1
        col_i -= 1
      end
    end

    # add guides to str_memo
    if generate_memo_display
      str_memo.unshift str_memo_cols_guide
      str_memo_rows_guide.unshift " " # fix padding on display's row guide
      str_memo.each_with_index {|col, i| col.unshift str_memo_rows_guide[i] || " "}
      @memo_display = str_memo
    end

    return DiffResults.new(
      @before,
      @after,
      only_in_before.reverse,
      only_in_after.reverse,
      matches.reverse)
  end

  def colorize_str!(str, color)
    str.prepend color
    str << TERM_RESET
    return str
  end

  attr_accessor :memo_display

  def self.pretty_print(results, memo_display=nil)
    removed = results.removed
    added = results.added
    unchanged = results.unchanged

    stringify_arr = ->(arr) do
      return arr.reduce('') {|memo, c| memo << (c || ' ')}
    end

    result = ""

    # if the memo display is passed in, add it to the results string
    if memo_display
      result << "LCS array visualization:\n"
      result << memo_display.each_with_index.map do |arr, i|
        arr.reduce("[ ") {|memo, obj| memo << (obj + " ")} << "]"
      end.join("\n")
      result << "\n\n==========Diff===========\n"
    end

    result << "- #{TERM_RED}#{stringify_arr.call removed}#{TERM_RESET}\n"
    result << "+ #{TERM_GREEN}#{stringify_arr.call added}#{TERM_RESET}\n"
    result << "= #{stringify_arr.call unchanged}"
  end

  def self.simple_diff(str1, str2)
    puts "\nDiffing '#{str1}' and '#{str2}'"
    instance = get_class_instance(str1, str2)
    memo = instance.make_memo
    results = instance.create_diff memo, true
    puts self.pretty_print(results, instance.memo_display)
  end

  def self.diff(str1, str2)
    instance = get_class_instance(str1, str2)
    memo = instance.make_memo
    return instance.create_diff memo
  end

  private
  def self.get_class_instance(str1, str2)
    return self.new(str1, str2)
  end

  # terminal colors
  TERM_RED   = "\e[31m"
  TERM_GREEN = "\e[32m"
  TERM_BLUE  = "\e[34m"
  TERM_RESET = "\e[0m"

end

Differ.simple_diff "abcdefgd", "aabcdgf"
Differ.simple_diff "aaaaaaaa", "aaaaaaba"
Differ.simple_diff "abcdefg", "hijklmno"
Differ.simple_diff "abcd", "hbicjdk"
Differ.simple_diff "abcdefg", "abcdefg"

puts "Can also return the data directly:\n#{
  Differ.diff "Abcdefg", "aBCDEfg"
}"
