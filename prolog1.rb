require 'readline'
require 'msgpack'
class Term
  attr_accessor :pred, :args
  def initialize(str)
    str = str.gsub(".", "")
    abort("Syntax error in term:\n\t #{str}") if not str.end_with?(')')
    fields = str.split('(')
    abort("Syntax error in term: #{str}") if fields.length != 2
    @args = fields[1].split(/,|\)/)
    @pred = fields[0]
  end

  def to_s
    "#{pred}(#{args.join(",")})"
  end
end

class Rule
  attr_accessor :head, :goals
  def initialize(str)
    str = str.gsub(".", "")
    fields = str.split(":-")
    @head = Term.new(fields[0])
    @goals = []
    if fields.length == 2
      fields[1] = fields[1].gsub("),", ");")
      fields = fields[1].split(";")
      fields.each { |field| @goals.push Term.new(field) }
    end
  end

  def to_s
    res = @head.to_s
    unless @goals.empty?
      res << " :- "
      res << @goals[0].to_s
      @goals[1..-1].each { |goal| res << ", " << goal.to_s }
    end
    res << ".\n"
    res
  end
end

class Goal
  attr_accessor :id, :rule, :parent, :env, :idx
  @@goal_id = 0
  def initialize(rule, parent=nil, env={})
    @id = @@goal_id
    @@goal_id += 1
    @rule = rule
    @parent = parent
    @env = MessagePack.unpack(env.to_msgpack)
    @idx = 0
  end

  def unified?
    idx >= rule.goals.size
  end

  def to_s
    "GOAL[#{id}]\trule=#{rule}\tidx=#{idx}\tenv=#{env}"
  end

  def deep_copy
    goal = Goal.new(self.rule, self.parent, self.env)
    goal.id = self.id
    goal.idx = self.idx
    return goal
  end
end

class Interpreter
  attr_accessor :rules, :terms, :debug
  def initialize
    @rules = []
    @terms = []
    @debug = ENV['DEBUG'] ? true : false
  end

  def main
    puts "+------------------------------------------------+"
    puts "|               r p r o l o g                    |"
    puts "| This is a raw implementation of prolog in ruby |"
    puts "| author: Xian Ran, email: xianran@pku.edu.cn    |"
    puts "+------------------------------------------------+"
    filename = ARGV.shift
    if filename
      proc_file(filename)
    end

    while line = Readline.readline("> ?- ", true)
      proc_line(line);
    end
  end

  def proc_file(filename)
    File.open(filename, 'r') do |file|
      loop do
        line = file.gets
        break if line.nil?
        line = line.chomp
        line = line.gsub(/%.*$/, "").gsub(/ /, "")
        rules.push(Rule.new(line))
      end
    end
  end

  def proc_line(line)
    line = line.gsub(/%.*$/, "").gsub(/ /, "")
    case line
    when /quit/ then  exit(0)
    when /dump/ then @rules.each { |rule| puts rule }
    else search(Term.new(line))
    end
  end

  def search(term)
    found = false

    puts "search #{term}" if debug
    goal = Goal.new(Rule.new("got(goal):-x(y)."))
    goal.rule.goals = [term]
    stack = [goal]
    puts "stack:\t#{goal}" if debug
    loop do
      break if stack.empty?
      top = stack.pop
      puts "pop:\t#{top}" if debug
      if top.unified?
        if top.parent.nil?
          puts top.env unless top.env.empty?
          found = true
          next
        end
        parent = top.parent.deep_copy
        unify(top.rule.head, top.env, parent.rule.goals[parent.idx], parent.env)
        parent.idx += 1
        puts "stack:\t#{parent}" if debug
        stack.push parent
        next
      end

      term = top.rule.goals[top.idx]
      @rules.each do |rule|
        next if rule.head.pred != term.pred
        next if rule.head.args.size != term.args.size
        child = Goal.new(rule, top)
        ans = unify(term, top.env, rule.head, child.env)
        if ans
          stack.push(child) 
          puts "stack:\t#{child}" if debug
        end
      end
    end

    found ? (puts "YES.") : (puts "NO.")
  end

  def unify(src_term, src_env, dest_term, dest_env)
    return false if src_term.pred != dest_term.pred
    return false if src_term.args.size != dest_term.args.size
    (0...src_term.args.size).each do |index|
      src_arg, dest_arg = src_term.args[index], dest_term.args[index]
      if src_arg <= 'Z'
        src_val = src_env[src_arg]
      else
        src_val = src_arg
      end
      if src_val
        if dest_arg <= 'Z'
          dest_val = dest_env[dest_arg]
          if not dest_val
            dest_env[dest_arg] = src_val
          elsif dest_val != src_val
            return false
          end
        elsif src_val != dest_arg
          return false
        end
      end
    end
    return true
  end
end

interpreter = Interpreter.new
interpreter.main