-- EX 603 Assignment 2 — schema.sql
-- Theme: Game Telemetry
-- Author: Derek Campbell
-- Target: PostgreSQL 14+
-- =================================================================
-- Reset. Reverse creation order, so no dependency blocks a drop.
 
DROP TABLE IF EXISTS match_participants CASCADE;
DROP TABLE IF EXISTS match_modes        CASCADE;
DROP TABLE IF EXISTS matches            CASCADE;
DROP TABLE IF EXISTS game_modes         CASCADE;
DROP TABLE IF EXISTS players            CASCADE;

CREATE TABLE players (
    player_id INT PRIMARY KEY,
    display_name VARCHAR(50) NOT NULL
    );
CREATE TABLE matches (
    match_id INT PRIMARY KEY,
    match_name VARCHAR(100) NOT NULL,
    is_ranked BOOLEAN NOT NULL DEFAULT FALSE,
    duration_minutes INT NOT NULL
);
CREATE TABLE match_participants (
    participant_id INT PRIMARY KEY,
    player_id INT NOT NULL,
    match_id INT NOT NULL,
    played_at TIMESTAMP NOT NULL,
    score INT CHECK(score >= 0),

    CONSTRAINT fk_participant_player
        FOREIGN KEY (player_id) REFERENCES players (player_id)
        ON DELETE RESTRICT,
    CONSTRAINT fk_participant_match
        FOREIGN KEY (match_id) REFERENCES matches (match_id)
        ON DELETE CASCADE
);
CREATE TABLE game_modes (
    game_mode_id INT PRIMARY KEY,
    mode_name VARCHAR(50) NOT NULL
);
CREATE TABLE match_modes (
    match_id INT NOT NULL,
    game_mode_id INT NOT NULL,

    CONSTRAINT pk_match_modes
        PRIMARY KEY (match_id, game_mode_id),
    CONSTRAINT fk_match_modes_match
        FOREIGN KEY (match_id) REFERENCES matches(match_id)
        ON DELETE CASCADE,
    CONSTRAINT fk_match_modes_game_mode
        FOREIGN KEY (game_mode_id) REFERENCES game_modes(game_mode_id)
        ON DELETE RESTRICT
);
