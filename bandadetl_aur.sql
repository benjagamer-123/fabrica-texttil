-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Servidor: 127.0.0.1
-- Tiempo de generación: 16-11-2026 a las 08:27:08
-- Versión del servidor: 10.4.32-MariaDB
-- Versión de PHP: 8.2.12

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Base de datos: `bandadetl`
--

DELIMITER $$
--
-- Procedimientos
--
CREATE DEFINER=`root`@`localhost` PROCEDURE `mostrar` (IN `nombre_tabla` VARCHAR(64))   BEGIN
    SET @sql_query = CONCAT('SELECT * FROM ', nombre_tabla);
    PREPARE stmt FROM @sql_query;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_actualizar_dinamico` (IN `p_nombre_tabla` VARCHAR(64), IN `p_valores_set` TEXT, IN `p_id` INT)   BEGIN
    -- Ejemplo: UPDATE productos SET precio = 1500, stock = 20 WHERE id = 3
    SET @sql_query = CONCAT('UPDATE ', p_nombre_tabla, ' SET ', p_valores_set, ' WHERE id = ?');
    
    PREPARE stmt FROM @sql_query;
    SET @id_param = p_id;
    EXECUTE stmt USING @id_param;
    DEALLOCATE PREPARE stmt;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_eliminar_por_id` (IN `p_nombre_tabla` VARCHAR(64), IN `p_id` INT)   BEGIN
    SET @sql_query = CONCAT('DELETE FROM ', p_nombre_tabla, ' WHERE id = ?');
    
    PREPARE stmt FROM @sql_query;
    SET @id_param = p_id;
    EXECUTE stmt USING @id_param;
    DEALLOCATE PREPARE stmt;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_insertar_dinamico` (IN `p_nombre_tabla` VARCHAR(64), IN `p_columnas` TEXT, IN `p_valores` TEXT)   BEGIN
    -- Ejemplo: INSERT INTO usuarios (nombre, email) VALUES ('Juan', 'juan@email.com')
    SET @sql_query = CONCAT('INSERT INTO ', p_nombre_tabla, ' (', p_columnas, ') VALUES (', p_valores, ')');
    
    PREPARE stmt FROM @sql_query;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_registrar_consumo_mp` (IN `p_id_etapa` INT, IN `p_id_materia_prima` INT, IN `p_cantidad` DECIMAL(12,2), IN `p_lote` VARCHAR(50), IN `p_id_usuario` INT, IN `p_ip_origen` VARCHAR(45))   BEGIN

    DECLARE v_stock DECIMAL(12,2);
    DECLARE v_usuario INT;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET @id_usuario = NULL;
        SET @ip_origen = NULL;
        RESIGNAL;
    END;

    START TRANSACTION;

    IF p_cantidad <= 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Cantidad invalida';
    END IF;

    SELECT COUNT(*)
    INTO v_usuario
    FROM usuarios
    WHERE id_usuario = p_id_usuario;

    IF v_usuario = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Usuario inexistente';
    END IF;

    SELECT stock
    INTO v_stock
    FROM materias_primas
    WHERE id_materia_prima = p_id_materia_prima
    FOR UPDATE;

    IF v_stock IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Materia prima inexistente';
    END IF;

    IF v_stock < p_cantidad THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'No hay suficiente materia prima';
    END IF;

    SET @id_usuario = p_id_usuario;
    SET @ip_origen = p_ip_origen;

    INSERT INTO consumos_materia_prima (
        id_etapa,
        id_materia_prima,
        cantidad_utilizada,
        fecha_consumo,
        lote
    )
    VALUES (
        p_id_etapa,
        p_id_materia_prima,
        p_cantidad,
        NOW(),
        p_lote
    );

    SET @id_usuario = NULL;
    SET @ip_origen = NULL;

    COMMIT;

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_registrar_usuario` (IN `p_nombre` VARCHAR(100), IN `p_email` VARCHAR(100), IN `p_password_hash` VARCHAR(255), IN `p_estado` VARCHAR(50), IN `p_id_rol` INT(2))   BEGIN
    INSERT INTO usuarios (nombre, email, password_hash, estado, id_rol)
    VALUES (p_nombre, p_email, p_password_hash, p_estado, 2);
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `auditorias`
--

CREATE TABLE `auditorias` (
  `id_auditoria` int(11) NOT NULL,
  `id_usuario` int(11) DEFAULT NULL,
  `tabla_affected` varchar(100) DEFAULT NULL,
  `id_registro` int(11) DEFAULT NULL,
  `accion` varchar(50) DEFAULT NULL,
  `fecha_hora` datetime NOT NULL,
  `detalle_anterior` text DEFAULT NULL,
  `detalle_nuevo` text DEFAULT NULL,
  `ip_origen` varchar(45) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `categorias_productos`
--

CREATE TABLE `categorias_productos` (
  `id_categoria` int(11) NOT NULL,
  `nombre` varchar(100) NOT NULL,
  `descripcion` text DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `categorias_productos`
--

INSERT INTO `categorias_productos` (`id_categoria`, `nombre`, `descripcion`) VALUES
(1, 'Fibras Naturales', 'Tejidos confeccionados a partir de fibras de origen vegetal o animal, transpirables y suaves.'),
(2, 'Fibras Sintéticas', 'Tejidos elaborados con fibras artificiales de alta resistencia, elasticidad y durabilidad.'),
(3, 'Tejidos Especiales y Pesados', 'Telas de trama densa, suntuosa o rústica ideales para sastrería, abrigos, trabajo y decoración.');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `clientes`
--

CREATE TABLE `clientes` (
  `id_cliente` int(11) NOT NULL,
  `razon_social` varchar(150) NOT NULL,
  `tipo_cliente` varchar(50) DEFAULT NULL,
  `email` varchar(100) DEFAULT NULL,
  `direccion` varchar(255) DEFAULT NULL,
  `ciudad` varchar(100) DEFAULT NULL,
  `id_pais` int(11) NOT NULL,
  `estado` varchar(50) DEFAULT NULL,
  `cuit` varchar(20) DEFAULT NULL,
  `telefono` varchar(20) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `clientes`
--

INSERT INTO `clientes` (`id_cliente`, `razon_social`, `tipo_cliente`, `email`, `direccion`, `ciudad`, `id_pais`, `estado`, `cuit`, `telefono`) VALUES
(2, 'Juan Pérez S.R.L.', 'Minorista', 'juan@perez.com', 'Calle Falsa 123', 'Rosario', 54, 'Activo', '30-11223344-5', '341-4567890'),
(3, 'Distribuidora Sur', 'Mayorista', 'ventas@distrinorte.com', 'Ruta 9 Km 50', 'Córdoba', 54, 'Inactivo', '30-55667788-9', '351-9876543'),
(4, 'migers', 'Minorista', 'admin@gmail.com', 'asdasdasda', 'dasdasd', 3, 'Activo', '20-22334455-6', '11-23456789'),
(12, 'GOAT', 'Minorista', 'ejemplo@gmail.com', 'ASDASDASD12312312', 'SADASDASD', 3, 'Activo', '27-33445566-7', '11-87654321'),
(14, 'sad', 'Minorista', 'ejemplo1@gmail.com', 'cxvwfecsfd32131', 'asdasdasd', 3, 'Activo', '20-44556677-8', '11-55554444'),
(22, 'Benjamin Fernandez', 'Minorista', 'benja09fer@gmail.com', 'Av. San Martín 1450', 'Buenos Aires', 54, 'Activo', '20-38492015-4', '+54 11 4589-2310'),
(23, 'Benjamin Fernandez', 'Minorista', 'benja09fer@gmail.com', 'Av. San Martín 1450', 'Buenos Aires', 54, 'Activo', '20-38492015-4', '+54 11 4589-2310');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `consumos_materia_prima`
--

CREATE TABLE `consumos_materia_prima` (
  `id_consumo` int(11) NOT NULL,
  `id_etapa` int(11) NOT NULL,
  `id_materia_prima` int(11) NOT NULL,
  `cantidad_utilizada` decimal(12,2) NOT NULL,
  `fecha_consumo` datetime NOT NULL,
  `lote` varchar(50) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Disparadores `consumos_materia_prima`
--
DELIMITER $$
CREATE TRIGGER `tr_auditar_consumo_mp` AFTER INSERT ON `consumos_materia_prima` FOR EACH ROW BEGIN

    INSERT INTO auditorias (
        id_usuario,
        tabla_afectada,
        id_registro,
        accion,
        fecha_hora,
        detalle_anterior,
        detalle_nuevo,
        ip_origen
    )
    VALUES (
        @id_usuario,
        'consumos_materia_prima',
        NEW.id_consumo,
        'INSERT',
        NOW(),
        NULL,
        CONCAT(
            'Materia prima: ', NEW.id_materia_prima,
            ' | Cantidad utilizada: ', NEW.cantidad_utilizada,
            ' | Lote: ', NEW.lote
        ),
        COALESCE(@ip_origen, 'NO_DISPONIBLE')
    );

END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `tr_validar_consumo_mp` BEFORE INSERT ON `consumos_materia_prima` FOR EACH ROW BEGIN
    DECLARE v_stock DECIMAL(12,2);

    IF NEW.cantidad_utilizada <= 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'La cantidad debe ser mayor a cero';
    END IF;

    SELECT stock
    INTO v_stock
    FROM materias_primas
    WHERE id_materia_prima = NEW.id_materia_prima
    FOR UPDATE;

    IF v_stock IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'La materia prima no existe';
    END IF;

    IF v_stock < NEW.cantidad_utilizada THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Stock insuficiente';
    END IF;

    IF @id_usuario IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Debe identificarse el usuario responsable';
    END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `depositos`
--

CREATE TABLE `depositos` (
  `id_deposito` int(11) NOT NULL,
  `nombre` varchar(100) NOT NULL,
  `ubicacion` varchar(255) DEFAULT NULL,
  `descripcion` text DEFAULT NULL,
  `estado` varchar(50) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `despachos`
--

CREATE TABLE `despachos` (
  `id_despacho` int(11) NOT NULL,
  `fecha_despacho` datetime DEFAULT NULL,
  `id_pedido` int(11) NOT NULL,
  `transportista` varchar(100) DEFAULT NULL,
  `estado` varchar(50) DEFAULT NULL,
  `id_rol` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `detalles_despacho`
--

CREATE TABLE `detalles_despacho` (
  `id_detalle_despacho` int(11) NOT NULL,
  `id_despacho` int(11) NOT NULL,
  `id_producto` int(11) NOT NULL,
  `cantidad` decimal(12,2) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `detalles_orden_compra`
--

CREATE TABLE `detalles_orden_compra` (
  `id_detalle_compra` int(11) NOT NULL,
  `id_orden_compra` int(11) NOT NULL,
  `id_materia_prima` int(11) NOT NULL,
  `cantidad` decimal(12,2) NOT NULL,
  `precio_unitario` decimal(12,2) NOT NULL,
  `totalcompra` decimal(12,2) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `detalles_orden_prod`
--

CREATE TABLE `detalles_orden_prod` (
  `id_detalle_orden_prod` int(11) NOT NULL,
  `id_orden_prod` int(11) NOT NULL,
  `id_producto` int(11) NOT NULL,
  `cantidad_plan` decimal(12,2) NOT NULL,
  `tiempo_unitario_est` decimal(10,2) DEFAULT NULL,
  `tiempo_total_est` decimal(10,2) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `detalles_pedido`
--

CREATE TABLE `detalles_pedido` (
  `id_detalle_pedido` int(11) NOT NULL,
  `id_pedido` int(11) NOT NULL,
  `id_producto` int(11) NOT NULL,
  `cantidad` decimal(12,2) NOT NULL,
  `precio_unitario` decimal(12,2) NOT NULL,
  `descuento` decimal(5,2) DEFAULT 0.00,
  `subtotal` decimal(12,2) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `detalles_pedido`
--

INSERT INTO `detalles_pedido` (`id_detalle_pedido`, `id_pedido`, `id_producto`, `cantidad`, `precio_unitario`, `descuento`, `subtotal`) VALUES
(1, 1, 2, 1.00, 15000.00, 0.00, 15000.00),
(2, 2, 2, 1.00, 15000.00, 0.00, 15000.00),
(3, 2, 4, 1.00, 24000.00, 0.00, 24000.00),
(4, 3, 1, 1.00, 12500.00, 0.00, 12500.00);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `etapas_produccion`
--

CREATE TABLE `etapas_produccion` (
  `id_etapa` int(11) NOT NULL,
  `id_orden_prod` int(11) NOT NULL,
  `nombre_etapa` varchar(100) NOT NULL,
  `orden_secuencia` int(11) NOT NULL,
  `estado` varchar(50) DEFAULT NULL,
  `fecha_inicio_real` datetime DEFAULT NULL,
  `fecha_fin_real` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `inventarios`
--

CREATE TABLE `inventarios` (
  `id_inventario` int(11) NOT NULL,
  `id_producto` int(11) NOT NULL,
  `id_deposito` int(11) NOT NULL,
  `lote` varchar(50) DEFAULT NULL,
  `cantidad_disponible` decimal(12,2) NOT NULL,
  `unidad_medida` varchar(20) DEFAULT NULL,
  `fecha_actualizacion` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `lotes`
--

CREATE TABLE `lotes` (
  `id_lote` int(11) NOT NULL,
  `id_producto` int(11) NOT NULL,
  `numero_lote` varchar(50) NOT NULL,
  `fecha_fabricacion` date DEFAULT NULL,
  `cantidad_inicial` decimal(12,3) NOT NULL,
  `cantidad_disponible` decimal(12,3) NOT NULL,
  `estado` varchar(20) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `materias_primas`
--

CREATE TABLE `materias_primas` (
  `id_materia_prima` int(11) NOT NULL,
  `codigo` varchar(50) NOT NULL,
  `nombre` varchar(100) NOT NULL,
  `tipo` varchar(50) DEFAULT NULL,
  `unidad_medida` varchar(20) DEFAULT NULL,
  `stock_minimo` decimal(12,2) DEFAULT NULL,
  `estado` varchar(50) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `materias_primas`
--

INSERT INTO `materias_primas` (`id_materia_prima`, `codigo`, `nombre`, `tipo`, `unidad_medida`, `stock_minimo`, `estado`) VALUES
(1, 'MP-HIL-01', 'Hilado de Algodón Peinado 30/1', 'Hilado Natural', 'Kilogramos', 122.00, 'Activo'),
(2, 'MP-HIL-02', 'Hilado de Lino Crudo', 'Hilado Natural', 'Kilogramos', NULL, 'Activo'),
(3, 'MP-HIL-03', 'Vellón e Hilo de Lana Merino', 'Hilado Natural', 'Kilogramos', NULL, 'Activo'),
(4, 'MP-HIL-04', 'Filamento de Poliéster Texturizado', 'Hilado Sintético', 'Kilogramos', NULL, 'Activo'),
(5, 'MP-TIN-01', 'Tintura Reactiva Azul Índigo', 'Químico / Tintura', 'Litros', NULL, 'Activo'),
(6, 'MP-QUI-01', 'Apresto Suavizante y Antiarrugas', 'Químico / Acabado', 'Litros', NULL, 'Activo');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `ordenes_compra`
--

CREATE TABLE `ordenes_compra` (
  `id_orden_compra` int(11) NOT NULL,
  `fecha_orden` datetime NOT NULL,
  `estado` varchar(50) DEFAULT NULL,
  `id_proveedor` int(11) NOT NULL,
  `total_estimado` decimal(12,2) DEFAULT NULL,
  `precio` decimal(12,2) DEFAULT NULL,
  `cantidad` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `ordenes_produccion`
--

CREATE TABLE `ordenes_produccion` (
  `id_orden_prod` int(11) NOT NULL,
  `numero_orden` varchar(50) NOT NULL,
  `fecha_inicio_est` date DEFAULT NULL,
  `fecha_fin_est` date DEFAULT NULL,
  `estado` varchar(50) DEFAULT NULL,
  `id_responsable` int(11) DEFAULT NULL,
  `observaciones` text DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `paises`
--

CREATE TABLE `paises` (
  `id_pais` int(11) NOT NULL,
  `nombre` varchar(100) NOT NULL,
  `codigo_iso` varchar(3) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `paises`
--

INSERT INTO `paises` (`id_pais`, `nombre`, `codigo_iso`) VALUES
(2, 'Brasil', 'BRA'),
(3, 'Chile', 'CHI'),
(54, 'Argentina', '1'),
(55, 'Uruguay', 'UY'),
(56, 'China', 'CN'),
(57, 'Estados Unidos', 'US');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `pedidos`
--

CREATE TABLE `pedidos` (
  `id_pedido` int(11) NOT NULL,
  `id_cliente` int(11) NOT NULL,
  `fecha_pedido` datetime NOT NULL,
  `estado` varchar(50) DEFAULT NULL,
  `fecha_entrega_req` date DEFAULT NULL,
  `observaciones` text DEFAULT NULL,
  `total_estimado` decimal(12,2) DEFAULT NULL,
  `id_producto` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `pedidos`
--

INSERT INTO `pedidos` (`id_pedido`, `id_cliente`, `fecha_pedido`, `estado`, `fecha_entrega_req`, `observaciones`, `total_estimado`, `id_producto`) VALUES
(1, 4, '2026-11-16 02:21:55', 'Pendiente', '2026-11-23', 'Envío a asdasdasda asdasdasd, dasdasd asdasdasdasd, Chile. Costo de envío: $24125', 42275.00, 2),
(2, 12, '2026-11-16 03:03:15', 'Pendiente', '2026-11-23', 'Envío a ASDASDASD12312312 ASDASDASD23131, SADASDASD 2331, Chile. Costo de envío: $9750', 56940.00, 2),
(3, 14, '2026-11-16 03:06:45', 'Pendiente', '2026-11-23', 'Envío a cxvwfecsfd32131 sadsczxcs234123, asdasdasd 1234, Chile. Costo de envío: $3125', 18250.00, 1);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `permisos`
--

CREATE TABLE `permisos` (
  `id_permisos` int(11) NOT NULL,
  `nombre` varchar(100) NOT NULL,
  `descripcion` varchar(255) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `productos`
--

CREATE TABLE `productos` (
  `id_producto` int(11) NOT NULL,
  `codigo` varchar(50) NOT NULL,
  `nombre` varchar(100) NOT NULL,
  `descripcion` text DEFAULT NULL,
  `unidad_medida` varchar(20) DEFAULT NULL,
  `tipo` varchar(50) DEFAULT NULL,
  `id_categoria` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `productos`
--

INSERT INTO `productos` (`id_producto`, `codigo`, `nombre`, `descripcion`, `unidad_medida`, `tipo`, `id_categoria`) VALUES
(1, 'TEL-001', 'Algodón', 'Suave, transpirable y versátil. Ideal para prendas de uso diario.', '1', 'Tela Terminada', 1),
(2, 'TEL-002', 'Lino', 'Fresco y ligero, perfecto para indumentaria de verano y alta costura.', '1', 'Tela Terminada', 1),
(3, 'TEL-003', 'Lana', 'Excelente aislante térmico, ideal para abrigos y sacos de invierno.', '1', 'Tela Terminada', 1),
(4, 'TEL-004', 'Seda', 'Textura suave y brillante, referente de elegancia y sofisticación.', '1', 'Tela Terminada', 1),
(5, 'TEL-005', 'Jean (Denim)', 'Resistente y duradero, el estándar para pantalones y camperas.', '1', 'Tela Terminada', 3),
(6, 'TEL-006', 'Terciopelo', 'Tejido de tacto suntuoso y elegante apariencia sobria.', '1', 'Tela Terminada', 3),
(7, 'TEL-007', 'Nailon', 'Fibra sintética elástica y de alta resistencia al desgaste.', '1', 'Tela Terminada', 2),
(8, 'TEL-008', 'Poliéster', 'Económico, liviano y resistente a las arrugas y la humedad.', '1', 'Tela Terminada', 2),
(9, 'TEL-009', 'Tela de Jaba', 'Material rústico y resistente, ideal para sacos y decoración.', '1', 'Tela Terminada', 3),
(10, 'TEL-010', 'Gabardina', 'Tejido apretado y firme, idóneo para pilotos y pantalones de trabajo.', '1', 'Tela Terminada', 3);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `proveedores`
--

CREATE TABLE `proveedores` (
  `id_proveedor` int(11) NOT NULL,
  `razon_social` varchar(150) NOT NULL,
  `cuit` varchar(20) NOT NULL,
  `contacto` varchar(100) DEFAULT NULL,
  `email` varchar(100) DEFAULT NULL,
  `telefono` varchar(50) DEFAULT NULL,
  `direccion` varchar(255) DEFAULT NULL,
  `id_pais` int(11) NOT NULL,
  `estado` varchar(50) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `proveedores`
--

INSERT INTO `proveedores` (`id_proveedor`, `razon_social`, `cuit`, `contacto`, `email`, `telefono`, `direccion`, `id_pais`, `estado`) VALUES
(1, '', '30-71458923-4', 'Hilandería del Norte S.A. (Carlos Méndez)', 'ventas@hilanderiadelnorte.com.ar', '+54 11 4755-8810', 'Av. San Martín 4520, Villa Maipú, Buenos Aires', 54, NULL),
(2, '', '30-68941250-9', 'Química Textil Sur (Laura Gómez)', 'pedidos@quimicatextilsur.com.ar', '+54 11 4208-3390', 'Calle Industria 1280, Avellaneda, Buenos Aires', 54, NULL),
(3, '', '12.345.678/0001-90', 'Fibras & Fios Brasil Ltda (Roberto Silva)', 'export@fibrasbrasil.com.br', '+55 11 3254-9900', 'Rua das Indústrias 890, São Paulo', 2, NULL);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `redrelacion`
--

CREATE TABLE `redrelacion` (
  `id_red` int(11) NOT NULL,
  `id_rol_padre` int(11) NOT NULL,
  `id_rol_hijo` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `redrolpermiso`
--

CREATE TABLE `redrolpermiso` (
  `id` int(11) NOT NULL,
  `id_rol` int(11) NOT NULL,
  `id_permiso` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `roles`
--

CREATE TABLE `roles` (
  `id_rol` int(11) NOT NULL,
  `nombre` varchar(50) NOT NULL,
  `descripcion` varchar(255) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `roles`
--

INSERT INTO `roles` (`id_rol`, `nombre`, `descripcion`) VALUES
(1, 'Admin', 'Administrador con acceso total a la gestión de la fábrica textil, catálogo, producción y pedidos.'),
(2, 'Cliente', 'Usuario registrado en la tienda web para explorar el catálogo de telas y realizar pedidos.');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `usuarios`
--

CREATE TABLE `usuarios` (
  `id_usuario` int(11) NOT NULL,
  `nombre` varchar(100) NOT NULL,
  `email` varchar(100) NOT NULL,
  `password_hash` varchar(255) NOT NULL,
  `estado` varchar(50) DEFAULT NULL,
  `id_rol` int(11) DEFAULT 2
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `usuarios`
--

INSERT INTO `usuarios` (`id_usuario`, `nombre`, `email`, `password_hash`, `estado`, `id_rol`) VALUES
(1, 'juan peres', 'nif@gmail.com', '123123', 'activo', 2),
(2, 'Benjamin Fernandez', 'benja09fer@gmail.com', '123123', 'Activo', 2),
(3, 'pepito', 'ben@gmail.com', '123123', 'Activo', 2),
(15, 'GOAT', 'ejemplo@gmail.com', '123123', 'Activo', 1);

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `vw_estado_pedidos`
-- (Véase abajo para la vista actual)
--
CREATE TABLE `vw_estado_pedidos` (
`id_pedido` int(11)
,`cliente` varchar(20)
,`tipo_cliente` varchar(50)
,`fecha_pedido` datetime
,`estado_pedido` varchar(50)
,`fecha_entrega_req` date
,`total_estimado` decimal(12,2)
,`cantidad_productos` bigint(21)
,`unidades_totales` decimal(34,2)
,`cantidad_despachos` bigint(21)
,`ultimo_despacho` datetime
);

-- --------------------------------------------------------

--
-- Estructura para la vista `vw_estado_pedidos`
--
DROP TABLE IF EXISTS `vw_estado_pedidos`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vw_estado_pedidos`  AS SELECT `p`.`id_pedido` AS `id_pedido`, `c`.`cuit` AS `cliente`, `c`.`tipo_cliente` AS `tipo_cliente`, `p`.`fecha_pedido` AS `fecha_pedido`, `p`.`estado` AS `estado_pedido`, `p`.`fecha_entrega_req` AS `fecha_entrega_req`, `p`.`total_estimado` AS `total_estimado`, coalesce(`d`.`cantidad_productos`,0) AS `cantidad_productos`, coalesce(`d`.`unidades_totales`,0) AS `unidades_totales`, coalesce(`x`.`cantidad_despachos`,0) AS `cantidad_despachos`, `x`.`ultimo_despacho` AS `ultimo_despacho` FROM (((`pedidos` `p` join `clientes` `c` on(`p`.`id_cliente` = `c`.`id_cliente`)) left join (select `detalles_pedido`.`id_pedido` AS `id_pedido`,count(0) AS `cantidad_productos`,sum(`detalles_pedido`.`cantidad`) AS `unidades_totales` from `detalles_pedido` group by `detalles_pedido`.`id_pedido`) `d` on(`p`.`id_pedido` = `d`.`id_pedido`)) left join (select `despachos`.`id_pedido` AS `id_pedido`,count(0) AS `cantidad_despachos`,max(`despachos`.`fecha_despacho`) AS `ultimo_despacho` from `despachos` group by `despachos`.`id_pedido`) `x` on(`p`.`id_pedido` = `x`.`id_pedido`)) ;

--
-- Índices para tablas volcadas
--

--
-- Indices de la tabla `auditorias`
--
ALTER TABLE `auditorias`
  ADD PRIMARY KEY (`id_auditoria`),
  ADD KEY `id_usuario` (`id_usuario`);

--
-- Indices de la tabla `categorias_productos`
--
ALTER TABLE `categorias_productos`
  ADD PRIMARY KEY (`id_categoria`);

--
-- Indices de la tabla `clientes`
--
ALTER TABLE `clientes`
  ADD PRIMARY KEY (`id_cliente`),
  ADD KEY `id_pais` (`id_pais`);

--
-- Indices de la tabla `consumos_materia_prima`
--
ALTER TABLE `consumos_materia_prima`
  ADD PRIMARY KEY (`id_consumo`),
  ADD KEY `id_etapa` (`id_etapa`),
  ADD KEY `id_materia_prima` (`id_materia_prima`);

--
-- Indices de la tabla `depositos`
--
ALTER TABLE `depositos`
  ADD PRIMARY KEY (`id_deposito`);

--
-- Indices de la tabla `despachos`
--
ALTER TABLE `despachos`
  ADD PRIMARY KEY (`id_despacho`),
  ADD KEY `id_pedido` (`id_pedido`),
  ADD KEY `id_rol` (`id_rol`);

--
-- Indices de la tabla `detalles_despacho`
--
ALTER TABLE `detalles_despacho`
  ADD PRIMARY KEY (`id_detalle_despacho`),
  ADD KEY `id_despacho` (`id_despacho`),
  ADD KEY `id_producto` (`id_producto`);

--
-- Indices de la tabla `detalles_orden_compra`
--
ALTER TABLE `detalles_orden_compra`
  ADD PRIMARY KEY (`id_detalle_compra`),
  ADD KEY `id_materia_prima` (`id_materia_prima`),
  ADD KEY `id_orden_compra` (`id_orden_compra`);

--
-- Indices de la tabla `detalles_orden_prod`
--
ALTER TABLE `detalles_orden_prod`
  ADD PRIMARY KEY (`id_detalle_orden_prod`),
  ADD KEY `id_orden_prod` (`id_orden_prod`),
  ADD KEY `id_producto` (`id_producto`);

--
-- Indices de la tabla `detalles_pedido`
--
ALTER TABLE `detalles_pedido`
  ADD PRIMARY KEY (`id_detalle_pedido`),
  ADD KEY `id_pedido` (`id_pedido`),
  ADD KEY `id_producto` (`id_producto`);

--
-- Indices de la tabla `etapas_produccion`
--
ALTER TABLE `etapas_produccion`
  ADD PRIMARY KEY (`id_etapa`),
  ADD KEY `id_orden_prod` (`id_orden_prod`);

--
-- Indices de la tabla `inventarios`
--
ALTER TABLE `inventarios`
  ADD PRIMARY KEY (`id_inventario`),
  ADD KEY `id_deposito` (`id_deposito`),
  ADD KEY `id_producto` (`id_producto`);

--
-- Indices de la tabla `lotes`
--
ALTER TABLE `lotes`
  ADD PRIMARY KEY (`id_lote`),
  ADD KEY `id_producto` (`id_producto`);

--
-- Indices de la tabla `materias_primas`
--
ALTER TABLE `materias_primas`
  ADD PRIMARY KEY (`id_materia_prima`),
  ADD UNIQUE KEY `AK_codigo_mp` (`codigo`);

--
-- Indices de la tabla `ordenes_compra`
--
ALTER TABLE `ordenes_compra`
  ADD PRIMARY KEY (`id_orden_compra`),
  ADD KEY `id_proveedor` (`id_proveedor`);

--
-- Indices de la tabla `ordenes_produccion`
--
ALTER TABLE `ordenes_produccion`
  ADD PRIMARY KEY (`id_orden_prod`),
  ADD UNIQUE KEY `AK_numero_orden_prod` (`numero_orden`),
  ADD KEY `id_responsable` (`id_responsable`);

--
-- Indices de la tabla `paises`
--
ALTER TABLE `paises`
  ADD PRIMARY KEY (`id_pais`),
  ADD UNIQUE KEY `AK_codigo_iso` (`codigo_iso`);

--
-- Indices de la tabla `pedidos`
--
ALTER TABLE `pedidos`
  ADD PRIMARY KEY (`id_pedido`),
  ADD KEY `id_cliente` (`id_cliente`),
  ADD KEY `id_producto` (`id_producto`);

--
-- Indices de la tabla `permisos`
--
ALTER TABLE `permisos`
  ADD PRIMARY KEY (`id_permisos`);

--
-- Indices de la tabla `productos`
--
ALTER TABLE `productos`
  ADD PRIMARY KEY (`id_producto`),
  ADD UNIQUE KEY `AK_codigo_producto` (`codigo`),
  ADD KEY `id_categoria` (`id_categoria`);

--
-- Indices de la tabla `proveedores`
--
ALTER TABLE `proveedores`
  ADD PRIMARY KEY (`id_proveedor`),
  ADD UNIQUE KEY `AK_cuit_proveedor` (`cuit`),
  ADD KEY `id_pais` (`id_pais`);

--
-- Indices de la tabla `redrelacion`
--
ALTER TABLE `redrelacion`
  ADD PRIMARY KEY (`id_red`),
  ADD KEY `id_rol_hijo` (`id_rol_hijo`),
  ADD KEY `id_rol_padre` (`id_rol_padre`);

--
-- Indices de la tabla `redrolpermiso`
--
ALTER TABLE `redrolpermiso`
  ADD PRIMARY KEY (`id`),
  ADD KEY `id_permiso` (`id_permiso`),
  ADD KEY `id_rol` (`id_rol`);

--
-- Indices de la tabla `roles`
--
ALTER TABLE `roles`
  ADD PRIMARY KEY (`id_rol`),
  ADD UNIQUE KEY `AK_nombre_rol` (`nombre`);

--
-- Indices de la tabla `usuarios`
--
ALTER TABLE `usuarios`
  ADD PRIMARY KEY (`id_usuario`),
  ADD UNIQUE KEY `AK_email` (`email`),
  ADD KEY `id_rol` (`id_rol`);

--
-- AUTO_INCREMENT de las tablas volcadas
--

--
-- AUTO_INCREMENT de la tabla `auditorias`
--
ALTER TABLE `auditorias`
  MODIFY `id_auditoria` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `categorias_productos`
--
ALTER TABLE `categorias_productos`
  MODIFY `id_categoria` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT de la tabla `clientes`
--
ALTER TABLE `clientes`
  MODIFY `id_cliente` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=24;

--
-- AUTO_INCREMENT de la tabla `consumos_materia_prima`
--
ALTER TABLE `consumos_materia_prima`
  MODIFY `id_consumo` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `depositos`
--
ALTER TABLE `depositos`
  MODIFY `id_deposito` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `despachos`
--
ALTER TABLE `despachos`
  MODIFY `id_despacho` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `detalles_despacho`
--
ALTER TABLE `detalles_despacho`
  MODIFY `id_detalle_despacho` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `detalles_orden_compra`
--
ALTER TABLE `detalles_orden_compra`
  MODIFY `id_detalle_compra` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `detalles_orden_prod`
--
ALTER TABLE `detalles_orden_prod`
  MODIFY `id_detalle_orden_prod` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `detalles_pedido`
--
ALTER TABLE `detalles_pedido`
  MODIFY `id_detalle_pedido` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT de la tabla `etapas_produccion`
--
ALTER TABLE `etapas_produccion`
  MODIFY `id_etapa` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `inventarios`
--
ALTER TABLE `inventarios`
  MODIFY `id_inventario` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `lotes`
--
ALTER TABLE `lotes`
  MODIFY `id_lote` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `materias_primas`
--
ALTER TABLE `materias_primas`
  MODIFY `id_materia_prima` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- AUTO_INCREMENT de la tabla `ordenes_compra`
--
ALTER TABLE `ordenes_compra`
  MODIFY `id_orden_compra` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `ordenes_produccion`
--
ALTER TABLE `ordenes_produccion`
  MODIFY `id_orden_prod` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `paises`
--
ALTER TABLE `paises`
  MODIFY `id_pais` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=58;

--
-- AUTO_INCREMENT de la tabla `pedidos`
--
ALTER TABLE `pedidos`
  MODIFY `id_pedido` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT de la tabla `permisos`
--
ALTER TABLE `permisos`
  MODIFY `id_permisos` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `productos`
--
ALTER TABLE `productos`
  MODIFY `id_producto` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=11;

--
-- AUTO_INCREMENT de la tabla `proveedores`
--
ALTER TABLE `proveedores`
  MODIFY `id_proveedor` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT de la tabla `redrelacion`
--
ALTER TABLE `redrelacion`
  MODIFY `id_red` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `redrolpermiso`
--
ALTER TABLE `redrolpermiso`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `roles`
--
ALTER TABLE `roles`
  MODIFY `id_rol` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT de la tabla `usuarios`
--
ALTER TABLE `usuarios`
  MODIFY `id_usuario` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=24;

--
-- Restricciones para tablas volcadas
--

--
-- Filtros para la tabla `auditorias`
--
ALTER TABLE `auditorias`
  ADD CONSTRAINT `auditorias_ibfk_1` FOREIGN KEY (`id_usuario`) REFERENCES `usuarios` (`id_usuario`);

--
-- Filtros para la tabla `clientes`
--
ALTER TABLE `clientes`
  ADD CONSTRAINT `clientes_ibfk_1` FOREIGN KEY (`id_pais`) REFERENCES `paises` (`id_pais`);

--
-- Filtros para la tabla `consumos_materia_prima`
--
ALTER TABLE `consumos_materia_prima`
  ADD CONSTRAINT `consumos_materia_prima_ibfk_1` FOREIGN KEY (`id_etapa`) REFERENCES `etapas_produccion` (`id_etapa`),
  ADD CONSTRAINT `consumos_materia_prima_ibfk_2` FOREIGN KEY (`id_materia_prima`) REFERENCES `materias_primas` (`id_materia_prima`);

--
-- Filtros para la tabla `despachos`
--
ALTER TABLE `despachos`
  ADD CONSTRAINT `despachos_ibfk_1` FOREIGN KEY (`id_pedido`) REFERENCES `pedidos` (`id_pedido`),
  ADD CONSTRAINT `despachos_ibfk_2` FOREIGN KEY (`id_rol`) REFERENCES `roles` (`id_rol`);

--
-- Filtros para la tabla `detalles_despacho`
--
ALTER TABLE `detalles_despacho`
  ADD CONSTRAINT `detalles_despacho_ibfk_1` FOREIGN KEY (`id_despacho`) REFERENCES `despachos` (`id_despacho`),
  ADD CONSTRAINT `detalles_despacho_ibfk_2` FOREIGN KEY (`id_producto`) REFERENCES `productos` (`id_producto`);

--
-- Filtros para la tabla `detalles_orden_compra`
--
ALTER TABLE `detalles_orden_compra`
  ADD CONSTRAINT `detalles_orden_compra_ibfk_1` FOREIGN KEY (`id_materia_prima`) REFERENCES `materias_primas` (`id_materia_prima`),
  ADD CONSTRAINT `detalles_orden_compra_ibfk_2` FOREIGN KEY (`id_orden_compra`) REFERENCES `ordenes_compra` (`id_orden_compra`);

--
-- Filtros para la tabla `detalles_orden_prod`
--
ALTER TABLE `detalles_orden_prod`
  ADD CONSTRAINT `detalles_orden_prod_ibfk_1` FOREIGN KEY (`id_orden_prod`) REFERENCES `ordenes_produccion` (`id_orden_prod`),
  ADD CONSTRAINT `detalles_orden_prod_ibfk_2` FOREIGN KEY (`id_producto`) REFERENCES `productos` (`id_producto`);

--
-- Filtros para la tabla `detalles_pedido`
--
ALTER TABLE `detalles_pedido`
  ADD CONSTRAINT `detalles_pedido_ibfk_1` FOREIGN KEY (`id_pedido`) REFERENCES `pedidos` (`id_pedido`),
  ADD CONSTRAINT `detalles_pedido_ibfk_2` FOREIGN KEY (`id_producto`) REFERENCES `productos` (`id_producto`);

--
-- Filtros para la tabla `etapas_produccion`
--
ALTER TABLE `etapas_produccion`
  ADD CONSTRAINT `etapas_produccion_ibfk_1` FOREIGN KEY (`id_orden_prod`) REFERENCES `ordenes_produccion` (`id_orden_prod`);

--
-- Filtros para la tabla `inventarios`
--
ALTER TABLE `inventarios`
  ADD CONSTRAINT `inventarios_ibfk_1` FOREIGN KEY (`id_deposito`) REFERENCES `depositos` (`id_deposito`),
  ADD CONSTRAINT `inventarios_ibfk_2` FOREIGN KEY (`id_producto`) REFERENCES `productos` (`id_producto`);

--
-- Filtros para la tabla `lotes`
--
ALTER TABLE `lotes`
  ADD CONSTRAINT `lotes_ibfk_1` FOREIGN KEY (`id_producto`) REFERENCES `productos` (`id_producto`);

--
-- Filtros para la tabla `ordenes_compra`
--
ALTER TABLE `ordenes_compra`
  ADD CONSTRAINT `ordenes_compra_ibfk_1` FOREIGN KEY (`id_proveedor`) REFERENCES `proveedores` (`id_proveedor`);

--
-- Filtros para la tabla `ordenes_produccion`
--
ALTER TABLE `ordenes_produccion`
  ADD CONSTRAINT `ordenes_produccion_ibfk_1` FOREIGN KEY (`id_responsable`) REFERENCES `usuarios` (`id_usuario`);

--
-- Filtros para la tabla `pedidos`
--
ALTER TABLE `pedidos`
  ADD CONSTRAINT `pedidos_ibfk_1` FOREIGN KEY (`id_cliente`) REFERENCES `clientes` (`id_cliente`),
  ADD CONSTRAINT `pedidos_ibfk_2` FOREIGN KEY (`id_producto`) REFERENCES `productos` (`id_producto`);

--
-- Filtros para la tabla `productos`
--
ALTER TABLE `productos`
  ADD CONSTRAINT `productos_ibfk_1` FOREIGN KEY (`id_categoria`) REFERENCES `categorias_productos` (`id_categoria`);

--
-- Filtros para la tabla `proveedores`
--
ALTER TABLE `proveedores`
  ADD CONSTRAINT `proveedores_ibfk_1` FOREIGN KEY (`id_pais`) REFERENCES `paises` (`id_pais`);

--
-- Filtros para la tabla `redrelacion`
--
ALTER TABLE `redrelacion`
  ADD CONSTRAINT `redrelacion_ibfk_1` FOREIGN KEY (`id_rol_hijo`) REFERENCES `roles` (`id_rol`),
  ADD CONSTRAINT `redrelacion_ibfk_2` FOREIGN KEY (`id_rol_padre`) REFERENCES `roles` (`id_rol`);

--
-- Filtros para la tabla `redrolpermiso`
--
ALTER TABLE `redrolpermiso`
  ADD CONSTRAINT `redrolpermiso_ibfk_1` FOREIGN KEY (`id_permiso`) REFERENCES `permisos` (`id_permisos`),
  ADD CONSTRAINT `redrolpermiso_ibfk_2` FOREIGN KEY (`id_rol`) REFERENCES `roles` (`id_rol`);

--
-- Filtros para la tabla `usuarios`
--
ALTER TABLE `usuarios`
  ADD CONSTRAINT `usuarios_ibfk_1` FOREIGN KEY (`id_rol`) REFERENCES `roles` (`id_rol`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
