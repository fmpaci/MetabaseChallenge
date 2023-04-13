CREATE DATABASE chicken_farm;

CREATE TABLE song (
    song_id     SERIAL PRIMARY KEY,
    title       VARCHAR(100) NOT NULL,
    artist      VARCHAR(100) NOT NULL,
    genre       VARCHAR(50),
    song_length INT,
    created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE incubation_spot (
    spot_id        SERIAL PRIMARY KEY,
    spot_number    INTEGER NOT NULL UNIQUE,
    description    VARCHAR(255),
    is_near_window CHAR(1),
    created_at     TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at     TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


CREATE TABLE egg (
    egg_id     SERIAL PRIMARY KEY,
    laid_date  DATE NOT NULL,
    mother_id  INT  NOT NULL CONSTRAINT egg_mother REFERENCES chicken,
    father_id  INT  NOT NULL CONSTRAINT egg_father REFERENCES chicken,
    spot_id    INT  NOT NULL CONSTRAINT egg_spot REFERENCES incubation_spot,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


CREATE TABLE chicken (
    chicken_id    SERIAL PRIMARY KEY,
    chicken_name  VARCHAR(100) NOT NULL,
    sex           VARCHAR(10)  NOT NULL CHECK ( sex IN ('Rooster', 'Hen') ),
    feather_color VARCHAR(50),
    favorite_song INT          NOT NULL CONSTRAINT chicken_song REFERENCES song,
    egg_id        INT          NOT NULL,
    created_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);



CREATE FUNCTION fn_log_change_time() RETURNS TRIGGER
    LANGUAGE plpgsql AS
$$
BEGIN
    new.updated_at = NOW();
    RETURN new;
END;
$$;

CREATE TRIGGER tg_bu_song_updated_at
    BEFORE UPDATE
    ON song
    FOR EACH ROW
EXECUTE PROCEDURE fn_log_change_time();

CREATE TRIGGER tg_bu_incubation_spot_updated_at
    BEFORE UPDATE
    ON incubation_spot
    FOR EACH ROW
EXECUTE PROCEDURE fn_log_change_time();

CREATE TRIGGER tg_bu_egg_updated_at
    BEFORE UPDATE
    ON egg
    FOR EACH ROW
EXECUTE PROCEDURE fn_log_change_time();

CREATE TRIGGER tg_bu_chicken_updated_at
    BEFORE UPDATE
    ON chicken
    FOR EACH ROW
EXECUTE PROCEDURE fn_log_change_time();
