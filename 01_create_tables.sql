DROP TABLE IF EXISTS eventos;
DROP TABLE IF EXISTS piezas;
DROP TABLE IF EXISTS materia_prima;
DROP TABLE IF EXISTS usuarios;
DROP TABLE IF EXISTS roles;

CREATE TABLE roles (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(50) UNIQUE NOT NULL
);

CREATE TABLE usuarios (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(100),
    rol_id INT REFERENCES roles(id)
);

CREATE TABLE materia_prima (
    id SERIAL PRIMARY KEY,
    numero_parte VARCHAR(50) UNIQUE,
    ancho NUMERIC,
    alto NUMERIC,
    distancia_minima_piezas NUMERIC,
    distancia_minima_borde NUMERIC
);

CREATE TABLE piezas (
    id SERIAL PRIMARY KEY,
    materia_prima_id INT REFERENCES materia_prima(id),
    numero_parte VARCHAR(50),
    geometria VARCHAR(50),
    ancho NUMERIC,
    alto NUMERIC,
    pos_x NUMERIC DEFAULT 0,
    pos_y NUMERIC DEFAULT 0,
    rotacion NUMERIC DEFAULT 0
);

CREATE TABLE eventos (
    id SERIAL PRIMARY KEY,
    pieza_id INT REFERENCES piezas(id),
    datos_json JSONB,
    fecha TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE OR REPLACE PROCEDURE sp_rotar_posicionar_figuras(
    p_pieza_id INT,
    p_rotacion NUMERIC,
    p_pos_x NUMERIC,
    p_pos_y NUMERIC,
    p_evento_json JSONB
)
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE piezas
    SET rotacion = p_rotacion,
        pos_x = p_pos_x,
        pos_y = p_pos_y
    WHERE id = p_pieza_id;

    INSERT INTO eventos (pieza_id, datos_json)
    VALUES (p_pieza_id, p_evento_json);
END;
$$;

CREATE OR REPLACE FUNCTION fn_calcular_utilizacion(p_materia_id INT)
RETURNS NUMERIC
LANGUAGE plpgsql
AS $$
DECLARE
    v_area_total NUMERIC;
    v_area_ocupada NUMERIC;
BEGIN
    SELECT ancho * alto INTO v_area_total
    FROM materia_prima
    WHERE id = p_materia_id;

    SELECT COALESCE(SUM(ancho * alto), 0) INTO v_area_ocupada
    FROM piezas
    WHERE materia_prima_id = p_materia_id;

    IF v_area_total = 0 OR v_area_total IS NULL THEN
        RETURN 0;
    END IF;

    RETURN (v_area_ocupada / v_area_total) * 100;
END;
$$;

CREATE OR REPLACE FUNCTION fn_validar_posicion()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_borde NUMERIC;
    v_mp_ancho NUMERIC;
    v_mp_alto NUMERIC;
BEGIN
    SELECT distancia_minima_borde, ancho, alto
    INTO v_borde, v_mp_ancho, v_mp_alto
    FROM materia_prima
    WHERE id = NEW.materia_prima_id;

    IF NEW.pos_x < v_borde OR NEW.pos_y < v_borde THEN
        RAISE EXCEPTION 'Violacion de borde minimo';
    END IF;

    IF (NEW.pos_x + NEW.ancho) > (v_mp_ancho - v_borde) OR 
       (NEW.pos_y + NEW.alto) > (v_mp_alto - v_borde) THEN
        RAISE EXCEPTION 'Pieza fuera de limites de materia prima';
    END IF;

    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_validar_posicion
BEFORE INSERT OR UPDATE ON piezas
FOR EACH ROW
EXECUTE FUNCTION fn_validar_posicion();
