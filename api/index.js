require("dotenv").config();

const express = require("express");
const cors = require("cors");
const { MongoClient } = require("mongodb");

const app = express();

app.use(cors());
app.use(express.json());

const PORT = process.env.PORT || 3000;
const uri = process.env.MONGODB_URI;

if (!uri) {
    console.error("Chua co MONGODB_URI trong .env");
    process.exit(1);
}

const client = new MongoClient(uri);

async function startServer() {
    try {
        await client.connect();
        await client.db("admin").command({ ping: 1 });

        const db = client.db(
            process.env.DB_NAME || "TaskManagerDB"
        );

        console.log("Ket noi MongoDB Atlas thanh cong!");

        app.get("/", (req, res) => {
            res.json({
                message: "TaskManager Server dang chay!",
                database: db.databaseName
            });
        });

        app.get("/api/tasks", async (req, res) => {
            try {
                const tasks = await db
                    .collection("tasks")
                    .find({})
                    .toArray();

                res.json(tasks);
            } catch (error) {
                res.status(500).json({
                    message: "Loi lay danh sach tasks"
                });
            }
        });

        app.listen(PORT, () => {
            console.log(
                `Server running at http://localhost:${PORT}`
            );
        });

    } catch (error) {
        console.error("Loi ket noi:", error.message);
        await client.close();
        process.exit(1);
    }
}

startServer();