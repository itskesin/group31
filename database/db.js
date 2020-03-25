const { Pool } = require('pg')

async function initDatabase() {
    const pool = await new Pool({
        connectionString: process.env.DATABASE_URL
    });
    if (pool == null) {
        console.error("Cannot connect to db");
    }
    else {
        console.log("connected to db")
    }
    return pool;
}

async function getDatabase() {
    let database = await initDatabase();
    return database;
}

module.exports = {
    getDatabase,
};
