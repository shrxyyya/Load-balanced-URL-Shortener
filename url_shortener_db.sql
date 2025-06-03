CREATE DATABASE IF NOT EXISTS url_shortener;
USE url_shortener;

CREATE TABLE redirections (
	ID INT AUTO_INCREMENT PRIMARY KEY,
    long_url VARCHAR(1024) NOT NULL,
    short_url VARCHAR(20) UNIQUE DEFAULT NULL
);

SELECT * FROM redirections;