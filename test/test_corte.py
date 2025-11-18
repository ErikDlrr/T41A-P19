import pytest
import psycopg2
import os

@pytest.fixture
def db_conn():
    conn = psycopg2.connect(
        host="localhost",
        database=os.getenv("POSTGRES_DB", "test_db"),
        user=os.getenv("POSTGRES_USER", "postgres"),
        password=os.getenv("POSTGRES_PASSWORD", "postgres"),
        port="5432"
    )
    conn.autocommit = True
    yield conn
    conn.close()
  
def test_sp_rotar_posicionar_figuras(db_conn):
    cur = db_conn.cursor()

    cur.execute("""
        INSERT INTO piezas (id, nombre, pos_x, pos_y, rotacion, geometria)
        VALUES (100, 'Pieza Test', 0, 0, 0, 'rectangulo')
        ON CONFLICT (id) DO NOTHING;
    """)
    
    nuevo_x = 10
    nuevo_y = 20
    nueva_rotacion = 90
    evento_json = '{"evento": "rotacion", "usuario": "admin"}'

    cur.execute(f"CALL sp_rotar_posicionar_figuras(100, {nueva_rotacion}, {nuevo_x}, {nuevo_y}, '{evento_json}');")

    cur.execute("SELECT pos_x, pos_y, rotacion FROM piezas WHERE id = 100;")
    resultado = cur.fetchone()

    assert resultado[0] == nuevo_x      # pos_x
    assert resultado[1] == nuevo_y      # pos_y
    assert resultado[2] == nueva_rotacion # rotacion

    cur.close()

def test_fn_calcular_utilizacion(db_conn):
    cur = db_conn.cursor()

    try:
        cur.execute("SELECT fn_calcular_utilizacion(1);") 
        resultado = cur.fetchone()[0]
        assert resultado >= 0
        assert resultado <= 100
        print(f"Utilización calculada: {resultado}%")
        
    except Exception as e:
        pytest.fail(f"La función falló: {e}")

    cur.close()
def test_trigger_validacion_distancia(db_conn):
    cur = db_conn.cursor()
    cur.execute("""
        INSERT INTO piezas (id, pos_x, pos_y) 
        VALUES (201, 10, 10) 
        ON CONFLICT (id) DO NOTHING;
    """)

    with pytest.raises(psycopg2.DatabaseError) as error_info:
        cur.execute("""
            INSERT INTO piezas (id, pos_x, pos_y) 
            VALUES (202, 10, 11);
        """)
    cur.close()
