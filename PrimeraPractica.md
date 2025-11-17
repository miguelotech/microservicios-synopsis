# Práctica Integral: Sistema de Gestión de Pedidos con Microservicios

## Objetivo
Desarrollar un sistema de gestión de pedidos completo utilizando arquitectura de microservicios, implementando las tecnologías y conceptos solicitados.

## Duración Estimada: 16 horas

---

## Descripción del Sistema

Desarrollarás un sistema con 3 microservicios:

1. **ms-productos** (Gradle + Procedimientos Almacenados)
2. **ms-pedidos** (Maven + CRUD Básico)
3. **ms-config-server** (Servidor de Configuración Centralizada)

---

## Parte 1: ms-config-server (2 horas)

### Objetivos
- Crear servidor de configuración centralizada
- Configurar repositorio Git para las configuraciones
- Definir perfiles dev, qa, prd

### Tareas

**1.1 Crear el proyecto Spring Boot**
- Inicializar con Spring Initializr
- Dependencias: Config Server, Actuator
- Configurar `@EnableConfigServer`

**1.2 Crear repositorio Git de configuraciones**
```
config-repo/
├── ms-productos-dev.yml
├── ms-productos-qa.yml
├── ms-productos-prd.yml
├── ms-pedidos-dev.yml
├── ms-pedidos-qa.yml
└── ms-pedidos-prd.yml
```

**1.3 Configurar application.yml**
```yaml
server:
  port: 8888
spring:
  cloud:
    config:
      server:
        git:
          uri: file://${user.home}/config-repo
          default-label: main
```

**Entregables:**
- Config server funcionando en puerto 8888
- Repositorio Git con archivos de configuración
- Verificación: `http://localhost:8888/ms-productos/dev`

---

## Parte 2: ms-productos con Gradle (6 horas)

### Objetivos
- Crear microservicio con Gradle
- Implementar JPA con PostgreSQL
- Crear y usar procedimientos almacenados
- Configurar perfiles (dev, qa, prd)
- Integrar con Config Server

### Tareas

**2.1 Crear base de datos PostgreSQL**
```sql
CREATE DATABASE db_productos_dev;
CREATE DATABASE db_productos_qa;
CREATE DATABASE db_productos_prd;
```

**2.2 Crear proyecto Spring Boot con Gradle**
```groovy
dependencies {
    implementation 'org.springframework.boot:spring-boot-starter-data-jpa'
    implementation 'org.springframework.boot:spring-boot-starter-web'
    implementation 'org.springframework.cloud:spring-cloud-starter-config'
    implementation 'org.springframework.boot:spring-boot-starter-actuator'
    runtimeOnly 'org.postgresql:postgresql'
    compileOnly 'org.projectlombok:lombok'
    annotationProcessor 'org.projectlombok:lombok'
}
```

**2.3 Crear entidad Producto**
```java
@Entity
@Table(name = "productos")
public class Producto {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    private String nombre;
    private String descripcion;
    private Double precio;
    private Integer stock;
    private Boolean activo;
    private LocalDateTime fechaCreacion;
}
```

**2.4 Crear procedimientos almacenados en PostgreSQL**
```sql
-- Procedimiento para actualizar stock
CREATE OR REPLACE FUNCTION actualizar_stock(
    p_producto_id BIGINT,
    p_cantidad INTEGER
) RETURNS VOID AS $$
BEGIN
    UPDATE productos 
    SET stock = stock - p_cantidad
    WHERE id = p_producto_id;
END;
$$ LANGUAGE plpgsql;

-- Procedimiento para obtener productos con bajo stock
CREATE OR REPLACE FUNCTION productos_bajo_stock(
    p_minimo INTEGER
) RETURNS TABLE(
    id BIGINT,
    nombre VARCHAR,
    stock INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT p.id, p.nombre, p.stock
    FROM productos p
    WHERE p.stock < p_minimo AND p.activo = true;
END;
$$ LANGUAGE plpgsql;
```

**2.5 Crear Repository con llamadas a procedimientos**
```java
@Repository
public interface ProductoRepository extends JpaRepository<Producto, Long> {
    
    @Procedure(name = "actualizar_stock")
    void actualizarStock(Long productoId, Integer cantidad);
    
    @Query(value = "SELECT * FROM productos_bajo_stock(:minimo)", nativeQuery = true)
    List<Object[]> obtenerProductosBajoStock(Integer minimo);
}
```

**2.6 Implementar Service y Controller**
- Service: Lógica de negocio
- Controller: Endpoints REST
  - GET /api/productos
  - GET /api/productos/{id}
  - POST /api/productos
  - PUT /api/productos/{id}
  - DELETE /api/productos/{id}
  - PUT /api/productos/{id}/stock
  - GET /api/productos/bajo-stock

**2.7 Configurar perfiles**

*bootstrap.yml*
```yaml
spring:
  application:
    name: ms-productos
  cloud:
    config:
      uri: http://localhost:8888
  profiles:
    active: dev
```

*Configuraciones en config-repo (ms-productos-dev.yml):*
```yaml
server:
  port: 8081
spring:
  datasource:
    url: jdbc:postgresql://localhost:5432/db_productos_dev
    username: postgres
    password: admin
  jpa:
    hibernate:
      ddl-auto: update
    show-sql: true
logging:
  level:
    root: INFO
```

**Entregables:**
- API REST completa de productos
- Procedimientos almacenados funcionando
- Perfiles dev, qa, prd configurados
- Integración con Config Server

---

## Parte 3: ms-pedidos con Maven (5 horas)

### Objetivos
- Crear microservicio con Maven
- Implementar CRUD básico
- Comunicarse con ms-productos
- Integrar con Config Server

### Tareas

**3.1 Crear base de datos**
```sql
CREATE DATABASE db_pedidos_dev;
CREATE DATABASE db_pedidos_qa;
CREATE DATABASE db_pedidos_prd;
```

**3.2 Crear proyecto Spring Boot con Maven**
```xml
<dependencies>
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-data-jpa</artifactId>
    </dependency>
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-web</artifactId>
    </dependency>
    <dependency>
        <groupId>org.springframework.cloud</groupId>
        <artifactId>spring-cloud-starter-config</artifactId>
    </dependency>
    <dependency>
        <groupId>org.springframework.cloud</groupId>
        <artifactId>spring-cloud-starter-openfeign</artifactId>
    </dependency>
    <dependency>
        <groupId>org.postgresql</groupId>
        <artifactId>postgresql</artifactId>
    </dependency>
</dependencies>
```

**3.3 Crear entidades**
```java
@Entity
@Table(name = "pedidos")
public class Pedido {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    private String cliente;
    private LocalDateTime fecha;
    private Double total;
    private String estado; // PENDIENTE, PROCESADO, CANCELADO
    
    @OneToMany(mappedBy = "pedido", cascade = CascadeType.ALL)
    private List<DetallePedido> detalles;
}

@Entity
@Table(name = "detalle_pedidos")
public class DetallePedido {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    
    @ManyToOne
    @JoinColumn(name = "pedido_id")
    private Pedido pedido;
    
    private Long productoId;
    private Integer cantidad;
    private Double precioUnitario;
}
```

**3.4 Implementar comunicación con ms-productos usando Feign**
```java
@FeignClient(name = "ms-productos", url = "${ms-productos.url}")
public interface ProductoClient {
    
    @GetMapping("/api/productos/{id}")
    ProductoDTO obtenerProducto(@PathVariable Long id);
    
    @PutMapping("/api/productos/{id}/stock")
    void actualizarStock(@PathVariable Long id, @RequestParam Integer cantidad);
}
```

**3.5 Implementar Service con lógica de negocio**
- Validar disponibilidad de productos
- Calcular totales
- Actualizar stock de productos
- Crear, leer, actualizar, eliminar pedidos

**3.6 Crear Controller**
Endpoints:
- POST /api/pedidos (crear pedido)
- GET /api/pedidos
- GET /api/pedidos/{id}
- PUT /api/pedidos/{id}/estado
- DELETE /api/pedidos/{id}

**3.7 Configurar perfiles (ms-pedidos-dev.yml en config-repo)**
```yaml
server:
  port: 8082
spring:
  datasource:
    url: jdbc:postgresql://localhost:5432/db_pedidos_dev
    username: postgres
    password: admin
  jpa:
    hibernate:
      ddl-auto: update
ms-productos:
  url: http://localhost:8081
```

**Entregables:**
- CRUD completo de pedidos
- Comunicación funcional con ms-productos
- Validación de stock al crear pedidos
- Perfiles configurados

---

## Parte 4: Integración y Pruebas (3 horas)

### Tareas

**4.1 Configurar perfiles QA y PRD**
- Crear configuraciones para qa y prd en config-repo
- Cambiar puertos y bases de datos
- Probar inicio con diferentes perfiles

**4.2 Crear datos de prueba**
```sql
-- Insertar productos de prueba
INSERT INTO productos (nombre, descripcion, precio, stock, activo, fecha_creacion)
VALUES 
('Laptop Dell', 'Laptop i7 16GB RAM', 1200.00, 10, true, NOW()),
('Mouse Logitech', 'Mouse inalámbrico', 25.00, 50, true, NOW()),
('Teclado Mecánico', 'Teclado RGB', 80.00, 30, true, NOW());
```

**4.3 Probar flujo completo**
1. Consultar productos disponibles
2. Crear un pedido con múltiples productos
3. Verificar actualización de stock
4. Consultar productos con bajo stock
5. Actualizar estado del pedido
6. Intentar crear pedido sin stock (debe fallar)

**4.4 Documentar endpoints**
Crear archivo README.md con:
- Instrucciones de instalación
- Configuración de bases de datos
- Cómo ejecutar cada microservicio
- Ejemplos de requests/responses

**Entregables:**
- Sistema completo funcionando
- Pruebas de integración exitosas
- Documentación completa

---

## Criterios de Evaluación

| Aspecto | Puntos |
|---------|--------|
| Config Server funcionando | 10% |
| ms-productos con Gradle | 25% |
| Procedimientos almacenados | 15% |
| ms-pedidos con Maven | 20% |
| Comunicación entre microservicios | 15% |
| Configuración de perfiles | 10% |
| Documentación y pruebas | 5% |

---

## Entregables Finales

1. Código fuente de los 3 microservicios
2. Repositorio Git con configuraciones
3. Scripts SQL de bases de datos
4. Archivo README.md con documentación
5. Colección de Postman o archivo curl con pruebas
6. Video/documento mostrando el sistema funcionando

---

## Consejos

- Comienza por el Config Server
- Prueba cada microservicio individualmente antes de integrar
- Usa Postman para probar los endpoints
- Revisa los logs para depurar errores
- Documenta conforme avanzas

¡Éxito en tu práctica!