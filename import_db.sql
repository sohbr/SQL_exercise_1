DROP TABLE IF EXISTS users;

CREATE TABLE users (
  id INTEGER PRIMARY KEY,
  fname VARCHAR(30),
  lname VARCHAR(30)

);

DROP TABLE if exists questions;

CREATE TABLE questions (
  id INTEGER PRIMARY KEY,
  title VARCHAR(255),
  body TEXT,
  user_id INTEGER NOT NULL,

  FOREIGN KEY (user_id) REFERENCES users(id)
);

DROP TABLE if exists question_follows;

CREATE TABLE question_follows (
  id INTEGER PRIMARY KEY,
  user_id INTEGER NOT NULL,
  question_id INTEGER NOT NULL,

  FOREIGN KEY (user_id) REFERENCES users(id),
  FOREIGN KEY (question_id) REFERENCES questions(id)

);

DROP TABLE if exists replies;

CREATE TABLE replies (
  id INTEGER PRIMARY KEY,
  body TEXT,
  question_id INTEGER NOT NULL,
  parent_reply INTEGER,
  user_id INTEGER NOT NULL,

  FOREIGN KEY (question_id) REFERENCES questions(id),
  FOREIGN KEY (parent_reply) REFERENCES replies(id),
  FOREIGN KEY (user_id) REFERENCES users(id)
);

DROP TABLE if exists question_likes;

CREATE TABLE question_likes (
  id INTEGER PRIMARY KEY,
  user_id INTEGER NOT NULL,
  question_id INTEGER NOT NULL,

  FOREIGN KEY (user_id) REFERENCES users(id),
  FOREIGN KEY (question_id) REFERENCES questions(id)

);

INSERT INTO
  users (fname, lname)
VALUES
  ('Brian', 'Sohn'),
  ('Rachel', 'Jacobson');

INSERT INTO
  questions (title, body, user_id)
VALUES
  ('SQL?','SQLite3',1),
  ('ORM?','ORM IS GREAT!',2);

INSERT INTO
  question_follows (user_id, question_id)
VALUES
  (1, 2),
  (2, 1);

INSERT INTO
  replies (body, question_id, user_id, parent_reply)
VALUES
  ('yes SQL is great', 1, 2, null),
  ('yes ORM go', 2, 1, null),
  ('yes yes I agree', 1, 1, 1);

INSERT INTO
  question_likes (user_id, question_id)
VALUES
  (1, 2),
  (2, 1);
