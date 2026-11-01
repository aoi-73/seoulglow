import mysql from "mysql2/promise";

/**
 * Pool único por proceso Node.
 *
 * La web usa `web_skincare@localhost`, que solo tiene SELECT sobre el
 * catálogo. Se conecta por 127.0.0.1 para forzar TCP (no socket Unix).
 *
 * Las credenciales viven en `.env.local` (nunca en el repositorio).
 */
const globalParaPool = globalThis as unknown as {
  __seoulglowPool?: mysql.Pool;
};

export const pool =
  globalParaPool.__seoulglowPool ??
  mysql.createPool({
    host: process.env.DB_HOST ?? "127.0.0.1",
    port: Number(process.env.DB_PORT ?? 3306),
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    database: process.env.DB_NAME,
    charset: "utf8mb4",
    waitForConnections: true,
    connectionLimit: 10,
    queueLimit: 0,
    decimalNumbers: true,
    dateStrings: true,
    timezone: "Z",
  });

// En desarrollo, el HMR puede reevaluar el módulo: reutilizamos el pool.
if (process.env.NODE_ENV !== "production") {
  globalParaPool.__seoulglowPool = pool;
}
