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
    is_near_window BOOL,
    created_at     TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at     TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE chicken (
    chicken_id    SERIAL PRIMARY KEY,
    chicken_name  VARCHAR(100) NOT NULL,
    sex           VARCHAR(10)  NOT NULL CHECK ( sex IN ('Rooster', 'Hen') ),
    feather_color VARCHAR(50),
    favorite_song INT          NOT NULL,
    egg_id        INT          NOT NULL,
    birth_date    DATE         NOT NULL,
    created_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


CREATE TABLE egg (
    egg_id     SERIAL PRIMARY KEY,
    laid_date  DATE NOT NULL,
    mother_id  INT  NOT NULL,
    father_id  INT  NOT NULL,
    spot_id    INT  NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
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


CREATE VIEW vw_direct_family AS
    SELECT c.chicken_id       AS chicken_id
         , c.chicken_name
         , c.birth_date
         , s.title            AS favorite_song
         , c.egg_id
         , e.spot_id
         , mother.chicken_id  AS mother_id
         , mother.egg_id      AS mother_egg
         , mother_egg.spot_id AS mother_spot
         , father.chicken_id  AS father_id
         , father.egg_id      AS father_egg
         , father_egg.spot_id AS father_spot
    FROM chicken           c
         LEFT JOIN egg     e
            ON c.egg_id = e.egg_id
         LEFT JOIN chicken mother
            ON e.mother_id = mother.chicken_id
         LEFT JOIN egg AS  mother_egg
            ON mother.egg_id = mother_egg.egg_id
         LEFT JOIN chicken father
            ON e.father_id = father.chicken_id
         LEFT JOIN egg AS  father_egg
            ON father.egg_id = father_egg.egg_id
         LEFT JOIN song    s
            ON c.favorite_song = s.song_id
;

CREATE VIEW vw_grand_parents AS
    (
    SELECT df.*

         , mo_grandpa.chicken_id AS mo_grandpa_id
         , mo_grandpa.egg_id     AS mo_grandpa_egg
         , mo_grandma.chicken_id AS mo_grandma_id
         , mo_grandma.egg_id     AS mo_grandma_egg

         , fa_grandma.chicken_id AS fa_grandma_id
         , fa_grandma.egg_id     AS fa_grandma_egg
         , fa_grandpa.chicken_id AS fa_grandpa_id
         , fa_grandpa.egg_id     AS fa_grandpa_egg

    FROM vw_direct_family              df
         LEFT JOIN vw_direct_family AS mo_grandma
            ON df.mother_id = mo_grandma.mother_id
         LEFT JOIN vw_direct_family AS mo_grandpa
            ON df.mother_id = mo_grandpa.father_id

         LEFT JOIN vw_direct_family AS fa_grandma
            ON df.mother_id = fa_grandma.mother_id
         LEFT JOIN vw_direct_family AS fa_grandpa
            ON df.mother_id = fa_grandpa.father_id
        )
;

create view vw_tags as (
with complete_info as (
    select chicken_name, favorite_song,  isp1.description as spot, ch1.chicken_id
    from chicken ch1
    left join egg eg1 on ch1.egg_id = eg1.egg_id
    left join incubation_spot isp1 on eg1.spot_id = isp1.spot_id)
select gp.chicken_name
        , isp.spot_number::varchar(4) ||' - ' || isp.description as spot
        , max('Mother: ' || mother.chicken_name || ' - ' || mother.spot) as mother
        , max('Father: ' || father.chicken_name || ' - ' || father.spot) as father
        , max('Mothers Grandpas: ' || mogpa.chicken_name || ' - ' || mogpa.spot || ', ' || mogma.chicken_name || ' - ' || mogma.spot) as "Mothers Grandpas"
        , max('Fathers Grandpas: ' || fagpa.chicken_name || ' - ' || fagpa.spot || ', ' || fagma.chicken_name || ' - ' || fagma.spot) as "Fathers Grandpas"
from vw_grand_parents gp
     left join incubation_spot isp on gp.spot_id = isp.spot_id
    --mother
     left join complete_info mother on gp.mother_id = mother.chicken_id
    --father
     left join complete_info father on father.chicken_id = gp.father_id
    -- mother grampas
     left join complete_info mogpa on mogpa.chicken_id = gp.mo_grandpa_id
     left join complete_info mogma on mogma.chicken_id = gp.mo_grandma_id
     -- fathers grampas
     left join complete_info fagpa on fagpa.chicken_id = gp.fa_grandpa_id
     left  join complete_info fagma on fagma.chicken_id = gp.fa_grandma_id
group by 1,2
)
