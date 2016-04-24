module Differ
  def self.make_memo(s1, s2)
    num_rows = s2.length + 1
    num_cols = s1.length + 1
    memo = []
    (num_rows).times {memo << Array.new(num_cols)}
    memo.each {|s2_matches| s2_matches[0] = 0}
    memo.first.map! { 0 }
    (1...num_rows).each do |i|
      (1...num_cols).each do |j|
        # puts "i: #{i}, j: #{j}"
        # p memo
        if (s1[j - 1] == s2[i - 1])
          # puts "Found a match for s1[#{j - 1}]: #{s1[j - 1]}"
          memo[i][j] = memo[i - 1][j - 1] + 1
        else
          # puts "s1[#{j - 1}] and s2[#{i - 1}] did not match: #{s1[j - 1]}, #{s2[i - 1]}"
          memo[i][j] = [ memo[i - 1][j], memo[i][j - 1] ].max
        end
      end
    end
    memo
  end

  def self.create_diff(memo, s1, s2)
    only_in_s1 = []
    only_in_s2 = []
    matches = []
    row_i = memo.length - 1
    col_i = memo.first.length - 1
    while (row_i > 0)
      curr_row = memo[row_i]
      while (col_i > 0 and curr_row[col_i - 1] == curr_row[col_i])
        only_in_s1 << s1[col_i - 1]
        only_in_s2 << nil
        matches << nil
        col_i -= 1
      end

      if (memo[row_i - 1][col_i] == curr_row[col_i])
        only_in_s2 << s2[row_i - 1]
        only_in_s1 << nil
        matches << nil
        row_i -= 1
      else
        raise "oops #{row_i}, #{col_i}" if s1[col_i - 1] != s2[row_i - 1]
        matches << s1[col_i - 1]
        only_in_s1 << nil
        only_in_s2 << nil
        row_i -= 1
        col_i -= 1
      end
      puts "col: #{col_i}, row: #{row_i}"
    end
    return only_in_s1, only_in_s2, matches
  end

  def self.pretty_print(added, removed, unchanged)
    fix_arr = ->(arr) do
      return arr.reverse.map {|c| c ? c : ' '}.join ''
    end
    result = ""
    result << "\e[31m#{fix_arr.call added}\e[0m\n"
    result << "\e[32m#{fix_arr.call removed}\e[0m\n"
    result << "#{fix_arr.call unchanged}"
  end

  def self.simple_diff(str1, str2)
    puts "Diffing '#{str1}' and '#{str2}'"
    memo = Differ.make_memo(str1, str2)
    added, removed, unchanged = Differ.create_diff(memo, str1, str2)
    puts Differ.pretty_print added, removed, unchanged
  end
end

Differ.simple_diff "abcdefgd", "aabcdgf"
Differ.simple_diff "aaaaaaaa", "aaaaaaba"
Differ.simple_diff "abcdefg", "hijklmno"
Differ.simple_diff "abcdefg", "ahbicjdkelfmgn"
