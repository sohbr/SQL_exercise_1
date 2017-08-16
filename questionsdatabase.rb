require 'byebug'
require 'sqlite3'
require 'singleton'
class QuestionsDB < SQLite3::Database
  include Singleton

  def initialize
    super('questionsdatabase.db')
    self.type_translation = true
    self.results_as_hash = true
  end
end

class Question

  attr_accessor :title, :body, :user_id

  def self.all
    data = QuestionsDB.instance.execute("SELECT * FROM questions")
    data.map { |datum| Question.new(datum)}
  end

  def self.find_by_id(id)
    question = QuestionsDB.instance.execute(<<-SQL, id)
      SELECT *
      FROM questions
      WHERE id = ?
    SQL

    return nil unless question.length > 0

    question.map {|question| Question.new(question)}
  end

  def author
    author = QuestionsDB.instance.execute(<<-SQL, @user_id)
    SELECT fname, lname
    FROM users
    WHERE users.id = ?
    SQL

    return nil unless author.length > 0

    return User.new(author[0])

  end

  def self.find_by_author_id(user_id)
    question = QuestionsDB.instance.execute(<<-SQL, user_id)
      SELECT *
      FROM questions
      WHERE user_id = ?
    SQL

    return nil unless question.length > 0

    Question.new(question.first)
  end

  def followers
    QuestionFollow.followers_for_question_id(@id)
  end

  def self.most_followed(n)
    QuestionFollow.most_followed_questions(n)
  end

  def likers
    QuestionLike.likers_for_question_id(@id)
  end

  def num_likes
    QuestionLike.num_likes_for_question_id(@id)
  end

  def initialize(options)

    @title = options['title']
    @body = options['body']
    @user_id = options['user_id']
    @id = options['id']
  end

end

class User
  attr_accessor :fname, :lname, :id

  def self.all
    data = QuestionsDB.instance.execute("SELECT * FROM users")
    data.map {|datum| User.new(datum)}
  end

  def self.find_by_id(id)
    user = QuestionsDB.instance.execute(<<-SQL, id)
      SELECT *
      FROM users
      WHERE id = ?
    SQL

    return nil unless user.length > 0

    User.new(user.first)
  end

  def self.find_by_name(fname,lname)
    user = QuestionsDB.instance.execute(<<-SQL, fname, lname)
      SELECT *
      FROM users
      WHERE fname = ?, lname = ?
    SQL

    return nil unless user.length > 0
    User.new(user.first)
  end

  def authored_questions
    Question.find_by_author_id(@id)
  end

  def authored_replies
    Reply.find_by_user_id(@id)
  end

  def followed_questions
    QuestionFollow.followed_questions_for_user_id(@id)
  end

  def liked_questions
    QuestionLike.liked_questions_for_user_id(@id)
  end

  def initialize(options)
    # debugger
    @fname = options['fname']
    @lname = options['lname']
    @id = options['id']
  end
end

class QuestionFollow
  attr_accessor :user_id, :question_id
  def self.all
    data = QuestionsDB.instance.execute("SELECT * FROM replies")
    data.map {|datum| QuestionFollow.new(datum)}
  end

  def self.find_by_id(id)
    question_follow = QuestionsDB.instance.execute(<<-SQL, id)
      SELECT *
      FROM question_follows
      WHERE id = ?
    SQL

    return nil unless question_follow.length > 0

    QuestionFollow.new(question_follow.first)
  end

  def self.followers_for_question_id(question_id)
    question_followers = QuestionsDB.instance.execute(<<-SQL, question_id)
      SELECT *
      FROM users
      JOIN question_follows ON users.id = question_follows.user_id
      WHERE question_follows.question_id = ?
    SQL

    return nil unless question_followers.length > 0

    question_followers.map {|follower| User.new(follower)}
  end

  def self.followed_questions_for_user_id(user_id)
    followed_questions = QuestionsDB.instance.execute(<<-SQL, user_id)
      SELECT *
      FROM questions
      JOIN question_follows ON questions.id = question_follows.question_id
      WHERE question_follows.user_id = ?
    SQL

    return nil unless followed_questions.length > 0

    followed_questions.map {|question| Question.new(question)}
  end

  def self.most_followed_questions(n)
    most_followed_questions = QuestionsDB.instance.execute(<<-SQL, n)
      SELECT *, COUNT(question_follows.user_id)
      FROM questions
      JOIN question_follows ON questions.id = question_follows.question_id
      GROUP BY questions.id
      ORDER BY COUNT(question_follows.user_id) DESC
      LIMIT ?
    SQL

    return nil unless most_followed_questions.length > 0

    most_followed_questions.map {|question| Question.new(question)}
  end


  def initialize(options)
    @question_id = options['question_id']
    @user_id = options['user_id']
    @id = options['id']
  end

end

class Reply
  attr_accessor :user_id, :question_id
  def self.all
    data = QuestionsDB.instance.execute("SELECT * FROM replies")
    data.map {|datum| Reply.new(datum)}
  end

  def self.find_by_id(id)
    reply = QuestionsDB.instance.execute(<<-SQL, id)
      SELECT *
      FROM replies
      WHERE id = ?
    SQL

    return nil unless reply.length > 0

    Reply.new(reply.first)
  end

  def self.find_by_user_id(user_id)
    reply = QuestionsDB.instance.execute(<<-SQL, user_id)
      SELECT *
      FROM replies
      WHERE user_id = ?
    SQL

    return nil unless reply.length > 0

    Reply.new(reply.first)
  end

  def self.find_by_question_id(question_id)
    reply = QuestionsDB.instance.execute(<<-SQL, question_id)
      SELECT *
      FROM replies
      WHERE question_id = ?
    SQL

    return nil unless reply.length > 0

    Reply.new(reply.first)
  end

  def author
    User.find_by_id(@user_id)
  end

  def question
    Question.find_by_id(@question_id)
  end

  def parent_reply
    Reply.find_by_id(@parent_reply)
  end

  def child_replies
    replies = QuestionsDB.instance.execute(<<-SQL, @id)
      SELECT *
      FROM replies
      WHERE replies.parent_reply = ?
    SQL

    return nil unless replies.length > 0

    replies.map {|reply| Reply.new(reply) }
  end

  def initialize(options)
    @question_id = options['question_id']
    @user_id = options['user_id']
    @id = options['id']
  end

end

class QuestionLike
  attr_accessor :user_id, :question_id
  def self.all
    data = QuestionsDB.instance.execute("SELECT * FROM question_likes")
    data.map {|datum| QuestionLike.new(datum)}
  end

  def self.find_by_id(id)
    question_like = QuestionsDB.instance.execute(<<-SQL, id)
      SELECT *
      FROM question_likes
      WHERE id = ?
    SQL

    return nil unless question_like.length > 0

    QuestionLike.new(question_like.first)
  end

  def self.most_liked_questions(n)
    most_liked = QuestionsDB.instance.execute(<<-SQL, n)
      SELECT questions.*, COUNT(question_likes.user_id)
      FROM questions
      JOIN question_likes ON questions.id = question_likes.question_id
      GROUP BY questions.id
      ORDER BY COUNT(question_likes.user_id) DESC
      LIMIT ?
    SQL

    return nil if most_liked.length > 0
    most_liked.map {|question| Question.new(question)}
  end

  def self.num_likes_for_question_id(question_id)
    num_likes = QuestionsDB.instance.execute(<<-SQL, question_id)
      SELECT COUNT(question_likes.question_id)
      FROM question_likes
      WHERE question_likes.question_id = ?
      GROUP BY question_likes.question_id
    SQL

    return nil if num_likes == 0
    num_likes[0]['COUNT(question_likes.question_id)']

  end

  def self.liked_questions_for_user_id(user_id)
    liked_questions = QuestionsDB.instance.execute(<<-SQL, user_id)
      SELECT *
      FROM questions
      JOIN question_likes on questions.id = question_likes.question_id
      WHERE question_likes.user_id = ?
    SQL

    return nil unless liked_questions.length > 0
    liked_questions.map {|question| Question.new(question)}
  end

  def self.likers_for_question_id(question_id)
    question_likers = QuestionsDB.instance.execute(<<-SQL, question_id)
      SELECT *
      FROM users
      JOIN question_likes ON users.id = question_likes.user_id
      WHERE question_likes.question_id = ?
    SQL

    return nil unless question_likers.length > 0
    question_likers.map {|liker| User.new(liker)}
  end

  def initialize(options)
    @question_id = options['question_id']
    @user_id = options['user_id']
    @id = options['id']
  end


end
