INSERT INTO roles (nombre) VALUES 
('Administrador'), 
('Operador');

INSERT INTO usuarios (nombre, rol_id) VALUES 
('Juan Perez', 1), 
('Ana Lopez', 2);

INSERT INTO materia_prima (numero_parte, ancho, alto, distancia_minima_piezas, distancia_minima_borde) VALUES
('MP-001', 100, 100, 2, 5);

INSERT INTO piezas (materia_prima_id, numero_parte, geometria, ancho, alto, pos_x, pos_y, rotacion) VALUES
(1, 'PZ-A', 'rectangulo', 10, 20, 10, 10, 0),
(1, 'PZ-B', 'rectangulo', 15, 15, 40, 40, 0);
