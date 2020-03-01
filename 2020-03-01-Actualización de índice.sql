CREATE TABLE intervalos(
  id SERIAL NOT NULL,
  minimo NUMERIC(12,4),
  maximo NUMERIC(12,4),
  minimo_actual NUMERIC(12,4),
  maximo_actual NUMERIC(12,4),
  nivel integer,
  CONSTRAINT intervalos_pkey PRIMARY KEY (id)
);

ALTER TABLE images RENAME COLUMN id_hoja TO id_nodo;

DROP TRIGGER actualizar_indice ON images;
DROP TRIGGER agregar_indice ON images;

DROP FUNCTION actualizar_indice();
CREATE OR REPLACE FUNCTION public.actualizar_indice()
  RETURNS trigger AS
$BODY$
DECLARE
	nodoAnterior indice;
	nodoActual indice;
	nivelActual integer;
	distanciaAPivote integer;
	cantidadPivotes integer;
	pivoteActual pivotes;
	intervalo intervalos;
BEGIN
	-- La tabla de indices debe contener previamente el pivote nivel 1 agregado
	-- con id_padre en NULL, distancia = 0 y nivel = 1. 
	-- Esa es la raíz del árbol. 
	SELECT INTO nodoAnterior * FROM indice WHERE id_padre IS NULL; --inicializa en raiz

	nivelActual := 1;
	SELECT INTO cantidadPivotes COUNT(*) FROM pivotes;
	
	WHILE nivelActual <= cantidadPivotes
	LOOP
		SELECT INTO pivoteActual * FROM pivotes WHERE nivel = nivelActual;
		distanciaAPivote := euclideandistance(NEW.vector, pivoteActual.vector);

		-- Me quedo con el intervalo que contiene a esta distanciaAPivote
		SELECT INTO intervalo * FROM intervalos WHERE nivel = nivelActual AND distanciaAPivote BETWEEN minimo AND maximo;
		
		IF intervalo IS NULL
		THEN
		    RAISE EXCEPTION 'No hay intervalo definido para la distancia % en el nivel %', distanciaAPivote, nivelActual; 
		END IF;

		-- Busco el nodo del árbol que corresponde a este intervalo. 
		SELECT INTO nodoActual indice.* 
		FROM indice 
		WHERE 
			indice.id_padre = nodoAnterior.id 
			AND indice.distancia BETWEEN intervalo.minimo AND intervalo.maximo 
			AND indice.nivel_pivote = nivelActual; -- nivel_pivote significa a qué nivel se corresponde esa distancia. 

		-- Si no existe un nodo para este intervalo en el árbol, se agrega. 
		-- También debo agregarlo si estoy en el último nivel, ya que nodoActual podría no ser null, pero al ser hoja debo agregar este nodo igual.
		IF nodoActual IS NULL OR nivelActual = cantidadPivotes 
		THEN 
			INSERT INTO indice (distancia, id_padre, nivel_pivote) VALUES (distanciaAPivote, nodoAnterior.id, pivoteActual.id)
			RETURNING indice.* INTO nodoActual;

			-- Actualizar intervalos actuales
			IF intervalo.minimo_actual IS NULL OR nodoActual.distancia < intervalo.minimo_actual
			THEN 
				UPDATE intervalos SET minimo_actual = nodoActual.distancia WHERE id = intervalo.id;
			END IF;
			IF intervalo.maximo_actual IS NULL OR nodoActual.distancia > intervalo.maximo_actual
			THEN 
				UPDATE intervalos SET maximo_actual = nodoActual.distancia WHERE id = intervalo.id;
			END IF;
		END IF;
		nivelActual := nivelActual + 1;
		nodoAnterior := nodoActual;
	END LOOP ; 
	
	NEW.id_nodo := nodoActual.id;
	RETURN NEW;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

CREATE TRIGGER actualizar_indice
  BEFORE INSERT OR UPDATE ON public.images
  FOR EACH ROW
  EXECUTE PROCEDURE public.agregar_indice();

